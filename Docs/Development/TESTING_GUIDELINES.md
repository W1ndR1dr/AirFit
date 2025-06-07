# AirFit Testing Guidelines

## 1. Testing Philosophy

Testing is a fundamental part of the AirFit development process, not an afterthought. We believe that comprehensive testing ensures reliability, prevents regressions, and serves as living documentation for our codebase. Every feature should be built with testing in mind from the start.

Our testing goals are:
- **Reliability**: Users can trust AirFit with their health and fitness data
- **Regression Prevention**: Changes don't break existing functionality
- **Documentation**: Tests demonstrate how components should be used
- **Confidence**: Developers can refactor and improve code without fear

Core principles:
- **Test-First Development**: Write tests before implementing features when possible
- **Independence**: Tests should not depend on each other or execution order
- **Fast & Reliable**: Unit tests should be quick and deterministic
- **Clear Intent**: Test names should clearly describe what is being tested

## 2. Test Organization

### Directory Structure
```
AirFit/AirFitTests/
├── Mocks/                  # Mock implementations
│   ├── Base/              # Base mock protocols
│   └── Mock*.swift        # Mock service implementations
├── Modules/               # Mirror main app structure
│   ├── AI/
│   ├── Chat/
│   ├── Dashboard/
│   ├── FoodTracking/
│   ├── Notifications/
│   ├── Onboarding/
│   ├── Settings/
│   └── Workouts/
├── Integration/           # End-to-end integration tests
├── Performance/           # Performance tests
├── Services/              # Service layer tests
└── TestUtils/            # Testing utilities and helpers

AirFit/AirFitUITests/
├── Pages/                # Page Object pattern
├── Onboarding/          # UI test flows
├── Dashboard/
└── FoodTracking/
```

## 3. Test Refactoring Guide (2025-06-05)

### Common Refactoring Patterns

#### Pattern 1: Private API Access
**Problem**: Tests accessing private properties/methods after refactoring
```swift
// ❌ OLD: Direct access to private internals
sut.transcribedText = "test input"
await sut.processTranscription()
XCTAssertEqual(sut.parsedItems.count, 1)
```

**Solution**: Use public interfaces and callbacks
```swift
// ✅ NEW: Use public API through mocks
mockVoiceAdapter.simulateTranscription("test input")
// Wait for async processing
await fulfillment(of: [expectation], timeout: 1.0)
XCTAssertEqual(sut.parsedItems.count, 1)
```

#### Pattern 2: DI Initialization
**Problem**: Tests using old initialization patterns
```swift
// ❌ OLD: Partial initialization
let viewModel = FoodTrackingViewModel(
    user: testUser,
    coordinator: mockCoordinator
)
```

**Solution**: Use full DI pattern
```swift
// ✅ NEW: Complete DI initialization
let viewModel = FoodTrackingViewModel(
    modelContext: modelContext,
    user: testUser,
    foodVoiceAdapter: mockVoiceAdapter,
    nutritionService: mockNutritionService,
    coachEngine: mockCoachEngine,
    coordinator: mockCoordinator
)
```

#### Pattern 3: Protocol vs Concrete Types
**Problem**: Expecting concrete types when protocols are needed
```swift
// ❌ OLD: Mock doesn't match expected type
let adapter: FoodVoiceAdapter = MockFoodVoiceAdapter() // Type mismatch
```

**Solution**: Add protocol conformance or factory methods
```swift
// ✅ NEW: Use protocols or test-specific factories
protocol FoodVoiceAdapterProtocol { ... }
class FoodVoiceAdapter: FoodVoiceAdapterProtocol { ... }
class MockFoodVoiceAdapter: FoodVoiceAdapterProtocol { ... }
```

#### Pattern 4: Async/Await Updates
**Problem**: Tests not handling Swift 6 concurrency
```swift
// ❌ OLD: Synchronous setUp/tearDown
override func setUp() {
    super.setUp()
    // setup code
}
```

