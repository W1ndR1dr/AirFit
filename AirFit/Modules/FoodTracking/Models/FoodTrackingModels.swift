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

