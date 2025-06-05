import Foundation
@testable import AirFit

// MARK: - MockNetworkManager
@MainActor
final class MockNetworkManager: NetworkManagementProtocol, MockProtocol {
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // NetworkManagementProtocol conformance
    var isReachable: Bool = true
    var currentNetworkType: NetworkType = .wifi
    
    // Stubbed responses
    var stubbedPerformRequestResult: Any?
    var stubbedPerformRequestError: Error?
    var stubbedStreamingRequestChunks: [Data] = []
    var stubbedStreamingRequestError: Error?
    var stubbedDownloadDataResult: Data = Data()
    var stubbedDownloadDataError: Error?
    var stubbedUploadDataResponse: URLResponse = HTTPURLResponse(
        url: URL(string: "https://test.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!
    var stubbedUploadDataError: Error?
    
    func performRequest<T: Decodable & Sendable>(
        _ request: URLRequest,
        expecting: T.Type
    ) async throws -> T {
        recordInvocation("performRequest", arguments: request, String(describing: expecting))
        
        if let error = stubbedPerformRequestError {
            throw error
        }
        
        if let result = stubbedPerformRequestResult as? T {
            return result
        }
        
        // Try to create a default instance for common types
        if T.self == String.self {
            return "" as! T
        }
        
        throw NetworkError.noData
    }
    
    func performStreamingRequest(_ request: URLRequest) -> AsyncThrowingStream<Data, Error> {
        recordInvocation("performStreamingRequest", arguments: request)
        
        return AsyncThrowingStream { continuation in
            Task {
                if let error = stubbedStreamingRequestError {
                    continuation.finish(throwing: error)
                    return
                }
                
                for chunk in stubbedStreamingRequestChunks {
                    continuation.yield(chunk)
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
                }
                
                continuation.finish()
            }
        }
    }
    
    func downloadData(from url: URL) async throws -> Data {
        recordInvocation("downloadData", arguments: url)
        
        if let error = stubbedDownloadDataError {
            throw error
        }
        
        return stubbedDownloadDataResult
    }
    
    func uploadData(_ data: Data, to url: URL) async throws -> URLResponse {
        recordInvocation("uploadData", arguments: data, url)
        
        if let error = stubbedUploadDataError {
            throw error
        }
        
        return stubbedUploadDataResponse
    }
    
    func buildRequest(
        url: URL,
        method: String,
        headers: [String: String]
    ) -> URLRequest {
        recordInvocation("buildRequest", arguments: url, method, headers)
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        return request
    }
    
    // Helper methods for testing
    func stubRequest<T>(with result: T) {
        stubbedPerformRequestResult = result
    }
    
    func stubRequestError(with error: Error) {
        stubbedPerformRequestError = error
    }
    
    func stubStreamingRequest(with chunks: [Data]) {
        stubbedStreamingRequestChunks = chunks
    }
    
    func stubStreamingRequestError(with error: Error) {
        stubbedStreamingRequestError = error
    }
    
    func stubDownloadData(with data: Data) {
        stubbedDownloadDataResult = data
    }
    
    func stubDownloadDataError(with error: Error) {
        stubbedDownloadDataError = error
    }
    
    func stubUploadResponse(with response: URLResponse) {
        stubbedUploadDataResponse = response
    }
    
    func stubUploadError(with error: Error) {
        stubbedUploadDataError = error
    }
    
    func stubNetworkStatus(reachable: Bool, type: NetworkType) {
        isReachable = reachable
        currentNetworkType = type
    }
    
    // Verify helpers
    func verifyPerformRequest(called times: Int = 1) {
        verify("performRequest", called: times)
    }
    
    func verifyStreamingRequest(called times: Int = 1) {
        verify("performStreamingRequest", called: times)
    }
    
    func verifyDownloadData(called times: Int = 1) {
        verify("downloadData", called: times)
    }
    
    func verifyUploadData(called times: Int = 1) {
        verify("uploadData", called: times)
    }
}