**Solution**: Use async setUp/tearDown
```swift
// ✅ NEW: Async setUp with MainActor
override func setUp() async throws {
    await MainActor.run {
        super.setUp()
    }
    // async setup code
}
```

### Test Migration Checklist
- [ ] Update all mock patterns to support DI
- [ ] Replace private API access with public interfaces
- [ ] Add async/await to test lifecycle methods
- [ ] Update initialization to match new signatures
- [ ] Ensure Sendable conformance for concurrent code
- [ ] Remove dependencies on implementation details
- [ ] Test behavior, not implementation

## 4. Test Types

### Unit Tests
**Definition**: Tests for individual units of code in isolation from their dependencies.

**Scope**: 
- ViewModels
- Services
- Utilities
- Data transformations
- Business logic

**Example Structure**:
```swift
import XCTest
@testable import AirFit

@MainActor
final class NutritionCalculatorTests: XCTestCase {
    var sut: NutritionCalculator!
    
    override func setUp() {
        super.setUp()
        sut = NutritionCalculator()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func test_calculateCalories_givenMacros_shouldReturnCorrectTotal() {
        // Arrange
        let protein = 50.0  // 50g * 4 cal/g = 200 cal
        let carbs = 100.0   // 100g * 4 cal/g = 400 cal
        let fat = 20.0      // 20g * 9 cal/g = 180 cal
        
        // Act
        let calories = sut.calculateCalories(
            protein: protein,
            carbs: carbs,
            fat: fat
        )
        
        // Assert
        XCTAssertEqual(calories, 780, accuracy: 0.01)
    }
}

// Modern DI Pattern for Service/ViewModel Tests
@MainActor
final class DashboardViewModelTestsWithDI: XCTestCase {
    var container: DIContainer!
    var factory: DIViewModelFactory!
    var sut: DashboardViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        // Use test container with all mocks pre-registered
        container = try await DIBootstrapper.createTestContainer()
        factory = DIViewModelFactory(container: container)
    }
    
    override func tearDown() async throws {
        sut = nil
        factory = nil
        container = nil
        try await super.tearDown()
    }
    
    func test_refreshData_withMockedServices_updatesCorrectly() async throws {
        // Arrange - Configure mocks
        let mockHealthKit = try container.resolve(HealthKitManagerProtocol.self) as! MockHealthKitManager
        mockHealthKit.mockSleepData = [/* test data */]
        
        // Act - Create ViewModel via factory
        sut = try await factory.makeDashboardViewModel()
        await sut.refresh()
        
        // Assert
        XCTAssertEqual(sut.sleepHours, 8.0)
        XCTAssertTrue(mockHealthKit.fetchSleepDataCalled)
    }
}
```

### Integration Tests
**Definition**: Tests that verify the interaction between multiple components working together.

**Scope**:
- Service + Repository interactions
- ViewModel + Service interactions
- Data flow between layers
- SwiftData operations

**When to Use vs Unit Tests**:
- Use integration tests when testing the contract between components
- Use unit tests for testing logic within a single component
- Integration tests should be fewer but cover critical paths

**Example**:
```swift
@MainActor
final class MealLoggingIntegrationTests: XCTestCase {
    var viewModel: MealLoggingViewModel!
    var mealService: MealService!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup in-memory database
        modelContext = try SwiftDataTestHelper.createTestContext(
            for: User.self, Meal.self, FoodItem.self
        )
        
        // Create real service with test database
        mealService = MealService(modelContext: modelContext)
        
        // Create view model with real service
        viewModel = MealLoggingViewModel(
            mealService: mealService,
            user: User.mock
        )
    }
    
    func test_saveMeal_shouldPersistToDatabase() async throws {
        // Arrange
        let meal = Meal(
            name: "Breakfast",
            items: [FoodItem.mock],
            loggedAt: Date()
        )
        
        // Act
        try await viewModel.saveMeal(meal)
        
        // Assert - Verify persistence
        let savedMeals = try modelContext.fetch(FetchDescriptor<Meal>())
        XCTAssertEqual(savedMeals.count, 1)
        XCTAssertEqual(savedMeals.first?.name, "Breakfast")
    }
}
```

