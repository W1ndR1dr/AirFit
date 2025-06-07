# AirFit Test Migration Guide

**Purpose**: Step-by-step instructions for migrating existing tests to follow new standards.  
**Target**: Developers refactoring the ~50% of tests that need minor updates.

## Pre-Migration Checklist

Before starting any migration:
1. Ensure the test compiles (fix syntax errors first)
2. Run the test to verify current behavior
3. Check if the feature being tested still exists
4. Review TEST_STANDARDS.md for patterns

## Migration Patterns

### Pattern 1: Manual Mocking → DI Container

#### Before (Manual Mocking)
```swift
final class FoodTrackingViewModelTests: XCTestCase {
    var sut: FoodTrackingViewModel!
    var mockCoordinator: MockFoodTrackingCoordinator!
    var mockVoiceAdapter: MockFoodVoiceAdapter!
    
    override func setUp() {
        super.setUp()
        mockCoordinator = MockFoodTrackingCoordinator()
        mockVoiceAdapter = MockFoodVoiceAdapter()
        
        sut = FoodTrackingViewModel(
            coordinator: mockCoordinator,
            voiceAdapter: mockVoiceAdapter
        )
    }
}
```

#### After (DI Container)
```swift
@MainActor
final class FoodTrackingViewModelTests: XCTestCase {
    private var container: DIContainer!
    private var sut: FoodTrackingViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        container = DITestHelper.createTestContainer()
    }
    
    override func tearDown() async throws {
        sut = nil
        container = nil
        try await super.tearDown()
    }
    
    func test_example() async throws {
        // Arrange - Configure mocks
        let mockVoice = try container.resolve(FoodVoiceServiceProtocol.self) as! MockFoodVoiceService
        mockVoice.stubbedTranscription = "one apple"
        
        // Act - Create via factory
        let factory = DIViewModelFactory(container: container)
        sut = try await factory.makeFoodTrackingViewModel()
        
        // Assert
        XCTAssertNotNil(sut)
    }
}
```

### Pattern 2: Sync → Async Setup/Teardown

#### Before (Sync)
```swift
override func setUp() {
    super.setUp()
    // setup code
}

override func tearDown() {
    // cleanup
    super.tearDown()
}
```

#### After (Async)
```swift
override func setUp() async throws {
    try await super.setUp()
    // async setup code
}

override func tearDown() async throws {
    // cleanup
    try await super.tearDown()
}
```

### Pattern 3: Direct Property Access → Public API

#### Before (Private Access)
```swift
func test_privateState() {
    sut.privateProperty = "test" // Won't compile after refactor
    sut.handleInternalEvent()    // Private method
    XCTAssertEqual(sut.internalState, "expected")
}
```

#### After (Public API)
```swift
func test_publicBehavior() async {
    // Arrange
    let mockService = try container.resolve(SomeServiceProtocol.self) as! MockSomeService
    mockService.stubbedResponse = "test response"
    
    // Act - Use public methods
    await sut.userAction()
    
    // Assert - Check observable state
    XCTAssertEqual(sut.displayText, "Expected output")
    XCTAssertTrue(mockService.methodWasCalled)
}
```

### Pattern 4: Concrete Types → Protocols

#### Before (Concrete)
```swift
var mockAdapter: MockFoodVoiceAdapter!
var sut: FoodTrackingViewModel!

func setUp() {
    mockAdapter = MockFoodVoiceAdapter()
    sut = FoodTrackingViewModel(voiceAdapter: mockAdapter) // Type mismatch
}
```

#### After (Protocol)
```swift
// 1. Define protocol if missing
protocol FoodVoiceAdapterProtocol {
    func startRecording() async throws
    func stopRecording() async throws -> String
}

// 2. Make concrete type conform
extension FoodVoiceAdapter: FoodVoiceAdapterProtocol { }

// 3. Make mock conform
final class MockFoodVoiceAdapter: FoodVoiceAdapterProtocol, MockProtocol {
    // implementation
}

// 4. Register in DI container
container.register(FoodVoiceAdapterProtocol.self) { _ in
    MockFoodVoiceAdapter()
}
```

### Pattern 5: Test Method Signatures

#### Before (Sync Test)
```swift
func testSomething() {
    let result = sut.calculate()
    XCTAssertEqual(result, 42)
}
```

#### After (Async Test)
```swift
func test_calculate_withValidInput_returnsCorrectValue() async throws {
    // Note: Even if method is sync, test can be async for consistency
    let result = sut.calculate()
    XCTAssertEqual(result, 42)
}
```

## Step-by-Step Migration Process

### Step 1: Update Class Declaration
```swift
// Add @MainActor if dealing with UI
@MainActor
final class SomeViewModelTests: XCTestCase {
```

### Step 2: Update Properties
```swift
// Remove individual mock properties
// Add container and sut
private var container: DIContainer!
private var sut: SomeViewModel!
```

