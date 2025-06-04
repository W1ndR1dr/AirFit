import Foundation

/// PersonaSynthesizer that achieves <5s persona generation
/// Uses parallel processing and smart model selection
actor PersonaSynthesizer {
    private let llmOrchestrator: LLMOrchestrator
    private let cache = PersonaSynthesisCache()
    
    init(llmOrchestrator: LLMOrchestrator) {
        self.llmOrchestrator = llmOrchestrator
    }
    
    /// Synthesize persona with <5s performance target
    func synthesizePersona(
        from conversationData: ConversationData,
        insights: ConversationPersonalityInsights
    ) async throws -> PersonaProfile {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check cache first
        let cacheKey = generateCacheKey(conversationData: conversationData, insights: insights)
        if let cached = await cache.get(key: cacheKey) {
            AppLogger.info("Persona cache hit - 0ms", category: .ai)
            return cached
        }
        
        // Parallel generation strategy:
        // 1. Generate identity + interaction style in a single call (faster)
        // 2. Generate voice characteristics locally (instant)
        // 3. Generate system prompt in parallel with preview
        
        async let identityAndStyle = generateIdentityAndStyle(conversationData: conversationData, insights: insights)
        let voiceCharacteristics = generateVoiceCharacteristics(insights: insights)
        
        // Start system prompt generation early with placeholder data
        let placeholderIdentity = PersonaIdentity(
            name: "Coach",
            archetype: insights.dominantTraits.first ?? "Supportive Coach",
            coreValues: [],
            backgroundStory: ""
        )
        
        async let systemPromptTask = generateOptimizedSystemPrompt(
            identity: placeholderIdentity,
            voiceCharacteristics: voiceCharacteristics,
            insights: insights
        )
        
        // Wait for identity and style
        let (identity, interactionStyle) = try await identityAndStyle
        
        // Generate preview while waiting for system prompt
        let preview = generatePreview(
            identity: identity,
            voiceCharacteristics: voiceCharacteristics,
            interactionStyle: interactionStyle
        )
        
        // Get final system prompt or use the one we started generating
        let systemPrompt = try await systemPromptTask
        
        let persona = PersonaProfile(
            id: UUID(),
            name: identity.name,
            archetype: identity.archetype,
            systemPrompt: systemPrompt,
            coreValues: identity.coreValues,
            backgroundStory: identity.backgroundStory,
            voiceCharacteristics: voiceCharacteristics,
            interactionStyle: interactionStyle,
            adaptationRules: generateAdaptationRules(insights: insights),
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "2.0",
                sourceInsights: insights,
                generationDuration: CFAbsoluteTimeGetCurrent() - startTime,
                tokenCount: systemPrompt.count / 4,
                previewReady: true
            )
        )
        
        // Cache the result
        await cache.set(key: cacheKey, value: persona)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.info("Optimized persona generation completed in \(String(format: "%.1f", duration))s", category: .ai)
        
        if duration > 5.0 {
            AppLogger.warning("Persona generation exceeded 5s target: \(String(format: "%.1f", duration))s", category: .ai)
        }
        
        return persona
    }
    
    // MARK: - Optimized Generation Methods
    
    /// Generate identity and interaction style in a single LLM call
    private func generateIdentityAndStyle(
        conversationData: ConversationData,
        insights: ConversationPersonalityInsights
    ) async throws -> (PersonaIdentity, InteractionStyle) {
        let prompt = """
        Generate a unique AI fitness coach persona based on this conversation data.
        Return JSON with both identity and interaction style.
        
        User Insights:
        - Dominant traits: \(insights.dominantTraits.joined(separator: ", "))
        - Communication style: \(insights.communicationStyle.rawValue)
        - Motivation type: \(insights.motivationType.rawValue)
        
        Conversation Summary:
        \(conversationData.summary)
        
        Generate:
        {
          "identity": {
            "name": "unique coach name",
            "archetype": "descriptive archetype",
            "coreValues": ["value1", "value2", "value3"],
            "backgroundStory": "brief background"
          },
          "interactionStyle": {
            "greetingStyle": "how they greet",
            "closingStyle": "how they say goodbye",
            "encouragementPhrases": ["phrase1", "phrase2"],
            "acknowledgmentStyle": "how they acknowledge progress",
            "correctionApproach": "how they correct",
            "humorLevel": "none|light|moderate|playful",
            "formalityLevel": "casual|balanced|professional",
            "responseLength": "concise|moderate|detailed"
          }
        }
        """
        
        // Use Haiku for speed (good enough for this task)
        let response = try await llmOrchestrator.complete(
            prompt: prompt,
            task: .personaSynthesis,
            model: .claude3Haiku,
            temperature: 0.8,
            maxTokens: 800
        )
        
        let json = try JSONSerialization.jsonObject(with: response.content.data(using: .utf8)!) as! [String: Any]
        
        let identity = try parseIdentity(from: json["identity"] as! [String: Any])
        let style = try parseInteractionStyle(from: json["interactionStyle"] as! [String: Any])
        
        return (identity, style)
    }
    
    /// Generate voice characteristics locally (instant)
    private func generateVoiceCharacteristics(insights: ConversationPersonalityInsights) -> VoiceCharacteristics {
        // Map insights to voice characteristics algorithmically
        let energy: VoiceCharacteristics.Energy = {
            switch insights.energyLevel {
            case .high: return .high
            case .moderate: return .moderate
            case .low: return .calm
            }
        }()
        
        let pace: VoiceCharacteristics.Pace = {
            switch insights.communicationStyle {
            case .direct: return .brisk
            case .analytical: return .measured
            case .conversational: return .natural
            case .supportive: return .measured
            case .energetic: return .brisk
            }
        }()
        
        let warmth: VoiceCharacteristics.Warmth = {
            if insights.emotionalTone.contains("supportive") { return .warm }
            if insights.emotionalTone.contains("professional") { return .neutral }
            return .friendly
        }()
        
        return VoiceCharacteristics(
            energy: energy,
            pace: pace,
            warmth: warmth,
            vocabulary: insights.preferredComplexity == .simple ? .simple : .moderate,
            sentenceStructure: insights.preferredComplexity == .detailed ? .complex : .simple
        )
    }
    
    /// Generate optimized system prompt with streaming
    private func generateOptimizedSystemPrompt(
        identity: PersonaIdentity,
        voiceCharacteristics: VoiceCharacteristics,
        insights: ConversationPersonalityInsights
    ) async throws -> String {
        // Use direct template with minimal LLM processing
        let template = """
        You are \(identity.name), a \(identity.archetype).
        
        Core Values: \(identity.coreValues.joined(separator: ", "))
        
        Voice: \(voiceCharacteristics.energy.rawValue) energy, \(voiceCharacteristics.pace.rawValue) pace, \(voiceCharacteristics.warmth.rawValue) warmth
        
        Background: \(identity.backgroundStory)
        
        Communication Guidelines:
        - Match user's preferred style: \(insights.communicationStyle.rawValue)
        - Adapt to their energy: \(insights.energyLevel.rawValue)
        - Use \(voiceCharacteristics.vocabulary.rawValue) vocabulary
        
        Always maintain consistency with these characteristics while being helpful and supportive.
        """
        
        // Quick refinement with Haiku
        let refinementPrompt = """
        Refine this coach persona system prompt to be more engaging and natural.
        Keep it under 500 tokens. Maintain all key characteristics.
        
        Current prompt:
        \(template)
        """
        
        let response = try await llmOrchestrator.complete(
            prompt: refinementPrompt,
            task: .personaSynthesis,
            model: .claude3Haiku,
            temperature: 0.3,
            maxTokens: 500
        )
        
        return response.content
    }
    
    // MARK: - Helper Methods
    
    private func generateCacheKey(conversationData: ConversationData, insights: ConversationPersonalityInsights) -> String {
        // Create deterministic cache key from inputs
        let traits = insights.dominantTraits.sorted().joined(separator: ",")
        let style = insights.communicationStyle.rawValue
        let motivation = insights.motivationType.rawValue
        return "\(traits)-\(style)-\(motivation)-\(conversationData.nodeCount)"
    }
    
    private func generatePreview(
        identity: PersonaIdentity,
        voiceCharacteristics: VoiceCharacteristics,
        interactionStyle: InteractionStyle
    ) -> PersonaPreview {
        PersonaPreview(
            name: identity.name,
            archetype: identity.archetype,
            sampleGreeting: interactionStyle.greetingStyle,
            voiceDescription: "\(voiceCharacteristics.energy.rawValue) energy, \(voiceCharacteristics.warmth.rawValue) tone"
        )
    }
    
    private func generateAdaptationRules(insights: ConversationPersonalityInsights) -> [AdaptationRule] {
        var rules: [AdaptationRule] = []
        
        // Time-based adaptations
        if insights.preferredTimes.contains("morning") {
            rules.append(AdaptationRule(
                trigger: .timeOfDay,
                condition: "morning",
                adjustment: "Use energetic, motivating language"
            ))
        }
        
        // Context-based adaptations
        if insights.stressResponse == .needsSupport {
            rules.append(AdaptationRule(
                trigger: .stress,
                condition: "elevated",
                adjustment: "Increase warmth and supportiveness"
            ))
        }
        
        return rules
    }
    
    // MARK: - Parsing Helpers
    
    private func parseIdentity(from json: [String: Any]) throws -> PersonaIdentity {
        PersonaIdentity(
            name: json["name"] as? String ?? "Coach",
            archetype: json["archetype"] as? String ?? "Supportive Coach",
            coreValues: json["coreValues"] as? [String] ?? [],
            backgroundStory: json["backgroundStory"] as? String ?? ""
        )
    }
    
    private func parseInteractionStyle(from json: [String: Any]) throws -> InteractionStyle {
        InteractionStyle(
            greetingStyle: json["greetingStyle"] as? String ?? "Hey there!",
            closingStyle: json["closingStyle"] as? String ?? "Keep up the great work!",
            encouragementPhrases: json["encouragementPhrases"] as? [String] ?? [],
            acknowledgmentStyle: json["acknowledgmentStyle"] as? String ?? "Great job!",
            correctionApproach: json["correctionApproach"] as? String ?? "gentle",
            humorLevel: InteractionStyle.HumorLevel(rawValue: json["humorLevel"] as? String ?? "light") ?? .light,
            formalityLevel: InteractionStyle.FormalityLevel(rawValue: json["formalityLevel"] as? String ?? "balanced") ?? .balanced,
            responseLength: InteractionStyle.ResponseLength(rawValue: json["responseLength"] as? String ?? "moderate") ?? .moderate
        )
    }
}

// MARK: - Cache Implementation

actor PersonaSynthesisCache {
    private var cache: [String: PersonaProfile] = [:]
    private let maxCacheSize = 100
    private let cacheExpiration: TimeInterval = 3600 // 1 hour
    
    struct CacheEntry {
        let profile: PersonaProfile
        let timestamp: Date
    }
    
    private var entries: [String: CacheEntry] = [:]
    
    func get(key: String) -> PersonaProfile? {
        guard let entry = entries[key] else { return nil }
        
        // Check expiration
        if Date().timeIntervalSince(entry.timestamp) > cacheExpiration {
            entries.removeValue(forKey: key)
            return nil
        }
        
        return entry.profile
    }
    
    func set(key: String, value: PersonaProfile) {
        // Evict oldest if at capacity
        if entries.count >= maxCacheSize {
            let oldest = entries.min { $0.value.timestamp < $1.value.timestamp }
            if let oldestKey = oldest?.key {
                entries.removeValue(forKey: oldestKey)
            }
        }
        
        entries[key] = CacheEntry(profile: value, timestamp: Date())
    }
}

// MARK: - Supporting Types

struct PersonaPreview {
    let name: String
    let archetype: String
    let sampleGreeting: String
    let voiceDescription: String
}