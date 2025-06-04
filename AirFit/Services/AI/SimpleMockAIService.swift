import Foundation

/// Simple mock AI service for backward compatibility
@MainActor
final class SimpleMockAIService: AIServiceProtocol {
    
    // MARK: - Properties
    let serviceIdentifier = "mock-ai-service"
    private(set) var isConfigured: Bool = true
    private(set) var activeProvider: AIProvider = .openAI
    private(set) var availableModels: [AIModel] = []
    
    private var responses: [String: String] = [:]
    private var shouldThrowError = false
    private var delay: TimeInterval = 0.5
    
    init() {
        // Setup default responses
        self.responses = [
            "lose weight": "Great goal! Focus on creating a sustainable caloric deficit through balanced nutrition and regular exercise.",
            "build muscle": "Excellent! Prioritize progressive overload training and adequate protein intake for optimal muscle growth.",
            "get fit": "Wonderful goal! A combination of cardiovascular exercise and strength training will help improve your overall fitness.",
            "eat healthier": "Perfect! Focus on whole foods, adequate hydration, and balanced macronutrients for better health."
        ]
        
        // Mock available models
        self.availableModels = [
            AIModel(
                id: "mock-model",
                name: "Mock Model",
                provider: .openAI,
                contextWindow: 4096,
                costPerThousandTokens: AIModel.TokenCost(input: 0.0, output: 0.0)
            )
        ]
    }
    
    // MARK: - ServiceProtocol
    
    func configure() async throws {
        isConfigured = true
    }
    
    func reset() async {
        isConfigured = false
        responses.removeAll()
        shouldThrowError = false
    }
    
    func healthCheck() async -> ServiceHealth {
        return ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: 0.001,
            errorMessage: nil,
            metadata: ["type": "mock"]
        )
    }
    
    // MARK: - AIServiceProtocol
    
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        activeProvider = provider
        isConfigured = true
    }
    
    func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                // Simulate network delay
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                if shouldThrowError {
                    continuation.finish(throwing: ServiceError.unknown(NSError(domain: "MockError", code: -1)))
                    return
                }
                
                // Extract the user's message
                let userMessage = request.messages.last(where: { $0.role == .user })?.content ?? ""
                
                // Generate response
                let responseText = responses[userMessage.lowercased()] ?? generateDefaultResponse(for: userMessage)
                
                if request.stream {
                    // Simulate streaming
                    let words = responseText.split(separator: " ")
                    for word in words {
                        continuation.yield(.textDelta(String(word) + " "))
                        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms between words
                    }
                } else {
                    continuation.yield(.text(responseText))
                }
                
                continuation.yield(.done(usage: AITokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30)))
                continuation.finish()
            }
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        return isConfigured
    }
    
    func checkHealth() async -> ServiceHealth {
        return await healthCheck()
    }
    
    func estimateTokenCount(for text: String) -> Int {
        return text.count / 4
    }
    
    // MARK: - Legacy Support
    
    func analyzeGoal(_ goalText: String) async throws -> String {
        let request = AIRequest(
            systemPrompt: "",
            messages: [AIChatMessage(role: .user, content: goalText)],
            functions: nil,
            temperature: 0.7,
            maxTokens: 150,
            stream: false,
            user: "mock-user"
        )
        
        var responseText = ""
        for try await response in sendRequest(request) {
            switch response {
            case .text(let content):
                responseText = content
            case .textDelta(let delta):
                responseText += delta
            default:
                break
            }
        }
        
        return responseText
    }
    
    // MARK: - Test Configuration
    
    func setResponse(for goal: String, response: String) {
        responses[goal.lowercased()] = response
    }
    
    func setShouldThrowError(_ shouldThrow: Bool) {
        shouldThrowError = shouldThrow
    }
    
    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }
    
    // MARK: - Private Methods
    
    private func generateDefaultResponse(for goalText: String) -> String {
        return "I understand your goal: '\(goalText)'. This is a great step towards improving your health and fitness. Let's work together to create a personalized plan that fits your lifestyle and preferences."
    }
}