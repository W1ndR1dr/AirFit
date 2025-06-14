import Foundation
import SwiftData

/// Basic implementation of AI Workout Service
/// Wraps the base WorkoutServiceProtocol and adds AI-specific functionality
@MainActor
final class AIWorkoutService: AIWorkoutServiceProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "ai-workout-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // For @MainActor classes, we need to return a simple value
        // The actual state is tracked in _isConfigured
        true
    }
    
    private let workoutService: WorkoutServiceProtocol
    private let aiService: AIServiceProtocol
    private let exerciseDatabase: ExerciseDatabase
    private let personaService: PersonaService
    
    init(
        workoutService: WorkoutServiceProtocol, 
        aiService: AIServiceProtocol, 
        exerciseDatabase: ExerciseDatabase,
        personaService: PersonaService
    ) {
        self.workoutService = workoutService
        self.aiService = aiService
        self.exerciseDatabase = exerciseDatabase
        self.personaService = personaService
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: _isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: _isConfigured ? nil : "Service not configured",
            metadata: ["hasWorkoutService": "true"]
        )
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
        
        // Get available exercises based on equipment and muscles
        let availableExercises = await exerciseDatabase.filterExercises(
            equipment: equipment.isEmpty ? nil : equipment,
            primaryMuscles: targetMuscles.isEmpty ? nil : targetMuscles
        )
        
        // Build prompt for LLM
        let prompt = buildWorkoutPrompt(
            goal: goal,
            duration: duration,
            intensity: intensity,
            targetMuscles: targetMuscles,
            equipment: equipment,
            constraints: constraints,
            style: style,
            availableExercises: availableExercises
        )
        
        // Get user's persona for consistent coaching voice
        let persona = try await personaService.getActivePersona(for: user.id)
        
        // Create AI request with persona's system prompt
        let request = AIRequest(
            systemPrompt: persona.systemPrompt,
            messages: [
                AIChatMessage(
                    role: .system,
                    content: "Task context: Creating a customized workout plan. Focus on proper form, safety, and progression."
                ),
                AIChatMessage(
                    role: .user,
                    content: prompt
                )
            ],
            temperature: 0.7,
            stream: false,
            user: user.id.uuidString
        )
        
        // Send request and collect response
        var fullResponse = ""
        for try await chunk in aiService.sendRequest(request) {
            switch chunk {
            case .text(let text):
                fullResponse = text
            case .textDelta(let delta):
                fullResponse += delta
            case .done:
                break
            default:
                continue
            }
        }
        
        let response = fullResponse
        
        // Parse the response into exercises
        let plannedExercises = try parseWorkoutPlan(from: response, availableExercises: availableExercises)
        
        // Calculate estimated calories based on intensity and duration
        let caloriesPerMinute = getCaloriesPerMinute(intensity: intensity)
        let estimatedCalories = caloriesPerMinute * duration
        
        // Determine difficulty
        let difficulty = mapIntensityToDifficulty(intensity)
        
        return WorkoutPlanResult(
            id: UUID(),
            exercises: plannedExercises,
            estimatedCalories: estimatedCalories,
            estimatedDuration: duration,
            summary: "\(duration)-minute \(intensity) \(goal) workout",
            difficulty: difficulty,
            focusAreas: targetMuscles
        )
    }
    
    nonisolated func adaptPlan(
        _ plan: WorkoutPlanResult,
        feedback: String,
        adjustments: [String: Any],
        for user: User
    ) async throws -> WorkoutPlanResult {
        
        // Build adaptation prompt
        let formattedPlan = await MainActor.run {
            formatWorkoutPlan(plan)
        }
        let prompt = """
        Current workout plan:
        \(formattedPlan)
        
        User feedback: \(feedback)
        
        Please adjust the workout based on this feedback. Return a modified workout plan that addresses the user's concerns while maintaining the overall goal and duration.
        
        Format your response as a JSON array of exercises with this structure:
        [
          {
            "name": "Exercise Name",
            "sets": 3,
            "reps": "8-12",
            "restSeconds": 60,
            "notes": "Optional notes"
          }
        ]
        """
        
        // Get user's persona for consistent coaching voice
        let userId = user.id
        let persona = try await self.personaService.getActivePersona(for: userId)
        
        // Create AI request with persona's system prompt
        let request = AIRequest(
            systemPrompt: persona.systemPrompt,
            messages: [
                AIChatMessage(
                    role: .system,
                    content: "Task context: Adapting a workout plan based on user feedback. Maintain safety and progression."
                ),
                AIChatMessage(
                    role: .user,
                    content: prompt
                )
            ],
            temperature: 0.7,
            stream: false,
            user: user.id.uuidString
        )
        
        // Send request and collect response
        var fullResponse = ""
        for try await chunk in aiService.sendRequest(request) {
            switch chunk {
            case .text(let text):
                fullResponse = text
            case .textDelta(let delta):
                fullResponse += delta
            case .done:
                break
            default:
                continue
            }
        }
        
        let response = fullResponse
        
        // Parse the adapted plan
        let adaptedExercises = try await parseWorkoutPlan(from: response, availableExercises: nil)
        
        return WorkoutPlanResult(
            id: UUID(),
            exercises: adaptedExercises,
            estimatedCalories: plan.estimatedCalories,
            estimatedDuration: plan.estimatedDuration,
            summary: "\(plan.summary) (adapted)",
            difficulty: plan.difficulty,
            focusAreas: plan.focusAreas
        )
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
    
    // Template methods removed - AI-native workout generation
    
    // MARK: - Private Helper Methods
    
    private func buildWorkoutPrompt(
        goal: String,
        duration: Int,
        intensity: String,
        targetMuscles: [String],
        equipment: [String],
        constraints: String?,
        style: String,
        availableExercises: [ExerciseInfo]
    ) -> String {
        var prompt = """
        Create a \(duration)-minute \(intensity) workout plan for: \(goal)
        
        Requirements:
        - Workout style: \(style)
        - Target muscles: \(targetMuscles.isEmpty ? "full body" : targetMuscles.joined(separator: ", "))
        - Available equipment: \(equipment.isEmpty ? "bodyweight only" : equipment.joined(separator: ", "))
        """
        
        if let constraints = constraints {
            prompt += "\n- Special constraints: \(constraints)"
        }
        
        prompt += """
        
        
        Available exercises to choose from:
        \(availableExercises.prefix(30).map { "- \($0.name) (\($0.primaryMuscles.joined(separator: ", ")))" }.joined(separator: "\n"))
        
        Please create a workout plan using ONLY the exercises listed above. Format your response as a JSON array with this structure:
        [
          {
            "name": "Exercise Name (must match exactly from available list)",
            "sets": 3,
            "reps": "8-12",
            "restSeconds": 60,
            "notes": "Form tips or modifications"
          }
        ]
        
        Ensure the workout fits within \(duration) minutes including rest periods.
        """
        
        return prompt
    }
    
    private func parseWorkoutPlan(from response: String, availableExercises: [ExerciseInfo]?) throws -> [PlannedExercise] {
        // Try to extract JSON from the response
        let jsonPattern = #"\[[\s\S]*\]"#
        guard let range = response.range(of: jsonPattern, options: .regularExpression),
              let data = String(response[range]).data(using: .utf8) else {
            throw AppError.decodingError(underlying: NSError(domain: "AIWorkoutService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find JSON in AI response"]))
        }
        
        // Parse JSON
        struct ExerciseJSON: Codable {
            let name: String
            let sets: Int
            let reps: String
            let restSeconds: Int
            let notes: String?
        }
        
        let exercises = try JSONDecoder().decode([ExerciseJSON].self, from: data)
        
        // Convert to PlannedExercise
        return exercises.compactMap { json in
            // Validate exercise exists if we have the database
            if let available = availableExercises,
               !available.contains(where: { $0.name.lowercased() == json.name.lowercased() }) {
                AppLogger.warning("AI suggested unknown exercise: \(json.name)", category: .ai)
                return nil
            }
            
            return PlannedExercise(
                exerciseId: UUID(),
                name: json.name,
                sets: json.sets,
                reps: json.reps,
                restSeconds: json.restSeconds,
                notes: json.notes,
                alternatives: [] // Could enhance this later
            )
        }
    }
    
    private func formatWorkoutPlan(_ plan: WorkoutPlanResult) -> String {
        let exercises = plan.exercises.map { exercise in
            "- \(exercise.name): \(exercise.sets) sets x \(exercise.reps) reps (rest: \(exercise.restSeconds)s)"
        }.joined(separator: "\n")
        
        return """
        Duration: \(plan.estimatedDuration) minutes
        Exercises:
        \(exercises)
        """
    }
    
    private func getCaloriesPerMinute(intensity: String) -> Int {
        switch intensity.lowercased() {
        case "low", "easy":
            return 4
        case "moderate", "medium":
            return 6
        case "high", "hard":
            return 8
        case "very high", "extreme":
            return 10
        default:
            return 6
        }
    }
    
    private func mapIntensityToDifficulty(_ intensity: String) -> WorkoutPlanResult.WorkoutDifficulty {
        switch intensity.lowercased() {
        case "low", "easy":
            return .beginner
        case "moderate", "medium":
            return .intermediate
        case "high", "hard":
            return .advanced
        case "very high", "extreme":
            return .expert
        default:
            return .intermediate
        }
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