import Foundation
import SwiftData

// MARK: - ParsedFoodItem
/// Represents a food item parsed from voice input or photo analysis
struct ParsedFoodItem: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let brand: String?
    let quantity: Double
    let unit: String
    let calories: Double
    let proteinGrams: Double
    let carbGrams: Double
    let fatGrams: Double
    let fiberGrams: Double?
    let sugarGrams: Double?
    let sodiumMilligrams: Double?
    let confidence: Float
    
    init(
        name: String,
        brand: String? = nil,
        quantity: Double,
        unit: String,
        calories: Double,
        proteinGrams: Double,
        carbGrams: Double,
        fatGrams: Double,
        fiberGrams: Double? = nil,
        sugarGrams: Double? = nil,
        sodiumMilligrams: Double? = nil,
        confidence: Float
    ) {
        self.name = name
        self.brand = brand
        self.quantity = quantity
        self.unit = unit
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbGrams = carbGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
        self.sugarGrams = sugarGrams
        self.sodiumMilligrams = sodiumMilligrams
        self.confidence = confidence
    }
}

// MARK: - FoodNutritionSummary
/// Represents a summary of nutrition data for display in charts and rings
struct FoodNutritionSummary: Sendable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    
    // Goals for comparison
    let calorieGoal: Double
    let proteinGoal: Double
    let carbGoal: Double
    let fatGoal: Double
    
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
}

// MARK: - FoodTrackingError
/// Errors specific to food tracking operations
enum FoodTrackingError: Error, LocalizedError, Sendable {
    case voiceRecognitionFailed
    case aiParsingTimeout
    case aiParsingFailed(String)
    case photoAnalysisFailed
    case networkError
    case invalidFoodData
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .voiceRecognitionFailed:
            return "Could not understand your voice input. Please try again."
        case .aiParsingTimeout:
            return "AI analysis took too long. Please try again."
        case .aiParsingFailed(let reason):
            return "AI analysis failed: \(reason)"
        case .photoAnalysisFailed:
            return "Could not analyze the photo. Please try again with better lighting."
        case .networkError:
            return "Network connection failed. Please check your internet connection."
        case .invalidFoodData:
            return "Invalid food data received. Please try again."
        case .saveFailed:
            return "Failed to save food entry. Please try again."
        }
    }
}

// MARK: - TimeoutError
/// Specific timeout error for operations with time limits
struct TimeoutError: Error, LocalizedError, Sendable {
    let operation: String
    let timeoutDuration: TimeInterval
    
    var errorDescription: String? {
        "Operation '\(operation)' timed out after \(timeoutDuration) seconds"
    }
}

// MARK: - WaterUnit
/// Units for water tracking
enum WaterUnit: String, CaseIterable, Sendable {
    case milliliters = "ml"
    case fluidOunces = "fl oz"
    case cups = "cups"
    case liters = "L"
    
    var displayName: String {
        switch self {
        case .milliliters:
            return "Milliliters"
        case .fluidOunces:
            return "Fluid Ounces"
        case .cups:
            return "Cups"
        case .liters:
            return "Liters"
        }
    }
    
    /// Convert to milliliters for storage
    func toMilliliters(_ amount: Double) -> Double {
        switch self {
        case .milliliters:
            return amount
        case .fluidOunces:
            return amount * 29.5735
        case .cups:
            return amount * 236.588
        case .liters:
            return amount * 1000
        }
    }
    
    /// Convert from milliliters for display
    func fromMilliliters(_ milliliters: Double) -> Double {
        switch self {
        case .milliliters:
            return milliliters
        case .fluidOunces:
            return milliliters / 29.5735
        case .cups:
            return milliliters / 236.588
        case .liters:
            return milliliters / 1000
        }
    }
}

// MARK: - VisionAnalysisResult
/// Result from Vision framework analysis of food photos
struct VisionAnalysisResult: Sendable {
    let detectedText: [String]
    let confidence: Float
    let boundingBoxes: [CGRect]
    
    init(detectedText: [String], confidence: Float, boundingBoxes: [CGRect] = []) {
        self.detectedText = detectedText
        self.confidence = confidence
        self.boundingBoxes = boundingBoxes
    }
}

// MARK: - FoodSearchResult
/// Result from food database search
struct FoodSearchResult: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let brand: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String
    let confidence: Float
    
    init(
        name: String,
        brand: String? = nil,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        servingSize: String,
        confidence: Float = 1.0
    ) {
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.confidence = confidence
    }
} 