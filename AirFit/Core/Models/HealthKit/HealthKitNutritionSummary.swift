import Foundation

/// Summary of nutrition data from HealthKit
struct HealthKitNutritionSummary: Sendable {
    let date: Date
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
}