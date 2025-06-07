# Mock Implementation Guide

> **Navigation**: Essential reading before creating mocks  
> **Previous**: [TEST_STANDARDS.md](./TEST_STANDARDS.md) - General test standards  
> **Next**: [DI_TEST_MIGRATION_PLAN.md](./DI_TEST_MIGRATION_PLAN.md) - Migration strategy

## When to Mock vs Use Real Implementation

```
Should I mock this dependency?
├─ Is it an external system (network, database, file system)?
│  └─ YES → Mock it
├─ Does it have side effects (analytics, notifications)?
│  └─ YES → Mock it
├─ Is it slow or resource-intensive?
│  └─ YES → Mock it
├─ Is it non-deterministic (time, randomness)?
│  └─ YES → Mock it
└─ NO → Use real implementation
```

## The Base MockProtocol

All mocks inherit from this protocol (defined in `Mocks/Base/MockProtocol.swift`):

```swift
protocol MockProtocol {
    var invocations: [String: [Any]] { get set }
    var stubbedResults: [String: Any] { get set }
    var mockLock: NSLock { get }
    
    func recordInvocation(_ method: String, arguments: Any...)
    func stubbedResult<T>(for method: String, default defaultValue: T) -> T
    func verify(_ method: String, called times: Int, file: StaticString, line: UInt)
    func reset()
}
```

## Mock Implementation Patterns

### 1. Basic Service Mock
For simple async services:

```swift
final class MockUserService: UserServiceProtocol, MockProtocol {
    // MARK: - MockProtocol
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - UserServiceProtocol
    func getCurrentUser() async throws -> User? {
        recordInvocation("getCurrentUser")
        return stubbedResult(for: "getCurrentUser", default: User.makeStub())
    }
}
```

### 2. @MainActor Mock
For UI-related services:

```swift
@MainActor
final class MockDashboardService: DashboardServiceProtocol, @preconcurrency MockProtocol {
    // MARK: - MockProtocol (nonisolated for thread safety)
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    nonisolated let mockLock = NSLock()
    
    // MARK: - DashboardServiceProtocol
    func updateDashboard() async {
        await recordInvocationAsync("updateDashboard")
    }
    
    // Helper for recording from MainActor
    nonisolated func recordInvocationAsync(_ method: String, arguments: Any...) async {
        recordInvocation(method, arguments: arguments)
    }
}
```

### 3. Streaming Mock
For AsyncSequence/AsyncThrowingStream:

```swift
final class MockAIService: AIServiceProtocol, MockProtocol {
    // ... MockProtocol implementation ...
    
    // Streaming configuration
    var streamedTokens: [String] = ["Hello", " ", "world", "!"]
    var streamDelay: TimeInterval = 0.1
    var shouldStreamFail = false
    
    func streamCompletion(prompt: String) -> AsyncThrowingStream<String, Error> {
        recordInvocation("streamCompletion", arguments: prompt)
        
        return AsyncThrowingStream { continuation in
            Task {
                if shouldStreamFail {
                    continuation.finish(throwing: MockError.streamFailure)
                    return
                }
                
                for token in streamedTokens {
                    continuation.yield(token)
                    try await Task.sleep(nanoseconds: UInt64(streamDelay * 1_000_000_000))
                }
                continuation.finish()
            }
        }
    }
}
```

### 4. Complex State Mock
For services with internal state:

```swift
final class MockHealthKitManager: HealthKitManagerProtocol, MockProtocol {
    // ... MockProtocol implementation ...
    
    // State management
    private var savedSamples: [String: [HKSample]] = [:]
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    func saveNutrition(_ nutrition: NutritionData) async throws {
        recordInvocation("saveNutrition", arguments: nutrition)
        
        // Simulate state change
        mockLock.lock()
        defer { mockLock.unlock() }
        
        let samples = createSamples(from: nutrition)
        savedSamples[nutrition.id] = samples
        
        // Return configured result
        if let error = stubbedResults["saveNutrition_error"] as? Error {
            throw error
        }
    }
    
    // Verification helper
    func verifySavedNutrition(withId id: String) -> [HKSample]? {
        mockLock.lock()
        defer { mockLock.unlock() }
        return savedSamples[id]
    }
}
```

## Verification Helpers

Add domain-specific verification to your mocks:

