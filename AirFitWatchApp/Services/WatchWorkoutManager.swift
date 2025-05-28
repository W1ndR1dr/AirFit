import Foundation
import HealthKit
import Observation
import WatchKit

@MainActor
@Observable
final class WatchWorkoutManager: NSObject {
    // MARK: - Properties
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    // Session state
    private(set) var workoutState: WorkoutState = .idle
    private(set) var isPaused = false

    // Metrics
    private(set) var heartRate: Double = 0
    private(set) var activeCalories: Double = 0
    private(set) var totalCalories: Double = 0
    private(set) var distance: Double = 0
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var currentPace: Double = 0

    // Workout data
    var selectedActivityType: HKWorkoutActivityType = .traditionalStrengthTraining
    private(set) var currentWorkoutData = WorkoutBuilderData()
    private var startTime: Date?
    private var elapsedTimer: Timer?

    // MARK: - Workout State
    enum WorkoutState: Equatable {
        case idle
        case starting
        case running
        case paused
        case ending
        case ended
        case error(String)
    }

    // MARK: - Authorization
    func requestAuthorization() async throws -> Bool {
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]

        let typesToRead: Set = [
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKObjectType.activitySummaryType()
        ]

        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    // MARK: - Workout Control
    func startWorkout(activityType: HKWorkoutActivityType) async throws {
        workoutState = .starting
        selectedActivityType = activityType

        // Configure workout
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = activityType.isIndoor ? .indoor : .outdoor

        // Create session and builder
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()

            // Setup builder
            builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            // Set delegates
            session?.delegate = self
            builder?.delegate = self

            // Start activity
            let startDate = Date()
            session?.startActivity(with: startDate)

            // Begin collection with completion handler
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder?.beginCollection(withStart: startDate) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: WorkoutError.saveFailed)
                    }
                }
            }

            startTime = startDate
            workoutState = .running
            startElapsedTimer()

            // Haptic feedback
            WKInterfaceDevice.current().play(.start)

            AppLogger.info("Workout started: \(activityType.name)", category: .health)

        } catch {
            workoutState = .error(error.localizedDescription)
            throw error
        }
    }

    func pauseWorkout() {
        guard workoutState == .running else { return }

        session?.pause()
        isPaused = true
        workoutState = .paused
        elapsedTimer?.invalidate()

        WKInterfaceDevice.current().play(.stop)
        AppLogger.info("Workout paused", category: .health)
    }

    func resumeWorkout() {
        guard workoutState == .paused else { return }

        session?.resume()
        isPaused = false
        workoutState = .running
        startElapsedTimer()

        WKInterfaceDevice.current().play(.start)
        AppLogger.info("Workout resumed", category: .health)
    }

    func endWorkout() async {
        guard workoutState == .running || workoutState == .paused else { return }

        workoutState = .ending
        elapsedTimer?.invalidate()

        do {
            // End collection with completion handler
            session?.end()
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder?.endCollection(withEnd: Date()) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: WorkoutError.saveFailed)
                    }
                }
            }

            // Save workout
            guard let workout = try await builder?.finishWorkout() else {
                throw WorkoutError.saveFailed
            }

            // Process and sync data
            await processCompletedWorkout(workout)

            workoutState = .ended

            // Success haptic
            WKInterfaceDevice.current().play(.success)

            AppLogger.info("Workout ended and saved", category: .health)

        } catch {
            workoutState = .error(error.localizedDescription)
            AppLogger.error("Failed to end workout", error: error, category: .health)
        }
    }

    // MARK: - Exercise Tracking
    func startNewExercise(name: String, muscleGroups: [String]) {
        let exercise = ExerciseBuilderData(
            id: UUID(),
            name: name,
            muscleGroups: muscleGroups,
            startTime: Date()
        )

        currentWorkoutData.exercises.append(exercise)

        WKInterfaceDevice.current().play(.click)
        AppLogger.info("Started exercise: \(name)", category: .health)
    }

    func logSet(reps: Int?, weight: Double?, duration: TimeInterval?, rpe: Double?) {
        guard let currentExercise = currentWorkoutData.exercises.last else { return }

        let set = SetBuilderData(
            reps: reps,
            weightKg: weight,
            duration: duration,
            rpe: rpe,
            completedAt: Date()
        )

        currentWorkoutData.exercises[currentWorkoutData.exercises.count - 1].sets.append(set)

        // Haptic feedback based on performance
        if let lastSet = currentExercise.sets.dropLast().last,
           let currentWeight = weight,
           let lastWeight = lastSet.weightKg,
           currentWeight > lastWeight {
            WKInterfaceDevice.current().play(.success)
        } else {
            WKInterfaceDevice.current().play(.click)
        }

        AppLogger.info("Logged set: \(set)", category: .health)
    }

    // MARK: - Private Methods
    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func processCompletedWorkout(_ workout: HKWorkout) async {
        // Prepare workout data for sync
        currentWorkoutData.workoutType = Int(selectedActivityType.rawValue)
        currentWorkoutData.startTime = workout.startDate
        currentWorkoutData.endTime = workout.endDate

        // Use activeEnergyBurned instead of deprecated totalEnergyBurned
        if let activeEnergy = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity() {
            currentWorkoutData.totalCalories = activeEnergy.doubleValue(for: .kilocalorie())
        } else {
            currentWorkoutData.totalCalories = 0
        }

        currentWorkoutData.totalDistance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        currentWorkoutData.duration = workout.duration

        // Send to iPhone via notification (simplified sync for now)
        NotificationCenter.default.post(
            name: .workoutDataReceived,
            object: nil,
            userInfo: ["data": currentWorkoutData]
        )
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            switch toState {
            case .running:
                workoutState = .running
            case .paused:
                workoutState = .paused
            case .ended:
                workoutState = .ended
            default:
                break
            }
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            workoutState = .error(error.localizedDescription)
            AppLogger.error("Workout session error", error: error, category: .health)
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor in
            for type in collectedTypes {
                guard let quantityType = type as? HKQuantityType else { continue }

                let statistics = workoutBuilder.statistics(for: quantityType)

                switch quantityType {
                case HKQuantityType(.heartRate):
                    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                    heartRate = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0

                case HKQuantityType(.activeEnergyBurned):
                    activeCalories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0

                case HKQuantityType(.distanceWalkingRunning), HKQuantityType(.distanceCycling):
                    distance = statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                    updatePace()

                default:
                    break
                }
            }
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events
    }
}

// MARK: - Supporting Types
// WorkoutBuilderData types are now in AirFit/Core/Models/WorkoutBuilderData.swift

// MARK: - Extensions
private extension WatchWorkoutManager {
    func updatePace() {
        guard elapsedTime > 0, distance > 0 else {
            currentPace = 0
            return
        }

        // Pace in minutes per kilometer
        let kilometers = distance / 1000
        let minutes = elapsedTime / 60
        currentPace = minutes / kilometers
    }
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .traditionalStrengthTraining: return "Strength Training"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Functional Training"
        case .coreTraining: return "Core Training"
        default: return "Workout"
        }
    }

    var isIndoor: Bool {
        // Simplified logic - could be expanded
        return self == .traditionalStrengthTraining || self == .yoga || self == .coreTraining
    }
}

extension Notification.Name {
    static let workoutDataReceived = Notification.Name("workoutDataReceived")
}
