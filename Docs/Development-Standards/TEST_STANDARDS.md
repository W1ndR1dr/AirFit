# AirFit Test Standards

**Last Updated**: 2025-01-08  
**Status**: Active

**Purpose**: Define the patterns, conventions, and standards that ALL tests must follow.  
**Scope**: Unit tests, integration tests, and UI tests for the AirFit iOS app.

## Core Principles

1. **Test Behavior, Not Implementation**: Focus on public APIs and observable outcomes
2. **Complete Isolation**: Each test must be independent with no shared state
3. **Fast and Deterministic**: No network calls, predictable results
4. **Self-Documenting**: Test names describe the scenario and expected outcome
5. **DI Everything**: All dependencies injected via DIContainer

## ⚠️ CRITICAL: Before Writing ANY Test

1. **Check if test already exists**: Use grep/search for the class name
2. **Review similar tests**: Find tests in same module for patterns
3. **Check TEST_EXECUTION_PLAN.md**: See if task is already completed
4. **Use exact naming**: Follow conventions below EXACTLY to prevent duplicates

## File Organization

```
AirFitTests/
├── Mocks/
│   ├── Base/
│   │   └── MockProtocol.swift         # Base protocol all mocks conform to
│   └── Mock{Service}.swift             # One mock per protocol
├── Modules/
│   └── {ModuleName}/
│       ├── ViewModels/
│       │   └── {ViewModel}Tests.swift  # ViewModel tests
│       └── Services/
│           └── {Service}Tests.swift    # Service tests
├── Core/
│   ├── DI/
│   │   └── DI{Component}Tests.swift   # DI system tests
│   └── Extensions/
│       └── {Extension}Tests.swift     # Extension tests
├── Integration/
│   └── {Feature}IntegrationTests.swift # Multi-component tests
└── TestUtils/
    ├── DITestHelper.swift              # DI test container setup
    └── TestData.swift                  # Shared test data factories
```

## Naming Conventions

### Test Class Names
```swift
// Format: {ClassUnderTest}Tests
final class UserServiceTests: XCTestCase { }
final class DashboardViewModelTests: XCTestCase { }
final class DIBootstrapperTests: XCTestCase { }
```

### Test Method Names
```swift
// Format: test_{methodName}_{condition}_{expectedResult}
func test_calculateBMI_withValidInputs_returnsCorrectValue()
func test_saveUser_whenDatabaseFails_throwsError()
func test_fetchWeather_withNoAPIKey_returnsNil()
```

### Mock Names
```swift
// Format: Mock{ProtocolName}
final class MockUserService: UserServiceProtocol, MockProtocol { }
final class MockHealthKitManager: HealthKitManagerProtocol, MockProtocol { }
```

## Standard Test Structure

### Basic Test Template
```swift
import XCTest
@testable import AirFit

@MainActor
final class SomeViewModelTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var sut: SomeViewModel!  // System Under Test
    
    // MARK: - Setup & Teardown
    override func setUp() async throws {
        try await super.setUp()
        container = DITestHelper.createTestContainer()
    }
    
    override func tearDown() async throws {
        sut = nil
        container = nil
        try await super.tearDown()
    }
    
    // MARK: - Tests
    func test_someMethod_givenCondition_expectedResult() async throws {
        // Arrange
        let mockService = try container.resolve(SomeServiceProtocol.self) as! MockSomeService
        mockService.stubbedResult = .success("test")
        
        sut = SomeViewModel(container: container)
        
        // Act
        await sut.someMethod()
        
        // Assert
        XCTAssertEqual(sut.someProperty, "expected value")
        XCTAssertTrue(mockService.someMethodCalled)
    }
}
```

## Mock Standards

### Mock Protocol
```swift
protocol MockProtocol {
    func reset()
}
```