```swift
extension MockAnalyticsService {
    /// Verify a specific event was tracked
    func verifyEventTracked(
        _ eventName: String,
        withProperties properties: [String: Any]? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let calls = invocations["trackEvent"] as? [[Any]] ?? []
        
        let found = calls.contains { args in
            guard args.count >= 1,
                  let name = args[0] as? String,
                  name == eventName else { return false }
            
            if let expectedProps = properties,
               args.count >= 2,
               let actualProps = args[1] as? [String: Any] {
                return NSDictionary(dictionary: expectedProps)
                    .isEqual(to: actualProps)
            }
            
            return properties == nil
        }
        
        XCTAssertTrue(
            found,
            "Event '\(eventName)' was not tracked\(properties != nil ? " with expected properties" : "")",
            file: file,
            line: line
        )
    }
    
    /// Verify no events were tracked
    func verifyNoEventsTracked(file: StaticString = #file, line: UInt = #line) {
        let eventCount = (invocations["trackEvent"] as? [Any])?.count ?? 0
        XCTAssertEqual(eventCount, 0, "Expected no events but found \(eventCount)", file: file, line: line)
    }
}
```

## Common Mock Configurations

### Error Simulation
```swift
// Option 1: Simple flag
mock.shouldThrowError = true
mock.errorToThrow = NetworkError.timeout

// Option 2: Result type (more flexible)
mock.stubbedResults["fetchData"] = Result<Data, Error>.failure(NetworkError.timeout)

// Option 3: Per-method configuration
mock.stubbedResults["saveUser_error"] = ValidationError.invalidEmail
```

### Async Behavior
```swift
// Add delays
mock.simulatedDelay = 0.5 // seconds

// In the mock method:
if simulatedDelay > 0 {
    try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
}
```

### State Verification
```swift
// Track state changes
var stateHistory: [State] = []

func transition(to newState: State) {
    mockLock.lock()
    stateHistory.append(newState)
    mockLock.unlock()
}

// Verify transitions
func verifyStateTransitions(_ expected: [State]) {
    XCTAssertEqual(stateHistory, expected)
}
```

## Testing with Mocks

### Setup Pattern
```swift
func test_saveUser_callsAnalytics() async throws {
    // Arrange
    try await setupTest()
    let analyticsService = try await container.resolve(AnalyticsServiceProtocol.self) as? MockAnalyticsService
    
    let user = User.makeStub()
    
    // Act
    try await sut.saveUser(user)
    
    // Assert
    analyticsService?.verifyEventTracked("user_saved", withProperties: ["user_id": user.id])
}
```

### Multiple Mocks
```swift
func test_complexFlow() async throws {
    // Get all mocks
    let networkMock = try await container.resolve(NetworkClientProtocol.self) as? MockNetworkClient
    let storageMock = try await container.resolve(StorageProtocol.self) as? MockStorage
    let analyticsMock = try await container.resolve(AnalyticsProtocol.self) as? MockAnalytics
    
    // Configure
    networkMock?.stubbedResults["fetchData"] = TestData.sample
    storageMock?.shouldSucceed = true
    
    // Act
    try await sut.performComplexOperation()
    
    // Assert
    networkMock?.verify("fetchData", called: 1)
    storageMock?.verify("save", called: 1)
    analyticsMock?.verifyEventTracked("operation_completed")
}
```

## Mock Checklist

Before submitting a mock:
- [ ] Implements both service protocol and MockProtocol
- [ ] Uses `nonisolated(unsafe)` for MockProtocol properties
- [ ] All state mutations use mockLock
- [ ] Provides reset() implementation
- [ ] Has verification helpers for common assertions
- [ ] Supports both success and failure scenarios
- [ ] Documents any special behavior
- [ ] Added to DITestHelper registration

## Anti-Patterns to Avoid

❌ **Don't put business logic in mocks**
```swift
// BAD: Mock shouldn't validate
func saveUser(_ user: User) throws {
    if user.email.isEmpty {
        throw ValidationError.invalidEmail  // Don't do this!
    }
}

// GOOD: Let test configure behavior
func saveUser(_ user: User) throws {
    recordInvocation("saveUser", arguments: user)
    if let error = stubbedResults["saveUser_error"] as? Error {
        throw error
    }
}
```

❌ **Don't forget thread safety**
```swift
// BAD: Race condition
var callCount = 0
func doSomething() {
    callCount += 1  // Not thread-safe!
}

// GOOD: Use lock
func doSomething() {
    mockLock.lock()
    callCount += 1
    mockLock.unlock()
}
```

❌ **Don't make mocks too smart**
```swift
// BAD: Mock knows too much
func fetchUser(id: String) -> User? {
    // 50 lines of logic to return different users
}

// GOOD: Simple stubbing
func fetchUser(id: String) -> User? {
    recordInvocation("fetchUser", arguments: id)
    return stubbedResult(for: "fetchUser", default: nil)
}
```

Remember: **Mocks should be simple and predictable**. If a mock is complex, the design might need refactoring.