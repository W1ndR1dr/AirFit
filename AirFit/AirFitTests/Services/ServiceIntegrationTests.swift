import XCTest
@testable import AirFit

@MainActor
final class ServiceIntegrationTests: XCTestCase {
    
    var networkManager: NetworkManager!
    var apiKeyManager: DefaultAPIKeyManager!
    var aiService: EnhancedAIAPIService!
    var weatherService: WeatherService!
    var serviceRegistry: ServiceRegistry!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use real implementations for integration testing
        networkManager = NetworkManager.shared
        apiKeyManager = DefaultAPIKeyManager()
        serviceRegistry = ServiceRegistry.shared
        
        // Initialize services
        aiService = EnhancedAIAPIService(
            networkManager: networkManager,
            apiKeyManager: apiKeyManager,
            llmOrchestrator: LLMOrchestrator(apiKeyManager: apiKeyManager)
        )
        
        weatherService = WeatherService(
            networkManager: networkManager,
            apiKeyManager: apiKeyManager
        )
    }
    
    override func tearDown() async throws {
        // Clean up
        await serviceRegistry.resetAll()
        try await super.tearDown()
    }
    
    // MARK: - Service Registry Integration
    
    func testServiceRegistryIntegration() async throws {
        // Register services
        serviceRegistry.register(aiService, for: AIServiceProtocol.self)
        serviceRegistry.register(weatherService, for: WeatherServiceProtocol.self)
        serviceRegistry.register(networkManager, for: NetworkManagementProtocol.self)
        
        // Retrieve services
        let retrievedAI = serviceRegistry.get(AIServiceProtocol.self)
        let retrievedWeather = serviceRegistry.get(WeatherServiceProtocol.self)
        let retrievedNetwork = serviceRegistry.get(NetworkManagementProtocol.self)
        
        XCTAssertNotNil(retrievedAI)
        XCTAssertNotNil(retrievedWeather)
        XCTAssertNotNil(retrievedNetwork)
        
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
        let providers: [AIProvider] = [.openAI, .anthropic, .googleGemini, .openRouter]
        
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
        let testAIService = EnhancedAIAPIService(
            networkManager: mockNetwork,
            apiKeyManager: apiKeyManager,
            llmOrchestrator: LLMOrchestrator(apiKeyManager: apiKeyManager)
        )
        
        // Setup
        try await apiKeyManager.saveAPIKey("test-key", for: .openAI)
        try await testAIService.configure(provider: .openAI, apiKey: "test-key", model: "gpt-4o-mini")
        
        // Prepare mock response
        mockNetwork.mockResponses["https://api.openai.com/v1/chat/completions"] = 
            TestDataGenerators.makeOpenAIStreamData(content: "Hello from AI")
        
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
        XCTAssertTrue(mockNetwork.requestHistory.count > 0)
    }
    
    // MARK: - Weather Service Integration
    
    func testWeatherServiceCaching() async throws {
        // Setup mock network for controlled testing
        let mockNetwork = MockNetworkManager()
        let testWeatherService = WeatherService(
            networkManager: mockNetwork,
            apiKeyManager: apiKeyManager
        )
        
        // Configure
        try await apiKeyManager.saveAPIKey("weather-test-key", for: .openAI) // Using as placeholder
        try await testWeatherService.configure()
        
        // Mock weather response
        let mockWeather = TestDataGenerators.makeWeatherData(
            temperature: 75.0,
            condition: .clear,
            location: "Test City"
        )
        try mockNetwork.setMockResponse(mockWeather, for: "https://api.openweathermap.org/data/2.5/weather")
        
        // First request - should hit network
        let weather1 = try await testWeatherService.getCurrentWeather(latitude: 40.0, longitude: -74.0)
        XCTAssertEqual(mockNetwork.requestHistory.count, 1)
        
        // Second request - should use cache
        let weather2 = try await testWeatherService.getCurrentWeather(latitude: 40.0, longitude: -74.0)
        XCTAssertEqual(mockNetwork.requestHistory.count, 1) // No additional request
        
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
        
        let testAIService = EnhancedAIAPIService(
            networkManager: mockNetwork,
            apiKeyManager: apiKeyManager,
            llmOrchestrator: LLMOrchestrator(apiKeyManager: apiKeyManager)
        )
        
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
            if let serviceError = error as? ServiceError {
                XCTAssertEqual(serviceError, .networkUnavailable)
            } else {
                XCTFail("Expected ServiceError.networkUnavailable, got \(error)")
            }
        }
    }
    
    func testRateLimitHandling() async throws {
        let mockNetwork = MockNetworkManager()
        mockNetwork.shouldFail = true
        mockNetwork.failureError = ServiceError.rateLimitExceeded(retryAfter: 60)
        
        let testAIService = EnhancedAIAPIService(
            networkManager: mockNetwork,
            apiKeyManager: apiKeyManager,
            llmOrchestrator: LLMOrchestrator(apiKeyManager: apiKeyManager)
        )
        
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