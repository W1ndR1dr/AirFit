# Concurrency Standards for AirFit

**Last Updated**: 2025-01-08  
**Status**: Active  
**Priority**: 🚨 Critical - Addresses black screen and performance issues

## Table of Contents
1. [Overview](#overview)
2. [Core Principles](#core-principles)
3. [Actor Isolation Patterns](#actor-isolation-patterns)
4. [MainActor Usage Guidelines](#mainactor-usage-guidelines)
5. [Task Management](#task-management)
6. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
7. [Migration Patterns](#migration-patterns)
8. [Testing Concurrency](#testing-concurrency)

## Overview

This document defines concurrency patterns for the AirFit codebase to prevent performance issues, race conditions, and the black screen initialization problem. Following these standards is mandatory for all new code and should guide refactoring efforts.

## Core Principles

1. **Minimize @MainActor usage** - Only UI components need @MainActor
2. **Use actors for services** - Services should be actors, not @MainActor classes
3. **Structured concurrency** - Prefer async/await over unstructured Tasks
4. **No blocking operations** - Never block threads, especially the main thread
5. **Clear isolation boundaries** - Each component should have clear actor isolation

## Actor Isolation Patterns

### ✅ ViewModels (UI Layer)
```swift
@MainActor
@Observable
final class DashboardViewModel: ViewModelProtocol {
    private let service: DashboardServiceProtocol
    
    init(service: DashboardServiceProtocol) {
        self.service = service
    }
    
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

### ✅ Services (Business Logic Layer)
```swift
actor DashboardService: DashboardServiceProtocol {
    private let healthKit: HealthKitManagerProtocol
    private let ai: AIServiceProtocol
    
    init(healthKit: HealthKitManagerProtocol, ai: AIServiceProtocol) async {
        self.healthKit = healthKit
        self.ai = ai
        await initialize()
    }
    
    func fetchDashboardData() async throws -> DashboardData {
        // Parallel data fetching
        async let health = healthKit.getTodaysSummary()
        async let insights = ai.generateDailyInsights()
        
        return try await DashboardData(
            health: health,
            insights: insights
        )
    }
}
```

### ✅ Managers (System Integration Layer)
```swift
actor HealthKitManager: HealthKitManagerProtocol {
    private let store = HKHealthStore()
    
    // Actors provide natural synchronization
    private var activeQueries: Set<HKQuery> = []
    
    func startObserving() async {
        // No need for locks or dispatch queues
        let query = createObserverQuery()
        activeQueries.insert(query)
        store.execute(query)
    }
}
```

## MainActor Usage Guidelines

### ✅ ONLY Use @MainActor For:

1. **ViewModels** - They update UI state
2. **View Components** - Custom view helpers
3. **UI-Only Managers** - Navigation, presentation
4. **SwiftUI Environment Objects** - Must be on MainActor

### ❌ NEVER Use @MainActor For:

1. **Services** - Use actors instead
2. **Data Models** - Keep them neutral
3. **Network Clients** - Use actors
4. **Persistence Layers** - Use actors
5. **Business Logic** - Isolate from UI

### Migration Example
```swift
// ❌ BAD: Service on MainActor
@MainActor
class UserService {
    func updateProfile(_ profile: Profile) async throws {
        // This blocks the main thread!
    }
}

// ✅ GOOD: Service as actor
actor UserService: UserServiceProtocol {
    func updateProfile(_ profile: Profile) async throws {
        // Runs on actor's executor
    }
}
```

## Task Management

### ✅ Structured Concurrency
```swift
func loadDashboard() async {
    // Tasks are automatically cancelled if view disappears
    async let nutrition = loadNutrition()
    async let workouts = loadWorkouts()
    async let goals = loadGoals()
    
    do {
        self.data = try await DashboardData(
            nutrition: nutrition,
            workouts: workouts,
            goals: goals
        )
    } catch {
        handleError(error)
    }
}
```

### ✅ Task Groups for Dynamic Work
```swift
func processMultipleItems(_ items: [Item]) async throws -> [Result] {
    try await withThrowingTaskGroup(of: Result.self) { group in
        for item in items {
            group.addTask {
                try await self.processItem(item)
            }
        }
        
        var results: [Result] = []
        for try await result in group {
            results.append(result)
        }
        return results
    }
}
```

### ❌ Avoid Unstructured Tasks
```swift
// ❌ BAD: Fire and forget
func loadData() {
    Task {
        let data = try await service.fetch()
        self.data = data  // Might execute after view is gone!
    }
}

// ✅ GOOD: Structured with cancellation
func loadData() async {
    let data = try await service.fetch()
    self.data = data  // Cancelled if view disappears
}
```

## Anti-Patterns to Avoid

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

### ❌ MainActor.run in Services
```swift
// ❌ BAD: Service reaching into UI
actor MyService {
    func updateUI() async {
        await MainActor.run {
            // Services shouldn't know about UI!
        }
    }
}
```

### ❌ @unchecked Sendable
```swift
// ❌ BAD: Bypassing safety
class MyClass: @unchecked Sendable {
    var mutableState: String = ""  // Data race!
}

// ✅ GOOD: Proper synchronization
actor MyActor {
    var mutableState: String = ""  // Actor-isolated
}
```

### ❌ Excessive Async Initialization
```swift
// ❌ BAD: Complex async init chains
class AppState {
    init() async throws {
        await initializeEverything()  // Can timeout!
    }
}

// ✅ GOOD: Simple init, explicit loading
class AppState {
    init() {}
    
    func initialize() async throws {
        // Explicit, can show loading UI
    }
}
```

## Migration Patterns

### From @MainActor Service to Actor
```swift
// Step 1: Create protocol
protocol UserServiceProtocol {
    func getUser() async throws -> User
}

// Step 2: Implement as actor
actor UserService: UserServiceProtocol {
    func getUser() async throws -> User {
        // Implementation
    }
}

// Step 3: Update injection
container.register(UserServiceProtocol.self) { _ in
    await UserService()
}

// Step 4: Update ViewModels
@MainActor
final class ProfileViewModel {
    private let userService: UserServiceProtocol  // Protocol, not concrete
    
    func load() async {
        let user = try await userService.getUser()  // Crosses actor boundary
        self.user = user
    }
}
```

### From Completion Handlers to Async/Await
```swift
// ❌ OLD: Callback-based
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            completion(.failure(error))
        } else if let data = data {
            completion(.success(data))
        }
    }.resume()
}

// ✅ NEW: Async/await
func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}
```

## Testing Concurrency

### Testing Actors
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

### Testing Cancellation
```swift
func testCancellation() async throws {
    let task = Task {
        try await longRunningOperation()
    }
    
    // Cancel after short delay
    try await Task.sleep(nanoseconds: 100_000_000)
    task.cancel()
    
    // Verify cancellation
    do {
        try await task.value
        XCTFail("Should have been cancelled")
    } catch {
        XCTAssertTrue(error is CancellationError)
    }
}
```

## Performance Guidelines

1. **Measure MainActor pressure**: Keep UI responsive
   ```swift
   // Use Instruments to measure main thread usage
   // Aim for <50% main thread utilization
   ```

2. **Avoid actor hopping**: Batch operations
   ```swift
   // ❌ BAD: Multiple round trips
   for item in items {
       await actor.process(item)
   }
   
   // ✅ GOOD: Single batch operation
   await actor.processItems(items)
   ```

3. **Use async let for parallelism**
   ```swift
   // Parallel fetching
   async let a = fetchA()
   async let b = fetchB()
   let (resultA, resultB) = try await (a, b)
   ```

## Checklist for Code Review

- [ ] ViewModels are @MainActor, services are actors
- [ ] No synchronous blocking (semaphores, wait, etc.)
- [ ] No @unchecked Sendable without documentation
- [ ] Structured concurrency used (no unstructured Tasks)
- [ ] Actor boundaries are clear and minimal
- [ ] No MainActor.run in services
- [ ] Cancellation is handled properly
- [ ] Error handling crosses actor boundaries correctly

## References

- [Swift Concurrency Guide](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency)
- Research Reports: `Concurrency_Model_Analysis.md`
- Recovery Plan: `CODEBASE_RECOVERY_PLAN.md`