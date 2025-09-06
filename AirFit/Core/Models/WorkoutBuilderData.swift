import Foundation
import HealthKit

// MARK: - Shared Workout Builder Types
struct WorkoutBuilderData: Codable, Sendable {
    var id = UUID()
    var workoutType: Int = 0
    var startTime: Date?
    var endTime: Date?
    var exercises: [ExerciseBuilderData] = []
    var totalCalories: Double = 0
    var totalDistance: Double = 0
    var duration: TimeInterval = 0
    var healthKitWorkoutID: String? // UUID of the HKWorkout
}

struct ExerciseBuilderData: Codable, Sendable {
    let id: UUID
    let name: String
    let muscleGroups: [String]
    let startTime: Date
    var sets: [SetBuilderData] = []
}

struct SetBuilderData: Codable, Sendable {
    let reps: Int?
    let weightKg: Double?
    let duration: TimeInterval?
    let rpe: Double?
    let comment: String?
    let side: String? // "L" for left, "R" for right, nil for both
    let completedAt: Date
    
    init(
        reps: Int? = nil,
        weightKg: Double? = nil,
        duration: TimeInterval? = nil,
        rpe: Double? = nil,
        comment: String? = nil,
        side: String? = nil,
        completedAt: Date = Date()
    ) {
        self.reps = reps
        self.weightKg = weightKg
        self.duration = duration
        self.rpe = rpe
        self.comment = comment
        self.side = side
        self.completedAt = completedAt
    }
}

enum WorkoutError: LocalizedError, Sendable {
    case saveFailed
    case syncFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed: return "Failed to save workout"
        case .syncFailed: return "Failed to sync workout data"
        }
    }
}
