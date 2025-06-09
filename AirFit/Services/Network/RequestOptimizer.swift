import Foundation
import Network
import Combine

/// Network request optimizer - batching, retry, and offline handling
actor RequestOptimizer: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "request-optimizer"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { true } // Always ready for an actor
    
    private let networkMonitor: NetworkMonitor
    private var pendingRequests: [RequestKey: PendingRequest] = [:]
    private var batchQueue: [BatchableRequest] = []
    private var retryQueue: [RetryableRequest] = []
    private let maxBatchSize = 10
    private let batchDelay: TimeInterval = 0.1 // 100ms
    private var batchTimer: Task<Void, Never>?
    
    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        pendingRequests.removeAll()
        batchQueue.removeAll()
        retryQueue.removeAll()
        batchTimer?.cancel()
        batchTimer = nil
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        let isConnected = await MainActor.run { networkMonitor.isConnected }
        return ServiceHealth(
            status: isConnected ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: isConnected ? nil : "Network offline",
            metadata: [
                "pendingRequests": "\(pendingRequests.count)",
                "batchQueueSize": "\(batchQueue.count)",
                "retryQueueSize": "\(retryQueue.count)"
            ]
        )
    }
    
    struct RequestKey: Hashable {
        let endpoint: String
        let method: String
        let bodyHash: Int?
    }
    
    struct PendingRequest {
        let request: URLRequest
        let completion: CheckedContinuation<Data, Error>
        let retryCount: Int
    }
    
    struct BatchableRequest {
        let request: URLRequest
        let completion: CheckedContinuation<Data, Error>
    }
    
    struct RetryableRequest {
        let request: URLRequest
        let completion: CheckedContinuation<Data, Error>
        let retryCount: Int
        let nextRetryTime: Date
    }
    
    // MARK: - Public API
    
    /// Execute request with optimization
    func execute(_ request: URLRequest) async throws -> Data {
        // Check if we're offline
        let isConnected = await MainActor.run { networkMonitor.isConnected }
        if !isConnected {
            throw AppError.from(RequestOptimizerError.offline)
        }
        
        // Check for duplicate in-flight requests
        let key = makeKey(for: request)
        if pendingRequests[key] != nil {
            // Dedupe - wait for existing request
            return try await withCheckedThrowingContinuation { continuation in
                // This would need proper handling in production
                continuation.resume(throwing: AppError.from(RequestOptimizerError.duplicate))
            }
        }
        
        // Check if request is batchable
        if isBatchable(request) {
            return try await batchRequest(request)
        }
        
        // Execute immediately
        return try await executeWithRetry(request)
    }
    
    // MARK: - Batching
    
    private func isBatchable(_ request: URLRequest) -> Bool {
        // Only batch GET requests to specific endpoints
        guard request.httpMethod == "GET",
              let url = request.url,
              url.path.contains("/api/batch-compatible") else {
            return false
        }
        return true
    }
    
    private func batchRequest(_ request: URLRequest) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            batchQueue.append(BatchableRequest(request: request, completion: continuation))
            
            // Start or reset batch timer
            batchTimer?.cancel()
            batchTimer = Task {
                try? await Task.sleep(nanoseconds: UInt64(batchDelay * 1_000_000_000))
                await processBatch()
            }
            
            // Process immediately if batch is full
            if batchQueue.count >= maxBatchSize {
                Task {
                    await processBatch()
                }
            }
        }
    }
    
    private func processBatch() async {
        guard !batchQueue.isEmpty else { return }
        
        let batch = batchQueue
        batchQueue.removeAll()
        
        // In real implementation, would combine requests into single batch API call
        // For now, just execute them with slight optimization
        await withTaskGroup(of: Void.self) { group in
            for item in batch {
                group.addTask {
                    do {
                        let data = try await self.executeWithRetry(item.request)
                        item.completion.resume(returning: data)
                    } catch {
                        item.completion.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Retry Logic
    
    private func executeWithRetry(_ request: URLRequest, retryCount: Int = 0) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.from(RequestOptimizerError.invalidResponse)
            }
            
            if httpResponse.statusCode == 429 { // Rate limited
                throw AppError.from(RequestOptimizerError.rateLimited(retryAfter: httpResponse.value(forHTTPHeaderField: "Retry-After")))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw AppError.from(RequestOptimizerError.httpError(statusCode: httpResponse.statusCode, data: data))
            }
            
            return data
            
        } catch {
            // Determine if retryable
            if shouldRetry(error: error, retryCount: retryCount) {
                let delay = retryDelay(for: retryCount)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(request, retryCount: retryCount + 1)
            }
            throw error
        }
    }
    
    private func shouldRetry(error: Error, retryCount: Int) -> Bool {
        guard retryCount < 3 else { return false }
        
        if let appError = error as? AppError {
            return appError.shouldRetry
        }
        
        // Retry on URLError network failures
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    private func retryDelay(for attempt: Int) -> TimeInterval {
        // Exponential backoff with jitter
        let baseDelay = pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...1)
        return min(baseDelay + jitter, 30) // Max 30s
    }
    
    // MARK: - Helpers
    
    private func makeKey(for request: URLRequest) -> RequestKey {
        RequestKey(
            endpoint: request.url?.absoluteString ?? "",
            method: request.httpMethod ?? "GET",
            bodyHash: request.httpBody?.hashValue
        )
    }
}

// MARK: - Network Monitor

@MainActor
class NetworkMonitor: ObservableObject, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "network-monitor"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }
    
    @Published private(set) var isConnected = true
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // In production, would use NWPathMonitor
        // For now, assume connected
        isConnected = true
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        monitor?.cancel()
        monitor = nil
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        return ServiceHealth(
            status: isConnected ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: isConnected ? nil : "Network offline",
            metadata: ["connected": "\(isConnected)"]
        )
    }
}

// MARK: - Network Errors

enum RequestOptimizerError: LocalizedError {
    case offline
    case timeout
    case connectionLost
    case duplicate
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case rateLimited(retryAfter: String?)
    
    var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .connectionLost:
            return "Connection lost"
        case .duplicate:
            return "Request already in progress"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code, _):
            return "Server error: \(code)"
        case .rateLimited(let retryAfter):
            return "Rate limited. Retry after: \(retryAfter ?? "unknown")"
        }
    }
}