### UI Tests
**Definition**: End-to-end tests that simulate user interactions with the app's interface.

**Scope**:
- Complete user journeys
- Critical user paths
- Complex UI interactions
- Accessibility verification

**Example**:
```swift
final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
    }
    
    func test_completeOnboarding_shouldNavigateToDashboard() {
        // Welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to AirFit"].exists)
        app.buttons["Get Started"].tap()
        
        // Name entry
        let nameField = app.textFields["onboarding.name.field"]
        nameField.tap()
        nameField.typeText("John Doe")
        app.buttons["Continue"].tap()
        
        // Profile setup
        app.buttons["Male"].tap()
        app.sliders["age.slider"].adjust(toNormalizedSliderPosition: 0.3)
        app.buttons["Continue"].tap()
        
        // Goals selection
        app.buttons["Lose Weight"].tap()
        app.buttons["Complete Setup"].tap()
        
        // Verify dashboard
        XCTAssertTrue(app.navigationBars["Dashboard"].waitForExistence(timeout: 5))
    }
}
```

## 4. Naming Conventions

### Unit Test Pattern
```swift
func test_methodName_givenCondition_shouldExpectedResult()
```

**Examples**:
```swift
// Testing calculations
func test_calculateBMR_givenValidUserProfile_shouldReturnPositiveValue()
func test_calculateBMR_givenUnderageUser_shouldThrowValidationError()
func test_calculateTDEE_givenSedentaryLifestyle_shouldApplyCorrectMultiplier()

// Testing state changes
func test_saveProfile_givenValidData_shouldUpdateUserState()
func test_saveProfile_givenNetworkError_shouldThrowConnectionError()
func test_deleteWorkout_givenExistingWorkout_shouldRemoveFromList()

// Testing async operations
func test_fetchMeals_givenSuccessfulResponse_shouldPopulateList()
func test_syncHealthData_givenNoPermission_shouldRequestAuthorization()
```

### UI Test Pattern
```swift
func test_userFlow_whenAction_thenUIState()
```

**Examples**:
```swift
// User flows
func test_onboardingFlow_whenCompletingAllSteps_thenDashboardIsVisible()
func test_mealLogging_whenAddingMeal_thenMealAppearsInList()
func test_workoutTracking_whenPausingWorkout_thenTimerStops()

// Error handling
func test_login_whenInvalidCredentials_thenErrorAlertShows()
func test_dataSync_whenOffline_thenOfflineBannerAppears()

// Navigation
func test_tabBar_whenSelectingProfile_thenProfileScreenShows()
func test_settings_whenTappingLogout_thenReturnsToLogin()
```

## 5. AAA Pattern

All tests should follow the Arrange-Act-Assert pattern for clarity and consistency.

### Example 1: Testing Calculation Logic
```swift
func test_calculateTDEE_givenSedentaryUser_shouldApplyCorrectMultiplier() {
    // Arrange
    let profile = UserProfile(
        age: 30,
        weight: 70,        // kg
        height: 175,       // cm
        biologicalSex: .male,
        activityLevel: .sedentary
    )
    let calculator = TDEECalculator()
    let expectedBMR = 1679.0  // Mifflin-St Jeor formula
    let activityMultiplier = 1.2
    
    // Act
    let tdee = calculator.calculateTDEE(for: profile)
    
    // Assert
    XCTAssertEqual(tdee, expectedBMR * activityMultiplier, accuracy: 10)
}
```

