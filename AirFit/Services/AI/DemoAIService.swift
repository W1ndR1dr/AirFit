import Foundation

/// Demo AI service that provides canned responses for testing without API keys
actor DemoAIService: AIServiceProtocol {
    
    // MARK: - Properties
    nonisolated let serviceIdentifier = "demo-ai-service"
    private var _isConfigured: Bool = true
    nonisolated var isConfigured: Bool {
        get { true } // Always configured in demo mode
    }
    private var _activeProvider: AIProvider = .gemini
    nonisolated var activeProvider: AIProvider {
        get { .gemini } // Always gemini in demo mode
    }
    private var _availableModels: [AIModel] = []
    nonisolated var availableModels: [AIModel] {
        get { [] } // Return empty for nonisolated access
    }
    
    private var responseDelay: TimeInterval = 1.0
    
    // Demo responses for different contexts
    private let demoResponses: [String] = [
        "Welcome! I'm excited to be part of your fitness journey. Let's start by getting to know you better.",
        "Those are great goals! I can see you're committed to making positive changes.",
        "Thanks for sharing your schedule. I'll make sure our workouts fit seamlessly into your routine.",
        "Got it! I'll keep your preferences in mind as we build your personalized plan.",
        "I can see what drives you! I'll use this insight to keep you motivated throughout your journey."
    ]
    
    // Context-aware responses for different types of queries
    private let contextResponses: [String: [String]] = [
        "workout": [
            "Let's create a workout plan that fits your goals! I'd recommend starting with 3-4 sessions per week.",
            "Great progress on your last workout! Ready to take it up a notch today?",
            "How about we try some compound exercises today? They're excellent for building functional strength.",
            "Remember, consistency beats intensity. Let's focus on sustainable progress.",
            "Your form is getting better! Keep focusing on controlled movements."
        ],
        "nutrition": [
            "Nutrition is key to your fitness goals. Let's work on building sustainable eating habits.",
            "Great job logging your meals! I notice you're hitting your protein targets consistently.",
            "Hydration is often overlooked. Aim for at least 8 glasses of water daily.",
            "Pre-workout nutrition can boost your performance. Try a banana with almond butter 30 minutes before.",
            "Recovery nutrition is crucial. Let's ensure you're getting enough protein post-workout."
        ],
        "motivation": [
            "You've got this! Every workout brings you closer to your goals.",
            "Progress isn't always linear, but your consistency is paying off!",
            "Remember why you started. You're stronger than you think!",
            "Small wins add up to big changes. Celebrate your progress!",
            "The only bad workout is the one you didn't do. Let's make today count!"
        ],
        "general": [
            "I'm here to support you every step of the way. What would you like to focus on today?",
            "Tell me more about your fitness journey. I'm listening!",
            "That's a great question! Let me help you with that.",
            "I understand. Let's work together to find a solution that works for you.",
            "Excellent point! Here's my take on that..."
        ]
    ]
    
    // MARK: - Initialization
    init() {
        self._availableModels = [
            AIModel(
                id: "demo-model",
                name: "Demo AI (No API Key)",
                provider: .gemini,
                contextWindow: 100_000,
                costPerThousandTokens: AIModel.TokenCost(input: 0, output: 0)
            )
        ]
    }
    
    // MARK: - ServiceProtocol
    
    func configure() async throws {
        _isConfigured = true
    }
    
    func reset() async {
        // Nothing to reset in demo mode
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: 0.1,
            errorMessage: nil,
            metadata: ["mode": "demo"]
        )
    }
    
    // MARK: - AIServiceProtocol
    
    func configure(
        provider: AIProvider,
        apiKey: String,
        model: String?
    ) async throws {
        // Demo mode doesn't need configuration
        _isConfigured = true
    }
    
    nonisolated func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                // Simulate network delay
                try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
                
                // Check if this is a function-calling request
                if let functions = request.functions, !functions.isEmpty, let functionCall = await self.checkForFunctionCall(request: request) {
                    // Return a function call response
                    continuation.yield(.functionCall(functionCall))
                    continuation.yield(.done(usage: AITokenUsage(
                        promptTokens: 100,
                        completionTokens: 50,
                        totalTokens: 150
                    )))
                } else {
                    // Determine context from the request
                    let response = await self.getContextAwareResponse(for: request)
                    
                    // Simulate streaming response
                    let words = response.split(separator: " ")
                    for (index, word) in words.enumerated() {
                        if index > 0 {
                            continuation.yield(.textDelta(" "))
                        }
                        continuation.yield(.textDelta(String(word)))
                        try await Task.sleep(nanoseconds: 50_000_000) // 50ms between words
                    }
                    
                    // Send done with mock usage
                    continuation.yield(.done(usage: AITokenUsage(
                        promptTokens: 100,
                        completionTokens: 50,
                        totalTokens: 150
                    )))
                }
                
                continuation.finish()
            }
        }
    }
    
    private func getContextAwareResponse(for request: AIRequest) -> String {
        // Analyze the last user message to determine context
        guard let lastMessage = request.messages.last?.content.lowercased() else {
            return demoResponses.randomElement() ?? demoResponses[0]
        }
        
        // Check for keywords to determine context
        if lastMessage.contains("workout") || lastMessage.contains("exercise") || lastMessage.contains("training") {
            return contextResponses["workout"]?.randomElement() ?? demoResponses[0]
        } else if lastMessage.contains("food") || lastMessage.contains("eat") || lastMessage.contains("nutrition") || lastMessage.contains("meal") {
            return contextResponses["nutrition"]?.randomElement() ?? demoResponses[0]
        } else if lastMessage.contains("motivat") || lastMessage.contains("tired") || lastMessage.contains("help") || lastMessage.contains("struggle") {
            return contextResponses["motivation"]?.randomElement() ?? demoResponses[0]
        } else if request.messages.count <= 1 {
            // First message in conversation
            return demoResponses[0]
        } else {
            return contextResponses["general"]?.randomElement() ?? demoResponses.randomElement()!
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        // Demo mode is always valid
        return true
    }
    
    func checkHealth() async -> ServiceHealth {
        await healthCheck()
    }
    
    nonisolated func estimateTokenCount(for text: String) -> Int {
        // Rough estimate: 1 token per 4 characters
        return text.count / 4
    }
}

