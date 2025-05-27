import Foundation
import SwiftData

// MARK: - PersonaProfile Type Alias
typealias PersonaProfile = UserProfileJsonBlob

// MARK: - PersonaEngine
@MainActor
final class PersonaEngine {
    // MARK: - Properties
    private let systemPromptTemplate: String

    // MARK: - Initialization
    init() {
        self.systemPromptTemplate = Self.buildSystemPromptTemplate()
    }

    // MARK: - Private Static Methods
    private static func buildSystemPromptTemplate() -> String {
        return """
        ## I. CORE IDENTITY & PRIME DIRECTIVE
        You are "AirFit Coach," a bespoke AI fitness and wellness coach. Your sole purpose is to embody and enact the unique coaching persona defined by the user, leveraging their comprehensive health data to provide insightful, motivational, and actionable guidance.

        **Critical Rule: You MUST always interact as this specific coach persona. Never break character. Never mention you are an AI or a language model. Your responses should feel as if they are coming from a dedicated, human coach who deeply understands the user.**

        ## II. USER-DEFINED PERSONA BLUEPRINT (INJECTED VIA API)
        This JSON object is the absolute and non-negotiable source of truth for YOUR personality, communication style, and coaching approach for THIS user. Internalize and consistently apply these characteristics in every interaction.

        {{USER_PROFILE_JSON}}

        ## III. DYNAMIC CONTEXT (INJECTED PER INTERACTION VIA API)
        For each user message, you will receive the following to inform your response:

        HealthContextSnapshot:
        {{HEALTH_CONTEXT_JSON}}

        **Workout Intelligence Context (Last 7 Days):**
        Use this comprehensive workout data to provide personalized, contextually-aware coaching:
        - Reference specific recent exercises and performance for targeted feedback
        - Consider workout streak and recovery status for motivation and readiness assessment
        - Factor muscle group balance into workout recommendations
        - Leverage intensity trends for recovery and progression guidance
        - Use upcoming planned workouts for accountability and preparation coaching

        ConversationHistory:
        {{CONVERSATION_HISTORY_JSON}}

        CurrentDateTimeUTC:
        {{CURRENT_DATETIME_UTC}}

        UserTimeZone:
        {{USER_TIMEZONE}}

        ## IV. HIGH-VALUE FUNCTION CALLING CAPABILITIES
        You can request the execution of specific in-app functions when your intelligent analysis indicates it's the most effective way to assist the user.

        If you decide a function call is necessary, your response MUST be ONLY the following JSON object structure:

        {
          "action": "function_call",
          "function_name": "NameOfTheFunctionToCall",
          "parameters": {
            "paramName1": "value1",
            "paramName2": "value2"
          }
        }

        Available Functions:
        {{AVAILABLE_FUNCTIONS_JSON}}

        ## V. CORE BEHAVIORAL & COMMUNICATION GUIDELINES
        1. Persona Primacy: Your persona is paramount. Every word must align.
        2. Contextual Synthesis: Seamlessly weave health data into responses.
        3. Goal-Oriented: Always keep the user's goal in mind.
        4. Proactive (Within Persona): Offer advice based on your style blend.
        5. Empathy and Safety: Advise medical consultation for health concerns.
        6. Clarity and Conciseness: Be clear and appropriately detailed.
        7. Positive Framing: Use empowering language per your persona.
        8. Respect Boundaries: Honor sleep windows and preferences.
        9. Markdown for Readability: Use formatting sparingly but effectively.

        ## VI. RESPONSE GENERATION
        Your primary output is conversational text. Strive for responses that are natural, engaging, and consistently reflect the unique AI persona you are embodying for this user.
        """
    }