### Example 2: Testing Async Operations
```swift
func test_fetchMeals_givenValidResponse_shouldUpdatePublishedProperty() async {
    // Arrange
    let mockService = MockMealService()
    let expectedMeals = [
        Meal(id: "1", name: "Grilled Chicken Salad", calories: 350),
        Meal(id: "2", name: "Protein Smoothie", calories: 280)
    ]
    mockService.mockResponse = .success(expectedMeals)
    let viewModel = MealListViewModel(mealService: mockService)
    
    // Act
    await viewModel.loadMeals()
    
    // Assert
    XCTAssertEqual(viewModel.meals.count, 2)
    XCTAssertEqual(viewModel.meals.first?.name, "Grilled Chicken Salad")
    XCTAssertEqual(viewModel.meals.last?.calories, 280)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.error)
}
```

### Example 3: Testing Error Handling
```swift
func test_login_givenInvalidCredentials_shouldShowErrorAlert() async {
    // Arrange
    let mockAuth = MockAuthService()
    mockAuth.shouldFailWithError = AuthError.invalidCredentials
    let viewModel = LoginViewModel(authService: mockAuth)
    viewModel.email = "test@example.com"
    viewModel.password = "wrongpassword"
    
    // Act
    await viewModel.login()
    
    // Assert
    XCTAssertTrue(viewModel.showAlert)
    XCTAssertEqual(viewModel.alertTitle, "Login Failed")
    XCTAssertEqual(viewModel.alertMessage, "Invalid email or password")
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.currentUser)
}
```

## 6. Dependency Injection in Tests

AirFit uses a modern dependency injection system (DIContainer) to ensure complete test isolation. All tests should use the DI pattern to inject mocks and control dependencies.

### DI Test Setup Pattern
```swift
@MainActor
class SomeViewModelTests: XCTestCase {
    var container: DIContainer!
    var factory: DIViewModelFactory!
    
    override func setUp() async throws {
        try await super.setUp()
        container = try await DIBootstrapper.createTestContainer()
        factory = DIViewModelFactory(container: container)
    }
    
    override func tearDown() async throws {
        container = nil
        factory = nil
        try await super.tearDown()
    }
}
```

### Configuring Mocks in DI
```swift
func test_someFeature_withMockedDependencies() async throws {
    // Configure mocks before creating SUT
    let mockAI = try container.resolve(AIServiceProtocol.self) as! MockAIService
    mockAI.generateResponseResult = .success("Test response")
    
    let mockUser = try container.resolve(UserServiceProtocol.self) as! MockUserService
    mockUser.currentUser = User(name: "Test User")
    
    // Create SUT via factory - it will get the configured mocks
    let viewModel = try await factory.makeSomeViewModel()
    
    // Test the feature
    await viewModel.doSomething()
    
    // Verify interactions
    XCTAssertTrue(mockAI.generateResponseCalled)
}
```

### Benefits of DI Testing
- **Complete Isolation**: Each test gets its own container with fresh mocks
- **No Singleton Pollution**: Tests can run in parallel without interference
- **Easy Mock Configuration**: Configure all mocks before creating the SUT
- **Consistent Pattern**: Same pattern works for all ViewModels and services

## 7. Mocking Strategy

Use protocol-based mocking for all external dependencies to ensure tests are fast, reliable, and deterministic. All mocks should be registered in the test DI container.

### Protocol Definition
```swift
// Define protocols for all services
protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func upload(_ data: Data, to endpoint: Endpoint) async throws
}

protocol HealthDataServiceProtocol: AnyObject {
    func requestAuthorization() async throws -> Bool
    func fetchSteps(for date: Date) async throws -> Int
    func fetchHeartRate(for date: Date) async throws -> [HeartRateReading]
    func fetchSleepData(for date: Date) async throws -> SleepData?
}
```