### Standard Mock Implementation
```swift
// For actor-isolated services
actor MockUserService: UserServiceProtocol, MockProtocol {
    // Use nonisolated for simple properties
    nonisolated let id = UUID()
    
    // For mutable state, stay actor-isolated
    private(set) var callCount = 0
    
    // Reset must be async for actors
    func reset() async {
        callCount = 0
    }
}

// For @MainActor services
@MainActor
final class MockUserService: UserServiceProtocol, MockProtocol {
    // MARK: - MockProtocol
    func reset() {
        // Reset all properties to initial state
        getCurrentUserCallCount = 0
        getCurrentUserResult = nil
        saveUserCallCount = 0
        saveUserReceivedUser = nil
        saveUserError = nil
    }
    
    // MARK: - Tracking Properties
    private(set) var getCurrentUserCallCount = 0
    private(set) var saveUserCallCount = 0
    private(set) var saveUserReceivedUser: User?
    
    // MARK: - Stubbed Results
    var getCurrentUserResult: User?
    var saveUserError: Error?
    
    // MARK: - UserServiceProtocol
    func getCurrentUser() async throws -> User? {
        getCurrentUserCallCount += 1
        return getCurrentUserResult
    }
    
    func save(_ user: User) async throws {
        saveUserCallCount += 1
        saveUserReceivedUser = user
        if let error = saveUserError {
            throw error
        }
    }
}
```

## DI Container Usage

### Test Container Setup
```swift
// In DITestHelper.swift
struct DITestHelper {
    static func createTestContainer() -> DIContainer {
        let container = DIContainer()
        
        // Register all mocks
        container.register(UserServiceProtocol.self) { _ in
            MockUserService()
        }
        
        container.register(HealthKitManagerProtocol.self) { _ in
            MockHealthKitManager()
        }
        
        // ... register all other mocks
        
        return container
    }
}
```

### Using DI in Tests
```swift
func test_loadDashboard_withHealthData_displaysCorrectly() async throws {
    // Arrange - Configure mocks before creating SUT
    let mockHealth = try container.resolve(HealthKitManagerProtocol.self) as! MockHealthKitManager
    mockHealth.stubbedSleepData = SleepData(hours: 8.5, quality: .good)
    
    let factory = DIViewModelFactory(container: container)
    
    // Act - Create ViewModel through factory
    sut = try await factory.makeDashboardViewModel()
    await sut.loadData()
    
    // Assert
    XCTAssertEqual(sut.sleepHours, 8.5)
    XCTAssertEqual(sut.sleepQuality, "Good")
    XCTAssertTrue(mockHealth.fetchSleepDataCalled)
}
```

## SwiftData Testing

### In-Memory Test Container
```swift
extension ModelContainer {
    static func createTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: User.self, FoodEntry.self, Workout.self,
            configurations: config
        )
        return container
    }
}
```

### SwiftData Test Template
```swift
@MainActor
final class NutritionServiceTests: XCTestCase {
    private var modelContext: ModelContext!
    private var sut: NutritionService!
    
    override func setUp() async throws {
        try await super.setUp()
        let container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        sut = NutritionService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        modelContext = nil
        sut = nil
        try await super.tearDown()
    }
}
```

## Async/Await Standards (Swift 6)

### Setup/Teardown Patterns
```swift
// ✅ CORRECT - Swift 6 Pattern
override func setUp() async throws {
    try super.setUp()  // NO await - XCTestCase methods aren't async
    
    // Your async setup code here
    container = try await DITestHelper.createTestContainer()
}

override func tearDown() async throws {
    // Async cleanup first
    await mockService?.reset()
    
    // Then call super
    try super.tearDown()  // NO await
}

// ❌ WRONG - This pattern is outdated
override func setUp() async throws {
    try super.setUp()  // ❌ Missing await in Swift 6!
}

// ✅ CORRECT - Swift 6 requires await for async parent methods
override func setUp() async throws {
    try await super.setUp()  // ✅ Must await async parent methods
}
```

### Actor Isolation Requirements
```swift
// ✅ CORRECT - For tests using ModelContext or UI components
@MainActor
final class ViewModelTests: XCTestCase {
    private var modelContext: ModelContext!
    // ...
}

// ❌ WRONG - Missing actor isolation
final class ViewModelTests: XCTestCase {
    private var modelContext: ModelContext!  // ❌ Requires @MainActor
}
```

### Testing Async Methods
```swift
func test_asyncOperation_completesSuccessfully() async throws {
    // Arrange
    let mockService = MockSomeService()
    mockService.delay = 0.1 // Simulate network delay
    
    // Act
    let result = try await sut.performAsyncOperation()
    
    // Assert
    XCTAssertNotNil(result)
}
```

