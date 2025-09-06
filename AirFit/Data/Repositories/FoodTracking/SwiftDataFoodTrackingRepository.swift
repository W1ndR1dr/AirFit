import Foundation
import SwiftData

@MainActor
final class SwiftDataFoodTrackingRepository: FoodTrackingRepositoryProtocol {
    private let context: ModelContext
    
    init(modelContext: ModelContext) {
        self.context = modelContext
    }
    
    // MARK: - Food Entry Operations
    
    func save(_ foodEntry: FoodEntry) throws {
        // SwiftData autosaves on changes; ensure explicit save for determinism
        try context.save()
    }
    
    func delete(_ foodEntry: FoodEntry) throws {
        context.delete(foodEntry)
        try context.save()
    }
    
    func duplicate(_ foodEntry: FoodEntry, for date: Date) throws -> FoodEntry {
        let duplicate = foodEntry.duplicate()
        duplicate.loggedAt = date
        
        context.insert(duplicate)
        try context.save()
        
        return duplicate
    }
    
    // MARK: - Data Fetching
    
    func getFoodEntries(for user: User, date: Date) throws -> [FoodEntry] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        var descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { entry in
                entry.user.id == user.id && 
                entry.loggedAt >= startOfDay && 
                entry.loggedAt < endOfDay
            },
            sortBy: [SortDescriptor(\.loggedAt, order: .forward)]
        )
        
        return try context.fetch(descriptor)
    }
    
    func getRecentFoods(for user: User, limit: Int) throws -> [FoodItem] {
        // Get recent food entries for the user
        var descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { entry in
                entry.user.id == user.id
            },
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 50 // Get more entries to find unique foods
        
        let recentEntries = try context.fetch(descriptor)
        
        // Extract unique food items based on name
        var seenFoodNames = Set<String>()
        var recentFoods: [FoodItem] = []
        
        for entry in recentEntries {
            for item in entry.items {
                if !seenFoodNames.contains(item.name) && recentFoods.count < limit {
                    seenFoodNames.insert(item.name)
                    recentFoods.append(item)
                }
            }
            
            if recentFoods.count >= limit {
                break
            }
        }
        
        return recentFoods
    }
    
    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) throws -> [FoodEntry] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        
        var descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { entry in
                entry.user.id == user.id && 
                entry.mealType == mealType &&
                entry.loggedAt >= cutoffDate
            },
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    // MARK: - User Management
    
    func addFoodEntryToUser(_ entry: FoodEntry, user: User) throws {
        user.foodEntries.append(entry)
        context.insert(entry)
        try context.save()
    }
}