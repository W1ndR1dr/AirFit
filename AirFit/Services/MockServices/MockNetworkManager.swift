import Foundation

/// Mock implementation of NetworkManagementProtocol for testing
@MainActor
final class MockNetworkManager: NetworkManagementProtocol {
    
    // MARK: - Properties
    private(set) var isReachable: Bool = true
    private(set) var currentNetworkType: NetworkType = .wifi
    
    // Test control properties
    var shouldFail = false
    var failureError: Error = ServiceError.networkUnavailable
    var responseDelay: TimeInterval = 0
    var mockResponses: [String: Any] = [:]
    var requestHistory: [URLRequest] = []
    
    // MARK: - NetworkManagementProtocol
    
    func performRequest<T: Decodable & Sendable>(
        _ request: URLRequest,
        expecting type: T.Type
    ) async throws -> T {
        requestHistory.append(request)
        
        // Simulate network delay
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        // Check for failure
        if shouldFail {
            throw failureError
        }
        
        // Check for mock response
        if let url = request.url?.absoluteString,
           let mockData = mockResponses[url] {
            
            if let data = mockData as? Data {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(type, from: data)
            } else if let decodable = mockData as? T {
                return decodable
            }
        }
        
        // Generate default response based on type
        return try generateDefaultResponse(for: type)
    }
    
    func performStreamingRequest(
        _ request: URLRequest
    ) -> AsyncThrowingStream<Data, Error> {
        requestHistory.append(request)
        
        return AsyncThrowingStream { continuation in
            Task {
                // Simulate network delay
                if self.responseDelay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(self.responseDelay * 1_000_000_000))
                }
                
                // Check for failure
                if self.shouldFail {
                    continuation.finish(throwing: self.failureError)
                    return
                }
                
                // Stream mock data
                let mockMessages = [
                    "data: {\"choices\":[{\"delta\":{\"content\":\"Hello\"}}]}",
                    "data: {\"choices\":[{\"delta\":{\"content\":\" world!\"}}]}",
                    "data: [DONE]"
                ]
                
                for message in mockMessages {
                    if let data = message.data(using: .utf8) {
                        continuation.yield(data)
                    }
                    
                    // Small delay between chunks
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
                
                continuation.finish()
            }
        }
    }
    
    func downloadData(from url: URL) async throws -> Data {
        let request = URLRequest(url: url)
        requestHistory.append(request)
        
        // Simulate network delay
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        // Check for failure
        if shouldFail {
            throw failureError
        }
        
        // Return mock data
        return "Mock downloaded data".data(using: .utf8) ?? Data()
    }
    
    func uploadData(_ data: Data, to url: URL) async throws -> URLResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        requestHistory.append(request)
        
        // Simulate network delay
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        // Check for failure
        if shouldFail {
            throw failureError
        }
        
        // Return mock response
        return HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
    }
    
    func buildRequest(
        url: URL,
        method: String,
        headers: [String: String]
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        shouldFail = false
        failureError = ServiceError.networkUnavailable
        responseDelay = 0
        mockResponses.removeAll()
        requestHistory.removeAll()
        isReachable = true
        currentNetworkType = .wifi
    }
    
    func setMockResponse<T: Encodable>(_ response: T, for url: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(response)
        mockResponses[url] = data
    }
    
    func setNetworkStatus(reachable: Bool, type: NetworkType) {
        isReachable = reachable
        currentNetworkType = type
    }
    
    // MARK: - Private Methods
    
    private func generateDefaultResponse<T: Decodable>(for type: T.Type) throws -> T {
        // Generate empty/default responses for common types
        if type == Data.self {
            return Data() as! T
        }
        
        // Try to create empty JSON object
        let emptyJSON = "{}".data(using: .utf8)!
        return try JSONDecoder().decode(type, from: emptyJSON)
    }
}