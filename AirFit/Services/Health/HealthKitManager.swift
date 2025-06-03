import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class HealthKitManager {
    // MARK: - Singleton
    static let shared = HealthKitManager()

    // MARK: - Properties
    private let healthStore = HKHealthStore()
    private let dataFetcher: HealthKitDataFetcher
    private let sleepAnalyzer: HealthKitSleepAnalyzer
    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    // MARK: - Authorization Status
    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    // MARK: - HealthKit Errors
    enum HealthKitError: LocalizedError {
        case notAvailable
        case authorizationDenied
        case dataNotFound
        case queryFailed(Error)
        case invalidData

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "HealthKit is not available on this device"
            case .authorizationDenied:
                return "HealthKit authorization was denied"
            case .dataNotFound:
                return "Requested health data not found"
            case .queryFailed(let error):
                return "HealthKit query failed: \(error.localizedDescription)"
            case .invalidData:
                return "Invalid health data received"
            }
        }
    }

    // MARK: - Initialization
    private init() {
        self.dataFetcher = HealthKitDataFetcher(healthStore: healthStore)
        self.sleepAnalyzer = HealthKitSleepAnalyzer(healthStore: healthStore)
        refreshAuthorizationStatus()
    }

    // MARK: - Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .restricted
            throw HealthKitError.notAvailable
        }

        do {
            try await healthStore.requestAuthorization(
                toShare: HealthKitDataTypes.writeTypes,
                read: HealthKitDataTypes.readTypes
            )
            authorizationStatus = .authorized
            AppLogger.info("HealthKit authorization granted", category: .health)

            // Enable background delivery after successful authorization
            do {
                try await dataFetcher.enableBackgroundDelivery()
            } catch {
                AppLogger.error("Failed to enable HealthKit background delivery", error: error, category: .health)
            }
        } catch {
            authorizationStatus = .denied
            AppLogger.error("HealthKit authorization failed", error: error, category: .health)
            throw error
        }
    }

    func refreshAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .restricted
            return
        }

        // Check authorization status using a representative type
        let status = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .stepCount)!)
        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .sharingDenied:
            authorizationStatus = .denied
        case .sharingAuthorized:
            authorizationStatus = .authorized
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }

    // MARK: - Data Fetching Methods

    /// Fetches today's activity metrics
    func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now

        return try await fetchActivityMetrics(from: startOfDay, to: endOfDay)
    }

    /// Fetches activity metrics for a specific date range
    private func fetchActivityMetrics(from startDate: Date, to endDate: Date) async throws -> ActivityMetrics {
        async let activeEnergy = dataFetcher.fetchTotalQuantity(
            identifier: .activeEnergyBurned, start: startDate, end: endDate, unit: HKUnit.kilocalorie()
        )
        async let basalEnergy = dataFetcher.fetchTotalQuantity(
            identifier: .basalEnergyBurned, start: startDate, end: endDate, unit: HKUnit.kilocalorie()
        )
        async let steps = dataFetcher.fetchTotalQuantity(
            identifier: .stepCount, start: startDate, end: endDate, unit: HKUnit.count()
        )
        async let distance = dataFetcher.fetchTotalQuantity(
            identifier: .distanceWalkingRunning, start: startDate, end: endDate, unit: HKUnit.meter()
        )
        async let flights = dataFetcher.fetchTotalQuantity(
            identifier: .flightsClimbed, start: startDate, end: endDate, unit: HKUnit.count()
        )
        async let exerciseTime = dataFetcher.fetchTotalQuantity(
            identifier: .appleExerciseTime, start: startDate, end: endDate, unit: HKUnit.minute()
        )
        async let standHours = dataFetcher.fetchTotalQuantity(
            identifier: .appleStandTime, start: startDate, end: endDate, unit: HKUnit.count()
        )
        async let moveTime = dataFetcher.fetchTotalQuantity(
            identifier: .appleMoveTime, start: startDate, end: endDate, unit: HKUnit.minute()
        )
        async let currentHR = dataFetcher.fetchLatestQuantitySample(
            identifier: .heartRate, unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        var metrics = ActivityMetrics()
        metrics.activeEnergyBurned = (try await activeEnergy).map { Measurement(value: $0, unit: UnitEnergy.kilocalories) }
        metrics.basalEnergyBurned = (try await basalEnergy).map { Measurement(value: $0, unit: UnitEnergy.kilocalories) }
        metrics.steps = (try await steps).map { Int($0) }
        metrics.distance = (try await distance).map { Measurement(value: $0, unit: UnitLength.meters) }
        metrics.flightsClimbed = (try await flights).map { Int($0) }
        metrics.exerciseMinutes = (try await exerciseTime).map { Int($0) }
        metrics.standHours = (try await standHours).map { Int($0) }
        metrics.moveMinutes = (try await moveTime).map { Int($0) }
        metrics.currentHeartRate = (try await currentHR).map { Int($0) }
        metrics.isWorkoutActive = false // TODO: Implement workout detection
        metrics.workoutType = nil
        metrics.moveProgress = nil // TODO: Calculate from goals
        metrics.exerciseProgress = nil
        metrics.standProgress = nil

        return metrics
    }

    /// Fetches heart health metrics
    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
        async let restingHR = dataFetcher.fetchLatestQuantitySample(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        async let hrv = dataFetcher.fetchLatestQuantitySample(
            identifier: .heartRateVariabilitySDNN,
            unit: HKUnit.secondUnit(with: .milli)
        )

        async let respiratoryRate = dataFetcher.fetchLatestQuantitySample(
            identifier: .respiratoryRate,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        async let vo2Max = dataFetcher.fetchLatestQuantitySample(
            identifier: .vo2Max,
            unit: HKUnit.literUnit(with: .milli)
                .unitDivided(by: HKUnit.gramUnit(with: .kilo))
                .unitDivided(by: HKUnit.minute())
        )

        async let recovery = dataFetcher.fetchLatestQuantitySample(
            identifier: .heartRateRecoveryOneMinute,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        return HeartHealthMetrics(
            restingHeartRate: (try await restingHR).map { Int($0) },
            hrv: (try await hrv).map { Measurement(value: $0, unit: UnitDuration.milliseconds) },
            respiratoryRate: try await respiratoryRate,
            vo2Max: try await vo2Max,
            cardioFitness: (try await vo2Max).flatMap {
                HeartHealthMetrics.CardioFitnessLevel.from(vo2Max: $0)
            },
            recoveryHeartRate: (try await recovery).map { Int($0) },
            heartRateRecovery: nil // TODO: Calculate from workout data
        )
    }

    /// Fetches latest body metrics
    func fetchLatestBodyMetrics() async throws -> BodyMetrics {
        async let weight = dataFetcher.fetchLatestQuantitySample(
            identifier: .bodyMass,
            unit: HKUnit.gramUnit(with: .kilo)
        )

        async let bodyFat = dataFetcher.fetchLatestQuantitySample(
            identifier: .bodyFatPercentage,
            unit: HKUnit.percent()
        )

        async let leanMass = dataFetcher.fetchLatestQuantitySample(
            identifier: .leanBodyMass,
            unit: HKUnit.gramUnit(with: .kilo)
        )

        async let bmi = dataFetcher.fetchLatestQuantitySample(
            identifier: .bodyMassIndex,
            unit: HKUnit.count()
        )

        return BodyMetrics(
            weight: (try await weight).map { Measurement(value: $0, unit: UnitMass.kilograms) },
            bodyFatPercentage: (try await bodyFat).map { $0 * 100 }, // Convert to percentage
            leanBodyMass: (try await leanMass).map { Measurement(value: $0, unit: UnitMass.kilograms) },
            bmi: try await bmi,
            weightTrend: nil, // TODO: Calculate trends
            bodyFatTrend: nil
        )
    }

    /// Fetches last night's sleep session
    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {
        let calendar = Calendar.current
        let now = Date()

        // Look for sleep data from yesterday evening to this morning
        let startDate = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) ?? now
        let endDate = calendar.date(byAdding: .hour, value: 12, to: calendar.startOfDay(for: now)) ?? now

        return try await sleepAnalyzer.analyzeSleepSamples(from: startDate, to: endDate)
    }
    
    /// Fetches workout data within date range
    func getWorkoutData(from startDate: Date, to endDate: Date) async -> [WorkoutData] {
        // Create predicate for date range
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Create query
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        // Use HKWorkoutType
        let workoutType = HKObjectType.workoutType()
        
        // Execute query with async/await
        return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: workoutType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { (_, samples, error) in
                    if let error = error {
                        AppLogger.error("Failed to fetch workouts", error: error, category: .health)
                        continuation.resume(returning: [])
                        return
                    }
                    
                    let workouts = (samples as? [HKWorkout] ?? []).map { workout in
                        WorkoutData(
                            id: workout.uuid,
                            duration: workout.duration,
                            totalCalories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                            workoutType: workout.workoutActivityType,
                            startDate: workout.startDate,
                            endDate: workout.endDate
                        )
                    }
                    
                    continuation.resume(returning: workouts)
                }
                
                healthStore.execute(query)
            }
    }

}

// MARK: - Workout Data Model
struct WorkoutData {
    let id: UUID
    let duration: TimeInterval
    let totalCalories: Double?
    let workoutType: HKWorkoutActivityType
    let startDate: Date
    let endDate: Date
}
