import Foundation

/// Service for food database operations and lookups.
actor FoodDatabaseService: FoodDatabaseServiceProtocol {
    
    func searchCommonFood(_ name: String) async throws -> FoodDatabaseItem? {
        // Mock implementation with common foods
        let commonFoods: [String: FoodDatabaseItem] = [
            "apple": FoodDatabaseItem(
                id: "apple_001",
                name: "Apple",
                brand: nil,
                defaultQuantity: 1,
                defaultUnit: "medium",
                servingUnit: "medium",
                caloriesPerServing: 95,
                proteinPerServing: 0.5,
                carbsPerServing: 25,
                fatPerServing: 0.3,
                calories: 95,
                protein: 0.5,
                carbs: 25,
                fat: 0.3
            ),
            "banana": FoodDatabaseItem(
                id: "banana_001",
                name: "Banana",
                brand: nil,
                defaultQuantity: 1,
                defaultUnit: "medium",
                servingUnit: "medium",
                caloriesPerServing: 105,
                proteinPerServing: 1.3,
                carbsPerServing: 27,
                fatPerServing: 0.4,
                calories: 105,
                protein: 1.3,
                carbs: 27,
                fat: 0.4
            ),
            "chicken": FoodDatabaseItem(
                id: "chicken_001",
                name: "Chicken Breast",
                brand: nil,
                defaultQuantity: 100,
                defaultUnit: "g",
                servingUnit: "g",
                caloriesPerServing: 165,
                proteinPerServing: 31,
                carbsPerServing: 0,
                fatPerServing: 3.6,
                calories: 165,
                protein: 31,
                carbs: 0,
                fat: 3.6
            ),
            "egg": FoodDatabaseItem(
                id: "egg_001",
                name: "Large Egg",
                brand: nil,
                defaultQuantity: 1,
                defaultUnit: "large",
                servingUnit: "large",
                caloriesPerServing: 70,
                proteinPerServing: 6,
                carbsPerServing: 0.6,
                fatPerServing: 5,
                calories: 70,
                protein: 6,
                carbs: 0.6,
                fat: 5
            )
        ]
        
        let searchKey = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return commonFoods[searchKey]
    }
    
    func lookupBarcode(_ barcode: String) async throws -> FoodDatabaseItem? {
        // Mock implementation - in real app would call external API
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        // Mock barcode lookup
        if barcode == "123456789" {
            return FoodDatabaseItem(
                id: "barcode_\(barcode)",
                name: "Sample Product",
                brand: "Sample Brand",
                defaultQuantity: 1,
                defaultUnit: "serving",
                servingUnit: "serving",
                caloriesPerServing: 150,
                proteinPerServing: 5,
                carbsPerServing: 20,
                fatPerServing: 6,
                calories: 150,
                protein: 5,
                carbs: 20,
                fat: 6
            )
        }
        
        return nil
    }
    
    func searchFoods(query: String, limit: Int) async throws -> [FoodDatabaseItem] {
        // Mock implementation with search results
        let allFoods = [
            FoodDatabaseItem(
                id: "search_001",
                name: "Grilled Chicken Breast",
                brand: nil,
                defaultQuantity: 100,
                defaultUnit: "g",
                servingUnit: "g",
                caloriesPerServing: 165,
                proteinPerServing: 31,
                carbsPerServing: 0,
                fatPerServing: 3.6,
                calories: 165,
                protein: 31,
                carbs: 0,
                fat: 3.6
            ),
            FoodDatabaseItem(
                id: "search_002",
                name: "Brown Rice",
                brand: nil,
                defaultQuantity: 100,
                defaultUnit: "g",
                servingUnit: "g",
                caloriesPerServing: 112,
                proteinPerServing: 2.6,
                carbsPerServing: 23,
                fatPerServing: 0.9,
                calories: 112,
                protein: 2.6,
                carbs: 23,
                fat: 0.9
            ),
            FoodDatabaseItem(
                id: "search_003",
                name: "Greek Yogurt",
                brand: "Generic",
                defaultQuantity: 150,
                defaultUnit: "g",
                servingUnit: "g",
                caloriesPerServing: 100,
                proteinPerServing: 17,
                carbsPerServing: 6,
                fatPerServing: 0.7,
                calories: 100,
                protein: 17,
                carbs: 6,
                fat: 0.7
            ),
            FoodDatabaseItem(
                id: "search_004",
                name: "Avocado",
                brand: nil,
                defaultQuantity: 0.5,
                defaultUnit: "medium",
                servingUnit: "medium",
                caloriesPerServing: 160,
                proteinPerServing: 2,
                carbsPerServing: 8.5,
                fatPerServing: 15,
                calories: 160,
                protein: 2,
                carbs: 8.5,
                fat: 15
            ),
            FoodDatabaseItem(
                id: "search_005",
                name: "Salmon Fillet",
                brand: nil,
                defaultQuantity: 100,
                defaultUnit: "g",
                servingUnit: "g",
                caloriesPerServing: 206,
                proteinPerServing: 22,
                carbsPerServing: 0,
                fatPerServing: 12,
                calories: 206,
                protein: 22,
                carbs: 0,
                fat: 12
            )
        ]
        
        let lowercaseQuery = query.lowercased()
        let filtered = allFoods.filter { food in
            food.name.lowercased().contains(lowercaseQuery) ||
            food.brand?.lowercased().contains(lowercaseQuery) == true
        }
        
        return Array(filtered.prefix(limit))
    }
} 