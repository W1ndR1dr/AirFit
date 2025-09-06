import Foundation

// MARK: - PlannedWorkoutData
//
// Purpose: Transfer models for sending AI-generated workout plans from iOS to watchOS.
// Enables seamless handoff of structured workout data for Apple Watch execution.
//
// Key Features:
// - Codable for WatchConnectivity serialization
/// - Sendable for actor-safe cross-platform transfer
/// - Optimized for efficient watch execution
/// - Preserves AI-generated structure and intelligence
///
/// ## Usage
/// ```swift
/// let plannedWorkout = PlannedWorkoutData(
///     name: "Upper Body Strength",
///     workoutType: WorkoutType.strength.rawValue,
///     plannedExercises: exercises
/// )
///
/// try await transferService.sendWorkoutPlan(plannedWorkout)
/// ```

// MARK: - Planned Workout Transfer Models

/// Complete workout plan for transfer to Apple Watch
public struct PlannedWorkoutData: Codable, Sendable {
    /// Unique identifier for the workout plan
    let id: UUID

    /// Human-readable workout name (AI-generated)
    let name: String

    /// Workout type as integer (maps to WorkoutType enum)
    let workoutType: Int

    /// Estimated duration in minutes
    let estimatedDuration: Int

    /// Estimated calories to be burned
    let estimatedCalories: Int

    /// Structured exercise list with sets/reps
    let plannedExercises: [PlannedExerciseData]

    /// Primary muscle groups targeted
    let targetMuscleGroups: [String]

    /// AI-generated workout instructions or notes
    let instructions: String?

    /// Difficulty level assessment
    let difficulty: String

    /// Timestamp when plan was created
    let createdAt: Date

    /// User who the plan was created for
    let userId: UUID

    public init(
        id: UUID = UUID(),
        name: String,
        workoutType: Int,
        estimatedDuration: Int,
        estimatedCalories: Int,
        plannedExercises: [PlannedExerciseData],
        targetMuscleGroups: [String] = [],
        instructions: String? = nil,
        difficulty: String = "intermediate",
        createdAt: Date = Date(),
        userId: UUID
    ) {
        self.id = id
        self.name = name
        self.workoutType = workoutType
        self.estimatedDuration = estimatedDuration
        self.estimatedCalories = estimatedCalories
        self.plannedExercises = plannedExercises
        self.targetMuscleGroups = targetMuscleGroups
        self.instructions = instructions
        self.difficulty = difficulty
        self.createdAt = createdAt
        self.userId = userId
    }
}

/// Individual exercise definition for watch execution
public struct PlannedExerciseData: Codable, Sendable {
    /// Unique identifier for the exercise
    let id: UUID

    /// Exercise name (AI-generated, human-readable)
    let name: String

    /// Number of sets to perform
    let sets: Int

    /// Target repetitions per set (lower bound)
    let targetReps: Int

    /// Original rep range from AI (e.g., "8-12")
    let targetRepRange: String?

    /// Rest time between sets in seconds
    let restSeconds: Int

    /// Muscle groups targeted by this exercise
    let muscleGroups: [String]

    /// Form tips, modifications, or special instructions
    let notes: String?

    /// Required equipment for the exercise
    let equipment: [String]

    /// Exercise order in the workout
    let orderIndex: Int

    /// Estimated duration for this exercise (including rest)
    let estimatedDurationMinutes: Double?

    public init(
        id: UUID = UUID(),
        name: String,
        sets: Int,
        targetReps: Int,
        targetRepRange: String? = nil,
        restSeconds: Int = 60,
        muscleGroups: [String] = [],
        notes: String? = nil,
        equipment: [String] = [],
        orderIndex: Int,
        estimatedDurationMinutes: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.targetReps = targetReps
        self.targetRepRange = targetRepRange
        self.restSeconds = restSeconds
        self.muscleGroups = muscleGroups
        self.notes = notes
        self.equipment = equipment
        self.orderIndex = orderIndex
        self.estimatedDurationMinutes = estimatedDurationMinutes
    }
}

// MARK: - Transfer Protocol

/// Protocol for workout plan transfer operations
protocol WorkoutPlanTransferProtocol: ServiceProtocol {
    /// Send a planned workout to Apple Watch for execution
    func sendWorkoutPlan(_ plan: PlannedWorkoutData) async throws

    /// Check if watch is available for workout plan transfer
    func isWatchAvailable() async -> Bool

    /// Get pending workout plans awaiting transfer
    func getPendingPlans() async -> [PlannedWorkoutData]

    /// Retry failed workout plan transfers
    func retryPendingTransfers() async throws

    /// Cancel a pending workout plan transfer
    func cancelPendingPlan(id: UUID) async
}

// MARK: - Convenience Extensions

extension PlannedWorkoutData {
    /// Total estimated time including all exercises and rest periods
    var totalEstimatedMinutes: Double {
        plannedExercises.reduce(0) { total, exercise in
            let exerciseTime = exercise.estimatedDurationMinutes ?? 0
            let restTime = Double(exercise.restSeconds * (exercise.sets - 1)) / 60.0
            return total + exerciseTime + restTime
        }
    }

    /// Primary focus areas for the workout
    var primaryFocusAreas: [String] {
        Array(Set(plannedExercises.flatMap(\.muscleGroups)).union(Set(targetMuscleGroups)))
    }

