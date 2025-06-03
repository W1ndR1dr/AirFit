import Foundation
@testable import AirFit

// MARK: - MockNetworkClient
final class MockNetworkClient: NetworkClientProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // Stubbed responses
    var stubbedRequestResult: Any?
    var stubbedRequestError: Error?
    var stubbedUploadError: Error?
    var stubbedDownloadResult: Data = Data()
    var stubbedDownloadError: Error?
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        recordInvocation("request", arguments: endpoint)
        
        if let error = stubbedRequestError {
            throw error
        }
        
        if let result = stubbedRequestResult as? T {
            return result
        }
        
        // Try to decode empty JSON object for simple types
        if T.self == String.self {
            return "" as! T
        }
        
        throw NetworkError.noData
    }
    
    func upload(_ data: Data, to endpoint: Endpoint) async throws {
        recordInvocation("upload", arguments: data, endpoint)
        
        if let error = stubbedUploadError {
            throw error
        }
    }
    
    func download(from endpoint: Endpoint) async throws -> Data {
        recordInvocation("download", arguments: endpoint)
        
        if let error = stubbedDownloadError {
            throw error
        }
        
        return stubbedDownloadResult
    }
    
    // Helper methods for testing
    func stubRequest<T>(with result: T) {
        stubbedRequestResult = result
    }
    
    func stubRequestError(with error: Error) {
        stubbedRequestError = error
    }
    
    func stubUploadError(with error: Error) {
        stubbedUploadError = error
    }
    
    func stubDownload(with data: Data) {
        stubbedDownloadResult = data
    }
    
    func stubDownloadError(with error: Error) {
        stubbedDownloadError = error
    }
    
    // Verify helpers
    func verifyRequest(called times: Int = 1) {
        verify("request", called: times)
    }
    
    func verifyUpload(called times: Int = 1) {
        verify("upload", called: times)
    }
    
    func verifyDownload(called times: Int = 1) {
        verify("download", called: times)
    }
}