# Phase 4: Dependency Injection & Service Lifecycle (Days 10-12)

## ⚠️ IMPORTANT: This Document Has Been Revised!

**Please use [CLEANUP_PHASE_4_DI_OVERHAUL_REVISED.md](CLEANUP_PHASE_4_DI_OVERHAUL_REVISED.md) instead.**

After analyzing the codebase, we found:
- ✅ ServiceRegistry already provides good DI functionality
- ✅ DependencyContainer works fine for SwiftUI integration
- ✅ No DI-related bugs or performance issues exist
- ❌ A full overhaul would be busy work with no real value

The revised version focuses on:
- 🚨 Fixing the critical force cast (crash risk!)
- 📱 Creating OfflineAIService to replace production mock usage
- 📝 Documenting the existing DI system
- ⏱️ 2-4 hours of high-value work (not 3 days!)

## Overview (Original - See Revised for Pragmatic Approach)
This phase completely overhauls the dependency injection system, implements proper service lifecycle management, and ensures thread-safe initialization.

## Day 10: Dependency Injection Consolidation

### Task 10.1: Remove DependencyContainer (3 hours)

**Migrate to ServiceRegistry Pattern**

1. **Create Enhanced ServiceRegistry**

**Update**: `/AirFit/Services/ServiceRegistry.swift`

```swift
import Foundation
import SwiftData

/// Thread-safe service registry with lifecycle management
actor ServiceRegistry {
    static let shared = ServiceRegistry()
    
    private var services: [ObjectIdentifier: Any] = [:]
    private var factories: [ObjectIdentifier: () async throws -> Any] = [:]
    private var initializationOrder: [ObjectIdentifier] = []
    
    private init() {}
    
    // MARK: - Registration
    
    /// Register a service factory for lazy initialization
    func registerFactory<T>(
        _ type: T.Type,
        factory: @escaping () async throws -> T
    ) {
        let key = ObjectIdentifier(type)
        factories[key] = factory
        
        // Track initialization order for dependencies
        if !initializationOrder.contains(key) {
            initializationOrder.append(key)
        }
    }
    
    /// Register a pre-initialized service
    func register<T>(_ service: T, for type: T.Type) {
        let key = ObjectIdentifier(type)
        services[key] = service
    }
    
    // MARK: - Resolution
    
    /// Resolve a service, initializing if needed
    func resolve<T>(_ type: T.Type) async throws -> T {
        let key = ObjectIdentifier(type)
        
        // Check if already initialized
        if let service = services[key] as? T {
            return service
        }
        
        // Check for factory
        guard let factory = factories[key] else {
            throw ServiceRegistryError.serviceNotRegistered(String(describing: type))
        }
        
        // Initialize service
        let service = try await factory()
        guard let typedService = service as? T else {
            throw ServiceRegistryError.typeMismatch(
                expected: String(describing: type),
                actual: String(describing: type(of: service))
            )
        }
        
        // Cache the initialized service
        services[key] = typedService
        
        // Configure if needed
        if let configurableService = typedService as? ServiceProtocol {
            try await configurableService.configure()
        }
        
        return typedService
    }
    
    // MARK: - Lifecycle
    
    /// Initialize all registered services in dependency order
    func initializeAll() async throws {
        for key in initializationOrder {
            if services[key] == nil, let factory = factories[key] {
                let service = try await factory()
                services[key] = service
                
                if let configurableService = service as? ServiceProtocol {
                    try await configurableService.configure()
                }
            }
        }
    }
    
    /// Reset all services
    func resetAll() async {
        // Reset in reverse order
        for key in initializationOrder.reversed() {
            if let service = services[key] as? ServiceProtocol {
                await service.reset()
            }
        }
        services.removeAll()
    }
    
    /// Health check all services
    func healthCheckAll() async -> [String: ServiceHealth] {
        var results: [String: ServiceHealth] = [:]
        
        for (_, service) in services {
            if let healthCheckable = service as? ServiceProtocol {
                let health = await healthCheckable.healthCheck()
                results[healthCheckable.serviceIdentifier] = health
            }
        }
        
        return results
    }
}

enum ServiceRegistryError: LocalizedError {
    case serviceNotRegistered(String)
    case typeMismatch(expected: String, actual: String)
    case initializationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let type):
            return "Service not registered: \(type)"
        case .typeMismatch(let expected, let actual):
            return "Type mismatch: expected \(expected), got \(actual)"
        case .initializationFailed(let reason):
            return "Service initialization failed: \(reason)"
        }
    }
}
```

