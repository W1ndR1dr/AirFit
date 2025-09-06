import Foundation
import SwiftData

// Note: Using PersonalityInsights from AI/Models/ConversationPersonalityInsights.swift
// instead of Onboarding/Models/PersonalityInsights.swift for persona synthesis

@MainActor
final class PersonaService: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "persona-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }

    private let personaSynthesizer: PersonaSynthesizer
    private let aiService: AIServiceProtocol
    private let modelContext: ModelContext

    init(
        personaSynthesizer: PersonaSynthesizer,
        aiService: AIServiceProtocol,
        modelContext: ModelContext
    ) {
        self.personaSynthesizer = personaSynthesizer
        self.aiService = aiService
        self.modelContext = modelContext
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
            metadata: [
                "hasPersonaSynthesizer": "true",
                "hasAIService": "true"
            ]
        )
    }

    func generatePersona(from session: ConversationSession) async throws -> PersonaProfile {
        // Extract conversation data from session
        let userName = extractUserName(from: session.responses)
        let primaryGoal = extractPrimaryGoal(from: session.responses)
        _ = convertResponsesToDict(session.responses)

        // Convert responses to conversation messages
        let messages = session.responses.map { response in
            ConversationMessage(
                role: .user,
                content: String(describing: response.responseData),
                timestamp: response.timestamp
            )
        }

        let conversationData = ConversationData(
            messages: messages,
            variables: [
                "userName": userName,
                "primary_goal": primaryGoal
            ]
        )

        // Extract personality insights from responses (has retry logic)
        let insights = try await extractPersonalityInsights(from: session.responses)

        // Synthesize persona with retry logic
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                let persona = try await personaSynthesizer.synthesizePersona(
                    from: conversationData,
                    insights: insights
                )

                AppLogger.info("Successfully generated persona on attempt \(attempt + 1)", category: .ai)
                return persona
            } catch {
                lastError = error
                AppLogger.warning("Persona synthesis attempt \(attempt + 1) failed: \(error)", category: .ai)

                if attempt < 2 {
                    // Exponential backoff: 1s, 2s, 4s
                    let backoffSeconds = pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
                }
            }
        }

        // All retries failed
        throw lastError ?? PersonaError.invalidResponse("Failed to synthesize persona after 3 attempts")
    }

    func adjustPersona(_ persona: PersonaProfile, adjustment: String) async throws -> PersonaProfile {
        // Create adjustment request
        let adjustmentPrompt = """
        Current persona: \(persona.name)
        Current archetype: \(persona.archetype)
        Current voice energy: \(persona.voiceCharacteristics.energy.rawValue)
        Current voice warmth: \(persona.voiceCharacteristics.warmth.rawValue)
        Current formality: \(persona.interactionStyle.formalityLevel.rawValue)

        User requested adjustment: "\(adjustment)"

        Modify the persona to incorporate this feedback while maintaining core personality.
        Return updated persona details.
        """

        // Retry with exponential backoff
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                // Create request for AI service
                let request = AIRequest(
                    systemPrompt: "You are adjusting an AI fitness coach persona based on user feedback.",
                    messages: [AIChatMessage(role: .user, content: adjustmentPrompt)],
                    temperature: 0.7,
                    maxTokens: 2_000,
                    stream: false,
                    user: "persona-adjustment"
                )
                
                var responseContent = ""
                for try await response in aiService.sendRequest(request) {
                    switch response {
                    case .text(let content):
                        responseContent = content
                    case .textDelta(let delta):
                        responseContent += delta
                    default:
                        break
                    }
                }
                
                let response = LLMResponse(
                    content: responseContent,
                    model: "gemini-2.5-flash",
                    usage: LLMResponse.TokenUsage(promptTokens: 0, completionTokens: 0),
                    finishReason: .stop,
                    metadata: [:],
                    structuredData: nil,
                    cacheMetrics: nil
                )

                // Parse adjusted persona from response
                return try parseAdjustedPersona(from: response, original: persona)
            } catch {
                lastError = error
                AppLogger.warning("Persona adjustment attempt \(attempt + 1) failed: \(error)", category: .ai)

                if attempt < 2 {
                    // Exponential backoff: 1s, 2s, 4s
                    let backoffSeconds = pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
                }
            }
        }

        // All retries failed
        throw lastError ?? PersonaError.invalidResponse("Failed to adjust persona after 3 attempts")
    }

    func savePersona(_ persona: PersonaProfile, for userId: UUID) async throws {
        // First get the user
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.id == userId
            }
        )
        let users = try modelContext.fetch(userDescriptor)
        guard let user = users.first else {
            throw AppError.userNotFound
        }

        // Get the user's onboarding profile
        if let existingProfile = user.onboardingProfile {
            // Update existing profile
            existingProfile.name = persona.name
            existingProfile.personaData = try JSONEncoder().encode(persona)
            // Update timestamp handled by SwiftData
        } else {
            // Create new profile
            let profile = OnboardingProfile(
                personaPromptData: Data(),
                communicationPreferencesData: Data(),
                rawFullProfileData: Data(),
                user: user
            )
            profile.name = persona.name
            profile.personaData = try JSONEncoder().encode(persona)
            profile.isComplete = true
            user.onboardingProfile = profile
            modelContext.insert(profile)
        }

        // Update user's macro preferences from persona recommendations
        if let nutritionRecs = persona.nutritionRecommendations {
            user.proteinGramsPerPound = nutritionRecs.proteinGramsPerPound
            user.fatPercentage = nutritionRecs.fatPercentage

            // Map flexibility notes to simple preference
            if nutritionRecs.flexibilityNotes.contains("strict") || nutritionRecs.flexibilityNotes.contains("precise") {
                user.macroFlexibility = "strict"
            } else if nutritionRecs.flexibilityNotes.contains("80/20") || nutritionRecs.flexibilityNotes.contains("flexible") {
                user.macroFlexibility = "flexible"
            } else {
                user.macroFlexibility = "balanced"
            }

            AppLogger.info("Updated user macros from persona: \(nutritionRecs.proteinGramsPerPound)g/lb protein, \(Int(nutritionRecs.fatPercentage * 100))% fat", category: .data)
        }

        try modelContext.save()
    }

    func getActivePersona(for userId: UUID) async throws -> PersonaProfile {
        // Fetch the user and their onboarding profile
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.id == userId
            }
        )
        let users = try modelContext.fetch(userDescriptor)
        guard let user = users.first else {
            throw AppError.userNotFound
        }

        guard let onboardingProfile = user.onboardingProfile,
              let personaData = onboardingProfile.personaData else {
            throw AppError.validationError(message: "No persona found for user")
        }

        // Decode the persona profile
        let persona = try JSONDecoder().decode(PersonaProfile.self, from: personaData)
        return persona
    }

    // MARK: - Private Methods

    private func extractPersonalityInsights(from responses: [ConversationResponse]) async throws -> ConversationPersonalityInsights {
        // Convert responses to readable format
        var responseTexts: [String] = []
        for response in responses {
            if let value = try? JSONDecoder().decode(ResponseValue.self, from: response.responseData) {
                let responseText: String
                switch value {
                case .text(let text):
                    responseText = text
                case .choice(let choice):
                    responseText = choice
                case .multiChoice(let choices):
                    responseText = choices.joined(separator: ", ")
                case .slider(let value):
                    responseText = String(value)
                case .voice(let transcription, _):
                    responseText = transcription
                }
                responseTexts.append("Node: \(response.nodeId)\nResponse: \(responseText)")
            }
        }

        let analysisPrompt = """
        Analyze these conversation responses to extract personality insights:

        \(responseTexts.joined(separator: "\n\n"))

        Extract:
        1. Dominant personality traits (2-3)
        2. Communication style preference
        3. Motivation type
        4. Energy level
        5. Preferred complexity
        6. Emotional tone preferences
        7. Stress response patterns
        8. Preferred times for interaction

        Return as structured JSON.
        """

        // Retry with exponential backoff
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                // Create request for AI service
                let request = AIRequest(
                    systemPrompt: "You are analyzing conversation responses to extract personality insights.",
                    messages: [AIChatMessage(role: .user, content: analysisPrompt)],
                    temperature: 0.5,
                    maxTokens: 1_500,
                    stream: false,
                    user: "personality-analysis"
                )
                
                var responseContent = ""
                for try await response in aiService.sendRequest(request) {
                    switch response {
                    case .text(let content):
                        responseContent = content
                    case .textDelta(let delta):
                        responseContent += delta
                    default:
                        break
                    }
                }
                
                let response = LLMResponse(
                    content: responseContent,
                    model: "gemini-2.5-flash",
                    usage: LLMResponse.TokenUsage(promptTokens: 0, completionTokens: 0),
                    finishReason: .stop,
                    metadata: [:],
                    structuredData: nil,
                    cacheMetrics: nil
                )

                // Parse insights from response
                return try parsePersonalityInsights(from: response)
            } catch {
                lastError = error
                AppLogger.warning("Personality insights extraction attempt \(attempt + 1) failed: \(error)", category: .ai)

                if attempt < 2 {
                    // Exponential backoff: 1s, 2s, 4s
                    let backoffSeconds = pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
                }
            }
        }

        // All retries failed
        throw lastError ?? PersonaError.invalidResponse("Failed to extract personality insights after 3 attempts")
    }

    private func parsePersonalityInsights(from response: LLMResponse) throws -> ConversationPersonalityInsights {
        let content = response.content
        guard let data = content.data(using: .utf8) else {
            throw PersonaError.invalidResponse("Invalid response content")
        }

        struct InsightsResponse: Codable {
            let dominantTraits: [String]
            let communicationStyle: String
            let motivationType: String
            let energyLevel: String
            let preferredComplexity: String
            let emotionalTone: [String]
            let stressResponse: String
            let preferredTimes: [String]
        }

        let decoded = try JSONDecoder().decode(InsightsResponse.self, from: data)

        return ConversationPersonalityInsights(
            dominantTraits: decoded.dominantTraits,
            communicationStyle: ConversationCommunicationStyle(rawValue: decoded.communicationStyle) ?? .conversational,
            motivationType: ConversationMotivationType(rawValue: decoded.motivationType) ?? .balanced,
            energyLevel: ConversationEnergyLevel(rawValue: decoded.energyLevel) ?? .moderate,
            preferredComplexity: ConversationComplexity(rawValue: decoded.preferredComplexity) ?? .moderate,
            emotionalTone: decoded.emotionalTone,
            stressResponse: ConversationStressResponse(rawValue: decoded.stressResponse) ?? .needsSupport,
            preferredTimes: decoded.preferredTimes,
            extractedAt: Date()
        )
    }

    private func parseAdjustedPersona(from response: LLMResponse, original: PersonaProfile) throws -> PersonaProfile {
        let content = response.content
        guard let data = content.data(using: .utf8) else {
            throw PersonaError.invalidResponse("Invalid response content")
        }

        struct AdjustmentResponse: Codable {
            let name: String?
            let archetype: String?
            let energy: String?
            let warmth: String?
            let formality: String?
            let humorLevel: String?
            let encouragementPhrases: [String]?
        }

        let decoded = try JSONDecoder().decode(AdjustmentResponse.self, from: data)

        // Create new voice characteristics if needed
        var newVoiceCharacteristics = original.voiceCharacteristics
        if let energy = decoded.energy,
           let energyEnum = VoiceCharacteristics.Energy(rawValue: energy) {
            newVoiceCharacteristics = VoiceCharacteristics(
                energy: energyEnum,
                pace: original.voiceCharacteristics.pace,
                warmth: decoded.warmth.flatMap { VoiceCharacteristics.Warmth(rawValue: $0) } ?? original.voiceCharacteristics.warmth,
                vocabulary: original.voiceCharacteristics.vocabulary,
                sentenceStructure: original.voiceCharacteristics.sentenceStructure
            )
        }

        // Create new interaction style if needed
        var newInteractionStyle = original.interactionStyle
        if decoded.formality != nil || decoded.humorLevel != nil || decoded.encouragementPhrases != nil {
            newInteractionStyle = InteractionStyle(
                greetingStyle: original.interactionStyle.greetingStyle,
                closingStyle: original.interactionStyle.closingStyle,
                encouragementPhrases: decoded.encouragementPhrases ?? original.interactionStyle.encouragementPhrases,
                acknowledgmentStyle: original.interactionStyle.acknowledgmentStyle,
                correctionApproach: original.interactionStyle.correctionApproach,
                humorLevel: decoded.humorLevel.flatMap { InteractionStyle.HumorLevel(rawValue: $0) } ?? original.interactionStyle.humorLevel,
                formalityLevel: decoded.formality.flatMap { InteractionStyle.FormalityLevel(rawValue: $0) } ?? original.interactionStyle.formalityLevel,
                responseLength: original.interactionStyle.responseLength
            )
        }

        // Create adjusted persona
        let adjusted = PersonaProfile(
            id: original.id,
            name: decoded.name ?? original.name,
            archetype: decoded.archetype ?? original.archetype,
            systemPrompt: original.systemPrompt, // Regenerate if needed
            coreValues: original.coreValues,
            backgroundStory: original.backgroundStory,
            voiceCharacteristics: newVoiceCharacteristics,
            interactionStyle: newInteractionStyle,
            adaptationRules: original.adaptationRules,
            metadata: PersonaMetadata(
                createdAt: original.metadata.createdAt,
                version: original.metadata.version,
                sourceInsights: original.metadata.sourceInsights,
                generationDuration: original.metadata.generationDuration,
                tokenCount: original.metadata.tokenCount,
                previewReady: true
            ),
            nutritionRecommendations: original.nutritionRecommendations // Keep original nutrition recommendations
        )

        return adjusted
    }
}