### Mock Implementation
```swift
// Comprehensive mock with verification capabilities
final class MockNetworkClient: NetworkClientProtocol {
    // Stubbed responses
    var mockResponses: [String: Any] = [:]
    var shouldThrowError: Error?
    
    // Verification properties
    var capturedRequests: [Endpoint] = []
    var requestCount: Int { capturedRequests.count }
    
    // Delay simulation
    var simulatedDelay: TimeInterval = 0
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Record the request
        capturedRequests.append(endpoint)
        
        // Simulate network delay if needed
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        // Throw error if configured
        if let error = shouldThrowError {
            throw error
        }
        
        // Return mock response
        guard let response = mockResponses[endpoint.path] as? T else {
            throw NetworkError.invalidResponse
        }
        
        return response
    }
    
    func upload(_ data: Data, to endpoint: Endpoint) async throws {
        capturedRequests.append(endpoint)
        
        if let error = shouldThrowError {
            throw error
        }
    }
    
    // Verification helpers
    func verify(endpoint: String, calledTimes times: Int) {
        let actualCalls = capturedRequests.filter { $0.path == endpoint }.count
        XCTAssertEqual(actualCalls, times, 
                      "\(endpoint) was called \(actualCalls) times, expected \(times)")
    }
    
    func reset() {
        mockResponses.removeAll()
        capturedRequests.removeAll()
        shouldThrowError = nil
        simulatedDelay = 0
    }
}
```

### Mock with Builder Pattern
```swift
@MainActor
final class MockHealthDataService: HealthDataServiceProtocol {
    // Builder properties
    private var authorizationResult = true
    private var stepsData: [Date: Int] = [:]
    private var heartRateData: [Date: [HeartRateReading]] = [:]
    private var sleepData: [Date: SleepData] = [:]
    
    // Configure authorization
    func willAuthorize(_ authorized: Bool) -> Self {
        authorizationResult = authorized
        return self
    }
    
    // Configure step data
    func withSteps(_ steps: Int, on date: Date) -> Self {
        stepsData[Calendar.current.startOfDay(for: date)] = steps
        return self
    }
    
    // Protocol implementation
    func requestAuthorization() async throws -> Bool {
        return authorizationResult
    }
    
    func fetchSteps(for date: Date) async throws -> Int {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return stepsData[startOfDay] ?? 0
    }
    
    func fetchHeartRate(for date: Date) async throws -> [HeartRateReading] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return heartRateData[startOfDay] ?? []
    }
    
    func fetchSleepData(for date: Date) async throws -> SleepData? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return sleepData[startOfDay]
    }
}
```

### Mock Base Protocol
All mocks should conform to a base protocol for consistency:

```swift
protocol MockProtocol {
    func reset()
}

extension MockAIService: MockProtocol {
    func reset() {
        generateResponseCalled = false
        generateResponseCallCount = 0
        generateResponsePrompt = nil
        generateResponseResult = .success("Mock response")
    }
}
```

### Dependency Injection Testing

AirFit uses a custom DI container for clean, isolated testing:

```swift
@MainActor
final class DashboardViewModelTests: XCTestCase {
    var container: DIContainer!
    var factory: DIViewModelFactory!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test container with mocks
        container = await DIBootstrapper.createTestContainer()
        factory = DIViewModelFactory(container: container)
        
        // Register test-specific mocks if needed
        container.register(WeatherServiceProtocol.self) { _ in
            let mock = MockWeatherService()
            mock.getCurrentWeatherResult = .success(WeatherData.mock)
            return mock
        }
    }
    
    func test_loadDashboard_withValidData_shouldUpdateState() async throws {
        // Arrange
        let user = User.mock
        
        // Act - ViewModel created with all dependencies injected
        let viewModel = try await factory.makeDashboardViewModel(user: user)
        await viewModel.loadDashboard()
        
        // Assert
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.weatherData)
        XCTAssertEqual(viewModel.nutritionData.calories, 1500)
    }
}
```