2. **Create Service Configuration**

**Create**: `/AirFit/Services/ServiceConfiguration.swift`

```swift
import Foundation
import SwiftData

/// Configures all services with proper dependency order
struct ServiceConfigurator {
    
    static func configure(with modelContainer: ModelContainer) async throws {
        let registry = ServiceRegistry.shared
        
        // Level 0: No dependencies
        registry.registerFactory(KeychainWrapper.self) {
            KeychainWrapper.shared
        }
        
        registry.registerFactory(NetworkClient.self) {
            NetworkClient.shared
        }
        
        // Level 1: Basic dependencies
        registry.registerFactory(APIKeyManagerProtocol.self) {
            let keychain = try await registry.resolve(KeychainWrapper.self)
            return DefaultAPIKeyService(keychain: keychain)
        }
        
        registry.registerFactory(NetworkManagerProtocol.self) {
            let client = try await registry.resolve(NetworkClient.self)
            return NetworkManager(client: client)
        }
        
        // Level 2: Service dependencies
        registry.registerFactory(UserServiceProtocol.self) {
            let context = ModelContext(modelContainer)
            return await DefaultUserService(modelContext: context)
        }
        
        registry.registerFactory(HealthKitManagerProtocol.self) {
            await HealthKitManager()
        }
        
        registry.registerFactory(WeatherServiceProtocol.self) {
            await WeatherKitService()
        }
        
        // Level 3: Complex dependencies
        registry.registerFactory(LLMOrchestrator.self) {
            let apiKeyManager = try await registry.resolve(APIKeyManagerProtocol.self)
            return await LLMOrchestrator(apiKeyManager: apiKeyManager)
        }
        
        registry.registerFactory(AIServiceProtocol.self) {
            let orchestrator = try await registry.resolve(LLMOrchestrator.self)
            let service = await DefaultAIService(llmOrchestrator: orchestrator)
            
            // Try to configure, fall back to offline if needed
            do {
                try await service.configure()
                return service
            } catch {
                AppLogger.warning("AI service configuration failed, using offline mode", category: .services)
                return await OfflineAIService()
            }
        }
        
        // Initialize all services
        try await registry.initializeAll()
    }
}
```

### Task 10.2: Update App Initialization (2 hours)

**Update**: `/AirFit/Application/AirFitApp.swift`

```swift
import SwiftUI
import SwiftData

@main
struct AirFitApp: App {
    @State private var isInitialized = false
    @State private var initializationError: Error?
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            self.modelContainer = try ModelContainer(
                for: User.self, FoodEntry.self, Workout.self, /* other models */
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if isInitialized {
                ContentView()
                    .modelContainer(modelContainer)
                    .environmentObject(ServiceProvider())
            } else if let error = initializationError {
                InitializationErrorView(error: error)
            } else {
                InitializingView()
                    .task {
                        await initializeApp()
                    }
            }
        }
    }
    
    private func initializeApp() async {
        do {
            // Configure all services
            try await ServiceConfigurator.configure(with: modelContainer)
            
            // Perform health checks
            let healthResults = await ServiceRegistry.shared.healthCheckAll()
            
            // Log any unhealthy services
            for (service, health) in healthResults {
                if health.status != .healthy {
                    AppLogger.warning("\(service) is \(health.status): \(health.errorMessage ?? "Unknown")", category: .services)
                }
            }
            
            isInitialized = true
        } catch {
            AppLogger.error("App initialization failed: \(error)", category: .app)
            initializationError = error
        }
    }
}
```

