import SwiftData
import Foundation

@Model
final class NutritionData: @unchecked Sendable {
    // MARK: - Properties
    var id: UUID
    var date: Date
    var targetCalories: Double?
    var targetProtein: Double?
    var targetCarbs: Double?
    var targetFat: Double?
    var actualCalories: Double = 0
    var actualProtein: Double = 0
    var actualCarbs: Double = 0
    var actualFat: Double = 0
    var waterLiters: Double = 0
    var notes: String?

    // MARK: - Relationships
    @Relationship(inverse: \FoodEntry.nutritionData)
    var foodEntries: [FoodEntry] = []

    // MARK: - Computed Properties
    var calorieDeficit: Double? {
        guard let target = targetCalories else { return nil }
        return target - actualCalories
    }

    var proteinProgress: Double {
        guard let target = targetProtein, target > 0 else { return 0 }
        return min(actualProtein / target, 1.0)
    }

    var carbsProgress: Double {
        guard let target = targetCarbs, target > 0 else { return 0 }
        return min(actualCarbs / target, 1.0)
    }

    var fatProgress: Double {
        guard let target = targetFat, target > 0 else { return 0 }
        return min(actualFat / target, 1.0)
    }

    var isComplete: Bool {
        targetCalories != nil && targetProtein != nil &&
        targetCarbs != nil && targetFat != nil
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        targetCalories: Double? = nil,
        targetProtein: Double? = nil,
        targetCarbs: Double? = nil,
        targetFat: Double? = nil
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetCarbs = targetCarbs
        self.targetFat = targetFat
    }

    // MARK: - Methods
    func updateActuals() {
        actualCalories = foodEntries.reduce(0) { $0 + $1.totalCalories }
        actualProtein = foodEntries.reduce(0) { $0 + $1.totalProtein }
        actualCarbs = foodEntries.reduce(0) { $0 + $1.totalCarbs }
        actualFat = foodEntries.reduce(0) { $0 + $1.totalFat }
    }
}