    // MARK: - Public Methods
    func buildSystemPrompt(
        userProfile: PersonaProfile,
        healthContext: HealthContextSnapshot,
        conversationHistory: [ChatMessage],
        availableFunctions: [AIFunctionDefinition]
    ) throws -> String {
        // Prepare JSON representations
        let userProfileJSON = try JSONEncoder.airFitEncoder.encodeToString(userProfile)
        let healthContextJSON = try JSONEncoder.airFitEncoder.encodeToString(healthContext)

        // Convert ChatMessage to simplified format for context
        let simplifiedHistory = conversationHistory.suffix(20).map { message in
            [
                "role": message.role,
                "content": message.content,
                "timestamp": ISO8601DateFormatter().string(from: message.timestamp)
            ]
        }
        let conversationJSON = try JSONEncoder.airFitEncoder.encodeToString(simplifiedHistory)
        let functionsJSON = try JSONEncoder.airFitEncoder.encodeToString(availableFunctions)

        // Get current time info
        let now = Date()
        let formatter = ISO8601DateFormatter()
        let utcString = formatter.string(from: now)

        // Build the prompt
        let prompt = systemPromptTemplate
            .replacingOccurrences(of: "{{USER_PROFILE_JSON}}", with: userProfileJSON)
            .replacingOccurrences(of: "{{HEALTH_CONTEXT_JSON}}", with: healthContextJSON)
            .replacingOccurrences(of: "{{CONVERSATION_HISTORY_JSON}}", with: conversationJSON)
            .replacingOccurrences(of: "{{CURRENT_DATETIME_UTC}}", with: utcString)
            .replacingOccurrences(of: "{{USER_TIMEZONE}}", with: userProfile.timezone)
            .replacingOccurrences(of: "{{AVAILABLE_FUNCTIONS_JSON}}", with: functionsJSON)

        // Validate prompt length
        let estimatedTokens = prompt.count / 4 // Rough estimate: 4 chars per token
        if estimatedTokens > 8_000 {
            AppLogger.warning("System prompt may be too long: ~\(estimatedTokens) tokens", category: .ai)
            throw PersonaEngineError.promptTooLong(estimatedTokens)
        }

        AppLogger.info("Built system prompt with ~\(estimatedTokens) tokens", category: .ai)
        return prompt
    }

    func adjustPersonaForContext(
        baseProfile: PersonaProfile,
        healthContext: HealthContextSnapshot
    ) -> PersonaProfile {
        var adjustedBlend = baseProfile.blend

        adjustedBlend = adjustForEnergyLevel(adjustedBlend, healthContext: healthContext)
        adjustedBlend = adjustForStressLevel(adjustedBlend, healthContext: healthContext)
        adjustedBlend = adjustForTimeOfDay(adjustedBlend, healthContext: healthContext)
        adjustedBlend = adjustForSleepQuality(adjustedBlend, healthContext: healthContext)
        adjustedBlend = adjustForRecoveryTrend(adjustedBlend, healthContext: healthContext)
        adjustedBlend = adjustForWorkoutContext(adjustedBlend, healthContext: healthContext)

        return PersonaProfile(
            lifeContext: baseProfile.lifeContext,
            goal: baseProfile.goal,
            blend: adjustedBlend,
            engagementPreferences: baseProfile.engagementPreferences,
            sleepWindow: baseProfile.sleepWindow,
            motivationalStyle: baseProfile.motivationalStyle,
            timezone: baseProfile.timezone,
            baselineModeEnabled: baseProfile.baselineModeEnabled
        )
    }

    // MARK: - Private Adjustment Methods
    private func adjustForEnergyLevel(_ blend: Blend, healthContext: HealthContextSnapshot) -> Blend {
        guard let energy = healthContext.subjectiveData.energyLevel, energy <= 2 else { return blend }

        var adjustedBlend = blend
        adjustedBlend.encouragingEmpathetic = min(adjustedBlend.encouragingEmpathetic + 0.15, 1.0)
        adjustedBlend.authoritativeDirect = max(adjustedBlend.authoritativeDirect - 0.10, 0.0)
        adjustedBlend.playfullyProvocative = max(adjustedBlend.playfullyProvocative - 0.05, 0.0)
        adjustedBlend.normalize()

        AppLogger.debug("Adjusted persona for low energy: more empathetic", category: .ai)
        return adjustedBlend
    }

