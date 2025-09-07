import XCTest
@testable import AirFit

final class NetworkReachabilityTests: XCTestCase {

    func testIsHostReachableReflectsInitialConnectivityTrue() async throws {
        let fake = NetworkManagerFake(isReachable: true)
        let reachability = await MainActor.run { NetworkReachability(networkManager: fake, initialIsConnected: true) }
        let result = await reachability.isHostReachable("example.com")
        XCTAssertTrue(result)
    }

    func testIsHostReachableReflectsInitialConnectivityFalse() async throws {
        let fake = NetworkManagerFake(isReachable: false)
        let reachability = await MainActor.run { NetworkReachability(networkManager: fake, initialIsConnected: false) }
        let result = await reachability.isHostReachable("example.com")
        XCTAssertFalse(result)
    }
}

// Minimal fake for NetworkManagementProtocol used by reachability
private final class NetworkManagerFake: NetworkManagementProtocol {
    var isReachable: Bool
    var currentNetworkType: NetworkType = .wifi

    init(isReachable: Bool) { self.isReachable = isReachable }

    func performRequest<T>(_ request: URLRequest, expecting: T.Type) async throws -> T where T : Decodable, T : Sendable {
        throw AppError.serviceUnavailable
    }

    func performStreamingRequest(_ request: URLRequest) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: AppError.serviceUnavailable)
        }
    }

    func downloadData(from url: URL) async throws -> Data { Data() }

    func uploadData(_ data: Data, to url: URL) async throws -> URLResponse { URLResponse() }

    func buildRequest(url: URL, method: String, headers: [String : String]) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        return req
    }
}

