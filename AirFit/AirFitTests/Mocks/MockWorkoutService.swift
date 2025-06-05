import Foundation
import SwiftData
import XCTest
@testable import AirFit

/// Mock implementation of WorkoutServiceProtocol for testing
final class MockWorkoutService: WorkoutServiceProtocol, MockProtocol {
    // MARK: - MockProtocol
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - Error Control
    var shouldThrowError = false
    var errorToThrow: Error = AppError.unknown(message: "Mock workout service error")
    
    // MARK: - Stubbed Data
    var stubbedWorkout: Workout?
    var stubbedWorkoutHistory: [Workout] = []
    var stubbedWorkoutTemplates: [WorkoutTemplate] = []
    
    // MARK: - State Tracking
    private var activeWorkouts: Set<UUID> = []
    private var pausedWorkouts: Set<UUID> = []
    
    init() {
        // Setup default stubbed data
        setupDefaultStubs()
    }
    
    // MARK: - WorkoutServiceProtocol
    func startWorkout(type: WorkoutType, user: User) async throws -> Workout {
        recordInvocation("startWorkout", arguments: type, user.id)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let workout = stubbedWorkout {
            activeWorkouts.insert(workout.id)
            return workout
        }
        
        // Create a default workout
        let workout = Workout(name: "Test Workout")
        workout.workoutType = type.rawValue
        workout.plannedDate = Date()
        workout.user = user
        
        activeWorkouts.insert(workout.id)
        return workout
    }
    
    func pauseWorkout(_ workout: Workout) async throws {
        recordInvocation("pauseWorkout", arguments: workout.id)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard activeWorkouts.contains(workout.id) else {
            throw AppError.unknown(message: "Cannot pause inactive workout")
        }
        
        activeWorkouts.remove(workout.id)
        pausedWorkouts.insert(workout.id)
        // Track state internally
    }
    
    func resumeWorkout(_ workout: Workout) async throws {
        recordInvocation("resumeWorkout", arguments: workout.id)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard pausedWorkouts.contains(workout.id) else {
            throw AppError.unknown(message: "Cannot resume workout that is not paused")
        }
        
        pausedWorkouts.remove(workout.id)
        activeWorkouts.insert(workout.id)
        // Track resumed state internally
    }
    
    func endWorkout(_ workout: Workout) async throws {
        recordInvocation("endWorkout", arguments: workout.id)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        activeWorkouts.remove(workout.id)
        pausedWorkouts.remove(workout.id)
        
        workout.completedDate = Date()
        workout.caloriesBurned = calculateMockCalories(workout)
    }
    
    func logExercise(_ exercise: Exercise, in workout: Workout) async throws {
        recordInvocation("logExercise", arguments: exercise.name, workout.id)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        workout.exercises.append(exercise)
    }
    
    func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout] {
        recordInvocation("getWorkoutHistory", arguments: user.id, limit)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if !stubbedWorkoutHistory.isEmpty {
            return Array(stubbedWorkoutHistory.prefix(limit))
        }
        
        // Return empty history
        return []
    }
    
    func getWorkoutTemplates() async throws -> [WorkoutTemplate] {
        recordInvocation("getWorkoutTemplates")
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return stubbedWorkoutTemplates
    }
    
    func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws {
        recordInvocation("saveWorkoutTemplate", arguments: template.name)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        stubbedWorkoutTemplates.append(template)
    }
    
    // MARK: - Test Helpers
    private func setupDefaultStubs() {
        // Create default workout templates
        let pushTemplate = WorkoutTemplate(name: "Push Day")
        pushTemplate.workoutType = WorkoutType.strength.rawValue
        pushTemplate.descriptionText = "Target muscles: Chest, Shoulders, Triceps"
        pushTemplate.difficulty = "intermediate"
        
        let cardioTemplate = WorkoutTemplate(name: "HIIT Cardio")
        cardioTemplate.workoutType = WorkoutType.cardio.rawValue
        cardioTemplate.estimatedDuration = 30 * 60 // 30 minutes
        cardioTemplate.difficulty = "advanced"
        
        stubbedWorkoutTemplates = [pushTemplate, cardioTemplate]
    }
    
    private func calculateMockCalories(_ workout: Workout) -> Double {
        // Simple mock calculation based on duration and type
        let duration = (workout.durationSeconds ?? 1800) / 60 // Default 30 min
        let caloriesPerMinute: Double = {
            let type = WorkoutType(rawValue: workout.workoutType) ?? .general
            switch type {
            case .strength:
                return 5.0
            case .cardio, .hiit:
                return 8.0
            case .flexibility:
                return 3.0
            case .sports:
                return 7.0
            case .general, .yoga, .pilates:
                return 4.0
            }
        }()
        
        return duration * caloriesPerMinute
    }
    
    func stubWorkout(_ workout: Workout) {
        stubbedWorkout = workout
    }
    
    func stubWorkoutHistory(_ history: [Workout]) {
        stubbedWorkoutHistory = history
    }
    
    func stubTemplates(_ templates: [WorkoutTemplate]) {
        stubbedWorkoutTemplates = templates
    }
    
    func verifyWorkoutStarted(type: WorkoutType) {
        mockLock.lock()
        defer { mockLock.unlock() }
        
        guard let calls = invocations["startWorkout"] as? [[Any]] else {
            XCTFail("No workouts were started")
            return
        }
        
        let matching = calls.contains { args in
            guard let workoutType = args.first as? WorkoutType else { return false }
            return workoutType == type
        }
        
        XCTAssertTrue(matching, "No workout started with type: \(type)")
    }
    
    func verifyExerciseLogged(named exerciseName: String) {
        mockLock.lock()
        defer { mockLock.unlock() }
        
        guard let calls = invocations["logExercise"] as? [[Any]] else {
            XCTFail("No exercises were logged")
            return
        }
        
        let matching = calls.contains { args in
            guard let name = args.first as? String else { return false }
            return name == exerciseName
        }
        
        XCTAssertTrue(matching, "No exercise logged with name: \(exerciseName)")
    }
    
    func isWorkoutActive(_ workoutId: UUID) -> Bool {
        mockLock.lock()
        defer { mockLock.unlock() }
        return activeWorkouts.contains(workoutId)
    }
    
    func isWorkoutPaused(_ workoutId: UUID) -> Bool {
        mockLock.lock()
        defer { mockLock.unlock() }
        return pausedWorkouts.contains(workoutId)
    }
}