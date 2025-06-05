# Phase 4: Foundation & Production Readiness ✅ COMPLETE

## Overview
Phase 4 focused on file naming standardization. Phase 5 is now the DI implementation phase.

## Completed Work
- ✅ 26 file naming violations addressed
- ✅ 24 files renamed to follow consistent patterns
- ✅ 14 new mock files created from 3 plural files
- ✅ 1 unified protocol from 2 duplicates
- ✅ All imports updated throughout codebase
- ✅ Build successful with consistent naming

See CLEANUP_TRACKER.md for Phase 5 DI implementation details.

## Task 1: Fix Test Infrastructure First (2 days)

### 1.1: Update Broken Test References
**Critical**: Many tests won't compile due to deleted services

```bash
# Find all broken test references
grep -r "EnhancedAIAPIService\|AIAPIServiceProtocol\|MockAIService" AirFit/AirFitTests/

# Files needing updates:
# - ServicePerformanceTests.swift
# - MockAIAPIService.swift  
# - Various integration tests
```

### 1.2: Create Test Service Registry
```swift
// In AirFitTests/TestHelpers/TestServiceRegistry.swift
class TestServiceRegistry {
    static func createForTesting() -> ServiceRegistry {
        let registry = ServiceRegistry()
        
        // Register all test mocks
        registry.register(MockAIService(), for: AIServiceProtocol.self)
        registry.register(MockUserService(), for: UserServiceProtocol.self)
        registry.register(MockHealthKitManager(), for: HealthKitManagerProtocol.self)
        // ... etc
        
        return registry
    }
}
```

### 1.3: Fix Mock Implementations
Update all mocks to use current protocols:
```swift
// Update MockAIAPIService.swift
final class MockAIService: AIServiceProtocol { // Not AIAPIServiceProtocol
    // Implement current protocol methods
}
```

## Task 2: Implement Proper DI System (3 days)

### 2.1: Enhance DependencyContainer
Current `register()` method just logs. Make it functional:

```swift
@MainActor
final class DependencyContainer: ObservableObject {
    private let registry = ServiceRegistry.shared
    
    // Keep existing properties for SwiftUI compatibility
    @Published private(set) var modelContainer: ModelContainer?
    @Published private(set) var networkClient: NetworkClient?
    // ...
    
    func configure() async {
        do {
            // Phase 1: Core infrastructure
            let modelContainer = try createModelContainer()
            self.modelContainer = modelContainer
            registry.register(modelContainer, for: ModelContainer.self)
            
            // Phase 2: Network & Security
            let networkClient = NetworkClient()
            self.networkClient = networkClient
            registry.register(networkClient, for: NetworkClientProtocol.self)
            
            let keychain = KeychainHelper()
            registry.register(keychain, for: KeychainHelper.self)
            
            let apiKeyManager = DefaultAPIKeyManager(keychain: keychain)
            registry.register(apiKeyManager, for: APIKeyManagerProtocol.self)
            
            // Phase 3: Services (in dependency order)
            await configureServices(
                modelContainer: modelContainer,
                networkClient: networkClient,
                apiKeyManager: apiKeyManager
            )
            
            // Phase 4: Verify health
            let unhealthy = await registry.checkHealth()
                .filter { $0.value.status == .unhealthy }
            
            if !unhealthy.isEmpty {
                AppLogger.warning("Unhealthy services at startup: \(unhealthy.keys)")
            }
            
        } catch {
            AppLogger.error("Failed to configure services: \(error)")
            // Use offline/degraded mode
            await configureOfflineMode()
        }
    }
    
    private func configureServices(
        modelContainer: ModelContainer,
        networkClient: NetworkClientProtocol,
        apiKeyManager: APIKeyManagerProtocol
    ) async {
        // Configure in dependency order
        
        // 1. Data layer
        let dataManager = DataManager(modelContainer: modelContainer)
        registry.register(dataManager, for: DataManager.self)
        
        // 2. Health services
        let healthKitManager = HealthKitManager()
        try? await healthKitManager.configure()
        registry.register(healthKitManager, for: HealthKitManagerProtocol.self)
        
        // 3. AI services
        if let aiService = try? await createAIService(apiKeyManager: apiKeyManager) {
            registry.register(aiService, for: AIServiceProtocol.self)
        } else {
            registry.register(OfflineAIService(), for: AIServiceProtocol.self)
        }
        
        // 4. Feature services
        let userService = DefaultUserService(dataManager: dataManager)
        registry.register(userService, for: UserServiceProtocol.self)
        
        let workoutService = DefaultWorkoutService(dataManager: dataManager)
        registry.register(workoutService, for: WorkoutServiceProtocol.self)
        
        // 5. Weather (use native WeatherKit)
        let weatherService = WeatherKitService()
        try? await weatherService.configure()
        registry.register(weatherService, for: WeatherServiceProtocol.self)
    }
}
```

