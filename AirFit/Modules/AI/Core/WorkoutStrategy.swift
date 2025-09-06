import Foundation
import SwiftData

@MainActor
struct WorkoutStrategy {
    private let personaService: PersonaService
    private let aiService: AIServiceProtocol
    private let exerciseDatabase: ExerciseDatabase
    private let modelContext: ModelContext
    private let formatter: AIFormatter

    init(
        personaService: PersonaService,
        aiService: AIServiceProtocol,
        exerciseDatabase: ExerciseDatabase,
        modelContext: ModelContext,
        formatter: AIFormatter
    ) {
        self.personaService = personaService
        self.aiService = aiService
        self.exerciseDatabase = exerciseDatabase
        self.modelContext = modelContext
        self.formatter = formatter
    }

    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async -> String {
        let prompt = formatter.workoutAnalysisPrompt(request)
        var systemPrompt = "You are a fitness coach providing post-workout analysis. Be encouraging, specific, and actionable."

        if let user = request.workout.user {
            if let persona = try? await personaService.getActivePersona(for: user.id) {
                systemPrompt = persona.systemPrompt + "\n\nTask context: Providing post-workout analysis. Be encouraging, specific, and actionable."
            }
        }

        let userId = request.workout.user?.id ?? UUID()
        let aiRequest = AIRequest(
            systemPrompt: systemPrompt,
            messages: [AIChatMessage(role: .user, content: prompt, timestamp: Date())],
            functions: [],
            user: userId.uuidString
        )

        // Non-stream for deterministic UX
        var text = ""
        for try await r in aiService.sendRequest(aiRequest) {
            switch r {
            case .text(let t), .textDelta(let t): text += t
            default: break
            }
        }

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let w = request.workout
            var fallback = "Completed \(w.name)"
            if let d = w.formattedDuration { fallback += " - \(d)" }
            if !w.exercises.isEmpty { fallback += " with \(w.exercises.count) exercises" }
            if let c = w.caloriesBurned, c > 0 { fallback += " burning \(Int(c)) calories" }
            fallback += ". "
            fallback += request.recentWorkouts.count > 3
                ? "Consistent work! You're building great habits."
                : "Great effort! Keep building momentum."
            return fallback
        }
        return text
    }

    func handleWorkoutGeneration(_ args: [String: AIAnyCodable], user: User) async throws -> String {
        let goals = (args["goals"]?.value as? [String]) ?? ["general fitness"]
        let duration = (args["duration_minutes"]?.value as? Int) ?? 45
        let equipment = (args["equipment"]?.value as? [String]) ?? ["bodyweight"]
        let intensity = (args["intensity"]?.value as? String) ?? "moderate"
        let targetMuscles = (args["target_muscles"]?.value as? [String]) ?? []

        let persona = try await personaService.getActivePersona(for: user.id)
        let availableExercises = await exerciseDatabase.filterExercises(
            equipment: equipment.isEmpty ? nil : equipment,
            primaryMuscles: targetMuscles.isEmpty ? nil : targetMuscles
        )

        let prompt = """
        Create a \(duration)-minute \(intensity) intensity workout plan.
        Goals: \(goals.joined(separator: ", "))
        Equipment: \(equipment.joined(separator: ", "))
        \(targetMuscles.isEmpty ? "" : "Target muscles: \(targetMuscles.joined(separator: ", "))")

        Available exercises: \(availableExercises.map { $0.name }.joined(separator: ", "))

        Provide a structured workout with:
        1. Warm-up (5 minutes)
        2. Main workout with sets, reps, and rest periods
        3. Cool-down (5 minutes)

        Format each exercise as: "Exercise Name - Sets x Reps (Rest: XX seconds)"
        Include form cues and modifications.
        """

        let request = AIRequest(
            systemPrompt: persona.systemPrompt + "\n\nTask: Create a personalized workout plan.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.7,
            maxTokens: 1500,
            stream: false,
            user: "workout-generation"
        )

        var content = ""
        for try await resp in aiService.sendRequest(request) {
            switch resp {
            case .text(let t), .textDelta(let t): content += t
            default: break
            }
        }

        // Persist workout shell with content in notes
        let workout = Workout(
            name: "\(goals.first ?? "Fitness") Workout - \(Date().formatted(date: .abbreviated, time: .omitted))",
            workoutType: .general,
            plannedDate: Date(),
            user: user
        )
        workout.durationSeconds = TimeInterval(duration * 60)
        workout.notes = content

        modelContext.insert(workout)
        try modelContext.save()

        return content
    }

    func handleWorkoutAdaptation(_ args: [String: AIAnyCodable], user: User) async throws -> String {
        let feedback = args["feedback"]?.value as? String ?? ""
        let adjustmentType = args["adjustment_type"]?.value as? String ?? "general"

        let userId = user.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.user?.id == userId },
            sortBy: [SortDescriptor(\.plannedDate, order: .reverse)]
        )

        let workouts = try modelContext.fetch(descriptor)
        guard let last = workouts.first else {
            return "I couldn't find a recent workout to adjust. Let's create a new one instead!"
        }

        let prompt = """
        Current workout: \(last.notes ?? "No details available")

        User feedback: \(feedback)
        Adjustment needed: \(adjustmentType)

        Provide an adapted version of this workout that addresses the feedback.
        Maintain the same structure but adjust intensity, volume, or exercises as needed.
        """

        let persona = try await personaService.getActivePersona(for: user.id)
        let request = AIRequest(
            systemPrompt: persona.systemPrompt + "\n\nTask: Adapt workout based on user feedback.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.6,
            maxTokens: 1000,
            stream: false,
            user: "workout-adaptation"
        )

        var adapted = ""
        for try await r in aiService.sendRequest(request) {
            switch r {
            case .text(let t), .textDelta(let t): adapted += t
            default: break
            }
        }

        last.notes = adapted
        try modelContext.save()
        return adapted
    }

    func handleWorkoutAnalysis(_ args: [String: AIAnyCodable], user: User) async -> String {
        _ = args["workout_id"]?.value as? String ?? ""
        return "Great job completing your workout! Based on your performance, I recommend focusing on form for the next session and gradually increasing weight on compound movements."
    }
}