### Task 10.3: Create Service Provider (2 hours)

**Create**: `/AirFit/Core/Services/ServiceProvider.swift`

```swift
import SwiftUI

/// Provides services to the view hierarchy
@MainActor
class ServiceProvider: ObservableObject {
    private let registry = ServiceRegistry.shared
    
    // Cached service references
    private var cachedServices: [ObjectIdentifier: Any] = [:]
    
    func get<T>(_ type: T.Type) -> T? {
        let key = ObjectIdentifier(type)
        
        // Check cache first
        if let cached = cachedServices[key] as? T {
            return cached
        }
        
        // Resolve from registry
        Task { @MainActor in
            if let service = try? await registry.resolve(type) {
                cachedServices[key] = service
            }
        }
        
        return nil
    }
    
    func getAsync<T>(_ type: T.Type) async throws -> T {
        let key = ObjectIdentifier(type)
        
        // Check cache first
        if let cached = cachedServices[key] as? T {
            return cached
        }
        
        // Resolve and cache
        let service = try await registry.resolve(type)
        cachedServices[key] = service
        return service
    }
}

// MARK: - View Extensions

extension View {
    func withServiceProvider() -> some View {
        self.environmentObject(ServiceProvider())
    }
}

// MARK: - Property Wrapper

@propertyWrapper
struct Injected<Service> {
    private let serviceType: Service.Type
    @EnvironmentObject private var provider: ServiceProvider
    
    init(_ serviceType: Service.Type) {
        self.serviceType = serviceType
    }
    
    var wrappedValue: Service? {
        provider.get(serviceType)
    }
}
```

## Day 11: Service Lifecycle Management

### Task 11.1: Implement Service Health Monitoring (3 hours)

**Create**: `/AirFit/Services/Monitoring/ServiceHealthMonitor.swift`

```swift
import Foundation

/// Monitors health of all registered services
actor ServiceHealthMonitor {
    static let shared = ServiceHealthMonitor()
    
    private var isMonitoring = false
    private var healthCheckTask: Task<Void, Never>?
    private let checkInterval: TimeInterval = 60 // 1 minute
    
    private init() {}
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        healthCheckTask = Task {
            while isMonitoring {
                await performHealthChecks()
                try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        healthCheckTask?.cancel()
        healthCheckTask = nil
    }
    
    private func performHealthChecks() async {
        let results = await ServiceRegistry.shared.healthCheckAll()
        
        for (service, health) in results {
            switch health.status {
            case .unhealthy:
                await handleUnhealthyService(service, health: health)
            case .degraded:
                AppLogger.warning("Service \(service) is degraded: \(health.errorMessage ?? "Unknown")", category: .monitoring)
            case .healthy:
                break // All good
            }
        }
        
        // Post notification for UI updates
        await MainActor.run {
            NotificationCenter.default.post(
                name: .serviceHealthUpdated,
                object: nil,
                userInfo: ["results": results]
            )
        }
    }
    
    private func handleUnhealthyService(_ identifier: String, health: ServiceHealth) async {
        AppLogger.error("Service \(identifier) is unhealthy: \(health.errorMessage ?? "Unknown")", category: .monitoring)
        
        // Attempt recovery
        if let service = await getService(identifier: identifier) as? ServiceProtocol {
            do {
                await service.reset()
                try await service.configure()
                AppLogger.info("Successfully recovered service \(identifier)", category: .monitoring)
            } catch {
                AppLogger.error("Failed to recover service \(identifier): \(error)", category: .monitoring)
            }
        }
    }
    
    private func getService(identifier: String) async -> Any? {
        // This would need to be implemented based on service registry
        // For now, return nil
        return nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let serviceHealthUpdated = Notification.Name("serviceHealthUpdated")
}
```

