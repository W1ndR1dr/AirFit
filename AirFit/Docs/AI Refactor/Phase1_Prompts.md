# Phase 1 Prompt Chain: Nutrition System Refactor

**Target Agent Environment:** Sandboxed Codex (No Xcode Available)  
**Execution Priority:** Phase 1 - HIGHEST PRIORITY  
**Parent Document:** `Phase1_NutritionSystem_Refactor.md`

## Executive Summary

This prompt chain breaks down the Nutrition System Refactor into discrete, manageable tasks for sandboxed Codex agents. The core issue: **current parsing returns 100 calories for everything** - this is broken placeholder code that needs replacing with proper AI-driven nutrition parsing.

**Total Estimated Time:** 12-16 hours across 8 sequential tasks
**Success Criteria:** Real nutrition data instead of hardcoded 100-calorie placeholders

---

## Task Execution Order & Parallelization

### 🔴 **SEQUENTIAL TASKS (Must run in order)**
1. **Task 1:** Codebase Analysis & Documentation 
2. **Task 2:** AI Nutrition Parsing Implementation
3. **Task 3:** FoodTrackingViewModel Refactor
4. **Task 4:** Error Handling & Protocol Updates
5. **Task 5:** Integration & Cleanup
6. **Task 8:** Final Integration Testing

### 🟢 **PARALLELIZABLE TASKS (Can run simultaneously after Task 4)**
- **Task 6:** Unit Test Implementation
- **Task 7:** Performance & Regression Testing

---

## Task 1: Codebase Analysis & Documentation
**Duration:** 2-3 hours  
**Dependencies:** None  
**Agent Focus:** Analysis and documentation

### Prompt

```markdown
You are a senior iOS engineer analyzing the AirFit nutrition parsing system for a critical refactor. Your task is to analyze the broken nutrition parsing code and create comprehensive documentation for the refactor.

## Primary Objective
Analyze the current nutrition parsing disaster in `FoodTrackingViewModel.swift` and document the exact problems for replacement with AI-driven parsing.

## Key Files to Analyze
1. `AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift`
2. `AirFit/Modules/AI/CoachEngine.swift` 
3. `AirFit/Modules/FoodTracking/Models/FoodTrackingModels.swift`
4. `AirFit/Modules/FoodTracking/Services/NutritionService.swift`

## Analysis Requirements

### 1. Document Broken Methods
Find and document these specific broken methods:
- `parseLocalCommand(_:)` - Should return hardcoded 100 calories
- `parseSimpleFood(_:)` - Should do the same terrible job
- `parseWithLocalFallback(_:)` - Should chain these broken methods

For each method, document:
- Current implementation approach
- Hardcoded values used
- Why it fails to provide real nutrition data
- Estimated lines of code to remove

### 2. Document Current Flow
Map the exact flow from voice transcription to nutrition parsing:
1. `processTranscription()` entry point
2. Method call chain 
3. Where hardcoded 100-calorie values are returned
4. How this impacts user experience

### 3. Identify What to Keep
Document the `NutritionService` database operations that work correctly:
- `getFoodEntries()` - SwiftData queries
- `calculateNutritionSummary()` - Math operations
- `saveFoodEntry()` - Persistence
- Water intake tracking

### 4. Create Implementation Plan
Document the replacement strategy:
- New `parseNaturalLanguageFood()` method in CoachEngine
- Integration points with existing FoodTrackingViewModel
- Error handling requirements
- Fallback strategies for AI failures

## Validation Commands
```bash
# Verify Swift syntax without building iOS project
find AirFit -name "*.swift" -exec swift -frontend -parse {} \; 2>&1 | grep -E "error|warning" || echo "✅ Swift syntax validation passed"

# Check for hardcoded nutrition values
grep -r "calories: 100" AirFit/Modules/FoodTracking/ || echo "No hardcoded 100-calorie values found"
```

## Deliverables
1. **Analysis Report:** `PHASE1_ANALYSIS.md` with complete documentation
2. **Code Inventory:** List of all methods to remove/modify
3. **Implementation Roadmap:** Step-by-step replacement strategy
4. **Risk Assessment:** Potential integration challenges

The analysis must be thorough enough that subsequent agents can implement the refactor without needing to re-analyze the codebase.
```

