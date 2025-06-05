import Foundation
import SwiftData

@MainActor
final class WorkoutService: WorkoutServiceProtocol {
    // MARK: - Properties
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - WorkoutServiceProtocol
    func startWorkout(type: WorkoutType, user: User) async throws -> Workout {
        AppLogger.info("Starting \(type.displayName) workout for user \(user.id)", category: .services)
        
        let workout = Workout(
            name: "\(type.displayName) - \(Date().formatted(date: .abbreviated, time: .shortened))",
            workoutType: type,
            plannedDate: Date(),
            user: user
        )
        
        workout.startWorkout()
        modelContext.insert(workout)
        
        do {
            try modelContext.save()
            AppLogger.info("Started workout \(workout.id)", category: .services)
            return workout
        } catch {
            AppLogger.error("Failed to start workout", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }
    
    func pauseWorkout(_ workout: Workout) async throws {
        AppLogger.info("Pausing workout \(workout.id)", category: .services)
        
        // Mark pause time in notes for now (could be extended with proper pause tracking)
        let pauseTime = Date().formatted(date: .omitted, time: .standard)
        workout.notes = (workout.notes ?? "") + "\nPaused at \(pauseTime)"
        
        do {
            try modelContext.save()
            AppLogger.info("Paused workout \(workout.id)", category: .services)
        } catch {
            AppLogger.error("Failed to pause workout", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }
    
    func resumeWorkout(_ workout: Workout) async throws {
        AppLogger.info("Resuming workout \(workout.id)", category: .services)
        
        // Mark resume time in notes
        let resumeTime = Date().formatted(date: .omitted, time: .standard)
        workout.notes = (workout.notes ?? "") + "\nResumed at \(resumeTime)"
        
        do {
            try modelContext.save()
            AppLogger.info("Resumed workout \(workout.id)", category: .services)
        } catch {
            AppLogger.error("Failed to resume workout", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }
    
    func endWorkout(_ workout: Workout) async throws {
        AppLogger.info("Ending workout \(workout.id)", category: .services)
        
        workout.completeWorkout()
        
        // Calculate calories if not already set
        if workout.caloriesBurned == nil {
            workout.caloriesBurned = calculateEstimatedCalories(for: workout)
        }
        
        do {
            try modelContext.save()
            AppLogger.info("Ended workout \(workout.id) - Duration: \(workout.formattedDuration ?? "unknown")", category: .services)
        } catch {
            AppLogger.error("Failed to end workout", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }
    
    func logExercise(_ exercise: Exercise, in workout: Workout) async throws {
        AppLogger.info("Logging exercise \(exercise.name) in workout \(workout.id)", category: .services)
        
        workout.addExercise(exercise)
        
        do {
            try modelContext.save()
            AppLogger.info("Logged exercise \(exercise.id) with \(exercise.sets.count) sets", category: .services)
        } catch {
            AppLogger.error("Failed to log exercise", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }
    
    func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout] {
        AppLogger.info("Fetching workout history for user \(user.id)", category: .services)
        
        // Fetch all workouts and filter in memory to avoid SwiftData predicate issues
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
        )
        
        do {
            let allWorkouts = try modelContext.fetch(descriptor)
            let userWorkouts = Array(allWorkouts
                .filter { $0.user?.id == user.id }
                .prefix(limit))
            
            AppLogger.info("Fetched \(userWorkouts.count) workouts for user", category: .services)
            return userWorkouts
        } catch {
            AppLogger.error("Failed to fetch workout history", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }
    
    func getWorkoutTemplates() async throws -> [WorkoutTemplate] {
        AppLogger.info("Fetching workout templates", category: .services)
        
        // Fetch all templates without sorting (will sort in memory)
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        
        do {
            let templates = try modelContext.fetch(descriptor)
            // Sort in memory: system templates first, then by name
            let sortedTemplates = templates.sorted { first, second in
                if first.isSystemTemplate != second.isSystemTemplate {
                    return first.isSystemTemplate
                }
                return first.name < second.name
            }
            AppLogger.info("Fetched \(sortedTemplates.count) workout templates", category: .services)
            return sortedTemplates
        } catch {
            AppLogger.error("Failed to fetch workout templates", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }
    
    func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws {
        AppLogger.info("Saving workout template: \(template.name)", category: .services)
        
        modelContext.insert(template)
        
        do {
            try modelContext.save()
            AppLogger.info("Saved workout template \(template.id)", category: .services)
        } catch {
            AppLogger.error("Failed to save workout template", error: error, category: .services)
            throw AppError.unknown(message: "Database error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    private func calculateEstimatedCalories(for workout: Workout) -> Double {
        // Basic calorie estimation based on workout type and duration
        guard let duration = workout.durationSeconds else { return 0 }
        let minutes = duration / 60.0
        
        // Basic MET values for different workout types
        let metValue: Double = switch workout.workoutTypeEnum {
        case .strength: 3.5
        case .cardio: 7.0
        case .hiit: 8.0
        case .yoga: 2.5
        case .pilates: 3.0
        case .flexibility: 2.0
        case .sports: 6.0
        case .general, .none: 4.0
        }
        
        // Assume average weight of 70kg for now (should come from user profile)
        let weightKg = 70.0
        
        // Calories = METs × weight in kg × time in hours
        let hours = minutes / 60.0
        return metValue * weightKg * hours
    }
}