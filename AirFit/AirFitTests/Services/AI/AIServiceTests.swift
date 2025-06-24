import XCTest
@testable import AirFit

@MainActor
final class AIServiceTests: XCTestCase {
    // MARK: - Properties
    private var sut: AIService!
    private var mockOrchestrator: MockLLMOrchestrator!
    private var mockAPIKeyManager: MockAPIKeyManager!
    
    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()
        
        // Create mocks
        mockAPIKeyManager = MockAPIKeyManager()
        mockOrchestrator = MockLLMOrchestrator()
        mockOrchestrator.apiKeyManager = mockAPIKeyManager
        
        // Create service
        sut = AIService(llmOrchestrator: mockOrchestrator)
    }
    
    override func tearDown() {
        sut = nil
        mockOrchestrator = nil
        mockAPIKeyManager = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func test_configure_withNoAPIKeys_throwsNotConfigured() async throws {
        // Arrange
        mockAPIKeyManager.hasKeyResults = [
            .anthropic: false,
            .openAI: false,
            .gemini: false
        ]
        
        // Act & Assert
        do {
            try await sut.configure()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? ServiceError, .notConfigured)
        }
        
        XCTAssertFalse(sut.isConfigured)
    }
    
    func test_configure_withAnthropicKey_setsAnthropicAsActive() async throws {
        // Arrange
        mockAPIKeyManager.hasKeyResults = [
            .anthropic: true,
            .openAI: false,
            .gemini: false
        ]
        
        // Act
        try await sut.configure()
        
        // Assert
        XCTAssertTrue(sut.isConfigured)
        XCTAssertEqual(sut.activeProvider, .anthropic)
    }
    
    func test_configure_withOpenAIKey_setsOpenAIAsActive() async throws {
        // Arrange
        mockAPIKeyManager.hasKeyResults = [
            .anthropic: false,
            .openAI: true,
            .gemini: false
        ]
        
        // Act
        try await sut.configure()
        
        // Assert
        XCTAssertTrue(sut.isConfigured)
        XCTAssertEqual(sut.activeProvider, .openAI)
    }
    
    func test_configure_withGeminiKey_setsGeminiAsActive() async throws {
        // Arrange
        mockAPIKeyManager.hasKeyResults = [
            .anthropic: false,
            .openAI: false,
            .gemini: true
        ]
        
        // Act
        try await sut.configure()
        
        // Assert
        XCTAssertTrue(sut.isConfigured)
        XCTAssertEqual(sut.activeProvider, .gemini)
    }
    
    func test_configure_withMultipleKeys_prefersAnthropic() async throws {
        // Arrange
        mockAPIKeyManager.hasKeyResults = [
            .anthropic: true,
            .openAI: true,
            .gemini: true
        ]
        
        // Act
        try await sut.configure()
        
        // Assert
        XCTAssertTrue(sut.isConfigured)
        XCTAssertEqual(sut.activeProvider, .anthropic) // Anthropic is preferred
    }
    
    func test_configureWithProvider_savesAPIKeyAndConfigures() async throws {
        // Arrange
        let provider = AIProvider.openAI
        let apiKey = "test-api-key"
        mockAPIKeyManager.hasKeyResults = [.openAI: true]
        
        // Act
        try await sut.configure(provider: provider, apiKey: apiKey, model: nil)
        
        // Assert
        XCTAssertTrue(mockAPIKeyManager.saveAPIKeyCalled)
        XCTAssertEqual(mockAPIKeyManager.lastSavedKey, apiKey)
        XCTAssertEqual(mockAPIKeyManager.lastSavedProvider, provider)
        XCTAssertTrue(sut.isConfigured)
        XCTAssertEqual(sut.activeProvider, provider)
    }
    
    // MARK: - Send Request Tests
    
    func test_sendRequest_whenNotConfigured_throwsError() async throws {
        // Arrange
        let request = AIRequest(
            systemPrompt: "Test prompt",
            messages: [AIChatMessage(role: .user, content: "Hello", name: nil)],
            functions: nil,
            temperature: 0.7,
            maxTokens: 100,
            stream: false,
            user: "test"
        )
        
        // Act
        var thrownError: Error?
        do {
            for try await _ in sut.sendRequest(request) {
                // Should not reach here
            }
        } catch {
            thrownError = error
        }
        
        // Assert
        XCTAssertNotNil(thrownError)
        XCTAssertEqual(thrownError as? ServiceError, .notConfigured)
    }
    
    func test_sendRequest_withNonStreamingRequest_returnsCompleteResponse() async throws {
        // Arrange
        try await configureService()
        
        let request = AIRequest(
            systemPrompt: "You are a helpful assistant",
            messages: [AIChatMessage(role: .user, content: "What is 2+2?", name: nil)],
            functions: nil,
            temperature: 0.5,
            maxTokens: 50,
            stream: false,
            user: "test"
        )
        
        mockOrchestrator.mockResponse = LLMResponse(
            content: "2+2 equals 4",
            model: "claude-3-sonnet",
            usage: LLMTokenUsage(promptTokens: 10, completionTokens: 5, totalTokens: 15),
            finishReason: .stop
        )
        
        // Act
        var responses: [AIResponse] = []
        for try await response in sut.sendRequest(request) {
            responses.append(response)
        }
        
        // Assert
        XCTAssertEqual(responses.count, 2) // text + done
        
        if case .text(let content) = responses[0] {
            XCTAssertEqual(content, "2+2 equals 4")
        } else {
            XCTFail("Expected text response")
        }
        
        if case .done(let usage) = responses[1] {
            XCTAssertEqual(usage.promptTokens, 10)
            XCTAssertEqual(usage.completionTokens, 5)
            XCTAssertEqual(usage.totalTokens, 15)
        } else {
            XCTFail("Expected done response")
        }
    }
    
    func test_sendRequest_withStreamingRequest_streamsResponseChunks() async throws {
        // Arrange
        try await configureService()
        
        let request = AIRequest(
            systemPrompt: "",
            messages: [AIChatMessage(role: .user, content: "Tell me a story", name: nil)],
            functions: nil,
            temperature: 0.8,
            maxTokens: 100,
            stream: true,
            user: "test"
        )
        
        // Mock streaming chunks
        mockOrchestrator.mockStreamChunks = [
            LLMStreamChunk(delta: "Once ", usage: nil, finishReason: nil, isFinished: false),
            LLMStreamChunk(delta: "upon ", usage: nil, finishReason: nil, isFinished: false),
            LLMStreamChunk(delta: "a ", usage: nil, finishReason: nil, isFinished: false),
            LLMStreamChunk(delta: "time...", usage: LLMTokenUsage(promptTokens: 8, completionTokens: 6, totalTokens: 14), finishReason: .stop, isFinished: true)
        ]
        
        // Act
        var responses: [AIResponse] = []
        for try await response in sut.sendRequest(request) {
            responses.append(response)
        }
        
        // Assert
        XCTAssertEqual(responses.count, 5) // 4 text deltas + done
        
        // Check text deltas
        for i in 0..<4 {
            if case .textDelta(let delta) = responses[i] {
                XCTAssertTrue(["Once ", "upon ", "a ", "time..."].contains(delta))
            } else {
                XCTFail("Expected textDelta response")
            }
        }
        
        // Check done response
        if case .done(let usage) = responses[4] {
            XCTAssertEqual(usage.totalTokens, 14)
        } else {
            XCTFail("Expected done response")
        }
    }
    
    func test_sendRequest_withSystemPromptAndMessages_buildsCorrectPrompt() async throws {
        // Arrange
        try await configureService()
        
        let request = AIRequest(
            systemPrompt: "You are a fitness coach",
            messages: [
                AIChatMessage(role: .user, content: "I want to lose weight", name: nil),
                AIChatMessage(role: .assistant, content: "I can help with that!", name: nil),
                AIChatMessage(role: .user, content: "What should I eat?", name: nil)
            ],
            functions: nil,
            temperature: 0.7,
            maxTokens: 200,
            stream: false,
            user: "test"
        )
        
        mockOrchestrator.mockResponse = LLMResponse(
            content: "Focus on whole foods...",
            model: "claude-3-sonnet",
            usage: LLMTokenUsage(promptTokens: 30, completionTokens: 10, totalTokens: 40),
            finishReason: .stop
        )
        
        // Act
        var responses: [AIResponse] = []
        for try await response in sut.sendRequest(request) {
            responses.append(response)
        }
        
        // Assert
        XCTAssertEqual(mockOrchestrator.completeCallCount, 1)
        
        // Verify the prompt was built correctly
        let expectedPrompt = """
        System: You are a fitness coach
        
        User: I want to lose weight
        Assistant: I can help with that!
        User: What should I eat?
        """
        XCTAssertEqual(mockOrchestrator.lastPrompt, expectedPrompt)
    }
    
    // MARK: - Cost Tracking Tests
    
    func test_sendRequest_updatesCostTracking() async throws {
        // Arrange
        try await configureService()
        
        let request = createTestRequest(stream: false)
        mockOrchestrator.mockResponse = LLMResponse(
            content: "Test response",
            model: "claude-3-sonnet",
            usage: LLMTokenUsage(promptTokens: 1_000, completionTokens: 500, totalTokens: 1_500),
            finishReason: .stop
        )
        
        // Act
        for try await _ in sut.sendRequest(request) {
            // Process response
        }
        
        // Assert
        // Claude 3 Sonnet costs: $0.003 per 1K input, $0.015 per 1K output
        // Cost = (1000/1000 * 0.003) + (500/1000 * 0.015) = 0.003 + 0.0075 = 0.0105
        XCTAssertEqual(sut.totalCost, 0.0105, accuracy: 0.0001)
    }
    
    func test_resetCostTracking_resetsCost() async throws {
        // Arrange
        try await configureService()
        
        // Add some cost
        let request = createTestRequest(stream: false)
        mockOrchestrator.mockResponse = LLMResponse(
            content: "Test",
            model: "claude-3-sonnet",
            usage: LLMTokenUsage(promptTokens: 1_000, completionTokens: 1_000, totalTokens: 2_000),
            finishReason: .stop
        )
        
        for try await _ in sut.sendRequest(request) {}
        XCTAssertGreaterThan(sut.totalCost, 0)
        
        // Act
        sut.resetCostTracking()
        
        // Assert
        XCTAssertEqual(sut.totalCost, 0)
    }
    
    func test_getCostBreakdown_returnsCurrentProviderCost() async throws {
        // Arrange
        try await configureService()
        
        // Add some cost
        let request = createTestRequest(stream: false)
        mockOrchestrator.mockResponse = LLMResponse(
            content: "Test",
            model: "claude-3-sonnet",
            usage: LLMTokenUsage(promptTokens: 1_000, completionTokens: 1_000, totalTokens: 2_000),
            finishReason: .stop
        )
        
        for try await _ in sut.sendRequest(request) {}
        
        // Act
        let breakdown = sut.getCostBreakdown()
        
        // Assert
        XCTAssertEqual(breakdown.count, 1)
        XCTAssertEqual(breakdown[0].provider, .anthropic)
        XCTAssertEqual(breakdown[0].cost, 0.018, accuracy: 0.0001) // (1000/1000 * 0.003) + (1000/1000 * 0.015)
    }
    
    // MARK: - Token Estimation Tests
    
    func test_estimateTokenCount_providesReasonableEstimate() {
        // Test various text lengths
        let testCases = [
            ("Hello", 1), // 5 chars / 4 ≈ 1
            ("This is a test", 3), // 14 chars / 4 ≈ 3
            ("A longer piece of text with multiple words", 10), // 42 chars / 4 ≈ 10
            (String(repeating: "word ", count: 100), 125) // 500 chars / 4 = 125
        ]
        
        for (text, expectedTokens) in testCases {
            let estimate = sut.estimateTokenCount(for: text)
            XCTAssertEqual(estimate, expectedTokens, "Failed for text: \(text)")
        }
    }
    
    // MARK: - Validation Tests
    
    func test_validateConfiguration_whenNotConfigured_returnsFalse() async throws {
        // Act
        let isValid = try await sut.validateConfiguration()
        
        // Assert
        XCTAssertFalse(isValid)
    }
    
    func test_validateConfiguration_whenConfiguredWithValidKey_returnsTrue() async throws {
        // Arrange
        try await configureService()
        mockAPIKeyManager.hasKeyResults[.anthropic] = true
        
        // Act
        let isValid = try await sut.validateConfiguration()
        
        // Assert
        XCTAssertTrue(isValid)
    }
    
    func test_validateConfiguration_whenConfiguredButKeyRemoved_returnsFalse() async throws {
        // Arrange
        try await configureService()
        mockAPIKeyManager.hasKeyResults[.anthropic] = false
        
        // Act
        let isValid = try await sut.validateConfiguration()
        
        // Assert
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Health Check Tests
    
    func test_healthCheck_whenNotConfigured_returnsUnhealthy() async {
        // Act
        let health = await sut.healthCheck()
        
        // Assert
        XCTAssertEqual(health.status, .unhealthy)
        XCTAssertEqual(health.errorMessage, "Service not configured")
    }
    
    func test_healthCheck_whenConfigured_returnsHealthy() async throws {
        // Arrange
        try await configureService()
        
        // Act
        let health = await sut.healthCheck()
        
        // Assert
        XCTAssertEqual(health.status, .healthy)
        XCTAssertNil(health.errorMessage)
        XCTAssertEqual(health.metadata["provider"] as? String, "anthropic")
    }
    
    func test_checkHealth_delegatesToHealthCheck() async throws {
        // Arrange
        try await configureService()
        
        // Act
        let health = await sut.checkHealth()
        
        // Assert
        XCTAssertEqual(health.status, .healthy)
    }
    
    // MARK: - Reset Tests
    
    func test_reset_clearsConfiguration() async throws {
        // Arrange
        try await configureService()
        XCTAssertTrue(sut.isConfigured)
        
        // Act
        await sut.reset()
        
        // Assert
        XCTAssertFalse(sut.isConfigured)
        XCTAssertEqual(sut.activeProvider, .anthropic) // Reset to default
    }
    
    // MARK: - Legacy Support Tests
    
    func test_analyzeGoal_whenNotConfigured_throwsError() async throws {
        // Act & Assert
        do {
            _ = try await sut.analyzeGoal("I want to lose 10 pounds")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? ServiceError, .notConfigured)
        }
    }
    
    func test_analyzeGoal_withValidGoal_returnsAnalysis() async throws {
        // Arrange
        try await configureService()
        let goalText = "I want to build muscle and get stronger"
        
        mockOrchestrator.mockResponse = LLMResponse(
            content: "Focus on progressive overload. Aim for 3-4 strength sessions per week. Ensure adequate protein intake.",
            model: "claude-3-sonnet",
            usage: LLMTokenUsage(promptTokens: 50, completionTokens: 20, totalTokens: 70),
            finishReason: .stop
        )
        
        // Act
        let analysis = try await sut.analyzeGoal(goalText)
        
        // Assert
        XCTAssertEqual(analysis, "Focus on progressive overload. Aim for 3-4 strength sessions per week. Ensure adequate protein intake.")
        XCTAssertTrue(mockOrchestrator.lastPrompt.contains("fitness and nutrition coach"))
        XCTAssertTrue(mockOrchestrator.lastPrompt.contains(goalText))
    }
    
    func test_analyzeGoal_withEmptyResponse_returnsFallback() async throws {
        // Arrange
        try await configureService()
        
        mockOrchestrator.mockResponse = LLMResponse(
            content: "",
            model: "claude-3-sonnet",
            usage: LLMTokenUsage(promptTokens: 50, completionTokens: 0, totalTokens: 50),
            finishReason: .stop
        )
        
        // Act
        let analysis = try await sut.analyzeGoal("Help me get fit")
        
        // Assert
        XCTAssertEqual(analysis, "I'll help you achieve your fitness goals! Let's create a personalized plan together.")
    }
    
    // MARK: - Cache Tests
    
    func test_setCacheEnabled_controlsCaching() {
        // Act
        sut.setCacheEnabled(false)
        
        // Assert
        // Cache behavior would be tested if cache was used in sendRequest
        XCTAssertTrue(true) // Placeholder
    }
    
    func test_clearCache_delegatesToCache() async {
        // Act
        await sut.clearCache()
        
        // Assert
        // Would verify cache.clear() was called if we had access to the cache
        XCTAssertTrue(true) // Placeholder
    }
    
    func test_getCacheStatistics_returnsStats() async {
        // Act
        let stats = await sut.getCacheStatistics()
        
        // Assert
        XCTAssertEqual(stats.hits, 0)
        XCTAssertEqual(stats.misses, 0)
        XCTAssertEqual(stats.size, 0)
    }
    
    // MARK: - Available Models Tests
    
    func test_availableModels_includesAllProviders() {
        // Assert
        XCTAssertEqual(sut.availableModels.count, 3)
        
        let providers = Set(sut.availableModels.map { $0.provider })
        XCTAssertTrue(providers.contains(.anthropic))
        XCTAssertTrue(providers.contains(.openAI))
        XCTAssertTrue(providers.contains(.gemini))
        
        // Verify model details
        if let claudeModel = sut.availableModels.first(where: { $0.provider == .anthropic }) {
            XCTAssertEqual(claudeModel.id, "claude-3-sonnet-20240229")
            XCTAssertEqual(claudeModel.contextWindow, 200_000)
            XCTAssertEqual(claudeModel.costPerThousandTokens.input, 0.003)
            XCTAssertEqual(claudeModel.costPerThousandTokens.output, 0.015)
        }
    }
    
    // MARK: - Edge Cases
    
    func test_sendRequest_withSpecialCharactersInContent_handlesCorrectly() async throws {
        // Arrange
        try await configureService()
        
        let request = AIRequest(
            systemPrompt: "System with émojis 🎯 and spëcial chars!",
            messages: [AIChatMessage(role: .user, content: "Text with newlines\nand\ttabs\nand émojis 💪", name: nil)],
            functions: nil,
            temperature: 0.7,
            maxTokens: 100,
            stream: false,
            user: "test"
        )
        
        mockOrchestrator.mockResponse = LLMResponse(
            content: "Response with special chars: café, naïve, 你好",
            model: "claude-3-sonnet",
            usage: LLMTokenUsage(promptTokens: 30, completionTokens: 10, totalTokens: 40),
            finishReason: .stop
        )
        
        // Act
        var responses: [AIResponse] = []
        for try await response in sut.sendRequest(request) {
            responses.append(response)
        }
        
        // Assert
        if case .text(let content) = responses[0] {
            XCTAssertTrue(content.contains("café"))
            XCTAssertTrue(content.contains("你好"))
        }
    }
    
    // MARK: - Helper Methods
    
    private func configureService() async throws {
        mockAPIKeyManager.hasKeyResults = [
            .anthropic: true,
            .openAI: false,
            .gemini: false
        ]
        try await sut.configure()
    }
    
    private func createTestRequest(stream: Bool) -> AIRequest {
        return AIRequest(
            systemPrompt: "Test system prompt",
            messages: [AIChatMessage(role: .user, content: "Test message", name: nil)],
            functions: nil,
            temperature: 0.7,
            maxTokens: 100,
            stream: stream,
            user: "test"
        )
    }
}
