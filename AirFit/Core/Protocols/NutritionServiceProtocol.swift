import Foundation
import SwiftData

/// Abstraction for nutrition-related data operations and calculations.
protocol NutritionServiceProtocol: Sendable {
    /// Persist a new `FoodEntry` to the data store.
    func saveFoodEntry(_ entry: FoodEntry) async throws

    /// Retrieve all food entries for the given date.
    func getFoodEntries(for date: Date) async throws -> [FoodEntry]

    /// Remove the specified `FoodEntry` from the data store.
    func deleteFoodEntry(_ entry: FoodEntry) async throws

    /// Retrieves all `FoodEntry` objects for the specified user and date.
    func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry]

    /// Calculates a nutrition summary from a collection of entries.
    nonisolated func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary

    /// Returns the amount of water consumed on a given day in milliliters.
    func getWaterIntake(for user: User, date: Date) async throws -> Double

    /// Retrieves the most recent foods logged by the user.
    func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem]

    /// Logs water intake for a user at the specified date.
    func logWaterIntake(for user: User, amountML: Double, date: Date) async throws

    /// Returns the meal history for a particular meal type and time span.
    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry]

    /// Nutrition targets derived from the onboarding profile.
    nonisolated func getTargets(from profile: OnboardingProfile?) -> NutritionTargets

    /// Convenience helper to generate today's nutrition summary.
    func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary
}
