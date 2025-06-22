import Foundation
import SwiftData

// MARK: - PersonaEngine
@MainActor
final class PersonaEngine {

    // MARK: - Cached Components (Performance Optimization)
    private static var cachedPromptTemplate: String?
    private var cachedPersonaInstructions: [UUID: String] = [:]

    // MARK: - Public Methods

    /// Build optimized system prompt with unique persona and goal synthesis
    func buildSystemPrompt(
        personaProfile: PersonaProfile,
        userGoal: String,
        userContext: String,
        goalSynthesis: GoalSynthesis?,
        healthContext: HealthContextSnapshot,
        conversationHistory: [AIChatMessage],
        availableFunctions: [AIFunctionDefinition]
    ) throws -> String {

        let startTime = CFAbsoluteTimeGetCurrent()

        // Get template (cached after first use)
        let template = Self.cachedPromptTemplate ?? Self.promptTemplate()
        if Self.cachedPromptTemplate == nil {
            Self.cachedPromptTemplate = template
        }

        // Get persona with context adaptations
        let personaInstructions = cachedPersonaInstructions[personaProfile.id] ?? adaptPersona(personaProfile, for: healthContext)
        if cachedPersonaInstructions[personaProfile.id] == nil {
            cachedPersonaInstructions[personaProfile.id] = personaProfile.systemPrompt
        }

        // Convert to JSON
        let healthContextJSON = try self.healthContext(healthContext)
        let conversationJSON = try self.conversationHistory(conversationHistory)
        let functionsJSON = try self.functionList(availableFunctions)
        let goalSynthesisJSON = try self.goalSynthesis(goalSynthesis)

        // Get current time efficiently
        let currentDateTime = ISO8601DateFormatter().string(from: Date())

        // Assemble final prompt with replacements
        let prompt = template
            .replacingOccurrences(of: "{{PERSONA_INSTRUCTIONS}}", with: personaInstructions)
            .replacingOccurrences(of: "{{USER_GOAL}}", with: userGoal)
            .replacingOccurrences(of: "{{USER_CONTEXT}}", with: userContext)
            .replacingOccurrences(of: "{{GOAL_SYNTHESIS_JSON}}", with: goalSynthesisJSON)
            .replacingOccurrences(of: "{{HEALTH_CONTEXT_JSON}}", with: healthContextJSON)
            .replacingOccurrences(of: "{{CONVERSATION_HISTORY_JSON}}", with: conversationJSON)
            .replacingOccurrences(of: "{{AVAILABLE_FUNCTIONS_JSON}}", with: functionsJSON)
            .replacingOccurrences(of: "{{CURRENT_DATETIME_UTC}}", with: currentDateTime)

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let estimatedTokens = prompt.count / 4 // Rough estimate: 4 chars per token

        AppLogger.info(
            "Built optimized persona prompt: \(estimatedTokens) tokens in \(Int(duration * 1_000))ms (persona: \(personaProfile.name))",
            category: .ai
        )

        // Warning if over target (should be <600 tokens with new system)
        if estimatedTokens > 600 {
            AppLogger.warning("Prompt exceeds target: \(estimatedTokens) tokens", category: .ai)
        }

        if estimatedTokens > 1_000 {
            throw PersonaEngineError.promptTooLong(estimatedTokens)
        }

        return prompt
    }


    // MARK: - Private Methods
    
    private func adaptPersona(_ persona: PersonaProfile, for healthContext: HealthContextSnapshot) -> String {
        var adaptations: [String] = []
        
        // Energy level adaptations
        if let energy = healthContext.subjectiveData.energyLevel {
            switch energy {
            case 1...2:
                adaptations.append("User has low energy. Be extra supportive and gentle.")
            case 4...5:
                adaptations.append("User has high energy. Match their enthusiasm.")
            default:
                break
            }
        }
        
        // Stress level adaptations
        if let stress = healthContext.subjectiveData.stress {
            switch stress {
            case 4...5:
                adaptations.append("User reports high stress. Prioritize stress management.")
            case 1...2:
                adaptations.append("User reports low stress. Good time for challenges.")
            default:
                break
            }
        }
        
        // Time of day adaptations
        switch healthContext.environment.timeOfDay {
        case .earlyMorning, .morning:
            adaptations.append("It's morning. Keep messages energetic and action-oriented.")
        case .evening, .night:
            adaptations.append("It's evening. Keep tone calmer and reflective.")
        default:
            break
        }
        
        if adaptations.isEmpty {
            return persona.systemPrompt
        } else {
            return """
            \(persona.systemPrompt)
            
            ## Current Context Adaptations:
            \(adaptations.joined(separator: "\n"))
            """
        }
    }

