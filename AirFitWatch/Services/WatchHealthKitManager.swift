import Foundation
import HealthKit
import Combine

/// Watch-specific HealthKit manager for real-time heart rate streaming during workouts.
/// Detects active workouts (from any app) and streams HR data to the HRRTracker.
actor WatchHealthKitManager: ObservableObject {
    static let shared = WatchHealthKitManager()

    // MARK: - Published State (via MainActor)

    @MainActor @Published private(set) var isWorkoutActive: Bool = false
    @MainActor @Published private(set) var currentHeartRate: Double = 0
    @MainActor @Published private(set) var heartRateSamples: [HRSample] = []

    // MARK: - Private Properties

    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    // Workout detection
    private var recentHRSampleCount: Int = 0
    private var lastHRSampleTime: Date?
    private let workoutDetectionThreshold = 10  // 10+ HR samples in 2 min = workout

    // HR sample buffer for workout detection
    private var hrSampleBuffer: [(date: Date, bpm: Double)] = []
    private let bufferDuration: TimeInterval = 120  // 2 minutes

    // Callback for new samples
    var onHeartRateSample: ((HRSample) -> Void)?

    // MARK: - Types

    struct HRSample: Identifiable, Sendable {
        let id = UUID()
        let date: Date
        let bpm: Double
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async throws {
        let typesToRead: Set<HKSampleType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKObjectType.workoutType()
        ]

        let typesToWrite: Set<HKSampleType> = [
            HKQuantityType(.heartRate),
            HKObjectType.workoutType()
        ]

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
    }

    // MARK: - Heart Rate Streaming

    /// Start observing heart rate samples (for detecting external workouts)
    func startHeartRateObservation() async throws {
        try await requestAuthorization()

        let heartRateType = HKQuantityType(.heartRate)

        // Create anchored query for live updates
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            guard error == nil, let samples = samples as? [HKQuantitySample] else { return }
            Task { await self?.processHeartRateSamples(samples) }
        }

        query.updateHandler = { [weak self] _, samples, _, _, error in
            guard error == nil, let samples = samples as? [HKQuantitySample] else { return }
            Task { await self?.processHeartRateSamples(samples) }
        }

        healthStore.execute(query)
        heartRateQuery = query
    }

    /// Stop heart rate observation
    func stopHeartRateObservation() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }

    private func processHeartRateSamples(_ samples: [HKQuantitySample]) async {
        let unit = HKUnit.count().unitDivided(by: .minute())

        for sample in samples {
            let bpm = sample.quantity.doubleValue(for: unit)
            let date = sample.endDate
            let hrSample = HRSample(date: date, bpm: bpm)

            // Update buffer for workout detection
            hrSampleBuffer.append((date: date, bpm: bpm))
            cleanupBuffer()

            // Update published state
            await MainActor.run {
                self.currentHeartRate = bpm
                self.heartRateSamples.append(hrSample)

                // Keep only last 5 minutes of samples
                if self.heartRateSamples.count > 300 {
                    self.heartRateSamples.removeFirst(self.heartRateSamples.count - 300)
                }
            }

            // Notify HRR tracker
            onHeartRateSample?(hrSample)

            // Check for workout detection
            await updateWorkoutDetection()
        }
    }

    private func cleanupBuffer() {
        let cutoff = Date().addingTimeInterval(-bufferDuration)
        hrSampleBuffer.removeAll { $0.date < cutoff }
    }

    private func updateWorkoutDetection() async {
        // If we have many HR samples in recent buffer, a workout is active
        let isActive = hrSampleBuffer.count >= workoutDetectionThreshold

        await MainActor.run {
            if self.isWorkoutActive != isActive {
                self.isWorkoutActive = isActive
            }
        }
    }

    // MARK: - Own Workout Session (for standalone tracking)

    /// Start our own workout session for HRR tracking
    func startWorkoutSession() async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        let builder = session.associatedWorkoutBuilder()

        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

        session.startActivity(with: Date())
        try await builder.beginCollection(at: Date())

        self.workoutSession = session
        self.workoutBuilder = builder

        await MainActor.run {
            self.isWorkoutActive = true
        }
    }

    /// End our workout session
    func endWorkoutSession() async throws {
        guard let session = workoutSession, let builder = workoutBuilder else { return }

        session.end()
        try await builder.endCollection(at: Date())

        // Optionally save the workout
        // try await builder.finishWorkout()

        self.workoutSession = nil
        self.workoutBuilder = nil

        await MainActor.run {
            self.isWorkoutActive = false
        }
    }

    // MARK: - Historical Queries

    /// Get resting heart rate for baseline comparison
    func getRestingHeartRate() async -> Double? {
        let type = HKQuantityType(.restingHeartRate)
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            end: Date(),
            options: .strictEndDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                let bpm = statistics?.averageQuantity()?.doubleValue(for: .count().unitDivided(by: .minute()))
                continuation.resume(returning: bpm)
            }
            healthStore.execute(query)
        }
    }

    /// Get recent heart rate samples for analysis
    func getRecentHeartRateSamples(minutes: Int) async -> [HRSample] {
        let type = HKQuantityType(.heartRate)
        let start = Date().addingTimeInterval(-Double(minutes * 60))
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let hrSamples = (samples as? [HKQuantitySample])?.map { sample in
                    HRSample(
                        date: sample.endDate,
                        bpm: sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                    )
                } ?? []
                continuation.resume(returning: hrSamples)
            }
            healthStore.execute(query)
        }
    }
}
