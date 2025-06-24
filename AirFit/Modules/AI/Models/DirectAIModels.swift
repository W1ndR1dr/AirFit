import Foundation

// MARK: - Direct AI Results

/// Legacy result type - kept for backward compatibility
/// New implementations use NutritionParseResult from NutritionParseResult.swift
struct LegacyNutritionParseResult: Sendable {
    let items: [ParsedNutritionItem]
    let totalCalories: Double
    let confidence: Double
    let parseMethod: ParseMethod
    let processingTimeMs: Int
    let tokenCount: Int?
    
    init(
        items: [ParsedNutritionItem],
        totalCalories: Double? = nil,
        confidence: Double,
        parseMethod: ParseMethod,
        processingTimeMs: Int,
        tokenCount: Int? = nil
    ) {
        self.items = items
        self.totalCalories = totalCalories ?? items.reduce(0) { $0 + $1.calories }
        self.confidence = confidence
        self.parseMethod = parseMethod
        self.processingTimeMs = processingTimeMs
        self.tokenCount = tokenCount
    }
}

/// Individual nutrition item from direct AI parsing
struct ParsedNutritionItem: Sendable {
    let name: String
    let quantity: String
    let calories: Double
    let proteinGrams: Double
    let carbGrams: Double
    let fatGrams: Double
    let fiberGrams: Double?
    let confidence: Double
    
    /// Validates nutrition values for reasonableness
    var isValid: Bool {
        calories > 0 && calories < 5_000 &&
        proteinGrams >= 0 && proteinGrams < 300 &&
        carbGrams >= 0 && carbGrams < 1_000 &&
        fatGrams >= 0 && fatGrams < 500
    }
}

/// Legacy educational content type - kept for backward compatibility  
/// New implementations use EducationalContent from NutritionParseResult.swift
struct LegacyEducationalContent: Sendable {
    let topic: String
    let content: String
    let keyPoints: [String]
    let personalizationLevel: Double
    let generatedAt: Date
    let processingTimeMs: Int
    let tokenCount: Int?
    
    /// Content quality score based on length and structure
    var qualityScore: Double {
        let lengthScore = min(Double(content.count) / 500.0, 1.0) // Target 500+ chars
        let structureScore = keyPoints.count >= 3 ? 1.0 : Double(keyPoints.count) / 3.0
        return (lengthScore + structureScore + personalizationLevel) / 3.0
    }
}

/// Parsing method for performance comparison
enum ParseMethod: String, Sendable {
    case directAI = "direct_ai"
    case functionDispatcher = "function_dispatcher"
    case hybrid = "hybrid"
    
    var description: String {
        switch self {
        case .directAI: return "Direct AI"
        case .functionDispatcher: return "Function Dispatcher"
        case .hybrid: return "Hybrid Routing"
        }
    }
}

// MARK: - Error Types
// Note: DirectAIError is now defined in CoachEngine.swift to avoid duplication 
