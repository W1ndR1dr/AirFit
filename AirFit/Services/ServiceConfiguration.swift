import Foundation

/// Configuration for all services in the application
@MainActor
struct ServiceConfiguration: Sendable {
    // MARK: - AI Service Configuration
    struct AIConfiguration: Sendable {
        let defaultProvider: AIProvider
        let defaultModel: String
        let maxRetries: Int
        let timeout: TimeInterval
        let cacheEnabled: Bool
        let cacheDuration: TimeInterval
        let streamingEnabled: Bool
        let costTrackingEnabled: Bool
        
        static let `default` = AIConfiguration(
            defaultProvider: .openAI,
            defaultModel: "gpt-4o-mini",
            maxRetries: 3,
            timeout: 30,
            cacheEnabled: true,
            cacheDuration: 3600, // 1 hour
            streamingEnabled: true,
            costTrackingEnabled: true
        )
    }
    
    // MARK: - Weather Service Configuration
    struct WeatherConfiguration: Sendable {
        let apiProvider: WeatherProvider
        let updateInterval: TimeInterval
        let cacheEnabled: Bool
        let cacheDuration: TimeInterval
        let defaultUnits: WeatherUnits
        
        enum WeatherProvider: String, Sendable {
            case openWeather = "OpenWeatherMap"
            case weatherAPI = "WeatherAPI"
        }
        
        enum WeatherUnits: String, Sendable {
            case metric
            case imperial
        }
        
        static let `default` = WeatherConfiguration(
            apiProvider: .openWeather,
            updateInterval: 900, // 15 minutes
            cacheEnabled: true,
            cacheDuration: 600, // 10 minutes
            defaultUnits: .imperial
        )
    }
    
    // MARK: - Network Configuration
    struct NetworkConfiguration: Sendable {
        let maxConcurrentRequests: Int
        let requestTimeout: TimeInterval
        let resourceTimeout: TimeInterval
        let retryCount: Int
        let retryDelay: TimeInterval
        let enableLogging: Bool
        
        static let `default` = NetworkConfiguration(
            maxConcurrentRequests: 4,
            requestTimeout: 30,
            resourceTimeout: 60,
            retryCount: 3,
            retryDelay: 1.0,
            enableLogging: true
        )
    }
    
    // MARK: - Analytics Configuration
    struct AnalyticsConfiguration: Sendable {
        let enabled: Bool
        let debugLogging: Bool
        let sessionTimeout: TimeInterval
        let flushInterval: TimeInterval
        let maxEventsPerBatch: Int
        
        static let `default` = AnalyticsConfiguration(
            enabled: true,
            debugLogging: false,
            sessionTimeout: 1800, // 30 minutes
            flushInterval: 60, // 1 minute
            maxEventsPerBatch: 100
        )
    }
    
    // MARK: - Properties
    let ai: AIConfiguration
    let weather: WeatherConfiguration
    let network: NetworkConfiguration
    let analytics: AnalyticsConfiguration
    let environment: Environment
    
    // MARK: - Environment
    enum Environment: String, Sendable {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "https://api-dev.airfit.app"
            case .staging:
                return "https://api-staging.airfit.app"
            case .production:
                return "https://api.airfit.app"
            }
        }
        
        var isDebug: Bool {
            self != .production
        }
    }
    
    // MARK: - Initialization
    static let shared = ServiceConfiguration(
        ai: .default,
        weather: .default,
        network: .default,
        analytics: .default,
        environment: detectEnvironment()
    )
    
    static func detectEnvironment() -> Environment {
        #if DEBUG
        return .development
        #else
        // Check for staging flag in Info.plist or environment variable
        if ProcessInfo.processInfo.environment["STAGING"] != nil {
            return .staging
        }
        return .production
        #endif
    }
}

// MARK: - Service Registry
@MainActor
final class ServiceRegistry {
    static let shared = ServiceRegistry()
    
    private var services: [String: any ServiceProtocol] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    // MARK: - Registration
    func register<T: ServiceProtocol>(_ service: T, for type: T.Type) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        
        services[key] = service
        AppLogger.debug("Registered service: \(key)", category: .services)
    }
    
    func unregister<T: ServiceProtocol>(_ type: T.Type) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        
        services.removeValue(forKey: key)
        AppLogger.debug("Unregistered service: \(key)", category: .services)
    }
    
    // MARK: - Retrieval
    func get<T: ServiceProtocol>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        
        return services[key] as? T
    }
    
    func require<T: ServiceProtocol>(_ type: T.Type) -> T {
        guard let service = get(type) else {
            fatalError("Required service \(type) is not registered")
        }
        return service
    }
    
    // MARK: - Health Check
    func healthCheck() async -> [String: ServiceHealth] {
        var results: [String: ServiceHealth] = [:]
        
        for (key, service) in services {
            results[key] = await service.healthCheck()
        }
        
        return results
    }
    
    // MARK: - Reset
    func resetAll() async {
        for service in services.values {
            await service.reset()
        }
    }
}

// MARK: - Service Locator Pattern Helper
protocol ServiceLocator {
    static var serviceRegistry: ServiceRegistry { get }
}

extension ServiceLocator {
    static var serviceRegistry: ServiceRegistry {
        ServiceRegistry.shared
    }
    
    static func registerService<T: ServiceProtocol>(_ service: T, for type: T.Type) {
        serviceRegistry.register(service, for: type)
    }
    
    static func getService<T: ServiceProtocol>(_ type: T.Type) -> T? {
        serviceRegistry.get(type)
    }
    
    static func requireService<T: ServiceProtocol>(_ type: T.Type) -> T {
        serviceRegistry.require(type)
    }
}