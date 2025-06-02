import XCTest
@testable import AirFit

@MainActor
final class ServicePerformanceTests: XCTestCase {
    
    var networkManager: NetworkManager!
    var aiService: EnhancedAIAPIService!
    var weatherService: WeatherService!
    var mockAPIKeyManager: MockAPIKeyManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        networkManager = NetworkManager.shared
        mockAPIKeyManager = MockAPIKeyManager()
        
        aiService = EnhancedAIAPIService(
            networkManager: networkManager,
            apiKeyManager: mockAPIKeyManager,
            llmOrchestrator: LLMOrchestrator(apiKeyManager: mockAPIKeyManager)
        )
        
        weatherService = WeatherService(
            networkManager: networkManager,
            apiKeyManager: mockAPIKeyManager
        )
    }
    
    // MARK: - Network Manager Performance
    
    func testNetworkManagerRequestBuildingPerformance() {
        let url = URL(string: "https://api.example.com/test")!
        
        measure {
            for _ in 0..<1000 {
                let request = networkManager.buildRequest(
                    url: url,
                    method: "POST",
                    headers: [
                        "Authorization": "Bearer test-token",
                        "Content-Type": "application/json",
                        "X-Custom-Header": "value"
                    ],
                    body: "test body".data(using: .utf8),
                    timeout: 30
                )
                
                // Verify request is built correctly
                XCTAssertNotNil(request)
                XCTAssertEqual(request.httpMethod, "POST")
            }
        }
    }
    
    func testURLRequestExtensionsPerformance() {
        let url = URL(string: "https://api.example.com/test")!
        
        measure {
            for _ in 0..<1000 {
                var request = URLRequest(url: url)
                request.addCommonHeaders()
                request.addStreamingHeaders()
                request.addAuthorization("test-token")
                
                let params = ["key1": "value1", "key2": "value2"]
                request.addQueryParameters(params)
            }
        }
    }
    
    // MARK: - AI Service Performance
    
    func testAIRequestBuildingPerformance() async throws {
        // Setup
        mockAPIKeyManager.setMockAPIKey("test-key", for: .openAI)
        try await aiService.configure(provider: .openAI, apiKey: "test-key", model: "gpt-4o-mini")
        
        let request = TestDataGenerators.makeAIRequest(
            userMessage: "This is a test message with some content to process",
            functions: [
                FunctionSchema(
                    name: "testFunction",
                    description: "A test function",
                    parameters: ["type": "object", "properties": ["param1": ["type": "string"]]]
                )
            ]
        )
        
        measure {
            // Test request building performance
            for _ in 0..<100 {
                _ = aiService.sendRequest(request)
            }
        }
    }
    
    func testAIResponseParsingPerformance() async throws {
        let parser = AIResponseParser()
        
        // Create test data for different providers
        let openAIData = TestDataGenerators.makeOpenAIStreamData(content: "Hello world from OpenAI")
        let anthropicData = TestDataGenerators.makeAnthropicStreamData(event: "content_block_delta", content: "Hello from Anthropic")
        let geminiData = TestDataGenerators.makeGeminiStreamData(text: "Hello from Gemini")
        
        measure {
            Task {
                for _ in 0..<1000 {
                    // Parse different provider responses
                    _ = try? await parser.parseStreamData(openAIData, provider: .openAI)
                    _ = try? await parser.parseStreamData(anthropicData, provider: .anthropic)
                    _ = try? await parser.parseStreamData(geminiData, provider: .googleGemini)
                }
            }
        }
    }
    
    func testTokenEstimationPerformance() async throws {
        mockAPIKeyManager.setMockAPIKey("test-key", for: .openAI)
        try await aiService.configure(provider: .openAI, apiKey: "test-key", model: nil)
        
        let texts = [
            "Short text",
            "Medium length text with more words to process and estimate tokens for",
            String(repeating: "Long text with many repeated words. ", count: 100)
        ]
        
        measure {
            for _ in 0..<10000 {
                for text in texts {
                    _ = aiService.estimateTokenCount(for: text)
                }
            }
        }
    }
    
    // MARK: - Weather Service Performance
    
    func testWeatherCacheLookupPerformance() async throws {
        mockAPIKeyManager.setMockAPIKey("test-key", for: .openAI) // Using as placeholder
        try await weatherService.configure()
        
        // Pre-populate cache
        let locations = (0..<100).map { i in
            (latitude: 40.0 + Double(i) * 0.1, longitude: -74.0 + Double(i) * 0.1)
        }
        
        measure {
            for _ in 0..<1000 {
                for location in locations {
                    _ = weatherService.getCachedWeather(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                }
            }
        }
    }
    
    // MARK: - Service Registry Performance
    
    func testServiceRegistryPerformance() async {
        let registry = ServiceRegistry.shared
        
        // Register multiple services
        let services: [(any ServiceProtocol, Any.Type)] = [
            (MockAIAPIService(), AIServiceProtocol.self),
            (MockWeatherService(), WeatherServiceProtocol.self),
            (MockNetworkManager(), NetworkManagementProtocol.self)
        ]
        
        for (service, type) in services {
            registry.register(service, for: type)
        }
        
        measure {
            for _ in 0..<10000 {
                // Test lookup performance
                _ = registry.get(AIServiceProtocol.self)
                _ = registry.get(WeatherServiceProtocol.self)
                _ = registry.get(NetworkManagementProtocol.self)
            }
        }
    }
    
    // MARK: - Memory Performance
    
    func testAIStreamingMemoryUsage() async throws {
        mockAPIKeyManager.setMockAPIKey("test-key", for: .openAI)
        try await aiService.configure(provider: .openAI, apiKey: "test-key", model: nil)
        
        let request = TestDataGenerators.makeAIRequest(
            userMessage: String(repeating: "Test message. ", count: 1000)
        )
        
        // Measure memory usage during streaming
        let memoryBefore = getMemoryUsage()
        
        // Simulate processing multiple streaming responses
        for _ in 0..<10 {
            _ = aiService.sendRequest(request)
        }
        
        let memoryAfter = getMemoryUsage()
        let memoryIncrease = memoryAfter - memoryBefore
        
        // Assert memory usage is under 50MB as per requirements
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024, "Memory usage exceeded 50MB limit")
    }
    
    func testServiceLayerOverallMemoryFootprint() async throws {
        let memoryBefore = getMemoryUsage()
        
        // Initialize all services
        _ = NetworkManager.shared
        _ = ServiceRegistry.shared
        _ = ServiceConfiguration.shared
        
        let aiService = EnhancedAIAPIService(
            networkManager: NetworkManager.shared,
            apiKeyManager: mockAPIKeyManager,
            llmOrchestrator: LLMOrchestrator(apiKeyManager: mockAPIKeyManager)
        )
        
        let weatherService = WeatherService(
            networkManager: NetworkManager.shared,
            apiKeyManager: mockAPIKeyManager
        )
        
        // Configure services
        mockAPIKeyManager.setMockAPIKey("test", for: .openAI)
        try? await aiService.configure()
        try? await weatherService.configure()
        
        let memoryAfter = getMemoryUsage()
        let totalMemoryUsage = memoryAfter - memoryBefore
        
        // Assert total memory usage is under 50MB as per requirements
        XCTAssertLessThan(totalMemoryUsage, 50 * 1024 * 1024, "Total service layer memory exceeded 50MB")
    }
    
    // MARK: - Concurrent Request Performance
    
    func testConcurrentAIRequestsPerformance() async throws {
        mockAPIKeyManager.setMockAPIKey("test-key", for: .openAI)
        try await aiService.configure(provider: .openAI, apiKey: "test-key", model: nil)
        
        let request = TestDataGenerators.makeAIRequest()
        
        measure {
            Task {
                // Test handling 5 concurrent requests as per requirements
                await withTaskGroup(of: Void.self) { group in
                    for _ in 0..<5 {
                        group.addTask {
                            _ = self.aiService.sendRequest(request)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}