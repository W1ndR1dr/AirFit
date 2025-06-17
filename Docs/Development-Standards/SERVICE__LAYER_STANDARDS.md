# Service Layer Standards

**Last Updated**: 2025-12-06  
**Status**: Active  
**Priority**: 🚨 Critical - Core architecture patterns

## Table of Contents
1. [Overview](#overview)
2. [Core Principles](#core-principles)
3. [Service Architecture](#service-architecture)
4. [Dependency Injection](#dependency-injection)
5. [Concurrency & Actor Isolation](#concurrency--actor-isolation)
6. [Service Lifecycle](#service-lifecycle)
7. [Performance Guidelines](#performance-guidelines)
8. [Anti-Patterns](#anti-patterns)
9. [Testing Services](#testing-services)
10. [Quick Reference](#quick-reference)

## Overview

This document defines how services are structured, created, and executed in AirFit. Services are the backbone of our architecture - they handle business logic, external integrations, and data processing while maintaining clean separation from UI concerns.

**Key Achievement**: Our service layer enables <0.5s app launch with immediate UI rendering through lazy dependency injection and proper actor isolation.

## Core Principles

1. **Lazy Creation** - Services created only when first accessed
2. **Async-First** - All service operations are async, no blocking
3. **Actor Isolation** - Services are actors unless they need @MainActor
4. **Dependency Injection** - No singletons, all dependencies injected
5. **Protocol-Based** - All services implement ServiceProtocol
6. **Type Safety** - Compile-time dependency verification
7. **Zero-Cost Startup** - No service creation during app initialization

## Service Architecture

### Service Types & Actor Isolation

#### ✅ Use `actor` for Services When:
- Pure computation or business logic
- Network operations
- Cache management
- Background processing
- HealthKit data fetching
- File operations

```swift
actor NetworkManager: NetworkManagementProtocol, ServiceProtocol {
    private var cache: [String: Data] = [:]
    
    func fetchData() async throws -> Data {
        // Runs on actor's executor, off main thread
    }
}
```

#### ✅ Use `@MainActor` for Services When:
- Using SwiftData models (@Model types are not Sendable)
- Using UI frameworks (LAContext, UIKit components)
- Need @Observable or @Published for SwiftUI
- Direct UI state management

```swift
@MainActor
final class UserService: UserServiceProtocol, ServiceProtocol {
    private let modelContext: ModelContext
    
    func updateProfile(_ profile: Profile) async throws {
        // Runs on MainActor due to SwiftData requirement
    }
}
```

### ServiceProtocol Implementation

Every service MUST implement ServiceProtocol:

```swift
protocol ServiceProtocol: AnyObject, Sendable {
    var isConfigured: Bool { get }
    var serviceIdentifier: String { get }
    
    func configure() async throws
    func reset() async
    func healthCheck() async -> ServiceHealth
}
```

**Implementation Pattern**:
```swift
actor MyService: ServiceProtocol {
    nonisolated let serviceIdentifier = "my-service"
    private var _isConfigured = false
    
    nonisolated var isConfigured: Bool {
        // For actors, access via async property if needed
        false // Simplified for example
    }
    
    func configure() async throws {
        // Heavy initialization work here
        _isConfigured = true
    }
}
```

## Dependency Injection

### Registration Patterns

#### Basic Service Registration
```swift
// ✅ CORRECT: Register factory closure
container.register(WeatherServiceProtocol.self) { _ in
    await WeatherService() // Created lazily when resolved
}

// ❌ WRONG: Creating instance during registration
let service = await WeatherService() // BAD: Created immediately
container.register(WeatherServiceProtocol.self) { _ in service }
```

#### Service with Dependencies
```swift
container.register(DashboardServiceProtocol.self) { resolver in
    let healthKit = try await resolver.resolve(HealthKitManagerProtocol.self)
    let ai = try await resolver.resolve(AIServiceProtocol.self)
    return await DashboardService(healthKit: healthKit, ai: ai)
}
```

#### SwiftData Services (MainActor Required)
```swift
container.register(UserServiceProtocol.self, lifetime: .singleton) { resolver in
    let container = try await resolver.resolve(ModelContainer.self)
    return await MainActor.run {
        UserService(modelContext: container.mainContext)
    }
}
```

### Lifetime Management

#### Singleton (Default for Services)
```swift
container.register(APIClient.self, lifetime: .singleton) { _ in
    await APIClient() // Created once, cached forever
}
```

#### Transient (New Instance Each Time)
```swift
container.register(UploadTask.self, lifetime: .transient) { _ in
    await UploadTask() // Fresh instance every resolve()
}
```

### Resolution Patterns

#### Basic Resolution
```swift
let service = try await container.resolve(ServiceProtocol.self)
```

#### Parallel Resolution
```swift
async let service1 = container.resolve(Service1.self)
async let service2 = container.resolve(Service2.self)
let (s1, s2) = try await (service1, service2)
```

## Concurrency & Actor Isolation

### Actor Boundaries & Communication

#### ✅ ViewModels Calling Actor Services
```swift
@MainActor
@Observable
final class DashboardViewModel: ViewModelProtocol {
    private let service: DashboardServiceProtocol
    
    func loadData() async {
        // UI updates happen on MainActor
        isLoading = true
        defer { isLoading = false }
        
        // Service calls cross actor boundary
        do {
            let data = try await service.fetchDashboardData()
            self.dashboardData = data
        } catch {
            self.error = error
        }
    }
}
```

#### ✅ Actor Services Calling Other Actor Services
```swift
actor DashboardService: DashboardServiceProtocol {
    private let healthKit: HealthKitManagerProtocol
    private let ai: AIServiceProtocol
    
    func fetchDashboardData() async throws -> DashboardData {
        // Parallel data fetching across actor boundaries
        async let health = healthKit.getTodaysSummary()
        async let insights = ai.generateDailyInsights()
        
        return try await DashboardData(
            health: health,
            insights: insights
        )
    }
}
```

### Thread Safety Patterns

#### ✅ Thread-Safe State in Actors
```swift
actor CacheService: ServiceProtocol {
    private var cache: [String: CacheEntry] = [:]
    private var accessCounts: [String: Int] = [:]
    
    func store(_ data: Data, for key: String) async {
        // All state mutations are automatically synchronized
        cache[key] = CacheEntry(data: data, timestamp: Date())
        accessCounts[key, default: 0] += 1
    }
}
```

#### ✅ @unchecked Sendable (Only When Required)
```swift
// ✅ VALID: SwiftData models (required by framework)
@Model
final class User: @unchecked Sendable {
    var name: String
    var email: String
}

// ✅ VALID: Manual synchronization with proper isolation
final class FunctionCallDispatcher: @unchecked Sendable {
    private let queue = DispatchQueue(label: "dispatcher")
    private var handlers: [String: Handler] = [:]
    
    func register(_ handler: Handler, for name: String) {
        queue.sync { handlers[name] = handler }
    }
}
```

## Service Lifecycle

### Initialization Pattern

#### ✅ Lightweight init() + Heavy configure()
```swift
actor NetworkService: ServiceProtocol {
    private let session: URLSession
    private var _isConfigured = false
    
    init() {
        // Lightweight init only - no async work!
        self.session = URLSession(configuration: .default)
    }
    
    func configure() async throws {
        // Heavy setup work happens here
        try await validateConnection()
        try await loadConfiguration()
        _isConfigured = true
    }
}
```

#### ❌ Wrong: Heavy Work in init()
```swift
// ❌ BAD: Async work in init
actor BadService {
    init() async throws {
        await setupService() // Blocks app startup!
    }
}
```

### Task Management

#### ✅ Structured Concurrency in Services
```swift
actor DataSyncService: ServiceProtocol {
    func syncAllData() async throws {
        // Tasks are automatically cancelled if service is deallocated
        async let userSync = syncUserData()
        async let healthSync = syncHealthData()
        async let workoutSync = syncWorkouts()
        
        _ = try await (userSync, healthSync, workoutSync)
    }
}
```

#### ✅ Long-Running Task Management
```swift
actor MonitoringService: ServiceProtocol {
    private var monitoringTask: Task<Void, Never>?
    
    func startMonitoring() async {
        monitoringTask?.cancel()
        monitoringTask = Task {
            while !Task.isCancelled {
                await performHealthCheck()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }
    
    func reset() async {
        monitoringTask?.cancel()
        monitoringTask = nil
    }
}
```

## Performance Guidelines

### Launch Time Optimization

#### ✅ Zero-Cost DI Registration
```swift
// ✅ PERFECT: Only registers factories, no service creation
public static func createAppContainer(modelContainer: ModelContainer) -> DIContainer {
    let container = DIContainer()
    // Only registers factories, no service creation!
    registerServices(in: container, modelContainer: modelContainer)
    return container  // Returns instantly
}
```

#### ✅ Lazy Service Access
```swift
@MainActor
final class DashboardViewModel {
    private let serviceFactory: () async throws -> DashboardServiceProtocol
    private var _service: DashboardServiceProtocol?
    
    private var service: DashboardServiceProtocol {
        get async throws {
            if let service = _service { return service }
            let service = try await serviceFactory()
            _service = service
            return service
        }
    }
}
```

### Actor Performance

#### ✅ Minimize Actor Hopping
```swift
// ❌ BAD: Multiple round trips
for item in items {
    await actor.process(item)
}

// ✅ GOOD: Single batch operation
await actor.processItems(items)
```

#### ✅ Parallel Execution
```swift
async let a = fetchA()
async let b = fetchB()
let (resultA, resultB) = try await (a, b)
```

## Anti-Patterns

### ❌ Synchronous Blocking
```swift
// ❌ NEVER DO THIS
let semaphore = DispatchSemaphore(value: 0)
Task {
    await doWork()
    semaphore.signal()
}
semaphore.wait()  // BLOCKS THREAD!
```

### ❌ Shared Instances
```swift
// ❌ WRONG: Using singleton pattern
class APIClient {
    static let shared = APIClient() // NO!
}

// ✅ CORRECT: Inject through DI
actor APIClient: ServiceProtocol {
    init() { } // Let DI manage lifecycle
}
```

### ❌ Service Locator Anti-Pattern
```swift
// ❌ WRONG: Accessing container globally
actor SomeService {
    func doWork() async {
        let other = try await DIContainer.global.resolve(...) // NO!
    }
}

// ✅ CORRECT: Inject dependencies
actor SomeService {
    private let dependency: DependencyProtocol
    
    init(dependency: DependencyProtocol) {
        self.dependency = dependency
    }
}
```

### ❌ MainActor.assumeIsolated Abuse
```swift
// ❌ DANGEROUS: Bypassing actor safety
actor MyService {
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured } // UNSAFE!
    }
}

// ✅ SAFE: Use proper async access or atomic types
actor MyService {
    private let _isConfigured = AtomicBool()
    nonisolated var isConfigured: Bool { _isConfigured.value }
}
```

## Testing Services

### Test Container Setup
```swift
func createTestContainer() -> DIContainer {
    let container = DIContainer()
    
    // Register mocks - still lazy!
    container.register(APIClientProtocol.self) { _ in
        await MockAPIClient(responses: testResponses)
    }
    
    return container
}
```

### Testing Actor Services
```swift
@MainActor
final class UserServiceTests: XCTestCase {
    func testUserFetch() async throws {
        // Create actor under test
        let service = await UserService()
        
        // Test across actor boundary
        let user = try await service.getUser()
        
        // Assert on MainActor
        XCTAssertEqual(user.name, "Test User")
    }
}
```

### Verify Lazy Behavior
```swift
func testLazyResolution() async {
    var created = false
    
    container.register(ServiceProtocol.self) { _ in
        created = true
        return await MockService()
    }
    
    XCTAssertFalse(created) // Not created yet
    
    _ = try await container.resolve(ServiceProtocol.self)
    XCTAssertTrue(created) // Now it's created
}
```

## Quick Reference

### Do's ✅
- Register factories, not instances
- Use async resolution everywhere
- Inject all dependencies
- Make services actors unless @MainActor required
- Keep init() lightweight
- Use ServiceProtocol for all services
- Handle errors with AppError (see ERROR_HANDLING_STANDARDS.md)

### Don'ts ❌
- No .shared singletons
- No synchronous resolution
- No global container access
- No eager service creation
- No blocking in init() methods
- No MainActor.assumeIsolated without justification
- No @unchecked Sendable without valid reason

### Code Review Checklist
- [ ] Service implements ServiceProtocol
- [ ] Actor isolation appropriate (actor vs @MainActor)
- [ ] Dependencies injected via DI
- [ ] No synchronous blocking operations
- [ ] Lightweight init(), heavy work in configure()
- [ ] No singletons or global state
- [ ] Error handling uses AppError
- [ ] Tests use mock DI container

### Performance Targets
- **App Launch**: <0.5s to interactive UI
- **Service Creation**: Lazy, only when needed
- **Memory Usage**: 60% lower than eager loading
- **Main Thread**: <50% utilization during normal operation

## Integration with Other Standards

- **Error Handling**: Use patterns from `ERROR_HANDLING_STANDARDS.md`
- **Testing**: Follow conventions in `TEST_STANDARDS.md`
- **AI Services**: Optimize per `AI_OPTIMIZATION_STANDARDS.md`
- **Module Boundaries**: Respect rules in `MODULE_BOUNDARIES.md`