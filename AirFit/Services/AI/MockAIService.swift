import Foundation

/// Mock AI service for testing and development
@MainActor
final class MockAIService: AIServiceProtocol {
    private var responses: [String: String] = [:]
    private var shouldThrowError = false
    private var delay: TimeInterval = 0.5
    private var _isConfigured = true
    private var _activeProvider: AIProvider = .openAI

    init() {
        // Setup default responses synchronously
        self.responses = [
            "lose weight": "Great goal! Focus on creating a sustainable caloric deficit through balanced nutrition and regular exercise.",
            "build muscle": "Excellent! Prioritize progressive overload training and adequate protein intake for optimal muscle growth.",
            "get fit": "Wonderful goal! A combination of cardiovascular exercise and strength training will help improve your overall fitness.",
            "eat healthier": "Perfect! Focus on whole foods, adequate hydration, and balanced macronutrients for better health."
        ]
    }
    
    // MARK: - AIServiceProtocol
    
    var isConfigured: Bool { _isConfigured }
    var activeProvider: AIProvider { _activeProvider }
    var availableModels: [AIModel] { [] }
    
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        _activeProvider = provider
        _isConfigured = true
    }
    
    func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    if shouldThrowError {
                        continuation.yield(.error(AIError.networkError("Mock error")))
                    } else {
                        let response = generateMockResponse(for: request)
                        continuation.yield(.text(response))
                        continuation.yield(.done(usage: AITokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30)))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        return _isConfigured
    }
    
    func checkHealth() async -> ServiceHealth {
        ServiceHealth(
            status: shouldThrowError ? .unhealthy : .healthy,
            lastCheckTime: Date(),
            responseTime: delay,
            errorMessage: shouldThrowError ? "Mock error" : nil,
            metadata: [:]
        )
    }
    
    func estimateTokenCount(for text: String) -> Int {
        text.count / 4 // Rough estimate
    }
    
    // MARK: - ServiceProtocol
    
    var serviceIdentifier: String { "mock_ai_service" }
    
    func configure() async throws {
        _isConfigured = true
    }
    
    func reset() async {
        _isConfigured = false
        responses.removeAll()
        shouldThrowError = false
    }
    
    func healthCheck() async -> ServiceHealth {
        await checkHealth()
    }

    func analyzeGoal(_ goalText: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        if shouldThrowError {
            throw AIError.networkError("Mock error for testing")
        }

        // Return mock response based on goal text
        return responses[goalText.lowercased()] ?? generateDefaultResponse(for: goalText)
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
    
    private func generateMockResponse(for request: AIRequest) -> String {
        if let lastMessage = request.messages.last {
            return generateDefaultResponse(for: lastMessage.content)
        }
        return "Mock AI response"
    }

    private func generateDefaultResponse(for goalText: String) -> String {
        return "I understand your goal: '\(goalText)'. This is a great step towards improving your health and fitness. Let's work together to create a personalized plan that fits your lifestyle and preferences."
    }
}
