import SwiftData
import Foundation

@Model
final class FoodEntry: @unchecked Sendable {
    // MARK: - Properties
    var id: UUID
    var loggedAt: Date
    var mealType: String
    var rawTranscript: String?
    var photoData: Data?
    var notes: String?

    // AI Metadata
    var parsingModelUsed: String?
    var parsingConfidence: Double?
    var parsingTimestamp: Date?

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \FoodItem.foodEntry)
    var items: [FoodItem] = []

    var nutritionData: NutritionData?

    var user: User?

    // MARK: - Computed Properties
    var totalCalories: Int {
        Int(items.reduce(0) { $0 + ($1.calories ?? 0) })
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

    var mealTypeEnum: MealType? {
        MealType(rawValue: mealType)
    }

    var isComplete: Bool {
        !items.isEmpty && items.allSatisfy { item in
            item.calories != nil && item.proteinGrams != nil &&
                item.carbGrams != nil && item.fatGrams != nil
        }
    }

    var mealDisplayName: String {
        if items.count == 1 {
            return items.first?.name ?? "Unknown Food"
        } else if items.count > 1 {
            return "\(items.count) items"
        } else {
            return mealTypeEnum?.displayName ?? "Empty Meal"
        }
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        loggedAt: Date = Date(),
        mealType: MealType = .snack,
        rawTranscript: String? = nil,
        photoData: Data? = nil,
        notes: String? = nil,
        user: User? = nil
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.mealType = mealType.rawValue
        self.rawTranscript = rawTranscript
        self.photoData = photoData
        self.notes = notes
        self.user = user
    }

    // MARK: - Methods
    func addItem(_ item: FoodItem) {
        items.append(item)
        item.foodEntry = self
    }

    func updateFromAIParsing(model: String, confidence: Double) {
        self.parsingModelUsed = model
        self.parsingConfidence = confidence
        self.parsingTimestamp = Date()
    }
    
    func duplicate() -> FoodEntry {
        let duplicateEntry = FoodEntry(
            loggedAt: self.loggedAt,
            mealType: self.mealTypeEnum ?? .snack,
            rawTranscript: self.rawTranscript,
            photoData: self.photoData,
            notes: self.notes,
            user: self.user
        )
        
        // Duplicate all food items
        for item in self.items {
            let duplicateItem = FoodItem(
                name: item.name,
                brand: item.brand,
                quantity: item.quantity,
                unit: item.unit,
                calories: item.calories,
                proteinGrams: item.proteinGrams ?? 0,
                carbGrams: item.carbGrams ?? 0,
                fatGrams: item.fatGrams ?? 0
            )
            duplicateItem.fiberGrams = item.fiberGrams
            duplicateItem.sugarGrams = item.sugarGrams
            duplicateItem.sodiumMg = item.sodiumMg
            duplicateItem.barcode = item.barcode
            duplicateEntry.addItem(duplicateItem)
        }
        
        return duplicateEntry
    }
}

// MARK: - MealType Enum
enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack
    case preWorkout = "pre_workout"
    case postWorkout = "post_workout"

    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        case .preWorkout: return "Pre-Workout"
        case .postWorkout: return "Post-Workout"
        }
    }

    var defaultTime: DateComponents {
        switch self {
        case .breakfast: return DateComponents(hour: 8, minute: 0)
        case .lunch: return DateComponents(hour: 12, minute: 30)
        case .dinner: return DateComponents(hour: 18, minute: 30)
        case .snack: return DateComponents(hour: 15, minute: 0)
        case .preWorkout: return DateComponents(hour: 17, minute: 0)
        case .postWorkout: return DateComponents(hour: 19, minute: 0)
        }
    }
    
    var emoji: String {
        switch self {
        case .breakfast: return "🍳"
        case .lunch: return "🥗"
        case .dinner: return "🍽️"
        case .snack: return "🍎"
        case .preWorkout: return "⚡"
        case .postWorkout: return "💪"
        }
    }
}
