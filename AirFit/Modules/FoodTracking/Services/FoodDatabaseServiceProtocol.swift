import Foundation

/// Protocol for food database search services
protocol FoodDatabaseServiceProtocol: Sendable {
    /// Search for foods in the database
    func searchFoods(query: String) async throws -> [FoodSearchResult]
    
    /// Get detailed information for a specific food item
    func getFoodDetails(id: String) async throws -> FoodSearchResult?
} 