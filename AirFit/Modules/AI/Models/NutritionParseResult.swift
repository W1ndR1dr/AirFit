import Foundation

// MARK: - Nutrition Parse Result Models

struct NutritionParseResult: Sendable {
    let items: [NutritionItem]
    let totalCalories: Double
    let confidence: Double
    let tokenCount: Int
    let processingTimeMs: Int
    let parseStrategy: ParseStrategy

    enum ParseStrategy: String, Sendable {
        case directAI = "direct_ai"
        case functionCall = "function_call"
        case fallback = "fallback"
        case cached = "cached"
        case quickLookup = "quick_lookup"
    }
}

struct NutritionItem: Sendable {
    let name: String
    let quantity: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let confidence: Double

    var formattedCalories: String {
        return "\(Int(calories)) cal"
    }

    var formattedMacros: String {
        return "P: \(String(format: "%.1f", protein))g, C: \(String(format: "%.1f", carbs))g, F: \(String(format: "%.1f", fat))g"
    }
}

struct EducationalContent: Sendable {
    let topic: String
    let content: String
    let generatedAt: Date
    let tokenCount: Int
    let personalizationLevel: Double
    let contentType: ContentType

    enum ContentType: String, Sendable {
        case exercise = "exercise"
        case nutrition = "nutrition"
        case recovery = "recovery"
        case motivation = "motivation"
        case general = "general"
    }
}
