import Foundation

// MARK: - Shared Models for Watch Transfer
//
// Purpose: Essential data models shared between iOS and watchOS for workout plan transfer.
// This file should be kept in sync with PlannedWorkoutData.swift in the iOS target.
//
// Important Note: These models are duplicated here for watchOS target compatibility.
// Changes should be made to both files to maintain consistency.

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

    init(
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

    init(
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

// MARK: - Error Types

enum WorkoutPlanError: LocalizedError, Sendable {
    case invalidWorkoutData
    case missingExercises
    case transferFailed(String)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidWorkoutData:
            return "Invalid workout plan data"
        case .missingExercises:
            return "Workout plan must contain exercises"
        case .transferFailed(let message):
            return "Transfer failed: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}

// MARK: - Shared Enums

/// Workout type enum that matches iOS side
enum WorkoutType: Int, CaseIterable {
    case general = 0
    case strength = 1
    case cardio = 2
    case hiit = 3
    case yoga = 4
    case run = 5
    case cycle = 6
    case swim = 7
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a planned workout is received from iOS
    static let plannedWorkoutReceived = Notification.Name("plannedWorkoutReceived")

    /// Posted when a planned workout is started
    static let plannedWorkoutStarted = Notification.Name("plannedWorkoutStarted")

    /// Posted when the available planned workout is cleared
    static let plannedWorkoutCleared = Notification.Name("plannedWorkoutCleared")
    
    /// Posted when workout data is received from watch
    static let workoutDataReceived = Notification.Name("workoutDataReceived")
    
    /// Posted when workout completion data is received from watch
    static let workoutCompletionDataReceived = Notification.Name("workoutCompletionDataReceived")
}
