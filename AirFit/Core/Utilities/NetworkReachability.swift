import Foundation
import Network
import Combine

/// Monitors network connectivity status and provides reactive updates
@MainActor
final class NetworkReachability: ObservableObject {
    // MARK: - Singleton
    static let shared = NetworkReachability()
    
    // MARK: - Published Properties
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isExpensive: Bool = false
    @Published private(set) var isConstrained: Bool = false
    
    // MARK: - Private Properties
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.airfit.networkmonitor")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Types
    enum ConnectionType: String, CaseIterable {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case unknown = "Unknown"
        case none = "None"
        
        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown: return "questionmark.circle"
            case .none: return "wifi.slash"
            }
        }
        
        var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .unknown: return "Unknown"
            case .none: return "No Connection"
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring network connectivity
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    /// Stops monitoring network connectivity
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Checks if a specific host is reachable
    func isHostReachable(_ host: String) async -> Bool {
        guard isConnected else { return false }
        
        do {
            let url = URL(string: "https://\(host)")!
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            return false
        }
    }
    
    /// Waits for connectivity with optional timeout
    func waitForConnectivity(timeout: TimeInterval = 30) async throws {
        if isConnected { return }
        
        let startTime = Date()
        
        while !isConnected {
            if Date().timeIntervalSince(startTime) > timeout {
                throw ReachabilityError.timeout
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    /// Returns current connection quality
    var connectionQuality: ConnectionQuality {
        switch connectionType {
        case .wifi, .ethernet:
            return isConstrained ? .moderate : .good
        case .cellular:
            return isExpensive ? .poor : .moderate
        case .unknown:
            return .unknown
        case .none:
            return .none
        }
    }
    
    // MARK: - Private Methods
    
    private func updateConnectionStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else if path.status == .satisfied {
            connectionType = .unknown
        } else {
            connectionType = .none
        }
        
        logConnectionChange()
    }
    
    private func logConnectionChange() {
        AppLogger.info("""
            Network status changed:
            - Connected: \(isConnected)
            - Type: \(connectionType.displayName)
            - Expensive: \(isExpensive)
            - Constrained: \(isConstrained)
            """, category: .network)
    }
}

// MARK: - Connection Quality

extension NetworkReachability {
    enum ConnectionQuality: String, CaseIterable {
        case good = "Good"
        case moderate = "Moderate"
        case poor = "Poor"
        case unknown = "Unknown"
        case none = "No Connection"
        
        var color: String {
            switch self {
            case .good: return "SuccessColor"
            case .moderate: return "WarningColor"
            case .poor: return "ErrorColor"
            case .unknown: return "TextSecondary"
            case .none: return "ErrorColor"
            }
        }
        
        var recommendation: String {
            switch self {
            case .good:
                return "Great connection for all features"
            case .moderate:
                return "Good for most features, large downloads may be slow"
            case .poor:
                return "Basic features available, some may be limited"
            case .unknown:
                return "Connection quality unknown"
            case .none:
                return "Offline mode - limited features available"
            }
        }
    }
}

// MARK: - Network Error

enum ReachabilityError: LocalizedError {
    case noConnection
    case timeout
    case hostUnreachable(String)
    case poorConnection
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available"
        case .timeout:
            return "Network request timed out"
        case .hostUnreachable(let host):
            return "Cannot reach \(host)"
        case .poorConnection:
            return "Poor network connection detected"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Please check your internet connection and try again"
        case .timeout:
            return "The request took too long. Please try again"
        case .hostUnreachable:
            return "The service may be temporarily unavailable"
        case .poorConnection:
            return "Try moving to an area with better signal"
        }
    }
}

// MARK: - SwiftUI Integration

extension NetworkReachability {
    /// Convenience property for SwiftUI views
    var statusMessage: String {
        if isConnected {
            return "\(connectionType.displayName) • \(connectionQuality.rawValue)"
        } else {
            return "No Connection"
        }
    }
    
    /// Convenience property for showing alerts
    var shouldShowOfflineAlert: Bool {
        !isConnected
    }
    
    /// Convenience method for retry logic
    func performWithConnectivity<T: Sendable>(
        timeout: TimeInterval = 30,
        operation: () async throws -> T
    ) async throws -> T {
        try await waitForConnectivity(timeout: timeout)
        return try await operation()
    }
}

// MARK: - Publisher Extensions

extension NetworkReachability {
    /// Publisher for connection status changes
    var connectionPublisher: AnyPublisher<Bool, Never> {
        $isConnected
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    /// Publisher for connection type changes
    var connectionTypePublisher: AnyPublisher<ConnectionType, Never> {
        $connectionType
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    /// Publisher for connection quality changes
    var connectionQualityPublisher: AnyPublisher<ConnectionQuality, Never> {
        Publishers.CombineLatest3($connectionType, $isExpensive, $isConstrained)
            .map { [weak self] _, _, _ in
                self?.connectionQuality ?? .unknown
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}