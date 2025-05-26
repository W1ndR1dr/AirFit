import SwiftData
import Foundation

@Model
final class FoodItemTemplate: Sendable {
    // MARK: - Properties
    var id: UUID
    var name: String
    var brand: String?
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
    
    // MARK: - Relationships
    var mealTemplate: MealTemplate?
    
    // MARK: - Computed Properties
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
    
    var isComplete: Bool {
        calories != nil && proteinGrams != nil &&
        carbGrams != nil && fatGrams != nil
    }
    
    var formattedQuantity: String? {
        guard let quantity = quantity else { return nil }
        
        if let unit = unit {
            return "\(Int(quantity)) \(unit)"
        } else {
            return "\(Int(quantity))"
        }
    }
    
    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        quantity: Double? = nil,
        unit: String? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.quantity = quantity
        self.unit = unit
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
    }
    
    func duplicate() -> FoodItemTemplate {
        let copy = FoodItemTemplate(
            name: name,
            brand: brand,
            quantity: quantity,
            unit: unit
        )
        
        copy.calories = calories
        copy.proteinGrams = proteinGrams
        copy.carbGrams = carbGrams
        copy.fatGrams = fatGrams
        copy.fiberGrams = fiberGrams
        copy.sugarGrams = sugarGrams
        copy.sodiumMg = sodiumMg
        copy.servingSize = servingSize
        
        return copy
    }
}