---

## Task 2: AI Nutrition Parsing Implementation
**Duration:** 3-4 hours  
**Dependencies:** Task 1 complete  
**Agent Focus:** Core AI parsing logic

### Prompt

```markdown
You are implementing the core AI nutrition parsing functionality that will replace the broken hardcoded nutrition system in AirFit.

## Primary Objective
Implement `parseNaturalLanguageFood()` method in CoachEngine with intelligent fallbacks and comprehensive error handling.

## Implementation Requirements

### 1. Core Method Implementation
Create in `AirFit/Modules/AI/CoachEngine.swift`:

```swift
public func parseNaturalLanguageFood(
    text: String,
    mealType: MealType,
    for user: User
) async throws -> [ParsedFoodItem]
```

**Requirements:**
- Use low temperature (0.1) for consistent nutrition data
- Include comprehensive validation of AI responses
- Implement intelligent fallback for AI failures
- Target <3 seconds response time
- Log performance metrics with AppLogger

### 2. AI Prompt Engineering
Design prompts that:
- Request structured JSON responses only
- Include USDA nutrition database accuracy requirements
- Handle multiple food items in single input
- Estimate quantities when not specified
- Return realistic confidence scores

### 3. Response Validation
Implement `validateNutritionValues()` that rejects:
- Calories outside 0-5000 range
- Protein outside 0-300g range  
- Carbs outside 0-1000g range
- Fat outside 0-500g range

### 4. Intelligent Fallback
Create `createFallbackFoodItem()` with:
- Basic food name extraction from input text
- Meal-type appropriate calorie defaults:
  - Breakfast: 250 calories
  - Lunch: 400 calories  
  - Dinner: 500 calories
  - Snack: 150 calories
- Reasonable macro distribution (15% protein, 50% carbs, 35% fat)
- Low confidence score (0.3) to indicate fallback

## Required Error Types
Add to `FoodTrackingModels.swift`:
```swift
case invalidNutritionResponse
case invalidNutritionData
```

## Validation Commands
```bash
# Validate Swift syntax
swift -frontend -parse AirFit/Modules/AI/CoachEngine.swift

# Check for proper error handling
grep -E "do.*catch|throw.*Error" AirFit/Modules/AI/CoachEngine.swift || echo "⚠️ Missing error handling"

# Verify logging implementation
grep "AppLogger" AirFit/Modules/AI/CoachEngine.swift || echo "⚠️ Missing logging"
```

## Deliverables
1. **Complete CoachEngine implementation** with parseNaturalLanguageFood method
2. **Error type definitions** in FoodTrackingModels
3. **JSON parsing utilities** for AI responses
4. **Validation functions** for nutrition data
5. **Performance logging** implementation

The implementation must handle all edge cases and provide reliable fallbacks when AI parsing fails.
```

---

## Task 3: FoodTrackingViewModel Refactor  
**Duration:** 2-3 hours  
**Dependencies:** Task 2 complete  
**Agent Focus:** ViewModel integration and cleanup

### Prompt

```markdown
You are refactoring the FoodTrackingViewModel to replace the broken local parsing methods with the new AI-driven nutrition parsing.

## Primary Objective
Replace the entire broken parsing chain in `FoodTrackingViewModel.swift` with a single AI call and remove 150+ lines of terrible code.

## Specific Changes Required

### 1. Replace processTranscription() Method
Current broken flow to replace:
```swift
parseLocalCommand() -> parseWithLocalFallback() -> parseSimpleFood()
```

New simplified flow:
```swift
coachEngine.parseNaturalLanguageFood() -> confirmation screen
```

### 2. Methods to DELETE ENTIRELY
Remove these broken methods (~150 lines):
- `parseLocalCommand(_:)` - Returns hardcoded 100 calories
- `parseWithLocalFallback(_:)` - Chains broken methods  
- `parseSimpleFood(_:)` - Same hardcoded garbage
- Any helper methods used only by these functions

### 3. Updated processTranscription Implementation
```swift
private func processTranscription() async {
    guard !transcribedText.isEmpty else { return }

    isProcessingAI = true
    defer { isProcessingAI = false }

    do {
        let aiParsedItems = try await coachEngine.parseNaturalLanguageFood(
            text: transcribedText,
            mealType: selectedMealType,
            for: user
        )

        self.parsedItems = aiParsedItems

        if !parsedItems.isEmpty {
            coordinator.showFullScreenCover(.confirmation(parsedItems))
        } else {
            setError(FoodTrackingError.noFoodFound)
        }

    } catch {
        setError(error)
        AppLogger.error("Failed to process nutrition with AI", error: error, category: .ai)
    }
}
```

### 4. Preserve Working Code
Keep these methods unchanged (they work correctly):
- All coordinator navigation methods
- UI state management
- Error handling infrastructure
- Speech recognition integration

## Validation Commands
```bash
# Verify ViewModel compiles
swift -frontend -parse AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift

# Confirm broken methods are removed
grep -E "parseLocalCommand|parseSimpleFood|parseWithLocalFallback" AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift && echo "❌ Broken methods still present" || echo "✅ Broken methods removed"

# Check for proper error handling
grep -E "do.*catch.*Error" AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift || echo "⚠️ Missing error handling"
```

## Deliverables
1. **Refactored FoodTrackingViewModel** with simplified parsing
2. **Removed broken methods** (~150 lines deleted)
3. **Updated processTranscription** using AI parsing
4. **Preserved working functionality** (navigation, state management)
5. **Error handling integration** for AI parsing failures

The refactor must maintain all existing UI functionality while replacing the broken parsing with working AI-driven nutrition data.
```

---

## Task 4: Error Handling & Protocol Updates
**Duration:** 1-2 hours  
**Dependencies:** Task 3 complete  
**Agent Focus:** Protocol compliance and error handling

### Prompt

```markdown
You are updating the protocol definitions and error handling to support the new AI nutrition parsing system.

## Primary Objective
Update `FoodCoachEngineProtocol` and error handling to properly integrate the new AI parsing functionality.

## Protocol Updates Required

### 1. Update FoodCoachEngineProtocol
Add to `AirFit/Modules/FoodTracking/Services/FoodCoachEngineProtocol.swift`:

```swift
/// Parse natural language food input into structured nutrition data
func parseNaturalLanguageFood(
    text: String,
    mealType: MealType,
    for user: User
) async throws -> [ParsedFoodItem]
```

### 2. Complete Error Handling
Ensure `FoodTrackingError` in `FoodTrackingModels.swift` includes:
```swift
case invalidNutritionResponse
case invalidNutritionData
case aiParsingFailed
case nutritionValidationFailed

var errorDescription: String? {
    switch self {
    case .invalidNutritionResponse:
        return "Invalid nutrition data from AI"
    case .invalidNutritionData:
        return "Malformed nutrition information"
    case .aiParsingFailed:
        return "Unable to parse nutrition information"
    case .nutritionValidationFailed:
        return "Nutrition values failed validation"
    }
}
```

### 3. Mock Protocol Implementation
Create or update mock implementation for testing:
```swift
extension MockFoodCoachEngine: FoodCoachEngineProtocol {
    func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
        // Return realistic test data
    }
}
```

## Validation Commands
```bash
# Verify protocol compiles
swift -frontend -parse AirFit/Modules/FoodTracking/Services/FoodCoachEngineProtocol.swift

# Check error types are complete
grep -E "invalidNutritionResponse|invalidNutritionData" AirFit/Modules/FoodTracking/Models/FoodTrackingModels.swift || echo "⚠️ Missing error types"

# Verify protocol conformance
grep -A 10 "parseNaturalLanguageFood" AirFit/Modules/FoodTracking/Services/FoodCoachEngineProtocol.swift || echo "⚠️ Protocol method missing"
```

## Deliverables
1. **Updated protocol definition** with new AI parsing method
2. **Complete error type definitions** with user-friendly messages  
3. **Mock implementation** for testing support
4. **Protocol conformance verification** for CoachEngine

All protocol updates must maintain backward compatibility while adding the new AI parsing functionality.
```