### 2.2: Migrate from Singleton Services
Convert singleton services to proper DI:

```swift
// BEFORE (in various files)
let result = await NetworkManager.shared.request(...)

// AFTER
@Injected var networkManager: NetworkManagerProtocol
let result = await networkManager.request(...)
```

Services to migrate:
1. NetworkManager
2. ExerciseDatabase  
3. WhisperModelManager
4. WorkoutSyncService
5. Others identified in Phase 2

### 2.3: Create Service Locator Pattern
For services that can't use @Injected:

```swift
extension ServiceRegistry {
    // Type-safe service resolution
    static func resolve<T>(_ type: T.Type) -> T? {
        return shared.resolve(type)
    }
    
    // Convenience accessors
    static var aiService: AIServiceProtocol? {
        resolve(AIServiceProtocol.self)
    }
    
    static var userService: UserServiceProtocol? {
        resolve(UserServiceProtocol.self)
    }
}
```

## Task 3: Leverage Existing ProductionMonitor (1 day)

### 3.1: Extend Monitoring
ProductionMonitor is already excellent. Just add cleanup-specific metrics:

```swift
extension ProductionMonitor {
    // Monitor refactoring impact
    func trackCleanupMetrics() async {
        // Track @Observable performance
        await trackMetric(
            category: .performance,
            name: "observable_update_frequency",
            value: getObservableUpdateRate()
        )
        
        // Track offline AI usage
        await trackMetric(
            category: .feature,
            name: "offline_ai_requests",
            value: getOfflineAIUsageCount()
        )
        
        // Track DI resolution time
        await trackMetric(
            category: .performance,
            name: "di_resolution_time",
            value: measureDIResolutionTime()
        )
    }
    
    // Alert on issues
    func checkRefactoringHealth() async {
        let metrics = await getCurrentMetrics()
        
        // Alert if performance degraded
        if let launchTime = metrics["app_launch_time"],
           launchTime > 1500 { // ms
            await createAlert(
                level: .warning,
                message: "App launch time degraded after refactoring",
                metadata: ["time": launchTime]
            )
        }
    }
}
```

### 3.2: Add Telemetry Dashboard
```swift
struct TelemetryDashboard: View {
    @StateObject private var monitor = ProductionMonitor.shared
    
    var body: some View {
        List {
            Section("Performance") {
                MetricRow("Launch Time", monitor.metrics.launchTime)
                MetricRow("Memory Usage", monitor.metrics.memoryUsage)
                MetricRow("Persona Generation", monitor.metrics.personaGenTime)
            }
            
            Section("Refactoring Impact") {
                MetricRow("Force Cast Attempts", monitor.metrics.forceCastAttempts)
                MetricRow("DI Resolution Time", monitor.metrics.diResolutionTime)
                MetricRow("Offline AI Usage", monitor.metrics.offlineAIUsage)
            }
        }
    }
}
```

## Task 4: Implement Rollback Support (2 days)

