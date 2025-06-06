# AirFit Testing Guidelines

## 1. Testing Philosophy

Testing is a fundamental part of the AirFit development process, not an afterthought. We believe that comprehensive testing ensures reliability, prevents regressions, and serves as living documentation for our codebase. Every feature should be built with testing in mind from the start.

Our testing goals are:
- **Reliability**: Users can trust AirFit with their health and fitness data
- **Regression Prevention**: Changes don't break existing functionality
- **Documentation**: Tests demonstrate how components should be used
- **Confidence**: Developers can refactor and improve code without fear

Testing is a first-class citizen in our development workflow. We write tests alongside features, not after.

## 2. Test Types

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

## 3. Test Naming Conventions

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

## 4. AAA Pattern

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

## 5. Mocking Strategy

Use protocol-based mocking for all external dependencies to ensure tests are fast, reliable, and deterministic.

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

## 6. SwiftData Testing

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

## 7. Code Coverage Requirements

Minimum coverage requirements by component type:

### ViewModels: 80% minimum
- All public methods must be tested
- All published properties must have state verification
- Error handling paths must be covered

### Services: 70% minimum  
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

## 8. CI/CD Integration

### Test Environment Requirements
- Tests must run headlessly without UI
- No external network dependencies
- Deterministic results (no random failures)
- Fast execution (< 5 minutes for unit tests)

### Timeout Considerations
```swift
// Set appropriate timeouts for async operations
func test_networkRequest_shouldCompleteWithinTimeout() async throws {
    // Use withTimeout to prevent hanging tests
    try await withTimeout(seconds: 5) {
        let result = try await networkService.fetchData()
        XCTAssertNotNil(result)
    }
}

// Helper for timeout
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

### Parallel Test Execution
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

## 9. Accessibility Testing

All interactive elements must be properly configured for accessibility testing and VoiceOver support.

### Identifier Requirements
- All interactive elements must have accessibility identifiers
- Naming convention: `module.component.element`
- Use semantic identifiers that describe function, not implementation

### Examples
```swift
// In SwiftUI views
Button("Continue") {
    // action
}
.accessibilityIdentifier("onboarding.welcome.continueButton")
.accessibilityLabel("Continue to next step")
.accessibilityHint("Double tap to proceed with onboarding")

TextField("Enter your name", text: $name)
    .accessibilityIdentifier("onboarding.name.textField")
    .accessibilityLabel("Name input field")
    .accessibilityValue(name.isEmpty ? "Empty" : name)

// Custom components
struct MacroRingView: View {
    let progress: Double
    let label: String
    
    var body: some View {
        // Ring implementation
    }
    .accessibilityElement()
    .accessibilityLabel("\(label) progress")
    .accessibilityValue("\(Int(progress * 100)) percent")
}
```

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
