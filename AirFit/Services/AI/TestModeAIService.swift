import Foundation

/// AI service that returns mock data for testing the UI without real API calls
actor TestModeAIService: @preconcurrency AIServiceProtocol {
    // MARK: - ServiceProtocol
    var isConfigured: Bool { true }
    var serviceIdentifier: String { "test_mode_ai_service" }
    
    func configure() async throws {
        // Already configured for test mode
    }
    
    func reset() async {
        // No-op for test service
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: 0.1,
            errorMessage: nil,
            metadata: ["mode": "test"]
        )
    }
    
    // MARK: - AIServiceProtocol
    var activeProvider: AIProvider { .openAI }
    var availableModels: [AIModel] { 
        [
            AIModel(
                id: "gpt-4",
                name: "GPT-4",
                provider: .openAI,
                contextWindow: 8192,
                costPerThousandTokens: AIModel.TokenCost(input: 0.03, output: 0.06)
            ),
            AIModel(
                id: "gpt-3.5-turbo",
                name: "GPT-3.5 Turbo",
                provider: .openAI,
                contextWindow: 4096,
                costPerThousandTokens: AIModel.TokenCost(input: 0.001, output: 0.002)
            )
        ]
    }
    
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        // No-op - always configured in test mode
    }
    
    func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                // Simulate API delay
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Generate appropriate response based on the request
                if let lastMessage = request.messages.last {
                    let response = generateMockResponse(for: lastMessage.content, functions: request.functions)
                    
                    // Simulate streaming response
                    let words = response.split(separator: " ")
                    for word in words {
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                        continuation.yield(.textDelta(String(word) + " "))
                    }
                    
                    // If there are functions defined and the response suggests calling one
                    if let functions = request.functions, !functions.isEmpty {
                        // Sometimes simulate a function call
                        if lastMessage.content.lowercased().contains("workout") {
                            continuation.yield(.functionCall(AIFunctionCall(
                                name: "generateWorkout",
                                arguments: ["duration": 30, "difficulty": "moderate"]
                            )))
                        } else if lastMessage.content.lowercased().contains("nutrition") || lastMessage.content.lowercased().contains("food") {
                            continuation.yield(.functionCall(AIFunctionCall(
                                name: "parseNutrition",
                                arguments: ["text": lastMessage.content]
                            )))
                        }
                    }
                }
                
                // Send completion with usage info
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
        true
    }
    
    func checkHealth() async -> ServiceHealth {
        await healthCheck()
    }
    
    func estimateTokenCount(for text: String) -> Int {
        text.count / 4
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockResponse(for message: String, functions: [AIFunctionDefinition]?) -> String {
        let lowercased = message.lowercased()
        
        if lowercased.contains("hello") || lowercased.contains("hi") {
            return "Hey there! Great to see you! How are you feeling today? Ready to crush some fitness goals?"
        } else if lowercased.contains("workout") {
            return "I'd love to help you with your workout! Are you looking for strength training, cardio, or maybe a mix of both today?"
        } else if lowercased.contains("food") || lowercased.contains("eat") {
            return "Nutrition is so important! Tell me what you had or what you're planning to eat, and I'll help you track it."
        } else if lowercased.contains("tired") || lowercased.contains("sore") {
            return "Rest and recovery are just as important as training! How about we focus on some light stretching or mobility work today?"
        } else if lowercased.contains("persona") || lowercased.contains("coach") {
            return "I'm Coach Alex, your enthusiastic fitness partner! I believe in making fitness fun and sustainable. I'll help you build strength, improve nutrition, and develop lasting healthy habits. Let's make every day a step toward your best self!"
        } else {
            return "That's a great question! Let me help you with that. In test mode, I'm providing mock responses, but in the real app, I'd give you personalized advice based on your goals and history."
        }
    }
}