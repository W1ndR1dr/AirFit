import Foundation

/// Pure JSON parsing and validation helpers. No side effects.
struct AIParser {

    // MARK: Natural-language nutrition -> FoodTracking.ParsedFoodItem[]

    func parseFoodItemsJSON(_ jsonString: String) throws -> [ParsedFoodItem] {
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let itemsArray = json["items"] as? [[String: Any]] else {
            throw FoodTrackingError.invalidNutritionResponse
        }

        return try itemsArray.map { dict in
            guard let name = dict["name"] as? String,
                  let quantity = dict["quantity"] as? Double,
                  let unit = dict["unit"] as? String,
                  let calories = dict["calories"] as? Int,
                  let protein = dict["proteinGrams"] as? Double,
                  let carbs = dict["carbGrams"] as? Double,
                  let fat = dict["fatGrams"] as? Double else {
                throw FoodTrackingError.invalidNutritionData
            }

            return ParsedFoodItem(
                name: name,
                brand: dict["brand"] as? String,
                quantity: quantity,
                unit: unit,
                calories: calories,
                proteinGrams: protein,
                carbGrams: carbs,
                fatGrams: fat,
                fiberGrams: dict["fiberGrams"] as? Double,
                sugarGrams: dict["sugarGrams"] as? Double,
                sodiumMilligrams: dict["sodiumMilligrams"] as? Double,
                databaseId: nil,
                confidence: Float(dict["confidence"] as? Double ?? 0.8)
            )
        }
    }

    func validateFoodItems(_ items: [ParsedFoodItem]) -> [ParsedFoodItem] {
        items.compactMap { item in
            guard item.calories > 0 && item.calories < 5_000,
                  item.proteinGrams >= 0 && item.proteinGrams < 300,
                  item.carbGrams >= 0 && item.carbGrams < 1_000,
                  item.fatGrams >= 0 && item.fatGrams < 500 else {
                AppLogger.warning("Rejected invalid nutrition values for \(item.name)", category: .ai)
                return nil
            }
            return item
        }
    }

    func fallbackFoodItem(from text: String, mealType: MealType) -> ParsedFoodItem {
        let foodName = text.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? "Unknown Food"

        let defaultCalories: Int = {
            switch mealType {
            case .breakfast: return 250
            case .lunch: return 400
            case .dinner: return 500
            case .snack: return 150
            case .preWorkout: return 200
            case .postWorkout: return 300
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

    // MARK: Helpers

    func extractString(from any: AIAnyCodable?) -> String? {
        guard let v = any?.value else { return nil }
        if let s = v as? String { return s }
        if let n = v as? NSNumber { return n.stringValue }
        return String(describing: v)
    }
}