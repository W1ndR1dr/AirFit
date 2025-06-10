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
                
                // Get a random response
                let response = demoResponses.randomElement() ?? demoResponses[0]
                
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
                
                continuation.finish()
            }
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
}