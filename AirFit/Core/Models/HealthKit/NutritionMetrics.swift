import Foundation

/// Nutrition metrics from HealthKit
struct NutritionMetrics: Sendable {
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double
}