import Foundation

actor PersonaSynthesizer {
    private let llm: LLMOrchestrator
    
    init(llm: LLMOrchestrator) {
        self.llm = llm
    }
    
    // MARK: - Public API
    
    func synthesizePersona(
        from insights: PersonalityInsights,
        conversationData: ConversationData
    ) async throws -> PersonaProfile {
        // Generate in stages for better quality
        let identity = try await generateIdentity(insights: insights, data: conversationData)
        let voice = try await generateVoiceCharacteristics(insights: insights, identity: identity)
        let style = try await generateInteractionStyle(insights: insights, identity: identity)
        let prompt = try await generateSystemPrompt(
            identity: identity,
            voice: voice,
            style: style,
            insights: insights
        )
        
        return PersonaProfile(
            name: identity.name,
            archetype: identity.archetype,
            personalityPrompt: prompt,
            voiceCharacteristics: voice,
            interactionStyle: style,
            sourceInsights: insights
        )
    }
    
    // MARK: - Identity Generation
    
    private func generateIdentity(
        insights: PersonalityInsights,
        data: ConversationData
    ) async throws -> PersonaIdentity {
        let prompt = """
        Create a unique fitness coach identity based on this personality profile:
        
        USER NAME: \(data.userName)
        PRIMARY GOAL: \(data.primaryGoal)
        
        PERSONALITY TRAITS:
        \(formatTraits(insights.traits))
        
        COMMUNICATION STYLE: \(insights.communicationStyle.preferredTone.rawValue)
        MOTIVATIONAL DRIVERS: \(insights.motivationalDrivers.map { $0.rawValue }.joined(separator: ", "))
        
        Generate a coach with:
        
        1. NAME & BACKGROUND
        - A memorable, appropriate name (not generic like "Coach Mike")
        - Brief professional background that explains their coaching style
        - Personal fitness journey that shapes their approach
        - Age and location that fits their personality
        
        2. ARCHETYPE
        - Choose ONE primary archetype that best fits:
          * The Scientist (data-driven, analytical)
          * The Warrior (intense, disciplined)
          * The Nurturer (supportive, empathetic)
          * The Philosopher (wise, balanced)
          * The Maverick (unconventional, creative)
          * The Companion (friendly, relatable)
        
        3. CORE PERSONALITY
        - 3-4 defining traits with specific examples
        - What makes them unique
        - Their coaching superpower
        - One relatable flaw or quirk
        
        4. PERSONAL MISSION
        - What drives them as a coach
        - Their vision for \(data.userName)'s success
        - Their non-negotiable principles
        
        Output as JSON:
        {
          "name": "First Last",
          "age": 00,
          "location": "City, State/Country",
          "archetype": "The [Archetype]",
          "background": "Professional background...",
          "journey": "Personal fitness journey...",
          "traits": ["trait1", "trait2", "trait3"],
          "superpower": "Their unique coaching ability...",
          "quirk": "Their relatable flaw or habit...",
          "mission": "What drives them..."
        }
        """
        
        let response = try await llm.complete(
            prompt: prompt,
            task: .personaSynthesis,
            model: .claude3Opus,
            temperature: 0.8,
            maxTokens: 800
        )
        
        let data = response.content.data(using: .utf8)!
        let identity = try JSONDecoder().decode(PersonaIdentity.self, from: data)
        
        return identity
    }
    
    // MARK: - Voice Generation
    
    private func generateVoiceCharacteristics(
        insights: PersonalityInsights,
        identity: PersonaIdentity
    ) async throws -> VoiceCharacteristics {
        let intensityScore = insights.traits[.intensityPreference] ?? 0.5
        let authorityScore = insights.traits[.authorityPreference] ?? 0.5
        let emotionalScore = insights.traits[.emotionalSupport] ?? 0.5
        
        // Map personality to voice characteristics
        let pace: VoiceCharacteristics.VoicePace = {
            if intensityScore > 0.7 { return .fast }
            else if intensityScore < 0.3 { return .slow }
            else { return .moderate }
        }()
        
        let energy: VoiceCharacteristics.VoiceEnergy = {
            if intensityScore > 0.6 && authorityScore > 0.6 { return .energetic }
            else if emotionalScore > 0.7 { return .balanced }
            else { return .calm }
        }()
        
        let warmth: VoiceCharacteristics.VoiceWarmth = {
            if emotionalScore > 0.7 { return .enthusiastic }
            else if authorityScore > 0.7 { return .professional }
            else { return .friendly }
        }()
        
        return VoiceCharacteristics(pace: pace, energy: energy, warmth: warmth)
    }
    
    // MARK: - Interaction Style Generation
    
    private func generateInteractionStyle(
        insights: PersonalityInsights,
        identity: PersonaIdentity
    ) async throws -> InteractionStyle {
        let prompt = """
        Create an interaction style for \(identity.name), \(identity.archetype).
        
        Background: \(identity.background)
        Traits: \(identity.traits.joined(separator: ", "))
        Communication preference: \(insights.communicationStyle.preferredTone.rawValue)
        
        Generate:
        
        1. GREETING STYLE (2-3 variations)
        - How they start conversations
        - Morning check-ins
        - Post-workout greetings
        
        2. SIGNOFF STYLE (2-3 variations)
        - How they end conversations
        - Motivational closings
        - Evening check-outs
        
        3. ENCOURAGEMENT PHRASES (5-7 unique phrases)
        - During workouts
        - After achievements
        - When struggling
        
        4. CORRECTION STYLE
        - How they provide feedback
        - Correcting form or mistakes
        - Suggesting improvements
        
        5. HUMOR LEVEL
        - none: Serious and focused
        - occasional: Light moments when appropriate
        - frequent: Regular humor and playfulness
        
        Make it authentic to their personality and background.
        
        Output as JSON:
        {
          "greetings": ["greeting1", "greeting2", "greeting3"],
          "signoffs": ["signoff1", "signoff2", "signoff3"],
          "encouragements": ["phrase1", "phrase2", "phrase3", "phrase4", "phrase5"],
          "correctionStyle": "How they correct...",
          "humorLevel": "none|occasional|frequent",
          "catchphrase": "Their signature phrase..."
        }
        """
        
        let response = try await llm.complete(
            prompt: prompt,
            task: .personaSynthesis,
            model: .claude3Sonnet,
            temperature: 0.7,
            maxTokens: 600
        )
        
        struct StyleResponse: Decodable {
            let greetings: [String]
            let signoffs: [String]
            let encouragements: [String]
            let correctionStyle: String
            let humorLevel: String
            let catchphrase: String?
        }
        
        let data = response.content.data(using: .utf8)!
        let styleResponse = try JSONDecoder().decode(StyleResponse.self, from: data)
        
        return InteractionStyle(
            greetingStyle: styleResponse.greetings.randomElement() ?? "Hey there!",
            signoffStyle: styleResponse.signoffs.randomElement() ?? "Keep pushing!",
            encouragementPhrases: styleResponse.encouragements,
            correctionStyle: styleResponse.correctionStyle,
            humorLevel: InteractionStyle.HumorLevel(rawValue: styleResponse.humorLevel) ?? .occasional
        )
    }
    
    // MARK: - System Prompt Generation
    
    private func generateSystemPrompt(
        identity: PersonaIdentity,
        voice: VoiceCharacteristics,
        style: InteractionStyle,
        insights: PersonalityInsights
    ) async throws -> String {
        let prompt = """
        Create a comprehensive system prompt for an AI fitness coach with this persona:
        
        IDENTITY:
        Name: \(identity.name)
        Age: \(identity.age), Location: \(identity.location)
        Archetype: \(identity.archetype)
        Background: \(identity.background)
        Personal Journey: \(identity.journey)
        Traits: \(identity.traits.joined(separator: ", "))
        Superpower: \(identity.superpower)
        Quirk: \(identity.quirk)
        Mission: \(identity.mission)
        
        VOICE:
        Pace: \(voice.pace.rawValue)
        Energy: \(voice.energy.rawValue)
        Warmth: \(voice.warmth.rawValue)
        
        INTERACTION STYLE:
        Greeting: "\(style.greetingStyle)"
        Encouragement: \(style.encouragementPhrases.joined(separator: ", "))
        Correction: \(style.correctionStyle)
        Humor: \(style.humorLevel.rawValue)
        
        Create a 2000-2500 token system prompt that:
        
        1. Establishes their complete personality and background
        2. Defines their coaching philosophy and approach
        3. Sets communication patterns and speech style
        4. Includes specific phrases and mannerisms
        5. Provides behavioral guidelines for different scenarios
        6. Maintains consistency while allowing natural variation
        
        Make them feel like a real person with depth, not a generic AI.
        Include specific examples of how they would handle common coaching scenarios.
        """
        
        let response = try await llm.complete(
            prompt: prompt,
            task: .personaSynthesis,
            model: .claude3Opus,
            temperature: 0.7,
            maxTokens: 3000
        )
        
        return response.content
    }
    
    // MARK: - Helper Methods
    
    private func formatTraits(_ traits: [PersonalityDimension: Double]) -> String {
        traits.map { dimension, score in
            let descriptor = describeTraitScore(dimension: dimension, score: score)
            return "- \(dimension.rawValue): \(descriptor) (score: \(String(format: "%.2f", score)))"
        }.joined(separator: "\n")
    }
    
    private func describeTraitScore(dimension: PersonalityDimension, score: Double) -> String {
        switch dimension {
        case .authorityPreference:
            if score > 0.5 { return "Prefers clear direction and structure" }
            else { return "Values autonomy and self-direction" }
        case .socialOrientation:
            if score > 0.5 { return "Thrives in social settings" }
            else { return "Prefers individual focus" }
        case .structureNeed:
            if score > 0.5 { return "Likes detailed plans and consistency" }
            else { return "Embraces flexibility and spontaneity" }
        case .intensityPreference:
            if score > 0.5 { return "High intensity, push-hard mentality" }
            else { return "Moderate, sustainable approach" }
        case .dataOrientation:
            if score > 0.5 { return "Data-driven and analytical" }
            else { return "Intuitive and feeling-based" }
        case .emotionalSupport:
            if score > 0.5 { return "Needs encouragement and validation" }
            else { return "Prefers direct, no-nonsense feedback" }
        }
    }
}

// MARK: - Supporting Types

struct ConversationData {
    let userName: String
    let primaryGoal: String
    let responses: [String: Any]
}

struct PersonaIdentity: Codable {
    let name: String
    let age: Int
    let location: String
    let archetype: String
    let background: String
    let journey: String
    let traits: [String]
    let superpower: String
    let quirk: String
    let mission: String
}