import Foundation
import SwiftData

/// Basic implementation of AI Workout Service
/// Wraps the base WorkoutServiceProtocol and adds AI-specific functionality
@MainActor
final class AIWorkoutService: AIWorkoutServiceProtocol {
    private let workoutService: WorkoutServiceProtocol
    
    init(workoutService: WorkoutServiceProtocol) {
        self.workoutService = workoutService
    }
    
    // MARK: - AI-specific methods
    
    func generatePlan(
        for user: User,
        goal: String,
        duration: Int,
        intensity: String,
        targetMuscles: [String],
        equipment: [String],
        constraints: String?,
        style: String
    ) async throws -> WorkoutPlanResult {
        // Placeholder implementation
        return WorkoutPlanResult(
            id: UUID(),
            exercises: [],
            estimatedCalories: duration * 5, // Simple estimate
            estimatedDuration: duration,
            summary: "Workout plan for \(goal)",
            difficulty: .intermediate,
            focusAreas: targetMuscles
        )
    }
    
    func adaptPlan(
        _ plan: WorkoutPlanResult,
        feedback: String,
        adjustments: [String: SendableValue]
    ) async throws -> WorkoutPlanResult {
        // Return the same plan for now
        return plan
    }
    
    // MARK: - WorkoutServiceProtocol methods
    
    func startWorkout(type: WorkoutType, user: User) async throws -> Workout {
        return try await workoutService.startWorkout(type: type, user: user)
    }
    
    func pauseWorkout(_ workout: Workout) async throws {
        try await workoutService.pauseWorkout(workout)
    }
    
    func resumeWorkout(_ workout: Workout) async throws {
        try await workoutService.resumeWorkout(workout)
    }
    
    func endWorkout(_ workout: Workout) async throws {
        try await workoutService.endWorkout(workout)
    }
    
    func logExercise(_ exercise: Exercise, in workout: Workout) async throws {
        try await workoutService.logExercise(exercise, in: workout)
    }
    
    func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout] {
        return try await workoutService.getWorkoutHistory(for: user, limit: limit)
    }
    
    func getWorkoutTemplates() async throws -> [WorkoutTemplate] {
        return try await workoutService.getWorkoutTemplates()
    }
    
    func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws {
        try await workoutService.saveWorkoutTemplate(template)
    }
}

// Extension to make dictionary values Sendable for AI methods
extension AIWorkoutServiceProtocol {
    func adaptPlan(
        _ plan: WorkoutPlanResult,
        feedback: String,
        adjustments: [String: Any]
    ) async throws -> WorkoutPlanResult {
        // Convert to SendableValue
        let sendableAdjustments = adjustments.mapValues { SendableValue($0) }
        return try await adaptPlan(plan, feedback: feedback, adjustments: sendableAdjustments)
    }
}