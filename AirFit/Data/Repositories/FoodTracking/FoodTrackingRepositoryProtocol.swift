import Foundation

@MainActor
protocol FoodTrackingRepositoryProtocol: Sendable {
    // MARK: - Food Entry Operations
    func save(_ foodEntry: FoodEntry) throws
    func delete(_ foodEntry: FoodEntry) throws
    func duplicate(_ foodEntry: FoodEntry, for date: Date) throws -> FoodEntry
    
    // MARK: - Data Fetching
    func getFoodEntries(for user: User, date: Date) throws -> [FoodEntry]
    func getRecentFoods(for user: User, limit: Int) throws -> [FoodItem]
    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) throws -> [FoodEntry]
    
    // MARK: - User Management
    func addFoodEntryToUser(_ entry: FoodEntry, user: User) throws
}