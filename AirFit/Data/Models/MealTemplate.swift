import SwiftData
import Foundation

@Model
final class MealTemplate: Sendable {
    // MARK: - Properties
    var id: UUID
    var name: String
    var mealType: String
    var descriptionText: String?
    var photoData: Data?
    var estimatedCalories: Double?
    var estimatedProtein: Double?
    var estimatedCarbs: Double?
    var estimatedFat: Double?
    var isSystemTemplate: Bool = false
    var isFavorite: Bool = false
    var lastUsedDate: Date?
    var useCount: Int = 0
    
    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \FoodItemTemplate.mealTemplate)
    var items: [FoodItemTemplate] = []
    
    // MARK: - Computed Properties
    var mealTypeEnum: MealType? {
        MealType(rawValue: mealType)
    }
    
    var totalCalories: Double {
        items.reduce(0) { $0 + ($1.calories ?? 0) }
    }
    
    var totalProtein: Double {
        items.reduce(0) { $0 + ($1.proteinGrams ?? 0) }
    }
    
    var totalCarbs: Double {
        items.reduce(0) { $0 + ($1.carbGrams ?? 0) }
    }
    
    var totalFat: Double {
        items.reduce(0) { $0 + ($1.fatGrams ?? 0) }
    }
    
    var macroBreakdown: (protein: Double, carbs: Double, fat: Double)? {
        let totalCals = totalCalories
        guard totalCals > 0 else { return nil }
        
        let proteinCals = totalProtein * 4
        let carbCals = totalCarbs * 4
        let fatCals = totalFat * 9
        
        return (
            protein: proteinCals / totalCals,
            carbs: carbCals / totalCals,
            fat: fatCals / totalCals
        )
    }
    
    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        name: String,
        mealType: MealType = .lunch,
        isSystemTemplate: Bool = false
    ) {
        self.id = id
        self.name = name
        self.mealType = mealType.rawValue
        self.isSystemTemplate = isSystemTemplate
    }
    
    // MARK: - Methods
    func recordUse() {
        lastUsedDate = Date()
        useCount += 1
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
    }
    
    func addItem(_ item: FoodItemTemplate) {
        items.append(item)
        item.mealTemplate = self
        updateEstimates()
    }
    
    func removeItem(_ item: FoodItemTemplate) {
        items.removeAll { $0.id == item.id }
        updateEstimates()
    }
    
    private func updateEstimates() {
        estimatedCalories = totalCalories
        estimatedProtein = totalProtein
        estimatedCarbs = totalCarbs
        estimatedFat = totalFat
    }
    
    func createFoodEntry(for user: User) -> FoodEntry {
        let entry = FoodEntry(
            mealType: mealTypeEnum ?? .snack,
            user: user
        )
        
        // Copy all template items to actual food items
        for templateItem in items {
            let foodItem = FoodItem(
                name: templateItem.name,
                quantity: templateItem.quantity,
                unit: templateItem.unit,
                calories: templateItem.calories,
                proteinGrams: templateItem.proteinGrams,
                carbGrams: templateItem.carbGrams,
                fatGrams: templateItem.fatGrams
            )
            entry.addItem(foodItem)
        }
        
        recordUse()
        return entry
    }
}
