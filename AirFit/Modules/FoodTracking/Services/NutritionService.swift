import Foundation
import SwiftData

/// Service for nutrition-related operations and calculations.
actor NutritionService: NutritionServiceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
    
    func getWaterIntake(for user: User, date: Date) async throws -> Double {
        // For now, return a placeholder value
        // In a real implementation, this would fetch from a water tracking model
        return 0
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
    
    func logWaterIntake(for user: User, amountML: Double, date: Date) async throws {
        // For now, this is a placeholder
        // In a real implementation, this would save to a water tracking model
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
} 