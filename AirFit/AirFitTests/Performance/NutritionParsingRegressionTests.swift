import XCTest
import SwiftData
@testable import AirFit

/// Comprehensive regression tests for nutrition system refactor
/// 
/// This test suite ensures the AI nutrition parsing refactor doesn't regress
/// to the previous broken hardcoded 100-calorie system and maintains all
/// existing functionality while providing accurate nutrition data.
@MainActor
final class NutritionParsingRegressionTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var coachEngine: MockCoachEngineExtensive!
    private var viewModel: FoodTrackingViewModel!
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
            name: "Regression Test User",
            email: "regression@test.com",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date())!,
            heightCm: 170,
            weightKg: 65,
            activityLevel: .moderate,
            primaryGoal: .maintainWeight
        )
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Setup mock coach engine with regression-focused configuration
        coachEngine = MockCoachEngineExtensive()
        
        // Setup view model with mock dependencies (simplified for testing)
        viewModel = FoodTrackingViewModel(
            user: testUser,
            coordinator: MockFoodTrackingCoordinator(),
            coachEngine: coachEngine,
            nutritionService: MockNutritionService()
        )
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        coachEngine = nil
        viewModel = nil
        testUser = nil
        try await super.tearDown()
    }
    
    // MARK: - Critical Regression Prevention
    
    /// **CRITICAL**: Ensures we never return hardcoded 100 calories for any food
    func test_criticalRegression_noHardcoded100Calories() async throws {
        let testCases = [
            ("1 apple", "Apple should have ~95 calories, not 100"),
            ("1 slice pizza", "Pizza should have ~285 calories, not 100"),
            ("1 banana", "Banana should have ~105 calories, not 100"),
            ("6 oz chicken breast", "Chicken should have ~280 calories, not 100"),
            ("1 cup rice", "Rice should have ~216 calories, not 100"),
            ("1 tbsp olive oil", "Olive oil should have ~120 calories, not 100"),
            ("protein bar", "Protein bar should vary by brand, not 100"),
            ("large salad", "Salad calories should vary by ingredients, not 100")
        ]
        
        for (input, failureMessage) in testCases {
            coachEngine.setupRealisticNutrition(for: input)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .lunch,
                for: testUser
            )
            
            XCTAssertGreaterThan(result.count, 0, "Should parse at least one item for: \(input)")
            
            let calories = result.first?.calories ?? 0
            
            // **CRITICAL REGRESSION CHECK**: Never return exactly 100 calories
            XCTAssertNotEqual(calories, 100, 
                "🚨 REGRESSION DETECTED: \(input) returned hardcoded 100 calories! \(failureMessage)")
            
            // Validate we have positive, realistic calories
            XCTAssertGreaterThan(calories, 0, "Calories should be positive for: \(input)")
            XCTAssertLessThan(calories, 2000, "Single food item should not exceed 2000 calories: \(input)")
        }
    }
    
    /// **CRITICAL**: Ensures we never return hardcoded macro placeholders
    func test_criticalRegression_noHardcodedMacros() async throws {
        let foods = ["apple", "pizza", "chicken", "rice", "avocado"]
        
        for food in foods {
            coachEngine.setupRealisticNutrition(for: food)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: food,
                mealType: .lunch,
                for: testUser
            )
            
            let item = result.first!
            
            // **CRITICAL**: Check for hardcoded macro placeholders from old system
            XCTAssertNotEqual(item.proteinGrams, 5.0, 
                "🚨 REGRESSION: \(food) has hardcoded 5g protein placeholder")
            XCTAssertNotEqual(item.carbGrams, 15.0,
                "🚨 REGRESSION: \(food) has hardcoded 15g carbs placeholder") 
            XCTAssertNotEqual(item.fatGrams, 3.0,
                "🚨 REGRESSION: \(food) has hardcoded 3g fat placeholder")
            
            // Validate macros are realistic ranges
            XCTAssertGreaterThanOrEqual(item.proteinGrams, 0, "Protein should be non-negative")
            XCTAssertLessThan(item.proteinGrams, 200, "Protein should be realistic for single item")
            XCTAssertGreaterThanOrEqual(item.carbGrams, 0, "Carbs should be non-negative")
            XCTAssertLessThan(item.carbGrams, 500, "Carbs should be realistic for single item")
            XCTAssertGreaterThanOrEqual(item.fatGrams, 0, "Fat should be non-negative")
            XCTAssertLessThan(item.fatGrams, 200, "Fat should be realistic for single item")
        }
    }
    
    /// **CRITICAL**: Validates different foods have meaningfully different nutrition
    func test_criticalRegression_nutritionVarietyNotUniform() async throws {
        let diverseFoods = [
            "apple",        // Low calorie fruit
            "avocado",      // High fat fruit
            "chicken breast", // High protein meat
            "white rice",   // High carb grain
            "almonds"       // High fat nuts
        ]
        
        var nutritionProfiles: [(food: String, calories: Int, protein: Double, carbs: Double, fat: Double)] = []
        
        for food in diverseFoods {
            coachEngine.setupRealisticNutrition(for: food)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: food,
                mealType: .snack,
                for: testUser
            )
            
            let item = result.first!
            nutritionProfiles.append((
                food: food,
                calories: item.calories,
                protein: item.proteinGrams,
                carbs: item.carbGrams,
                fat: item.fatGrams
            ))
        }
        
        // Ensure we have variety in nutrition values
        let calories = nutritionProfiles.map { $0.calories }
        let proteins = nutritionProfiles.map { Int($0.protein) }
        let carbs = nutritionProfiles.map { Int($0.carbs) }
        let fats = nutritionProfiles.map { Int($0.fat) }
        
        // Check for variety (not all the same values)
        let uniqueCalories = Set(calories)
        let uniqueProteins = Set(proteins)
        let uniqueCarbs = Set(carbs)
        let uniqueFats = Set(fats)
        
        XCTAssertGreaterThan(uniqueCalories.count, 3,
            "Should have variety in calories. Got: \(calories)")
        XCTAssertGreaterThan(uniqueProteins.count, 2,
            "Should have variety in protein. Got: \(proteins)")
        XCTAssertGreaterThan(uniqueCarbs.count, 2,
            "Should have variety in carbs. Got: \(carbs)")
        XCTAssertGreaterThan(uniqueFats.count, 2,
            "Should have variety in fat. Got: \(fats)")
        
        // Validate specific food characteristics
        let apple = nutritionProfiles.first { $0.food == "apple" }!
        let avocado = nutritionProfiles.first { $0.food == "avocado" }!
        let chicken = nutritionProfiles.first { $0.food == "chicken breast" }!
        
        // Apple should be lower calorie than avocado
        XCTAssertLessThan(apple.calories, avocado.calories,
            "Apple (\(apple.calories) cal) should have fewer calories than avocado (\(avocado.calories) cal)")
        
        // Chicken should have significantly more protein than apple
        XCTAssertGreaterThan(chicken.protein, apple.protein + 10,
            "Chicken (\(chicken.protein)g) should have much more protein than apple (\(apple.protein)g)")
        
        // Avocado should have more fat than apple
        XCTAssertGreaterThan(avocado.fat, apple.fat + 5,
            "Avocado (\(avocado.fat)g) should have more fat than apple (\(apple.fat)g)")
    }
    
    // MARK: - FoodTrackingViewModel Integration Regression
    
    /// Tests that processTranscription flow produces realistic nutrition (not placeholders)
    func test_viewModelRegression_processTranscriptionRealisticResults() async throws {
        let testInputs = [
            "I ate an apple",
            "had a slice of pizza for lunch", 
            "grilled chicken with vegetables"
        ]
        
        for input in testInputs {
            // Setup realistic nutrition in mock
            coachEngine.setupRealisticNutrition(for: input)
            
            // Simulate voice transcription
            viewModel.transcribedText = input
            
            // Process transcription (should use AI parsing now)
            await viewModel.processTranscription()
            
            // Validate results are realistic, not hardcoded placeholders
            XCTAssertGreaterThan(viewModel.parsedItems.count, 0,
                "Should parse items from: \(input)")
            
            let firstItem = viewModel.parsedItems.first!
            
            // Critical regression checks
            XCTAssertNotEqual(firstItem.calories, 100,
                "🚨 ViewModel regression: \(input) returned 100-calorie placeholder")
            XCTAssertNotEqual(firstItem.proteinGrams, 5.0,
                "🚨 ViewModel regression: \(input) returned 5g protein placeholder")
            
            // Validate realistic ranges
            XCTAssertGreaterThan(firstItem.calories, 0, "Should have positive calories")
            XCTAssertLessThan(firstItem.calories, 1000, "Single item should be under 1000 calories")
        }
    }
    
    /// Tests that error handling doesn't regress to broken parsing methods
    func test_viewModelRegression_errorHandlingMaintained() async throws {
        // Configure mock to simulate AI failure
        coachEngine.shouldThrowError = true
        
        viewModel.transcribedText = "problematic input"
        
        // Process transcription - should handle error gracefully
        await viewModel.processTranscription()
        
        // Should either show error or fallback results (not crash)
        if viewModel.parsedItems.isEmpty {
            // Error path - should have error set
            XCTAssertNotNil(viewModel.currentError, "Should set error when AI parsing fails")
        } else {
            // Fallback path - should have reasonable fallback
            let fallbackItem = viewModel.parsedItems.first!
            XCTAssertGreaterThan(fallbackItem.calories, 0, "Fallback should have positive calories")
            XCTAssertLessThan(fallbackItem.confidence, 0.5, "Fallback should have low confidence")
        }
        
        // Reset for next test
        coachEngine.shouldThrowError = false
    }
    
    // MARK: - Performance Regression Tests
    
    /// Ensures performance hasn't regressed below acceptable thresholds
    func test_performanceRegression_responseTimeAcceptable() async throws {
        let performanceInputs = [
            "simple apple",
            "complex meal with chicken, rice, and vegetables"
        ]
        
        for input in performanceInputs {
            coachEngine.setupRealisticNutrition(for: input)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            _ = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .lunch,
                for: testUser
            )
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            // Performance regression check - should complete quickly in mock
            XCTAssertLessThan(duration, 1.0,
                "Mock parsing should complete under 1 second for: \(input)")
        }
    }
    
    /// Tests that batch processing doesn't have memory leaks or performance degradation
    func test_performanceRegression_batchProcessingStable() async throws {
        let batchSize = 10
        let foods = (0..<batchSize).map { "test food \($0)" }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for food in foods {
            coachEngine.setupRealisticNutrition(for: food)
            
            _ = try await coachEngine.parseNaturalLanguageFood(
                text: food,
                mealType: .snack,
                for: testUser
            )
        }
        
        let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
        let averageDuration = totalDuration / Double(batchSize)
        
        // Batch processing should scale linearly (no degradation)
        XCTAssertLessThan(averageDuration, 0.1,
            "Average mock parsing time should be under 0.1s per item")
        XCTAssertLessThan(totalDuration, 2.0,
            "Total batch processing should complete under 2 seconds")
    }
    
    // MARK: - API Contract Regression Tests
    
    /// Ensures parseNaturalLanguageFood method signature and behavior is preserved
    func test_apiContractRegression_methodSignaturePreserved() async throws {
        let input = "test food"
        coachEngine.setupRealisticNutrition(for: input)
        
        // Test that method can be called with expected parameters
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .dinner,
            for: testUser
        )
        
        // Validate return type structure hasn't changed
        XCTAssertTrue(result is [ParsedFoodItem], "Should return [ParsedFoodItem]")
        XCTAssertGreaterThan(result.count, 0, "Should return at least one item")
        
        // Validate ParsedFoodItem structure is complete
        let item = result.first!
        XCTAssertFalse(item.name.isEmpty, "Name should not be empty")
        XCTAssertGreaterThan(item.calories, 0, "Calories should be positive")
        XCTAssertGreaterThanOrEqual(item.proteinGrams, 0, "Protein should be non-negative")
        XCTAssertGreaterThanOrEqual(item.carbGrams, 0, "Carbs should be non-negative")
        XCTAssertGreaterThanOrEqual(item.fatGrams, 0, "Fat should be non-negative")
        XCTAssertGreaterThan(item.confidence, 0, "Confidence should be positive")
        XCTAssertLessThanOrEqual(item.confidence, 1.0, "Confidence should not exceed 1.0")
    }
    
    /// Tests that error types and handling haven't changed
    func test_apiContractRegression_errorHandlingPreserved() async throws {
        // Test various error scenarios
        coachEngine.shouldThrowError = true
        
        do {
            _ = try await coachEngine.parseNaturalLanguageFood(
                text: "invalid",
                mealType: .lunch,
                for: testUser
            )
            XCTFail("Should have thrown an error")
        } catch {
            // Error should be a FoodTrackingError or compatible type
            XCTAssertTrue(error is FoodTrackingError || error is MockError,
                "Error should be expected type, got: \(type(of: error))")
        }
        
        // Reset error state
        coachEngine.shouldThrowError = false
        
        // Test successful case
        coachEngine.setupRealisticNutrition(for: "valid food")
        
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: "valid food",
            mealType: .lunch,
            for: testUser
        )
        
        XCTAssertGreaterThan(result.count, 0, "Should succeed for valid input")
    }
    
    // MARK: - Data Quality Regression Tests
    
    /// Ensures nutrition data quality hasn't degraded
    func test_dataQualityRegression_nutritionDataRealistic() async throws {
        let qualityTestCases: [(food: String, expectedCalorieRange: ClosedRange<Int>, macroCheck: String)] = [
            ("apple", 80...120, "fruit should be low calorie"),
            ("pizza slice", 250...400, "pizza should be moderate-high calorie"),
            ("chicken breast", 200...350, "lean protein should be moderate calorie"),
            ("olive oil tablespoon", 100...140, "pure fat should be high calorie density"),
            ("lettuce cup", 5...20, "leafy greens should be very low calorie")
        ]
        
        for (food, calorieRange, description) in qualityTestCases {
            coachEngine.setupRealisticNutrition(for: food)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: food,
                mealType: .lunch,
                for: testUser
            )
            
            let item = result.first!
            
            // Data quality check - realistic calorie ranges
            XCTAssertTrue(calorieRange.contains(item.calories),
                "\(food) calories (\(item.calories)) outside realistic range \(calorieRange) - \(description)")
            
            // Macronutrient consistency check
            let calculatedCalories = (item.proteinGrams * 4) + (item.carbGrams * 4) + (item.fatGrams * 9)
            let calorieDifference = abs(Double(item.calories) - calculatedCalories)
            
            // Allow some variance in calculations
            XCTAssertLessThan(calorieDifference, Double(item.calories) * 0.3,
                "\(food) macro calculations don't match calories within 30% tolerance")
        }
    }
    
    /// Tests that confidence scores are meaningful and not placeholder values
    func test_dataQualityRegression_confidenceScoresMeaningful() async throws {
        let confidenceTests = [
            ("apple", 0.8...1.0, "common food should have high confidence"),
            ("exotic fruit", 0.5...0.9, "less common food should have moderate confidence")
        ]
        
        for (food, expectedRange, description) in confidenceTests {
            coachEngine.setupRealisticNutrition(for: food)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: food,
                mealType: .snack,
                for: testUser
            )
            
            let confidence = result.first?.confidence ?? 0
            
            XCTAssertTrue(expectedRange.contains(confidence),
                "\(food) confidence (\(confidence)) outside expected range \(expectedRange) - \(description)")
            
            // Confidence should never be exactly 0.7 (old hardcoded value)
            XCTAssertNotEqual(confidence, 0.7,
                "🚨 Regression: \(food) has hardcoded 0.7 confidence from old system")
        }
    }
}

