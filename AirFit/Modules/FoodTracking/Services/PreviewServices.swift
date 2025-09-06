import Foundation
import SwiftData
import UIKit

#if DEBUG

/// Mock implementation of `NutritionServiceProtocol` for SwiftUI previews.
actor PreviewNutritionService: NutritionServiceProtocol {
    private var entries: [FoodEntry] = []

    func saveFoodEntry(_ entry: FoodEntry) async throws {
        entries.append(entry)
    }

    func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return entries.filter { Calendar.current.isDate($0.loggedAt, inSameDayAs: startOfDay) }
    }

    func deleteFoodEntry(_ entry: FoodEntry) async throws {
        entries.removeAll { $0.id == entry.id }
    }

    func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return entries.filter { $0.user?.id == user.id && Calendar.current.isDate($0.loggedAt, inSameDayAs: startOfDay) }
    }

    nonisolated func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary {
        var summary = FoodNutritionSummary()
        for entry in entries {
            for item in entry.items {
                summary.calories += item.calories ?? 0
                summary.protein += item.proteinGrams ?? 0
                summary.carbs += item.carbGrams ?? 0
                summary.fat += item.fatGrams ?? 0
                summary.fiber += item.fiberGrams ?? 0
                summary.sugar += item.sugarGrams ?? 0
                summary.sodium += item.sodiumMg ?? 0
            }
        }
        return summary
    }


    func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] {
        let userEntries = entries.filter { $0.user?.id == user.id }
        let recentItems = userEntries.sorted { $0.loggedAt > $1.loggedAt }.flatMap { $0.items }
        var unique: [String: FoodItem] = [:]
        for item in recentItems {
            if unique[item.name] == nil { unique[item.name] = item }
            if unique.count >= limit { break }
        }
        return Array(unique.values.prefix(limit))
    }


    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        return entries.filter { $0.user?.id == user.id && $0.mealType == mealType.rawValue && $0.loggedAt >= cutoff }
    }

    nonisolated func getTargets(from profile: OnboardingProfile?) -> NutritionTargets {
        .default
    }

    func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary {
        let todays = try await getFoodEntries(for: user, date: Date())
        var summary = calculateNutritionSummary(from: todays)
        summary.calorieGoal = NutritionTargets.default.calories
        summary.proteinGoal = NutritionTargets.default.protein
        summary.carbGoal = NutritionTargets.default.carbs
        summary.fatGoal = NutritionTargets.default.fat
        return summary
    }
}

/// Simplified implementation of `FoodCoachEngineProtocol` for previews.
actor PreviewCoachEngine: FoodCoachEngineProtocol {
    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
        ["response": .string("Preview response to \(message)")]
    }

    func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
        FunctionExecutionResult(
            success: true,
            message: "Executed \(functionCall.name)",
            executionTimeMs: 1,
            functionName: functionCall.name
        )
    }

    func analyzeMealPhoto(image: UIImage, context: NutritionContext?, for user: User) async throws -> MealPhotoAnalysisResult {
        let item = ParsedFoodItem(
            name: "Preview Meal",
            brand: nil,
            quantity: 1,
            unit: "serving",
            calories: 280,
            proteinGrams: 12,
            carbGrams: 35,
            fatGrams: 8,
            fiberGrams: 4,
            sugarGrams: 6,
            sodiumMilligrams: 320,
            databaseId: nil,
            confidence: 0.9
        )
        return MealPhotoAnalysisResult(items: [item], confidence: 0.9, processingTime: 0.1)
    }

    func searchFoods(query: String, limit: Int, for user: User) async throws -> [ParsedFoodItem] {
        // Return mock search results for previews
        return [
            ParsedFoodItem(
                name: "Mock \(query)",
                brand: nil,
                quantity: 1,
                unit: "serving",
                calories: 150,
                proteinGrams: 10,
                carbGrams: 20,
                fatGrams: 5,
                fiberGrams: 2,
                sugarGrams: 8,
                sodiumMilligrams: 300,
                databaseId: nil,
                confidence: 0.85
            )
        ]
    }

    func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
        // Return mock parsed food items for previews
        return [
            ParsedFoodItem(
                name: "Preview \(text)",
                brand: nil,
                quantity: 1.0,
                unit: "serving",
                calories: 200,
                proteinGrams: 15,
                carbGrams: 25,
                fatGrams: 8,
                fiberGrams: 3,
                sugarGrams: 5,
                sodiumMilligrams: 400,
                databaseId: nil,
                confidence: 0.8
            )
        ]
    }
}

#endif
