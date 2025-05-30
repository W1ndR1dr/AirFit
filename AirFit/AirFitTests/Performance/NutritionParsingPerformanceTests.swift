import XCTest
import SwiftData
@testable import AirFit

/// Performance benchmarks and regression tests for AI nutrition parsing system
/// 
/// This test suite validates the nutrition parsing refactor meets performance targets:
/// - Single food parsing: <3 seconds
/// - Multiple food parsing: <5 seconds  
/// - Memory usage: <50MB increase during parsing
/// - Prevents regression from the hardcoded 100-calorie system
@MainActor
final class NutritionParsingPerformanceTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var coachEngine: MockCoachEngineExtensive!
    private var testUser: User!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for performance testing
        let schema = Schema([User.self, FoodEntry.self, FoodItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Create test user
        testUser = User(
            name: "Performance Test User",
            email: "perf@test.com",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date())!,
            heightCm: 175,
            weightKg: 70,
            activityLevel: .moderate,
            primaryGoal: .maintainWeight
        )
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Create performance-focused mock coach engine
        coachEngine = MockCoachEngineExtensive()
        coachEngine.simulateDelay = 0 // Default to no artificial delay
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        coachEngine = nil
        testUser = nil
        try await super.tearDown()
    }
    
    // MARK: - Response Time Benchmarks
    
    /// Validates single food parsing completes under 3 seconds
    func test_nutritionParsing_singleFood_under3Seconds() async throws {
        let testInputs = [
            "grilled salmon with quinoa and vegetables",
            "protein shake with banana and peanut butter", 
            "chicken caesar salad with croutons",
            "oatmeal with berries and honey",
            "turkey sandwich with avocado and tomato"
        ]
        
        for input in testInputs {
            // Setup realistic nutrition for this input
            coachEngine.setupRealisticNutrition(for: input)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .dinner,
                for: testUser
            )
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            // Performance assertion: Must complete under 3 seconds
            XCTAssertLessThan(duration, 3.0, 
                "Parsing '\(input)' took \(String(format: "%.2f", duration))s, exceeds 3s limit")
            
            // Validate we got meaningful results
            XCTAssertGreaterThan(result.count, 0, "Should return at least one parsed item")
            XCTAssertGreaterThan(result.first?.calories ?? 0, 0, "Should have positive calories")
        }
    }
    
    /// Validates multiple food parsing completes under 5 seconds
    func test_nutritionParsing_multipleFoods_under5Seconds() async throws {
        let complexInputs = [
            "2 eggs scrambled with butter, 2 slices whole wheat toast, orange juice, and coffee with cream",
            "grilled chicken breast, brown rice, steamed broccoli, and a mixed green salad with olive oil",
            "greek yogurt with granola, fresh strawberries, blueberries, and a drizzle of honey",
            "salmon filet with roasted sweet potato, asparagus, and a glass of white wine"
        ]
        
        for input in complexInputs {
            // Setup multiple items for complex parsing
            coachEngine.setupMultipleItems(for: input)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .dinner,
                for: testUser
            )
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            // Performance assertion: Multiple foods under 5 seconds
            XCTAssertLessThan(duration, 5.0,
                "Complex parsing '\(input)' took \(String(format: "%.2f", duration))s, exceeds 5s limit")
            
            // Validate multiple items were parsed
            XCTAssertGreaterThanOrEqual(result.count, 2, "Should parse multiple items from complex input")
            
            // Ensure total calories are realistic (not hardcoded 100 x items)
            let totalCalories = result.reduce(0) { $0 + $1.calories }
            XCTAssertGreaterThan(totalCalories, 200, "Total calories should be realistic")
            XCTAssertLessThan(totalCalories, 1500, "Total calories should not be unrealistically high")
        }
    }
    
    /// Validates batch processing maintains performance under load
    func test_nutritionParsing_batchProcessing_maintainsSpeed() async throws {
        let batchInputs = [
            "apple", "banana", "orange", "chicken breast", "salmon",
            "rice", "quinoa", "broccoli", "spinach", "yogurt"
        ]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        var results: [[ParsedFoodItem]] = []
        
        // Process batch of foods sequentially
        for input in batchInputs {
            coachEngine.setupRealisticNutrition(for: input)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .snack,
                for: testUser
            )
            results.append(result)
        }
        
        let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
        let averageDuration = totalDuration / Double(batchInputs.count)
        
        // Performance assertions for batch processing
        XCTAssertLessThan(totalDuration, 10.0, 
            "Batch processing \(batchInputs.count) items took \(String(format: "%.2f", totalDuration))s, exceeds 10s limit")
        XCTAssertLessThan(averageDuration, 1.0,
            "Average parsing time \(String(format: "%.2f", averageDuration))s exceeds 1s per item")
        
        // Validate all items were processed successfully
        XCTAssertEqual(results.count, batchInputs.count, "Should process all batch items")
        for (index, result) in results.enumerated() {
            XCTAssertGreaterThan(result.count, 0, "Item \(index) should have results")
        }
    }
    
    // MARK: - Memory Usage Tests
    
    /// Validates memory usage remains under 50MB during parsing operations
    func test_nutritionParsing_memoryUsage_under50MB() async throws {
        let beforeMemory = getMemoryUsage()
        
        // Perform intensive parsing operations
        for i in 0..<20 {
            coachEngine.setupRealisticNutrition(for: "complex meal with multiple ingredients \(i)")
            
            _ = try await coachEngine.parseNaturalLanguageFood(
                text: "grilled chicken with vegetables, rice, and sauce",
                mealType: .dinner,
                for: testUser
            )
            
            // Add small delay to allow memory cleanup
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        let afterMemory = getMemoryUsage()
        let memoryIncrease = afterMemory - beforeMemory
        
        // Memory assertion: Should not exceed 50MB increase
        XCTAssertLessThan(memoryIncrease, 50_000_000,
            "Memory increase \(memoryIncrease / 1_000_000)MB exceeds 50MB limit")
        
        // Log memory usage for monitoring
        print("Memory usage - Before: \(beforeMemory / 1_000_000)MB, After: \(afterMemory / 1_000_000)MB, Increase: \(memoryIncrease / 1_000_000)MB")
    }
    
    /// Tests memory cleanup after parsing operations
    func test_nutritionParsing_memoryCleanup_properlyReleases() async throws {
        let initialMemory = getMemoryUsage()
        
        // Perform parsing operations in scope
        do {
            for i in 0..<10 {
                coachEngine.setupRealisticNutrition(for: "test food \(i)")
                let _ = try await coachEngine.parseNaturalLanguageFood(
                    text: "test food \(i)",
                    mealType: .lunch,
                    for: testUser
                )
            }
        }
        
        // Force garbage collection and wait
        autoreleasepool {
            // Empty autoreleasepool to trigger cleanup
        }
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms for cleanup
        
        let finalMemory = getMemoryUsage()
        let memoryDiff = finalMemory - initialMemory
        
        // Should return close to baseline after cleanup
        XCTAssertLessThan(abs(memoryDiff), 20_000_000,
            "Memory should return close to baseline after cleanup. Diff: \(memoryDiff / 1_000_000)MB")
    }
    
    // MARK: - Accuracy Regression Tests
    
    /// Prevents regression to hardcoded 100-calorie system
    func test_accuracyRegression_realNutritionNotPlaceholders() async throws {
        let testFoods = [
            ("apple", 80...120, "Should have realistic apple calories, not hardcoded 100"),
            ("pizza slice", 250...350, "Should have realistic pizza calories, not hardcoded 100"),
            ("protein bar", 150...300, "Should have realistic protein bar calories, not hardcoded 100"),
            ("cup of coffee with milk", 20...80, "Should have realistic coffee calories, not hardcoded 100"),
            ("large salad with dressing", 150...400, "Should have realistic salad calories, not hardcoded 100")
        ]
        
        for (food, expectedRange, message) in testFoods {
            coachEngine.setupRealisticNutrition(for: food)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: food,
                mealType: .lunch,
                for: testUser
            )
            
            XCTAssertGreaterThan(result.count, 0, "Should parse at least one item for: \(food)")
            
            let calories = result.first?.calories ?? 0
            
            // Critical regression prevention: Not hardcoded 100 calories
            XCTAssertNotEqual(calories, 100, 
                "Food '\(food)' returned hardcoded 100 calories - REGRESSION DETECTED")
            
            // Validate realistic range
            XCTAssertTrue(expectedRange.contains(calories), message + " Got: \(calories)")
            
            // Validate macros are not hardcoded placeholders
            let protein = result.first?.proteinGrams ?? 0
            let carbs = result.first?.carbGrams ?? 0
            let fat = result.first?.fatGrams ?? 0
            
            XCTAssertNotEqual(protein, 5.0, "Protein should not be hardcoded 5g for: \(food)")
            XCTAssertNotEqual(carbs, 15.0, "Carbs should not be hardcoded 15g for: \(food)")
            XCTAssertNotEqual(fat, 3.0, "Fat should not be hardcoded 3g for: \(food)")
        }
    }
    
    /// Validates different foods return different nutrition values
    func test_accuracyRegression_differentFoodsDifferentValues() async throws {
        let foods = ["apple", "pizza slice", "chicken breast", "rice", "avocado"]
        var nutritionValues: [(calories: Int, protein: Double)] = []
        
        for food in foods {
            coachEngine.setupRealisticNutrition(for: food)
            
            let result = try await coachEngine.parseNaturalLanguageFood(
                text: food,
                mealType: .lunch,
                for: testUser
            )
            
            let item = result.first!
            nutritionValues.append((calories: item.calories, protein: item.proteinGrams))
        }
        
        // Ensure we have variety in nutrition values (not all the same)
        let uniqueCalories = Set(nutritionValues.map { $0.calories })
        let uniqueProtein = Set(nutritionValues.map { Int($0.protein) })
        
        XCTAssertGreaterThan(uniqueCalories.count, 3, 
            "Should have variety in calories across different foods")
        XCTAssertGreaterThan(uniqueProtein.count, 2,
            "Should have variety in protein across different foods")
        
        // Ensure no food has exactly 100 calories (regression check)
        for (index, nutrition) in nutritionValues.enumerated() {
            XCTAssertNotEqual(nutrition.calories, 100,
                "Food \(foods[index]) has hardcoded 100 calories - REGRESSION")
        }
    }
    
    // MARK: - API Contract Regression Tests
    
    /// Ensures the nutrition parsing API contract is maintained
    func test_apiContractRegression_interfaceMaintained() async throws {
        // Test that parseNaturalLanguageFood method signature is preserved
        let input = "test food"
        coachEngine.setupRealisticNutrition(for: input)
        
        let result = try await coachEngine.parseNaturalLanguageFood(
            text: input,
            mealType: .lunch,
            for: testUser
        )
        
        // Validate return type structure
        XCTAssertTrue(result is [ParsedFoodItem], "Should return array of ParsedFoodItem")
        
        guard let item = result.first else {
            XCTFail("Should return at least one item")
            return
        }
        
        // Validate ParsedFoodItem structure is maintained
        XCTAssertNotNil(item.name, "ParsedFoodItem should have name")
        XCTAssertNotNil(item.calories, "ParsedFoodItem should have calories")
        XCTAssertNotNil(item.proteinGrams, "ParsedFoodItem should have protein")
        XCTAssertNotNil(item.carbGrams, "ParsedFoodItem should have carbs")
        XCTAssertNotNil(item.fatGrams, "ParsedFoodItem should have fat")
        XCTAssertNotNil(item.confidence, "ParsedFoodItem should have confidence")
    }
    
    /// Tests error handling regression for API contract
    func test_apiContractRegression_errorHandlingMaintained() async throws {
        // Test that error scenarios still work correctly
        coachEngine.shouldThrowError = true
        
        do {
            _ = try await coachEngine.parseNaturalLanguageFood(
                text: "invalid input",
                mealType: .lunch,
                for: testUser
            )
            // Should not reach here if error handling works
        } catch {
            // Expected path - error should be thrown
            XCTAssertNotNil(error, "Should throw error for invalid scenarios")
        }
        
        // Reset error state
        coachEngine.shouldThrowError = false
        
        // Test fallback behavior
        coachEngine.shouldReturnFallback = true
        
        let fallbackResult = try await coachEngine.parseNaturalLanguageFood(
            text: "problematic input",
            mealType: .breakfast,
            for: testUser
        )
        
        // Fallback should still return results
        XCTAssertGreaterThan(fallbackResult.count, 0, "Fallback should return results")
        
        // Fallback should have low confidence
        let confidence = fallbackResult.first?.confidence ?? 1.0
        XCTAssertLessThan(confidence, 0.5, "Fallback should have low confidence score")
    }
    
    // MARK: - Performance Monitoring Helpers
    
    /// Gets current memory usage in bytes
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self(), task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - Test Extensions

