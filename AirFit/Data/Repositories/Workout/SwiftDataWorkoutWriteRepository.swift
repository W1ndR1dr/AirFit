import Foundation
import SwiftData

@MainActor
final class SwiftDataWorkoutWriteRepository: WorkoutWriteRepositoryProtocol {
    private let context: ModelContext
    
    init(modelContext: ModelContext) {
        self.context = modelContext
    }
    
    // MARK: - Workout Operations
    
    func save(_ workout: Workout) throws {
        try context.save()
    }
    
    func delete(_ workout: Workout) throws {
        context.delete(workout)
        try context.save()
    }
    
    func create(for user: User, plan: WorkoutPlan) throws -> Workout {
        let workout = Workout(from: plan, user: user)
        context.insert(workout)
        try context.save()
        return workout
    }
    
    func duplicate(_ workout: Workout, for date: Date) throws -> Workout {
        let duplicate = workout.duplicate()
        duplicate.plannedDate = date
        duplicate.completedDate = nil
        duplicate.isCompleted = false
        
        context.insert(duplicate)
        try context.save()
        
        return duplicate
    }
    
    // MARK: - Workout Status
    
    func startWorkout(_ workout: Workout, at date: Date) throws {
        workout.startedAt = date
        workout.isStarted = true
        try context.save()
    }
    
    func completeWorkout(_ workout: Workout, at date: Date, duration: TimeInterval?) throws {
        workout.completedDate = date
        workout.isCompleted = true
        
        if let duration = duration {
            workout.durationSeconds = duration
        } else if let startDate = workout.startedAt {
            workout.durationSeconds = date.timeIntervalSince(startDate)
        }
        
        try context.save()
    }
    
    func pauseWorkout(_ workout: Workout) throws {
        workout.isPaused = true
        try context.save()
    }
    
    func resumeWorkout(_ workout: Workout) throws {
        workout.isPaused = false
        try context.save()
    }
    
    // MARK: - Exercise Operations
    
    func addExercise(_ exercise: Exercise, to workout: Workout) throws {
        workout.exercises.append(exercise)
        context.insert(exercise)
        try context.save()
    }
    
    func removeExercise(_ exercise: Exercise, from workout: Workout) throws {
        if let index = workout.exercises.firstIndex(of: exercise) {
            workout.exercises.remove(at: index)
        }
        context.delete(exercise)
        try context.save()
    }
    
    func updateExercise(_ exercise: Exercise, in workout: Workout) throws {
        // SwiftData automatically tracks changes to persistent objects
        try context.save()
    }
    
    // MARK: - Set Operations
    
    func addSet(_ set: ExerciseSet, to exercise: Exercise) throws {
        exercise.sets.append(set)
        context.insert(set)
        try context.save()
    }
    
    func removeSet(_ set: ExerciseSet, from exercise: Exercise) throws {
        if let index = exercise.sets.firstIndex(of: set) {
            exercise.sets.remove(at: index)
        }
        context.delete(set)
        try context.save()
    }
    
    func updateSet(_ set: ExerciseSet) throws {
        // SwiftData automatically tracks changes to persistent objects
        try context.save()
    }
    
    // MARK: - Bulk Operations
    
    func saveWorkouts(_ workouts: [Workout]) throws {
        for workout in workouts {
            context.insert(workout)
        }
        try context.save()
    }
    
    func deleteWorkouts(_ workouts: [Workout]) throws {
        for workout in workouts {
            context.delete(workout)
        }
        try context.save()
    }
    
    // MARK: - User Association
    
    func addWorkoutToUser(_ workout: Workout, user: User) throws {
        user.workouts.append(workout)
        context.insert(workout)
        try context.save()
    }
}