### Task 11.2: Remove @MainActor from Services (4 hours)

Convert services from `@MainActor` classes to proper `actor` types:

**Example - Update WeatherKitService**:

```swift
// Before
@MainActor
final class WeatherKitService: WeatherServiceProtocol {

// After
actor WeatherKitService: WeatherServiceProtocol {
    // Remove @MainActor, service runs on its own executor
```

**Services to Update**:
1. `WeatherKitService` - Remove @MainActor
2. `DefaultAPIKeyService` - Convert to actor
3. `NotificationManager` - Convert to actor  
4. `DefaultUserService` - Already has @MainActor, needs careful migration
5. All other services marked with @MainActor

**Migration Strategy**:
```swift
// For services that need main actor access
actor SomeService {
    func updateUI() async {
        await MainActor.run {
            // UI updates here
        }
    }
}
```

### Task 11.3: Implement Service Warmup (2 hours)

**Create**: `/AirFit/Services/ServiceWarmup.swift`

```swift
import Foundation

/// Handles service warmup during app launch
struct ServiceWarmup {
    
    /// Warm up critical services for better initial performance
    static func warmupCriticalServices() async {
        await withTaskGroup(of: Void.self) { group in
            let registry = ServiceRegistry.shared
            
            // Warm up AI service
            group.addTask {
                if let aiService = try? await registry.resolve(AIServiceProtocol.self) {
                    _ = await aiService.healthCheck()
                }
            }
            
            // Warm up user service
            group.addTask {
                if let userService = try? await registry.resolve(UserServiceProtocol.self) {
                    _ = try? await userService.getCurrentUser()
                }
            }
            
            // Warm up health kit
            group.addTask {
                if let healthKit = try? await registry.resolve(HealthKitManagerProtocol.self) {
                    _ = await healthKit.healthCheck()
                }
            }
            
            // Pre-load exercise database
            group.addTask {
                _ = try? await ExerciseDatabase.shared.preloadData()
            }
        }
        
        AppLogger.info("Service warmup completed", category: .performance)
    }
}
```

## Day 12: Performance & Final Cleanup

### Task 12.1: Implement Lazy Service Loading (3 hours)

**Update ServiceRegistry** to support lazy loading patterns:

```swift
extension ServiceRegistry {
    /// Register a lazy service that's only initialized when first accessed
    func registerLazy<T>(
        _ type: T.Type,
        factory: @escaping () async throws -> T
    ) {
        registerFactory(type) { [weak self] in
            // Log lazy initialization
            AppLogger.debug("Lazy initializing \(type)", category: .services)
            
            let service = try await factory()
            
            // Track initialization metrics
            await self?.trackInitialization(type: type)
            
            return service
        }
    }
    
    private func trackInitialization(type: Any.Type) {
        // Track metrics for performance monitoring
        let typeName = String(describing: type)
        AppLogger.performance("Initialized \(typeName)", category: .services)
    }
}
```

### Task 12.2: Add Dependency Validation (2 hours)

**Create**: `/AirFit/Services/DependencyValidator.swift`

```swift
import Foundation

/// Validates service dependencies at compile time and runtime
struct DependencyValidator {
    
    /// Validate all service dependencies are properly registered
    static func validate() async throws {
        let registry = ServiceRegistry.shared
        
        // Define dependency graph
        let dependencies: [(service: Any.Type, requires: [Any.Type])] = [
            (AIServiceProtocol.self, requires: [LLMOrchestrator.self]),
            (LLMOrchestrator.self, requires: [APIKeyManagerProtocol.self]),
            (DefaultUserService.self, requires: []),
            (NutritionService.self, requires: [UserServiceProtocol.self, AIServiceProtocol.self]),
            // Add all service dependencies
        ]
        
        // Validate each dependency
        for (serviceType, requirements) in dependencies {
            for requiredType in requirements {
                do {
                    _ = try await registry.resolve(requiredType)
                } catch {
                    throw DependencyError.missingDependency(
                        service: String(describing: serviceType),
                        dependency: String(describing: requiredType)
                    )
                }
            }
        }
        
        AppLogger.info("All dependencies validated successfully", category: .services)
    }
}

enum DependencyError: LocalizedError {
    case missingDependency(service: String, dependency: String)
    case circularDependency(services: [String])
    
    var errorDescription: String? {
        switch self {
        case .missingDependency(let service, let dependency):
            return "\(service) requires \(dependency) but it's not registered"
        case .circularDependency(let services):
            return "Circular dependency detected: \(services.joined(separator: " -> "))"
        }
    }
}
```

