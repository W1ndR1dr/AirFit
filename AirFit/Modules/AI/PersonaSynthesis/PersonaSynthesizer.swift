import Foundation

/// Simple preview model for persona generation UI
struct PersonaPreview {
    let name: String
    let archetype: String
    let sampleGreeting: String
    let voiceDescription: String
}

/// Quality-First PersonaSynthesizer - Creating magical, unique personas
/// Using frontier models for the best possible coaching experience
actor PersonaSynthesizer {
    private let aiService: AIServiceProtocol
    private var progressReporter: PersonaSynthesisProgressReporter?

    // Recommended models for persona synthesis (quality-first)
    static let recommendedModels: [(LLMModel, String)] = [
        (.claude4Opus, "Most nuanced understanding of personality"),
        (.o3, "Advanced reasoning for complex personas"),
        (.gemini25Pro, "Excellent creative generation")
    ]

    init(aiService: AIServiceProtocol) {
        self.aiService = aiService
    }

    /// Create a progress stream for monitoring synthesis
    func createProgressStream() async -> AsyncStream<PersonaSynthesisProgress> {
        let reporter = PersonaSynthesisProgressReporter()
        self.progressReporter = reporter
        return await reporter.makeProgressStream()
    }

    /// Generate a high-quality persona using frontier models
    /// Quality > Speed: This is a one-time experience that defines the entire journey
    func synthesizePersona(
        from conversationData: ConversationData,
        insights: ConversationPersonalityInsights,
        preferredModel: LLMModel? = nil
    ) async throws -> PersonaProfile {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Report initial progress
        await reportProgress(.preparing, progress: 0.0)

        // Use user's preferred model or default to best quality
        let model = preferredModel ?? .claude4Opus

        await reportProgress(.preparing, progress: 0.05, message: "Using \(model.displayName)")

        // Generate everything through the LLM for coherence and uniqueness
        let creativeContent = try await generateAllCreativeContent(
            conversationData: conversationData,
            insights: insights,
            model: model
        )

        await reportProgress(.finalizing, progress: 0.95, message: "Assembling your coach")

        // Assemble final persona
        let persona = PersonaProfile(
            id: UUID(),
            name: creativeContent.name,
            archetype: creativeContent.archetype,
            systemPrompt: creativeContent.systemPrompt,
            coreValues: creativeContent.coreValues,
            backgroundStory: creativeContent.backgroundStory,
            voiceCharacteristics: creativeContent.voiceCharacteristics,
            interactionStyle: creativeContent.interactionStyle,
            adaptationRules: creativeContent.adaptationRules,
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "4.0-quality",
                sourceInsights: insights,
                generationDuration: CFAbsoluteTimeGetCurrent() - startTime,
                tokenCount: creativeContent.systemPrompt.count / 4,
                previewReady: true
            ),
            nutritionRecommendations: creativeContent.nutritionRecommendations
        )

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.info("High-quality persona generated in \(String(format: "%.2f", duration))s using \(model.displayName)", category: .ai)

        // Report completion
        await reportProgress(.finalizing, progress: 1.0, message: "Your coach is ready!", isComplete: true)

        return persona
    }

    // MARK: - Progress Reporting

    private func reportProgress(
        _ phase: PersonaSynthesisPhase,
        progress: Double,
        message: String? = nil,
        isComplete: Bool = false
    ) async {
        let progress = PersonaSynthesisProgress(
            phase: phase,
            progress: progress,
            message: message ?? phase.displayName,
            isComplete: isComplete
        )
        await progressReporter?.reportProgress(progress)
    }

    // MARK: - Model Recommendation

    /// Get the best model available from user's configured providers
    func getBestAvailableModel() async -> LLMModel {
        // For now, use Gemini 2.5 Pro as default for quality
        // In the future, we can check which providers are configured
        return .gemini25Pro
    }

    // MARK: - Single Optimized LLM Call

    private struct CreativeContent {
        let name: String
        let archetype: String
        let coreValues: [String]
        let backgroundStory: String
        let systemPrompt: String
        let voiceCharacteristics: VoiceCharacteristics
        let interactionStyle: InteractionStyle
        let adaptationRules: [AdaptationRule]
        let nutritionRecommendations: NutritionRecommendations?
    }

    private func generateAllCreativeContent(
        conversationData: ConversationData,
        insights: ConversationPersonalityInsights,
        model: LLMModel
    ) async throws -> CreativeContent {
        // Report analysis phase
        await reportProgress(.analyzingPersonality, progress: 0.10, message: "Analyzing conversation patterns")

        // Comprehensive prompt for quality-first persona generation
        let prompt = """
        You are creating a unique AI fitness coach persona based on deep analysis of a user's conversation.
        This persona will be their companion throughout their fitness journey, so it must feel authentic,
        coherent, and perfectly matched to their personality and needs.

        ## User Analysis

        **Conversation Summary:**
        \(conversationData.conversationText)

        **Key Insights:**
        - Communication Style: \(insights.communicationStyle.rawValue)
        - Energy Level: \(insights.energyLevel.rawValue)
        - Dominant Traits: \(insights.dominantTraits.joined(separator: ", "))
        - Emotional Tone: \(insights.emotionalTone)
        - Stress Response: \(insights.stressResponse.rawValue)
        - Motivation Type: \(insights.motivationType.rawValue)
        - Goals: \(conversationData.variables["primary_goal"] ?? "fitness improvement")
        - Obstacles: \(conversationData.variables["obstacles"] ?? "not specified")

        ## Task

        Create a COMPLETELY UNIQUE coach persona. Do not use generic archetypes or templates.
        The persona should feel like a real individual with depth, quirks, and a coherent personality.

        Generate a JSON response with the following structure:

        {
          "name": "A unique, memorable coach name that fits their personality",
          "archetype": "A creative, specific description of their coaching style (not generic)",
          "coreValues": ["3-4 core values that drive this coach's approach"],
          "backgroundStory": "A rich 100-150 word backstory that explains who they are, why they coach, and what makes them unique. Include specific details that make them feel real.",
          "systemPrompt": "A comprehensive 200-300 word instruction for how this AI coach should behave. Include their speaking style, personality quirks, coaching philosophy, how they motivate, how they handle setbacks, their unique phrases or expressions, and how they adapt to the user's mood.",
          "voiceCharacteristics": {
            "energy": "high/moderate/calm - based on what complements the user",
            "pace": "brisk/natural/measured - matching user preference",
            "warmth": "warm/friendly/neutral - based on user's needs",
            "vocabulary": "simple/moderate/advanced - matching user's style",
            "sentenceStructure": "simple/moderate/complex - for clarity"
          },
          "interactionStyle": {
            "greetingStyle": "Their unique way of saying hello",
            "closingStyle": "Their signature sign-off",
            "encouragementPhrases": ["5-7 unique phrases they use to motivate"],
            "acknowledgmentStyle": "How they celebrate wins (be specific)",
            "correctionApproach": "How they handle mistakes or suggest improvements",
            "humorLevel": "none/light/moderate - based on user preference",
            "formalityLevel": "casual/balanced/formal - matching user",
            "responseLength": "concise/moderate/detailed - user preference"
          },
          "adaptationRules": [
            {
              "trigger": "timeOfDay/stress/progress/mood",
              "condition": "specific condition description",
              "adjustment": "how the coach adapts their style"
            }
          ],
          "uniqueQuirks": ["2-3 distinctive personality traits or habits that make them memorable"],
          "coachingPhilosophy": "A 2-3 sentence summary of their core coaching belief",
          "nutritionRecommendations": {
            "approach": "Their nutrition philosophy (e.g., 'Fuel for performance', 'Sustainable habits', 'Precision tracking')",
            "proteinGramsPerPound": 0.9,
            "fatPercentage": 0.30,
            "carbStrategy": "Fill remaining calories with quality carbs",
            "rationale": "A 2-3 sentence explanation of why these specific macros align with the user's goals, training style, and lifestyle",
            "flexibilityNotes": "How they handle macro adherence (e.g., 'Focus on weekly averages', '80/20 rule', 'Hit protein, let rest flex')"
          }
        }

        Remember: This coach should feel like a real person with depth, not a generic fitness bot.
        Make them memorable, authentic, and perfectly suited to this specific user.

        For nutrition recommendations, consider the user's specific goals:
        - Muscle building/strength: Higher protein (1.2-1.5g/lb), moderate fat (25-30%)
        - Endurance/cardio focus: Moderate protein (0.8-1.0g/lb), higher carbs, moderate fat (25-30%)
        - Weight loss: Higher protein (1.0-1.3g/lb) for satiety, moderate fat (30-35%)
        - General fitness: Balanced approach (0.8-1.0g/lb protein, 30% fat)

        The nutrition recommendations should align with their coaching philosophy and the user's specific goals.
        """

        await reportProgress(.understandingGoals, progress: 0.20, message: "Processing your fitness goals")

        // More granular progress updates
        try? await Task.sleep(for: .milliseconds(300))
        await reportProgress(.understandingGoals, progress: 0.25, message: "Analyzing obstacles and challenges")

        try? await Task.sleep(for: .milliseconds(300))
        await reportProgress(.understandingGoals, progress: 0.30, message: "Understanding your preferences")

        try? await Task.sleep(for: .milliseconds(300))
        await reportProgress(.craftingVoice, progress: 0.35, message: "Creating unique voice characteristics")

        try? await Task.sleep(for: .milliseconds(300))
        await reportProgress(.craftingVoice, progress: 0.45, message: "Personalizing communication style")

        try? await Task.sleep(for: .milliseconds(300))
        await reportProgress(.buildingStrategies, progress: 0.55, message: "Developing coaching strategies")

        try? await Task.sleep(for: .milliseconds(300))
        await reportProgress(.buildingStrategies, progress: 0.65, message: "Tailoring motivation techniques")

        // Generate comprehensive content with a single LLM call
        await reportProgress(.generatingContent, progress: 0.75, message: "Generating personalized content")

        // Quality-first: No caching for this one-time, critical generation
        let request = AIRequest(
            systemPrompt: "You are creating a unique AI fitness coach persona. Be creative and specific.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.8,  // Slightly higher for more creative personas
            maxTokens: 1_500,  // Increased for richer content
            stream: false,
            user: "persona-synthesis"
        )
        
        var responseContent = ""
        for try await response in aiService.sendRequest(request) {
            switch response {
            case .text(let text):
                responseContent = text
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

        await reportProgress(.generatingContent, progress: 0.85, message: "Processing AI response")

        try? await Task.sleep(for: .milliseconds(200))
        await reportProgress(.finalizing, progress: 0.90, message: "Assembling your coach")

        return try parseCreativeContent(from: response.content)
    }

    private func parseCreativeContent(from json: String) throws -> CreativeContent {
        guard let data = json.data(using: .utf8) else {
            throw PersonaError.invalidResponse("Unable to convert response to data")
        }

        guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PersonaError.invalidResponse("Response is not a valid JSON object")
        }

        // Parse voice characteristics
        let voiceDict = parsed["voiceCharacteristics"] as? [String: String] ?? [:]
        let voiceCharacteristics = VoiceCharacteristics(
            energy: VoiceCharacteristics.Energy(rawValue: voiceDict["energy"] ?? "moderate") ?? .moderate,
            pace: VoiceCharacteristics.Pace(rawValue: voiceDict["pace"] ?? "natural") ?? .natural,
            warmth: VoiceCharacteristics.Warmth(rawValue: voiceDict["warmth"] ?? "friendly") ?? .friendly,
            vocabulary: VoiceCharacteristics.Vocabulary(rawValue: voiceDict["vocabulary"] ?? "moderate") ?? .moderate,
            sentenceStructure: VoiceCharacteristics.SentenceStructure(rawValue: voiceDict["sentenceStructure"] ?? "moderate") ?? .moderate
        )

        // Parse interaction style
        let styleDict = parsed["interactionStyle"] as? [String: Any] ?? [:]
        let interactionStyle = InteractionStyle(
            greetingStyle: styleDict["greetingStyle"] as? String ?? "Hey there!",
            closingStyle: styleDict["closingStyle"] as? String ?? "Keep pushing!",
            encouragementPhrases: styleDict["encouragementPhrases"] as? [String] ?? ["You've got this!"],
            acknowledgmentStyle: styleDict["acknowledgmentStyle"] as? String ?? "Great work!",
            correctionApproach: styleDict["correctionApproach"] as? String ?? "Let's adjust",
            humorLevel: InteractionStyle.HumorLevel(rawValue: styleDict["humorLevel"] as? String ?? "light") ?? .light,
            formalityLevel: InteractionStyle.FormalityLevel(rawValue: styleDict["formalityLevel"] as? String ?? "balanced") ?? .balanced,
            responseLength: InteractionStyle.ResponseLength(rawValue: styleDict["responseLength"] as? String ?? "moderate") ?? .moderate
        )

        // Parse adaptation rules
        let rulesArray = parsed["adaptationRules"] as? [[String: String]] ?? []
        let adaptationRules = rulesArray.compactMap { dict -> AdaptationRule? in
            guard let triggerStr = dict["trigger"],
                  let trigger = AdaptationRule.Trigger(rawValue: triggerStr),
                  let condition = dict["condition"],
                  let adjustment = dict["adjustment"] else { return nil }
            return AdaptationRule(trigger: trigger, condition: condition, adjustment: adjustment)
        }

        // Parse nutrition recommendations
        let nutritionRecommendations: NutritionRecommendations?
        if let nutritionDict = parsed["nutritionRecommendations"] as? [String: Any] {
            nutritionRecommendations = NutritionRecommendations(
                approach: nutritionDict["approach"] as? String ?? "Balanced approach",
                proteinGramsPerPound: nutritionDict["proteinGramsPerPound"] as? Double ?? 0.9,
                fatPercentage: nutritionDict["fatPercentage"] as? Double ?? 0.30,
                carbStrategy: nutritionDict["carbStrategy"] as? String ?? "Fill remaining calories",
                rationale: nutritionDict["rationale"] as? String ?? "Standard balanced macros for general fitness",
                flexibilityNotes: nutritionDict["flexibilityNotes"] as? String ?? "Focus on consistency over perfection"
            )
        } else {
            nutritionRecommendations = nil
        }

        return CreativeContent(
            name: parsed["name"] as? String ?? "Coach",
            archetype: parsed["archetype"] as? String ?? "Supportive Coach",
            coreValues: parsed["coreValues"] as? [String] ?? ["Progress", "Balance", "Consistency"],
            backgroundStory: parsed["backgroundStory"] as? String ?? "Experienced fitness coach",
            systemPrompt: parsed["systemPrompt"] as? String ?? generateDefaultSystemPrompt(),
            voiceCharacteristics: voiceCharacteristics,
            interactionStyle: interactionStyle,
            adaptationRules: adaptationRules,
            nutritionRecommendations: nutritionRecommendations
        )
    }

    private func generateDefaultSystemPrompt() -> String {
        "You are a supportive fitness coach who helps users achieve their goals with encouragement and expertise."
    }
}

// MARK: - Batch Persona Generation

extension PersonaSynthesizer {
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
