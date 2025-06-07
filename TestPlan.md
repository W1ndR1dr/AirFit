# AirFit Test Recovery Plan

## Current State (2025-06-05)
- Main app builds successfully ✅
- Test suite has 162 Swift 6 concurrency errors
- 55 test files with valuable coverage

## Priority Test Categories

### Phase 1: Critical Business Logic (Run Today)
These tests prevent regressions in core functionality:

1. **Nutrition Parsing** (CRITICAL - prevents 100-calorie bug)
   - NutritionParsingRegressionTests
   - NutritionParsingExtensiveTests
   - AINutritionParsingTests

2. **Core Models & Data**
   - UserModelTests
   - FoodEntry tests
   - Workout model tests

3. **Essential Services**
   - HealthKitManagerTests
   - CoachEngine core functionality
   - ConversationManager basics

### Phase 2: Integration Tests (This Week)
Once Phase 1 passes:
- PersonaGenerationTests
- OnboardingFlowTests
- FoodTrackingIntegrationTests

### Phase 3: UI & Secondary Tests (Next Sprint)
- ViewModel tests
- Coordinator tests
- Mock verification tests

## Execution Strategy

### Step 1: Create Minimal Test Target
Create AirFitCoreTests target with only Phase 1 tests, fixing concurrency issues as we go.

### Step 2: Fix Tests Incrementally
For each test file:
1. Add @MainActor to test class
2. Remove async from setUp/tearDown where possible
3. Use synchronous setup, async in test methods
4. Fix actor isolation errors

### Step 3: Expand Coverage
Once core tests pass, gradually add Phase 2 and 3 tests.

## Success Metrics
- [ ] Zero regression in nutrition calculations
- [ ] Persona generation under 3 seconds
- [ ] All HealthKit operations tested
- [ ] CI/CD can run core tests

## Test Fixing Patterns

### Pattern 1: Actor Isolation
```swift
// Bad
func testSomething() {
    let viewModel = DashboardViewModel()
}

// Good
@MainActor
func testSomething() {
    let viewModel = DashboardViewModel()
}
```

### Pattern 2: Async Setup
```swift
// Bad
override func setUp() async throws {
    try await super.setUp()
    // async setup
}

// Good
override func setUpWithError() throws {
    try super.setUpWithError()
    // sync setup
}

func testSomething() async throws {
    // async work here
}
```

### Pattern 3: Mock Creation
```swift
// Bad
let mock = MockService() // If MockService is @MainActor

// Good
@MainActor
func testWithMock() {
    let mock = MockService()
}
```

## Disabled Tests Tracking
Track which tests are temporarily disabled and why:
- [ ] OnboardingPerformanceTests - Heavy async operations
- [ ] ServiceIntegrationTests - Uses deprecated APIs
- [ ] UITests - Not critical path

This pragmatic approach gets us testing quickly while preserving the option to expand coverage.