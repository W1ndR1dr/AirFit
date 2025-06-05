import Foundation
import XCTest
@testable import AirFit

/// Mock implementation of NetworkClientProtocol for testing
final class MockNetworkClient: NetworkClientProtocol, MockProtocol {
    // MARK: - MockProtocol
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - Error Control
    var shouldThrowError = false
    var errorToThrow: Error = NetworkError.networkError(NSError(domain: "MockNetworkClient", code: 1, userInfo: nil))
    
    // MARK: - Response Configuration
    var stubbedResponses: [String: Any] = [:]
    var stubbedData: Data?
    var responseDelay: TimeInterval = 0
    
    // MARK: - NetworkClientProtocol
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        recordInvocation("request", arguments: endpoint.path, endpoint.method.rawValue)
        
        // Simulate network delay if configured
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Check for stubbed response by path
        if let response = stubbedResponses[endpoint.path] as? T {
            return response
        }
        
        // Check for generic stubbed result
        if let response = stubbedResults["request-\(T.self)"] as? T {
            return response
        }
        
        // Try to decode from stubbed data
        if let data = stubbedData {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        }
        
        throw NetworkError.noData
    }
    
    func upload(_ data: Data, to endpoint: Endpoint) async throws {
        recordInvocation("upload", arguments: data.count, endpoint.path, endpoint.method.rawValue)
        
        // Simulate network delay if configured
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
    }
    
    func download(from endpoint: Endpoint) async throws -> Data {
        recordInvocation("download", arguments: endpoint.path, endpoint.method.rawValue)
        
        // Simulate network delay if configured
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let data = stubbedData {
            return data
        }
        
        // Return empty data by default
        return Data()
    }
    
    // MARK: - Test Helpers
    func stubResponse<T: Encodable>(_ response: T, for path: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        stubbedResponses[path] = response
        stubbedData = data
    }
    
    func stubResponse<T>(_ response: T, for type: T.Type) {
        stub("request-\(type)", with: response)
    }
    
    func verifyRequest(to path: String, method: HTTPMethod) {
        mockLock.lock()
        defer { mockLock.unlock() }
        
        guard let calls = invocations["request"] as? [[Any]] else {
            XCTFail("No requests were made")
            return
        }
        
        let matching = calls.contains { args in
            guard args.count >= 2,
                  let callPath = args[0] as? String,
                  let callMethod = args[1] as? String else {
                return false
            }
            return callPath == path && callMethod == method.rawValue
        }
        
        XCTAssertTrue(matching, "No request found for path: \(path) with method: \(method.rawValue)")
    }
    
    func simulateHTTPError(statusCode: Int, data: Data? = nil) {
        shouldThrowError = true
        errorToThrow = NetworkError.httpError(statusCode: statusCode, data: data)
    }
    
    func simulateTimeout() {
        shouldThrowError = true
        errorToThrow = NetworkError.timeout
    }
    
    func simulateNoNetwork() {
        shouldThrowError = true
        errorToThrow = NetworkError.networkError(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil))
    }
}