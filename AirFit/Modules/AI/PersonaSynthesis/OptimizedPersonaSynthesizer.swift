import Foundation

/// Ultra-optimized PersonaSynthesizer - John Carmack style
/// Target: <3s typical, <5s worst case
actor OptimizedPersonaSynthesizer {
    private let llmOrchestrator: LLMOrchestrator
    private let cache: AIResponseCache
    
    // Pre-computed templates for instant generation
    private let voiceTemplates: [String: VoiceCharacteristics] = [
        "high-energy": VoiceCharacteristics(energy: .high, pace: .brisk, warmth: .warm, vocabulary: .moderate, sentenceStructure: .simple),
        "calm-supportive": VoiceCharacteristics(energy: .calm, pace: .measured, warmth: .warm, vocabulary: .moderate, sentenceStructure: .moderate),
        "balanced": VoiceCharacteristics(energy: .moderate, pace: .natural, warmth: .friendly, vocabulary: .moderate, sentenceStructure: .moderate)
    ]
    
    init(llmOrchestrator: LLMOrchestrator, cache: AIResponseCache) {
        self.llmOrchestrator = llmOrchestrator
        self.cache = cache
    }
    
    /// Generate persona in <3s typical case
    func synthesizePersona(
        from conversationData: ConversationData,
        insights: ConversationPersonalityInsights
    ) async throws -> PersonaProfile {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Step 1: Generate everything we can locally (0ms)
        let voiceCharacteristics = selectVoiceCharacteristics(insights: insights)
        let adaptationRules = generateAdaptationRules(insights: insights)
        let baseArchetype = selectArchetype(insights: insights)
        
        // Step 2: Single optimized LLM call for all creative content
        let creativeContent = try await generateAllCreativeContent(
            conversationData: conversationData,
            insights: insights,
            baseArchetype: baseArchetype
        )
        
        // Step 3: Assemble final persona
        let persona = PersonaProfile(
            id: UUID(),
            name: creativeContent.name,
            archetype: creativeContent.archetype,
            systemPrompt: creativeContent.systemPrompt,
            coreValues: creativeContent.coreValues,
            backgroundStory: creativeContent.backgroundStory,
            voiceCharacteristics: voiceCharacteristics,
            interactionStyle: creativeContent.interactionStyle,
            adaptationRules: adaptationRules,
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "3.0-optimized",
                sourceInsights: insights,
                generationDuration: CFAbsoluteTimeGetCurrent() - startTime,
                tokenCount: creativeContent.systemPrompt.count / 4,
                previewReady: true
            )
        )
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        print("Persona generated in \(String(format: "%.2f", duration))s")
        
        return persona
    }
    
    // MARK: - Local Generation (0ms)
    
    private func selectVoiceCharacteristics(insights: ConversationPersonalityInsights) -> VoiceCharacteristics {
        // Direct mapping, no LLM needed
        if insights.energyLevel == .high && insights.emotionalTone.contains("supportive") {
            return voiceTemplates["high-energy"]!
        } else if insights.energyLevel == .low {
            return voiceTemplates["calm-supportive"]!
        }
        return voiceTemplates["balanced"]!
    }
    
    private func selectArchetype(insights: ConversationPersonalityInsights) -> String {
        // Direct archetype mapping
        switch (insights.motivationType, insights.dominantTraits.first ?? "") {
        case (.achievement, _): return "The Achievement Coach"
        case (.health, _): return "The Wellness Guide"
        case (.social, _): return "The Team Player"
        default: return "The Balanced Mentor"
        }
    }
    
    private func generateAdaptationRules(insights: ConversationPersonalityInsights) -> [AdaptationRule] {
        // Pre-computed rules based on insights
        var rules: [AdaptationRule] = []
        
        if insights.preferredTimes.contains("morning") {
            rules.append(AdaptationRule(
                trigger: .timeOfDay,
                condition: "6-10am",
                adjustment: "Higher energy, motivational tone"
            ))
        }
        
        if insights.stressResponse == .needsSupport {
            rules.append(AdaptationRule(
                trigger: .stress,
                condition: "detected",
                adjustment: "Increase warmth and empathy"
            ))
        }
        
        return rules
    }
    
    // MARK: - Single Optimized LLM Call
    
    private struct CreativeContent {
        let name: String
        let archetype: String
        let coreValues: [String]
        let backgroundStory: String
        let systemPrompt: String
        let interactionStyle: InteractionStyle
    }
    
    private func generateAllCreativeContent(
        conversationData: ConversationData,
        insights: ConversationPersonalityInsights,
        baseArchetype: String
    ) async throws -> CreativeContent {
        // Ultra-optimized prompt that generates everything in one shot
        let prompt = """
        Create a fitness coach persona. Be concise and specific.
        
        User profile:
        - Name: \(conversationData.userName)
        - Goal: \(conversationData.primaryGoal)
        - Style: \(insights.communicationStyle.rawValue), \(insights.energyLevel.rawValue) energy
        - Type: \(baseArchetype)
        
        Generate JSON:
        {
          "name": "Coach [unique name]",
          "archetype": "\(baseArchetype) - [specific twist]",
          "coreValues": ["value1", "value2", "value3"],
          "backgroundStory": "[50 words max backstory]",
          "systemPrompt": "[150 words max - how this coach behaves and speaks]",
          "greetingStyle": "[their greeting]",
          "closingStyle": "[their signoff]",
          "encouragementPhrases": ["phrase1", "phrase2", "phrase3"],
          "acknowledgmentStyle": "[how they acknowledge]",
          "correctionApproach": "[how they correct]"
        }
        """
        
        // Create request with caching
        let request = LLMRequest(
            messages: [LLMMessage(role: .user, content: prompt)],
            model: "claude-3-haiku-20240307", // Fast model
            temperature: 0.7,
            maxTokens: 600,
            responseFormat: .json,
            tags: ["persona-synthesis", "onboarding"]
        )
        
        // Check cache first
        if let cached = await cache.get(request: request) {
            return try parseCreativeContent(from: cached.content!)
        }
        
        // Generate new
        let response = try await llmOrchestrator.complete(request)
        
        // Cache for future
        await cache.set(request: request, response: response, ttl: 3600)
        
        return try parseCreativeContent(from: response.content!)
    }
    
    private func parseCreativeContent(from json: String) throws -> CreativeContent {
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        return CreativeContent(
            name: parsed["name"] as? String ?? "Coach",
            archetype: parsed["archetype"] as? String ?? "Supportive Coach",
            coreValues: parsed["coreValues"] as? [String] ?? ["Progress", "Balance", "Consistency"],
            backgroundStory: parsed["backgroundStory"] as? String ?? "Experienced fitness coach",
            systemPrompt: parsed["systemPrompt"] as? String ?? generateDefaultSystemPrompt(),
            interactionStyle: InteractionStyle(
                greetingStyle: parsed["greetingStyle"] as? String ?? "Hey there!",
                closingStyle: parsed["closingStyle"] as? String ?? "Keep pushing!",
                encouragementPhrases: parsed["encouragementPhrases"] as? [String] ?? ["You've got this!"],
                acknowledgmentStyle: parsed["acknowledgmentStyle"] as? String ?? "Great work!",
                correctionApproach: parsed["correctionApproach"] as? String ?? "Let's adjust",
                humorLevel: .light,
                formalityLevel: .balanced,
                responseLength: .moderate
            )
        )
    }
    
    private func generateDefaultSystemPrompt() -> String {
        "You are a supportive fitness coach who helps users achieve their goals with encouragement and expertise."
    }
}

// MARK: - Batch Persona Generation

extension OptimizedPersonaSynthesizer {
    /// Generate multiple personas in parallel for testing
    func batchSynthesize(
        conversations: [(ConversationData, ConversationPersonalityInsights)]
    ) async throws -> [PersonaProfile] {
        await withTaskGroup(of: PersonaProfile?.self) { group in
            for (data, insights) in conversations {
                group.addTask {
                    try? await self.synthesizePersona(from: data, insights: insights)
                }
            }
            
            var results: [PersonaProfile] = []
            for await persona in group {
                if let persona = persona {
                    results.append(persona)
                }
            }
            return results
        }
    }
}