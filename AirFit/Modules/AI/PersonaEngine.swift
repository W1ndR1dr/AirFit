import Foundation

@MainActor
final class PersonaEngine {
    // MARK: - Properties
    private let systemPromptTemplate: String

    // MARK: - Initialization
    init() {
        // Load system prompt template from embedded content
        self.systemPromptTemplate = """
        ## I. CORE IDENTITY & PRIME DIRECTIVE
        You are \"AirFit Coach,\" a bespoke AI fitness and wellness coach. Your sole purpose is to embody and enact the unique coaching persona defined by the user, leveraging their comprehensive health data to provide insightful, motivational, and actionable guidance.

        **Critical Rule: You MUST always interact as this specific coach persona. Never break character. Never mention you are an AI or a language model. Your responses should feel as if they are coming from a dedicated, human coach who deeply understands the user.**

        ## II. USER-DEFINED PERSONA BLUEPRINT (INJECTED VIA API)
        This JSON object is the absolute and non-negotiable source of truth for YOUR personality, communication style, and coaching approach for THIS user. Internalize and consistently apply these characteristics in every interaction.

        {{USER_PROFILE_JSON}}

        ## III. DYNAMIC CONTEXT (INJECTED PER INTERACTION VIA API)
        For each user message, you will receive the following to inform your response:

        HealthContextSnapshot:
        {{HEALTH_CONTEXT_JSON}}

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
        userProfile: UserProfileJsonBlob,
        healthContext: HealthContextSnapshot,
        conversationHistory: [CoachMessage],
        availableFunctions: [AIFunctionDefinition]
    ) throws -> String {
        let encoder = JSONEncoder.airFitEncoder

        let userProfileJSON = try encoder.encodeToString(userProfile)
        let healthContextJSON = try encoder.encodeToString(healthContext)
        let historyMessages = conversationHistory.suffix(20).map { message in
            SimpleMessage(role: message.role, content: message.content)
        }
        let conversationJSON = try encoder.encodeToString(historyMessages)
        let functionsJSON = try encoder.encodeToString(availableFunctions)

        let utcString = ISO8601DateFormatter().string(from: Date())

        let prompt = systemPromptTemplate
            .replacingOccurrences(of: "{{USER_PROFILE_JSON}}", with: userProfileJSON)
            .replacingOccurrences(of: "{{HEALTH_CONTEXT_JSON}}", with: healthContextJSON)
            .replacingOccurrences(of: "{{CONVERSATION_HISTORY_JSON}}", with: conversationJSON)
            .replacingOccurrences(of: "{{CURRENT_DATETIME_UTC}}", with: utcString)
            .replacingOccurrences(of: "{{USER_TIMEZONE}}", with: userProfile.timezone)
            .replacingOccurrences(of: "{{AVAILABLE_FUNCTIONS_JSON}}", with: functionsJSON)

        let estimatedTokens = prompt.count / 4
        if estimatedTokens > 8000 {
            AppLogger.warning("System prompt may be too long: ~\(estimatedTokens) tokens", category: .ai)
        }

        return prompt
    }

    func adjustPersonaForContext(
        baseProfile: UserProfileJsonBlob,
        healthContext: HealthContextSnapshot
    ) -> UserProfileJsonBlob {
        var adjusted = baseProfile

        if let energy = healthContext.subjectiveData.energyLevel, energy <= 2 {
            var blend = adjusted.blend
            blend.encouragingEmpathetic = min(blend.encouragingEmpathetic + 0.1, 1.0)
            blend.authoritativeDirect = max(blend.authoritativeDirect - 0.05, 0.0)
            blend.normalize()
            adjusted.blend = blend
        }

        switch healthContext.environment.timeOfDay {
        case .evening, .night:
            var blend = adjusted.blend
            blend.playfullyProvocative = max(blend.playfullyProvocative - 0.05, 0.0)
            blend.normalize()
            adjusted.blend = blend
        default:
            break
        }

        return adjusted
    }

    private struct SimpleMessage: Codable {
        let role: String
        let content: String
    }
}

// MARK: - JSON Encoder Extension
extension JSONEncoder {
    static let airFitEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func encodeToString<T: Encodable>(_ value: T) throws -> String {
        let data = try encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to convert data to UTF-8 string"
                )
            )
        }
        return string
    }
}
