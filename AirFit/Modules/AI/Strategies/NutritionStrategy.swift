import Foundation
import UIKit

@MainActor
struct NutritionStrategy {
    private let aiService: AIServiceProtocol
    private let directAI: DirectAIProcessor
    private let parser: AIParser

    init(
        aiService: AIServiceProtocol,
        directAIProcessor: DirectAIProcessor,
        parser: AIParser
    ) {
        self.aiService = aiService
        self.directAI = directAIProcessor
        self.parser = parser
    }

    // Direct, fast path
    func parseAndLogNutritionDirect(
        foodText: String,
        context: String = "",
        user: User,
        conversationId: UUID?
    ) async throws -> NutritionParseResult {
        try await directAI.parseNutrition(foodText: foodText, context: context, user: user, conversationId: conversationId)
    }

    // Natural language -> JSON -> ParsedFoodItem[]
    func parseNaturalLanguageFood(text: String, mealType: MealType, user: User) async throws -> [ParsedFoodItem] {
        let start = CFAbsoluteTimeGetCurrent()

        let prompt = """
        Parse this food description into accurate nutrition data: "\(text)"
        Meal type: \(mealType.rawValue)

        Return ONLY valid JSON with this exact structure:
        {
            "items": [
                {
                    "name": "food name",
                    "brand": "brand name or null",
                    "quantity": 1.5,
                    "unit": "cups",
                    "calories": 0,
                    "proteinGrams": 0.0,
                    "carbGrams": 0.0,
                    "fatGrams": 0.0,
                    "fiberGrams": 0.0,
                    "sugarGrams": 0.0,
                    "sodiumMilligrams": 0.0,
                    "confidence": 0.95
                }
            ]
        }

        Rules:
        - Use USDA nutrition database accuracy
        - If multiple items mentioned, include all
        - Estimate quantities if not specified
        - Return realistic nutrition values (not 100 calories for everything!)
        - Confidence 0.9+ for common foods, lower for ambiguous items
        - No explanations or extra text, just JSON
        """

        let req = AIRequest(
            systemPrompt: "You are a nutrition expert providing accurate food parsing. Return only valid JSON.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.1,
            maxTokens: 600,
            user: "nutrition-parsing"
        )

        var full = ""
        for try await r in aiService.sendRequest(req) {
            switch r {
            case .text(let t), .textDelta(let t): full += t
            case .error(let e): throw e
            default: break
            }
        }

        do {
            let items = try parser.parseFoodItemsJSON(full)
            let validated = parser.validateFoodItems(items)
            let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            AppLogger.info("AI nutrition parsing: \(validated.count) items in \(ms)ms | Input: '\(text)'", category: .ai)
            return validated
        } catch {
            return [parser.fallbackFoodItem(from: text, mealType: mealType)]
        }
    }

    func searchFoods(query: String, limit: Int, user: User) async throws -> [ParsedFoodItem] {
        let prompt = """
        Search for foods matching: "\(query)"

        Return the top \(limit) food items that match this query.

        Return ONLY valid JSON with this exact structure:
        {
            "items": [
                {
                    "name": "food name",
                    "brand": "brand name or null",
                    "quantity": 1.0,
                    "unit": "serving",
                    "calories": 0,
                    "proteinGrams": 0.0,
                    "carbGrams": 0.0,
                    "fatGrams": 0.0,
                    "fiberGrams": 0.0,
                    "sugarGrams": 0.0,
                    "sodiumMilligrams": 0.0,
                    "confidence": 0.95
                }
            ]
        }
        """

        let req = AIRequest(
            systemPrompt: "You are a nutrition expert. Use your knowledge to provide accurate nutrition data.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.3,
            maxTokens: 800,
            user: "food-search"
        )

        var full = ""
        for try await r in aiService.sendRequest(req) {
            switch r {
            case .text(let t), .textDelta(let t): full += t
            default: break
            }
        }

        let items = try parser.parseFoodItemsJSON(full)
        return Array(items.prefix(limit))
    }

    func analyzeMealPhoto(image: UIImage, context: NutritionContext?, user: User) async throws -> MealPhotoAnalysisResult {
        // Delegate to existing DirectAIProcessor logic that uses structured output style
        // (We avoid duplicating that multimodal prompt here.)
        // For now, just call through the direct path by converting to "natural language" wrapper if desired,
        // or you can keep the existing CoachEngine pathway and move later.
        // Keeping parity: move the existing implementation later if you prefer a strict split.
        throw FoodTrackingError.invalidImage // Scaffold: keep existing CoachEngine path until photo flows are moved.
    }
}