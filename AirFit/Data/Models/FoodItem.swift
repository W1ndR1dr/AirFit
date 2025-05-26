import SwiftData
import Foundation

@Model
final class FoodItem: Sendable {
    // MARK: - Properties
    var id: UUID
    var name: String
    var brand: String?
    var barcode: String?
    var quantity: Double?
    var unit: String?
    var calories: Double?
    var proteinGrams: Double?
    var carbGrams: Double?
    var fatGrams: Double?
    var fiberGrams: Double?
    var sugarGrams: Double?
    var sodiumMg: Double?
    var servingSize: String?
    var servingsConsumed: Double = 1.0
    
    // Data Source
    var dataSource: String? // "user", "database", "ai_parsed", "barcode"
    var databaseID: String? // External database reference
    var verificationStatus: String? // "verified", "unverified", "user_modified"
    
    // MARK: - Relationships
    var foodEntry: FoodEntry?
    
    // MARK: - Computed Properties
    var actualCalories: Double {
        (calories ?? 0) * servingsConsumed
    }
    
    var actualProtein: Double {
        (proteinGrams ?? 0) * servingsConsumed
    }
    
    var actualCarbs: Double {
        (carbGrams ?? 0) * servingsConsumed
    }
    
    var actualFat: Double {
        (fatGrams ?? 0) * servingsConsumed
    }
    
    var macroPercentages: (protein: Double, carbs: Double, fat: Double)? {
        guard let protein = proteinGrams,
              let carbs = carbGrams,
              let fat = fatGrams else { return nil }
        
        let totalCalories = (protein * 4) + (carbs * 4) + (fat * 9)
        guard totalCalories > 0 else { return (0, 0, 0) }
        
        return (
            protein: (protein * 4) / totalCalories,
            carbs: (carbs * 4) / totalCalories,
            fat: (fat * 9) / totalCalories
        )
    }
    
    var isValid: Bool {
        !name.isEmpty && calories != nil && calories! >= 0
    }
    
    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        quantity: Double? = nil,
        unit: String? = nil,
        calories: Double? = nil,
        proteinGrams: Double? = nil,
        carbGrams: Double? = nil,
        fatGrams: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.quantity = quantity
        self.unit = unit
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbGrams = carbGrams
        self.fatGrams = fatGrams
    }
    
    // MARK: - Methods
    func updateNutrition(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil
    ) {
        self.calories = calories
        self.proteinGrams = protein
        self.carbGrams = carbs
        self.fatGrams = fat
        self.fiberGrams = fiber
        self.sugarGrams = sugar
        self.sodiumMg = sodium
        self.verificationStatus = "user_modified"
    }
}
