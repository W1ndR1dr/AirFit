import Foundation

/// Service Registry for managing application services
@MainActor
final class ServiceRegistry {
    
    // MARK: - Singleton
    static let shared = ServiceRegistry()
    
    // MARK: - Properties
    private var services: [ObjectIdentifier: any ServiceProtocol] = [:]
    private var serviceTypes: [ObjectIdentifier: Any.Type] = [:]
    private let lock = NSLock()
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Registration
    
    /// Register a service implementation for a protocol type
    func register<T>(_ service: any ServiceProtocol, for type: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        
        let typeId = ObjectIdentifier(type)
        services[typeId] = service
        serviceTypes[typeId] = type
    }
    
    /// Register multiple services
    func registerAll(_ registrations: [(service: any ServiceProtocol, type: Any.Type)]) {
        for (service, type) in registrations {
            register(service, for: type)
        }
    }
    
    // MARK: - Retrieval
    
    /// Get a service for the specified protocol type
    func get<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        let typeId = ObjectIdentifier(type)
        return services[typeId] as? T
    }
    
    /// Get a required service (crashes if not found)
    func require<T>(_ type: T.Type) -> T {
        guard let service = get(type) else {
            fatalError("Required service \(type) not registered")
        }
        return service
    }
    
    /// Check if a service is registered
    func has<T>(_ type: T.Type) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let typeId = ObjectIdentifier(type)
        return services[typeId] != nil
    }
    
    // MARK: - Health Check
    
    /// Perform health check on all registered services
    func healthCheck() async -> [String: ServiceHealth] {
        var results: [String: ServiceHealth] = [:]
        
        for (typeId, service) in services {
            if let typeName = serviceTypes[typeId] {
                let health = await service.healthCheck()
                results["\(typeName)"] = health
            }
        }
        
        return results
    }
    
    /// Get health status for a specific service
    func healthCheck<T>(for type: T.Type) async -> ServiceHealth? {
        guard let service = get(type) as? any ServiceProtocol else {
            return nil
        }
        
        return await service.healthCheck()
    }
    
    // MARK: - Management
    
    /// Reset all services
    func resetAll() async {
        for service in services.values {
            await service.reset()
        }
    }
    
    /// Reset a specific service
    func reset<T>(_ type: T.Type) async {
        guard let service = get(type) as? any ServiceProtocol else {
            return
        }
        
        await service.reset()
    }
    
    /// Remove a service from the registry
    func unregister<T>(_ type: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        
        let typeId = ObjectIdentifier(type)
        services.removeValue(forKey: typeId)
        serviceTypes.removeValue(forKey: typeId)
    }
    
    /// Remove all services
    func unregisterAll() {
        lock.lock()
        defer { lock.unlock() }
        
        services.removeAll()
        serviceTypes.removeAll()
    }
    
    // MARK: - Debug
    
    /// Get list of all registered service types
    var registeredTypes: [String] {
        lock.lock()
        defer { lock.unlock() }
        
        return serviceTypes.values.map { "\($0)" }
    }
    
    /// Get count of registered services
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        
        return services.count
    }
}

// MARK: - Service Registration Extensions

extension ServiceRegistry {
    
    /// Convenience method to register common services
    func registerDefaultServices(
        networkManager: NetworkManagementProtocol & ServiceProtocol,
        apiKeyManager: APIKeyManagementProtocol & ServiceProtocol,
        aiService: AIServiceProtocol?,
        weatherService: WeatherServiceProtocol?
    ) {
        register(networkManager, for: NetworkManagementProtocol.self)
        register(apiKeyManager, for: APIKeyManagementProtocol.self)
        
        if let aiService = aiService {
            register(aiService, for: AIServiceProtocol.self)
        }
        
        if let weatherService = weatherService {
            register(weatherService, for: WeatherServiceProtocol.self)
        }
    }
}

// MARK: - Property Wrapper for Service Injection

@propertyWrapper
@MainActor
struct Injected<Service> {
    private let type: Service.Type
    
    init(_ type: Service.Type) {
        self.type = type
    }
    
    var wrappedValue: Service {
        ServiceRegistry.shared.require(type)
    }
    
    var projectedValue: Service? {
        ServiceRegistry.shared.get(type)
    }
}

// MARK: - Service Bootstrapper

/// Helper to bootstrap services in the correct order
@MainActor
struct ServiceBootstrapper {
    
    static func bootstrap() async throws {
        let registry = ServiceRegistry.shared
        
        // Clear any existing services
        await registry.resetAll()
        registry.unregisterAll()
        
        // Initialize core services
        let networkManager = NetworkManager.shared
        let apiKeyManager = APIKeyManager()
        
        // Register core services
        registry.register(networkManager, for: NetworkManagementProtocol.self)
        registry.register(apiKeyManager, for: APIKeyManagementProtocol.self)
        
        // Initialize AI service if keys are available
        if await apiKeyManager.getAllConfiguredProviders().count > 0 {
            let llmOrchestrator = LLMOrchestrator(apiKeyManager: apiKeyManager)
            let aiService = AIService(llmOrchestrator: llmOrchestrator)
            
            try await aiService.configure()
            registry.register(aiService, for: AIServiceProtocol.self)
        }
        
        // Initialize weather service - WeatherKit requires no configuration
        let weatherService = WeatherService()
        try await weatherService.configure()
        registry.register(weatherService, for: WeatherServiceProtocol.self)
        
        // Perform initial health check
        let healthResults = await registry.healthCheck()
        for (service, health) in healthResults {
            print("Service \(service): \(health.status)")
        }
    }
}