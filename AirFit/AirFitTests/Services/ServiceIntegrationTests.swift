import XCTest
@testable import AirFit

final class ServiceIntegrationTests: XCTestCase {
    private var container: DIContainer!
    
    var networkClient: NetworkClientProtocol!
    var apiKeyManager: APIKeyManagementProtocol!
    var aiService: AIServiceProtocol!
    var weatherService: WeatherServiceProtocol!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        
        // Create DI container for integration testing
        container = DIContainer()
        let bootstrapper = DIBootstrapper(container: container, isTestEnvironment: true)
        try await bootstrapper.bootstrap()
        
        // Resolve services
        networkClient = try await container.resolve(NetworkClientProtocol.self)
        apiKeyManager = try await container.resolve(APIKeyManagementProtocol.self)
        aiService = try await container.resolve(AIServiceProtocol.self)
        weatherService = try await container.resolve(WeatherServiceProtocol.self)
    }
    
    override func tearDown() {
        container = nil
        super.tearDown()
    }
    
    // MARK: - DI Container Integration
    
    @MainActor
    func testDIContainerIntegration() async throws {
        // Services should be resolved via DI
        XCTAssertNotNil(aiService)
        XCTAssertNotNil(weatherService)
        XCTAssertNotNil(networkClient)
        XCTAssertNotNil(apiKeyManager)
        
        // Test that resolved services are singletons where expected
        let aiService2 = try await container.resolve(AIServiceProtocol.self)
        XCTAssertTrue(aiService === aiService2, "AI Service should be a singleton")
        
        let weatherService2 = try await container.resolve(WeatherServiceProtocol.self)
        XCTAssertTrue(weatherService === weatherService2, "Weather Service should be a singleton")
        
        // Test health check across all services
        let healthResults = await serviceRegistry.healthCheck()
        XCTAssertFalse(healthResults.isEmpty)
        XCTAssertTrue(healthResults.keys.contains { $0.contains("AIServiceProtocol") })
    }
    
    // MARK: - API Key Manager Integration
    
    func testAPIKeyManagerWithKeychain() async throws {
        let testProvider = AIProvider.openAI
        let testKey = "test-api-key-\(UUID().uuidString)"
        
        // Save key
        try await apiKeyManager.saveAPIKey(testKey, for: testProvider)
        
        // Retrieve key
        let retrievedKey = try await apiKeyManager.getAPIKey(for: testProvider)
        XCTAssertEqual(retrievedKey, testKey)
        
        // Check existence
        let hasKey = await apiKeyManager.hasAPIKey(for: testProvider)
        XCTAssertTrue(hasKey)
        
        // Get all configured providers
        let providers = await apiKeyManager.getAllConfiguredProviders()
        XCTAssertTrue(providers.contains(testProvider))
        
        // Delete key
        try await apiKeyManager.deleteAPIKey(for: testProvider)
        
        // Verify deletion
        let hasKeyAfterDelete = await apiKeyManager.hasAPIKey(for: testProvider)
        XCTAssertFalse(hasKeyAfterDelete)
    }
    
    // MARK: - Network Manager Integration
    
    func testNetworkManagerWithReachability() async {
        // Test initial state
        XCTAssertTrue(networkManager.isReachable)
        XCTAssertNotEqual(networkManager.currentNetworkType, .none)
        
        // Test request building
        let url = URL(string: "https://api.example.com/test")!
        let request = networkManager.buildRequest(
            url: url,
            method: "POST",
            headers: ["X-Test": "Value"],
            body: "test".data(using: .utf8),
            timeout: 15
        )
        
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.timeoutInterval, 15)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Test"), "Value")
        XCTAssertNotNil(request.value(forHTTPHeaderField: "User-Agent"))
    }
    
    // MARK: - AI Service Integration
    
    func testAIServiceWithAllProviders() async throws {
        let providers: [AIProvider] = [.openAI, .anthropic, .gemini, .openRouter]
        
        for provider in providers {
            // Save test API key
            try await apiKeyManager.saveAPIKey("test-key-\(provider.rawValue)", for: provider)
            
            // Configure service
            try await aiService.configure(
                provider: provider,
                apiKey: "test-key-\(provider.rawValue)",
                model: provider.defaultModel
            )
            
            // Verify configuration
            XCTAssertTrue(aiService.isConfigured)
            XCTAssertEqual(aiService.activeProvider, provider)
            XCTAssertFalse(aiService.availableModels.isEmpty)
            
            // Test health check
            let health = await aiService.healthCheck()
            XCTAssertNotNil(health)
            XCTAssertEqual(health.metadata["provider"], provider.rawValue)
            
            // Reset for next provider
            await aiService.reset()
        }
    }
    
    func testAIServiceRequestFlow() async throws {
        // Configure with mock network manager for controlled testing
        let mockNetwork = MockNetworkManager()
        let llmOrchestrator = LLMOrchestrator(apiKeyManager: apiKeyManager)
        let testAIService = AIService(llmOrchestrator: llmOrchestrator)
        
        // Setup
        try await apiKeyManager.saveAPIKey("test-key", for: .openAI)
        try await testAIService.configure(provider: .openAI, apiKey: "test-key", model: "gpt-4o-mini")
        
        // Prepare mock response
        mockNetwork.stubStreamingRequest(with: [
            TestDataGenerators.makeOpenAIStreamData(content: "Hello from AI")
        ])
        
        // Create request
        let request = TestDataGenerators.makeAIRequest(
            systemPrompt: "You are a helpful assistant",
            userMessage: "Hello"
        )
        
        // Send request and collect responses
        var responses: [AIResponse] = []
        let stream = testAIService.sendRequest(request)
        
        do {
            for try await response in stream {
                responses.append(response)
            }
        } catch {
            XCTFail("Stream failed: \(error)")
        }
        
        // Verify we received responses
        XCTAssertFalse(responses.isEmpty)
    }
    
    // MARK: - Weather Service Integration
    
    func testWeatherServiceCaching() async throws {
        // Setup mock network for controlled testing
        let mockNetwork = MockNetworkManager()
        let testWeatherService = WeatherService()
        
        // Configure
        try await apiKeyManager.saveAPIKey("weather-test-key", for: .openAI) // Using as placeholder
        try await testWeatherService.configure()
        
        // Mock weather response
        let mockWeather = TestDataGenerators.makeWeatherData(
            temperature: 75.0,
            condition: .clear,
            location: "Test City"
        )
        mockNetwork.stubRequest(with: mockWeather)
        
        // First request - should hit WeatherKit (actual implementation)
        let weather1 = try await testWeatherService.getCurrentWeather(latitude: 40.0, longitude: -74.0)
        XCTAssertNotNil(weather1)
        
        // Second request - should use cache
        let weather2 = try await testWeatherService.getCurrentWeather(latitude: 40.0, longitude: -74.0)
        XCTAssertNotNil(weather2)
        
        // Verify both responses are the same
        XCTAssertEqual(weather1.temperature, weather2.temperature)
        XCTAssertEqual(weather1.location, weather2.location)
    }
    
    // MARK: - End-to-End Integration
    
    func testFullServiceStackIntegration() async throws {
        // Register all services
        serviceRegistry.register(networkManager, for: NetworkManagementProtocol.self)
        serviceRegistry.register(apiKeyManager, for: APIKeyManagementProtocol.self)
        serviceRegistry.register(aiService, for: AIServiceProtocol.self)
        serviceRegistry.register(weatherService, for: WeatherServiceProtocol.self)
        
        // Configure services
        try await apiKeyManager.saveAPIKey("test-ai-key", for: .openAI)
        try await apiKeyManager.saveAPIKey("test-weather-key", for: .openAI) // Placeholder
        
        // Get services from registry
        let aiFromRegistry = serviceRegistry.require(AIServiceProtocol.self)
        let weatherFromRegistry = serviceRegistry.require(WeatherServiceProtocol.self)
        
        // Configure through registry
        try await aiFromRegistry.configure()
        try await weatherFromRegistry.configure()
        
        // Perform health checks
        let healthResults = await serviceRegistry.healthCheck()
        
        // Verify all services are operational
        for (serviceName, health) in healthResults {
            print("Service: \(serviceName), Status: \(health.status)")
            XCTAssertTrue(
                health.status == .healthy || health.status == .degraded,
                "Service \(serviceName) is not operational"
            )
        }
    }
    
    // MARK: - Error Handling Integration
    
    func testServiceErrorPropagation() async throws {
        // Test network unavailable
        let mockNetwork = MockNetworkManager()
        mockNetwork.isReachable = false
        
        let llmOrchestrator = LLMOrchestrator(apiKeyManager: apiKeyManager)
        let testAIService = AIService(llmOrchestrator: llmOrchestrator)
        
        // Configure service
        try await apiKeyManager.saveAPIKey("test-key", for: .openAI)
        try await testAIService.configure(provider: .openAI, apiKey: "test-key", model: nil)
        
        // Try to send request with no network
        let request = TestDataGenerators.makeAIRequest()
        let stream = testAIService.sendRequest(request)
        
        do {
            for try await _ in stream {
                XCTFail("Should not receive responses with no network")
            }
        } catch {
            // Verify we get network unavailable error
            if let serviceError = error as? ServiceError,
               case .networkUnavailable = serviceError {
                // Success - got expected error
            } else {
                XCTFail("Expected ServiceError.networkUnavailable, got \(error)")
            }
        }
    }
    
    func testRateLimitHandling() async throws {
        let mockNetwork = MockNetworkManager()
        mockNetwork.stubRequestError(with: ServiceError.rateLimitExceeded(retryAfter: 60))
        
        let llmOrchestrator = LLMOrchestrator(apiKeyManager: apiKeyManager)
        let testAIService = AIService(llmOrchestrator: llmOrchestrator)
        
        try await apiKeyManager.saveAPIKey("test-key", for: .openAI)
        try await testAIService.configure(provider: .openAI, apiKey: "test-key", model: nil)
        
        let request = TestDataGenerators.makeAIRequest()
        let stream = testAIService.sendRequest(request)
        
        do {
            for try await _ in stream {
                XCTFail("Should not receive responses when rate limited")
            }
        } catch ServiceError.rateLimitExceeded(let retryAfter) {
            XCTAssertEqual(retryAfter, 60)
        } catch {
            XCTFail("Expected rate limit error, got \(error)")
        }
    }
    
    // MARK: - Performance Requirements Validation
    
    func testPerformanceRequirements() async throws {
        // Test API key operations < 100ms
        let keyStart = Date()
        try await apiKeyManager.saveAPIKey("perf-test", for: .openAI)
        _ = try await apiKeyManager.getAPIKey(for: .openAI)
        let keyDuration = Date().timeIntervalSince(keyStart)
        XCTAssertLessThan(keyDuration, 0.1, "API key operations exceeded 100ms")
        
        // Test network reachability check < 50ms
        let reachabilityStart = Date()
        _ = networkManager.isReachable
        _ = networkManager.currentNetworkType
        let reachabilityDuration = Date().timeIntervalSince(reachabilityStart)
        XCTAssertLessThan(reachabilityDuration, 0.05, "Reachability check exceeded 50ms")
        
        // Test cache lookups < 10ms
        let cacheStart = Date()
        _ = weatherService.getCachedWeather(latitude: 40.0, longitude: -74.0)
        let cacheDuration = Date().timeIntervalSince(cacheStart)
        XCTAssertLessThan(cacheDuration, 0.01, "Cache lookup exceeded 10ms")
    }
}