import Foundation
import SwiftData

actor PersonaService {
    private let personaSynthesizer: PersonaSynthesizer
    private let llmOrchestrator: LLMOrchestrator
    private let modelContext: ModelContext
    private let cache: AIResponseCache
    
    init(
        personaSynthesizer: PersonaSynthesizer,
        llmOrchestrator: LLMOrchestrator,
        modelContext: ModelContext,
        cache: AIResponseCache? = nil
    ) {
        self.personaSynthesizer = personaSynthesizer
        self.llmOrchestrator = llmOrchestrator
        self.modelContext = modelContext
        self.cache = cache ?? AIResponseCache()
    }
    
    func generatePersona(from session: ConversationSession) async throws -> PersonaProfile {
        // Extract conversation data from session
        let userName = extractUserName(from: session.responses)
        let primaryGoal = extractPrimaryGoal(from: session.responses)
        let responsesDict = convertResponsesToDict(session.responses)
        
        let conversationData = ConversationData(
            userName: userName,
            primaryGoal: primaryGoal,
            responses: responsesDict
        )
        
        // Extract personality insights from responses
        let insights = try await extractPersonalityInsights(from: session.responses)
        
        // Synthesize persona
        let persona = try await personaSynthesizer.synthesizePersona(
            from: conversationData,
            insights: insights
        )
        
        return persona
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
        
        let request = LLMRequest(
            messages: [
                LLMMessage(role: .system, content: "You are an AI persona adjustment specialist."),
                LLMMessage(role: .user, content: adjustmentPrompt)
            ],
            model: "claude-3-haiku-20240307",
            temperature: 0.7,
            responseFormat: .json
        )
        
        let response = try await llmOrchestrator.complete(request)
        
        // Parse adjusted persona from response
        return try parseAdjustedPersona(from: response, original: persona)
    }
    
    func savePersona(_ persona: PersonaProfile, for userId: UUID) async throws {
        // Create or update OnboardingProfile
        let descriptor = FetchDescriptor<OnboardingProfile>(
            predicate: #Predicate { profile in
                profile.userId == userId
            }
        )
        
        let profiles = try modelContext.fetch(descriptor)
        
        if let existingProfile = profiles.first {
            // Update existing profile
            existingProfile.personaName = persona.name
            existingProfile.personaData = try JSONEncoder().encode(persona)
            existingProfile.updatedAt = Date()
        } else {
            // Create new profile
            let profile = OnboardingProfile(
                userId: userId,
                completedAt: Date(),
                personaName: persona.name
            )
            profile.personaData = try JSONEncoder().encode(persona)
            modelContext.insert(profile)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Private Methods
    
    private func extractPersonalityInsights(from responses: [ConversationResponse]) async throws -> PersonalityInsights {
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
        
        let request = LLMRequest(
            messages: [
                LLMMessage(role: .system, content: "You are a personality analysis expert."),
                LLMMessage(role: .user, content: analysisPrompt)
            ],
            model: "claude-3-haiku-20240307",
            temperature: 0.5,
            responseFormat: .json
        )
        
        let response = try await llmOrchestrator.complete(request)
        
        // Parse insights from response
        return try parsePersonalityInsights(from: response)
    }
    
    private func parsePersonalityInsights(from response: LLMResponse) throws -> PersonalityInsights {
        guard let content = response.content,
              let data = content.data(using: .utf8) else {
            throw PersonaError.parsingFailed("Invalid response content")
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
        
        return PersonalityInsights(
            dominantTraits: decoded.dominantTraits,
            communicationStyle: CommunicationStyle(rawValue: decoded.communicationStyle) ?? .conversational,
            motivationType: MotivationType(rawValue: decoded.motivationType) ?? .balanced,
            energyLevel: EnergyLevel(rawValue: decoded.energyLevel) ?? .moderate,
            preferredComplexity: Complexity(rawValue: decoded.preferredComplexity) ?? .moderate,
            emotionalTone: decoded.emotionalTone,
            stressResponse: StressResponse(rawValue: decoded.stressResponse) ?? .needsSupport,
            preferredTimes: decoded.preferredTimes,
            extractedAt: Date()
        )
    }
    
    private func parseAdjustedPersona(from response: LLMResponse, original: PersonaProfile) throws -> PersonaProfile {
        guard let content = response.content,
              let data = content.data(using: .utf8) else {
            throw PersonaError.parsingFailed("Invalid response content")
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
            )
        )
        
        return adjusted
    }
}

// MARK: - Error Types

enum PersonaError: LocalizedError {
    case parsingFailed(String)
    case generationFailed(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .parsingFailed(let detail):
            return "Failed to parse response: \(detail)"
        case .generationFailed(let detail):
            return "Failed to generate persona: \(detail)"
        case .saveFailed(let detail):
            return "Failed to save persona: \(detail)"
        }
    }
}

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
    var completionPercentage: Int {
        guard responses.count > 0 else { return 0 }
        // Estimate based on typical flow having ~10-12 questions
        let estimatedTotal = 12
        return min(100, Int((Double(responses.count) / Double(estimatedTotal)) * 100))
    }
    
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