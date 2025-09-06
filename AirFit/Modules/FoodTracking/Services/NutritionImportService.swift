import Foundation
import SwiftData
import HealthKit

/// Service for auto-importing HealthKit nutrition data into SwiftData as synthetic entries
/// when no local entries exist for a given day
@MainActor
final class NutritionImportService: ServiceProtocol {
    private let modelContext: ModelContext
    private let healthKitManager: HealthKitManaging
    
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "nutrition-import-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }
    
    init(modelContext: ModelContext, healthKitManager: HealthKitManaging) {
        self.modelContext = modelContext
        self.healthKitManager = healthKitManager
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("NutritionImportService configured", category: .services)
    }
    
    func reset() async {
        _isConfigured = false
        AppLogger.info("NutritionImportService reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        return ServiceHealth(
            status: _isConfigured ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: [:]
        )
    }
    
    // MARK: - Public Interface
    
    /// Syncs today's HealthKit nutrition data for the specified user
    /// - Creates synthetic entry if no local entries exist
    /// - Removes synthetic entry if local entries are found
    func syncToday(for user: User) async {
        do {
            try await syncNutritionData(for: user, date: Date())
        } catch {
            AppLogger.error("Failed to sync nutrition data for today", error: error, category: .data)
        }
    }
    
    // MARK: - Private Implementation
    
    private func syncNutritionData(for user: User, date: Date) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        let userId = user.id
        
        // Check for existing entries for this day
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { entry in
                entry.user?.id == userId &&
                    entry.loggedAt >= startOfDay &&
                    entry.loggedAt < endOfDay
            }
        )
        
        let existingEntries = try modelContext.fetch(descriptor)
        
        // Separate synthetic and real entries
        let syntheticEntries = existingEntries.filter { entry in
            entry.notes?.contains("healthkit_import") == true
        }
        let realEntries = existingEntries.filter { entry in
            entry.notes?.contains("healthkit_import") != true
        }
        
        if realEntries.isEmpty {
            // No real entries - ensure we have a synthetic entry if HealthKit has data
            await ensureSyntheticEntry(for: user, date: date, existingSynthetic: syntheticEntries.first)
        } else {
            // Real entries exist - remove any synthetic entries to avoid double counting
            await removeSyntheticEntries(syntheticEntries)
        }
    }
    
    private func ensureSyntheticEntry(for user: User, date: Date, existingSynthetic: FoodEntry?) async {
        do {
            let hk = try await healthKitManager.getNutritionData(for: date)
            let healthKitNutrition = NutritionMetrics(
                calories: hk.calories,
                protein: hk.protein,
                carbohydrates: hk.carbohydrates,
                fat: hk.fat,
                fiber: hk.fiber
            )
            
            // Only create/update if HealthKit has meaningful data
            guard healthKitNutrition.calories > 0 ||
                  healthKitNutrition.protein > 0 ||
                  healthKitNutrition.carbohydrates > 0 ||
                  healthKitNutrition.fat > 0 else {
                return
            }
            
            if let existing = existingSynthetic {
                // Update existing synthetic entry
                updateSyntheticEntry(existing, with: healthKitNutrition)
            } else {
                // Create new synthetic entry
                createSyntheticEntry(for: user, date: date, with: healthKitNutrition)
            }
            
            try modelContext.save()
            AppLogger.info("Updated HealthKit synthetic nutrition entry for \(date)", category: .data)
            
        } catch {
            AppLogger.error("Failed to fetch HealthKit nutrition data", error: error, category: .data)
        }
    }
    
    private func createSyntheticEntry(for user: User, date: Date, with nutrition: NutritionMetrics) {
        let entry = FoodEntry(
            loggedAt: date,
            mealType: .snack,
            notes: "healthkit_import",
            user: user
        )
        
        let foodItem = FoodItem(
            name: "HealthKit Import",
            calories: nutrition.calories,
            proteinGrams: nutrition.protein,
            carbGrams: nutrition.carbohydrates,
            fatGrams: nutrition.fat
        )
        
        foodItem.fiberGrams = nutrition.fiber
        foodItem.dataSource = "healthkit_import"
        
        entry.addItem(foodItem)
        modelContext.insert(entry)
    }
    
    private func updateSyntheticEntry(_ entry: FoodEntry, with nutrition: NutritionMetrics) {
        // Update the first (and should be only) item
        guard let firstItem = entry.items.first else { return }
        
        firstItem.calories = nutrition.calories
        firstItem.proteinGrams = nutrition.protein
        firstItem.carbGrams = nutrition.carbohydrates
        firstItem.fatGrams = nutrition.fat
        firstItem.fiberGrams = nutrition.fiber
    }
    
    private func removeSyntheticEntries(_ entries: [FoodEntry]) async {
        guard !entries.isEmpty else { return }
        
        for entry in entries {
            modelContext.delete(entry)
        }
        
        do {
            try modelContext.save()
            AppLogger.info("Removed \(entries.count) synthetic nutrition entries", category: .data)
        } catch {
            AppLogger.error("Failed to remove synthetic nutrition entries", error: error, category: .data)
        }
    }
}
