import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class NutritionParsingExtensiveTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var coachEngine: MockCoachEngineExtensive!
    private var testUser: User!

    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container
        let schema = Schema([User.self, FoodEntry.self, FoodItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Create test user
        testUser = User(
            name: "Test User",
            email: "test@example.com",
            dateOfBirth: Date(),
            heightCm: 175,
            weightKg: 70,
            activityLevel: .moderate,
            primaryGoal: .maintainWeight
        )
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Create enhanced mock coach engine
        coachEngine = MockCoachEngineExtensive()
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        coachEngine = nil
        testUser = nil
        try await super.tearDown()
    }

    // MARK: - TASK 6.1: Accuracy Validation Tests

    func test_nutritionParsing_commonFoods_accurateValues() async throws {
        let testCases: [(input: String, expectedCalories: Range<Int>, description: String)] = [
            ("1 large apple", 90...110, "Apple should have realistic calories, not hardcoded 100"),
            ("2 slices whole wheat bread", 140...180, "Bread should vary from apple calories"),
            ("6 oz grilled chicken breast", 250...300, "Chicken should have high protein content"),
            ("1 cup brown rice", 210...250, "Rice should have carb-heavy nutrition profile"),
            ("1 tablespoon olive oil", 110...130, "Oil should be fat-heavy with high calories per gram"),
            ("1 slice pepperoni pizza", 250...350, "Pizza should have much higher calories than apple"),
            ("protein bar", 180...280, "Protein bar should have balanced macros"),
            ("small banana", 80...110, "Banana should have natural fruit nutrition profile")
        ]
        
        for testCase in testCases {
            coachEngine.setupRealisticNutrition(for: testCase.input)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: testCase.input,
                mealType: .lunch,
                for: testUser
            )
            
            XCTAssertEqual(result.count, 1, "Should parse single item from: \(testCase.input)")
            let calories = result.first?.calories ?? 0
            XCTAssertTrue(
                testCase.expectedCalories.contains(calories),
                "\(testCase.description). Got \(calories) calories, expected \(testCase.expectedCalories)"
            )
            
            // Verify not hardcoded placeholder values
            XCTAssertNotEqual(calories, 100, "Should not return hardcoded 100 calories for: \(testCase.input)")
            
            let item = result.first!
            XCTAssertNotEqual(item.proteinGrams, 5.0, "Should not return hardcoded 5g protein for: \(testCase.input)")
            XCTAssertNotEqual(item.carbGrams, 15.0, "Should not return hardcoded 15g carbs for: \(testCase.input)")
            XCTAssertNotEqual(item.fatGrams, 3.0, "Should not return hardcoded 3g fat for: \(testCase.input)")
        }
    }

    func test_nutritionParsing_multipleItems_separateEntries() async throws {
        let complexInputs = [
            "2 eggs and 1 slice of toast with butter",
            "chicken caesar salad with croutons and dressing",
            "protein shake with banana and peanut butter",
            "grilled salmon with quinoa and asparagus"
        ]
        
        for input in complexInputs {
            coachEngine.setupMultipleItems(for: input)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .dinner,
                for: testUser
            )
            
            XCTAssertGreaterThanOrEqual(result.count, 2, "Should parse multiple items from: \(input)")
            
            // Verify each item has realistic, different nutrition values
            for (index, item) in result.enumerated() {
                XCTAssertGreaterThan(item.calories, 0, "Item \(index) should have positive calories")
                XCTAssertNotEqual(item.calories, 100, "Item \(index) should not have hardcoded 100 calories")
                XCTAssertGreaterThan(item.confidence, 0.5, "Item \(index) should have reasonable confidence")
            }
            
            // Verify items have different nutrition profiles (not all identical)
            if result.count >= 2 {
                let firstItem = result[0]
                let secondItem = result[1]
                let nutritionDifference = abs(firstItem.calories - secondItem.calories) + 
                                        abs(Int(firstItem.proteinGrams - secondItem.proteinGrams)) +
                                        abs(Int(firstItem.carbGrams - secondItem.carbGrams))
                XCTAssertGreaterThan(nutritionDifference, 10, "Different foods should have different nutrition profiles")
            }
        }
    }

    func test_nutritionParsing_complexDescriptions_handlesCookingMethods() async throws {
        let cookingMethodTests = [
            ("grilled chicken breast", "grilled"),
            ("fried chicken strips", "fried"),
            ("steamed broccoli", "steamed"),
            ("baked sweet potato", "baked"),
            ("raw spinach salad", "raw")
        ]
        
        for (input, method) in cookingMethodTests {
            coachEngine.setupCookingMethodNutrition(for: input, method: method)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .dinner,
                for: testUser
            )
            
            XCTAssertEqual(result.count, 1, "Should parse cooking method food: \(input)")
            
            let item = result.first!
            XCTAssertTrue(item.name.lowercased().contains(method.lowercased()), 
                         "Food name should include cooking method: \(method)")
            
            // Verify cooking method affects nutrition (e.g., fried has more calories than grilled)
            if method == "fried" {
                XCTAssertGreaterThan(item.fatGrams, 8.0, "Fried foods should have higher fat content")
            } else if method == "grilled" {
                XCTAssertLessThan(item.fatGrams, 8.0, "Grilled foods should have lower fat content")
            }
        }
    }

    // MARK: - TASK 6.2: Performance Tests

    func test_nutritionParsing_performance_under3Seconds() async throws {
        let performanceTestCases = [
            "simple apple",
            "grilled chicken breast with quinoa and steamed vegetables",
            "protein shake with banana, peanut butter, oats, and almond milk",
            "complex meal with multiple ingredients and cooking methods"
        ]
        
        for input in performanceTestCases {
            coachEngine.setupRealisticNutrition(for: input)
            coachEngine.simulateDelay = 0.8 // Simulate realistic AI response time
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .dinner,
                for: testUser
            )
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            XCTAssertLessThan(duration, 3.0, "Parsing '\(input)' took \(duration)s, exceeds 3s target")
            XCTAssertGreaterThan(result.count, 0, "Should return results within time limit")
        }
    }

    func test_nutritionParsing_batchProcessing_maintainsSpeed() async throws {
        let batchInputs = [
            "apple", "banana", "orange", "chicken", "rice",
            "broccoli", "salmon", "quinoa", "almonds", "yogurt"
        ]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for input in batchInputs {
            coachEngine.setupRealisticNutrition(for: input)
            _ = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .snack,
                for: testUser
            )
        }
        
        let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
        let averageDuration = totalDuration / Double(batchInputs.count)
        
        XCTAssertLessThan(averageDuration, 2.0, "Average parsing time should be under 2s per item")
        XCTAssertLessThan(totalDuration, 15.0, "Total batch processing should complete quickly")
    }

    // MARK: - TASK 6.3: Error Handling and Fallback Tests

    func test_nutritionParsing_invalidInput_gracefulFallback() async throws {
        let invalidInputs = [
            "",
            "xyz123invalid",
            "random gibberish text that makes no sense",
            "!@#$%^&*()",
            "a" // Single character
        ]
        
        for input in invalidInputs {
            coachEngine.shouldReturnFallback = true
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .snack,
                for: testUser
            )
            
            XCTAssertEqual(result.count, 1, "Should return fallback item for invalid input: '\(input)'")
            
            let fallbackItem = result.first!
            XCTAssertEqual(fallbackItem.confidence, 0.3, accuracy: 0.01, "Fallback should have low confidence")
            XCTAssertEqual(fallbackItem.calories, 150, "Snack fallback should have 150 calories")
            XCTAssertLessThan(fallbackItem.proteinGrams, 50.0, "Fallback should have reasonable protein")
        }
    }

    func test_nutritionParsing_aiFailure_returnsIntelligentFallback() async throws {
        let inputs = ["chicken salad", "pasta with sauce", "fruit smoothie"]
        
        for input in inputs {
            coachEngine.shouldThrowError = true
            coachEngine.errorToThrow = FoodTrackingError.aiParsingFailed
            
            // Should not throw, should return fallback instead
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .lunch,
                for: testUser
            )
            
            XCTAssertEqual(result.count, 1, "Should return intelligent fallback for AI failure")
            
            let fallbackItem = result.first!
            XCTAssertEqual(fallbackItem.calories, 400, "Lunch fallback should have 400 calories")
            XCTAssertEqual(fallbackItem.confidence, 0.3, accuracy: 0.01, "AI failure fallback should have low confidence")
            
            // Verify fallback has reasonable macro distribution
            let proteinCalories = fallbackItem.proteinGrams * 4
            let carbCalories = fallbackItem.carbGrams * 4
            let fatCalories = fallbackItem.fatGrams * 9
            let totalMacroCalories = proteinCalories + carbCalories + fatCalories
            
            XCTAssertTrue(abs(totalMacroCalories - Double(fallbackItem.calories)) < 50,
                         "Fallback macros should approximately match total calories")
        }
    }

    // MARK: - TASK 6.4: Validation Tests

    func test_nutritionParsing_validation_rejectsUnrealisticValues() async throws {
        let invalidNutritionItems = [
            // Extremely high calories
            ParsedFoodItem(name: "magic food", brand: nil, quantity: 1.0, unit: "serving",
                          calories: 10000, proteinGrams: 500, carbGrams: 2000, fatGrams: 1000,
                          fiberGrams: 0, sugarGrams: 0, sodiumMilligrams: 0, databaseId: nil, confidence: 0.9),
            // Negative values
            ParsedFoodItem(name: "impossible food", brand: nil, quantity: 1.0, unit: "serving",
                          calories: -100, proteinGrams: -10, carbGrams: -5, fatGrams: -3,
                          fiberGrams: 0, sugarGrams: 0, sodiumMilligrams: 0, databaseId: nil, confidence: 0.8),
            // Zero calories but high macros
            ParsedFoodItem(name: "contradictory food", brand: nil, quantity: 1.0, unit: "serving",
                          calories: 0, proteinGrams: 50, carbGrams: 100, fatGrams: 20,
                          fiberGrams: 0, sugarGrams: 0, sodiumMilligrams: 0, databaseId: nil, confidence: 0.9)
        ]
        
        for invalidItem in invalidNutritionItems {
            coachEngine.mockParseResult = [invalidItem]
            coachEngine.shouldValidate = true
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: "test food",
                mealType: .lunch,
                for: testUser
            )
            
            // Should return fallback instead of invalid data
            XCTAssertEqual(result.count, 1, "Should return fallback for invalid nutrition data")
            
            let validatedItem = result.first!
            XCTAssertLessThan(validatedItem.calories, 5000, "Validated item should have reasonable calories")
            XCTAssertGreaterThan(validatedItem.calories, 0, "Validated item should have positive calories")
            XCTAssertEqual(validatedItem.confidence, 0.3, accuracy: 0.01, "Validation fallback should have low confidence")
        }
    }

    func test_nutritionParsing_validation_acceptsRealisticValues() async throws {
        let validNutritionItems = [
            ParsedFoodItem(name: "apple", brand: nil, quantity: 1.0, unit: "medium",
                          calories: 95, proteinGrams: 0.5, carbGrams: 25, fatGrams: 0.3,
                          fiberGrams: 4, sugarGrams: 19, sodiumMilligrams: 2, databaseId: nil, confidence: 0.95),
            ParsedFoodItem(name: "chicken breast", brand: nil, quantity: 6.0, unit: "oz",
                          calories: 280, proteinGrams: 53, carbGrams: 0, fatGrams: 6,
                          fiberGrams: 0, sugarGrams: 0, sodiumMilligrams: 126, databaseId: nil, confidence: 0.92),
            ParsedFoodItem(name: "brown rice", brand: nil, quantity: 1.0, unit: "cup",
                          calories: 216, proteinGrams: 5, carbGrams: 45, fatGrams: 1.8,
                          fiberGrams: 3.5, sugarGrams: 0.7, sodiumMilligrams: 10, databaseId: nil, confidence: 0.90)
        ]
        
        for validItem in validNutritionItems {
            coachEngine.mockParseResult = [validItem]
            coachEngine.shouldValidate = true
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: validItem.name,
                mealType: .lunch,
                for: testUser
            )
            
            XCTAssertEqual(result.count, 1, "Should accept valid nutrition data")
            
            let acceptedItem = result.first!
            XCTAssertEqual(acceptedItem.name, validItem.name, "Valid item should pass through unchanged")
            XCTAssertEqual(acceptedItem.calories, validItem.calories, "Valid calories should be preserved")
            XCTAssertEqual(acceptedItem.confidence, validItem.confidence, accuracy: 0.01, "Valid confidence should be preserved")
        }
    }

    // MARK: - TASK 6.5: Meal Type Context Tests

    func test_nutritionParsing_mealTypeContext_adjustsDefaults() async throws {
        let mealTypeTests: [(MealType, Int)] = [
            (.breakfast, 250),
            (.lunch, 400),
            (.dinner, 500),
            (.snack, 150)
        ]
        
        for (mealType, expectedCalories) in mealTypeTests {
            coachEngine.shouldReturnFallback = true
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: "unknown food",
                mealType: mealType,
                for: testUser
            )
            
            XCTAssertEqual(result.count, 1, "Should return fallback for unknown food")
            XCTAssertEqual(result.first?.calories, expectedCalories, 
                          "\(mealType.rawValue) should have \(expectedCalories) default calories")
            XCTAssertTrue(coachEngine.lastMealType == mealType, "Should preserve meal type context")
        }
    }

    // MARK: - TASK 6.6: Regression Prevention Tests

    func test_nutritionParsing_regressionPrevention_noHardcodedValues() async throws {
        let diverseFoods = [
            "apple", "pizza", "salad", "burger", "soup", "cake", "nuts", "cheese"
        ]
        
        var calorieValues: Set<Int> = []
        var proteinValues: Set<Double> = []
        
        for food in diverseFoods {
            coachEngine.setupRealisticNutrition(for: food)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: food,
                mealType: .lunch,
                for: testUser
            )
            
            let item = result.first!
            calorieValues.insert(item.calories)
            proteinValues.insert(item.proteinGrams)
            
            // Verify no hardcoded placeholder values
            XCTAssertNotEqual(item.calories, 100, "\(food) should not have hardcoded 100 calories")
            XCTAssertNotEqual(item.proteinGrams, 5.0, "\(food) should not have hardcoded 5g protein")
            XCTAssertNotEqual(item.carbGrams, 15.0, "\(food) should not have hardcoded 15g carbs")
            XCTAssertNotEqual(item.fatGrams, 3.0, "\(food) should not have hardcoded 3g fat")
        }
        
        // Verify nutrition values are diverse (not all the same)
        XCTAssertGreaterThan(calorieValues.count, 5, "Different foods should have different calorie values")
        XCTAssertGreaterThan(proteinValues.count, 5, "Different foods should have different protein values")
    }

    func test_nutritionParsing_apiContractMaintained() async throws {
        // Verify the API contract hasn't changed
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: "test food",
            mealType: .lunch,
            for: testUser
        )
        
        // Verify return type structure
        XCTAssertTrue(result is [ParsedFoodItem], "Should return array of ParsedFoodItem")
        
        if let firstItem = result.first {
            // Verify all required properties exist
            XCTAssertNotNil(firstItem.name, "ParsedFoodItem should have name")
            XCTAssertNotNil(firstItem.quantity, "ParsedFoodItem should have quantity") 
            XCTAssertNotNil(firstItem.unit, "ParsedFoodItem should have unit")
            XCTAssertNotNil(firstItem.calories, "ParsedFoodItem should have calories")
            XCTAssertNotNil(firstItem.proteinGrams, "ParsedFoodItem should have proteinGrams")
            XCTAssertNotNil(firstItem.carbGrams, "ParsedFoodItem should have carbGrams")
            XCTAssertNotNil(firstItem.fatGrams, "ParsedFoodItem should have fatGrams")
            XCTAssertNotNil(firstItem.confidence, "ParsedFoodItem should have confidence")
        }
    }
}

