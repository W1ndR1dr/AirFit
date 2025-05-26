@testable import AirFit
import Foundation

final class MockNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    // Stubbed responses using thread-safe wrappers
    private let _mockResponses = Mutex<[String: Any]>([:])
    private let _shouldThrowError = Mutex<Error?>(nil)
    private let _capturedRequests = Mutex<[Endpoint]>([])
    private let _simulatedDelay = Mutex<TimeInterval>(0)

    var mockResponses: [String: Any] {
        get { _mockResponses.value }
        set { _mockResponses.value = newValue }
    }

    var shouldThrowError: Error? {
        get { _shouldThrowError.value }
        set { _shouldThrowError.value = newValue }
    }

    var capturedRequests: [Endpoint] {
        _capturedRequests.value
    }

    var requestCount: Int { capturedRequests.count }

    var simulatedDelay: TimeInterval {
        get { _simulatedDelay.value }
        set { _simulatedDelay.value = newValue }
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Record the request
        var currentRequests = _capturedRequests.value
        currentRequests.append(endpoint)
        _capturedRequests.value = currentRequests
        
        let delay = _simulatedDelay.value
        let error = _shouldThrowError.value
        let responses = _mockResponses.value

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
        var currentRequests = _capturedRequests.value
        currentRequests.append(endpoint)
        _capturedRequests.value = currentRequests
        
        let error = _shouldThrowError.value

        if let error = error {
            throw error
        }
    }

    func download(from endpoint: Endpoint) async throws -> Data {
        var currentRequests = _capturedRequests.value
        currentRequests.append(endpoint)
        _capturedRequests.value = currentRequests
        
        let delay = _simulatedDelay.value
        let error = _shouldThrowError.value
        let responses = _mockResponses.value

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
        _mockResponses.value.removeAll()
        _capturedRequests.value.removeAll()
        _shouldThrowError.value = nil
        _simulatedDelay.value = 0
    }
}