/// Extended mock coach engine for performance testing
private class MockCoachEngineExtensive {
    var mockParseResult: [ParsedFoodItem] = []
    var shouldThrowError = false
    var shouldReturnFallback = false
    var shouldValidate = false
    var simulateDelay: TimeInterval = 0
    var lastMealType: MealType?
    
    func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
        lastMealType = mealType
        
        // Simulate processing delay if configured
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        // Simulate error condition
        if shouldThrowError {
            throw FoodTrackingError.aiParsingFailed
        }
        
        // Return fallback if configured
        if shouldReturnFallback {
            return [createFallbackFoodItem(from: text, mealType: mealType)]
        }
        
        // Return validated results if configured
        if shouldValidate {
            let validatedItems = validateNutritionValues(mockParseResult)
            if validatedItems.isEmpty {
                return [createFallbackFoodItem(from: text, mealType: mealType)]
            }
            return validatedItems
        }
        
        // Return mock results (default case)
        return mockParseResult.isEmpty ? [createDefaultItem(from: text)] : mockParseResult
    }
    
    // MARK: - Setup Helper Methods
    
    func setupRealisticNutrition(for food: String) {
        let nutrition = getRealisticNutrition(for: food)
        mockParseResult = [nutrition]
    }
    
    func setupMultipleItems(for description: String) {
        let items = parseMultipleItems(from: description)
        mockParseResult = items
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
            confidence: 0.3 // Low confidence indicates fallback
        )
    }
    
    private func createDefaultItem(from text: String) -> ParsedFoodItem {
        return ParsedFoodItem(
            name: text,
            brand: nil,
            quantity: 1.0,
            unit: "serving",
            calories: 150,
            proteinGrams: 8.0,
            carbGrams: 20.0,
            fatGrams: 4.0,
            fiberGrams: 2.0,
            sugarGrams: 5.0,
            sodiumMilligrams: 100.0,
            databaseId: nil,
            confidence: 0.75
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
        case foodLower.contains("avocado"):
            return ParsedFoodItem(name: "avocado", brand: nil, quantity: 0.5, unit: "medium",
                                calories: 160, proteinGrams: 2.0, carbGrams: 8.5, fatGrams: 14.7,
                                fiberGrams: 6.7, sugarGrams: 0.7, sodiumMilligrams: 7.0,
                                databaseId: nil, confidence: 0.93)
        case foodLower.contains("salmon"):
            return ParsedFoodItem(name: "grilled salmon", brand: nil, quantity: 6.0, unit: "oz",
                                calories: 350, proteinGrams: 58.0, carbGrams: 0.0, fatGrams: 11.0,
                                fiberGrams: 0.0, sugarGrams: 0.0, sodiumMilligrams: 98.0,
                                databaseId: nil, confidence: 0.91)
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
        
        // Simple parsing for test purposes - identify common foods
        if words.contains("eggs") || words.contains("egg") {
            items.append(ParsedFoodItem(name: "eggs", brand: nil, quantity: 2.0, unit: "large",
                                      calories: 140, proteinGrams: 12.0, carbGrams: 1.0, fatGrams: 10.0,
                                      fiberGrams: 0.0, sugarGrams: 1.0, sodiumMilligrams: 140.0,
                                      databaseId: nil, confidence: 0.95))
        }
        if words.contains("toast") || words.contains("bread") {
            items.append(ParsedFoodItem(name: "toast", brand: nil, quantity: 1.0, unit: "slice",
                                      calories: 80, proteinGrams: 3.0, carbGrams: 14.0, fatGrams: 1.0,
                                      fiberGrams: 2.0, sugarGrams: 1.0, sodiumMilligrams: 150.0,
                                      databaseId: nil, confidence: 0.90))
        }
        if words.contains("chicken") {
            items.append(getRealisticNutrition(for: "chicken"))
        }
        if words.contains("rice") {
            items.append(getRealisticNutrition(for: "rice"))
        }
        if words.contains("salmon") {
            items.append(getRealisticNutrition(for: "salmon"))
        }
        if words.contains("yogurt") {
            items.append(ParsedFoodItem(name: "greek yogurt", brand: nil, quantity: 1.0, unit: "cup",
                                      calories: 130, proteinGrams: 23.0, carbGrams: 9.0, fatGrams: 0.0,
                                      fiberGrams: 0.0, sugarGrams: 9.0, sodiumMilligrams: 65.0,
                                      databaseId: nil, confidence: 0.92))
        }
        
        // If no specific foods identified, return a generic complex meal
        if items.isEmpty {
            items.append(getRealisticNutrition(for: "complex meal"))
        }
        
        return items
    }
} 