### 4.1: Service Version Tracking
```swift
protocol VersionedService: ServiceProtocol {
    var version: String { get }
    var previousVersion: String? { get }
    
    func rollback() async throws
}

// Example implementation
actor VersionedAIService: AIServiceProtocol, VersionedService {
    let version = "2.0" // Post-refactoring
    let previousVersion = "1.0"
    
    private var useNewImplementation = true
    
    func rollback() async throws {
        useNewImplementation = false
        AppLogger.info("Rolled back AI service to v1.0")
    }
}
```

### 4.2: Feature Flags
```swift
@MainActor
final class FeatureFlags: ObservableObject {
    @Published var useObservablePattern = true
    @Published var useNewDISystem = true
    @Published var useWeatherKit = true
    
    func rollbackToLegacy() {
        useObservablePattern = false
        useNewDISystem = false
        useWeatherKit = false
        
        AppLogger.warning("Rolled back to legacy implementations")
    }
}
```

### 4.3: State Snapshots
```swift
extension DependencyContainer {
    func createSnapshot() -> DependencySnapshot {
        DependencySnapshot(
            timestamp: Date(),
            services: registry.getAllServices(),
            health: registry.getHealthStatuses()
        )
    }
    
    func restoreSnapshot(_ snapshot: DependencySnapshot) async throws {
        // Restore service configuration
        for (type, service) in snapshot.services {
            registry.register(service, for: type)
        }
    }
}
```

## Task 5: Production Hardening (2 days)

### 5.1: Graceful Degradation
```swift
extension DependencyContainer {
    func configureOfflineMode() async {
        AppLogger.warning("Configuring offline/degraded mode")
        
        // Register offline alternatives
        registry.register(OfflineAIService(), for: AIServiceProtocol.self)
        registry.register(CachedWeatherService(), for: WeatherServiceProtocol.self)
        registry.register(LocalWorkoutService(), for: WorkoutServiceProtocol.self)
        
        // Notify user
        await NotificationManager.shared.notify(
            title: "Limited Mode",
            body: "Some features are unavailable. Working offline."
        )
    }
}
```

### 5.2: Performance Validation
```swift
class RefactoringPerformanceTests: XCTestCase {
    func testCriticalMetrics() async {
        // App launch
        let launchTime = await measureAppLaunch()
        XCTAssertLessThan(launchTime, 1.5) // seconds
        
        // Persona generation
        let personaTime = await measurePersonaGeneration()
        XCTAssertLessThan(personaTime, 3.0) // seconds
        
        // Memory after ObservableObject migration
        let memory = await measureMemoryUsage()
        XCTAssertLessThan(memory, 150) // MB
        
        // DI resolution overhead
        let diTime = await measureDIResolution()
        XCTAssertLessThan(diTime, 0.1) // seconds
    }
}
```

### 5.3: Documentation
Create comprehensive guides:
- How the new DI system works
- Rollback procedures
- Performance monitoring setup
- Troubleshooting guide

## Time Estimate: 10 days

### Breakdown:
- Fix test infrastructure: 2 days
- Implement proper DI: 3 days
- Monitoring setup: 1 day
- Rollback support: 2 days
- Production hardening: 2 days

This is realistic given we're building foundations, not just polishing.

## Success Criteria
- [ ] All tests compile and pass
- [ ] Services properly registered in DI container
- [ ] No singleton services remain
- [ ] Monitoring captures refactoring metrics
- [ ] Rollback procedures tested and documented
- [ ] Performance targets still met
- [ ] Graceful degradation works

## Risk Mitigation
1. **Fix tests first** - Can't refactor safely without tests
2. **Incremental DI migration** - Don't break everything at once
3. **Use feature flags** - Can disable new systems if issues arise
4. **Monitor continuously** - ProductionMonitor will alert on issues
5. **Document everything** - Future developers need to understand the system

## Next Steps After Phase 4
1. Deploy to TestFlight with monitoring
2. Collect metrics for 1-2 weeks
3. Address any performance regressions
4. Remove feature flags once stable
5. Plan next feature development

## Note
This phase is significantly different from the original plan because validation revealed:
- DI system needs to be built, not polished
- Test infrastructure is broken
- ProductionMonitor is already excellent
- Need rollback capabilities

This revised plan addresses the actual state of the codebase.