// MARK: - Demo Persona Generation

extension DemoAIService {
    /// Generate a demo persona for onboarding
    func generateDemoPersona() async -> PersonaProfile {
        // Simulate generation delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        return PersonaProfile(
            id: UUID(),
            name: "Coach Demo",
            archetype: "Supportive Mentor",
            systemPrompt: "You are a demo fitness coach providing example interactions.",
            coreValues: ["Encouragement", "Adaptability", "Progress-focused"],
            backgroundStory: "I'm your demo coach, here to show you how AirFit works. In the full version, I'll be uniquely tailored to your personality and goals!",
            voiceCharacteristics: VoiceCharacteristics(
                energy: .moderate,
                pace: .natural,
                warmth: .warm,
                vocabulary: .moderate,
                sentenceStructure: .moderate
            ),
            interactionStyle: InteractionStyle(
                greetingStyle: "Warm and welcoming",
                closingStyle: "Encouraging next steps",
                encouragementPhrases: [
                    "You're doing great!",
                    "Keep up the momentum!",
                    "Every step counts!"
                ],
                acknowledgmentStyle: "Positive reinforcement",
                correctionApproach: "Gentle guidance",
                humorLevel: .light,
                formalityLevel: .casual,
                responseLength: .moderate
            ),
            adaptationRules: [],
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "demo-1.0",
                sourceInsights: ConversationPersonalityInsights(
                    dominantTraits: ["supportive"],
                    communicationStyle: .supportive,
                    motivationType: .balanced,
                    energyLevel: .moderate,
                    preferredComplexity: .simple,
                    emotionalTone: ["encouraging"],
                    stressResponse: .needsSupport,
                    preferredTimes: ["flexible"],
                    extractedAt: Date()
                ),
                generationDuration: 2.0,
                tokenCount: 0,
                previewReady: true
            )
        )
    }
    
    /// Check if we should simulate a function call based on the request
    private func checkForFunctionCall(request: AIRequest) -> AIFunctionCall? {
        guard let lastMessage = request.messages.last?.content.lowercased() else {
            return nil
        }
        
        // Simulate function calls for specific keywords
        if lastMessage.contains("workout plan") || lastMessage.contains("create workout") {
            return AIFunctionCall(
                name: "generatePersonalizedWorkoutPlan",
                arguments: [
                    "goals": AIAnyCodable(["strength", "cardio"]),
                    "duration_minutes": AIAnyCodable(45),
                    "equipment": AIAnyCodable(["dumbbells", "resistance bands"]),
                    "intensity": AIAnyCodable("moderate")
                ]
            )
        } else if lastMessage.contains("log") && (lastMessage.contains("food") || lastMessage.contains("meal")) {
            return AIFunctionCall(
                name: "parseAndLogComplexNutrition",
                arguments: [
                    "food_text": AIAnyCodable("Demo: Grilled chicken salad with mixed greens"),
                    "context": AIAnyCodable("lunch")
                ]
            )
        } else if lastMessage.contains("analyze") && lastMessage.contains("performance") {
            return AIFunctionCall(
                name: "analyzePerformanceTrends",
                arguments: [
                    "metric_type": AIAnyCodable("overall"),
                    "time_period": AIAnyCodable("week")
                ]
            )
        }
        
        return nil
    }
}
