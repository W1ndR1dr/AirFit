import Foundation
import UIKit

/// Abstraction over food database lookup operations.
protocol FoodDatabaseServiceProtocol: Sendable {
    /// Search foods with default limit.
    func searchFoods(query: String) async throws -> [FoodDatabaseItem]
    /// Fetch full details for a given food identifier.
    func getFoodDetails(id: String) async throws -> FoodDatabaseItem?
    /// Search foods with explicit result limit.
    func searchFoods(query: String, limit: Int) async throws -> [FoodDatabaseItem]
    /// Lookup a common food name for quick add.
    func searchCommonFood(_ name: String) async throws -> FoodDatabaseItem?
    /// Retrieve an item using a product barcode.
    func lookupBarcode(_ barcode: String) async throws -> FoodDatabaseItem?
    /// Analyze a photo and return detected foods.
    func analyzePhotoForFoods(_ image: UIImage) async throws -> [FoodDatabaseItem]
}
