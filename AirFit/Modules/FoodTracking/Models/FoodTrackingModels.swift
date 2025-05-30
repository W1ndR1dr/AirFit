import Foundation

/// Summary of nutritional intake compared against user goals.
struct FoodNutritionSummary: Sendable {
    /// Total calories consumed.
    var calories: Double = 0
    /// Total grams of protein consumed.
    var protein: Double = 0
    /// Total grams of carbohydrates consumed.
    var carbs: Double = 0
    /// Total grams of fat consumed.
    var fat: Double = 0
    /// Total grams of fiber consumed.
    var fiber: Double = 0
    /// Total grams of sugar consumed.
    var sugar: Double = 0
    /// Total milligrams of sodium consumed.
    var sodium: Double = 0

    /// Daily calorie goal.
    var calorieGoal: Double = 2000
    /// Daily protein goal in grams.
    var proteinGoal: Double = 150
    /// Daily carbohydrate goal in grams.
    var carbGoal: Double = 250
    /// Daily fat goal in grams.
    var fatGoal: Double = 65

    /// Default initializer with zeroed values and default goals.
    init() {}

    /// Full parameter initializer for explicit summaries and goals.
    init(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double,
        sugar: Double,
        sodium: Double,
        calorieGoal: Double,
        proteinGoal: Double,
        carbGoal: Double,
        fatGoal: Double
    ) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.calorieGoal = calorieGoal
        self.proteinGoal = proteinGoal
        self.carbGoal = carbGoal
        self.fatGoal = fatGoal
    }

    /// Progress toward the daily calorie goal as a fraction between 0 and 1.
    var calorieProgress: Double { calories / calorieGoal }
    /// Progress toward the daily protein goal.
    var proteinProgress: Double { protein / proteinGoal }
    /// Progress toward the daily carbohydrate goal.
    var carbProgress: Double { carbs / carbGoal }
    /// Progress toward the daily fat goal.
    var fatProgress: Double { fat / fatGoal }
}

/// Result of analyzing a photo using Vision.
struct VisionAnalysisResult: Sendable {
    /// All recognized text fragments in the photo.
    let recognizedText: [String]
    /// Overall confidence score for the analysis.
    let confidence: Float
}

/// Raw food item information returned from parsing services.
/// Properties use explicit units for clarity.
struct ParsedFoodItem: Identifiable, Sendable {
    /// Unique identifier for this parsed item.
    let id = UUID()
    /// Name of the food item.
    let name: String
    /// Optional brand associated with the item.
    let brand: String?
    /// Detected quantity of the food item.
    let quantity: Double
    /// Unit for the detected quantity.
    let unit: String
    /// Estimated calories contained in the quantity.
    let calories: Double
    /// Estimated grams of protein.
    let proteinGrams: Double
    /// Estimated grams of carbohydrates.
    let carbGrams: Double
    /// Estimated grams of fat.
    let fatGrams: Double
    /// Estimated grams of fiber.
    let fiberGrams: Double?
    /// Estimated grams of sugar.
    let sugarGrams: Double?
    /// Estimated milligrams of sodium.
    let sodiumMilligrams: Double?
    /// Barcode value if parsed from a scan.
    let barcode: String?
    /// Database identifier from external food data sources.
    let databaseId: String?
    /// Confidence score from the parser.
    let confidence: Float

    // MARK: - Backward Compatibility
    /// Provides the fiber amount for callers using the old `fiber` property.
    var fiber: Double? { fiberGrams }
    /// Provides the sugar amount for callers using the old `sugar` property.
    var sugar: Double? { sugarGrams }
    /// Provides the sodium amount for callers using the old `sodium` property.
    var sodium: Double? { sodiumMilligrams }
}

/// Indicates that an asynchronous operation exceeded the allowed duration.
struct TimeoutError: Error, LocalizedError, Sendable {
    /// The name of the operation that timed out.
    let operation: String
    /// The duration after which the timeout occurred.
    let timeoutDuration: TimeInterval

    /// Human readable description for display and logging.
    var errorDescription: String? {
        "Operation '\(operation)' timed out after \(timeoutDuration) seconds"
    }
}

/// Result of analyzing a meal photo using Vision and AI models.
struct MealPhotoAnalysisResult: Sendable {
    /// The food items that were detected in the photo.
    let items: [ParsedFoodItem]
    /// Overall confidence score for the photo analysis.
    let confidence: Float
    /// The amount of time the analysis took to complete.
    let processingTime: TimeInterval
}

/// Errors that can occur when tracking foods or processing nutrition data.
enum FoodTrackingError: Error, LocalizedError, Sendable {
    /// Persistence layer failed to save the logged items.
    case saveFailed
    /// Network connectivity prevented the requested operation.
    case networkError
    /// Voice recognition failed to produce a valid transcript.
    case voiceRecognitionFailed
    /// AI parsing failed with a suggestion for the user.
    case aiProcessingFailed(suggestion: String)
    /// AI processing exceeded the allotted time.
    case aiProcessingTimeout
    /// No food items were detected from the provided input.
    case noFoodsDetected
    /// Photo analysis could not determine any usable results.
    case photoAnalysisFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save food entry"
        case .networkError:
            return "Network connection error"
        case .voiceRecognitionFailed:
            return "Voice recognition failed"
        case let .aiProcessingFailed(suggestion):
            return "AI processing failed. \(suggestion)"
        case .aiProcessingTimeout:
            return "AI processing timed out"
        case .noFoodsDetected:
            return "No food items detected"
        case .photoAnalysisFailed:
            return "Photo analysis failed"
        }
    }
}

// MARK: - Food Database Models

/// Represents a food item from the database with nutritional information
struct FoodDatabaseItem: Identifiable, Sendable {
    let id: String
    let name: String
    let brand: String?
    let caloriesPerServing: Double
    let proteinPerServing: Double
    let carbsPerServing: Double
    let fatPerServing: Double
    let servingSize: Double
    let servingUnit: String
    let defaultQuantity: Double
    let defaultUnit: String
}

/// Context for nutrition-related operations
struct NutritionContext: Sendable {
    let userGoals: NutritionTargets?
    let recentMeals: [FoodEntry]
    let currentDate: Date
    
    init(userGoals: NutritionTargets? = nil, recentMeals: [FoodEntry] = [], currentDate: Date = Date()) {
        self.userGoals = userGoals
        self.recentMeals = recentMeals
        self.currentDate = currentDate
    }
}

/// Search result from food database
struct FoodSearchResult: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String
}

