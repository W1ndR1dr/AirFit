import Foundation

// MARK: - Nutrition Preferences
struct NutritionPreferences: Sendable {
    let dietaryRestrictions: [String]
    let allergies: [String]
    let preferredUnits: String // "metric" or "imperial"
    let calorieGoal: Double?
    let proteinGoal: Double?
    let carbGoal: Double?
    let fatGoal: Double?

    static let `default` = NutritionPreferences(
        dietaryRestrictions: [],
        allergies: [],
        preferredUnits: "imperial",
        calorieGoal: nil,
        proteinGoal: nil,
        carbGoal: nil,
        fatGoal: nil
    )
}
