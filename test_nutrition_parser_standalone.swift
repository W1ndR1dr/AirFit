#!/usr/bin/env swift
import Foundation

// MARK: - Test Models (Simplified versions for standalone testing)

struct ParsedFoodItem {
    let name: String
    let brand: String?
    let quantity: Double
    let unit: String
    let calories: Int
    let proteinGrams: Double
    let carbGrams: Double
    let fatGrams: Double
    let fiberGrams: Double?
    let sugarGrams: Double?
    let sodiumMilligrams: Double?
    let confidence: Float
}

enum FoodTrackingError: Error, LocalizedError {
    case invalidNutritionResponse
    case invalidNutritionData
    
    var errorDescription: String? {
        switch self {
        case .invalidNutritionResponse:
            return "Invalid nutrition data from AI"
        case .invalidNutritionData:
            return "Malformed nutrition information"
        }
    }
}

// MARK: - Test Implementation

class NutritionParserTestRunner {
    
    /// Test helper to parse nutrition JSON (mirroring CoachEngine's private method)
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
                confidence: Float(itemDict["confidence"] as? Double ?? 0.8)
            )
        }
    }
    
    /// Test helper to validate nutrition values
    private func validateNutritionValues(_ items: [ParsedFoodItem]) -> [ParsedFoodItem] {
        return items.compactMap { item in
            // Reject obviously wrong values (mirroring private implementation)
            guard item.calories > 0 && item.calories < 5_000,
                  item.proteinGrams >= 0 && item.proteinGrams < 300,
                  item.carbGrams >= 0 && item.carbGrams < 1_000,
                  item.fatGrams >= 0 && item.fatGrams < 500 else {
                return nil
            }
            return item
        }
    }
    
    /// Load fixture file content
    private func loadFixture(_ filename: String) throws -> String {
        let currentDir = FileManager.default.currentDirectoryPath
        let fixturePath = "\(currentDir)/AirFit/AirFitTests/Fixtures/Nutrition/\(filename)"
        
        guard FileManager.default.fileExists(atPath: fixturePath),
              let content = try? String(contentsOfFile: fixturePath) else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fixture not found: \(filename)"])
        }
        
        return content
    }
    
    // MARK: - Test Cases
    
    func testValidSingleItem() -> Bool {
        print("Testing valid single item parsing...")
        do {
            let json = try loadFixture("valid_single_item.json")
            let items = try parseNutritionJSON(json)
            
            guard items.count == 1 else {
                print("❌ Expected 1 item, got \(items.count)")
                return false
            }
            
            let item = items[0]
            guard item.name == "Grilled Chicken Breast" &&
                  item.calories == 231 &&
                  item.proteinGrams == 43.5 &&
                  item.confidence == 0.95 else {
                print("❌ Item values don't match expected values")
                return false
            }
            
            print("✅ Valid single item test passed")
            return true
        } catch {
            print("❌ Valid single item test failed: \(error)")
            return false
        }
    }
    
    func testValidMultipleItems() -> Bool {
        print("Testing valid multiple items parsing...")
        do {
            let json = try loadFixture("valid_multiple_items.json")
            let items = try parseNutritionJSON(json)
            
            guard items.count == 2 else {
                print("❌ Expected 2 items, got \(items.count)")
                return false
            }
            
            guard items[0].name == "Greek Yogurt" &&
                  items[1].name == "Blueberries" else {
                print("❌ Item names don't match expected values")
                return false
            }
            
            print("✅ Valid multiple items test passed")
            return true
        } catch {
            print("❌ Valid multiple items test failed: \(error)")
            return false
        }
    }
    
    func testMissingRequiredFields() -> Bool {
        print("Testing missing required fields...")
        do {
            let json = try loadFixture("missing_required_fields.json")
            _ = try parseNutritionJSON(json)
            print("❌ Should have thrown error for missing required fields")
            return false
        } catch is FoodTrackingError {
            print("✅ Missing required fields test passed")
            return true
        } catch {
            print("❌ Wrong error type: \(error)")
            return false
        }
    }
    
    func testMalformedJSON() -> Bool {
        print("Testing malformed JSON...")
        do {
            let json = try loadFixture("malformed_json.json")
            _ = try parseNutritionJSON(json)
            print("❌ Should have thrown error for malformed JSON")
            return false
        } catch {
            print("✅ Malformed JSON test passed")
            return true
        }
    }
    
    func testExtremeValues() -> Bool {
        print("Testing extreme values validation...")
        do {
            let json = try loadFixture("extreme_values.json")
            let items = try parseNutritionJSON(json)
            let validatedItems = validateNutritionValues(items)
            
            guard validatedItems.count == 0 else {
                print("❌ Expected extreme values to be filtered out")
                return false
            }
            
            print("✅ Extreme values test passed")
            return true
        } catch {
            print("❌ Extreme values test failed: \(error)")
            return false
        }
    }
    
    func testZeroNegativeValues() -> Bool {
        print("Testing zero/negative values validation...")
        do {
            let json = try loadFixture("zero_negative_values.json")
            let items = try parseNutritionJSON(json)
            let validatedItems = validateNutritionValues(items)
            
            guard validatedItems.count == 0 else {
                print("❌ Expected zero/negative values to be filtered out")
                return false
            }
            
            print("✅ Zero/negative values test passed")
            return true
        } catch {
            print("❌ Zero/negative values test failed: \(error)")
            return false
        }
    }
    
    func testBoundaryValues() -> Bool {
        print("Testing boundary values...")
        do {
            let json = try loadFixture("boundary_values.json")
            let items = try parseNutritionJSON(json)
            let validatedItems = validateNutritionValues(items)
            
            guard validatedItems.count == 1 else {
                print("❌ Expected boundary values to be accepted")
                return false
            }
            
            let item = validatedItems[0]
            guard item.calories == 1 && item.proteinGrams == 0.1 else {
                print("❌ Boundary values not preserved correctly")
                return false
            }
            
            print("✅ Boundary values test passed")
            return true
        } catch {
            print("❌ Boundary values test failed: \(error)")
            return false
        }
    }
    
    func testSpecialCharacters() -> Bool {
        print("Testing special characters...")
        do {
            let json = try loadFixture("special_characters.json")
            let items = try parseNutritionJSON(json)
            
            guard items.count == 1 else {
                print("❌ Expected 1 item with special characters")
                return false
            }
            
            let item = items[0]
            guard item.name.contains("Café") && item.name.contains("🥛") else {
                print("❌ Special characters not preserved correctly")
                return false
            }
            
            print("✅ Special characters test passed")
            return true
        } catch {
            print("❌ Special characters test failed: \(error)")
            return false
        }
    }
    
    func runAllTests() -> (passed: Int, total: Int) {
        print("Running Nutrition Parser Tests...")
        print("================================")
        
        let tests: [() -> Bool] = [
            testValidSingleItem,
            testValidMultipleItems,
            testMissingRequiredFields,
            testMalformedJSON,
            testExtremeValues,
            testZeroNegativeValues,
            testBoundaryValues,
            testSpecialCharacters
        ]
        
        var passed = 0
        let total = tests.count
        
        for test in tests {
            if test() {
                passed += 1
            }
        }
        
        print("================================")
        print("Results: \(passed)/\(total) tests passed")
        
        if passed == total {
            print("🎉 All tests passed!")
        } else {
            print("⚠️  Some tests failed")
        }
        
        return (passed: passed, total: total)
    }
}

// MARK: - Test Execution

let runner = NutritionParserTestRunner()
let results = runner.runAllTests()
exit(results.passed == results.total ? 0 : 1)