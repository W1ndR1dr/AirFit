import Foundation

@MainActor
protocol WorkoutWriteRepositoryProtocol: Sendable {
    // MARK: - Workout Operations
    func save(_ workout: Workout) throws
    func delete(_ workout: Workout) throws
    func create(for user: User, plan: PlannedWorkoutData) throws -> Workout
    func duplicate(_ workout: Workout, for date: Date) throws -> Workout
    
    // MARK: - Workout Status
    func startWorkout(_ workout: Workout, at date: Date) throws
    func completeWorkout(_ workout: Workout, at date: Date, duration: TimeInterval?) throws
    func pauseWorkout(_ workout: Workout) throws
    func resumeWorkout(_ workout: Workout) throws
    
    // MARK: - Exercise Operations
    func addExercise(_ exercise: Exercise, to workout: Workout) throws
    func removeExercise(_ exercise: Exercise, from workout: Workout) throws
    func updateExercise(_ exercise: Exercise, in workout: Workout) throws
    
    // MARK: - Set Operations
    func addSet(_ set: ExerciseSet, to exercise: Exercise) throws
    func removeSet(_ set: ExerciseSet, from exercise: Exercise) throws
    func updateSet(_ set: ExerciseSet) throws
    
    // MARK: - Bulk Operations
    func saveWorkouts(_ workouts: [Workout]) throws
    func deleteWorkouts(_ workouts: [Workout]) throws
    
    // MARK: - User Association
    func addWorkoutToUser(_ workout: Workout, user: User) throws
}