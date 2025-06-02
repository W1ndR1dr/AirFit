import XCTest
@testable import AirFit

@MainActor
final class MockServicesTests: XCTestCase {
    
    // MARK: - MockNetworkManager Tests
    
    func testMockNetworkManagerInitialState() {
        let mock = MockNetworkManager()
        
        XCTAssertTrue(mock.isReachable)
        XCTAssertEqual(mock.currentNetworkType, .wifi)
        XCTAssertFalse(mock.shouldFail)
        XCTAssertEqual(mock.responseDelay, 0)
        XCTAssertTrue(mock.requestHistory.isEmpty)
    }
    
    func testMockNetworkManagerRecordsRequests() async throws {
        let mock = MockNetworkManager()
        let url = URL(string: "https://test.com")!
        let request = URLRequest(url: url)
        
        // Make request
        do {
            let _: EmptyResponse = try await mock.performRequest(request, expecting: EmptyResponse.self)
        } catch {
            // Ignore errors for this test
        }
        
        // Verify request was recorded
        XCTAssertEqual(mock.requestHistory.count, 1)
        XCTAssertEqual(mock.requestHistory.first?.url, url)
    }
    
    func testMockNetworkManagerSimulatesFailure() async {
        let mock = MockNetworkManager()
        mock.shouldFail = true
        mock.failureError = ServiceError.timeout
        
        let request = URLRequest(url: URL(string: "https://test.com")!)
        
        do {
            let _: EmptyResponse = try await mock.performRequest(request, expecting: EmptyResponse.self)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is ServiceError)
            if let serviceError = error as? ServiceError {
                XCTAssertEqual(serviceError.localizedDescription, ServiceError.timeout.localizedDescription)
            }
        }
    }
    
    func testMockNetworkManagerStreaming() async throws {
        let mock = MockNetworkManager()
        let request = URLRequest(url: URL(string: "https://test.com")!)
        
        var chunks: [String] = []
        let stream = mock.performStreamingRequest(request)
        
        for try await data in stream {
            if let string = String(data: data, encoding: .utf8) {
                chunks.append(string)
            }
        }
        
        XCTAssertFalse(chunks.isEmpty)
        XCTAssertTrue(chunks.contains { $0.contains("Hello") })
        XCTAssertTrue(chunks.contains { $0.contains("[DONE]") })
    }
    
    // MARK: - MockAIAPIService Tests
    
    func testMockAIAPIServiceInitialState() {
        let mock = MockAIAPIService()
        
        XCTAssertFalse(mock.isConfigured)
        XCTAssertEqual(mock.activeProvider, .openAI)
        XCTAssertFalse(mock.shouldFail)
        XCTAssertTrue(mock.requestHistory.isEmpty)
        XCTAssertEqual(mock.configureCallCount, 0)
    }
    
    func testMockAIAPIServiceConfigure() async throws {
        let mock = MockAIAPIService()
        
        try await mock.configure()
        
        XCTAssertTrue(mock.isConfigured)
        XCTAssertEqual(mock.configureCallCount, 1)
    }
    
    func testMockAIAPIServiceStreaming() async throws {
        let mock = MockAIAPIService()
        mock.setMockResponses(["Test", " response", " message"])
        
        let request = AIRequest(
            messages: [AIMessage(role: .user, content: "Hello", name: nil)],
            model: "mock-model",
            systemPrompt: "",
            maxTokens: nil,
            temperature: nil,
            stream: true,
            functions: nil
        )
        
        var responses: [String] = []
        for try await response in mock.sendRequest(request) {
            if case .textDelta(let text) = response {
                responses.append(text)
            }
        }
        
        XCTAssertEqual(responses, ["Test", " response", " message"])
        XCTAssertEqual(mock.requestHistory.count, 1)
    }
    
    func testMockAIAPIServiceHealthCheck() async {
        let mock = MockAIAPIService()
        
        // Not configured
        var health = await mock.healthCheck()
        XCTAssertEqual(health.status, .unhealthy)
        
        // Configure and check again
        try? await mock.configure()
        health = await mock.healthCheck()
        XCTAssertEqual(health.status, .healthy)
        XCTAssertEqual(mock.healthCheckCallCount, 2)
    }
    
    // MARK: - MockWeatherService Tests
    
    func testMockWeatherServiceDefaultResponses() async throws {
        let mock = MockWeatherService()
        try await mock.configure()
        
        let weather = try await mock.getCurrentWeather(latitude: 40.0, longitude: -74.0)
        
        XCTAssertEqual(weather.temperature, 72.0)
        XCTAssertEqual(weather.condition, .partlyCloudy)
        XCTAssertTrue(weather.location.contains("40.00"))
        XCTAssertTrue(weather.location.contains("-74.00"))
    }
    
    func testMockWeatherServiceCustomResponse() async throws {
        let mock = MockWeatherService()
        try await mock.configure()
        
        let customWeather = WeatherData(
            temperature: 85.0,
            condition: .clear,
            humidity: 40.0,
            windSpeed: 5.0,
            location: "Custom Location",
            timestamp: Date()
        )
        mock.setMockWeather(customWeather)
        
        let weather = try await mock.getCurrentWeather(latitude: 0, longitude: 0)
        
        XCTAssertEqual(weather.temperature, 85.0)
        XCTAssertEqual(weather.condition, .clear)
        XCTAssertEqual(weather.location, "Custom Location")
    }
    
    func testMockWeatherServiceRequestHistory() async throws {
        let mock = MockWeatherService()
        try await mock.configure()
        
        _ = try await mock.getCurrentWeather(latitude: 40.0, longitude: -74.0)
        _ = try await mock.getForecast(latitude: 35.0, longitude: -120.0, days: 5)
        
        XCTAssertEqual(mock.requestHistory.count, 2)
        
        if let first = mock.requestHistory.first {
            XCTAssertEqual(first.latitude, 40.0)
            XCTAssertEqual(first.longitude, -74.0)
            if case .current = first.type {
                // Success
            } else {
                XCTFail("Expected current weather request")
            }
        }
        
        if let last = mock.requestHistory.last {
            XCTAssertEqual(last.latitude, 35.0)
            XCTAssertEqual(last.longitude, -120.0)
            if case .forecast(let days) = last.type {
                XCTAssertEqual(days, 5)
            } else {
                XCTFail("Expected forecast request")
            }
        }
    }
    
    // MARK: - MockAPIKeyManager Tests
    
    func testMockAPIKeyManagerOperations() async throws {
        let mock = MockAPIKeyManager()
        
        // Save key
        try await mock.saveAPIKey("test-key", for: .openAI)
        XCTAssertEqual(mock.saveCallCount, 1)
        
        // Get key
        let key = try await mock.getAPIKey(for: .openAI)
        XCTAssertEqual(key, "test-key")
        XCTAssertEqual(mock.getCallCount, 1)
        
        // Check existence
        let hasKey = await mock.hasAPIKey(for: .openAI)
        XCTAssertTrue(hasKey)
        
        // Delete key
        try await mock.deleteAPIKey(for: .openAI)
        XCTAssertEqual(mock.deleteCallCount, 1)
        
        // Verify deletion
        let hasKeyAfterDelete = await mock.hasAPIKey(for: .openAI)
        XCTAssertFalse(hasKeyAfterDelete)
    }
    
    func testMockAPIKeyManagerGetAllProviders() async throws {
        let mock = MockAPIKeyManager()
        
        // Add keys for multiple providers
        try await mock.saveAPIKey("key1", for: .openAI)
        try await mock.saveAPIKey("key2", for: .anthropic)
        
        let providers = await mock.getAllConfiguredProviders()
        
        XCTAssertEqual(providers.count, 2)
        XCTAssertTrue(providers.contains(.openAI))
        XCTAssertTrue(providers.contains(.anthropic))
    }
}

// Helper struct for testing
private struct EmptyResponse: Decodable {}