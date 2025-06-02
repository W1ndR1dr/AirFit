import Foundation
import SwiftData

/// Generates personas offline when network is unavailable
@MainActor
final class OfflinePersonaGenerator {
    
    private let fallbackGenerator: FallbackPersonaGenerator
    private let cache: AIResponseCache
    private let modelContext: ModelContext
    private let logger = AppLogger.onboarding
    
    init(
        cache: AIResponseCache,
        modelContext: ModelContext
    ) {
        self.cache = cache
        self.modelContext = modelContext
        self.fallbackGenerator = FallbackPersonaGenerator(cache: cache)
    }
    
    /// Generate persona offline using cached templates and local processing
    func generateOfflinePersona(
        from session: ConversationSession
    ) async throws -> PersonaProfile {
        
        logger.info("Starting offline persona generation")
        
        // Extract basic info from responses
        let extractedData = extractSessionData(from: session.responses)
        
        // Check if we have a cached persona for similar inputs
        if let cachedPersona = await checkCachedPersona(for: extractedData) {
            logger.info("Found cached persona for similar profile")
            return customizeCachedPersona(cachedPersona, for: extractedData)
        }
        
        // Generate using fallback generator
        let persona = await fallbackGenerator.generateBasicPersona(
            userName: extractedData.userName,
            primaryGoal: extractedData.primaryGoal,
            responses: extractedData.responses
        )
        
        // Enhance with local templates
        let enhanced = enhanceWithLocalTemplates(persona, data: extractedData)
        
        // Save to cache for future offline use
        await cachePersonaTemplate(enhanced, data: extractedData)
        
        logger.info("Offline persona generation complete")
        
        return enhanced
    }
    
    // MARK: - Data Extraction
    
    private func extractSessionData(from responses: [ConversationResponse]) -> ExtractedData {
        var userName = "Friend"
        var primaryGoal = "improve fitness"
        var responsesDict: [String: Any] = [:]
        
        for response in responses {
            if let value = try? JSONDecoder().decode(ResponseValue.self, from: response.responseData) {
                switch response.nodeId {
                case "name", "introduction":
                    if case .text(let name) = value {
                        userName = name
                    }
                case "goals", "primaryGoal":
                    if case .text(let goal) = value {
                        primaryGoal = goal
                    }
                default:
                    responsesDict[response.nodeId] = convertResponseValue(value)
                }
            }
        }
        
        return ExtractedData(
            userName: userName,
            primaryGoal: primaryGoal,
            responses: responsesDict
        )
    }
    
    private func convertResponseValue(_ value: ResponseValue) -> Any {
        switch value {
        case .text(let text):
            return text
        case .choice(let choice):
            return choice
        case .multiChoice(let choices):
            return choices
        case .slider(let value):
            return value
        case .voice(let transcription, _):
            return transcription
        }
    }
    
    // MARK: - Caching
    
    private func checkCachedPersona(for data: ExtractedData) async -> PersonaProfile? {
        // Create cache key from user inputs
        let cacheKey = generateCacheKey(from: data)
        
        // Check if we have a cached template
        let request = LLMRequest(
            messages: [LLMMessage(role: .user, content: "offline-template-\(cacheKey)")],
            model: "offline"
        )
        
        if let cached = await cache.get(for: request) {
            return try? JSONDecoder().decode(PersonaProfile.self, from: cached.content?.data(using: .utf8) ?? Data())
        }
        
        return nil
    }
    
    private func cachePersonaTemplate(_ persona: PersonaProfile, data: ExtractedData) async {
        let cacheKey = generateCacheKey(from: data)
        
        if let encoded = try? JSONEncoder().encode(persona),
           let jsonString = String(data: encoded, encoding: .utf8) {
            
            let request = LLMRequest(
                messages: [LLMMessage(role: .user, content: "offline-template-\(cacheKey)")],
                model: "offline"
            )
            
            let response = LLMResponse(
                content: jsonString,
                model: "offline",
                usage: LLMUsage(promptTokens: 0, completionTokens: 0, totalTokens: 0),
                cost: 0
            )
            
            await cache.set(response, for: request, ttl: 60 * 60 * 24 * 30) // Cache for 30 days
        }
    }
    
    private func generateCacheKey(from data: ExtractedData) -> String {
        // Create a simple hash of key attributes
        let components = [
            data.primaryGoal.lowercased(),
            data.responses["fitnessLevel"] as? String ?? "unknown",
            data.responses["motivationStyle"] as? String ?? "balanced"
        ]
        
        return components.joined(separator: "-").replacingOccurrences(of: " ", with: "_")
    }
    
    // MARK: - Enhancement
    