    /// Total number of sets across all exercises
    var totalSets: Int {
        plannedExercises.reduce(0) { $0 + $1.sets }
    }

    /// Check if this workout requires specific equipment
    var requiresEquipment: Bool {
        !plannedExercises.flatMap(\.equipment).isEmpty
    }

    /// Get all unique equipment needed for this workout
    var requiredEquipment: [String] {
        Array(Set(plannedExercises.flatMap(\.equipment)))
    }
}

extension PlannedExerciseData {
    /// Calculate estimated time for this exercise including rest
    func calculateEstimatedDuration() -> Double {
        // Estimate: 2-3 seconds per rep + rest between sets
        let repTime = Double(targetReps * sets) * 2.5 / 60.0 // Convert to minutes
        let restTime = Double(restSeconds * (sets - 1)) / 60.0 // Rest between sets
        return repTime + restTime
    }

    /// Create a user-friendly summary of the exercise
    var summary: String {
        let repDisplay = targetRepRange ?? "\(targetReps)"
        return "\(sets) sets × \(repDisplay) reps"
    }

    /// Get the rest time formatted as minutes:seconds
    var formattedRestTime: String {
        let minutes = restSeconds / 60
        let seconds = restSeconds % 60
        return minutes > 0 ? "\(minutes):\(String(format: "%02d", seconds))" : "\(seconds)s"
    }
}

// MARK: - WorkoutPlanResult Conversion

extension PlannedWorkoutData {
    /// Create PlannedWorkoutData from AI-generated WorkoutPlanResult
    static func from(
        workoutPlan: WorkoutPlanResult,
        workoutType: WorkoutType,
        userId: UUID,
        workoutName: String? = nil
    ) -> PlannedWorkoutData {

        let plannedExercises = workoutPlan.exercises.enumerated().map { index, exercise in
            PlannedExerciseData(
                name: exercise.name,
                sets: exercise.sets,
                targetReps: parseTargetReps(from: exercise.reps),
                targetRepRange: exercise.reps,
                restSeconds: exercise.restSeconds,
                muscleGroups: [], // Could be enhanced with AI parsing
                notes: exercise.notes,
                equipment: [], // Could be enhanced with AI parsing
                orderIndex: index,
                estimatedDurationMinutes: nil // Will be calculated
            )
        }

        return PlannedWorkoutData(
            name: workoutName ?? generateWorkoutName(from: workoutPlan, type: workoutType),
            workoutType: workoutType.rawValue.hashValue, // Convert to stable int
            estimatedDuration: workoutPlan.estimatedDuration,
            estimatedCalories: workoutPlan.estimatedCalories,
            plannedExercises: plannedExercises,
            targetMuscleGroups: workoutPlan.focusAreas,
            instructions: workoutPlan.summary,
            difficulty: workoutPlan.difficulty.rawValue,
            userId: userId
        )
    }

    /// Parse target reps from AI-generated rep range
    private static func parseTargetReps(from repsString: String) -> Int {
        // Parse reps like "8-12", "10", "12-15", etc.
        if let dashRange = repsString.range(of: "-") {
            let lowerBound = String(repsString[..<dashRange.lowerBound])
            return Int(lowerBound.trimmingCharacters(in: .whitespaces)) ?? 10
        } else {
            return Int(repsString.trimmingCharacters(in: .whitespaces)) ?? 10
        }
    }

    /// Generate a default workout name
    private static func generateWorkoutName(from plan: WorkoutPlanResult, type: WorkoutType) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(type.displayName) - \(formatter.string(from: Date()))"
    }

    /// Create PlannedWorkoutData from existing Workout model
    static func from(workout: Workout, userId: UUID) -> PlannedWorkoutData {
        let plannedExercises = workout.exercises.enumerated().map { index, exercise in
            PlannedExerciseData(
                name: exercise.name,
                sets: exercise.sets.count,
                targetReps: exercise.sets.first?.targetReps ?? 10,
                targetRepRange: nil, // Not available in ExerciseSet model
                restSeconds: 60, // Default rest time
                muscleGroups: exercise.muscleGroups,
                notes: exercise.notes,
                equipment: exercise.equipment,
                orderIndex: index,
                estimatedDurationMinutes: nil
            )
        }

        return PlannedWorkoutData(
            name: workout.name,
            workoutType: workout.workoutTypeEnum?.rawValue.hashValue ?? 0,
            estimatedDuration: Int(workout.durationSeconds ?? 0) / 60, // Convert to minutes
            estimatedCalories: Int(workout.caloriesBurned ?? 0),
            plannedExercises: plannedExercises,
            targetMuscleGroups: Array(Set(workout.exercises.flatMap(\.muscleGroups))),
            instructions: workout.notes,
            difficulty: "intermediate", // Default difficulty
            userId: userId
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a planned workout is received on watchOS
    static let plannedWorkoutReceived = Notification.Name("plannedWorkoutReceived")

    /// Posted when workout plan transfer fails
    static let workoutPlanTransferFailed = Notification.Name("workoutPlanTransferFailed")

    /// Posted when workout plan transfer succeeds
    static let workoutPlanTransferSuccess = Notification.Name("workoutPlanTransferSuccess")
}
