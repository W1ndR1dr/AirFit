import Foundation
import SwiftData

// MARK: - Workout Analysis Engine
@MainActor
final class WorkoutAnalysisEngine {
    // MARK: - Dependencies
    private let aiService: AIServiceProtocol

    // MARK: - Initialization
    init(aiService: AIServiceProtocol) {
        self.aiService = aiService
    }

    // MARK: - Public Methods

    /// Generates AI-powered post-workout analysis
    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
        // Build analysis prompt
        let analysisPrompt = buildWorkoutAnalysisPrompt(request)

        // Create AI request for analysis
        let aiRequest = AIRequest(
            systemPrompt: "You are a fitness coach providing post-workout analysis. Be encouraging, specific, and actionable.",
            messages: [
                AIChatMessage(
                    role: .user,
                    content: analysisPrompt,
                    timestamp: Date()
                )
            ],
            functions: [],
            user: "workout-analysis"
        )

        // Get AI response
        var analysisResult = ""

        do {
            for try await response in aiService.sendRequest(aiRequest) {
                switch response {
                case .text(let text), .textDelta(let text):
                    analysisResult += text
                default:
                    break
                }
            }
        } catch {
            AppLogger.error("Failed to analyze workout: \(error)", category: .ai)
        }

        return analysisResult.isEmpty ? "Great workout! Keep up the excellent work." : analysisResult
    }

    // MARK: - Private Methods

    private func buildWorkoutAnalysisPrompt(_ request: PostWorkoutAnalysisRequest) -> String {
        let workout = request.workout
        let recentWorkouts = request.recentWorkouts

        var prompt = "Analyze this workout:\n\n"
        prompt += "Workout: \(workout.workoutTypeEnum?.displayName ?? workout.workoutType)\n"
        prompt += "Duration: \(workout.formattedDuration ?? "Unknown")\n"
        prompt += "Exercises: \(workout.exercises.count)\n"

        if let calories = workout.caloriesBurned, calories > 0 {
            prompt += "Calories: \(Int(calories))\n"
        }

        // Add exercise details
        for exercise in workout.exercises {
            prompt += "\n\(exercise.name): \(exercise.sets.count) sets"
            if let totalVolume = exercise.totalVolume, totalVolume > 0 {
                prompt += ", \(Int(totalVolume))kg total volume"
            }
        }

        // Add context from recent workouts
        if !recentWorkouts.isEmpty {
            prompt += "\n\nRecent workout context:\n"
            for recentWorkout in recentWorkouts.prefix(3) {
                prompt += "- \(recentWorkout.workoutTypeEnum?.displayName ?? recentWorkout.workoutType)"
                if let duration = recentWorkout.formattedDuration {
                    prompt += " (\(duration))"
                }
                prompt += "\n"
            }
        }

        prompt += "\nProvide encouraging analysis with specific insights and actionable recommendations."

        return prompt
    }
}

// MARK: - Supporting Types
struct PostWorkoutAnalysisRequest: Sendable {
    let workout: Workout
    let recentWorkouts: [Workout]
    let userGoals: [String]?
    let recoveryData: RecoveryData?

    init(workout: Workout, recentWorkouts: [Workout] = [], userGoals: [String]? = nil, recoveryData: RecoveryData? = nil) {
        self.workout = workout
        self.recentWorkouts = recentWorkouts
        self.userGoals = userGoals
        self.recoveryData = recoveryData
    }
}

struct RecoveryData: Sendable {
    let sleepHours: Double?
    let restingHeartRate: Int?
    let hrv: Double?
    let subjectedEnergyLevel: Int? // 1-10 scale
}