// MARK: - Mock Dependencies for Regression Testing

/// Mock coordinator for regression testing
private class MockFoodTrackingCoordinator: FoodTrackingCoordinatorProtocol {
    var didShowFullScreenCover: FoodTrackingRoute?
    
    func showFullScreenCover(_ route: FoodTrackingRoute) {
        didShowFullScreenCover = route
    }
    
    func dismissFullScreenCover() {
        didShowFullScreenCover = nil
    }
}

/// Mock nutrition service for regression testing
private class MockNutritionService: NutritionServiceProtocol {
    func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
        return []
    }
    
    func saveFoodEntry(_ entry: FoodEntry) async throws {
        // Mock implementation
    }
    
    func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary {
        return FoodNutritionSummary(
            totalCalories: 0,
            totalProteinGrams: 0,
            totalCarbGrams: 0,
            totalFatGrams: 0,
            totalFiberGrams: 0,
            totalSugarGrams: 0,
            totalSodiumMilligrams: 0
        )
    }
    
    func getWaterIntake(for user: User, date: Date) async throws -> Double {
        return 0.0
    }
    
    func updateWaterIntake(for user: User, date: Date, amount: Double) async throws {
        // Mock implementation
    }
    
    func getRecentFoods(for user: User, limit: Int) async throws -> [ParsedFoodItem] {
        return []
    }
    
    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
        return []
    }
}

/// Mock error type for testing
private enum MockError: Error, Equatable {
    case testError
} 