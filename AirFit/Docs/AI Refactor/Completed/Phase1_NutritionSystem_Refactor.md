# Phase 1: Nutrition System Refactor Plan (HIGHEST PRIORITY)

**Parent Document:** `Nutrition_System.md`
**Framework Reference:** `AI_ARCHITECTURE_OPTIMIZATION_FRAMEWORK.md`

## 1. Executive Summary
This phase replaces the embarrassingly bad local nutrition parsing logic with proper AI-driven parsing. The current system uses hardcoded nutrition values (100 calories for everything!) and basic regex patterns. This is the highest-impact, lowest-risk refactor in the entire codebase.

**EXECUTION PRIORITY: Phase 1 - Execute FIRST for immediate user value.**

**Core Changes:**
- Replace `parseLocalCommand()` and `parseSimpleFood()` with direct AI parsing (~150 lines removed)
- Eliminate hardcoded nutrition values (everything currently returns 100 calories)
- Remove duplicate parsing methods that do the same terrible job
- Keep `NutritionService` database operations (they're fine as-is)

**The Problem:** Current parsing returns 100 calories for an apple and 100 calories for a pizza. This is not a complex architectural problem - it's just broken code that needs fixing.

## 2. Goals for Phase 3

1. **Replace Broken Parsing:** Fix the terrible nutrition parsing with AI that actually works
2. **Remove Code Duplication:** Eliminate duplicate methods that do the same bad job
3. **Maintain Data Operations:** Keep working database operations as-is
4. **Improve Accuracy:** Get real nutrition data instead of hardcoded placeholders
5. **Performance Target:** <3 seconds for voice → parsed nutrition results

## 3. Current State Analysis

### What's Actually Broken

**File:** `AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift`

```swift
// This is the current "nutrition parsing" logic:
private func parseLocalCommand(_ text: String) async -> [ParsedFoodItem]? {
    // ... basic regex ...
    return [ParsedFoodItem(
        name: foodName,
        quantity: quantity,
        unit: unit,
        calories: 100, // ← HARDCODED GARBAGE
        proteinGrams: 5, // ← HARDCODED GARBAGE
        carbGrams: 15,   // ← HARDCODED GARBAGE
        fatGrams: 3,     // ← HARDCODED GARBAGE
        confidence: 0.7
    )]
}

// This method does THE EXACT SAME THING:
private func parseSimpleFood(_ text: String) -> [ParsedFoodItem] {
    // ... identical logic with same hardcoded values ...
}
```

**The Current Flow:**
1. `processTranscription()` calls `parseLocalCommand()` 
2. If that "fails" (it always "succeeds" with garbage), it calls `parseWithLocalFallback()`
3. `parseWithLocalFallback()` calls `parseSimpleFood()` 
4. `parseSimpleFood()` returns the same hardcoded 100-calorie garbage

**What Actually Needs to Happen:**
Replace this entire flow with one AI call that returns real nutrition data.

### What's Actually Fine

**`NutritionService` Database Operations:** These are properly implemented and should stay:
- `getFoodEntries()` - SwiftData queries work fine
- `calculateNutritionSummary()` - Simple math, no need for AI
- `saveFoodEntry()` - Basic persistence
- Water intake tracking - Simple value storage

## 4. Implementation Plan

### Step 4.1: Add Real AI Nutrition Parsing

**File:** `AirFit/Modules/AI/CoachEngine.swift`

```swift
// Add proper nutrition parsing method with fallback strategy
public func parseNaturalLanguageFood(
    text: String,
    mealType: MealType,
    for user: User
) async throws -> [ParsedFoodItem] {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    let prompt = buildNutritionParsingPrompt(text: text, mealType: mealType, user: user)
    
    do {
        let response = try await aiService.getResponse(
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.1, // Low temperature for consistent nutrition data
            maxTokens: 600
        )
        
        let result = try parseNutritionJSON(response.content)
        
        // CRITICAL: Validate nutrition values are realistic
        let validatedResult = validateNutritionValues(result)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.info(
            "AI nutrition parsing: \(validatedResult.count) items in \(Int(duration * 1000))ms",
            category: .ai,
            metadata: [
                "input_text": text,
                "items_parsed": validatedResult.count,
                "duration_ms": Int(duration * 1000),
                "validation_passed": validatedResult.allSatisfy { $0.calories > 0 }
            ]
        )
        
        return validatedResult
        
    } catch {
        AppLogger.error("AI nutrition parsing failed", error: error, category: .ai)
        // FALLBACK: Return single estimated item rather than failing completely
        return [createFallbackFoodItem(from: text, mealType: mealType)]
    }
}

// CRITICAL ADDITION: Validate AI returns reasonable values
private func validateNutritionValues(_ items: [ParsedFoodItem]) -> [ParsedFoodItem] {
    return items.compactMap { item in
        // Reject obviously wrong values
        guard item.calories > 0 && item.calories < 5000,
              item.proteinGrams >= 0 && item.proteinGrams < 300,
              item.carbGrams >= 0 && item.carbGrams < 1000,
              item.fatGrams >= 0 && item.fatGrams < 500 else {
            AppLogger.warning("Rejected invalid nutrition values for \(item.name)", category: .ai)
            return nil
        }
        return item
    }
}

// CRITICAL ADDITION: Intelligent fallback for AI failures
private func createFallbackFoodItem(from text: String, mealType: MealType) -> ParsedFoodItem {
    // Extract basic food name from text
    let foodName = text.components(separatedBy: .whitespacesAndNewlines)
        .first(where: { $0.count > 2 }) ?? "Unknown Food"
    
    // Reasonable default values based on meal type
    let defaultCalories: Int = {
        switch mealType {
        case .breakfast: return 250
        case .lunch: return 400
        case .dinner: return 500
        case .snack: return 150
        }
    }()
    
    return ParsedFoodItem(
        name: foodName,
        brand: nil,
        quantity: 1.0,
        unit: "serving",
        calories: defaultCalories,
        proteinGrams: Double(defaultCalories) * 0.15 / 4, // 15% protein
        carbGrams: Double(defaultCalories) * 0.50 / 4,    // 50% carbs  
        fatGrams: Double(defaultCalories) * 0.35 / 9,     // 35% fat
        fiberGrams: 3.0,
        sugarGrams: nil,
        sodiumMilligrams: nil,
        databaseId: nil,
        confidence: 0.3 // Low confidence indicates fallback
    )
}

private func buildNutritionParsingPrompt(text: String, mealType: MealType, user: User) -> String {
    return """
    Parse this food description into accurate nutrition data: "\(text)"
    Meal type: \(mealType.rawValue)
    
    Return ONLY valid JSON with this exact structure:
    {
        "items": [
            {
                "name": "food name",
                "brand": "brand name or null",
                "quantity": 1.5,
                "unit": "cups",
                "calories": 0,
                "proteinGrams": 0.0,
                "carbGrams": 0.0,
                "fatGrams": 0.0,
                "fiberGrams": 0.0,
                "sugarGrams": 0.0,
                "sodiumMilligrams": 0.0,
                "confidence": 0.95
            }
        ]
    }
    
    Rules:
    - Use USDA nutrition database accuracy
    - If multiple items mentioned, include all
    - Estimate quantities if not specified  
    - Return realistic nutrition values (not 100 calories for everything!)
    - Confidence 0.9+ for common foods, lower for ambiguous items
    - No explanations or extra text, just JSON
    """
}

private func parseNutritionJSON(_ jsonString: String) throws -> [ParsedFoodItem] {
    guard let data = jsonString.data(using: .utf8),
          let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let itemsArray = json["items"] as? [[String: Any]] else {
        throw FoodTrackingError.invalidNutritionResponse
    }
    
    return try itemsArray.map { itemDict in
        guard let name = itemDict["name"] as? String,
              let quantity = itemDict["quantity"] as? Double,
              let unit = itemDict["unit"] as? String,
              let calories = itemDict["calories"] as? Int,
              let protein = itemDict["proteinGrams"] as? Double,
              let carbs = itemDict["carbGrams"] as? Double,
              let fat = itemDict["fatGrams"] as? Double else {
            throw FoodTrackingError.invalidNutritionData
        }
        
        return ParsedFoodItem(
            name: name,
            brand: itemDict["brand"] as? String,
            quantity: quantity,
            unit: unit,
            calories: calories,
            proteinGrams: protein,
            carbGrams: carbs,
            fatGrams: fat,
            fiberGrams: itemDict["fiberGrams"] as? Double,
            sugarGrams: itemDict["sugarGrams"] as? Double,
            sodiumMilligrams: itemDict["sodiumMilligrams"] as? Double,
            databaseId: nil,
            confidence: itemDict["confidence"] as? Double ?? 0.8
        )
    }
}
```

### Step 4.2: Replace Broken Parsing in FoodTrackingViewModel

**File:** `AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift`

```swift
// Replace the entire processTranscription method
private func processTranscription() async {
    guard !transcribedText.isEmpty else { return }

    isProcessingAI = true
    defer { isProcessingAI = false }

    do {
        // Single AI call replaces all the broken local parsing
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

// DELETE THESE BROKEN METHODS ENTIRELY:
// - parseLocalCommand()
// - parseWithLocalFallback() 
// - parseSimpleFood()
// Total: ~150 lines of terrible code removed
```

### Step 4.3: Add Missing Error Types

**File:** `AirFit/Modules/FoodTracking/Models/FoodTrackingModels.swift`

```swift
// Add to existing FoodTrackingError enum
enum FoodTrackingError: LocalizedError {
    // ... existing cases ...
    case invalidNutritionResponse
    case invalidNutritionData
    
    var errorDescription: String? {
        switch self {
        // ... existing cases ...
        case .invalidNutritionResponse:
            return "Invalid nutrition data from AI"
        case .invalidNutritionData:
            return "Malformed nutrition information"
        }
    }
}
```

### Step 4.4: Update Protocol Definition

**File:** `AirFit/Modules/FoodTracking/Services/FoodCoachEngineProtocol.swift`

```swift
// Add to existing protocol
protocol FoodCoachEngineProtocol: Sendable {
    // ... existing methods ...
    
    /// Parse natural language food input into structured nutrition data
    func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem]
}
```

### Step 4.5: Keep What Actually Works

**No Changes to `NutritionService`** - The database operations are fine:
- `getFoodEntries()` - Proper SwiftData queries
- `calculateNutritionSummary()` - Simple arithmetic
- `saveFoodEntry()` - Basic persistence
- Water logging - Simple value tracking

These work correctly and don't need AI replacement.

## 5. Testing Strategy

### Accuracy Validation

**File:** `AirFitTests/FoodTracking/NutritionParsingTests.swift`

```swift
class NutritionParsingTests: XCTestCase {
    
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
            
            XCTAssertEqual(result.count, 1, "Should parse single item from: \(testCase.input)")
            let calories = result.first?.calories ?? 0
            XCTAssertTrue(
                testCase.expectedCalories.contains(calories),
                "Calories \(calories) not in expected range \(testCase.expectedCalories) for: \(testCase.input)"
            )
        }
    }
    
    func test_nutritionParsing_multipleItems_separateEntries() async throws {
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: "2 eggs and 1 slice of toast with butter",
            mealType: .breakfast,
            for: testUser
        )
        
        XCTAssertGreaterThanOrEqual(result.count, 2, "Should parse multiple items")
        
        let totalCalories = result.reduce(0) { $0 + $1.calories }
        XCTAssertGreaterThan(totalCalories, 200, "Multiple items should have realistic total calories")
        XCTAssertLessThan(totalCalories, 600, "Should not be unrealistically high")
    }
    
    func test_nutritionParsing_performance_under3Seconds() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        _ = try await coachEngine.parseNaturalLanguageFood(
            text: "grilled salmon with quinoa and steamed vegetables",
            mealType: .dinner,
            for: testUser
        )
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(duration, 3.0, "Parsing should complete under 3 seconds")
    }
}
```

### Regression Tests

**File:** `AirFitTests/FoodTracking/FoodTrackingViewModelTests.swift`

```swift
// Update existing tests to verify new parsing
func test_processTranscription_aiParsingSuccess_showsConfirmation() async throws {
    sut.transcribedText = "1 medium banana"
    
    await sut.processTranscription()
    
    XCTAssertFalse(sut.isProcessingAI)
    XCTAssertEqual(sut.parsedItems.count, 1)
    
    let banana = sut.parsedItems.first!
    XCTAssertEqual(banana.name.lowercased(), "banana")
    XCTAssertGreaterThan(banana.calories, 50, "Should have realistic calories, not hardcoded 100")
    XCTAssertLessThan(banana.calories, 150, "Should not be unrealistically high")
    XCTAssertEqual(mockCoordinator.didShowFullScreenCover, .confirmation(sut.parsedItems))
}
```

## 6. Success Metrics & Rollout

### Key Performance Indicators

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| **Parsing Accuracy** | 0% (hardcoded values) | >90% accurate calories | Manual spot checks |
| **Code Reduction** | 150 lines of bad parsing | Remove entirely | Line count |
| **Response Time** | ~0ms (no AI) | <3 seconds | Performance tests |
| **Nutrition Quality** | All foods = 100 calories | Realistic values | User feedback |

### Rollout Strategy

**Phase 3a: AI Parsing Implementation (Low Risk)**
1. Implement AI parsing method in CoachEngine
2. A/B test: 30% users get AI parsing, 70% get current broken parsing
3. Compare accuracy and user satisfaction for 1 week
4. Full migration after validation

**Phase 3b: Remove Broken Code (No Risk)**
1. Delete `parseLocalCommand()`, `parseSimpleFood()`, `parseWithLocalFallback()`
2. Update `processTranscription()` to only use AI parsing
3. Remove hardcoded nutrition values and duplicate logic
4. Monitor for any missed edge cases

### Success Validation

**User-Visible Improvements:**
- Apple no longer reports 100 calories (should be ~95)
- Pizza slice no longer reports 100 calories (should be ~250-300)  
- Multiple food items get parsed separately instead of single 100-calorie blob
- Actual nutrition breakdowns instead of 5g protein for everything

## 7. Expected Outcomes

### Immediate Benefits
- **Fix completely broken nutrition parsing** - No more 100-calorie everything
- **Remove 150+ lines of duplicate/useless code** 
- **Actual nutrition accuracy** instead of hardcoded placeholders
- **User trust improvement** when they see realistic values

### Long-term Benefits
- **Foundation for nutrition insights** - Real data enables coaching features
- **User engagement** - Accurate tracking encourages continued use
- **Feature development velocity** - No more working around broken parsing

This phase fixes the most embarrassing code in the entire codebase. It's high-impact, low-risk, and will immediately improve the user experience. 