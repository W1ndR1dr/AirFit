import Foundation
import SwiftData

/// Service for nutrition-related operations and calculations.
/// @MainActor required due to SwiftData ModelContext usage (not thread-safe)
@MainActor
final class NutritionService: NutritionServiceProtocol, ServiceProtocol {
    private let modelContext: ModelContext
    private let healthKitManager: HealthKitManaging?

    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "nutrition-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }

    init(modelContext: ModelContext, healthKitManager: HealthKitManaging? = nil) {
        self.modelContext = modelContext
        self.healthKitManager = healthKitManager
    }

    // MARK: - ServiceProtocol Methods

    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("NutritionService configured", category: .services)
    }

    func reset() async {
        _isConfigured = false
        AppLogger.info("NutritionService reset", category: .services)
    }

    func healthCheck() async -> ServiceHealth {
        return ServiceHealth(
            status: _isConfigured ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: [
                "healthKitAvailable": "\(healthKitManager != nil)"
            ]
        )
    }

    // MARK: - Basic CRUD

    func saveFoodEntry(_ entry: FoodEntry) async throws {
        // 1. Save to SwiftData first (immediate UI update)
        modelContext.insert(entry)
        try modelContext.save()

        // 2. Save to HealthKit (best effort, but synchronous for now)
        do {
            guard let healthKitManager else {
                AppLogger.warning("HealthKitManager not available for food entry sync", category: .data)
                return
            }
            let sampleIDs = try await healthKitManager.saveFoodEntry(entry)
            if !sampleIDs.isEmpty {
                // Store HealthKit sample IDs for future reference
                entry.healthKitSampleIDs = sampleIDs
                entry.healthKitSyncDate = Date()
                try modelContext.save()
                AppLogger.info("Synced food entry to HealthKit with \(sampleIDs.count) samples", category: .data)
            }
        } catch {
            // Don't fail the save operation if HealthKit sync fails
            AppLogger.error("Failed to sync food entry to HealthKit", error: error, category: .data)
        }
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
        let userId = user.id

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { entry in
                entry.user?.id == userId &&
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


    func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] {
        let userId = user.id

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { entry in
                entry.user?.id == userId
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


    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let userId = user.id
        let mealTypeString = mealType.rawValue

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { entry in
                entry.user?.id == userId &&
                    entry.mealType == mealTypeString &&
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

}

// MARK: - Nutrition Targets