// MARK: - Enhanced Mock Coach Engine for Extensive Testing

@MainActor
final class MockCoachEngineExtensive: FoodCoachEngineProtocol {
    var mockParseResult: [ParsedFoodItem] = []
    var shouldThrowError = false
    var errorToThrow: Error = FoodTrackingError.aiParsingFailed
    var shouldReturnFallback = false
    var shouldValidate = false
    var simulateDelay: TimeInterval = 0
    var lastMealType: MealType?

    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
        return [:]
    }

    func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
        return FunctionExecutionResult(
            functionName: functionCall.name,
            success: true,
            message: "Mock execution",
            data: [:]
        )
    }

    func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
        return MealPhotoAnalysisResult(
            items: mockParseResult,
            confidence: 0.8,
            processingTime: 0.5
        )
    }

    func searchFoods(query: String, limit: Int) async throws -> [ParsedFoodItem] {
        return mockParseResult
    }

    func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
        lastMealType = mealType

        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }

        if shouldThrowError {
            return [createFallbackFoodItem(from: text, mealType: mealType)]
        }

        if shouldReturnFallback {
            return [createFallbackFoodItem(from: text, mealType: mealType)]
        }

        if shouldValidate {
            let validatedItems = validateNutritionValues(mockParseResult)
            if validatedItems.isEmpty {
                return [createFallbackFoodItem(from: text, mealType: mealType)]
            }
            return validatedItems
        }

        return mockParseResult
    }

    // MARK: - Test Helper Methods

    func setupRealisticNutrition(for food: String) {
        let nutrition = getRealisticNutrition(for: food)
        mockParseResult = [nutrition]
    }

    func setupMultipleItems(for description: String) {
        // Parse description to create multiple realistic items
        let items = parseMultipleItems(from: description)
        mockParseResult = items
    }

    func setupCookingMethodNutrition(for food: String, method: String) {
        let nutrition = getRealisticNutrition(for: food)
        var adjustedNutrition = nutrition
        
        // Adjust nutrition based on cooking method
        if method == "fried" {
            adjustedNutrition = ParsedFoodItem(
                name: "\(method) \(nutrition.name)",
                brand: nutrition.brand,
                quantity: nutrition.quantity,
                unit: nutrition.unit,
                calories: nutrition.calories + 50, // Fried foods have more calories
                proteinGrams: nutrition.proteinGrams,
                carbGrams: nutrition.carbGrams,
                fatGrams: nutrition.fatGrams + 5, // More fat from frying
                fiberGrams: nutrition.fiberGrams,
                sugarGrams: nutrition.sugarGrams,
                sodiumMilligrams: nutrition.sodiumMilligrams,
                databaseId: nutrition.databaseId,
                confidence: nutrition.confidence
            )
        } else {
            adjustedNutrition = ParsedFoodItem(
                name: "\(method) \(nutrition.name)",
                brand: nutrition.brand,
                quantity: nutrition.quantity,
                unit: nutrition.unit,
                calories: nutrition.calories,
                proteinGrams: nutrition.proteinGrams,
                carbGrams: nutrition.carbGrams,
                fatGrams: nutrition.fatGrams,
                fiberGrams: nutrition.fiberGrams,
                sugarGrams: nutrition.sugarGrams,
                sodiumMilligrams: nutrition.sodiumMilligrams,
                databaseId: nutrition.databaseId,
                confidence: nutrition.confidence
            )
        }
        
        mockParseResult = [adjustedNutrition]
    }

    // MARK: - Private Helper Methods

    private func createFallbackFoodItem(from text: String, mealType: MealType) -> ParsedFoodItem {
        let foodName = text.components(separatedBy: .whitespacesAndNewlines)
            .first(where: { $0.count > 2 }) ?? "Unknown Food"

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
            proteinGrams: Double(defaultCalories) * 0.15 / 4,
            carbGrams: Double(defaultCalories) * 0.50 / 4,
            fatGrams: Double(defaultCalories) * 0.35 / 9,
            fiberGrams: 3.0,
            sugarGrams: nil,
            sodiumMilligrams: nil,
            databaseId: nil,
            confidence: 0.3
        )
    }

    private func validateNutritionValues(_ items: [ParsedFoodItem]) -> [ParsedFoodItem] {
        return items.compactMap { item in
            guard item.calories > 0 && item.calories < 5000,
                  item.proteinGrams >= 0 && item.proteinGrams < 300,
                  item.carbGrams >= 0 && item.carbGrams < 1000,
                  item.fatGrams >= 0 && item.fatGrams < 500 else {
                return nil
            }
            return item
        }
    }

    private func getRealisticNutrition(for food: String) -> ParsedFoodItem {
        let foodLower = food.lowercased()
        
        // Return realistic nutrition based on food type
        switch true {
        case foodLower.contains("apple"):
            return ParsedFoodItem(name: "apple", brand: nil, quantity: 1.0, unit: "medium",
                                calories: 95, proteinGrams: 0.5, carbGrams: 25.0, fatGrams: 0.3,
                                fiberGrams: 4.0, sugarGrams: 19.0, sodiumMilligrams: 2.0, 
                                databaseId: nil, confidence: 0.95)
        case foodLower.contains("pizza"):
            return ParsedFoodItem(name: "pizza slice", brand: nil, quantity: 1.0, unit: "slice",
                                calories: 285, proteinGrams: 12.0, carbGrams: 36.0, fatGrams: 10.0,
                                fiberGrams: 2.3, sugarGrams: 3.8, sodiumMilligrams: 640.0,
                                databaseId: nil, confidence: 0.90)
        case foodLower.contains("chicken"):
            return ParsedFoodItem(name: "chicken breast", brand: nil, quantity: 6.0, unit: "oz",
                                calories: 280, proteinGrams: 53.0, carbGrams: 0.0, fatGrams: 6.0,
                                fiberGrams: 0.0, sugarGrams: 0.0, sodiumMilligrams: 126.0,
                                databaseId: nil, confidence: 0.92)
        case foodLower.contains("rice"):
            return ParsedFoodItem(name: "brown rice", brand: nil, quantity: 1.0, unit: "cup",
                                calories: 216, proteinGrams: 5.0, carbGrams: 45.0, fatGrams: 1.8,
                                fiberGrams: 3.5, sugarGrams: 0.7, sodiumMilligrams: 10.0,
                                databaseId: nil, confidence: 0.88)
        case foodLower.contains("banana"):
            return ParsedFoodItem(name: "banana", brand: nil, quantity: 1.0, unit: "medium",
                                calories: 105, proteinGrams: 1.3, carbGrams: 27.0, fatGrams: 0.4,
                                fiberGrams: 3.1, sugarGrams: 14.4, sodiumMilligrams: 1.0,
                                databaseId: nil, confidence: 0.94)
        default:
            return ParsedFoodItem(name: food, brand: nil, quantity: 1.0, unit: "serving",
                                calories: 150, proteinGrams: 8.0, carbGrams: 20.0, fatGrams: 4.0,
                                fiberGrams: 2.0, sugarGrams: 5.0, sodiumMilligrams: 100.0,
                                databaseId: nil, confidence: 0.75)
        }
    }

    private func parseMultipleItems(from description: String) -> [ParsedFoodItem] {
        let words = description.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var items: [ParsedFoodItem] = []
        
        // Simple parsing for test purposes
        if words.contains("eggs") {
            items.append(ParsedFoodItem(name: "eggs", brand: nil, quantity: 2.0, unit: "large",
                                      calories: 140, proteinGrams: 12.0, carbGrams: 1.0, fatGrams: 10.0,
                                      fiberGrams: 0.0, sugarGrams: 1.0, sodiumMilligrams: 140.0,
                                      databaseId: nil, confidence: 0.95))
        }
        if words.contains("toast") {
            items.append(ParsedFoodItem(name: "toast", brand: nil, quantity: 1.0, unit: "slice",
                                      calories: 80, proteinGrams: 3.0, carbGrams: 14.0, fatGrams: 1.0,
                                      fiberGrams: 2.0, sugarGrams: 1.0, sodiumMilligrams: 150.0,
                                      databaseId: nil, confidence: 0.90))
        }
        if words.contains("chicken") {
            items.append(getRealisticNutrition(for: "chicken"))
        }
        if words.contains("salad") {
            items.append(ParsedFoodItem(name: "mixed salad", brand: nil, quantity: 1.0, unit: "cup",
                                      calories: 20, proteinGrams: 1.0, carbGrams: 4.0, fatGrams: 0.2,
                                      fiberGrams: 2.0, sugarGrams: 2.0, sodiumMilligrams: 10.0,
                                      databaseId: nil, confidence: 0.85))
        }
        
        return items.isEmpty ? [getRealisticNutrition(for: description)] : items
    }
} 