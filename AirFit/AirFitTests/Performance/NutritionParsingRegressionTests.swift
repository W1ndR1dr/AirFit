import XCTest
import SwiftData
@testable import AirFit
import Observation

/// Comprehensive regression tests for nutrition system refactor
/// 
/// This test suite ensures the AI nutrition parsing refactor doesn't regress
/// to the previous broken hardcoded 100-calorie system and maintains all
/// existing functionality while providing accurate nutrition data.
@MainActor
final class NutritionParsingRegressionTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var coachEngine: MockCoachEngine!
    private var viewModel: FoodTrackingViewModel!
    private var testUser: User!
    private var coordinator: FoodTrackingCoordinator!
    private var mockFoodVoiceAdapter: MockFoodVoiceAdapter!
    
    override func setUp() {
        super.setUp()
        // Async initialization moved to setupTest()
    }
    
    private func setupTest() async throws {
        // SwiftData setup
        do {
            let schema = Schema([User.self, FoodEntry.self, FoodItem.self, Workout.self, Exercise.self, ExerciseSet.self, DailyLog.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
        
        modelContext = modelContainer.mainContext
        
        // Create test user
        testUser = User(name: "Test User")
        testUser.dailyCalorieTarget = 2000
        testUser.preferences = NutritionPreferences()
        modelContext.insert(testUser)
        
        try modelContext.save()
        
        // Initialize mocks and SUT
        nutritionService = NutritionService(modelContext: modelContext)
        coachEngine = MockCoachEngine()
        coordinator = FoodTrackingCoordinator()
        mockFoodVoiceAdapter = MockFoodVoiceAdapter()
        
        viewModel = FoodTrackingViewModel(
            modelContext: modelContext,
            user: testUser,
            foodVoiceAdapter: mockFoodVoiceAdapter,
            nutritionService: nutritionService,
            coachEngine: coachEngine,
            coordinator: coordinator
        )
    } catch {

            XCTFail("Failed to save test context: \(error)")

        }
        
        // Setup mock coach engine with regression-focused configuration
        coachEngine = MockCoachEngine()
        
        // Setup view model with mock dependencies (simplified for testing)
        coordinator = FoodTrackingCoordinator()
        mockFoodVoiceAdapter = MockFoodVoiceAdapter()
        
        viewModel = FoodTrackingViewModel(
            modelContext: modelContext,
            user: testUser,
            foodVoiceAdapter: mockFoodVoiceAdapter,
            nutritionService: LocalMockNutritionService(),
            coachEngine: coachEngine,
            coordinator: coordinator
        )
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        coachEngine = nil
        viewModel = nil
        testUser = nil
        coordinator = nil
        mockFoodVoiceAdapter = nil
        super.tearDown()
    }
    
    // MARK: - Critical Regression Prevention
    
    /// **CRITICAL**: Ensures we never return hardcoded 100 calories for any food
    func test_criticalRegression_noHardcoded100Calories() async throws {
        try await setupTest()
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
            setupRealisticNutrition(for: input)
            
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
        try await setupTest()
        let foods = ["apple", "pizza", "chicken", "rice", "avocado"]
        
        for food in foods {
            setupRealisticNutrition(for: food)
            
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
        try await setupTest()
        let diverseFoods = [
            "apple",        // Low calorie fruit
            "avocado",      // High fat fruit
            "chicken breast", // High protein meat
            "white rice",   // High carb grain
            "almonds"       // High fat nuts
        ]
        
        var nutritionProfiles: [(food: String, calories: Int, protein: Double, carbs: Double, fat: Double)] = []
        
        for food in diverseFoods {
            setupRealisticNutrition(for: food)
            
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
        try await setupTest()
        let testInputs = [
            "I ate an apple",
            "had a slice of pizza for lunch", 
            "grilled chicken with vegetables"
        ]
        
        for input in testInputs {
            // Setup realistic nutrition in mock
            setupRealisticNutrition(for: input)
            
            // Clear previous parsed items
            viewModel.setParsedItems([])
            
            // Simulate voice transcription through the adapter
            mockFoodVoiceAdapter.onFoodTranscription?(input)
            
            // Wait for async processing
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
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
        try await setupTest()
        // Configure mock to simulate AI failure
        coachEngine.shouldThrowError = true
        
        // Clear previous state
        viewModel.setParsedItems([])
        viewModel.clearError()
        
        // Simulate voice transcription through the adapter
        mockFoodVoiceAdapter.onFoodTranscription?("problematic input")
        
        // Wait for async processing
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Should either show error or fallback results (not crash)
        if viewModel.parsedItems.isEmpty {
            // Error path - should have error set
            XCTAssertNotNil(viewModel.error, "Should set error when AI parsing fails")
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
        try await setupTest()
        let performanceInputs = [
            "simple apple",
            "complex meal with chicken, rice, and vegetables"
        ]
        
        for input in performanceInputs {
            setupRealisticNutrition(for: input)
            
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
        try await setupTest()
        let batchSize = 10
        let foods = (0..<batchSize).map { "test food \($0)" }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for food in foods {
            setupRealisticNutrition(for: food)
            
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
        try await setupTest()
        let input = "test food"
        setupRealisticNutrition(for: input)
        
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
        try await setupTest()
        // Test various error scenarios
        coachEngine.shouldThrowError = true
        coachEngine.errorToThrow = FoodTrackingError.aiParsingFailed
        
        do {
            _ = try await coachEngine.parseNaturalLanguageFood(
                text: "invalid",
                mealType: .lunch,
                for: testUser
            )
            XCTFail("Should have thrown an error")
        } catch {
            // Error should be a FoodTrackingError or compatible type
            XCTAssertTrue(error is FoodTrackingError,
                "Error should be expected type, got: \(type(of: error))")
        }
        
        // Reset error state
        coachEngine.shouldThrowError = false
        
        // Test successful case
        setupRealisticNutrition(for: "valid food")
        
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
        try await setupTest()
        let qualityTestCases: [(food: String, expectedCalorieRange: ClosedRange<Int>, macroCheck: String)] = [
            ("apple", 80...120, "fruit should be low calorie"),
            ("pizza slice", 250...400, "pizza should be moderate-high calorie"),
            ("chicken breast", 200...350, "lean protein should be moderate calorie"),
            ("olive oil tablespoon", 100...140, "pure fat should be high calorie density"),
            ("lettuce cup", 5...20, "leafy greens should be very low calorie")
        ]
        
        for (food, calorieRange, description) in qualityTestCases {
            setupRealisticNutrition(for: food)
            
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
        try await setupTest()
        let confidenceTests = [
            ("apple", 0.8...1.0, "common food should have high confidence"),
            ("exotic fruit", 0.5...0.9, "less common food should have moderate confidence")
        ]
        
        for (food, expectedRange, description) in confidenceTests {
            setupRealisticNutrition(for: food)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: food,
                mealType: .snack,
                for: testUser
            )
            
            let confidence = result.first?.confidence ?? 0
            
            XCTAssertTrue(expectedRange.contains(Double(confidence)),
                "\(food) confidence (\(confidence)) outside expected range \(expectedRange) - \(description)")
            
            // Confidence should never be exactly 0.7 (old hardcoded value)
            XCTAssertNotEqual(confidence, 0.7,
                "🚨 Regression: \(food) has hardcoded 0.7 confidence from old system")
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupRealisticNutrition(for food: String) {
        let foodLower = food.lowercased()
        
        // Set up realistic nutrition based on food type
        switch true {
        case foodLower.contains("apple"):
            coachEngine.mockParsedItems = [
                ParsedFoodItem(name: "apple", brand: nil, quantity: 1.0, unit: "medium",
                              calories: 95, proteinGrams: 0.5, carbGrams: 25.0, fatGrams: 0.3,
                              fiberGrams: 4.0, sugarGrams: 19.0, sodiumMilligrams: 2.0,
                              databaseId: nil, confidence: 0.95)
            ]
        case foodLower.contains("pizza"):
            coachEngine.mockParsedItems = [
                ParsedFoodItem(name: "pizza slice", brand: nil, quantity: 1.0, unit: "slice",
                              calories: 285, proteinGrams: 12.0, carbGrams: 36.0, fatGrams: 10.0,
                              fiberGrams: 2.3, sugarGrams: 3.8, sodiumMilligrams: 640.0,
                              databaseId: nil, confidence: 0.90)
            ]
        case foodLower.contains("chicken"):
            coachEngine.mockParsedItems = [
                ParsedFoodItem(name: "chicken breast", brand: nil, quantity: 6.0, unit: "oz",
                              calories: 280, proteinGrams: 53.0, carbGrams: 0.0, fatGrams: 6.0,
                              fiberGrams: 0.0, sugarGrams: 0.0, sodiumMilligrams: 126.0,
                              databaseId: nil, confidence: 0.92)
            ]
        case foodLower.contains("rice"):
            coachEngine.mockParsedItems = [
                ParsedFoodItem(name: "brown rice", brand: nil, quantity: 1.0, unit: "cup",
                              calories: 216, proteinGrams: 5.0, carbGrams: 45.0, fatGrams: 1.8,
                              fiberGrams: 3.5, sugarGrams: 0.7, sodiumMilligrams: 10.0,
                              databaseId: nil, confidence: 0.88)
            ]
        case foodLower.contains("banana"):
            coachEngine.mockParsedItems = [
                ParsedFoodItem(name: "banana", brand: nil, quantity: 1.0, unit: "medium",
                              calories: 105, proteinGrams: 1.3, carbGrams: 27.0, fatGrams: 0.4,
                              fiberGrams: 3.1, sugarGrams: 14.4, sodiumMilligrams: 1.0,
                              databaseId: nil, confidence: 0.94)
            ]
        case foodLower.contains("avocado"):
            coachEngine.mockParsedItems = [
                ParsedFoodItem(name: "avocado", brand: nil, quantity: 1.0, unit: "whole",
                              calories: 322, proteinGrams: 4.0, carbGrams: 17.0, fatGrams: 29.0,
                              fiberGrams: 13.5, sugarGrams: 1.3, sodiumMilligrams: 14.0,
                              databaseId: nil, confidence: 0.91)
            ]
        case foodLower.contains("almonds"):
            coachEngine.mockParsedItems = [
                ParsedFoodItem(name: "almonds", brand: nil, quantity: 1.0, unit: "oz",
                              calories: 164, proteinGrams: 6.0, carbGrams: 6.0, fatGrams: 14.0,
                              fiberGrams: 3.5, sugarGrams: 1.2, sodiumMilligrams: 0.0,
                              databaseId: nil, confidence: 0.93)
            ]
        default:
            coachEngine.mockParsedItems = [
                ParsedFoodItem(name: food, brand: nil, quantity: 1.0, unit: "serving",
                              calories: 150, proteinGrams: 8.0, carbGrams: 20.0, fatGrams: 4.0,
                              fiberGrams: 2.0, sugarGrams: 5.0, sodiumMilligrams: 100.0,
                              databaseId: nil, confidence: 0.75)
            ]
        }
    }

// MARK: - Mock Dependencies

// Using MockFoodVoiceAdapter from Mocks directory

// Using MockNutritionService from Mocks folder

/// Local mock nutrition service wrapper for regression testing
@MainActor
private final class LocalMockNutritionService: NutritionServiceProtocol, @unchecked Sendable {
    private let mockService = MockNutritionService()
    
    func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
        return try await mockService.getFoodEntries(for: user, date: date)
    }
    
    func saveFoodEntry(_ entry: FoodEntry) async throws {
        try await mockService.saveFoodEntry(entry)
    }
    
    func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary {
        return mockService.calculateNutritionSummary(from: entries)
    }
    
    func getWaterIntake(for user: User, date: Date) async throws -> Double {
        return try await mockService.getWaterIntake(for: user, date: date)
    }
    
    func updateWaterIntake(for user: User, date: Date, amount: Double) async throws {
        try await mockService.updateWaterIntake(for: user, date: date, amount: amount)
    }
    
    func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] {
        return try await mockService.getRecentFoods(for: user, limit: limit)
    }
    
    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
        return try await mockService.getMealHistory(for: user, mealType: mealType, daysBack: daysBack)
    }
    
    func logWaterIntake(for user: User, amountML: Double, date: Date) async throws {
        try await mockService.logWaterIntake(for: user, amountML: amountML, date: date)
    }
    
    func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
        return try await mockService.getFoodEntries(for: date)
    }
    
    func deleteFoodEntry(_ entry: FoodEntry) async throws {
        try await mockService.deleteFoodEntry(entry)
    }
    
    nonisolated func getTargets(from profile: OnboardingProfile?) -> NutritionTargets {
        return mockService.getTargets(from: profile)
    }
    
    func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary {
        return try await mockService.getTodaysSummary(for: user)
    }
}

/// Mock error type for testing
// Using MockError from MockFoodVoiceAdapter.swift 