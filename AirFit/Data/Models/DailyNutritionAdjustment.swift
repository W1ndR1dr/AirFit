import SwiftData
import Foundation

/// Records an applied daily nutrition target adjustment for transparency and trend analysis.
@Model
final class DailyNutritionAdjustment: @unchecked Sendable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var userID: UUID

    // Percent adjustments applied (e.g., 0.08 = +8%)
    var percent: Double

    // Resulting targets after adjustment (for traceability)
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double

    // Optional rationale for UI/debug
    var rationale: String?

    init(
        id: UUID = UUID(),
        date: Date,
        userID: UUID,
        percent: Double,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double,
        rationale: String? = nil
    ) {
        self.id = id
        self.date = date
        self.userID = userID
        self.percent = percent
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.rationale = rationale
    }
}