// MARK: - Error Types

// PersonaError is now defined in PersonaModels.swift

// MARK: - Helper Methods

extension PersonaService {
    private func extractUserName(from responses: [ConversationResponse]) -> String {
        // Look for name in responses
        for response in responses {
            if response.nodeId == "name" || response.nodeId == "introduction" {
                if let data = try? JSONDecoder().decode(ResponseValue.self, from: response.responseData),
                   case .text(let name) = data {
                    return name
                }
            }
        }
        return "Friend"
    }

    private func extractPrimaryGoal(from responses: [ConversationResponse]) -> String {
        // Look for goal in responses
        for response in responses {
            if response.nodeId == "goals" || response.nodeId == "primaryGoal" {
                if let data = try? JSONDecoder().decode(ResponseValue.self, from: response.responseData),
                   case .text(let goal) = data {
                    return goal
                }
            }
        }
        return "improve fitness"
    }

    private func convertResponsesToDict(_ responses: [ConversationResponse]) -> [String: Any] {
        var dict: [String: Any] = [:]

        for response in responses {
            if let value = try? JSONDecoder().decode(ResponseValue.self, from: response.responseData) {
                switch value {
                case .text(let text):
                    dict[response.nodeId] = text
                case .choice(let choice):
                    dict[response.nodeId] = choice
                case .multiChoice(let choices):
                    dict[response.nodeId] = choices
                case .slider(let value):
                    dict[response.nodeId] = value
                case .voice(let transcription, _):
                    dict[response.nodeId] = transcription
                }
            }
        }

        return dict
    }
}

// MARK: - ConversationSession Extension

extension ConversationSession {
    // Note: completionPercentage is now a stored property in the model
    // to support assignment in ConversationFlowManager

    var sessionId: UUID {
        return id
    }

    var nodeCount: Int {
        // This would be set by ConversationFlowManager
        return 12
    }

    var summary: String? {
        // Generate summary from responses
        return nil
    }

    var extractedData: [String: Any]? {
        // This would be populated by ResponseAnalyzer
        return nil
    }
}
