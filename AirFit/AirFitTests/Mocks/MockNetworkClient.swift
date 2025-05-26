@testable import AirFit
import Foundation

final class MockNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    // Stubbed responses
    private var _mockResponses: [String: Any] = [:]
    private var _shouldThrowError: Error?
    private var _capturedRequests: [Endpoint] = []
    private var _simulatedDelay: TimeInterval = 0
    private let lock = NSLock()
    
    var mockResponses: [String: Any] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _mockResponses
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _mockResponses = newValue
        }
    }
    
    var shouldThrowError: Error? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _shouldThrowError
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _shouldThrowError = newValue
        }
    }
    
    var capturedRequests: [Endpoint] {
        lock.lock()
        defer { lock.unlock() }
        return _capturedRequests
    }
    
    var requestCount: Int { capturedRequests.count }
    
    var simulatedDelay: TimeInterval {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _simulatedDelay
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _simulatedDelay = newValue
        }
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Record the request
        lock.lock()
        _capturedRequests.append(endpoint)
        let delay = _simulatedDelay
        let error = _shouldThrowError
        let responses = _mockResponses
        lock.unlock()
        
        // Simulate network delay if needed
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Throw error if configured
        if let error = error {
            throw error
        }
        
        // Return mock response
        guard let response = responses[endpoint.path] as? T else {
            throw NetworkError.invalidResponse
        }
        
        return response
    }
    
    func upload(_ data: Data, to endpoint: Endpoint) async throws {
        lock.lock()
        _capturedRequests.append(endpoint)
        let error = _shouldThrowError
        lock.unlock()
        
        if let error = error {
            throw error
        }
    }
    
    func download(from endpoint: Endpoint) async throws -> Data {
        lock.lock()
        _capturedRequests.append(endpoint)
        let delay = _simulatedDelay
        let error = _shouldThrowError
        let responses = _mockResponses
        lock.unlock()
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if let error = error {
            throw error
        }
        
        guard let data = responses[endpoint.path] as? Data else {
            throw NetworkError.noData
        }
        
        return data
    }
    
    // Verification helpers
    func verify(endpoint: String, calledTimes times: Int) {
        let actualCalls = capturedRequests.filter { $0.path == endpoint }.count
        assert(actualCalls == times,
                "\(endpoint) was called \(actualCalls) times, expected \(times)")
    }
    
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _mockResponses.removeAll()
        _capturedRequests.removeAll()
        _shouldThrowError = nil
        _simulatedDelay = 0
    }
} 
