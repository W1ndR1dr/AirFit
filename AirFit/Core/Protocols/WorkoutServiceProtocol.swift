import Foundation
import SwiftData

/// Protocol for workout-related operations
protocol WorkoutServiceProtocol: AnyObject, Sendable {
    func startWorkout(type: WorkoutType, user: User) async throws -> Workout
    func pauseWorkout(_ workout: Workout) async throws
    func resumeWorkout(_ workout: Workout) async throws
    func endWorkout(_ workout: Workout) async throws
    func logExercise(_ exercise: Exercise, in workout: Workout) async throws
    func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout]
    // Template methods removed - using AI-native workout generation
}