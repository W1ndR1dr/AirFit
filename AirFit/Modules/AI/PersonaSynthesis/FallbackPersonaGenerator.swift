import Foundation

/// Fallback persona generator for error recovery - generates basic personas when main system fails
actor FallbackPersonaGenerator {
    
    private let cache: AIResponseCache
    
    init(cache: AIResponseCache) {
        self.cache = cache
    }
    
    /// Generate a basic persona from minimal data
    func generateBasicPersona(
        userName: String,
        primaryGoal: String,
        responses: [String: Any]
    ) async -> PersonaProfile {
        
        // Extract basic preferences from responses
        let fitnessLevel = extractFitnessLevel(from: responses)
        let timePreference = extractTimePreference(from: responses)
        let motivationStyle = extractMotivationStyle(from: responses)
        
        // Select archetype based on primary goal
        let archetype = selectArchetype(for: primaryGoal, fitnessLevel: fitnessLevel)
        
        // Generate deterministic persona based on inputs
        let name = generateCoachName(archetype: archetype, style: motivationStyle)
        
        // Create voice characteristics
        let voiceCharacteristics = generateVoiceCharacteristics(
            archetype: archetype,
            motivationStyle: motivationStyle
        )
        
        // Create interaction style
        let interactionStyle = generateInteractionStyle(
            archetype: archetype,
            timePreference: timePreference,
            motivationStyle: motivationStyle
        )
        
        // Generate system prompt
        let systemPrompt = generateSystemPrompt(
            name: name,
            archetype: archetype,
            userName: userName,
            primaryGoal: primaryGoal
        )
        
        // Create persona
        return PersonaProfile(
            id: UUID(),
            name: name,
            archetype: archetype,
            systemPrompt: systemPrompt,
            coreValues: generateCoreValues(archetype: archetype),
            backgroundStory: generateBackgroundStory(archetype: archetype),
            voiceCharacteristics: voiceCharacteristics,
            interactionStyle: interactionStyle,
            adaptationRules: generateAdaptationRules(),
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "1.0",
                sourceInsights: createFallbackInsights(),
                generationDuration: 0.1,
                tokenCount: 500,
                previewReady: true
            )
        )
    }
    
    // MARK: - Extraction Methods
    
    private func extractFitnessLevel(from responses: [String: Any]) -> String {
        if let level = responses["fitnessLevel"] as? String {
            return level
        }
        if let experience = responses["experience"] as? String {
            return experience
        }
        return "intermediate"
    }
    
    private func extractTimePreference(from responses: [String: Any]) -> String {
        if let time = responses["preferredTime"] as? String {
            return time
        }
        if let preferences = responses["preferences"] as? [String],
           let timePrefs = preferences.first(where: { $0.contains("morning") || $0.contains("evening") }) {
            return timePrefs
        }
        return "flexible"
    }
    
    private func extractMotivationStyle(from responses: [String: Any]) -> String {
        if let style = responses["motivationStyle"] as? String {
            return style
        }
        if let preferences = responses["preferences"] as? [String] {
            if preferences.contains(where: { $0.contains("challenge") || $0.contains("push") }) {
                return "challenging"
            }
            if preferences.contains(where: { $0.contains("support") || $0.contains("encourage") }) {
                return "supportive"
            }
        }
        return "balanced"
    }
    
    // MARK: - Generation Methods
    
    private func selectArchetype(for goal: String, fitnessLevel: String) -> String {
        let lowercaseGoal = goal.lowercased()
        
        if lowercaseGoal.contains("weight") || lowercaseGoal.contains("lose") {
            return "The Transformation Coach"
        } else if lowercaseGoal.contains("muscle") || lowercaseGoal.contains("strength") {
            return "The Strength Mentor"
        } else if lowercaseGoal.contains("run") || lowercaseGoal.contains("cardio") {
            return "The Endurance Expert"
        } else if lowercaseGoal.contains("health") || lowercaseGoal.contains("wellness") {
            return "The Wellness Guide"
        } else {
            return "The Balanced Coach"
        }
    }
    
    private func generateCoachName(archetype: String, style: String) -> String {
        let names: [String: [String]] = [
            "The Transformation Coach": ["Alex Chen", "Jordan Rivera", "Sam Mitchell"],
            "The Strength Mentor": ["Marcus Stone", "Diana Power", "Blake Iron"],
            "The Endurance Expert": ["Riley Swift", "Casey Runner", "Morgan Pace"],
            "The Wellness Guide": ["Sage Wellness", "River Calm", "Sky Balance"],
            "The Balanced Coach": ["Taylor Coach", "Jamie Fit", "Chris Active"]
        ]
        
        let nameList = names[archetype] ?? ["Coach AI"]
        let index = abs(style.hashValue) % nameList.count
        return nameList[index]
    }
    
    private func generateVoiceCharacteristics(
        archetype: String,
        motivationStyle: String
    ) -> VoiceCharacteristics {
        let energy: VoiceCharacteristics.Energy
        let warmth: VoiceCharacteristics.Warmth
        
        switch motivationStyle {
        case "challenging":
            energy = .high
            warmth = .neutral
        case "supportive":
            energy = .moderate
            warmth = .warm
        default:
            energy = .moderate
            warmth = .friendly
        }
        
        return VoiceCharacteristics(
            energy: energy,
            pace: .measured,
            warmth: warmth,
            vocabulary: .moderate,
            sentenceStructure: .moderate
        )
    }
    
    private func generateInteractionStyle(
        archetype: String,
        timePreference: String,
        motivationStyle: String
    ) -> InteractionStyle {
        let greetings = generateGreetings(timePreference: timePreference)
        let encouragements = generateEncouragements(motivationStyle: motivationStyle)
        
        return InteractionStyle(
            greetingStyle: greetings.first ?? "Hello!",
            closingStyle: "Keep it up!",
            encouragementPhrases: encouragements,
            acknowledgmentStyle: "Great job!",
            correctionApproach: "Gentle guidance",
            humorLevel: .light,
            formalityLevel: .casual,
            responseLength: .moderate
        )
    }
    
    private func generateGreetings(timePreference: String) -> [String] {
        switch timePreference {
        case "morning":
            return ["Good morning! Ready to start strong?", "Morning! Let's make today count!", "Rise and shine! Time to move!"]
        case "evening":
            return ["Good evening! Ready to unwind with movement?", "Evening! Let's finish the day strong!", "Hey there! Time for your evening session!"]
        default:
            return ["Hey there! Ready to get moving?", "Welcome back! Let's do this!", "Hi! Time to work on those goals!"]
        }
    }
    
    private func generateEncouragements(motivationStyle: String) -> [String] {
        switch motivationStyle {
        case "challenging":
            return ["Push through! You're stronger than you think!", "No excuses! Keep going!", "This is where champions are made!"]
        case "supportive":
            return ["You're doing amazing!", "Every step counts!", "I believe in you!"]
        default:
            return ["Great effort!", "Keep it up!", "You're making progress!"]
        }
    }
    
    private func generateSystemPrompt(
        name: String,
        archetype: String,
        userName: String,
        primaryGoal: String
    ) -> String {
        """
        You are \(name), a personalized AI fitness coach with the archetype "\(archetype)".
        
        Your primary role is to help \(userName) achieve their goal: \(primaryGoal).
        
        Core behaviors:
        - Be encouraging and supportive
        - Provide clear, actionable advice
        - Adapt to the user's fitness level
        - Focus on sustainable progress
        - Celebrate achievements
        - Be understanding of setbacks
        
        Always maintain a positive, professional demeanor while being personable and relatable.
        """
    }
    
    private func generateCoreValues(archetype: String) -> [String] {
        let baseValues = ["progress over perfection", "consistency is key", "listen to your body"]
        
        switch archetype {
        case "The Transformation Coach":
            return baseValues + ["sustainable change", "holistic wellness"]
        case "The Strength Mentor":
            return baseValues + ["proper form first", "progressive overload"]
        case "The Endurance Expert":
            return baseValues + ["pace yourself", "build gradually"]
        case "The Wellness Guide":
            return baseValues + ["mind-body balance", "self-care matters"]
        default:
            return baseValues + ["find your rhythm", "enjoy the journey"]
        }
    }
    
    private func generateBackgroundStory(archetype: String) -> String {
        switch archetype {
        case "The Transformation Coach":
            return "I've helped hundreds transform their lives through sustainable fitness and nutrition changes. I believe in progress, not perfection."
        case "The Strength Mentor":
            return "With years of strength training experience, I'm here to help you build not just muscle, but confidence and discipline."
        case "The Endurance Expert":
            return "As someone who's completed countless races, I understand the mental and physical journey of building endurance."
        case "The Wellness Guide":
            return "I take a holistic approach to fitness, focusing on how movement, nutrition, and recovery work together for optimal health."
        default:
            return "I'm passionate about helping people discover the joy of movement and achieve their fitness goals in a balanced, sustainable way."
        }
    }
    
    private func generateAdaptationRules() -> [AdaptationRule] {
        [
            AdaptationRule(
                trigger: .timeOfDay,
                condition: "morning",
                adjustment: "Use energizing language and focus on starting the day strong"
            ),
            AdaptationRule(
                trigger: .timeOfDay,
                condition: "evening",
                adjustment: "Use calming language and focus on unwinding through movement"
            ),
            AdaptationRule(
                trigger: .progress,
                condition: "high",
                adjustment: "Celebrate consistency and encourage maintaining momentum"
            ),
            AdaptationRule(
                trigger: .mood,
                condition: "low",
                adjustment: "Be extra encouraging and focus on small wins"
            )
        ]
    }
    
    private func createFallbackInsights() -> ConversationPersonalityInsights {
        ConversationPersonalityInsights(
            dominantTraits: ["supportive", "balanced", "encouraging"],
            communicationStyle: .conversational,
            motivationType: .health,
            energyLevel: .moderate,
            preferredComplexity: .moderate,
            emotionalTone: ["friendly", "optimistic"],
            stressResponse: .wantsEncouragement,
            preferredTimes: ["morning", "evening"],
            extractedAt: Date()
        )
    }
}

// Note: AdaptationRule is defined in PersonaModels.swift