import Foundation
import SwiftData

/// Protocol for nutrition data management services
protocol NutritionServiceProtocol: Sendable {
    /// Save a food entry to the database
    func saveFoodEntry(_ entry: FoodEntry) async throws
    
    /// Get food entries for a specific date
    func getFoodEntries(for date: Date) async throws -> [FoodEntry]
    
    /// Delete a food entry from the database
    func deleteFoodEntry(_ entry: FoodEntry) async throws
} 