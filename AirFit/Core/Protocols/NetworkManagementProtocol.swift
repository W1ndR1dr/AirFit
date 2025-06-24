import Foundation

// MARK: - Network Management Protocol
protocol NetworkManagementProtocol: AnyObject {
    var isReachable: Bool { get }
    var currentNetworkType: NetworkType { get }
    
    func performRequest<T: Decodable & Sendable>(
        _ request: URLRequest,
        expecting: T.Type
    ) async throws -> T
    
    func performStreamingRequest(
        _ request: URLRequest
    ) -> AsyncThrowingStream<Data, Error>
    
    func downloadData(
        from url: URL
    ) async throws -> Data
    
    func uploadData(
        _ data: Data,
        to url: URL
    ) async throws -> URLResponse
    
    func buildRequest(
        url: URL,
        method: String,
        headers: [String: String]
    ) -> URLRequest
}

// MARK: - Network Type
enum NetworkType: String, Sendable {
    case wifi
    case cellular
    case ethernet
    case unknown
    case none
}