    private static func promptTemplate() -> String {
        return """
        # AirFit Coach System Instructions

        ## Core Identity
        You are an AirFit Coach with the following persona:
        {{PERSONA_INSTRUCTIONS}}

        ## User Goal
        Primary objective: {{USER_GOAL}}

        ## User Context
        {{USER_CONTEXT}}

        ## Goal Strategy
        {{GOAL_SYNTHESIS_JSON}}

        ## Current Health Data
        {{HEALTH_CONTEXT_JSON}}

        ## Recent Conversation
        {{CONVERSATION_HISTORY_JSON}}

        ## Available Functions
        {{AVAILABLE_FUNCTIONS_JSON}}

        ## Critical Rules
        - Never break character or mention you're an AI
        - Use health data to inform your coaching style naturally
        - Adapt your energy/intensity based on user's current state
        - Current time: {{CURRENT_DATETIME_UTC}}

        Respond as this coach persona would, using the health data and context provided.
        """
    }


    private func healthContext(_ healthContext: HealthContextSnapshot) throws -> String {
        // Build minimal, essential health context for token efficiency
        var compactContext: [String: Any] = [:]

        // Subjective data (most important for persona adaptation)
        if let energy = healthContext.subjectiveData.energyLevel {
            compactContext["energy"] = energy
        }
        if let stress = healthContext.subjectiveData.stress {
            compactContext["stress"] = stress
        }
        if let mood = healthContext.subjectiveData.mood {
            compactContext["mood"] = mood
        }

        // Sleep quality
        if let quality = healthContext.sleep.lastNight?.quality {
            compactContext["sleep_quality"] = quality.rawValue
        }

        // Activity metrics (key indicators only)
        if let steps = healthContext.activity.steps {
            compactContext["steps"] = steps
        }
        if let exerciseMinutes = healthContext.activity.exerciseMinutes {
            compactContext["exercise_min"] = exerciseMinutes
        }

        // Workout context
        if let workoutContext = healthContext.appContext.workoutContext {
            compactContext["streak_days"] = workoutContext.streakDays
            compactContext["recovery_status"] = workoutContext.recoveryStatus.rawValue
        }

        // Recovery trend
        if let recoveryTrend = healthContext.trends.recoveryTrend {
            compactContext["recovery_trend"] = recoveryTrend.rawValue
        }

        // Time context
        compactContext["time_of_day"] = healthContext.environment.timeOfDay.rawValue

        let data = try JSONSerialization.data(withJSONObject: compactContext)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private func conversationHistory(_ history: [AIChatMessage]) throws -> String {
        // Include only last 5 messages to save tokens
        let recentHistory = Array(history.suffix(5)).map { message in
            [
                "role": message.role.rawValue,
                "content": String(message.content.prefix(200))  // Truncate long messages
            ]
        }

        let data = try JSONSerialization.data(withJSONObject: recentHistory)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private func functionList(_ functions: [AIFunctionDefinition]) throws -> String {
        // Include only function names and brief descriptions
        let compactFunctions = functions.map { function in
            [
                "name": function.name,
                "description": String(function.description.prefix(100))  // Brief descriptions
            ]
        }

        let data = try JSONSerialization.data(withJSONObject: compactFunctions)
        return String(data: data, encoding: .utf8) ?? "[]"
    }
    
    private func goalSynthesis(_ goalSynthesis: GoalSynthesis?) throws -> String {
        guard let synthesis = goalSynthesis else {
            return "{}"
        }
        
        // Build compact goal synthesis for token efficiency
        let compactSynthesis: [String: Any] = [
            "strategy": synthesis.unifiedStrategy,
            "focus": synthesis.coachingFocus,
            "timeline": synthesis.timeline,
            "challenges": synthesis.challenges,
            "hooks": synthesis.motivationalHooks
        ]
        
        let data = try JSONSerialization.data(withJSONObject: compactSynthesis)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// MARK: - PersonaEngine Errors
enum PersonaEngineError: LocalizedError {
    case promptTooLong(Int)
    case invalidProfile
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .promptTooLong(let tokens):
            return "System prompt too long: ~\(tokens) tokens"
        case .invalidProfile:
            return "Invalid user profile data"
        case .encodingFailed:
            return "Failed to encode profile data to JSON"
        }
    }
}

// MARK: - LLM-First Persona System
//
// ✅ CURRENT ARCHITECTURE:
// - PersonaProfile: Rich, unique personas generated by LLM
// - No preset archetypes or modes - each persona is completely unique
// - Context-aware adaptation based on health data and user state
// - Efficient token usage through compact prompt building
// - Performance caching for templates and instructions