### Step 3: Update Setup/Teardown
```swift
override func setUp() async throws {
    try await super.setUp()
    container = DITestHelper.createTestContainer()
}

override func tearDown() async throws {
    sut = nil
    container = nil
    try await super.tearDown()
}
```

### Step 4: Update Each Test Method

1. **Rename** to follow convention:
   ```swift
   // From: testLogin()
   // To:   test_login_withValidCredentials_succeeds()
   ```

2. **Add async throws**:
   ```swift
   func test_something() async throws {
   ```

3. **Configure mocks** via container:
   ```swift
   let mockAuth = try container.resolve(AuthServiceProtocol.self) as! MockAuthService
   mockAuth.stubbedUser = User.testUser
   ```

4. **Create SUT** via factory:
   ```swift
   let factory = DIViewModelFactory(container: container)
   sut = try await factory.makeLoginViewModel()
   ```

5. **Update assertions** to use public API

### Step 5: Handle Special Cases

#### SwiftData Tests
```swift
// Add model context
private var modelContext: ModelContext!

override func setUp() async throws {
    try await super.setUp()
    container = DITestHelper.createTestContainer()
    
    // Create test model context
    let modelContainer = try ModelContainer.createTestContainer()
    modelContext = modelContainer.mainContext
    
    // Register with container if needed
    container.register(ModelContext.self) { _ in modelContext }
}
```

#### Tests with Timers/Delays
```swift
func test_delayed_operation() async throws {
    // Act
    await sut.startDelayedOperation()
    
    // Wait for operation
    try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
    
    // Assert
    XCTAssertTrue(sut.operationCompleted)
}
```

#### Tests with NotificationCenter
```swift
func test_notification_handling() async {
    // Arrange
    let expectation = XCTestExpectation(description: "Notification received")
    
    let cancellable = NotificationCenter.default
        .publisher(for: .someNotification)
        .sink { _ in
            expectation.fulfill()
        }
    
    // Act
    await sut.triggerNotification()
    
    // Assert
    await fulfillment(of: [expectation], timeout: 1.0)
}
```

## Common Issues and Solutions

### Issue: "Cannot find type 'MockXYZ' in scope"
**Solution**: Ensure mock exists and is registered in DITestHelper

### Issue: "Type mismatch - expected Protocol, got Mock"
**Solution**: Cast after resolving:
```swift
let mock = try container.resolve(SomeProtocol.self) as! MockSome
```

### Issue: "Property 'X' is inaccessible due to 'private' protection level"
**Solution**: Test through public API instead

### Issue: "Expression is 'async' but is not marked with 'await'"
**Solution**: Add await or make test method async

### Issue: "@MainActor-isolated property can not be referenced"
**Solution**: Add @MainActor to test class

## Validation Checklist

After migrating a test file:

- [ ] All tests compile without warnings
- [ ] All tests pass
- [ ] Uses DIContainer (no manual mocking)
- [ ] Follows naming conventions
- [ ] Has async setup/teardown
- [ ] No access to private APIs
- [ ] Proper error handling
- [ ] Fast execution (<100ms per test)

## Example: Complete Migration

### Before
```swift
import XCTest
@testable import AirFit

class OnboardingViewModelTests: XCTestCase {
    var viewModel: OnboardingViewModel!
    var mockService: MockOnboardingService!
    
    override func setUp() {
        super.setUp()
        mockService = MockOnboardingService()
        viewModel = OnboardingViewModel(service: mockService)
    }
    
    func testSaveProfile() {
        viewModel.name = "John"
        viewModel.age = 30
        viewModel.saveProfile()
        
        XCTAssertTrue(mockService.saveProfileCalled)
        XCTAssertEqual(mockService.savedProfile?.name, "John")
    }
}
```

### After
```swift
import XCTest
@testable import AirFit

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var sut: OnboardingViewModel!
    
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
    func test_saveProfile_withValidData_callsServiceCorrectly() async throws {
        // Arrange
        let mockService = try container.resolve(OnboardingServiceProtocol.self) as! MockOnboardingService
        mockService.saveProfileResult = .success(())
        
        let factory = DIViewModelFactory(container: container)
        sut = try await factory.makeOnboardingViewModel()
        
        sut.name = "John"
        sut.age = 30
        
        // Act
        await sut.saveProfile()
        
        // Assert
        XCTAssertTrue(mockService.saveProfileCalled)
        XCTAssertEqual(mockService.saveProfileCallCount, 1)
        XCTAssertEqual(mockService.lastSavedProfile?.name, "John")
        XCTAssertEqual(mockService.lastSavedProfile?.age, 30)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
}
```

## Next Steps

1. Start with files that have compilation errors
2. Then migrate files with the most tests
3. Finally, handle edge cases and complex tests
4. Run coverage report after each module
5. Update this guide with new patterns discovered