**Key DI Testing Patterns:**
1. Use `DIBootstrapper.createTestContainer()` for isolated test containers
2. Override specific services with custom mocks when needed
3. Use `DIViewModelFactory` to create ViewModels with proper dependencies
4. No cleanup needed - each test gets a fresh container
5. Avoid accessing singletons directly in tests

## 7. SwiftData Testing

Testing with SwiftData requires special setup to ensure tests are isolated and don't affect production data.

### Test Helper for SwiftData
```swift
// Centralized helper for creating test containers
@MainActor
class SwiftDataTestHelper {
    /// Creates an in-memory container for testing
    static func createTestContainer(for types: any PersistentModel.Type...) throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema(types)
        return try ModelContainer(for: schema, configurations: config)
    }
    
    /// Creates a test context with in-memory storage
    static func createTestContext(for types: any PersistentModel.Type...) throws -> ModelContext {
        let container = try createTestContainer(for: types)
        return ModelContext(container)
    }
    
    /// Clears all data from a context
    static func clearAllData(from context: ModelContext, types: any PersistentModel.Type...) throws {
        for type in types {
            let descriptor = FetchDescriptor(type)
            let objects = try context.fetch(descriptor)
            for object in objects {
                context.delete(object)
            }
        }
        try context.save()
    }
}
```

### Usage in Tests
```swift
@MainActor
final class UserRepositoryTests: XCTestCase {
    var modelContext: ModelContext!
    var repository: UserRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory context
        modelContext = try SwiftDataTestHelper.createTestContext(
            for: User.self, 
            OnboardingProfile.self,
            DailyLog.self
        )
        
        // Initialize repository with test context
        repository = UserRepository(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        // Clear all test data
        try SwiftDataTestHelper.clearAllData(
            from: modelContext,
            types: User.self, OnboardingProfile.self, DailyLog.self
        )
        
        modelContext = nil
        repository = nil
        
        try await super.tearDown()
    }
    
    func test_createUser_shouldPersistToDatabase() async throws {
        // Arrange
        let profile = OnboardingProfile(
            name: "Jane Doe",
            age: 28,
            weight: 65,
            height: 165,
            activityLevel: .active,
            goals: [.buildMuscle]
        )
        
        // Act
        let user = try await repository.createUser(from: profile)
        
        // Assert - Verify object was saved
        let fetchDescriptor = FetchDescriptor<User>()
        let users = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.id, user.id)
        XCTAssertEqual(users.first?.name, "Jane Doe")
    }
}
```

### Testing Relationships
```swift
func test_userMealRelationship_shouldCascadeDelete() async throws {
    // Arrange - Create user with meals
    let user = User(name: "Test User")
    let meal1 = Meal(name: "Breakfast", user: user)
    let meal2 = Meal(name: "Lunch", user: user)
    
    modelContext.insert(user)
    modelContext.insert(meal1)
    modelContext.insert(meal2)
    try modelContext.save()
    
    // Act - Delete user
    modelContext.delete(user)
    try modelContext.save()
    
    // Assert - Meals should be deleted
    let meals = try modelContext.fetch(FetchDescriptor<Meal>())
    XCTAssertEqual(meals.count, 0)
}
```

## 8. Code Coverage Requirements

Minimum coverage requirements by component type:

### ViewModels: 80% minimum
- All public methods must be tested
- All published properties must have state verification
- Error handling paths must be covered

### Services: 80-90% minimum  
- Core business logic must be thoroughly tested
- Edge cases and error conditions must be covered
- External dependencies must be mocked

### Utilities: 90% minimum
- Pure functions should have near 100% coverage
- All calculation methods must be tested with various inputs
- Edge cases (nil, empty, boundary values) must be tested

### UI Tests
- Cover all critical user paths
- Test both happy paths and error scenarios
- Verify accessibility for all interactive elements