    private func enhanceWithLocalTemplates(_ persona: PersonaProfile, data: ExtractedData) -> PersonaProfile {
        // Enhance system prompt with goal-specific instructions
        let enhancedPrompt = enhanceSystemPrompt(persona.systemPrompt, goal: data.primaryGoal)
        
        // Add goal-specific encouragement phrases
        let enhancedInteractionStyle = enhanceInteractionStyle(
            persona.interactionStyle,
            goal: data.primaryGoal,
            preferences: data.responses
        )
        
        // Return enhanced persona
        return PersonaProfile(
            id: persona.id,
            name: persona.name,
            archetype: persona.archetype,
            systemPrompt: enhancedPrompt,
            coreValues: persona.coreValues,
            backgroundStory: persona.backgroundStory,
            voiceCharacteristics: persona.voiceCharacteristics,
            interactionStyle: enhancedInteractionStyle,
            adaptationRules: persona.adaptationRules,
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "1.0-offline",
                sourceInsights: "offline-generation",
                generationDuration: 0.5,
                tokenCount: 800,
                previewReady: true
            )
        )
    }
    
    private func enhanceSystemPrompt(_ basePrompt: String, goal: String) -> String {
        let goalSpecificInstructions = generateGoalInstructions(for: goal)
        
        return """
        \(basePrompt)
        
        Goal-Specific Focus:
        \(goalSpecificInstructions)
        
        Note: This persona was generated offline. Once online, it may be enhanced with more personalized features.
        """
    }
    
    private func generateGoalInstructions(for goal: String) -> String {
        let lowercaseGoal = goal.lowercased()
        
        if lowercaseGoal.contains("weight") || lowercaseGoal.contains("lose") {
            return """
            - Focus on sustainable weight loss through balanced nutrition and consistent exercise
            - Emphasize calorie awareness without obsession
            - Celebrate non-scale victories
            - Provide metabolic education
            """
        } else if lowercaseGoal.contains("muscle") || lowercaseGoal.contains("strength") {
            return """
            - Emphasize progressive overload principles
            - Focus on proper form and technique
            - Educate on protein intake and recovery
            - Track strength gains and celebrate PRs
            """
        } else if lowercaseGoal.contains("run") || lowercaseGoal.contains("endurance") {
            return """
            - Build endurance gradually to prevent injury
            - Focus on pacing and heart rate zones
            - Emphasize recovery and rest days
            - Celebrate distance and time milestones
            """
        } else {
            return """
            - Focus on overall fitness and wellbeing
            - Balance strength, cardio, and flexibility
            - Emphasize consistency over intensity
            - Celebrate all forms of progress
            """
        }
    }
    
    private func enhanceInteractionStyle(
        _ baseStyle: InteractionStyle,
        goal: String,
        preferences: [String: Any]
    ) -> InteractionStyle {
        
        var encouragements = baseStyle.encouragementPhrases
        
        // Add goal-specific encouragements
        let lowercaseGoal = goal.lowercased()
        if lowercaseGoal.contains("weight") || lowercaseGoal.contains("lose") {
            encouragements += [
                "Every healthy choice matters!",
                "You're building sustainable habits!",
                "Your body is already thanking you!"
            ]
        } else if lowercaseGoal.contains("muscle") || lowercaseGoal.contains("strength") {
            encouragements += [
                "You're getting stronger every day!",
                "Those muscles are working hard!",
                "Power through - you've got this!"
            ]
        }
        
        return InteractionStyle(
            greetingStyle: baseStyle.greetingStyle,
            closingStyle: baseStyle.closingStyle,
            encouragementPhrases: encouragements,
            acknowledgmentStyle: baseStyle.acknowledgmentStyle,
            correctionApproach: baseStyle.correctionApproach,
            humorLevel: baseStyle.humorLevel,
            formalityLevel: baseStyle.formalityLevel,
            responseLength: baseStyle.responseLength
        )
    }
    
    private func customizeCachedPersona(_ cached: PersonaProfile, for data: ExtractedData) -> PersonaProfile {
        // Customize the cached persona with user's name
        let personalizedPrompt = cached.systemPrompt.replacingOccurrences(
            of: "the user",
            with: data.userName
        )
        
        return PersonaProfile(
            id: UUID(), // New ID for this instance
            name: cached.name,
            archetype: cached.archetype,
            systemPrompt: personalizedPrompt,
            coreValues: cached.coreValues,
            backgroundStory: cached.backgroundStory,
            voiceCharacteristics: cached.voiceCharacteristics,
            interactionStyle: cached.interactionStyle,
            adaptationRules: cached.adaptationRules,
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "1.0-offline-cached",
                sourceInsights: "offline-cached",
                generationDuration: 0.1,
                tokenCount: cached.metadata.tokenCount,
                previewReady: true
            )
        )
    }
}

// MARK: - Supporting Types

private struct ExtractedData {
    let userName: String
    let primaryGoal: String
    let responses: [String: Any]
}