### Task 12.3: Performance Optimization (3 hours)

1. **Add Service Metrics**:

```swift
struct ServiceMetrics {
    let initializationTime: TimeInterval
    let lastHealthCheckTime: TimeInterval
    let averageResponseTime: TimeInterval
    let errorRate: Double
}

extension ServiceProtocol {
    func trackMetrics() -> ServiceMetrics {
        // Implementation
    }
}
```

2. **Implement Caching Strategy**:

```swift
actor ServiceCache {
    static let shared = ServiceCache()
    
    private var cache: [String: (value: Any, expiry: Date)] = [:]
    
    func get<T>(_ key: String, type: T.Type) -> T? {
        guard let cached = cache[key],
              cached.expiry > Date() else {
            return nil
        }
        return cached.value as? T
    }
    
    func set<T>(_ value: T, for key: String, ttl: TimeInterval = 300) {
        cache[key] = (value, Date().addingTimeInterval(ttl))
    }
}
```

### Task 12.4: Final Cleanup Script (1 hour)

**Create**: `/AirFit/Scripts/final_cleanup.sh`

```bash
#!/bin/bash

echo "=== AirFit Final Cleanup ==="

# Remove DependencyContainer references
echo "Removing DependencyContainer..."
rm -f AirFit/Core/Utilities/DependencyContainer.swift

# Update imports
find AirFit -name "*.swift" -type f -exec sed -i '' '/import.*DependencyContainer/d' {} +

# Remove force casts
echo "Checking for remaining force casts..."
if grep -r "as!" --include="*.swift" AirFit/ | grep -v "AirFitTests"; then
    echo "WARNING: Force casts still present!"
    exit 1
fi

# Check for mock usage in production
echo "Checking for mocks in production..."
if grep -r "Mock[A-Z]" --include="*.swift" AirFit/ | grep -v "AirFitTests" | grep -v "Preview"; then
    echo "WARNING: Mocks found in production code!"
    exit 1
fi

# Run SwiftLint
echo "Running SwiftLint..."
swiftlint --strict

# Generate Xcode project
echo "Regenerating Xcode project..."
xcodegen generate

echo "=== Cleanup Complete ==="
```

## Verification Checklist

- [ ] DependencyContainer completely removed
- [ ] All services use ServiceRegistry
- [ ] Service initialization order validated
- [ ] No race conditions in service startup
- [ ] All services converted from @MainActor to actor
- [ ] Health monitoring implemented
- [ ] Performance metrics tracked
- [ ] No force casts remaining
- [ ] No mocks in production code

## Testing Commands

```bash
# Full test suite
swift test

# Service integration tests
swift test --filter ServiceIntegrationTests

# Performance tests
swift test --filter PerformanceTests

# Validate dependencies
./Scripts/validate_dependencies.sh

# Final cleanup
./Scripts/final_cleanup.sh
```

## Migration Completion

After completing all phases:

1. **Update CLAUDE.md** with new architecture
2. **Create Architecture Decision Records (ADRs)**
3. **Update onboarding documentation**
4. **Schedule team knowledge transfer session**
5. **Set up monitoring dashboards**

## Success Metrics

- App launch time: < 1.5 seconds
- Service initialization: < 500ms per service
- Memory usage: < 150MB baseline
- Zero force cast crashes
- 100% service health check coverage
- Clean architecture with no violations