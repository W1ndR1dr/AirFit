import Foundation
import SwiftData
import XCTest
@testable import AirFit

/// Mock implementation of NutritionServiceProtocol for testing
final class MockNutritionService: NutritionServiceProtocol, MockProtocol, @unchecked Sendable {
    // MARK: - MockProtocol
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

    // MARK: - Error Control
    var shouldThrowError = false
    var errorToThrow: Error = AppError.unknown(message: "Mock nutrition service error")

    // MARK: - Data Storage
    private var foodEntries: [UUID: FoodEntry] = [:]
    private var waterIntakes: [String: Double] = [:] // Key: "userId-date"

    // MARK: - Stubbed Responses
    var stubbedSummary: FoodNutritionSummary?
    var stubbedTargets: NutritionTargets?
    var stubbedRecentFoods: [FoodItem] = []

    // Test-specific properties
    var foodEntriesToReturn: [FoodEntry] = []
    var nutritionSummaryToReturn: FoodNutritionSummary?
    var waterIntakeToReturn: Double = 0
    var recentFoodsToReturn: [FoodItem] = []
    var targetsToReturn: NutritionTargets?
    var mealHistoryToReturn: [FoodEntry] = []
    var loggedWaterAmount: Double?
    var loggedWaterDate: Date?

    init() {
        // Set up default stubs
        stubbedSummary = FoodNutritionSummary(
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            calorieGoal: 2_000,
            proteinGoal: 150,
            carbGoal: 250,
            fatGoal: 65
        )

        stubbedTargets = NutritionTargets(
            calories: 2_000,
            protein: 150,
            carbs: 250,
            fat: 65,
            fiber: 25,
            water: 3_000
        )
    }

    // MARK: - NutritionServiceProtocol
    func saveFoodEntry(_ entry: FoodEntry) async throws {
        recordInvocation("saveFoodEntry", arguments: entry.id)

        if shouldThrowError {
            throw errorToThrow
        }

        foodEntries[entry.id] = entry
    }

    func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
        recordInvocation("getFoodEntries", arguments: date)

        if shouldThrowError {
            throw errorToThrow
        }

