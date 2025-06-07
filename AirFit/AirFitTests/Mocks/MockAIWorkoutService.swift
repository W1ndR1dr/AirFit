import Foundation
@testable import AirFit

// MARK: - Mock AI Workout Service
// This is the AI-based workout generation service, different from MockWorkoutService

actor MockAIWorkoutService: AIWorkoutServiceProtocol {
    
    // MARK: - WorkoutServiceProtocol conformance (base protocol)
    func startWorkout(type: WorkoutType, user: User) async throws -> Workout {
        let workout = Workout(name: "AI Generated Workout")
        workout.workoutType = type.rawValue
        workout.plannedDate = Date()
        workout.user = user
        return workout
    }
    
    func pauseWorkout(_ workout: Workout) async throws {
        // Mock implementation
    }
    
    func resumeWorkout(_ workout: Workout) async throws {
        // Mock implementation
    }
    
    func endWorkout(_ workout: Workout) async throws {
        workout.completedDate = Date()
        workout.caloriesBurned = 250
    }
    
    func logExercise(_ exercise: Exercise, in workout: Workout) async throws {
        workout.exercises.append(exercise)
    }
    
    func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout] {
        return []
    }
    
    func getWorkoutTemplates() async throws -> [WorkoutTemplate] {
        return []
    }
    
    func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws {
        // Mock implementation
    }
    
    // MARK: - AIWorkoutServiceProtocol specific methods
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

        // Simulate processing time
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        let exercises = generateExercises(
            goal: goal,
            duration: duration,
            targetMuscles: targetMuscles,
            equipment: equipment,
            style: style
        )

        let estimatedCalories = calculateEstimatedCalories(
            exercises: exercises,
            duration: duration,
            intensity: intensity
        )
        
        let difficulty: WorkoutPlanResult.WorkoutDifficulty = switch intensity {
        case "light": .beginner
        case "moderate": .intermediate
        case "high": .advanced
        case "extreme": .expert
        default: .intermediate
        }
        
        let focusAreas = targetMuscles // Use the input target muscles as focus areas

        return WorkoutPlanResult(
            id: UUID(),
            exercises: exercises,
            estimatedCalories: estimatedCalories,
            estimatedDuration: duration,
            summary: generateWorkoutSummary(goal: goal, exercises: exercises, duration: duration),
            difficulty: difficulty,
            focusAreas: focusAreas
        )
    }
    
    nonisolated func adaptPlan(
        _ plan: WorkoutPlanResult,
        feedback: String,
        adjustments: [String: Any]
    ) async throws -> WorkoutPlanResult {
        // Simple mock: return the same plan with updated summary
        return WorkoutPlanResult(
            id: plan.id,
            exercises: plan.exercises,
            estimatedCalories: plan.estimatedCalories,
            estimatedDuration: plan.estimatedDuration,
            summary: plan.summary + " (adapted based on feedback)",
            difficulty: plan.difficulty,
            focusAreas: plan.focusAreas
        )
    }

    private func generateExercises(
        goal: String,
        duration: Int,
        targetMuscles: [String],
        equipment: [String],
        style: String
    ) -> [PlannedExercise] {

        let exerciseCount = min(max(duration / 8, 3), 8) // 3-8 exercises based on duration
        var exercises: [PlannedExercise] = []

        let exerciseDatabase = getExerciseDatabase(equipment: equipment)
        let filteredExercises = exerciseDatabase.filter { exercise in
            targetMuscles.contains("full_body") ||
                !Set(exercise.muscleGroups).isDisjoint(with: Set(targetMuscles))
        }

        for i in 0..<exerciseCount {
            let exercise = filteredExercises[i % filteredExercises.count]
            let (sets, reps) = getSetsAndReps(goal: goal, style: style, exerciseIndex: i)
            let restSeconds = getRestTime(goal: goal, style: style)

            exercises.append(PlannedExercise(
                exerciseId: UUID(),
                name: exercise.name,
                sets: sets,
                reps: reps,
                restSeconds: restSeconds,
                notes: "Target muscles: \(exercise.muscleGroups.joined(separator: ", "))",
                alternatives: []
            ))
        }

        return exercises
    }

    private func getExerciseDatabase(equipment: [String]) -> [(name: String, muscleGroups: [String])] {
        let bodyweightExercises = [
            ("Push-ups", ["chest", "triceps", "shoulders"]),
            ("Squats", ["quadriceps", "glutes", "core"]),
            ("Lunges", ["quadriceps", "glutes", "hamstrings"]),
            ("Plank", ["core", "shoulders"]),
            ("Burpees", ["full_body"]),
            ("Mountain Climbers", ["core", "shoulders", "legs"]),
            ("Jumping Jacks", ["full_body"]),
            ("Pull-ups", ["back", "biceps"])
        ]

        let dumbbellExercises = [
            ("Dumbbell Bench Press", ["chest", "triceps", "shoulders"]),
            ("Dumbbell Rows", ["back", "biceps"]),
            ("Dumbbell Squats", ["quadriceps", "glutes"]),
            ("Dumbbell Shoulder Press", ["shoulders", "triceps"]),
            ("Dumbbell Deadlifts", ["hamstrings", "glutes", "back"]),
            ("Dumbbell Bicep Curls", ["biceps"]),
            ("Dumbbell Lunges", ["quadriceps", "glutes"])
        ]

        let barbellExercises = [
            ("Barbell Squats", ["quadriceps", "glutes", "core"]),
            ("Deadlifts", ["hamstrings", "glutes", "back", "core"]),
            ("Bench Press", ["chest", "triceps", "shoulders"]),
            ("Barbell Rows", ["back", "biceps"]),
            ("Overhead Press", ["shoulders", "triceps", "core"])
        ]

        var availableExercises = bodyweightExercises

        if equipment.contains("dumbbells") || equipment.contains("full_gym") {
            availableExercises.append(contentsOf: dumbbellExercises)
        }

        if equipment.contains("barbell") || equipment.contains("full_gym") {
            availableExercises.append(contentsOf: barbellExercises)
        }

        return availableExercises
    }

    private func getSetsAndReps(goal: String, style: String, exerciseIndex: Int) -> (sets: Int, reps: String) {
        switch goal {
        case "strength":
            return (4, "3-5")
        case "hypertrophy":
            return (3, "8-12")
        case "endurance":
            return (3, "15-20")
        case "power":
            return (4, "3-6")
        case "mobility":
            return (2, "10-15")
        case "active_recovery":
            return (2, "8-10")
        default:
            return (3, "8-12")
        }
    }

    private func getRestTime(goal: String, style: String) -> Int {
        if style == "circuit" || style == "hiit" {
            return 30
        }

        switch goal {
        case "strength", "power":
            return 120
        case "hypertrophy":
            return 90
        case "endurance", "active_recovery":
            return 60
        default:
            return 75
        }
    }

    private func calculateEstimatedCalories(
        exercises: [PlannedExercise],
        duration: Int,
        intensity: String
    ) -> Int {
        let baseCaloriesPerMinute: Double = switch intensity {
        case "light": 4.0
        case "moderate": 6.0
        case "high": 8.0
        default: 6.0
        }

        return Int(Double(duration) * baseCaloriesPerMinute)
    }

    private func generateWorkoutSummary(
        goal: String,
        exercises: [PlannedExercise],
        duration: Int
    ) -> String {
        // Extract muscle groups from notes since PlannedExercise doesn't have muscleGroups property
        let muscleGroups = exercises.compactMap { exercise -> [String]? in
            guard let notes = exercise.notes,
                  let range = notes.range(of: "Target muscles: ") else { return nil }
            let musclesString = String(notes[range.upperBound...])
            return musclesString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }.flatMap { $0 }
        
        let primaryMuscles = Set(muscleGroups).prefix(3).joined(separator: ", ")
        return "A \(duration)-minute \(goal) workout targeting \(primaryMuscles) with \(exercises.count) exercises."
    }
    
    // MARK: - Reset
    
    func reset() {
        // This is an actor, so no state to reset
        // All methods return fresh data each time
    }
}