## Common Patterns

### Testing Published Properties
```swift
func test_publishedProperty_updatesCorrectly() async {
    // Arrange
    let expectation = XCTestExpectation(description: "Property updated")
    var cancellables = Set<AnyCancellable>()
    
    sut.$someProperty
        .dropFirst() // Skip initial value
        .sink { value in
            XCTAssertEqual(value, "expected")
            expectation.fulfill()
        }
        .store(in: &cancellables)
    
    // Act
    await sut.updateProperty()
    
    // Assert
    await fulfillment(of: [expectation], timeout: 1.0)
}
```

### Testing Error Cases
```swift
func test_operation_whenServiceFails_showsError() async {
    // Arrange
    let mockService = try container.resolve(SomeServiceProtocol.self) as! MockSomeService
    mockService.shouldThrowError = NetworkError.connectionFailed
    
    // Act
    await sut.performOperation()
    
    // Assert
    XCTAssertTrue(sut.showError)
    XCTAssertEqual(sut.errorMessage, "Connection failed")
}
```

### Testing State Transitions
```swift
func test_loading_showsAndHidesCorrectly() async {
    // Arrange
    XCTAssertFalse(sut.isLoading)
    
    // Act
    let task = Task {
        await sut.loadData()
    }
    
    // Assert - Check loading started
    try await Task.sleep(nanoseconds: 10_000_000) // 0.01s
    XCTAssertTrue(sut.isLoading)
    
    // Wait for completion
    await task.value
    XCTAssertFalse(sut.isLoading)
}
```

## Test Data Factories

### User Test Data
```swift
extension User {
    static var testUser: User {
        User(
            name: "Test User",
            email: "test@example.com",
            dateOfBirth: Date(timeIntervalSince1970: 946684800), // 2000-01-01
            heightCm: 175,
            weightKg: 70,
            activityLevel: .moderate,
            preferredUnits: "metric"
        )
    }
}
```

### Builder Pattern for Complex Objects
```swift
class TestDataBuilder {
    static func makeWorkout(
        name: String = "Test Workout",
        duration: TimeInterval = 3600,
        exercises: [Exercise] = []
    ) -> Workout {
        Workout(
            name: name,
            duration: duration,
            exercises: exercises.isEmpty ? [makeExercise()] : exercises,
            completedAt: Date()
        )
    }
    
    static func makeExercise(
        name: String = "Bench Press",
        sets: Int = 3,
        reps: Int = 10
    ) -> Exercise {
        Exercise(name: name, sets: sets, reps: reps)
    }
}
```

## Swift 6 Common Pitfalls

### ❌ Wrong Variable Names
```swift
// Wrong - inconsistent naming
var context: ModelContext!  // Should be modelContext
var mockHealth: MockHealthKitManager!  // Should be mockHealthKitManager
```

### ❌ Wrong Protocol References  
```swift
// Wrong - using old/wrong protocol names
let healthKit = try container.resolve(HealthKitManagerProtocol.self)  // ❌

// Correct
let healthKit = try container.resolve(HealthKitManaging.self)  // ✅
```

### ❌ Force Unwrapping Without Assertion
```swift
// Wrong - will crash without helpful message
let mock = container.resolve(SomeProtocol.self) as! MockService

// Correct - fails with clear message
let mock = try container.resolve(SomeProtocol.self) as? MockService
XCTAssertNotNil(mock, "MockService should be registered in DITestHelper")
```

## Anti-Patterns to Avoid

### ❌ Testing Private Methods
```swift
// Wrong - testing implementation details
func test_privateHelper_calculatesCorrectly() {
    let result = sut.privateCalculation() // Won't compile
}
```

### ❌ Shared State Between Tests
```swift
// Wrong - tests affect each other
class BadTests: XCTestCase {
    static var sharedUser = User() // Never do this
}
```

### ❌ Real Network Calls
```swift
// Wrong - flaky and slow
func test_api_fetchesRealData() async {
    let data = try await URLSession.shared.data(from: URL(string: "https://api.example.com")!)
}
```

### ❌ Testing Multiple Things
```swift
// Wrong - test does too much
func test_everything() {
    // Tests login
    // Tests navigation  
    // Tests data loading
    // Tests error handling
}
```

## Coverage Requirements