        let calendar = Calendar.current
        return foodEntries.values.filter { entry in
            calendar.isDate(entry.loggedAt, inSameDayAs: date)
        }.sorted { $0.loggedAt < $1.loggedAt }
    }

    func deleteFoodEntry(_ entry: FoodEntry) async throws {
        recordInvocation("deleteFoodEntry", arguments: entry.id)

        if shouldThrowError {
            throw errorToThrow
        }

        foodEntries.removeValue(forKey: entry.id)
    }

    func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
        recordInvocation("getFoodEntriesForUser", arguments: user.id, date)

        if shouldThrowError {
            throw errorToThrow
        }

        let calendar = Calendar.current
        return foodEntries.values.filter { entry in
            entry.user?.id == user.id &&
                calendar.isDate(entry.loggedAt, inSameDayAs: date)
        }.sorted { $0.loggedAt < $1.loggedAt }
    }

    nonisolated func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary {
        // Note: Can't use recordInvocation here due to nonisolated

        var summary = FoodNutritionSummary(
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            calorieGoal: 2_000,
            proteinGoal: 150,
            carbGoal: 250,
            fatGoal: 65
        )

        for entry in entries {
            summary.calories += Double(entry.totalCalories)
            summary.protein += entry.totalProtein
            summary.carbs += entry.totalCarbs
            summary.fat += entry.totalFat

            // Sum up fiber, sugar, and sodium from individual food items
            for item in entry.items {
                summary.fiber += item.fiberGrams ?? 0
                summary.sugar += item.sugarGrams ?? 0
                summary.sodium += (item.sodiumMg ?? 0) / 1_000.0 // Convert mg to g for consistency
            }
        }

        return summary
    }

    func getWaterIntake(for user: User, date: Date) async throws -> Double {
        recordInvocation("getWaterIntake", arguments: user.id, date)

        if shouldThrowError {
            throw errorToThrow
        }

        let key = waterIntakeKey(userId: user.id, date: date)
        return waterIntakes[key] ?? 0
    }

    func updateWaterIntake(for user: User, date: Date, amount: Double) async throws {
        recordInvocation("updateWaterIntake", arguments: user.id, date, amount)

        if shouldThrowError {
            throw errorToThrow
        }

        let key = waterIntakeKey(userId: user.id, date: date)
        waterIntakes[key] = amount
    }

    func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] {
        recordInvocation("getRecentFoods", arguments: user.id, limit)

        if shouldThrowError {
            throw errorToThrow
        }

        if !stubbedRecentFoods.isEmpty {
            return Array(stubbedRecentFoods.prefix(limit))
        }

        // Return unique food items from recent entries
        let recentEntries = foodEntries.values
            .filter { $0.user?.id == user.id }
            .sorted { $0.loggedAt > $1.loggedAt }
            .prefix(limit * 2) // Get more entries to ensure unique foods

        var uniqueFoods: [FoodItem] = []
        var seenNames = Set<String>()

        for entry in recentEntries {
            for foodItem in entry.items {
                if !seenNames.contains(foodItem.name) {
                    uniqueFoods.append(foodItem)
                    seenNames.insert(foodItem.name)

                    if uniqueFoods.count >= limit {
                        break
                    }
                }
            }
            if uniqueFoods.count >= limit {
                break
            }
        }

        return uniqueFoods
    }

    func logWaterIntake(for user: User, amountML: Double, date: Date) async throws {
        recordInvocation("logWaterIntake", arguments: user.id, amountML, date)

        if shouldThrowError {
            throw errorToThrow
        }

        let key = waterIntakeKey(userId: user.id, date: date)
        let currentIntake = waterIntakes[key] ?? 0
        waterIntakes[key] = currentIntake + amountML
    }

    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
        recordInvocation("getMealHistory", arguments: user.id, mealType, daysBack)

        if shouldThrowError {
            throw errorToThrow
        }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: endDate) else {
            return []
        }

        return foodEntries.values.filter { entry in
            entry.user?.id == user.id &&
                entry.mealType == mealType.rawValue &&
                entry.loggedAt >= startDate &&
                entry.loggedAt <= endDate
        }.sorted { $0.loggedAt < $1.loggedAt }
    }

    nonisolated func getTargets(from profile: OnboardingProfile?) -> NutritionTargets {
        // Return stubbed targets or defaults
        return NutritionTargets(
            calories: 2_000,
            protein: 150,
            carbs: 250,
            fat: 65,
            fiber: 25,
            water: 3_000
        )
    }

    func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary {
        recordInvocation("getTodaysSummary", arguments: user.id)

        if shouldThrowError {
            throw errorToThrow
        }

        if let stubbed = stubbedSummary {
            return stubbed
        }

        let todaysEntries = try await getFoodEntries(for: user, date: Date())
        return calculateNutritionSummary(from: todaysEntries)
    }

    // MARK: - Test Helpers
    private func waterIntakeKey(userId: UUID, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(userId)-\(formatter.string(from: date))"
    }

    func stubSummary(_ summary: FoodNutritionSummary) {
        stubbedSummary = summary
    }

    func stubTargets(_ targets: NutritionTargets) {
        stubbedTargets = targets
    }

    func stubRecentFoods(_ foods: [FoodItem]) {
        stubbedRecentFoods = foods
    }

    func addTestFoodEntry(_ entry: FoodEntry) {
        mockLock.lock()
        defer { mockLock.unlock() }
        foodEntries[entry.id] = entry
    }

    func verifyFoodEntrySaved(withId id: UUID) -> Bool {
        mockLock.lock()
        defer { mockLock.unlock() }
        return foodEntries[id] != nil
    }

    func verifyWaterIntake(for userId: UUID, date: Date) -> Double {
        mockLock.lock()
        defer { mockLock.unlock() }
        let key = waterIntakeKey(userId: userId, date: date)
        return waterIntakes[key] ?? 0
    }

    func resetAllData() {
        mockLock.lock()
        defer { mockLock.unlock() }
        foodEntries.removeAll()
        waterIntakes.removeAll()
        stubbedRecentFoods.removeAll()
    }
}
