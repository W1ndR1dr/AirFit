# AirFit Test Structure

## Overview
This document describes the test organization and patterns used in the AirFit test suite after the recent DI migration and nutrition parsing fixes.

## Key Testing Patterns

### 1. MockCoachEngine
The main mock for nutrition parsing tests. Located in `/Mocks/MockCoachEngine.swift`:
- Implements both `CoachEngineProtocol` and `FoodCoachEngineProtocol`
- Provides `mockParsedItems` array for setting up test data
- Supports error simulation with `shouldThrowError`
- Handles fallback scenarios based on meal type

### 2. Test Setup Pattern
```swift
@MainActor
final class NutritionParsingTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var coachEngine: MockCoachEngine!
    private var testUser: User!
    
    override func setUp() async throws {
        // Create in-memory model container
        let schema = Schema([User.self, FoodEntry.self, FoodItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Initialize mock coach engine
        coachEngine = MockCoachEngine()
    }
}
```

### 3. Nutrition Data Setup
Helper functions for setting up realistic nutrition data:
```swift
private func setupRealisticNutrition(for food: String) {
    let foodLower = food.lowercased()
    switch true {
    case foodLower.contains("apple"):
        coachEngine.mockParsedItems = [
            ParsedFoodItem(name: "apple", brand: nil, quantity: 1.0, unit: "medium",
                          calories: 95, proteinGrams: 0.5, carbGrams: 25.0, fatGrams: 0.3,
                          fiberGrams: 4.0, sugarGrams: 19.0, sodiumMilligrams: 2.0, 
                          databaseId: nil, confidence: 0.95)
        ]
    // ... more cases
    }
}
```

## Test Categories

### 1. Integration Tests
- `NutritionParsingIntegrationTests.swift` - End-to-end flow validation
- `AINutritionParsingIntegrationTests.swift` - AI integration testing

### 2. Performance Tests
- `NutritionParsingPerformanceTests.swift` - Ensures <3 second response times
- Memory usage validation (<50MB increase)

### 3. Regression Tests
- `NutritionParsingRegressionTests.swift` - Prevents regression to 100-calorie bug
- Validates nutrition variety and realistic values

### 4. Unit Tests
- `AINutritionParsingTests.swift` - Basic parsing functionality
- `NutritionParsingExtensiveTests.swift` - Comprehensive edge cases

## Key Test Scenarios

### 1. 100-Calorie Bug Prevention
Every nutrition test includes validation that foods don't return hardcoded 100 calories:
```swift
XCTAssertNotEqual(calories, 100, "Should not return hardcoded 100 calories")
```

### 2. Realistic Nutrition Values
Tests verify:
- Different foods have different calorie values
- Macros are not hardcoded (5g protein, 15g carbs, 3g fat)
- Nutrition values match food types (apple ~95 cal, pizza ~285 cal)

### 3. Fallback Behavior
When AI fails or input is invalid:
- Returns meal-type appropriate calories
- Low confidence (0.3)
- Reasonable macro distribution

### 4. Performance Requirements
- Simple foods parse in <1 second
- Complex meals parse in <3 seconds
- Batch processing scales linearly

## Mock Services

### Primary Mocks
- `MockCoachEngine` - Main nutrition parsing mock
- `MockFoodVoiceAdapter` - Voice input simulation
- `MockNutritionService` - Nutrition data persistence
- `MockAIService` - AI service simulation

### DI Container Test Setup
Use `DITestHelper.createTestContainer()` for full DI setup in integration tests.

## Common Test Patterns

### 1. Testing Nutrition Parsing
```swift
func test_parseFood() async throws {
    // Setup
    setupRealisticNutrition(for: "apple")
    
    // Act
    let result = try await coachEngine.parseNaturalLanguageFood(
        text: "apple",
        mealType: .snack,
        for: testUser
    )
    
    // Assert
    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result.first?.calories, 95)
    XCTAssertNotEqual(result.first?.calories, 100) // Prevent regression
}
```

### 2. Testing Error Handling
```swift
func test_errorHandling() async throws {
    // Setup
    coachEngine.shouldThrowError = true
    coachEngine.errorToThrow = FoodTrackingError.aiParsingFailed
    
    // Act & Assert
    do {
        _ = try await coachEngine.parseNaturalLanguageFood(...)
        XCTFail("Expected error")
    } catch {
        XCTAssertTrue(error is FoodTrackingError)
    }
}
```

### 3. Testing Performance
```swift
func test_performance() async throws {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    _ = try await coachEngine.parseNaturalLanguageFood(...)
    
    let duration = CFAbsoluteTimeGetCurrent() - startTime
    XCTAssertLessThan(duration, 3.0)
}
```

## Running Tests

```bash
# Run all nutrition parsing tests
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' \
  -only-testing:AirFitTests/NutritionParsingIntegrationTests \
  -only-testing:AirFitTests/NutritionParsingPerformanceTests \
  -only-testing:AirFitTests/NutritionParsingRegressionTests \
  -only-testing:AirFitTests/NutritionParsingExtensiveTests \
  -only-testing:AirFitTests/AINutritionParsingTests \
  -only-testing:AirFitTests/AINutritionParsingIntegrationTests
```

## Notes

1. All nutrition tests focus on preventing the 100-calorie bug regression
2. MockCoachEngine provides flexible test setup for various scenarios
3. Performance tests ensure <3 second response times
4. Integration tests validate end-to-end flows
5. Regression tests maintain data quality standards