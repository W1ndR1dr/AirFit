import Foundation
import SwiftData
@testable import AirFit

// MARK: - MockWorkoutService
final class MockWorkoutService: WorkoutServiceProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // Stubbed responses
    var stubbedStartWorkoutResult: Workout?
    var stubbedStartWorkoutError: Error?
    var stubbedPauseWorkoutError: Error?
    var stubbedResumeWorkoutError: Error?
    var stubbedEndWorkoutError: Error?
    var stubbedLogExerciseError: Error?
    var stubbedGetWorkoutHistoryResult: [Workout] = []
    var stubbedGetWorkoutHistoryError: Error?
    var stubbedGetWorkoutTemplatesResult: [WorkoutTemplate] = []
    var stubbedGetWorkoutTemplatesError: Error?
    var stubbedSaveWorkoutTemplateError: Error?
    
    func startWorkout(type: WorkoutType, user: User) async throws -> Workout {
        recordInvocation("startWorkout", arguments: type, user)
        
        if let error = stubbedStartWorkoutError {
            throw error
        }
        
        if let workout = stubbedStartWorkoutResult {
            return workout
        }
        
        // Create a default workout for testing
        let workout = Workout(
            name: "Test Workout",
            type: type,
            startDate: Date(),
            user: user
        )
        return workout
    }
    
    func pauseWorkout(_ workout: Workout) async throws {
        recordInvocation("pauseWorkout", arguments: workout)
        
        if let error = stubbedPauseWorkoutError {
            throw error
        }
        
        workout.isPaused = true
    }
    
    func resumeWorkout(_ workout: Workout) async throws {
        recordInvocation("resumeWorkout", arguments: workout)
        
        if let error = stubbedResumeWorkoutError {
            throw error
        }
        
        workout.isPaused = false
    }
    
    func endWorkout(_ workout: Workout) async throws {
        recordInvocation("endWorkout", arguments: workout)
        
        if let error = stubbedEndWorkoutError {
            throw error
        }
        
        workout.endDate = Date()
        workout.isCompleted = true
    }
    
    func logExercise(_ exercise: Exercise, in workout: Workout) async throws {
        recordInvocation("logExercise", arguments: exercise, workout)
        
        if let error = stubbedLogExerciseError {
            throw error
        }
        
        workout.exercises.append(exercise)
    }
    
    func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout] {
        recordInvocation("getWorkoutHistory", arguments: user, limit)
        
        if let error = stubbedGetWorkoutHistoryError {
            throw error
        }
        
        return stubbedGetWorkoutHistoryResult
    }
    
    func getWorkoutTemplates() async throws -> [WorkoutTemplate] {
        recordInvocation("getWorkoutTemplates", arguments: nil)
        
        if let error = stubbedGetWorkoutTemplatesError {
            throw error
        }
        
        return stubbedGetWorkoutTemplatesResult
    }
    
    func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws {
        recordInvocation("saveWorkoutTemplate", arguments: template)
        
        if let error = stubbedSaveWorkoutTemplateError {
            throw error
        }
    }
    
    // Helper methods for testing
    func stubStartWorkout(with workout: Workout) {
        stubbedStartWorkoutResult = workout
    }
    
    func stubStartWorkoutError(with error: Error) {
        stubbedStartWorkoutError = error
    }
    
    func stubWorkoutHistory(with workouts: [Workout]) {
        stubbedGetWorkoutHistoryResult = workouts
    }
    
    func stubWorkoutTemplates(with templates: [WorkoutTemplate]) {
        stubbedGetWorkoutTemplatesResult = templates
    }
    
    // Verify helpers
    func verifyStartWorkout(called times: Int = 1) {
        verify("startWorkout", called: times)
    }
    
    func verifyEndWorkout(called times: Int = 1) {
        verify("endWorkout", called: times)
    }
    
    func verifyLogExercise(called times: Int = 1) {
        verify("logExercise", called: times)
    }
}