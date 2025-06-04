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


// MARK: - Service Locator Pattern Helper
protocol ServiceLocator {
    static var serviceRegistry: ServiceRegistry { get }
}

extension ServiceLocator {
    @MainActor
    static var serviceRegistry: ServiceRegistry {
        ServiceRegistry.shared
    }
    
    @MainActor
    static func registerService<T: ServiceProtocol>(_ service: T, for type: T.Type) {
        serviceRegistry.register(service, for: type)
    }
    
    @MainActor
    static func getService<T: ServiceProtocol>(_ type: T.Type) -> T? {
        serviceRegistry.get(type)
    }
    
    @MainActor
    static func requireService<T: ServiceProtocol>(_ type: T.Type) -> T {
        serviceRegistry.require(type)
    }
}