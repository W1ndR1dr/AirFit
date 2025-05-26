import Foundation
@testable import AirFit

final class MockNetworkClient: NetworkClientProtocol {
    // Stubbed responses
    var mockResponses: [String: Any] = [:]
    var shouldThrowError: Error?
    
    // Verification properties
    var capturedRequests: [Endpoint] = []
    var requestCount: Int { capturedRequests.count }
    
    // Delay simulation
    var simulatedDelay: TimeInterval = 0
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Record the request
        capturedRequests.append(endpoint)
        
        // Simulate network delay if needed
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        // Throw error if configured
        if let error = shouldThrowError {
            throw error
        }
        
        // Return mock response
        guard let response = mockResponses[endpoint.path] as? T else {
            throw NetworkError.invalidResponse
        }
        
        return response
    }
    
    func upload(_ data: Data, to endpoint: Endpoint) async throws {
        capturedRequests.append(endpoint)
        
        if let error = shouldThrowError {
            throw error
        }
    }
    
    // Verification helpers
    func verify(endpoint: String, calledTimes times: Int) {
        let actualCalls = capturedRequests.filter { $0.path == endpoint }.count
        assert(actualCalls == times, 
               "\(endpoint) was called \(actualCalls) times, expected \(times)")
    }
    
    func reset() {
        mockResponses.removeAll()
        capturedRequests.removeAll()
        shouldThrowError = nil
        simulatedDelay = 0
    }
} 