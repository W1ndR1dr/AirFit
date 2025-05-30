import Foundation
import SwiftData
import HealthKit

/// Service for nutrition-related operations and calculations.
actor NutritionService: NutritionServiceProtocol {
    private let modelContext: ModelContext
    private let healthStore = HKHealthStore()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Basic CRUD

    func saveFoodEntry(_ entry: FoodEntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { entry in
                entry.loggedAt >= startOfDay &&
                entry.loggedAt < endOfDay
            },
            sortBy: [SortDescriptor(\.loggedAt)]
        )

        return try modelContext.fetch(descriptor)
    }

    func deleteFoodEntry(_ entry: FoodEntry) async throws {
        modelContext.delete(entry)
        try modelContext.save()
    }
    
    func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { entry in
                entry.user?.id == user.id &&
                entry.loggedAt >= startOfDay &&
                entry.loggedAt < endOfDay
            },
            sortBy: [SortDescriptor(\.loggedAt)]
        )
        
        return try modelContext.fetch(descriptor)
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
    
    func getWaterIntake(for user: User, date: Date) async throws -> Double {
        // Placeholder implementation. In a complete app this would fetch from a
        // dedicated WaterIntake entity.
        return 0
    }
    
    func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] {
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { entry in
                entry.user?.id == user.id
            },
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )
        
        let recentEntries = try modelContext.fetch(descriptor).prefix(limit * 2)
        let recentItems = recentEntries.flatMap { $0.items }
        
        // Remove duplicates by name and return most recent
        var uniqueItems: [String: FoodItem] = [:]
        for item in recentItems {
            if uniqueItems[item.name] == nil {
                uniqueItems[item.name] = item
            }
        }
        
        return Array(uniqueItems.values.prefix(limit))
    }
    
    func logWaterIntake(for user: User, amountML: Double, date: Date) async throws {
        // Placeholder implementation. Would create a WaterIntake model and save
        // a HealthKit sample of type `.dietaryWater`.
    }
    
    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { entry in
                entry.user?.id == user.id &&
                entry.mealType == mealType.rawValue &&
                entry.loggedAt >= cutoffDate
            },
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Nutrition Targets
    nonisolated func getTargets(from profile: OnboardingProfile?) -> NutritionTargets {
        guard let _ = profile else {
            return .default
        }

        // Placeholder implementation - real logic would use profile data.
        return .default
    }

    // MARK: - Daily Summary
    func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary {
        let entries = try await getFoodEntries(for: user, date: Date())
        var summary = calculateNutritionSummary(from: entries)

        if let profile = user.onboardingProfile {
            let targets = getTargets(from: profile)
            summary.calorieGoal = targets.calories
            summary.proteinGoal = targets.protein
            summary.carbGoal = targets.carbs
            summary.fatGoal = targets.fat
        }

        return summary
    }

    // MARK: - HealthKit Sync
    func syncCaloriesToHealthKit(for user: User, date: Date) async throws {
        guard HKHealthStore.isHealthDataAvailable(),
              let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            return
        }

        let status = healthStore.authorizationStatus(for: energyType)
        guard status == .sharingAuthorized else { return }

        let entries = try await getFoodEntries(for: user, date: date)
        let summary = calculateNutritionSummary(from: entries)
        guard summary.calories > 0 else { return }

        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: summary.calories)
        let sample = HKQuantitySample(type: energyType, quantity: quantity, start: date, end: date)

        try await withCheckedThrowingContinuation { continuation in
            healthStore.save(sample) { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }
}

// MARK: - Nutrition Targets
struct NutritionTargets: Sendable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let water: Double

    static let `default` = NutritionTargets(
        calories: 2_000,
        protein: 50,
        carbs: 250,
        fat: 65,
        fiber: 25,
        water: 2_000
    )
}
