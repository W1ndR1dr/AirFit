import Foundation
import SwiftData

/// # WorkoutService
///
/// ## Purpose
/// Manages workout sessions, exercise logging, and HealthKit synchronization.
/// Provides the core functionality for workout tracking and history management.
///
/// ## Dependencies
/// - `ModelContext`: SwiftData context for persisting workout data
/// - `HealthKitManaging`: Optional integration for syncing workouts to Apple Health
///
/// ## Key Responsibilities
/// - Start, pause, resume, and end workout sessions
/// - Log exercises with sets, reps, and weights
/// - Calculate estimated calories burned based on MET values
/// - AI-native workout generation (no templates needed)
/// - Sync completed workouts to HealthKit
/// - Provide workout history and statistics
///
/// ## Usage
/// ```swift
/// let workoutService = await container.resolve(WorkoutServiceProtocol.self)
///
/// // Start a workout
/// let workout = try await workoutService.startWorkout(type: .strength, user: currentUser)
///
/// // Log an exercise
/// let exercise = Exercise(name: "Bench Press", category: .chest)
/// try await workoutService.logExercise(exercise, in: workout)
///
/// // End workout (auto-syncs to HealthKit)
/// try await workoutService.endWorkout(workout)
/// ```
///
/// ## Important Notes
/// - @MainActor isolated for SwiftData compatibility
/// - HealthKit sync happens asynchronously after workout completion
/// - Calorie calculations use standard MET values
/// - AI generates personalized workouts based on user goals and preferences
@MainActor
final class WorkoutService: WorkoutServiceProtocol, ServiceProtocol {
    // MARK: - Properties
    private let modelContext: ModelContext
    private let healthKitManager: HealthKitManaging?
    private let strengthProgressionService: StrengthProgressionServiceProtocol?

    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "workout-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }

    // MARK: - Initialization
    init(
        modelContext: ModelContext,
        healthKitManager: HealthKitManaging? = nil,
        strengthProgressionService: StrengthProgressionServiceProtocol? = nil
    ) {
        self.modelContext = modelContext
        self.healthKitManager = healthKitManager
        self.strengthProgressionService = strengthProgressionService
    }

