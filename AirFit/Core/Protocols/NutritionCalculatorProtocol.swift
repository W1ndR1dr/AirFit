import Foundation

/// Protocol for calculating dynamic nutrition targets based on body metrics and activity
protocol NutritionCalculatorProtocol: AnyObject, Sendable {
    /// Calculate personalized nutrition targets for a user
    /// - Parameter user: The user to calculate targets for
    /// - Returns: Dynamic nutrition targets including base and active calories
    func calculateDynamicTargets(for user: User) async throws -> DynamicNutritionTargets

    /// Calculate BMR using available body metrics
    /// - Parameters:
    ///   - weight: Weight in kilograms
    ///   - height: Height in centimeters
    ///   - bodyFat: Body fat percentage (optional)
    ///   - age: Age in years
    ///   - biologicalSex: Biological sex ("male" or "female")
    /// - Returns: Basal Metabolic Rate in calories
    func calculateBMR(
        weight: Double?,
        height: Double?,
        bodyFat: Double?,
        age: Int,
        biologicalSex: String?
    ) -> Double
}

/// Dynamic nutrition targets with base and activity breakdown
struct DynamicNutritionTargets: Sendable {
    let baseCalories: Double        // BMR × 1.2 (sedentary)
    let activeCalorieBonus: Double  // From Apple Watch
    let totalCalories: Double       // base + active
    let protein: Double             // grams
    let carbs: Double              // grams
    let fat: Double                // grams

    // For UI display
    var displayCalories: String {
        "\(Int(baseCalories)) + \(Int(activeCalorieBonus)) = \(Int(totalCalories))"
    }
}