### How to Measure Coverage
```bash
# Run tests with coverage
xcodebuild test \
    -scheme AirFit \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -enableCodeCoverage YES \
    -resultBundlePath coverage.xcresult

# View coverage report
xcrun xccov view --report coverage.xcresult

# Generate JSON report for CI
xcrun xccov view --report coverage.xcresult --json > coverage.json

# Extract specific metrics
xcrun xccov view --report coverage.xcresult --json | \
    jq '.targets[] | select(.name == "AirFit") | .lineCoverage'
```

## 9. UI Testing Best Practices

### Page Object Pattern
Structure UI tests using the Page Object pattern for maintainability:

```swift
class OnboardingPage: BasePage {
    // Elements
    var beginButton: XCUIElement {
        app.buttons["onboarding.beginButton"]
    }
    
    var titleLabel: XCUIElement {
        app.staticTexts["onboarding.title"]
    }
    
    // Actions
    func tapBegin() {
        beginButton.tap()
    }
    
    // Verifications
    func verifyOnOpeningScreen() {
        XCTAssertTrue(beginButton.exists)
        XCTAssertTrue(titleLabel.exists)
    }
}
```

### Accessibility Identifiers
Always set accessibility identifiers for UI testing:

```swift
struct SomeView: View {
    var body: some View {
        Button("Continue") {
            // action
        }
        .accessibilityIdentifier("someView.continueButton")
        .accessibilityLabel("Continue to next step")
        .accessibilityHint("Double tap to proceed with onboarding")
    }
}
```

### Identifier Naming Convention
- Format: `module.component.element`
- Use semantic identifiers that describe function, not implementation
- Examples:
  - `onboarding.welcome.continueButton`
  - `dashboard.nutrition.addMealButton`
  - `settings.profile.nameTextField`

## 10. Accessibility Testing

All interactive elements must be properly configured for accessibility testing and VoiceOver support.

### Testing Accessibility
```swift
func test_onboardingScreen_shouldHaveProperAccessibility() {
    // Verify elements have accessibility labels
    let continueButton = app.buttons["onboarding.welcome.continueButton"]
    XCTAssertTrue(continueButton.exists)
    XCTAssertEqual(continueButton.label, "Continue to next step")
    
    // Verify VoiceOver navigation order
    let nameField = app.textFields["onboarding.name.textField"]
    XCTAssertTrue(nameField.isHittable)
    
    // Test with VoiceOver enabled (in UI test scheme)
    if UIAccessibility.isVoiceOverRunning {
        // Perform VoiceOver-specific validations
        XCTAssertTrue(continueButton.isAccessibilityElement)
    }
}
```

### Accessibility Audit Helper
```swift
extension XCUIElement {
    func performAccessibilityAudit() throws {
        // Check for accessibility label
        guard !label.isEmpty else {
            throw AccessibilityError.missingLabel(identifier: identifier)
        }
        
        // Check for proper traits
        if elementType == .button {
            XCTAssertTrue(buttons[identifier].exists,
                         "Button should have button trait")
        }
        
        // Verify contrast ratios (would need image processing)
        // Verify touch target size (44x44 minimum)
    }
}
```

## 11. Testing Async Code

### Using async/await
```swift
func testAsyncOperation() async throws {
    // Given
    let expectation = XCTestExpectation(description: "Async operation completes")
    
    // When
    let result = try await viewModel.performAsyncOperation()
    
    // Then
    XCTAssertNotNil(result)
    expectation.fulfill()
    
    await fulfillment(of: [expectation], timeout: 5.0)
}
```

### Timeout Helper
```swift
func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TestError.timeout
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
```

## 12. CI/CD Integration

### Test Environment Requirements
- Tests must run headlessly without UI
- No external network dependencies
- Deterministic results (no random failures)
- Fast execution (< 5 minutes for unit tests)

