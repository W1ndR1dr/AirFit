import Foundation
@testable import AirFit

/// Stub AI service for testing
/// Provides predictable responses and configurable behavior for all AI operations
actor AIServiceStub: AIServiceProtocol {
    
    // MARK: - ServiceProtocol Properties
    
    nonisolated let serviceIdentifier = "ai-service-stub"
    private var _isConfigured = true
    nonisolated var isConfigured: Bool { true }
    
    // MARK: - AIServiceProtocol Properties
    
    private var _activeProvider: AIProvider = .gemini
    nonisolated var activeProvider: AIProvider { _activeProvider }
    
    nonisolated var availableModels: [AIModel] {
        [
            AIModel(
                id: "test-model",
                name: "Test AI Model",
                provider: .gemini,
                contextWindow: 100_000,
                costPerThousandTokens: AIModel.TokenCost(input: 0, output: 0)
            )
        ]
    }
    
    // MARK: - Configuration Properties
    
    var shouldThrowConfigurationError = false
    var shouldThrowRequestError = false
    var requestDelay: TimeInterval = 0
    var configurationDelay: TimeInterval = 0
    
    // MARK: - Response Configuration
    
    var mockResponseText = "This is a test AI response."
    var mockStructuredData: [String: Any]?
    var mockTokenUsage = AITokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30)
    var mockHealthStatus = ServiceHealth(
        status: .healthy,
        lastCheckTime: Date(),
        responseTime: 0.1,
        errorMessage: nil,
        metadata: ["mode": "test"]
    )
    
    // Response customization closures
    var responseGenerator: ((AIRequest) -> String)?
    var structuredDataGenerator: ((AIRequest) -> [String: Any]?)?
    var usageGenerator: ((AIRequest) -> AITokenUsage)?
    
    // MARK: - Call Tracking
    
    private(set) var configureCallCount = 0
    private(set) var sendRequestCallCount = 0
    private(set) var validateConfigurationCallCount = 0
    private(set) var checkHealthCallCount = 0
    private(set) var estimateTokenCountCallCount = 0
    private(set) var analyzeGoalCallCount = 0
    
    // MARK: - Request Tracking
    
    private(set) var lastRequest: AIRequest?
    private(set) var allRequests: [AIRequest] = []
    private(set) var lastConfigurationProvider: AIProvider?
    private(set) var lastConfigurationAPIKey: String?
    private(set) var lastConfigurationModel: String?
    private(set) var lastTokenCountText: String?
    private(set) var lastGoalText: String?
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        configureCallCount += 1
        
        if configurationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(configurationDelay * 1_000_000_000))
        }
        
        if shouldThrowConfigurationError {
            throw AppError.from(ServiceError.notConfigured)
        }
        
        _isConfigured = true
    }
    
    func reset() async {
        _isConfigured = false
        _activeProvider = .gemini
        
        // Reset call counts
        configureCallCount = 0
        sendRequestCallCount = 0
        validateConfigurationCallCount = 0
        checkHealthCallCount = 0
        estimateTokenCountCallCount = 0
        analyzeGoalCallCount = 0
        
        // Reset tracked data
        lastRequest = nil
        allRequests.removeAll()
        lastConfigurationProvider = nil
        lastConfigurationAPIKey = nil
        lastConfigurationModel = nil
        lastTokenCountText = nil
        lastGoalText = nil
        
        // Reset configuration
        shouldThrowConfigurationError = false
        shouldThrowRequestError = false
        requestDelay = 0
        configurationDelay = 0
        
        // Reset mock data
        mockResponseText = "This is a test AI response."
        mockStructuredData = nil
        mockTokenUsage = AITokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30)
    }
    
    func healthCheck() async -> ServiceHealth {
        checkHealthCallCount += 1
        return mockHealthStatus
    }
    
    // MARK: - AIServiceProtocol Methods
    
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        lastConfigurationProvider = provider
        lastConfigurationAPIKey = apiKey
        lastConfigurationModel = model
        _activeProvider = provider
        
        try await configure()
    }
    
    nonisolated func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                await self.handleSendRequest(request, continuation: continuation)
            }
        }
    }
    
    private func handleSendRequest(
        _ request: AIRequest,
        continuation: AsyncThrowingStream<AIResponse, Error>.Continuation
    ) async {
        sendRequestCallCount += 1
        lastRequest = request
        allRequests.append(request)
        
        do {
            if requestDelay > 0 {
                try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
            }
            
            if shouldThrowRequestError {
                throw AIError.unauthorized
            }
            
            // Generate response text
            let responseText: String
            if let generator = responseGenerator {
                responseText = generator(request)
            } else {
                responseText = generateContextualResponse(for: request)
            }
            
            // Generate structured data if configured
            let structuredData: [String: Any]?
            if let generator = structuredDataGenerator {
                structuredData = generator(request)
            } else {
                structuredData = mockStructuredData
            }
            
            // Generate usage
            let usage: AITokenUsage
            if let generator = usageGenerator {
                usage = generator(request)
            } else {
                usage = mockTokenUsage
            }
            
            // Send responses based on stream mode
            if request.stream {
                // Simulate streaming by splitting response into chunks
                let words = responseText.split(separator: " ")
                for word in words {
                    continuation.yield(.textDelta(String(word) + " "))
                    try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay between chunks
                }
            } else {
                // Send structured data if available
                if let structuredData = structuredData {
                    continuation.yield(.structuredData(structuredData))
                } else {
                    continuation.yield(.text(responseText))
                }
            }
            
            // Always send usage at the end
            continuation.yield(.done(usage: usage))
            continuation.finish()
            
        } catch {
            continuation.finish(throwing: error)
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        validateConfigurationCallCount += 1
        
        if shouldThrowConfigurationError {
            throw AppError.from(ServiceError.notConfigured)
        }
        
        return _isConfigured
    }
    
    func checkHealth() async -> ServiceHealth {
        await healthCheck()
    }
    
    nonisolated func estimateTokenCount(for text: String) -> Int {
        Task {
            await self.trackEstimateTokenCount(text: text)
        }
        // Simple estimation: ~4 characters per token
        return text.count / 4
    }
    
    private func trackEstimateTokenCount(text: String) {
        estimateTokenCountCallCount += 1
        lastTokenCountText = text
    }
    
    // MARK: - Response Generation
    
    private func generateContextualResponse(for request: AIRequest) -> String {
        guard let lastMessage = request.messages.last else {
            return mockResponseText
        }
        
        let content = lastMessage.content.lowercased()
        
        // Generate contextual responses based on content
        if content.contains("workout") {
            return "Based on your fitness goals, I recommend a 3-4 day per week workout routine focusing on compound movements."
        } else if content.contains("nutrition") || content.contains("food") {
            return "For optimal nutrition, aim for balanced macronutrients with adequate protein intake."
        } else if content.contains("goal") {
            return "That's a great goal! Let's create a structured plan to help you achieve it."
        } else if content.contains("recovery") {
            return "Recovery is crucial. Make sure you're getting adequate sleep and managing stress levels."
        } else if content.contains("progress") {
            return "Great progress! Let's continue building on your current momentum."
        } else {
            return mockResponseText
        }
    }
    
    // MARK: - Test Helper Methods
    
    /// Set up the stub to behave like a nutrition parsing AI
    func configureForNutritionParsing() {
        responseGenerator = { request in
            // Return JSON-like response for nutrition parsing
            return """
            {
                "items": [
                    {
                        "name": "Grilled Chicken Breast",
                        "brand": null,
                        "quantity": 150,
                        "unit": "grams",
                        "calories": 231,
                        "proteinGrams": 43.5,
                        "carbGrams": 0,
                        "fatGrams": 5.0,
                        "fiberGrams": 0,
                        "sugarGrams": 0,
                        "sodiumMilligrams": 74,
                        "confidence": 0.95
                    }
                ]
            }
            """
        }
        
        structuredDataGenerator = { request in
            return [
                "items": [
                    [
                        "name": "Grilled Chicken Breast",
                        "quantity": 150,
                        "unit": "grams",
                        "calories": 231,
                        "proteinGrams": 43.5,
                        "carbGrams": 0,
                        "fatGrams": 5.0,
                        "confidence": 0.95
                    ]
                ]
            ]
        }
    }
    
    /// Set up the stub to behave like a workout planning AI
    func configureForWorkoutPlanning() {
        responseGenerator = { request in
            return "Here's a personalized workout plan: Day 1: Upper body strength training, Day 2: Lower body, Day 3: Cardio and core."
        }
    }
    
    /// Set up the stub to simulate streaming responses
    func configureForStreaming() {
        responseGenerator = { request in
            return "This is a longer response that will be streamed word by word to simulate real AI streaming behavior."
        }
    }
    
    /// Configure error scenarios
    func configureForErrors() {
        shouldThrowRequestError = true
        mockHealthStatus = ServiceHealth(
            status: .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: "AI service unavailable",
            metadata: [:]
        )
    }
    
    /// Reset to default configuration
    func resetToDefaults() async {
        await reset()
        mockResponseText = "This is a test AI response."
        responseGenerator = nil
        structuredDataGenerator = nil
        usageGenerator = nil
        mockHealthStatus = ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: 0.1,
            errorMessage: nil,
            metadata: ["mode": "test"]
        )
    }
}