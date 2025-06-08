# Dependency Injection Standards for AirFit

**Last Updated**: 2025-01-08  
**Status**: Active  
**Priority**: 🚨 Critical - Addresses black screen initialization issue

## Table of Contents
1. [Overview](#overview)
2. [Core Principles](#core-principles)
3. [Registration Patterns](#registration-patterns)
4. [Resolution Patterns](#resolution-patterns)
5. [Service Lifecycle](#service-lifecycle)
6. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
7. [Testing DI](#testing-di)
8. [Migration Guide](#migration-guide)

## Overview

This document defines dependency injection patterns to prevent initialization failures, circular dependencies, and the black screen issue. These patterns ensure predictable, fast app startup.

## Core Principles

1. **Async-first** - All resolution must be async, no blocking
2. **No singletons** - Inject dependencies, don't use shared instances
3. **Explicit dependencies** - No service locator pattern
4. **Fail fast** - Clear errors for missing dependencies
5. **Testable** - Easy to mock and test

## Registration Patterns

### ✅ Service Registration
```swift
// In DIBootstrapper.swift
static func registerServices(in container: DIContainer) async {
    // 1. Register protocols to implementations
    container.register(UserServiceProtocol.self) { resolver in
        await UserService(
            api: try await resolver.resolve(APIClientProtocol.self),
            cache: try await resolver.resolve(CacheProtocol.self)
        )
    }
    
    // 2. Register with lifecycle
    container.register(HealthKitManagerProtocol.self, lifecycle: .singleton) { resolver in
        await HealthKitManager()
    }
    
    // 3. Register factories for repeated creation
    container.registerFactory(WorkoutBuilderProtocol.self) { resolver in
        WorkoutBuilder(
            healthKit: try await resolver.resolve(HealthKitManagerProtocol.self)
        )
    }
}
```

### ✅ Module Registration
```swift
// Organize by feature module
extension DIBootstrapper {
    static func registerDashboardModule(in container: DIContainer) async {
        // Services
        container.register(DashboardServiceProtocol.self) { resolver in
            await DashboardService(
                healthKit: try await resolver.resolve(HealthKitManagerProtocol.self),
                ai: try await resolver.resolve(AIServiceProtocol.self)
            )
        }
        
        // ViewModels
        container.register(DashboardViewModel.self) { resolver in
            await DashboardViewModel(
                service: try await resolver.resolve(DashboardServiceProtocol.self)
            )
        }
    }
}
```

### ❌ Avoid Circular Dependencies
```swift
// ❌ BAD: Circular dependency
container.register(ServiceA.self) { resolver in
    ServiceA(b: try await resolver.resolve(ServiceB.self))
}
container.register(ServiceB.self) { resolver in
    ServiceB(a: try await resolver.resolve(ServiceA.self))  // CIRCULAR!
}

// ✅ GOOD: Break with protocol or redesign
protocol ServiceAProtocol {
    func doWork() async
}

container.register(ServiceAProtocol.self) { _ in
    ServiceA()  // No dependency on B
}
container.register(ServiceB.self) { resolver in
    ServiceB(a: try await resolver.resolve(ServiceAProtocol.self))
}
```

## Resolution Patterns

### ✅ Async Resolution
```swift
// In AppState or Root View
@MainActor
final class AppState: ObservableObject {
    @Published var isInitialized = false
    @Published var initError: Error?
    
    private let container: DIContainer
    
    init(container: DIContainer) {
        self.container = container
    }
    
    func initialize() async {
        do {
            // Resolve core services
            let userService = try await container.resolve(UserServiceProtocol.self)
            let healthKit = try await container.resolve(HealthKitManagerProtocol.self)
            
            // Initialize in correct order
            try await userService.initialize()
            try await healthKit.requestAuthorization()
            
            isInitialized = true
        } catch {
            initError = error
        }
    }
}
```

### ✅ View Model Creation
```swift
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    
    init(container: DIContainer) {
        // Create view model synchronously with async internals
        _viewModel = StateObject(wrappedValue: DashboardViewModel(container: container))
    }
    
    var body: some View {
        // View implementation
    }
}

// ViewModel handles async resolution
@MainActor
final class DashboardViewModel: ObservableObject {
    private let container: DIContainer
    private var service: DashboardServiceProtocol?
    
    init(container: DIContainer) {
        self.container = container
    }
    
    func onAppear() async {
        service = try? await container.resolve(DashboardServiceProtocol.self)
        await loadData()
    }
}
```

### ❌ NEVER Use Synchronous Resolution
```swift
// ❌ NEVER DO THIS - Causes black screen!
class DIContainer {
    func resolveSync<T>(_ type: T.Type) -> T {
        let semaphore = DispatchSemaphore(value: 0)
        var result: T?
        
        Task {
            result = try await resolve(type)
            semaphore.signal()
        }
        
        semaphore.wait(timeout: .now() + 5)  // BLOCKS MAIN THREAD!
        return result!  // FORCE UNWRAP!
    }
}
```

## Service Lifecycle

### Singleton Services (Shared State)
```swift
// For services that maintain state across app lifetime
container.register(UserSessionProtocol.self, lifecycle: .singleton) { _ in
    await UserSession()
}

// Singleton services should be actors for thread safety
actor UserSession: UserSessionProtocol {
    private var currentUser: User?
    
    func setUser(_ user: User) {
        self.currentUser = user
    }
}
```

### Transient Services (Fresh Instance)
```swift
// Default - new instance each time
container.register(NetworkRequestProtocol.self) { resolver in
    NetworkRequest(
        client: try await resolver.resolve(NetworkClientProtocol.self)
    )
}
```

### Factory Pattern (Parameterized Creation)
```swift
// For services that need runtime parameters
container.registerFactory(WorkoutBuilderProtocol.self) { resolver in
    { (type: WorkoutType) in
        WorkoutBuilder(
            type: type,
            healthKit: try await resolver.resolve(HealthKitManagerProtocol.self)
        )
    }
}

// Usage
let factory = try await container.resolve((WorkoutType) -> WorkoutBuilderProtocol).self)
let builder = factory(.strength)
```

## Anti-Patterns to Avoid

### ❌ Service Locator Pattern
```swift
// ❌ BAD: Hidden dependencies
class MyService {
    func doWork() async {
        let api = try! await DIContainer.shared.resolve(APIClient.self)  // Hidden!
    }
}

// ✅ GOOD: Explicit dependencies
class MyService {
    private let api: APIClientProtocol
    
    init(api: APIClientProtocol) {
        self.api = api
    }
}
```

### ❌ God Container
```swift
// ❌ BAD: Everything in one container
let container = DIContainer()
container.register(Everything.self) { ... }
// 200+ registrations in one place

// ✅ GOOD: Module-based registration
DIBootstrapper.registerCore(in: container)
DIBootstrapper.registerDashboard(in: container)
DIBootstrapper.registerWorkouts(in: container)
```

### ❌ Initialization in Registration
```swift
// ❌ BAD: Side effects during registration
container.register(Service.self) { _ in
    let service = Service()
    service.startBackgroundWork()  // Side effect!
    return service
}

// ✅ GOOD: Separate initialization
container.register(Service.self) { _ in
    Service()
}

// Initialize explicitly
let service = try await container.resolve(Service.self)
await service.initialize()
```

## Testing DI

### Test Container Setup
```swift
@MainActor
class MyViewModelTests: XCTestCase {
    var container: DIContainer!
    var sut: MyViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test container
        container = DIContainer()
        
        // Register mocks
        container.register(UserServiceProtocol.self) { _ in
            MockUserService()
        }
        
        // Create system under test
        sut = try await container.resolve(MyViewModel.self)
    }
}
```

### Testing Registration
```swift
func testServiceRegistration() async throws {
    // Verify service can be resolved
    let service = try await container.resolve(UserServiceProtocol.self)
    XCTAssertNotNil(service)
    
    // Verify correct implementation
    XCTAssertTrue(service is UserService)
}
```

### Testing Missing Dependencies
```swift
func testMissingDependency() async {
    let container = DIContainer()  // Empty
    
    do {
        _ = try await container.resolve(UserServiceProtocol.self)
        XCTFail("Should throw error for missing dependency")
    } catch DIError.notRegistered {
        // Expected
    }
}
```

## Migration Guide

### From Singleton to DI
```swift
// ❌ OLD: Singleton pattern
class UserManager {
    static let shared = UserManager()
    private init() {}
}

// Usage
UserManager.shared.updateUser(user)

// ✅ NEW: Dependency injection
protocol UserManagerProtocol {
    func updateUser(_ user: User) async throws
}

actor UserManager: UserManagerProtocol {
    func updateUser(_ user: User) async throws {
        // Implementation
    }
}

// Registration
container.register(UserManagerProtocol.self, lifecycle: .singleton) { _ in
    await UserManager()
}

// Usage
class ProfileViewModel {
    private let userManager: UserManagerProtocol
    
    init(userManager: UserManagerProtocol) {
        self.userManager = userManager
    }
}
```

### From Sync to Async Resolution
```swift
// ❌ OLD: Synchronous resolution
let service = container.resolve(Service.self)!

// ✅ NEW: Async resolution
let service = try await container.resolve(Service.self)
```

## Best Practices Checklist

### Registration Phase
- [ ] Register protocol to implementation, not concrete types
- [ ] Use lifecycle parameter for stateful services
- [ ] Group registrations by module
- [ ] No side effects in registration closures
- [ ] Document complex dependencies

### Resolution Phase
- [ ] Always use async resolution
- [ ] Handle resolution errors
- [ ] Resolve at appropriate lifecycle points
- [ ] Don't resolve in tight loops
- [ ] Cache resolved services when appropriate

### Testing
- [ ] Create fresh container for each test
- [ ] Register all required mocks
- [ ] Test missing dependency scenarios
- [ ] Verify correct implementations
- [ ] Test lifecycle behavior

## Common Patterns

### Conditional Registration
```swift
#if DEBUG
container.register(AIServiceProtocol.self) { _ in
    MockAIService()  // Use mock in debug
}
#else
container.register(AIServiceProtocol.self) { _ in
    await AIService()  // Real service in release
}
#endif
```

### Optional Dependencies
```swift
class MyService {
    private let cache: CacheProtocol?
    
    init(cache: CacheProtocol? = nil) {
        self.cache = cache
    }
    
    func getData() async -> Data {
        if let cached = await cache?.get("key") {
            return cached
        }
        return await fetchFreshData()
    }
}
```

### Multi-Implementation
```swift
// Register multiple implementations
container.register(PaymentProcessor.self, tag: "stripe") { _ in
    StripeProcessor()
}
container.register(PaymentProcessor.self, tag: "apple") { _ in
    ApplePayProcessor()
}

// Resolve specific implementation
let processor = try await container.resolve(PaymentProcessor.self, tag: "stripe")
```

## References

- Research Report: `DI_System_Complete_Analysis.md`
- Recovery Plan: `CODEBASE_RECOVERY_PLAN.md`
- Related: `CONCURRENCY_STANDARDS.md`