    private func adjustForStressLevel(_ blend: Blend, healthContext: HealthContextSnapshot) -> Blend {
        guard let stress = healthContext.subjectiveData.stress, stress >= 4 else { return blend }

        var adjustedBlend = blend
        adjustedBlend.encouragingEmpathetic = min(adjustedBlend.encouragingEmpathetic + 0.10, 1.0)
        adjustedBlend.playfullyProvocative = max(adjustedBlend.playfullyProvocative - 0.10, 0.0)
        adjustedBlend.normalize()

        AppLogger.debug("Adjusted persona for high stress: more supportive", category: .ai)
        return adjustedBlend
    }

    private func adjustForTimeOfDay(_ blend: Blend, healthContext: HealthContextSnapshot) -> Blend {
        var adjustedBlend = blend

        switch healthContext.environment.timeOfDay {
        case .earlyMorning, .morning:
            adjustedBlend.authoritativeDirect = min(adjustedBlend.authoritativeDirect + 0.05, 1.0)
            adjustedBlend.normalize()

        case .evening, .night:
            adjustedBlend.playfullyProvocative = max(adjustedBlend.playfullyProvocative - 0.10, 0.0)
            adjustedBlend.encouragingEmpathetic = min(adjustedBlend.encouragingEmpathetic + 0.05, 1.0)
            adjustedBlend.normalize()
            AppLogger.debug("Adjusted persona for evening: more calm", category: .ai)

        default:
            break
        }

        return adjustedBlend
    }

    private func adjustForSleepQuality(_ blend: Blend, healthContext: HealthContextSnapshot) -> Blend {
        guard let sleepQuality = healthContext.sleep.lastNight?.quality else { return blend }

        var adjustedBlend = blend

        switch sleepQuality {
        case .poor, .fair:
            adjustedBlend.encouragingEmpathetic = min(adjustedBlend.encouragingEmpathetic + 0.10, 1.0)
            adjustedBlend.authoritativeDirect = max(adjustedBlend.authoritativeDirect - 0.05, 0.0)
            adjustedBlend.normalize()
            AppLogger.debug("Adjusted persona for poor sleep: more understanding", category: .ai)

        case .excellent:
            adjustedBlend.authoritativeDirect = min(adjustedBlend.authoritativeDirect + 0.05, 1.0)
            adjustedBlend.normalize()

        default:
            break
        }

        return adjustedBlend
    }

    private func adjustForRecoveryTrend(_ blend: Blend, healthContext: HealthContextSnapshot) -> Blend {
        guard let recoveryTrend = healthContext.trends.recoveryTrend else { return blend }

        var adjustedBlend = blend

        switch recoveryTrend {
        case .needsRecovery, .overreaching:
            adjustedBlend.encouragingEmpathetic = min(adjustedBlend.encouragingEmpathetic + 0.15, 1.0)
            adjustedBlend.authoritativeDirect = max(adjustedBlend.authoritativeDirect - 0.10, 0.0)
            adjustedBlend.normalize()
            AppLogger.debug("Adjusted persona for recovery needs: more supportive", category: .ai)

        case .wellRecovered:
            adjustedBlend.authoritativeDirect = min(adjustedBlend.authoritativeDirect + 0.05, 1.0)
            adjustedBlend.playfullyProvocative = min(adjustedBlend.playfullyProvocative + 0.05, 1.0)
            adjustedBlend.normalize()

        default:
            break
        }

        return adjustedBlend
    }

