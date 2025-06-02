import XCTest
@testable import AirFit

@MainActor
final class NetworkManagerTests: XCTestCase {
    
    var sut: NetworkManager!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = NetworkManager.shared
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Tests
    
    func testNetworkManagerInitializes() {
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isReachable)
    }
    
    func testBuildRequestCreatesCorrectRequest() {
        // Given
        let url = URL(string: "https://api.example.com/test")!
        let headers = ["Authorization": "Bearer token", "Custom": "Value"]
        let body = "test data".data(using: .utf8)!
        
        // When
        let request = sut.buildRequest(
            url: url,
            method: "POST",
            headers: headers,
            body: body,
            timeout: 60
        )
        
        // Then
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.timeoutInterval, 60)
        XCTAssertEqual(request.httpBody, body)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Custom"), "Value")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }
    
    // MARK: - Network Type Tests
    
    func testNetworkTypeEnumCases() {
        let types: [NetworkType] = [.wifi, .cellular, .ethernet, .unknown, .none]
        
        for type in types {
            XCTAssertNotNil(type.rawValue)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testServiceErrorDescriptions() {
        let errors: [(ServiceError, String)] = [
            (.notConfigured, "Service is not configured"),
            (.networkUnavailable, "Network connection is unavailable"),
            (.timeout, "Request timed out"),
            (.cancelled, "Request was cancelled")
        ]
        
        for (error, expectedDescription) in errors {
            XCTAssertEqual(error.localizedDescription, expectedDescription)
        }
    }
    
    func testServiceErrorWithParameters() {
        let configError = ServiceError.invalidConfiguration("Missing API key")
        XCTAssertEqual(configError.localizedDescription, "Invalid configuration: Missing API key")
        
        let authError = ServiceError.authenticationFailed("Invalid token")
        XCTAssertEqual(authError.localizedDescription, "Authentication failed: Invalid token")
        
        let rateLimitError = ServiceError.rateLimitExceeded(retryAfter: 60)
        XCTAssertEqual(rateLimitError.localizedDescription, "Rate limit exceeded. Retry after 60 seconds")
        
        let providerError = ServiceError.providerError(code: "500", message: "Internal error")
        XCTAssertEqual(providerError.localizedDescription, "Provider error [500]: Internal error")
    }
}