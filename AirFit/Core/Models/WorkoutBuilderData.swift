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
    let completedAt: Date
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