- **ViewModels**: 80% minimum (all public methods)
- **Services**: 85% minimum (business logic)
- **Utilities**: 90% minimum (pure functions)
- **Extensions**: 95% minimum (simple logic)

## CI/CD Requirements

1. All tests must pass before merge
2. No decrease in coverage allowed
3. Tests must run in <2 minutes
4. No flaky tests (100% reliability)
5. Parallel execution must work

## Decision Tree for Common Scenarios

### "Should I create a mock for X?"
1. Is X an external dependency? → YES
2. Does X already have a protocol? → If NO, create protocol first
3. Does MockX already exist? → Check Mocks/ directory
4. Follow mock naming: Mock{ProtocolName} (not Mock{ClassName})

### "Should I test this private method?"
Answer: NO. Test through public API only. If you can't test it publicly, it shouldn't be private.

### "Should I create an integration test?"
1. Does it cross module boundaries? → Consider it
2. Does it test critical user path? → YES
3. Would unit tests be artificial? → YES
4. Keep under 5% of total tests

### "How do I name this test file?"
1. Testing a ViewModel? → {ViewModelName}Tests.swift
2. Testing a Service? → {ServiceName}Tests.swift  
3. Testing integration? → {Feature}IntegrationTests.swift
4. Place in mirror of source location

## File Location Rules

**CRITICAL**: Tests must mirror source structure exactly

| Source File | Test File |
|------------|-----------|
| `/Modules/Dashboard/ViewModels/DashboardViewModel.swift` | `/Modules/Dashboard/ViewModels/DashboardViewModelTests.swift` |
| `/Services/AI/AIService.swift` | `/Services/AI/AIServiceTests.swift` |
| `/Core/DI/DIContainer.swift` | `/Core/DI/DIContainerTests.swift` |

**Never place tests at module root** - always in appropriate subdirectory.

## Complete Mock Template

Use this EXACT template for consistency:

```swift
// File: Mocks/Mock{ProtocolName}.swift
import Foundation
@testable import AirFit

final class Mock{ProtocolName}: {ProtocolName}, MockProtocol, @unchecked Sendable {
    // MARK: - MockProtocol
    private let queue = DispatchQueue(label: "mock.{protocolName}.queue")
    
    func reset() {
        queue.sync {
            // Reset ALL properties to initial values
            someMethodCalled = false
            someMethodCallCount = 0
            someMethodReceivedParams = nil
            stubbedSomeMethodResult = nil
            stubbedSomeMethodError = nil
        }
    }
    
    // MARK: - Call Tracking (use queue.sync for thread safety)
    private var _someMethodCalled = false
    var someMethodCalled: Bool {
        queue.sync { _someMethodCalled }
    }
    
    private var _someMethodCallCount = 0
    var someMethodCallCount: Int {
        queue.sync { _someMethodCallCount }
    }
    
    private var _someMethodReceivedParams: (param1: String, param2: Int)?
    var someMethodReceivedParams: (param1: String, param2: Int)? {
        queue.sync { _someMethodReceivedParams }
    }
    
    // MARK: - Stubbed Results
    var stubbedSomeMethodResult: ResultType?
    var stubbedSomeMethodError: Error?
    
    // MARK: - {ProtocolName} Implementation
    func someMethod(param1: String, param2: Int) async throws -> ResultType {
        queue.sync {
            _someMethodCalled = true
            _someMethodCallCount += 1
            _someMethodReceivedParams = (param1, param2)
        }
        
        if let error = stubbedSomeMethodError {
            throw error
        }
        
        return stubbedSomeMethodResult ?? ResultType.default
    }
}
```

## Checklist for New Tests

- [ ] Checked TEST_EXECUTION_PLAN.md for task status
- [ ] Searched for existing test file
- [ ] Uses DIContainer for all dependencies
- [ ] Follows EXACT naming convention
- [ ] Located in correct directory (mirrors source)
- [ ] Uses AAA pattern (Arrange, Act, Assert)
- [ ] No shared state between tests
- [ ] Async setup/teardown
- [ ] Tests ONE thing
- [ ] Descriptive test method name
- [ ] All external dependencies mocked
- [ ] Runs in <100ms
- [ ] No commented/dead code
- [ ] Added to project.yml if new file