### GitHub Actions Example
```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-14
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_16.0.app
    
    - name: Run Unit Tests
      run: |
        xcodebuild test \
          -scheme AirFit \
          -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
          -parallel-testing-enabled YES \
          -maximum-concurrent-test-simulator-destinations 4 \
          -resultBundlePath unittest.xcresult
    
    - name: Run UI Tests
      run: |
        xcodebuild test \
          -scheme AirFitUITests \
          -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
          -resultBundlePath uitest.xcresult
    
    - name: Upload Coverage
      uses: codecov/codecov-action@v3
      with:
        xcode: true
        xcode_archive_path: unittest.xcresult
```

### Environment Variables
```swift
// Check if running in CI
let isCI = ProcessInfo.processInfo.environment["CI"] != nil

// Skip flaky tests in CI
func testFlakyFeature() throws {
    try XCTSkipIf(isCI, "Skipped in CI due to flakiness")
    // test implementation
}
```

## 13. Running Tests

### Command Line
```bash
# All tests
swift test

# Specific module
swift test --filter AirFitTests.OnboardingTests

# With coverage
xcodebuild test -scheme AirFit -enableCodeCoverage YES

# UI tests only
xcodebuild test -scheme AirFit -only-testing:AirFitUITests
```

### Xcode
- Run all tests: `Cmd+U`
- Run specific test: Click diamond next to test method
- Run with coverage: Edit scheme → Test → Options → Code Coverage

### Pre-commit Checks
```bash
# Run before committing
swift test
swiftlint --strict
```

## 14. Best Practices

### Do's
- ✅ Write tests for edge cases
- ✅ Use descriptive assertion messages
- ✅ Test both success and failure paths
- ✅ Keep tests focused and small
- ✅ Use proper setup/teardown
- ✅ Mock external dependencies
- ✅ Write tests alongside features, not after

### Don'ts
- ❌ Test implementation details
- ❌ Share state between tests
- ❌ Use real network calls
- ❌ Depend on test execution order
- ❌ Write tests that take > 1 second
- ❌ Leave commented-out test code

### Example of Good Test
```swift
func testFoodParsing_WithValidInput_ReturnsCorrectNutrition() async throws {
    // Given - Clear setup
    let mockCoachEngine = MockCoachEngine()
    mockCoachEngine.parseNaturalLanguageFoodResult = .success([
        FoodItem(name: "Apple", calories: 95, proteinGrams: 0.5, carbGrams: 25, fatGrams: 0.3)
    ])
    
    let viewModel = FoodTrackingViewModel(
        coachEngine: mockCoachEngine,
        // other dependencies...
    )
    
    // When - Single action
    viewModel.transcribedText = "One medium apple"
    await viewModel.processTranscription()
    
    // Then - Clear assertions
    XCTAssertEqual(mockCoachEngine.parseNaturalLanguageFoodCallCount, 1)
    XCTAssertEqual(viewModel.parsedItems.count, 1)
    XCTAssertEqual(viewModel.parsedItems.first?.name, "Apple")
    XCTAssertEqual(viewModel.parsedItems.first?.calories, 95)
}
```

## 15. Continuous Improvement

- Review test failures in PR comments
- Update tests when requirements change
- Refactor tests when they become brittle
- Share testing utilities across modules
- Document complex test scenarios

## Summary

Following these testing guidelines ensures that AirFit maintains high quality, reliability, and accessibility standards. Remember:

1. Write tests first or alongside features, not after
2. Use descriptive test names that document behavior
3. Keep tests focused, fast, and independent
4. Mock external dependencies for reliability
5. Aim for high coverage but focus on meaningful tests
6. Make tests readable - they're documentation
7. Ensure all UI is accessible and testable

Good tests give us confidence to move fast without breaking things. They're an investment in our ability to evolve and improve AirFit over time.

### Additional Implementation Notes

- Every interactive view used in UI tests must expose identifiers to allow reliable selection
- UI Test Page Objects are stored under `AirFitUITests/PageObjects` following the Page Object pattern
- SwiftData Helpers use `ModelContainer.makeInMemoryContainer` from `AirFitTests/TestUtils` for isolated testing