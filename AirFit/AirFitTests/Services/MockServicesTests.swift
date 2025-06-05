import XCTest
import Combine
@testable import AirFit

@MainActor
final class MockServicesTests: XCTestCase {
    
    // MARK: - MockNetworkManager Tests
    
    func testMockNetworkManagerInitialState() {
        let mock = MockNetworkManager()
        
        XCTAssertTrue(mock.isReachable)
        XCTAssertEqual(mock.currentNetworkType, .wifi)
        XCTAssertNil(mock.stubbedPerformRequestError)
        XCTAssertTrue(mock.invocations.isEmpty)
    }
    
    func testMockNetworkManagerRecordsRequests() async throws {
        let mock = MockNetworkManager()
        let url = URL(string: "https://test.com")!
        let request = URLRequest(url: url)
        
        // Stub a response
        struct TestResponse: Codable, Sendable {
            let value: String
        }
        mock.stubRequest(with: TestResponse(value: "test"))
        
        // Make request
        let _: TestResponse = try await mock.performRequest(request, expecting: TestResponse.self)
        
        // Verify request was recorded
        mock.verifyPerformRequest(called: 1)
        XCTAssertTrue(mock.invocations["performRequest"] != nil)
    }
    
    func testMockNetworkManagerSimulatesFailure() async {
        let mock = MockNetworkManager()
        mock.stubRequestError(with: ServiceError.timeout)
        
        let request = URLRequest(url: URL(string: "https://test.com")!)
        
        struct TestResponse: Codable, Sendable {
            let value: String
        }
        
        do {
            let _: TestResponse = try await mock.performRequest(request, expecting: TestResponse.self)
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
        
        // Stub streaming chunks
        let chunk1 = "Hello".data(using: .utf8)!
        let chunk2 = " World".data(using: .utf8)!
        let chunk3 = "[DONE]".data(using: .utf8)!
        mock.stubStreamingRequest(with: [chunk1, chunk2, chunk3])
        
        var chunks: [String] = []
        let stream = mock.performStreamingRequest(request)
        
        for try await data in stream {
            if let string = String(data: data, encoding: .utf8) {
                chunks.append(string)
            }
        }
        
        XCTAssertEqual(chunks.count, 3)
        XCTAssertTrue(chunks.contains("Hello"))
        XCTAssertTrue(chunks.contains("[DONE]"))
    }
    
    // MARK: - MockWeatherService Tests
    
    func testMockWeatherServiceDefaultResponses() async throws {
        let mock = MockWeatherService()
        try await mock.configure()
        
        let weather = try await mock.getCurrentWeather(latitude: 40.0, longitude: -74.0)
        
        XCTAssertEqual(weather.temperature, 72.0)
        XCTAssertEqual(weather.condition, .partlyCloudy)
        XCTAssertEqual(weather.location, "Test Location")
    }
    
    func testMockWeatherServiceCustomResponse() async throws {
        let mock = MockWeatherService()
        try await mock.configure()
        
        let customWeather = ServiceWeatherData(
            temperature: 85.0,
            condition: .clear,
            humidity: 40.0,
            windSpeed: 5.0,
            location: "Custom Location",
            timestamp: Date()
        )
        mock.stubWeather(customWeather, for: 0, longitude: 0)
        
        let weather = try await mock.getCurrentWeather(latitude: 0, longitude: 0)
        
        XCTAssertEqual(weather.temperature, 85.0)
        XCTAssertEqual(weather.condition, .clear)
        XCTAssertEqual(weather.location, "Custom Location")
    }
    
    func testMockWeatherServiceVerification() async throws {
        let mock = MockWeatherService()
        try await mock.configure()
        
        _ = try await mock.getCurrentWeather(latitude: 40.0, longitude: -74.0)
        _ = try await mock.getForecast(latitude: 35.0, longitude: -120.0, days: 5)
        
        // Verify methods were called
        mock.verifyWeatherRequested(for: 40.0, longitude: -74.0)
        XCTAssertEqual(mock.requestCount, 2)
    }
    
    // MARK: - MockAPIKeyManager Tests
    
    func testMockAPIKeyManagerOperations() async throws {
        let mock = MockAPIKeyManager()
        
        // Save key
        try await mock.saveAPIKey("test-key", for: .openAI)
        XCTAssertTrue(mock.invocations["saveAPIKey"] != nil)
        
        // Get key (uses stubbed result)
        let key = try await mock.getAPIKey(for: .openAI)
        XCTAssertEqual(key, "test-api-key") // Default stubbed value
        XCTAssertTrue(mock.invocations["getAPIKey"] != nil)
        
        // Check existence (uses stubbed result)
        let hasKey = await mock.hasAPIKey(for: .openAI)
        XCTAssertTrue(hasKey) // Default stubbed value
        
        // Delete key
        try await mock.deleteAPIKey(for: .openAI)
        XCTAssertTrue(mock.invocations["deleteAPIKey"] != nil)
    }
    
    func testMockAPIKeyManagerGetAllProviders() async {
        let mock = MockAPIKeyManager()
        
        // Stub the providers list
        mock.stubbedGetAllConfiguredProvidersResult = [.openAI, .anthropic]
        
        let providers = await mock.getAllConfiguredProviders()
        
        XCTAssertEqual(providers.count, 2)
        XCTAssertTrue(providers.contains(.openAI))
        XCTAssertTrue(providers.contains(.anthropic))
    }
}

// Helper struct for testing
private struct EmptyResponse: Decodable {}