    // MARK: - ServiceProtocol Methods

    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("WorkoutService configured", category: .services)
    }

    func reset() async {
        _isConfigured = false
        AppLogger.info("WorkoutService reset", category: .services)
    }

    nonisolated func healthCheck() async -> ServiceHealth {
        await MainActor.run {
            return ServiceHealth(
                status: _isConfigured ? .healthy : .degraded,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: nil,
                metadata: [
                    "healthKitAvailable": "\(healthKitManager != nil)"
                ]
            )
        }
    }

    // MARK: - WorkoutServiceProtocol
    func startWorkout(type: WorkoutType, user: User) async throws -> Workout {
        AppLogger.info("Starting \(type.displayName) workout for user \(user.id)", category: .services)

        let workout = Workout(
            name: "\(type.displayName) - \(Date().formatted(date: .abbreviated, time: .shortened))",
            workoutType: type,
            plannedDate: Date(),
            user: user
        )

        workout.startWorkout()
        modelContext.insert(workout)

        do {
            try modelContext.save()
            AppLogger.info("Started workout \(workout.id)", category: .services)
            return workout
        } catch {
            AppLogger.error("Failed to start workout", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }

    func pauseWorkout(_ workout: Workout) async throws {
        AppLogger.info("Pausing workout \(workout.id)", category: .services)

        // Mark pause time in notes for now (could be extended with proper pause tracking)
        let pauseTime = Date().formatted(date: .omitted, time: .standard)
        workout.notes = (workout.notes ?? "") + "\nPaused at \(pauseTime)"

        do {
            try modelContext.save()
            AppLogger.info("Paused workout \(workout.id)", category: .services)
        } catch {
            AppLogger.error("Failed to pause workout", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }

    func resumeWorkout(_ workout: Workout) async throws {
        AppLogger.info("Resuming workout \(workout.id)", category: .services)

        // Mark resume time in notes
        let resumeTime = Date().formatted(date: .omitted, time: .standard)
        workout.notes = (workout.notes ?? "") + "\nResumed at \(resumeTime)"

        do {
            try modelContext.save()
            AppLogger.info("Resumed workout \(workout.id)", category: .services)
        } catch {
            AppLogger.error("Failed to resume workout", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }

    func endWorkout(_ workout: Workout) async throws {
        AppLogger.info("Ending workout \(workout.id)", category: .services)

        workout.completeWorkout()

        // Calculate calories if not already set
        if workout.caloriesBurned == nil {
            workout.caloriesBurned = calculateEstimatedCalories(for: workout)
        }

        do {
            // Save to SwiftData first
            try modelContext.save()

            // Record strength progression (non-blocking)
            if let strengthService = strengthProgressionService,
               let user = workout.user {
                Task {
                    do {
                        try await strengthService.recordStrengthProgress(from: workout, for: user)
                        AppLogger.info("Recorded strength progression from workout", category: .services)
                    } catch {
                        AppLogger.error("Failed to record strength progression", error: error, category: .services)
                        // Don't throw - strength tracking is secondary
                    }
                }
            }

            // Save to HealthKit (non-blocking)
            if workout.healthKitWorkoutID == nil {
                Task {
                    do {
                        guard let healthKitManager = self.healthKitManager else {
                            AppLogger.warning("HealthKitManager not available for workout sync", category: .services)
                            return
                        }
                        let healthKitID = try await healthKitManager.saveWorkout(workout)
                        await MainActor.run {
                            workout.healthKitWorkoutID = healthKitID
                            workout.healthKitSyncedDate = Date()
                            try? modelContext.save()
                        }
                        AppLogger.info("Synced workout to HealthKit", category: .services)
                    } catch {
                        AppLogger.error("Failed to sync workout to HealthKit", error: error, category: .services)
                        // Don't throw - HealthKit sync is secondary
                    }
                }
            }

            AppLogger.info("Ended workout \(workout.id) - Duration: \(workout.formattedDuration ?? "unknown")", category: .services)
        } catch {
            AppLogger.error("Failed to end workout", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }

    func logExercise(_ exercise: Exercise, in workout: Workout) async throws {
        AppLogger.info("Logging exercise \(exercise.name) in workout \(workout.id)", category: .services)

        workout.addExercise(exercise)

        do {
            try modelContext.save()
            AppLogger.info("Logged exercise \(exercise.id) with \(exercise.sets.count) sets", category: .services)
        } catch {
            AppLogger.error("Failed to log exercise", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }

    func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout] {
        AppLogger.info("Fetching workout history for user \(user.id)", category: .services)

        // Fetch all workouts and filter in memory to avoid SwiftData predicate issues
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
        )

        do {
            let allWorkouts = try modelContext.fetch(descriptor)
            let userWorkouts = Array(allWorkouts
                                        .filter { $0.user?.id == user.id }
                                        .prefix(limit))

            AppLogger.info("Fetched \(userWorkouts.count) workouts for user", category: .services)
            return userWorkouts
        } catch {
            AppLogger.error("Failed to fetch workout history", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }

    // Template methods removed - AI-native workout generation handles this now

    // MARK: - Private Methods
    private func calculateEstimatedCalories(for workout: Workout) -> Double {
        // Basic calorie estimation based on workout type and duration
        guard let duration = workout.durationSeconds else { return 0 }
        let minutes = duration / 60.0

        // Basic MET values for different workout types
        let metValue: Double = switch workout.workoutTypeEnum {
        case .strength: 3.5
        case .cardio: 7.0
        case .hiit: 8.0
        case .yoga: 2.5
        case .pilates: 3.0
        case .flexibility: 2.0
        case .sports: 6.0
        case .general, .none: 4.0
        }

        // Assume average weight of 70kg for now (should come from user profile)
        let weightKg = 70.0

        // Calories = METs × weight in kg × time in hours
        let hours = minutes / 60.0
        return metValue * weightKg * hours
    }
}
