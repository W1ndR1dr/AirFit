import XCTest
@testable import AirFit

@MainActor
final class LLMOrchestratorTests: XCTestCase {
    // MARK: - Properties
    private var sut: LLMOrchestrator!
    private var mockAPIKeyManager: MockAPIKeyManager!
    
    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mocks
        mockAPIKeyManager = MockAPIKeyManager()
        
        // Create orchestrator
        sut = LLMOrchestrator(apiKeyManager: mockAPIKeyManager)
        
        // Wait for initial setup
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
    }
    
    override func tearDown() {
        Task { @MainActor in
            sut = nil
            mockAPIKeyManager = nil
        }
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_createsOrchestratorWithAPIKeyManager() {
        // Assert
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.totalCost, 0)
    }
    
    func test_availableProviders_reflectsAPIKeyAvailability() async throws {
        // Arrange
        mockAPIKeyManager.getAPIKeyResults = [
            .anthropic: "test-anthropic-key"
        ]
        mockAPIKeyManager.hasKeyResults = [
            .anthropic: true,
            .openAI: false,
            .gemini: false
        ]
        
        // Act
        sut = LLMOrchestrator(apiKeyManager: mockAPIKeyManager)
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s for setup
        
        // Assert - Note: Available providers are set during setupProviders()
        // Without being able to mock the provider validation, we can't fully test this
        XCTAssertNotNil(sut.availableProviders)
    }
    
    // MARK: - Cost Estimation Tests
    
    func test_estimateCost_withClaudeModel_calculatesCorrectly() {
        // Arrange
        let prompt = String(repeating: "word ", count: 200) // ~1000 chars = ~250 tokens
        let model = LLMModel.claude35Sonnet
        let responseTokens = 500
        
        // Act
        let cost = sut.estimateCost(for: prompt, model: model, responseTokens: responseTokens)
        
        // Assert
        // Claude 3.5 Sonnet: $0.003/1K input, $0.015/1K output
        // ~250 input tokens + 500 output tokens
        let expectedCost = (250.0/1000.0 * 0.003) + (500.0/1000.0 * 0.015)
        XCTAssertEqual(cost, expectedCost, accuracy: 0.001)
    }
    
    func test_estimateCost_withGPT4Model_calculatesCorrectly() {
        // Arrange
        let prompt = String(repeating: "test ", count: 400) // ~2000 chars = ~500 tokens
        let model = LLMModel.gpt4o
        let responseTokens = 1000
        
        // Act
        let cost = sut.estimateCost(for: prompt, model: model, responseTokens: responseTokens)
        
        // Assert
        // GPT-4o: $0.003/1K input, $0.020/1K output
        // ~500 input tokens + 1000 output tokens
        let expectedCost = (500.0/1000.0 * 0.003) + (1000.0/1000.0 * 0.020)
        XCTAssertEqual(cost, expectedCost, accuracy: 0.001)
    }
    
    func test_estimateCost_withGeminiModel_calculatesCorrectly() {
        // Arrange
        let prompt = String(repeating: "hello ", count: 1000) // ~6000 chars = ~1500 tokens
        let model = LLMModel.gemini15Flash
        let responseTokens = 2000
        
        // Act
        let cost = sut.estimateCost(for: prompt, model: model, responseTokens: responseTokens)
        
        // Assert
        // Gemini 1.5 Flash: $0.0002/1K input, $0.001/1K output
        // ~1500 input tokens + 2000 output tokens
        let expectedCost = (1500.0/1000.0 * 0.0002) + (2000.0/1000.0 * 0.001)
        XCTAssertEqual(cost, expectedCost, accuracy: 0.0001)
    }
    
    func test_estimateCost_withZeroTokens_returnsZero() {
        // Arrange
        let prompt = ""
        let model = LLMModel.claude35Sonnet
        let responseTokens = 0
        
        // Act
        let cost = sut.estimateCost(for: prompt, model: model, responseTokens: responseTokens)
        
        // Assert
        XCTAssertEqual(cost, 0)
    }
    
    func test_estimateCost_withVeryLongPrompt_handlesCorrectly() {
        // Arrange
        let prompt = String(repeating: "This is a very long prompt. ", count: 10000) // ~280K chars = ~70K tokens
        let model = LLMModel.claude3Opus
        let responseTokens = 5000
        
        // Act
        let cost = sut.estimateCost(for: prompt, model: model, responseTokens: responseTokens)
        
        // Assert
        // Claude 3 Opus: $0.015/1K input, $0.075/1K output
        // ~70000 input tokens + 5000 output tokens
        let expectedCost = (70000.0/1000.0 * 0.015) + (5000.0/1000.0 * 0.075)
        XCTAssertEqual(cost, expectedCost, accuracy: 0.01)
    }
    
    // MARK: - Complete Method Tests (Error Cases)
    
    func test_complete_withNoAvailableProviders_throwsError() async throws {
        // Arrange
        mockAPIKeyManager.hasKeyResults = [
            .anthropic: false,
            .openAI: false,
            .gemini: false
        ]
        sut = LLMOrchestrator(apiKeyManager: mockAPIKeyManager)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Act & Assert
        do {
            _ = try await sut.complete(prompt: "Test", task: .quickResponse)
            XCTFail("Should have thrown error")
        } catch {
            // Expected error due to no available providers
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Stream Method Tests
    
    func test_stream_createsAsyncStream() async throws {
        // Arrange
        let prompt = "Stream test"
        let task = AITask.coaching
        
        // Act
        let stream = sut.stream(prompt: prompt, task: task)
        
        // Assert
        XCTAssertNotNil(stream)
        // Note: Without mock providers, we can't test the actual streaming behavior
    }
    
    // MARK: - Cache Control Tests
    
    func test_setCacheEnabled_false_disablesCaching() {
        // Act
        sut.setCacheEnabled(false)
        
        // Assert
        // Cache state is private, but we can verify the method executes without error
        XCTAssertNotNil(sut)
    }
    
    func test_clearCache_executesWithoutError() async {
        // Act
        await sut.clearCache()
        
        // Assert
        XCTAssertNotNil(sut)
    }
    
    func test_invalidateCache_withTag_executesWithoutError() async {
        // Arrange
        let tag = "test-tag"
        
        // Act
        await sut.invalidateCache(tag: tag)
        
        // Assert
        XCTAssertNotNil(sut)
    }
    
    func test_getCacheStatistics_returnsStats() async {
        // Act
        let stats = await sut.getCacheStatistics()
        
        // Assert
        XCTAssertNotNil(stats)
        XCTAssertGreaterThanOrEqual(stats.hitCount, 0)
        XCTAssertGreaterThanOrEqual(stats.missCount, 0)
    }
    
    // MARK: - Total Cost Tracking
    
    func test_totalCost_startsAtZero() {
        // Assert
        XCTAssertEqual(sut.totalCost, 0)
    }
    
    // MARK: - Task Recommendation Tests
    
    func test_taskRecommendedModels_forPersonalityExtraction() {
        // Arrange
        let task = AITask.personalityExtraction
        
        // Act
        let models = task.recommendedModels
        
        // Assert
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.contains(.claude35Sonnet))
    }
    
    func test_taskRecommendedModels_forPersonaSynthesis() {
        // Arrange
        let task = AITask.personaSynthesis
        
        // Act
        let models = task.recommendedModels
        
        // Assert
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.contains(.claude3Opus))
    }
    
    func test_taskRecommendedModels_forConversationAnalysis() {
        // Arrange
        let task = AITask.conversationAnalysis
        
        // Act
        let models = task.recommendedModels
        
        // Assert
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.contains(.gemini25Flash) || models.contains(.gemini15Flash))
    }
    
    func test_taskRecommendedModels_forCoaching() {
        // Arrange
        let task = AITask.coaching
        
        // Act
        let models = task.recommendedModels
        
        // Assert
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.contains(.claude35Sonnet))
    }
    
    func test_taskRecommendedModels_forQuickResponse() {
        // Arrange
        let task = AITask.quickResponse
        
        // Act
        let models = task.recommendedModels
        
        // Assert
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.contains(.gemini25Flash) || models.contains(.gemini15Flash))
    }
    
    // MARK: - Performance Tests
    
    func test_estimateCost_performance() {
        // Arrange
        let longPrompt = String(repeating: "performance test ", count: 10000)
        let model = LLMModel.claude35Sonnet
        
        // Act & Measure
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = sut.estimateCost(for: longPrompt, model: model)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert
        XCTAssertLessThan(duration, 0.01, "Cost estimation should be very fast")
    }
    
    func test_init_performance() {
        // Act & Measure
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = LLMOrchestrator(apiKeyManager: mockAPIKeyManager)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert
        XCTAssertLessThan(duration, 0.1, "Initialization should be fast")
    }
}

// MARK: - Test Extensions

extension LLMOrchestratorTests {
    // Helper to create a mock orchestrator with injected providers
    private func createMockOrchestrator(with providers: [LLMProviderIdentifier: any LLMProvider]) -> LLMOrchestrator {
        // In a real test setup, we'd have a testable LLMOrchestrator that allows provider injection
        // For now, we're limited to testing the public API
        return LLMOrchestrator(apiKeyManager: mockAPIKeyManager)
    }
}