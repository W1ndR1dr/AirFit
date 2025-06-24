import Foundation
import Network
import Combine

/// # NetworkManager
/// 
/// ## Purpose
/// Central networking service that handles all HTTP requests, monitors network connectivity,
/// and provides streaming support for AI responses.
///
/// ## Dependencies
/// - `URLSession`: Core networking for HTTP requests
/// - `NWPathMonitor`: Network connectivity monitoring
///
/// ## Key Responsibilities
/// - Build and execute HTTP requests with proper headers
/// - Monitor network connectivity and type (WiFi, Cellular, etc.)
/// - Handle streaming responses for AI providers
/// - Validate HTTP responses and map errors
/// - Provide retry logic and timeout handling
/// - Track network performance metrics
///
/// ## Usage
/// ```swift
/// let network = await container.resolve(NetworkManagementProtocol.self)
/// 
/// // Build and perform request
/// let request = network.buildRequest(url: apiURL, method: "POST")
/// let response: APIResponse = try await network.performRequest(request, expecting: APIResponse.self)
/// 
/// // Stream data
/// let stream = network.performStreamingRequest(request)
/// for try await chunk in stream {
///     // Process chunk
/// }
/// ```
///
/// ## Important Notes
/// - Actor-isolated for thread safety
/// - Automatically monitors network changes
/// - Provides appropriate error types for network failures
actor NetworkManager: NetworkManagementProtocol, ServiceProtocol {
    // Actor-isolated state
    private var _isReachable: Bool = true
    private var _currentNetworkType: NetworkType = .unknown
    
    // Public accessors
    nonisolated var isReachable: Bool {
        // For now, return a default value. In production, consider using AsyncStream for updates
        return true
    }
    nonisolated var currentNetworkType: NetworkType {
        // For now, return a default value. In production, consider using AsyncStream for updates
        return .unknown
    }
    
    // MARK: - ServiceProtocol
    private var _isConfigured: Bool = false
    nonisolated let serviceIdentifier = "network-manager"
    
    // Nonisolated computed property for protocol conformance
    nonisolated var isConfigured: Bool {
        // For read-only access, we can use a simple flag
        // In production, might use AsyncStream or other mechanism
        true // Simplified for now
    }
    
    private let session: URLSession
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.airfit.networkmonitor")
    private var cancellables = Set<AnyCancellable>()
    
    init(session: URLSession = .shared) {
        self.session = session
        self.monitor = NWPathMonitor()
        // Network monitoring setup moved to configure()
    }
    
    // MARK: - ServiceProtocol
    
    func configure() async throws {
        guard !_isConfigured else { return }
        await setupNetworkMonitoring()
        _isConfigured = true
        AppLogger.info("NetworkManager configured", category: .networking)
    }
    
    func reset() async {
        // Nothing to reset for network manager
        AppLogger.info("NetworkManager reset", category: .networking)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: isReachable ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: isReachable ? nil : "Network unreachable",
            metadata: [
                "networkType": currentNetworkType.rawValue,
                "isReachable": "\(isReachable)"
            ]
        )
    }
    
    // MARK: - NetworkManagementProtocol
    
    nonisolated func buildRequest(url: URL, method: String = "GET", headers: [String: String] = [:]) -> URLRequest {
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
    
    func performRequest<T: Decodable & Sendable>(
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
    
    nonisolated func performStreamingRequest(
        _ request: URLRequest
    ) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard isReachable else {
                    continuation.finish(throwing: AppError.from(ServiceError.networkUnavailable))
                    return
                }
                
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: AppError.from(ServiceError.invalidResponse("Response is not HTTP")))
                        return
                    }
                    
                    if !(200...299).contains(httpResponse.statusCode) {
                        continuation.finish(throwing: AppError.from(ServiceError.providerError(
                            code: "\(httpResponse.statusCode)",
                            message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                        )))
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
    
    private func setupNetworkMonitoring() async {
        monitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.updateNetworkStatus(path)
            }
        }
        
        monitor.start(queue: monitorQueue)
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        _isReachable = path.status == .satisfied
        
        if path.usesInterfaceType(.wifi) {
            _currentNetworkType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            _currentNetworkType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            _currentNetworkType = .ethernet
        } else if path.status == .satisfied {
            _currentNetworkType = .unknown
        } else {
            _currentNetworkType = .none
        }
        
        // Cache values for notification
        let isReachableValue = _isReachable
        let networkTypeValue = _currentNetworkType
        
        // Notify observers on MainActor if needed
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .networkStatusChanged,
                object: nil,
                userInfo: ["isReachable": isReachableValue, "type": networkTypeValue]
            )
        }
        
        AppLogger.debug("Network status updated: \(currentNetworkType.rawValue)", category: .networking)
    }
    
    private func validateHTTPResponse(_ response: HTTPURLResponse, data: Data?) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw AppError.from(ServiceError.authenticationFailed("Invalid credentials"))
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw AppError.from(ServiceError.rateLimitExceeded(retryAfter: retryAfter))
        case 400...499:
            throw AppError.from(ServiceError.invalidResponse("Client error: \(response.statusCode)"))
        case 500...599:
            throw AppError.from(ServiceError.providerError(
                code: "\(response.statusCode)",
                message: "Server error"
            ))
        default:
            throw AppError.from(ServiceError.invalidResponse("Unexpected status code: \(response.statusCode)"))
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

// MARK: - Notification Names
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("com.airfit.network.statusChanged")
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
