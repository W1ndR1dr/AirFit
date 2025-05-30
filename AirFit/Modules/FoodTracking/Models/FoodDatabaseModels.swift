import Foundation

/// Models used for food database interactions.
struct FoodDatabaseItem: Identifiable, Sendable {
    /// Unique identifier from the food database.
    let id: String
    /// Food name.
    let name: String
    /// Optional brand name.
    let brand: String?
    /// Calories contained in one serving.
    let caloriesPerServing: Double
    /// Protein in grams per serving.
    let proteinPerServing: Double
    /// Carbohydrates in grams per serving.
    let carbsPerServing: Double
    /// Fat in grams per serving.
    let fatPerServing: Double
    /// Nominal serving size amount.
    let servingSize: Double
    /// Unit for the serving size.
    let servingUnit: String
    /// Default quantity to prefill when adding.
    let defaultQuantity: Double
    /// Default unit to prefill when adding.
    let defaultUnit: String

    /// Human readable serving description.
    var servingDescription: String {
        "\(servingSize.formatted()) \(servingUnit)"
    }
}

/// Context information for nutrition related AI operations.
struct NutritionContext: Sendable {
    let userPreferences: NutritionPreferences?
    let recentMeals: [FoodItem]
    let timeOfDay: Date
}
