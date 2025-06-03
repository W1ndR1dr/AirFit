import Foundation
import Network
import Combine

@MainActor
final class NetworkManager: NetworkManagementProtocol, ObservableObject {
    static let shared = NetworkManager()
    
    @Published private(set) var isReachable: Bool = true
    @Published private(set) var currentNetworkType: NetworkType = .unknown
    
    private let session: URLSession
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.airfit.networkmonitor")
    private var cancellables = Set<AnyCancellable>()
    
    init(session: URLSession = .shared) {
        self.session = session
        self.monitor = NWPathMonitor()
        
        setupNetworkMonitoring()
    }
    
    // MARK: - NetworkManagementProtocol
    
    func buildRequest(url: URL, method: String = "GET", headers: [String: String] = [:]) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    func performRequest<T: Decodable>(
        _ request: URLRequest,
        expecting: T.Type
    ) async throws -> T {
        guard isReachable else {
            throw ServiceError.networkUnavailable
        }
        
        let startTime = Date()
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.invalidResponse("Response is not HTTP")
            }
            
            // Log response time
            let responseTime = Date().timeIntervalSince(startTime)
            AppLogger.debug("Request completed in \(responseTime)s", category: .networking)
            
            try validateHTTPResponse(httpResponse, data: data)
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                throw ServiceError.invalidResponse("Failed to decode: \(error)")
            }
        } catch {
            if let serviceError = error as? ServiceError {
                throw serviceError
            }
            throw ServiceError.unknown(error)
        }
    }
    
    func performStreamingRequest(
        _ request: URLRequest
    ) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard isReachable else {
                    continuation.finish(throwing: ServiceError.networkUnavailable)
                    return
                }
                
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: ServiceError.invalidResponse("Response is not HTTP"))
                        return
                    }
                    
                    if !(200...299).contains(httpResponse.statusCode) {
                        continuation.finish(throwing: ServiceError.providerError(
                            code: "\(httpResponse.statusCode)",
                            message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                        ))
                        return
                    }
                    
                    for try await line in bytes.lines {
                        guard !Task.isCancelled else {
                            continuation.finish(throwing: ServiceError.cancelled)
                            return
                        }
                        
                        if let data = line.data(using: .utf8) {
                            continuation.yield(data)
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func downloadData(from url: URL) async throws -> Data {
        guard isReachable else {
            throw ServiceError.networkUnavailable
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.invalidResponse("Response is not HTTP")
            }
            
            try validateHTTPResponse(httpResponse, data: data)
            
            return data
        } catch {
            if let serviceError = error as? ServiceError {
                throw serviceError
            }
            throw ServiceError.unknown(error)
        }
    }
    
    func uploadData(_ data: Data, to url: URL) async throws -> URLResponse {
        guard isReachable else {
            throw ServiceError.networkUnavailable
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.invalidResponse("Response is not HTTP")
            }
            
            try validateHTTPResponse(httpResponse, data: nil)
            
            return response
        } catch {
            if let serviceError = error as? ServiceError {
                throw serviceError
            }
            throw ServiceError.unknown(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateNetworkStatus(path)
            }
        }
        
        monitor.start(queue: monitorQueue)
    }
    
    @MainActor
    private func updateNetworkStatus(_ path: NWPath) {
        isReachable = path.status == .satisfied
        
        if path.usesInterfaceType(.wifi) {
            currentNetworkType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            currentNetworkType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            currentNetworkType = .ethernet
        } else if path.status == .satisfied {
            currentNetworkType = .unknown
        } else {
            currentNetworkType = .none
        }
        
        AppLogger.debug("Network status updated: \(currentNetworkType.rawValue)", category: .networking)
    }
    
    private func validateHTTPResponse(_ response: HTTPURLResponse, data: Data?) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw ServiceError.authenticationFailed("Invalid credentials")
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw ServiceError.rateLimitExceeded(retryAfter: retryAfter)
        case 400...499:
            throw ServiceError.invalidResponse("Client error: \(response.statusCode)")
        case 500...599:
            throw ServiceError.providerError(
                code: "\(response.statusCode)",
                message: "Server error"
            )
        default:
            throw ServiceError.invalidResponse("Unexpected status code: \(response.statusCode)")
        }
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Request Builder Helpers
extension NetworkManager {
    func buildRequest(
        url: URL,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Data? = nil,
        timeout: TimeInterval = 30
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        // Custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.httpBody = body
        
        return request
    }
    
    private var userAgent: String {
        let appVersion = AppConstants.appVersion
        let buildNumber = AppConstants.buildNumber
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        return "AirFit/\(appVersion) (Build \(buildNumber); \(osVersion))"
    }
}

// MARK: - URLSession Configuration
extension NetworkManager {
    static func createURLSession(
        configuration: URLSessionConfiguration = .default,
        delegate: URLSessionDelegate? = nil
    ) -> URLSession {
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .useProtocolCachePolicy
        
        return URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
    }
}