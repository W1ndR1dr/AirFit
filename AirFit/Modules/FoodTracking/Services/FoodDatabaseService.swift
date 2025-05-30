import Foundation
import UIKit

/// Service for food database operations and lookups.
actor FoodDatabaseService: FoodDatabaseServiceProtocol {
    // Mock database until real API integration is implemented
    private let mockDatabase: [FoodDatabaseItem] = [
        FoodDatabaseItem(
            id: "1",
            name: "Apple",
            brand: nil,
            caloriesPerServing: 95,
            proteinPerServing: 0.5,
            carbsPerServing: 25,
            fatPerServing: 0.3,
            servingSize: 1,
            servingUnit: "medium",
            defaultQuantity: 1,
            defaultUnit: "medium"
        ),
        FoodDatabaseItem(
            id: "2",
            name: "Chicken Breast",
            brand: nil,
            caloriesPerServing: 165,
            proteinPerServing: 31,
            carbsPerServing: 0,
            fatPerServing: 3.6,
            servingSize: 100,
            servingUnit: "g",
            defaultQuantity: 100,
            defaultUnit: "g"
        ),
        FoodDatabaseItem(
            id: "3",
            name: "Greek Yogurt",
            brand: "Chobani",
            caloriesPerServing: 100,
            proteinPerServing: 18,
            carbsPerServing: 6,
            fatPerServing: 0,
            servingSize: 170,
            servingUnit: "g",
            defaultQuantity: 1,
            defaultUnit: "cup"
        )
    ]

    // MARK: - FoodDatabaseServiceProtocol

    func searchFoods(query: String) async throws -> [FoodDatabaseItem] {
        try await searchFoods(query: query, limit: 25)
    }

    func getFoodDetails(id: String) async throws -> FoodDatabaseItem? {
        mockDatabase.first { $0.id == id }
    }

    func searchFoods(query: String, limit: Int) async throws -> [FoodDatabaseItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        let lowercaseQuery = query.lowercased()
        let results = mockDatabase.filter { item in
            item.name.lowercased().contains(lowercaseQuery) ||
            (item.brand?.lowercased().contains(lowercaseQuery) ?? false)
        }

        return Array(results.prefix(limit))
    }

    func lookupBarcode(_ barcode: String) async throws -> FoodDatabaseItem? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        if barcode == "123456789" {
            return FoodDatabaseItem(
                id: "barcode_1",
                name: "Protein Bar",
                brand: "Quest",
                caloriesPerServing: 200,
                proteinPerServing: 20,
                carbsPerServing: 22,
                fatPerServing: 8,
                servingSize: 1,
                servingUnit: "bar",
                defaultQuantity: 1,
                defaultUnit: "bar"
            )
        }

        return nil
    }

    func searchCommonFood(_ name: String) async throws -> FoodDatabaseItem? {
        mockDatabase.first { $0.name.lowercased() == name.lowercased() }
    }

    func analyzePhotoForFoods(_ image: UIImage) async throws -> [FoodDatabaseItem] {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 500_000_000)

        // Mock response returns all known items
        return mockDatabase
    }
}

