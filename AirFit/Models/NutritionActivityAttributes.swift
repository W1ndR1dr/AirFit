import ActivityKit
import Foundation

/// ActivityAttributes for the Nutrition tracking Live Activity.
/// Shows real-time macro progress on the Lock Screen and Dynamic Island.
struct NutritionActivityAttributes: ActivityAttributes {
    /// Static context that doesn't change during the activity
    struct ContentState: Codable, Hashable {
        var calories: Int
        var protein: Int
        var carbs: Int
        var fat: Int

        var targetCalories: Int
        var targetProtein: Int
        var targetCarbs: Int
        var targetFat: Int

        var isTrainingDay: Bool
        var lastUpdated: Date

        // Computed progress values (0.0 - 1.0+)
        var calorieProgress: Double {
            guard targetCalories > 0 else { return 0 }
            return Double(calories) / Double(targetCalories)
        }

        var proteinProgress: Double {
            guard targetProtein > 0 else { return 0 }
            return Double(protein) / Double(targetProtein)
        }

        var carbProgress: Double {
            guard targetCarbs > 0 else { return 0 }
            return Double(carbs) / Double(targetCarbs)
        }

        var fatProgress: Double {
            guard targetFat > 0 else { return 0 }
            return Double(fat) / Double(targetFat)
        }

        // Remaining amounts
        var proteinRemaining: Int {
            max(0, targetProtein - protein)
        }

        var caloriesRemaining: Int {
            targetCalories - calories // Can be negative
        }
    }

    // The date this tracking started (for context)
    var date: Date
}