---

## Task 5: Integration & Cleanup
**Duration:** 1-2 hours  
**Dependencies:** Task 4 complete  
**Agent Focus:** Final integration and code cleanup

### Prompt

```markdown
You are performing final integration of the AI nutrition parsing system and cleaning up any remaining broken code references.

## Primary Objective
Ensure complete integration of AI parsing, remove all references to broken methods, and verify the refactor is complete.

## Integration Tasks

### 1. Remove Dead Code References
Search for and remove any remaining references to deleted methods:
- `parseLocalCommand`
- `parseSimpleFood` 
- `parseWithLocalFallback`
- Any imports or dependencies only used by these methods

### 2. Verify CoachEngine Integration
Ensure `CoachEngine` properly conforms to `FoodCoachEngineProtocol`:
```swift
extension CoachEngine: FoodCoachEngineProtocol {
    // Verify parseNaturalLanguageFood implementation is included
}
```

### 3. Update Documentation Comments
Add comprehensive documentation for the new AI parsing method:
```swift
/// Parse natural language food descriptions into structured nutrition data using AI
/// 
/// This method replaces the previous hardcoded parsing system that returned
/// placeholder values (100 calories for everything). Now provides realistic
/// nutrition data based on USDA standards.
///
/// - Parameters:
///   - text: Natural language food description (e.g., "2 eggs and toast")
///   - mealType: Context for calorie estimation defaults
///   - user: User profile for personalized parsing
/// - Returns: Array of parsed food items with realistic nutrition values
/// - Throws: FoodTrackingError if parsing fails completely
```

### 4. Clean Up Imports
Remove any unused imports from files that previously used the broken parsing methods.

## Validation Commands
```bash
# Search for any remaining broken method references
grep -r "parseLocalCommand\|parseSimpleFood\|parseWithLocalFallback" AirFit/Modules/FoodTracking/ && echo "❌ Found broken method references" || echo "✅ No broken method references found"

# Verify integration compiles
find AirFit/Modules/FoodTracking -name "*.swift" -exec swift -frontend -parse {} \; 2>&1 | grep -E "error:" || echo "✅ Integration compiles successfully"

# Check for unused imports
grep -E "^import" AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift
```

## Deliverables
1. **Clean codebase** with no references to broken methods
2. **Complete protocol conformance** for CoachEngine
3. **Updated documentation** for all new methods
4. **Verified compilation** of all modified files
5. **Integration verification** report

The integration must be seamless with no broken references or compilation errors.
```

---

## Task 6: Unit Test Implementation (PARALLELIZABLE)
**Duration:** 3-4 hours  
**Dependencies:** Task 4 complete  
**Agent Focus:** Comprehensive test coverage

### Prompt

```markdown
You are implementing comprehensive unit tests for the new AI nutrition parsing system to ensure reliability and catch regressions.

## Primary Objective
Create thorough test coverage for the AI nutrition parsing functionality, focusing on accuracy, performance, and error handling.

## Test Files to Create/Update

### 1. Core Parsing Tests
Create `AirFitTests/FoodTracking/NutritionParsingTests.swift`:

**Test Categories:**
- Common food accuracy validation
- Multiple item parsing
- Performance benchmarks (<3 seconds)
- Error handling and fallback scenarios
- Edge cases (empty input, malformed text)

**Example Test Structure:**
```swift
func test_nutritionParsing_commonFoods_accurateValues() async throws {
    let testCases: [(input: String, expectedCalories: Range<Int>)] = [
        ("1 large apple", 90...110),
        ("2 slices whole wheat bread", 140...180),
        ("6 oz grilled chicken breast", 250...300),
        ("1 cup brown rice", 210...250),
        ("1 tablespoon olive oil", 110...130)
    ]
    
    for testCase in testCases {
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: testCase.input,
            mealType: .lunch,
            for: testUser
        )
        
        XCTAssertEqual(result.count, 1)
        let calories = result.first?.calories ?? 0
        XCTAssertTrue(
            testCase.expectedCalories.contains(calories),
            "Calories \(calories) not in range \(testCase.expectedCalories) for: \(testCase.input)"
        )
    }
}
```

### 2. FoodTrackingViewModel Tests
Update `AirFitTests/FoodTracking/FoodTrackingViewModelTests.swift`:

**New Tests:**
- `test_processTranscription_aiParsingSuccess_showsConfirmation()`
- `test_processTranscription_aiParsingFailure_showsError()`
- `test_processTranscription_emptyText_noProcessing()`
- `test_processTranscription_performanceUnder3Seconds()`

### 3. Mock Implementation Tests
Create comprehensive mocks that return realistic test data:
```swift
class MockFoodCoachEngine: FoodCoachEngineProtocol {
    func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
        // Return realistic mock data based on input
    }
}
```

## Validation Commands
```bash
# Verify test files compile
find AirFitTests -name "*NutritionParsing*" -exec swift -frontend -parse {} \;

