import XCTest
@testable import AirFit

final class AIServiceTests: AirFitTestCase {
    
    var aiServiceStub: AIServiceStub!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        aiServiceStub = AIServiceStub()
    }
    
    override func tearDownWithError() throws {
        Task { await aiServiceStub?.resetToDefaults() }
        aiServiceStub = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Configuration Tests
    
    func testConfigure_Success() async throws {
        // Act
        try await aiServiceStub.configure()
        
        // Assert
        let configCount = await aiServiceStub.configureCallCount
        XCTAssertEqual(configCount, 1)
        XCTAssertTrue(aiServiceStub.isConfigured)
    }
    
    func testConfigure_WithDelay() async throws {
        // Arrange
        let delay: TimeInterval = 0.1
        await aiServiceStub.setConfigurationDelay(delay)
        
        // Act
        let startTime = Date()
        try await aiServiceStub.configure()
        let duration = Date().timeIntervalSince(startTime)
        
        // Assert
        XCTAssertGreaterThanOrEqual(duration, delay)
    }
    
    func testConfigure_Failure() async {
        // Arrange
        await aiServiceStub.setShouldThrowConfigurationError(true)
        
        // Act & Assert
        do {
            try await aiServiceStub.configure()
            XCTFail("Expected configuration error")
        } catch {
            let configCount = await aiServiceStub.configureCallCount
            XCTAssertEqual(configCount, 1)
            XCTAssertTrue(error is AppError)
        }
    }
    
    func testConfigureWithProvider_TracksParameters() async throws {
        // Act
        try await aiServiceStub.configure(provider: .anthropic, apiKey: "test-key", model: "test-model")
        
        // Assert
        let lastProvider = await aiServiceStub.lastConfigurationProvider
        let lastKey = await aiServiceStub.lastConfigurationAPIKey
        let lastModel = await aiServiceStub.lastConfigurationModel
        
        XCTAssertEqual(lastProvider, .anthropic)
        XCTAssertEqual(lastKey, "test-key")
        XCTAssertEqual(lastModel, "test-model")
    }
    
    // MARK: - Request Tests
    
    func testSendRequest_TextResponse() async throws {
        // Arrange
        let request = MockDataGenerator.createMockAIRequest(
            userMessage: "Help me with my workout"
        )
        
        // Act
        let responses = try await AsyncTestUtilities.collect(
            from: aiServiceStub.sendRequest(request),
            timeout: 5.0
        )
        
        // Assert
        let requestCount = await aiServiceStub.sendRequestCallCount
        let lastRequest = await aiServiceStub.lastRequest
        
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(lastRequest?.messages.first?.content, "Help me with my workout")
        XCTAssertGreaterThan(responses.count, 0)
        
        // Check for text response and usage
        let hasTextResponse = responses.contains { response in
            if case .text = response { return true }
            return false
        }
        let hasUsage = responses.contains { response in
            if case .done = response { return true }
            return false
        }
        
        XCTAssertTrue(hasTextResponse)
        XCTAssertTrue(hasUsage)
    }
    
    func testSendRequest_StreamingResponse() async throws {
        // Arrange
        await aiServiceStub.configureForStreaming()
        let request = MockDataGenerator.createMockAIRequest(
            userMessage: "Stream this response",
            stream: true
        )
        
        // Act
        let responses = try await AsyncTestUtilities.collect(
            from: aiServiceStub.sendRequest(request),
            timeout: 5.0
        )
        
        // Assert
        let textDeltas = responses.compactMap { response in
            if case .textDelta(let delta) = response { return delta }
            return nil
        }
        
        XCTAssertGreaterThan(textDeltas.count, 1) // Should have multiple chunks
        XCTAssertTrue(textDeltas.allSatisfy { !$0.isEmpty })
    }
    
    func testSendRequest_NutritionParsing() async throws {
        // Arrange
        await aiServiceStub.configureForNutritionParsing()
        let request = MockDataGenerator.createMockAIRequest(
            userMessage: "I ate grilled chicken breast"
        )
        
        // Act
        let responses = try await AsyncTestUtilities.collect(
            from: aiServiceStub.sendRequest(request),
            timeout: 5.0
        )
        
        // Assert
        let structuredResponse = responses.first { response in
            if case .structuredData = response { return true }
            return false
        }
        
        XCTAssertNotNil(structuredResponse)
    }
    
    func testSendRequest_WithError() async {
        // Arrange
        await aiServiceStub.setShouldThrowRequestError(true)
        let request = MockDataGenerator.createMockAIRequest()
        
        // Act & Assert
        do {
            let _ = try await AsyncTestUtilities.collect(
                from: aiServiceStub.sendRequest(request),
                timeout: 5.0
            )
            XCTFail("Expected request error")
        } catch {
            let requestCount = await aiServiceStub.sendRequestCallCount
            XCTAssertEqual(requestCount, 1)
            XCTAssertTrue(error is AIError)
        }
    }
    
    // MARK: - Health Check Tests
    
    func testHealthCheck_Healthy() async {
        // Act
        let health = await aiServiceStub.checkHealth()
        
        // Assert
        let checkCount = await aiServiceStub.checkHealthCallCount
        XCTAssertEqual(checkCount, 1)
        XCTAssertEqual(health.status, .healthy)
        XCTAssertNil(health.errorMessage)
        XCTAssertNotNil(health.responseTime)
    }
    
    func testHealthCheck_Unhealthy() async {
        // Arrange
        await aiServiceStub.configureForErrors()
        
        // Act
        let health = await aiServiceStub.checkHealth()
        
        // Assert
        XCTAssertEqual(health.status, .unhealthy)
        XCTAssertNotNil(health.errorMessage)
    }
    
    // MARK: - Validation Tests
    
    func testValidateConfiguration_Success() async throws {
        // Act
        let isValid = try await aiServiceStub.validateConfiguration()
        
        // Assert
        let validateCount = await aiServiceStub.validateConfigurationCallCount
        XCTAssertEqual(validateCount, 1)
        XCTAssertTrue(isValid)
    }
    
    func testValidateConfiguration_Failure() async {
        // Arrange
        await aiServiceStub.setShouldThrowConfigurationError(true)
        
        // Act & Assert
        do {
            _ = try await aiServiceStub.validateConfiguration()
            XCTFail("Expected validation error")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }
    
    // MARK: - Token Estimation Tests
    
    func testEstimateTokenCount() async {
        // Arrange
        let text = "This is a test string with some words"
        
        // Act
        let tokenCount = aiServiceStub.estimateTokenCount(for: text)
        
        // Assert
        let estimateCount = await aiServiceStub.estimateTokenCountCallCount
        let lastText = await aiServiceStub.lastTokenCountText
        
        XCTAssertEqual(estimateCount, 1)
        XCTAssertEqual(lastText, text)
        XCTAssertGreaterThan(tokenCount, 0)
        XCTAssertEqual(tokenCount, text.count / 4) // Simple estimation
    }
    
    // MARK: - Legacy Support Tests
    
    func testAnalyzeGoal_WeightLoss() async throws {
        // Arrange
        let goalText = "I want to lose 20 pounds"
        
        // Act
        let analysis = try await aiServiceStub.analyzeGoal(goalText)
        
        // Assert
        let analyzeCount = await aiServiceStub.analyzeGoalCallCount
        let lastGoal = await aiServiceStub.lastGoalText
        
        XCTAssertEqual(analyzeCount, 1)
        XCTAssertEqual(lastGoal, goalText)
        XCTAssertTrue(analysis.lowercased().contains("weight"))
        XCTAssertTrue(analysis.lowercased().contains("caloric"))
    }
    
    func testAnalyzeGoal_MuscleBuilding() async throws {
        // Arrange
        let goalText = "I want to gain muscle mass"
        
        // Act
        let analysis = try await aiServiceStub.analyzeGoal(goalText)
        
        // Assert
        XCTAssertTrue(analysis.lowercased().contains("muscle"))
        XCTAssertTrue(analysis.lowercased().contains("strength"))
    }
    
    func testAnalyzeGoal_WithError() async {
        // Arrange
        await aiServiceStub.setShouldThrowRequestError(true)
        
        // Act & Assert
        do {
            _ = try await aiServiceStub.analyzeGoal("test goal")
            XCTFail("Expected analysis error")
        } catch {
            XCTAssertTrue(error is AIError)
        }
    }
    
    // MARK: - Properties Tests
    
    func testAvailableModels_NotEmpty() {
        // Act
        let models = aiServiceStub.availableModels
        
        // Assert
        XCTAssertGreaterThan(models.count, 0)
        
        let testModel = models.first
        XCTAssertNotNil(testModel)
        XCTAssertEqual(testModel?.id, "test-model")
        XCTAssertEqual(testModel?.name, "Test AI Model")
        XCTAssertEqual(testModel?.provider, .gemini)
    }
    
    func testActiveProvider_ReturnsCorrectValue() {
        // Act & Assert
        XCTAssertEqual(aiServiceStub.activeProvider, .gemini)
    }
    
    func testServiceIdentifier_IsCorrect() {
        // Act & Assert
        XCTAssertEqual(aiServiceStub.serviceIdentifier, "ai-service-stub")
    }
    
    func testIsConfigured_ReturnsTrue() {
        // Act & Assert
        XCTAssertTrue(aiServiceStub.isConfigured)
    }
    
    // MARK: - Reset and Cleanup Tests
    
    func testReset_ClearsState() async {
        // Arrange - Perform operations to change state
        try? await aiServiceStub.configure()
        _ = aiServiceStub.estimateTokenCount(for: "test")
        try? await aiServiceStub.analyzeGoal("test goal")
        
        // Act
        await aiServiceStub.reset()
        
        // Assert - All counters should be reset
        let configCount = await aiServiceStub.configureCallCount
        let estimateCount = await aiServiceStub.estimateTokenCountCallCount
        let analyzeCount = await aiServiceStub.analyzeGoalCallCount
        
        XCTAssertEqual(configCount, 0)
        XCTAssertEqual(estimateCount, 0)
        XCTAssertEqual(analyzeCount, 0)
    }
    
    func testResetToDefaults_RestoresInitialState() async {
        // Arrange - Change configuration
        await aiServiceStub.configureForErrors()
        await aiServiceStub.setShouldThrowRequestError(true)
        
        // Act
        await aiServiceStub.resetToDefaults()
        
        // Assert
        let health = await aiServiceStub.checkHealth()
        XCTAssertEqual(health.status, .healthy)
        XCTAssertNil(health.errorMessage)
    }
    
    // MARK: - Request Tracking Tests
    
    func testRequestTracking_MultipleRequests() async throws {
        // Arrange
        let requests = [
            MockDataGenerator.createMockAIRequest(userMessage: "Request 1"),
            MockDataGenerator.createMockAIRequest(userMessage: "Request 2"),
            MockDataGenerator.createMockAIRequest(userMessage: "Request 3")
        ]
        
        // Act
        for request in requests {
            _ = try await AsyncTestUtilities.collect(
                from: aiServiceStub.sendRequest(request),
                timeout: 5.0,
                limit: 5
            )
        }
        
        // Assert
        let requestCount = await aiServiceStub.sendRequestCallCount
        let allRequests = await aiServiceStub.allRequests
        let lastRequest = await aiServiceStub.lastRequest
        
        XCTAssertEqual(requestCount, 3)
        XCTAssertEqual(allRequests.count, 3)
        XCTAssertEqual(lastRequest?.messages.first?.content, "Request 3")
    }
}

// MARK: - AIServiceStub Test Extensions

extension AIServiceStub {
    
    func setConfigurationDelay(_ delay: TimeInterval) async {
        self.configurationDelay = delay
    }
    
    func setShouldThrowConfigurationError(_ shouldThrow: Bool) async {
        self.shouldThrowConfigurationError = shouldThrow
    }
    
    func setShouldThrowRequestError(_ shouldThrow: Bool) async {
        self.shouldThrowRequestError = shouldThrow
    }
}