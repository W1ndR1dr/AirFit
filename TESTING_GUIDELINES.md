# AirFit Testing Guidelines

This document outlines the testing standards and best practices for the AirFit project. All contributors must follow these guidelines when writing tests.

## Table of Contents
- [Testing Philosophy](#testing-philosophy)
- [Test Organization](#test-organization)
- [Naming Conventions](#naming-conventions)
- [Unit Testing](#unit-testing)
- [UI Testing](#ui-testing)
- [Mock Strategy](#mock-strategy)
- [Code Coverage](#code-coverage)
- [CI Integration](#ci-integration)

## Testing Philosophy

- **Test-First Development**: Write tests before implementing features when possible
- **Independence**: Tests should not depend on each other or execution order
- **Fast & Reliable**: Unit tests should be quick and deterministic
- **Clear Intent**: Test names should clearly describe what is being tested

## Test Organization

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

## Naming Conventions

### Test Method Names
Use the Given-When-Then pattern or descriptive names:

```swift
// Pattern 1: Given-When-Then
func testGivenValidFoodInput_WhenParsing_ThenReturnsNutritionData()

// Pattern 2: Descriptive
func testNavigateToNextScreen_FromOpening_GoesToLifeSnapshot()

// Pattern 3: Function_Condition_ExpectedBehavior
func testProcessTranscription_WithEmptyText_ReturnsNoFood()
```

### Test Class Names
- Unit tests: `[ClassUnderTest]Tests`
- UI tests: `[Feature]UITests` or `[Flow]UITests`
- Integration tests: `[Feature]IntegrationTests`

## Unit Testing

### Basic Structure (AAA Pattern)
```swift
func testExample() {
    // Arrange - Set up test data and dependencies
    let viewModel = createViewModel()
    let expectedResult = "Expected"
    
    // Act - Execute the code under test
    let result = viewModel.performAction()
    
    // Assert - Verify the outcome
    XCTAssertEqual(result, expectedResult)
}
```

### Testing ViewModels
```swift
@MainActor
class OnboardingViewModelTests: XCTestCase {
    var viewModel: OnboardingViewModel!
    var mockAIService: MockAIService!
    var mockModelContainer: ModelContainer!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // In-memory SwiftData for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        mockModelContainer = try ModelContainer(
            for: User.self, OnboardingProfile.self,
            configurations: config
        )
        
        mockAIService = MockAIService()
        viewModel = OnboardingViewModel(
            aiService: mockAIService,
            modelContext: mockModelContainer.mainContext
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockAIService = nil
        mockModelContainer = nil
        try super.tearDownWithError()
    }
}
```

### Testing Async Code
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

## UI Testing

### Page Object Pattern
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

### UI Test Example
```swift
class OnboardingFlowUITests: XCTestCase {
    var app: XCUIApplication!
    var onboardingPage: OnboardingPage!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments += ["-UITesting"]
        app.launch()
        
        onboardingPage = OnboardingPage(app: app)
    }
    
    func testCompleteOnboardingFlow() throws {
        // Verify initial state
        onboardingPage.verifyOnOpeningScreen()
        
        // Navigate through flow
        onboardingPage.tapBegin()
        
        // Wait for next screen
        let nextScreen = app.staticTexts["lifeSnapshot.title"]
        XCTAssertTrue(nextScreen.waitForExistence(timeout: 5))
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
    }
}
```

## Mock Strategy

### Protocol-Based Mocking
```swift
// Protocol
protocol AIServiceProtocol {
    func generateResponse(prompt: String) async throws -> String
}

// Mock Implementation
class MockAIService: AIServiceProtocol {
    // Control properties
    var generateResponseCalled = false
    var generateResponseCallCount = 0
    var generateResponsePrompt: String?
    var generateResponseResult: Result<String, Error> = .success("Mock response")
    
    func generateResponse(prompt: String) async throws -> String {
        generateResponseCalled = true
        generateResponseCallCount += 1
        generateResponsePrompt = prompt
        
        switch generateResponseResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}
```

### Mock Base Protocol
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

## Code Coverage

### Target Coverage
- Critical business logic: 80-90%
- ViewModels: 70-80%
- Services: 80-90%
- Utilities: 90%+
- UI Views: Focus on UI tests instead

### Enabling Coverage
1. Edit the test plan (`.xctestplan`)
2. Enable "Code Coverage" in configurations
3. Run tests with coverage: `xcodebuild test -enableCodeCoverage YES`

### Viewing Coverage
- In Xcode: Product → Show Build Folder → Coverage
- Command line: `xcrun llvm-cov report`

## CI Integration

### Pre-commit Checks
```bash
# Run before committing
swift test
swiftlint --strict
```

### CI Pipeline Requirements
- All tests must pass
- Code coverage must meet minimums
- No SwiftLint violations
- Build must succeed for all targets

### Test Stability
- Avoid timing-dependent tests
- Use proper async/await patterns
- Mock external dependencies
- Use in-memory databases

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

## Best Practices

### Do's
- ✅ Write tests for edge cases
- ✅ Use descriptive assertion messages
- ✅ Test both success and failure paths
- ✅ Keep tests focused and small
- ✅ Use proper setup/teardown
- ✅ Mock external dependencies

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

## Running Tests

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

## Continuous Improvement

- Review test failures in PR comments
- Update tests when requirements change
- Refactor tests when they become brittle
- Share testing utilities across modules
- Document complex test scenarios