# Check test coverage for new methods
grep -E "parseNaturalLanguageFood" AirFitTests/FoodTracking/*.swift || echo "⚠️ Missing test coverage"

# Validate mock implementations
grep -E "MockFoodCoachEngine" AirFitTests/Mocks/*.swift || echo "⚠️ Missing mock implementations"
```

## Deliverables
1. **NutritionParsingTests.swift** with comprehensive test coverage
2. **Updated FoodTrackingViewModelTests** for new AI integration
3. **Realistic mock implementations** for consistent testing
4. **Performance benchmarks** ensuring <3 second target
5. **Error scenario tests** validating fallback behavior

All tests must pass and provide meaningful validation of the AI nutrition parsing functionality.
```

---

## Task 7: Performance & Regression Testing (PARALLELIZABLE)
**Duration:** 2-3 hours  
**Dependencies:** Task 4 complete  
**Agent Focus:** Performance validation and regression prevention

### Prompt

```markdown
You are implementing performance benchmarks and regression tests to ensure the AI nutrition parsing meets quality standards and doesn't break existing functionality.

## Primary Objective
Create comprehensive performance tests and regression prevention for the nutrition parsing refactor.

## Performance Test Requirements

### 1. Response Time Benchmarks
Create `AirFitTests/Performance/NutritionParsingPerformanceTests.swift`:

**Key Metrics:**
- Single food parsing: <3 seconds
- Multiple food parsing: <5 seconds  
- Batch processing: <10 seconds for 10 items
- Memory usage: <50MB increase during parsing

**Test Implementation:**
```swift
func test_nutritionParsing_performance_under3Seconds() async throws {
    let inputs = [
        "grilled salmon with quinoa and vegetables",
        "protein shake with banana and peanut butter",
        "chicken caesar salad with croutons"
    ]
    
    for input in inputs {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        _ = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .dinner,
            for: testUser
        )
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(duration, 3.0, "Parsing '\(input)' took \(duration)s, exceeds 3s limit")
    }
}
```

### 2. Accuracy Regression Tests  
Create baseline accuracy tests that must continue passing:
```swift
func test_nutritionParsing_accuracy_regression() async throws {
    let baselineTests = [
        ("1 medium banana", 95...105, "calories"),
        ("2 tbsp olive oil", 240...260, "calories"),
        ("6oz chicken breast", 25...35, "protein_grams")
    ]
    
    // Validate nutrition values are realistic, not hardcoded placeholders
}
```

### 3. Memory and Resource Tests
Monitor resource usage during parsing:
```swift
func test_nutritionParsing_memoryUsage() async throws {
    let beforeMemory = getMemoryUsage()
    
    // Parse multiple complex food descriptions
    for i in 0..<20 {
        _ = try await coachEngine.parseNaturalLanguageFood(
            text: "complex meal with multiple ingredients",
            mealType: .dinner,
            for: testUser
        )
    }
    
    let afterMemory = getMemoryUsage()
    let memoryIncrease = afterMemory - beforeMemory
    
    XCTAssertLessThan(memoryIncrease, 50_000_000, "Memory increase \(memoryIncrease) bytes exceeds 50MB limit")
}
```

## Regression Prevention

### 1. API Contract Tests
Ensure the new system maintains expected interfaces:
```swift
func test_foodTrackingViewModel_apiContractMaintained() {
    // Verify public interface hasn't changed
    XCTAssertTrue(sut.responds(to: #selector(processTranscription)))
    XCTAssertNotNil(sut.parsedItems)
    XCTAssertNotNil(sut.coordinator)
}
```

### 2. Error Handling Regression
Verify error scenarios work correctly:
```swift  
func test_nutritionParsing_errorHandling_regression() async {
    // Test various error conditions
    // Verify fallback mechanisms work
    // Ensure UI shows appropriate error messages
}
```

## Validation Commands
```bash
# Verify performance test files compile
find AirFitTests/Performance -name "*.swift" -exec swift -frontend -parse {} \;

# Check for performance benchmarks
grep -E "CFAbsoluteTimeGetCurrent|XCTAssertLessThan.*3\.0" AirFitTests/Performance/*.swift || echo "⚠️ Missing performance benchmarks"

# Validate memory usage tests
grep -E "getMemoryUsage|Memory.*MB" AirFitTests/Performance/*.swift || echo "⚠️ Missing memory tests"
```

## Deliverables
1. **Performance benchmark tests** with specific time limits
2. **Memory usage monitoring** with defined limits
3. **Accuracy regression tests** preventing quality degradation  
4. **API contract tests** ensuring interface stability
5. **Error handling validation** for all failure scenarios

All performance tests must validate the system meets the <3 second target and doesn't regress existing functionality.
```

---

## Task 8: Final Integration Testing
**Duration:** 1-2 hours  
**Dependencies:** All previous tasks complete  
**Agent Focus:** End-to-end validation

### Prompt

```markdown
You are performing final end-to-end integration testing to validate the complete AI nutrition parsing refactor is working correctly.

## Primary Objective
Conduct comprehensive integration testing to ensure the refactor achieves the success criteria: real nutrition data instead of hardcoded 100-calorie placeholders.

## Integration Test Requirements

### 1. End-to-End Flow Validation
Create `AirFitTests/Integration/NutritionParsingIntegrationTests.swift`:

**Complete User Flow Testing:**
```swift
func test_endToEnd_voiceToNutrition_realData() async throws {
    // 1. User speaks food description
    sut.transcribedText = "I had a grilled chicken salad with olive oil dressing"
    
    // 2. Process transcription (triggers AI parsing)
    await sut.processTranscription()
    
    // 3. Verify real nutrition data (not 100-calorie placeholder)
    XCTAssertFalse(sut.isProcessingAI)
    XCTAssertGreaterThan(sut.parsedItems.count, 0)
    
    let totalCalories = sut.parsedItems.reduce(0) { $0 + $1.calories }
    XCTAssertGreaterThan(totalCalories, 200, "Should have realistic calories, not hardcoded 100")
    XCTAssertLessThan(totalCalories, 800, "Should not be unrealistically high")
    
    // 4. Verify coordination to confirmation screen
    XCTAssertEqual(mockCoordinator.didShowFullScreenCover, .confirmation(sut.parsedItems))
}
```

### 2. Data Quality Validation
Test that real nutrition data is returned:
```swift
func test_nutritionQuality_realDataNotPlaceholders() async throws {
    let testFoods = [
        "1 apple",
        "slice of pizza", 
        "protein bar",
        "cup of coffee with milk"
    ]
    
    for food in testFoods {
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: food,
            mealType: .snack,
            for: testUser
        )
        
        // Verify not hardcoded 100 calories for everything
        let calories = result.first?.calories ?? 0
        XCTAssertNotEqual(calories, 100, "Food '\(food)' returned placeholder 100 calories")
        XCTAssertGreaterThan(calories, 0, "Food '\(food)' should have positive calories")
        
        // Verify realistic nutrition values
        let protein = result.first?.proteinGrams ?? 0
        XCTAssertNotEqual(protein, 5.0, "Food '\(food)' returned placeholder 5g protein")
    }
}
```

### 3. Error Recovery Testing
Validate fallback mechanisms work:
```swift
func test_integration_errorRecovery() async throws {
    // Test with problematic input that might cause AI failures
    sut.transcribedText = "xyz invalid food gibberish 123"
    
    await sut.processTranscription()
    
    // Should either parse successfully or show appropriate error
    if sut.parsedItems.isEmpty {
        // Verify error was set and user sees feedback
        XCTAssertNotNil(sut.currentError)
    } else {
        // Verify fallback provided reasonable values
        let fallbackItem = sut.parsedItems.first!
        XCTAssertLessThan(fallbackItem.confidence, 0.5, "Low confidence should indicate fallback")
    }
}
```

### 4. Performance Integration
Validate complete flow meets performance targets:
```swift
func test_integration_performanceTarget() async throws {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    sut.transcribedText = "grilled salmon with quinoa and steamed vegetables"
    await sut.processTranscription()
    
    let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
    XCTAssertLessThan(totalDuration, 3.0, "Complete voice-to-nutrition flow should complete under 3 seconds")
}
```

## Success Criteria Validation

### Before/After Comparison
Document the improvement:
```swift
func test_successCriteria_realNutritionData() async throws {
    // BEFORE: Everything returned 100 calories
    // AFTER: Real nutrition values based on actual food
    
    let apple = try await coachEngine.parseNaturalLanguageFood(
        text: "1 medium apple",
        mealType: .snack,
        for: testUser
    )
    
    let pizza = try await coachEngine.parseNaturalLanguageFood(
        text: "1 slice pepperoni pizza",
        mealType: .lunch,
        for: testUser
    )
    
    // Verify different foods have different calories (not hardcoded 100)
    XCTAssertNotEqual(apple.first?.calories, pizza.first?.calories, 
                     "Different foods should have different nutrition values")
    
    // Verify realistic ranges
    XCTAssertTrue((80...120).contains(apple.first?.calories ?? 0), "Apple should have ~95 calories")
    XCTAssertTrue((250...350).contains(pizza.first?.calories ?? 0), "Pizza should have ~300 calories")
}
```

## Validation Commands
```bash
# Verify all integration tests compile
swift -frontend -parse AirFitTests/Integration/NutritionParsingIntegrationTests.swift

# Check for hardcoded values that should be eliminated
grep -r "calories: 100" AirFit/Modules/FoodTracking/ && echo "❌ Found hardcoded 100-calorie values" || echo "✅ No hardcoded values found"

# Final compilation check for all modified files
find AirFit/Modules/FoodTracking AirFit/Modules/AI -name "*.swift" -exec swift -frontend -parse {} \; 2>&1 | grep -E "error:" || echo "✅ All files compile successfully"
```

## Deliverables
1. **Complete integration test suite** validating end-to-end functionality
2. **Data quality verification** ensuring real nutrition values
3. **Error recovery validation** for robust user experience
4. **Performance integration testing** meeting <3 second target
5. **Success criteria confirmation** documenting the improvement

The integration testing must confirm that users now receive realistic nutrition data instead of the previous hardcoded 100-calorie placeholders.
```

---

## Post-Phase Validation & Audit

After all tasks complete, run comprehensive validation:

```bash
# Verify no broken method references remain
grep -r "parseLocalCommand\|parseSimpleFood\|parseWithLocalFallback" AirFit/ || echo "✅ All broken methods removed"

# Confirm Swift compilation
find AirFit -name "*.swift" -exec swift -frontend -parse {} \; 2>&1 | grep -E "error:" || echo "✅ All Swift files compile"

# Validate test coverage
find AirFitTests -name "*Nutrition*" -type f | wc -l | xargs echo "Test files created:"

# Check for performance logging
grep -r "AppLogger.*nutrition.*parsing" AirFit/ || echo "⚠️ Missing performance logging"
```

**SUCCESS METRICS:**
- ✅ 150+ lines of broken parsing code removed
- ✅ Real nutrition data instead of hardcoded 100 calories
- ✅ <3 second voice-to-nutrition parsing
- ✅ Comprehensive test coverage
- ✅ No compilation errors or broken references

This prompt chain ensures systematic, verifiable replacement of the broken nutrition parsing system with working AI-driven functionality. 