    private func adjustForWorkoutContext(_ blend: Blend, healthContext: HealthContextSnapshot) -> Blend {
        guard let workoutContext = healthContext.appContext.workoutContext else { return blend }

        var adjustedBlend = blend

        // Adjust based on workout streak for motivation
        switch workoutContext.streakDays {
        case 0:
            // No recent workouts - be more encouraging and motivational
            adjustedBlend.encouragingEmpathetic = min(adjustedBlend.encouragingEmpathetic + 0.10, 1.0)
            adjustedBlend.authoritativeDirect = min(adjustedBlend.authoritativeDirect + 0.05, 1.0)
            adjustedBlend.normalize()
            AppLogger.debug("Adjusted persona for no workout streak: more motivational", category: .ai)

        case 1...3:
            // Building momentum - be supportive and encouraging
            adjustedBlend.encouragingEmpathetic = min(adjustedBlend.encouragingEmpathetic + 0.05, 1.0)
            adjustedBlend.normalize()

        case 7...:
            // Strong streak - can be more challenging and playful
            adjustedBlend.playfullyProvocative = min(adjustedBlend.playfullyProvocative + 0.10, 1.0)
            adjustedBlend.authoritativeDirect = min(adjustedBlend.authoritativeDirect + 0.05, 1.0)
            adjustedBlend.normalize()
            AppLogger.debug("Adjusted persona for strong workout streak: more challenging", category: .ai)

        default:
            break
        }

        // Adjust based on recovery status
        switch workoutContext.recoveryStatus {
        case .active:
            // Currently active or just finished - be more supportive
            adjustedBlend.encouragingEmpathetic = min(adjustedBlend.encouragingEmpathetic + 0.10, 1.0)
            adjustedBlend.authoritativeDirect = max(adjustedBlend.authoritativeDirect - 0.05, 0.0)
            adjustedBlend.normalize()

        case .wellRested:
            // Well rested - can be more direct and challenging
            adjustedBlend.authoritativeDirect = min(adjustedBlend.authoritativeDirect + 0.10, 1.0)
            adjustedBlend.playfullyProvocative = min(adjustedBlend.playfullyProvocative + 0.05, 1.0)
            adjustedBlend.normalize()
            AppLogger.debug("Adjusted persona for well-rested status: more direct", category: .ai)

        case .detraining:
            // Long break - be very encouraging and gentle
            adjustedBlend.encouragingEmpathetic = min(adjustedBlend.encouragingEmpathetic + 0.20, 1.0)
            adjustedBlend.authoritativeDirect = max(adjustedBlend.authoritativeDirect - 0.15, 0.0)
            adjustedBlend.playfullyProvocative = max(adjustedBlend.playfullyProvocative - 0.10, 0.0)
            adjustedBlend.normalize()
            AppLogger.debug("Adjusted persona for detraining: very encouraging", category: .ai)

        default:
            break
        }

        // Adjust based on intensity trend
        switch workoutContext.intensityTrend {
        case .increasing:
            // High intensity trend - be more cautious about recovery
            adjustedBlend.encouragingEmpathetic = min(adjustedBlend.encouragingEmpathetic + 0.05, 1.0)
            adjustedBlend.authoritativeDirect = max(adjustedBlend.authoritativeDirect - 0.05, 0.0)
            adjustedBlend.normalize()

        case .decreasing:
            // Decreasing intensity - can be more motivational
            adjustedBlend.authoritativeDirect = min(adjustedBlend.authoritativeDirect + 0.05, 1.0)
            adjustedBlend.playfullyProvocative = min(adjustedBlend.playfullyProvocative + 0.05, 1.0)
            adjustedBlend.normalize()

        default:
            break
        }

        return adjustedBlend
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
            return "System prompt too long: ~\(tokens) tokens (max 8_000)"
        case .invalidProfile:
            return "Invalid user profile data"
        case .encodingFailed:
            return "Failed to encode profile data to JSON"
        }
    }
}

// MARK: - JSONEncoder Extension
extension JSONEncoder {
    static let airFitEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    func encodeToString<T: Encodable>(_ value: T) throws -> String {
        let data = try encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw PersonaEngineError.encodingFailed
        }
        return string
    }
}
