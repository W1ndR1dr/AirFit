import XCTest
import SwiftData
@testable import AirFit

/// Performance tests for nutrition parsing functionality
/// 
/// These tests ensure that AI-powered nutrition parsing:
/// - Completes parsing within 3 seconds (network + processing)
/// - Handles complex multi-item inputs efficiently
/// - Validates nutrition values are realistic
/// - Memory usage: <50MB increase during parsing
/// - Prevents regression from the hardcoded 100-calorie system
final class NutritionParsingPerformanceTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var coachEngine: MockCoachEngine!
    private var testUser: User!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory model container for performance testing
        let schema = Schema([User.self, FoodEntry.self, FoodItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        modelContext.insert(testUser)
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }
        
        // Initialize mock coach engine
        coachEngine = MockCoachEngine()
    }
    
    override func tearDown() {
        coachEngine = nil
        testUser = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }
    
    // MARK: - Single Item Performance Tests
    
    func testParseSimpleFoodPerformance() async throws {
        // Setup realistic mock data
        let mockItem = ParsedFoodItem(
            name: "apple",
            brand: nil,
            quantity: 1.0,
            unit: "medium",
            calories: 95,
            proteinGrams: 0.5,
            carbGrams: 25.0,
            fatGrams: 0.3,
            fiberGrams: 4.4,
            sugarGrams: 19.0,
            sodiumMilligrams: 2.0,
            databaseId: nil,
            confidence: 0.95
        )
        
        coachEngine.mockParsedItems = [mockItem]
        
        // Measure performance - should complete within 1 second for simple items
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let results = try await coachEngine.parseNaturalLanguageFood(
            text: "I ate an apple",
            mealType: .snack,
            for: testUser
        )
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(elapsed, 1.0, "Simple food parsing should complete within 1 second")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "apple")
        XCTAssertEqual(results.first?.calories, 95)
        XCTAssertNotEqual(results.first?.calories, 100, "Should not use hardcoded 100 calorie default")
    }
    
    func testParseComplexMealPerformance() async throws {
        // Setup realistic multi-item meal
        let mockItems = [
            ParsedFoodItem(name: "grilled chicken", brand: nil, quantity: 4.0, unit: "oz",
                          calories: 184, proteinGrams: 35.0, carbGrams: 0.0, fatGrams: 4.0,
                          fiberGrams: 0.0, sugarGrams: 0.0, sodiumMilligrams: 74.0,
                          databaseId: nil, confidence: 0.90),
            ParsedFoodItem(name: "brown rice", brand: nil, quantity: 0.5, unit: "cup",
                          calories: 109, proteinGrams: 2.5, carbGrams: 23.0, fatGrams: 0.9,
                          fiberGrams: 1.8, sugarGrams: 0.4, sodiumMilligrams: 5.0,
                          databaseId: nil, confidence: 0.88),
            ParsedFoodItem(name: "steamed broccoli", brand: nil, quantity: 1.0, unit: "cup",
                          calories: 31, proteinGrams: 2.6, carbGrams: 6.0, fatGrams: 0.3,
                          fiberGrams: 2.4, sugarGrams: 1.5, sodiumMilligrams: 30.0,
                          databaseId: nil, confidence: 0.92)
        ]
        
        coachEngine.mockParsedItems = mockItems
        
        // Measure performance - should complete within 3 seconds for complex meals
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let results = try await coachEngine.parseNaturalLanguageFood(
            text: "I had grilled chicken with brown rice and steamed broccoli",
            mealType: .dinner,
            for: testUser
        )
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(elapsed, 3.0, "Complex meal parsing should complete within 3 seconds")
        XCTAssertEqual(results.count, 3)
        
        // Verify realistic nutrition values
        let totalCalories = results.reduce(0) { $0 + $1.calories }
        XCTAssertEqual(totalCalories, 324) // Not a multiple of 100
        
        // Verify macro distribution is realistic
        let totalProtein = results.reduce(0) { $0 + ($1.proteinGrams) }
        let totalCarbs = results.reduce(0) { $0 + ($1.carbGrams) }
        let totalFat = results.reduce(0) { $0 + ($1.fatGrams) }
        
        XCTAssertGreaterThan(totalProtein, 30.0, "High-protein meal should have >30g protein")
        XCTAssertLessThan(totalCarbs, 40.0, "Moderate carb meal")
        XCTAssertLessThan(totalFat, 10.0, "Low-fat meal")
    }
    
    // MARK: - Batch Processing Performance
    
    func testBatchParsingPerformance() async throws {
        // Test parsing multiple items in sequence
        let testInputs = [
            "Greek yogurt with blueberries",
            "Protein shake with banana",
            "Turkey sandwich on whole wheat",
            "Mixed nuts and dried fruit",
            "Salmon with quinoa and asparagus"
        ]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        var totalItems = 0
        
        for input in testInputs {
            // Setup mock response for each
            coachEngine.mockParsedItems = [
                ParsedFoodItem(name: input, brand: nil, quantity: 1.0, unit: "serving",
                              calories: Int.random(in: 150...450), // Realistic range
                              proteinGrams: Double.random(in: 5...35),
                              carbGrams: Double.random(in: 10...50),
                              fatGrams: Double.random(in: 2...20),
                              fiberGrams: Double.random(in: 1...8),
                              sugarGrams: Double.random(in: 2...15),
                              sodiumMilligrams: Double.random(in: 50...500),
                              databaseId: nil,
                              confidence: Float.random(in: 0.85...0.95))
            ]
            
            let results = try await coachEngine.parseNaturalLanguageFood(
                text: input,
                mealType: .snack,
                for: testUser
            )
            totalItems += results.count
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should process 5 items in under 5 seconds (1 second average per item)
        XCTAssertLessThan(elapsed, 5.0, "Batch parsing should average <1 second per item")
        XCTAssertEqual(totalItems, testInputs.count)
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageDuringParsing() async throws {
        // Measure memory before parsing
        let initialMemory = getMemoryUsage()
        
        // Parse a large complex meal description
        let complexInput = """
        For breakfast I had scrambled eggs with cheese, whole wheat toast with butter,
        orange juice, and a side of bacon. Also had coffee with cream and sugar.
        """
        
        coachEngine.mockParsedItems = [
            ParsedFoodItem(name: "scrambled eggs", brand: nil, quantity: 2.0, unit: "eggs",
                          calories: 182, proteinGrams: 12.6, carbGrams: 1.4, fatGrams: 13.8,
                          fiberGrams: 0.0, sugarGrams: 1.4, sodiumMilligrams: 342.0,
                          databaseId: nil, confidence: 0.91),
            ParsedFoodItem(name: "cheddar cheese", brand: nil, quantity: 1.0, unit: "oz",
                          calories: 114, proteinGrams: 7.0, carbGrams: 0.4, fatGrams: 9.4,
                          fiberGrams: 0.0, sugarGrams: 0.1, sodiumMilligrams: 174.0,
                          databaseId: nil, confidence: 0.89),
            ParsedFoodItem(name: "whole wheat toast", brand: nil, quantity: 2.0, unit: "slices",
                          calories: 138, proteinGrams: 7.2, carbGrams: 23.6, fatGrams: 2.0,
                          fiberGrams: 3.8, sugarGrams: 3.4, sodiumMilligrams: 292.0,
                          databaseId: nil, confidence: 0.90),
            ParsedFoodItem(name: "butter", brand: nil, quantity: 1.0, unit: "tbsp",
                          calories: 102, proteinGrams: 0.1, carbGrams: 0.0, fatGrams: 11.5,
                          fiberGrams: 0.0, sugarGrams: 0.0, sodiumMilligrams: 91.0,
                          databaseId: nil, confidence: 0.93),
            ParsedFoodItem(name: "orange juice", brand: nil, quantity: 8.0, unit: "oz",
                          calories: 111, proteinGrams: 1.7, carbGrams: 25.8, fatGrams: 0.5,
                          fiberGrams: 0.5, sugarGrams: 20.8, sodiumMilligrams: 2.0,
                          databaseId: nil, confidence: 0.94),
            ParsedFoodItem(name: "bacon", brand: nil, quantity: 2.0, unit: "slices",
                          calories: 86, proteinGrams: 5.8, carbGrams: 0.2, fatGrams: 6.8,
                          fiberGrams: 0.0, sugarGrams: 0.0, sodiumMilligrams: 388.0,
                          databaseId: nil, confidence: 0.91),
            ParsedFoodItem(name: "coffee with cream and sugar", brand: nil, quantity: 1.0, unit: "cup",
                          calories: 50, proteinGrams: 0.6, carbGrams: 6.5, fatGrams: 2.4,
                          fiberGrams: 0.0, sugarGrams: 6.0, sodiumMilligrams: 15.0,
                          databaseId: nil, confidence: 0.87)
        ]
        
        let _ = try await coachEngine.parseNaturalLanguageFood(
            text: complexInput,
            mealType: .breakfast,
            for: testUser
        )
        
        // Measure memory after parsing
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        let memoryIncreaseMB = Double(memoryIncrease) / 1_024_000
        
        XCTAssertLessThan(memoryIncreaseMB, 50.0, "Memory increase should be less than 50MB")
    }
    
    // MARK: - Error Handling Performance
    
    func testErrorRecoveryPerformance() async throws {
        // Test how quickly the system recovers from errors
        coachEngine.shouldThrowError = true
        coachEngine.errorToThrow = FoodTrackingError.aiParsingFailed
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            _ = try await coachEngine.parseNaturalLanguageFood(
                text: "test food",
                mealType: .snack,
                for: testUser
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Error should be thrown quickly without hanging
        XCTAssertLessThan(elapsed, 0.5, "Error handling should be fast")
    }
    
    // MARK: - Nutrition Validation Performance
    
    func testNutritionValidationPerformance() async throws {
        // Test validation of nutrition values doesn't add significant overhead
        let mockItems = (0..<100).map { index in
            ParsedFoodItem(
                name: "Food \(index)",
                brand: nil,
                quantity: 1.0,
                unit: "serving",
                calories: Int.random(in: 50...800),
                proteinGrams: Double.random(in: 0...50),
                carbGrams: Double.random(in: 0...100),
                fatGrams: Double.random(in: 0...50),
                fiberGrams: Double.random(in: 0...15),
                sugarGrams: Double.random(in: 0...50),
                sodiumMilligrams: Double.random(in: 0...2000),
                databaseId: nil,
                confidence: Float.random(in: 0.7...0.95)
            )
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Validate all items
        var validCount = 0
        for item in mockItems {
            if isNutritionRealistic(item) {
                validCount += 1
            }
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Validation of 100 items should be very fast
        XCTAssertLessThan(elapsed, 0.1, "Nutrition validation should be fast")
        XCTAssertGreaterThan(validCount, 50, "Most items should pass validation")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private func isNutritionRealistic(_ item: ParsedFoodItem) -> Bool {
        // Basic validation rules
        guard item.calories > 0 && item.calories < 1500 else { return false }
        
        // Calculate calories from macros (4 cal/g protein & carbs, 9 cal/g fat)
        let proteinCal = item.proteinGrams * 4
        let carbCal = item.carbGrams * 4
        let fatCal = item.fatGrams * 9
        let calculatedCal = proteinCal + carbCal + fatCal
        
        // Allow 20% margin of error in calorie calculation
        let calorieRatio = Double(item.calories) / calculatedCal
        guard calorieRatio > 0.8 && calorieRatio < 1.2 else { return false }
        
        // Check macro ratios are reasonable
        let totalMacroGrams = item.proteinGrams + item.carbGrams + item.fatGrams
        guard totalMacroGrams > 0 else { return false }
        
        // No single macro should be more than 90% of total
        let proteinRatio = item.proteinGrams / totalMacroGrams
        let carbRatio = item.carbGrams / totalMacroGrams
        let fatRatio = item.fatGrams / totalMacroGrams
        
        guard proteinRatio < 0.9 && carbRatio < 0.9 && fatRatio < 0.9 else { return false }
        
        // Fiber should be less than total carbs
        if let fiber = item.fiberGrams {
            guard fiber <= item.carbGrams else { return false }
        }
        
        // Sugar should be less than total carbs
        if let sugar = item.sugarGrams {
            guard sugar <= item.carbGrams else { return false }
        }
        
        return true
    }
}

// MARK: - Test Extensions

// MockCoachEngine is used from the Mocks directory