import Foundation
import SwiftData

/// Implementation of DashboardNutritionServiceProtocol
@MainActor
final class DashboardNutritionService: DashboardNutritionServiceProtocol {
    private let modelContext: ModelContext
    private let nutritionCalculator: NutritionCalculatorProtocol

    init(modelContext: ModelContext, nutritionCalculator: NutritionCalculatorProtocol) {
        self.modelContext = modelContext
        self.nutritionCalculator = nutritionCalculator
    }

    func getTodaysSummary(for user: User) async throws -> NutritionSummary {
        // Fetch today's food entries
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let userID = user.id
        let predicate = #Predicate<FoodEntry> { entry in
            if let entryUser = entry.user {
                return entryUser.id == userID &&
                    entry.loggedAt >= startOfDay &&
                    entry.loggedAt < endOfDay
            } else {
                return false
            }
        }

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.loggedAt)]
        )

        let entries = try modelContext.fetch(descriptor)

        // Calculate totals
        var calories = 0.0
        var protein = 0.0
        var carbs = 0.0
        var fat = 0.0
        var fiber = 0.0

        for entry in entries {
            calories += Double(entry.totalCalories)
            protein += entry.totalProtein
            carbs += entry.totalCarbs
            fat += entry.totalFat

            for item in entry.items {
                fiber += item.fiberGrams ?? 0
            }
        }

        // Get dynamic targets from NutritionCalculator
        let dynamicTargets = try await nutritionCalculator.calculateDynamicTargets(for: user)

        return NutritionSummary(
            calories: calories,
            caloriesTarget: dynamicTargets.totalCalories,
            protein: protein,
            proteinTarget: dynamicTargets.protein,
            carbs: carbs,
            carbsTarget: dynamicTargets.carbs,
            fat: fat,
            fatTarget: dynamicTargets.fat,
            fiber: fiber,
            fiberTarget: 25.0, // Default fiber recommendation
            mealCount: entries.count,
            meals: entries
        )
    }
}
