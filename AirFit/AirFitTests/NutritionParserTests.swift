import XCTest
@testable import AirFit

final class NutritionParserTests: XCTestCase {
    private var parser: AIParser!
    private var fixturesPath: String!
    
    override func setUp() {
        super.setUp()
        parser = AIParser()
        fixturesPath = Bundle.main.path(forResource: "AirFitTests", ofType: nil)! + "/Fixtures/Nutrition"
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func loadFixture(_ filename: String) -> String {
        let path = "\(fixturesPath!)/\(filename)"
        return try! String(contentsOfFile: path, encoding: .utf8)
    }
    
    private func loadFixtureData(_ filename: String) -> Data {
        let path = "\(fixturesPath!)/\(filename)"
        return try! Data(contentsOf: URL(fileURLWithPath: path))
    }
    
    // MARK: - Valid JSON Parsing Tests
    
    func testParseFoodItemsJSON_ValidSingleItem_ReturnsCorrectData() throws {
        let json = loadFixture("valid_single_item.json")
        
        let items = try parser.parseFoodItemsJSON(json)
        
        XCTAssertEqual(items.count, 1)
        let item = items[0]
        XCTAssertEqual(item.name, "Grilled Chicken Breast")
        XCTAssertNil(item.brand)
        XCTAssertEqual(item.quantity, 1.0)
        XCTAssertEqual(item.unit, "serving")
        XCTAssertEqual(item.calories, 231)
        XCTAssertEqual(item.proteinGrams, 43.5)
        XCTAssertEqual(item.carbGrams, 0.0)
        XCTAssertEqual(item.fatGrams, 5.0)
        XCTAssertEqual(item.fiberGrams, 0.0)
        XCTAssertEqual(item.sugarGrams, 0.0)
        XCTAssertEqual(item.sodiumMilligrams, 104.0)
        XCTAssertEqual(item.confidence, 0.95)
    }
    
    func testParseFoodItemsJSON_ValidMultipleItems_ReturnsAllItems() throws {
        let json = loadFixture("valid_multiple_items.json")
        
        let items = try parser.parseFoodItemsJSON(json)
        
        XCTAssertEqual(items.count, 3)
        
        // First item: Greek Yogurt
        let yogurt = items[0]
        XCTAssertEqual(yogurt.name, "Greek Yogurt")
        XCTAssertEqual(yogurt.brand, "Chobani")
        XCTAssertEqual(yogurt.quantity, 1.0)
        XCTAssertEqual(yogurt.unit, "cup")
        XCTAssertEqual(yogurt.calories, 130)
        XCTAssertEqual(yogurt.proteinGrams, 23.0)
        XCTAssertEqual(yogurt.confidence, 0.92)
        
        // Second item: Blueberries
        let blueberries = items[1]
        XCTAssertEqual(blueberries.name, "Blueberries")
        XCTAssertNil(blueberries.brand)
        XCTAssertEqual(blueberries.quantity, 0.5)
        XCTAssertEqual(blueberries.unit, "cup")
        XCTAssertEqual(blueberries.calories, 42)
        XCTAssertEqual(blueberries.fiberGrams, 1.8)
        
        // Third item: Granola
        let granola = items[2]
        XCTAssertEqual(granola.name, "Granola")
        XCTAssertEqual(granola.brand, "Nature Valley")
        XCTAssertEqual(granola.quantity, 2.0)
        XCTAssertEqual(granola.unit, "tbsp")
    }
    
    func testParseFoodItemsJSON_MinimalValid_HandlesOptionalFields() throws {
        let json = loadFixture("minimal_valid.json")
        
        let items = try parser.parseFoodItemsJSON(json)
        
        XCTAssertEqual(items.count, 1)
        let item = items[0]
        XCTAssertEqual(item.name, "Apple")
        XCTAssertNil(item.brand)
        XCTAssertEqual(item.calories, 95)
        XCTAssertNil(item.fiberGrams)  // Optional fields should be nil when missing
        XCTAssertNil(item.sugarGrams)
        XCTAssertNil(item.sodiumMilligrams)
        XCTAssertEqual(item.confidence, 0.8) // Should use default from dict
    }
    
    func testParseFoodItemsJSON_LargeBatch_HandlesMultipleItems() throws {
        let json = loadFixture("large_batch.json")
        
        let items = try parser.parseFoodItemsJSON(json)
        
        XCTAssertGreaterThan(items.count, 5) // Large batch should have many items
        
        // Verify each item has required fields
        for item in items {
            XCTAssertFalse(item.name.isEmpty)
            XCTAssertGreaterThan(item.quantity, 0)
            XCTAssertFalse(item.unit.isEmpty)
            XCTAssertGreaterThanOrEqual(item.calories, 0)
            XCTAssertGreaterThanOrEqual(item.proteinGrams, 0)
            XCTAssertGreaterThanOrEqual(item.carbGrams, 0)
            XCTAssertGreaterThanOrEqual(item.fatGrams, 0)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testParseFoodItemsJSON_MalformedJSON_ThrowsInvalidNutritionResponse() {
        let json = loadFixture("malformed_json.json")
        
        XCTAssertThrowsError(try parser.parseFoodItemsJSON(json)) { error in
            XCTAssertEqual(error as? FoodTrackingError, .invalidNutritionResponse)
        }
    }
    
    func testParseFoodItemsJSON_EmptyItems_ReturnsEmptyArray() throws {
        let json = loadFixture("empty_items.json")
        
        let items = try parser.parseFoodItemsJSON(json)
        
        XCTAssertEqual(items.count, 0)
    }
    
    func testParseFoodItemsJSON_MissingRequiredFields_ThrowsInvalidNutritionData() {
        let json = loadFixture("invalid_missing_required_fields.json")
        
        XCTAssertThrowsError(try parser.parseFoodItemsJSON(json)) { error in
            XCTAssertEqual(error as? FoodTrackingError, .invalidNutritionData)
        }
    }
    
    func testParseFoodItemsJSON_WrongTypes_ThrowsInvalidNutritionData() {
        let json = loadFixture("invalid_wrong_types.json")
        
        XCTAssertThrowsError(try parser.parseFoodItemsJSON(json)) { error in
            XCTAssertEqual(error as? FoodTrackingError, .invalidNutritionData)
        }
    }
    
    func testParseFoodItemsJSON_MissingItemsArray_ThrowsInvalidNutritionResponse() {
        let json = loadFixture("invalid_missing_items.json")
        
        XCTAssertThrowsError(try parser.parseFoodItemsJSON(json)) { error in
            XCTAssertEqual(error as? FoodTrackingError, .invalidNutritionResponse)
        }
    }
    
    func testParseFoodItemsJSON_InvalidUTF8_ThrowsInvalidNutritionResponse() {
        let invalidData = Data([0xFF, 0xFE]) // Invalid UTF-8
        let invalidString = String(data: invalidData, encoding: .utf8) ?? ""
        
        XCTAssertThrowsError(try parser.parseFoodItemsJSON(invalidString)) { error in
            XCTAssertEqual(error as? FoodTrackingError, .invalidNutritionResponse)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testParseFoodItemsJSON_ZeroValues_HandlesCorrectly() throws {
        let json = loadFixture("edge_case_zero_values.json")
        
        let items = try parser.parseFoodItemsJSON(json)
        
        XCTAssertEqual(items.count, 1)
        let item = items[0]
        XCTAssertEqual(item.calories, 0)
        XCTAssertEqual(item.proteinGrams, 0.0)
        XCTAssertEqual(item.carbGrams, 0.0)
        XCTAssertEqual(item.fatGrams, 0.0)
    }
    
    func testParseFoodItemsJSON_LargeValues_HandlesCorrectly() throws {
        let json = loadFixture("edge_case_large_values.json")
        
        let items = try parser.parseFoodItemsJSON(json)
        
        XCTAssertEqual(items.count, 1)
        let item = items[0]
        XCTAssertGreaterThan(item.calories, 1000)
        XCTAssertGreaterThan(item.proteinGrams, 100)
    }
    
    // MARK: - Validation Tests
    
    func testValidateFoodItems_ValidItems_ReturnsAllItems() {
        let validItems = [
            ParsedFoodItem(
                name: "Banana",
                brand: nil,
                quantity: 1.0,
                unit: "medium",
                calories: 105,
                proteinGrams: 1.3,
                carbGrams: 27.0,
                fatGrams: 0.4,
                fiberGrams: 3.1,
                sugarGrams: 14.4,
                sodiumMilligrams: 1.0,
                databaseId: nil,
                confidence: 0.95
            )
        ]
        
        let validatedItems = parser.validateFoodItems(validItems)
        
        XCTAssertEqual(validatedItems.count, 1)
        XCTAssertEqual(validatedItems[0].name, "Banana")
    }
    
    func testValidateFoodItems_ExtremeValues_FiltersOutInvalid() throws {
        let json = loadFixture("extreme_values.json")
        let items = try parser.parseFoodItemsJSON(json)
        
        let validatedItems = parser.validateFoodItems(items)
        
        // Extreme values should be filtered out
        XCTAssertEqual(validatedItems.count, 0)
    }
    
    func testValidateFoodItems_MixedValidAndInvalid_ReturnsOnlyValid() {
        let mixedItems = [
            // Valid item
            ParsedFoodItem(
                name: "Apple",
                brand: nil,
                quantity: 1.0,
                unit: "medium",
                calories: 95,
                proteinGrams: 0.5,
                carbGrams: 25.0,
                fatGrams: 0.3,
                fiberGrams: 4.0,
                sugarGrams: 19.0,
                sodiumMilligrams: 2.0,
                databaseId: nil,
                confidence: 0.9
            ),
            // Invalid item - extreme calories
            ParsedFoodItem(
                name: "Extreme Food",
                brand: nil,
                quantity: 1.0,
                unit: "serving",
                calories: 10000, // Too high
                proteinGrams: 10.0,
                carbGrams: 20.0,
                fatGrams: 5.0,
                fiberGrams: nil,
                sugarGrams: nil,
                sodiumMilligrams: nil,
                databaseId: nil,
                confidence: 0.5
            ),
            // Invalid item - negative protein
            ParsedFoodItem(
                name: "Negative Food",
                brand: nil,
                quantity: 1.0,
                unit: "serving",
                calories: 100,
                proteinGrams: -5.0, // Negative values should be invalid
                carbGrams: 20.0,
                fatGrams: 5.0,
                fiberGrams: nil,
                sugarGrams: nil,
                sodiumMilligrams: nil,
                databaseId: nil,
                confidence: 0.8
            )
        ]
        
        let validatedItems = parser.validateFoodItems(mixedItems)
        
        XCTAssertEqual(validatedItems.count, 1)
        XCTAssertEqual(validatedItems[0].name, "Apple")
    }
    
    // MARK: - Fallback Food Item Tests
    
    func testFallbackFoodItem_Breakfast_ReturnsCorrectDefaults() {
        let fallbackItem = parser.fallbackFoodItem(from: "scrambled eggs with toast", mealType: .breakfast)
        
        XCTAssertEqual(fallbackItem.name, "scrambled")
        XCTAssertNil(fallbackItem.brand)
        XCTAssertEqual(fallbackItem.quantity, 1.0)
        XCTAssertEqual(fallbackItem.unit, "serving")
        XCTAssertEqual(fallbackItem.calories, 250)
        XCTAssertEqual(fallbackItem.confidence, 0.3)
        
        // Check macro distribution (15% protein, 50% carbs, 35% fat)
        let expectedProtein = Double(250) * 0.15 / 4
        let expectedCarbs = Double(250) * 0.50 / 4
        let expectedFat = Double(250) * 0.35 / 9
        
        XCTAssertEqual(fallbackItem.proteinGrams, expectedProtein, accuracy: 0.1)
        XCTAssertEqual(fallbackItem.carbGrams, expectedCarbs, accuracy: 0.1)
        XCTAssertEqual(fallbackItem.fatGrams, expectedFat, accuracy: 0.1)
        XCTAssertEqual(fallbackItem.fiberGrams, 3.0)
    }
    
    func testFallbackFoodItem_Dinner_ReturnsCorrectDefaults() {
        let fallbackItem = parser.fallbackFoodItem(from: "pasta with meat sauce", mealType: .dinner)
        
        XCTAssertEqual(fallbackItem.name, "pasta")
        XCTAssertEqual(fallbackItem.calories, 500) // Dinner default
        XCTAssertEqual(fallbackItem.confidence, 0.3)
    }
    
    func testFallbackFoodItem_PostWorkout_ReturnsCorrectDefaults() {
        let fallbackItem = parser.fallbackFoodItem(from: "protein shake", mealType: .postWorkout)
        
        XCTAssertEqual(fallbackItem.name, "protein")
        XCTAssertEqual(fallbackItem.calories, 300) // Post-workout default
        XCTAssertEqual(fallbackItem.confidence, 0.3)
    }
    
    func testFallbackFoodItem_EmptyInput_ReturnsUnknownFood() {
        let fallbackItem = parser.fallbackFoodItem(from: "", mealType: .snack)
        
        XCTAssertEqual(fallbackItem.name, "Unknown Food")
        XCTAssertEqual(fallbackItem.calories, 150) // Snack default
    }
    
    func testFallbackFoodItem_WhitespaceOnlyInput_ReturnsUnknownFood() {
        let fallbackItem = parser.fallbackFoodItem(from: "   \n\t  ", mealType: .lunch)
        
        XCTAssertEqual(fallbackItem.name, "Unknown Food")
        XCTAssertEqual(fallbackItem.calories, 400) // Lunch default
    }
    
    // MARK: - Confidence Score Tests
    
    func testParseFoodItemsJSON_ConfidenceDefault_AppliesCorrectly() throws {
        let jsonWithoutConfidence = """
        {
            "items": [
                {
                    "name": "Test Food",
                    "brand": null,
                    "quantity": 1.0,
                    "unit": "serving",
                    "calories": 100,
                    "proteinGrams": 10.0,
                    "carbGrams": 10.0,
                    "fatGrams": 5.0
                }
            ]
        }
        """
        
        let items = try parser.parseFoodItemsJSON(jsonWithoutConfidence)
        
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].confidence, 0.8) // Default confidence
    }
    
    // MARK: - Boundary Value Tests
    
    func testValidateFoodItems_BoundaryValues_ValidatesCorrectly() {
        let boundaryItems = [
            // At the edge of valid ranges
            ParsedFoodItem(name: "High Calorie", brand: nil, quantity: 1.0, unit: "serving", 
                          calories: 4999, proteinGrams: 299, carbGrams: 999, fatGrams: 499,
                          fiberGrams: nil, sugarGrams: nil, sodiumMilligrams: nil, databaseId: nil, confidence: 0.5),
            
            // Just over the edge - should be filtered
            ParsedFoodItem(name: "Too High Calorie", brand: nil, quantity: 1.0, unit: "serving",
                          calories: 5000, proteinGrams: 10, carbGrams: 20, fatGrams: 5,
                          fiberGrams: nil, sugarGrams: nil, sodiumMilligrams: nil, databaseId: nil, confidence: 0.5),
            
            // Minimum values
            ParsedFoodItem(name: "Minimal", brand: nil, quantity: 1.0, unit: "serving",
                          calories: 1, proteinGrams: 0, carbGrams: 0, fatGrams: 0,
                          fiberGrams: nil, sugarGrams: nil, sodiumMilligrams: nil, databaseId: nil, confidence: 0.5)
        ]
        
        let validatedItems = parser.validateFoodItems(boundaryItems)
        
        XCTAssertEqual(validatedItems.count, 2) // First and third items should pass
        XCTAssertEqual(validatedItems[0].name, "High Calorie")
        XCTAssertEqual(validatedItems[1].name, "Minimal")
    }
}