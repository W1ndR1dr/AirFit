import Foundation

/// Handles direct AI operations for optimized performance
/// Single responsibility: Execute focused AI tasks without function calling overhead
@MainActor
final class DirectAIProcessor {
    // MARK: - Dependencies
    
    private let aiService: AIServiceProtocol
    
    // MARK: - Configuration
    
    private let nutritionParsingConfig = AIConfig(
        temperature: 0.1,      // Low for consistent parsing
        maxTokens: 500,        // Optimized for JSON responses
        systemPrompt: "You are a precision nutrition expert. Return only valid JSON without explanations."
    )
    
    private let educationalContentConfig = AIConfig(
        temperature: 0.7,      // Higher for creative content
        maxTokens: 800,        // Sufficient for detailed content
        systemPrompt: "You are an expert fitness educator providing personalized, science-based guidance."
    )
    
    private struct AIConfig {
        let temperature: Double
        let maxTokens: Int
        let systemPrompt: String
    }
    
    // MARK: - Initialization
    
    init(aiService: AIServiceProtocol) {
        self.aiService = aiService
    }
    
    // MARK: - Nutrition Parsing
    
    /// Parses nutrition data using direct AI for 3x performance improvement
    func parseNutrition(
        foodText: String,
        context: String = "",
        user: User,
        conversationId: UUID? = nil
    ) async throws -> NutritionParseResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard !foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DirectAIError.nutritionParsingFailed("Empty food description")
        }
        
        let prompt = buildNutritionPrompt(foodText: foodText, context: context)
        
        do {
            let response = try await executeAIRequest(
                prompt: prompt,
                config: nutritionParsingConfig,
                userId: user.id.uuidString
            )
            
            let items = try parseNutritionJSON(response)
            let validated = validateNutritionItems(items)
            
            guard !validated.isEmpty else {
                throw DirectAIError.nutritionValidationFailed
            }
            
            let processingTime = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1_000)
            let confidence = validated.reduce(0) { $0 + $1.confidence } / Double(validated.count)
            
            let result = NutritionParseResult(
                items: validated,
                totalCalories: validated.reduce(0) { $0 + $1.calories },
                confidence: confidence,
                tokenCount: estimateTokenCount(prompt),
                processingTimeMs: processingTime,
                parseStrategy: .directAI
            )
            
            // Result is stored in conversation history by CoachEngine
            
            AppLogger.info(
                "Direct nutrition: \(validated.count) items in \(processingTime)ms | Confidence: \(String(format: "%.2f", confidence))",
                category: .ai
            )
            
            return result
            
        } catch let error as DirectAIError {
            throw error
        } catch {
            throw DirectAIError.nutritionParsingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Educational Content
    
    /// Generates educational content with 80% token reduction vs function calling
    func generateEducationalContent(
        topic: String,
        userContext: String,
        userProfile: CoachingPlan
    ) async throws -> EducationalContent {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DirectAIError.educationalContentFailed("Empty topic")
        }
        
        let prompt = buildEducationalPrompt(
            topic: topic,
            userContext: userContext,
            userProfile: userProfile
        )
        
        do {
            let response = try await executeAIRequest(
                prompt: prompt,
                config: educationalContentConfig,
                userId: "edu-\(userProfile.timezone.replacingOccurrences(of: "/", with: "-"))"
            )
            
            let processingTime = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1_000)
            let personalization = calculatePersonalization(response, userProfile: userProfile)
            
            let contentTypeString = classifyContentType(topic)
            let contentType = EducationalContent.ContentType(rawValue: contentTypeString) ?? .general
            
            let content = EducationalContent(
                topic: topic,
                content: response,
                generatedAt: Date(),
                tokenCount: estimateTokenCount(prompt + response),
                personalizationLevel: personalization,
                contentType: contentType
            )
            
            AppLogger.info(
                "Educational content: \(response.count) chars in \(processingTime)ms | Personalization: \(String(format: "%.2f", personalization))",
                category: .ai
            )
            
            return content
            
        } catch {
            throw DirectAIError.educationalContentFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Simple Conversations
    
    /// Generates simple conversational responses without function calling
    func generateSimpleResponse(
        text: String,
        userProfile: CoachingPlan,
        healthContext: HealthContextSnapshot
    ) async throws -> String {
        let prompt = """
        Respond to this fitness-related question or comment: "\(text)"
        
        User context:
        - Work Style: \(userProfile.lifeContext.workStyle)
        - Primary goal: \(userProfile.goal.family.displayName)
        - Recent activity: \(healthContext.appContext.workoutContext?.recentWorkouts.count ?? 0) workouts
        
        Provide a helpful, encouraging response in 1-2 sentences. Be conversational and supportive.
        """
        
        let config = AIConfig(
            temperature: 0.7,
            maxTokens: 200,
            systemPrompt: "You are a supportive fitness coach providing brief, helpful responses."
        )
        
        return try await executeAIRequest(
            prompt: prompt,
            config: config,
            userId: "\(userProfile.timezone.replacingOccurrences(of: "/", with: "-"))-simple"
        )
    }
    
    // MARK: - Private Helpers
    
    private func executeAIRequest(
        prompt: String,
        config: AIConfig,
        userId: String
    ) async throws -> String {
        let request = AIRequest(
            systemPrompt: config.systemPrompt,
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: config.temperature,
            maxTokens: config.maxTokens,
            user: userId
        )
        
        var fullResponse = ""
        
        for try await response in aiService.sendRequest(request) {
            switch response {
            case .text(let text), .textDelta(let text):
                fullResponse += text
            case .error(let error):
                throw error
            case .done:
                break
            default:
                break
            }
        }
        
        guard !fullResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DirectAIError.emptyResponse
        }
        
        return fullResponse
    }
    
    private func buildNutritionPrompt(foodText: String, context: String) -> String {
        let contextSuffix = context.isEmpty ? "" : "\nContext: \(context)"
        
        return """
        Parse: "\(foodText)"\(contextSuffix)
        
        Return JSON:
        {
            "items": [
                {
                    "name": "food name",
                    "quantity": "1 cup",
                    "calories": 200,
                    "proteinGrams": 8.0,
                    "carbGrams": 45.0,
                    "fatGrams": 3.0,
                    "fiberGrams": 2.0,
                    "confidence": 0.95
                }
            ]
        }
        
        Rules:
        - USDA nutrition database accuracy
        - Realistic values (not 100 cal defaults)
        - Multiple items if mentioned
        - Confidence 0.9+ for common foods
        - JSON only, no text
        """
    }
    
    private func buildEducationalPrompt(
        topic: String,
        userContext: String,
        userProfile: CoachingPlan
    ) -> String {
        let cleanTopic = topic.replacingOccurrences(of: "_", with: " ").capitalized
        let contextLine = userContext.isEmpty ? "" : "\nContext: \(userContext)"
        
        return """
        Create educational content about \(cleanTopic) for this user:
        
        User Level: Intermediate
        Goals: \(userProfile.goal.family.displayName)
        Motivation Style: \(userProfile.motivationalStyle.styles.first?.rawValue ?? "encouraging")\(contextLine)
        
        Requirements:
        - Explain \(cleanTopic) scientifically but accessibly
        - Personalize for their level and goals
        - Include 3-4 actionable tips
        - 250-400 words, conversational tone
        - Focus on practical application
        
        Structure: Brief explanation, personalized insights, actionable tips.
        """
    }
    
    private func parseNutritionJSON(_ response: String) throws -> [NutritionItem] {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let itemsArray = json["items"] as? [[String: Any]] else {
            throw DirectAIError.invalidJSONResponse(response)
        }
        
        return try itemsArray.map { dict in
            guard let name = dict["name"] as? String,
                  let quantity = dict["quantity"] as? String,
                  let calories = dict["calories"] as? Double,
                  let protein = dict["proteinGrams"] as? Double,
                  let carbs = dict["carbGrams"] as? Double,
                  let fat = dict["fatGrams"] as? Double else {
                throw DirectAIError.invalidJSONResponse("Missing required fields")
            }
            
            return NutritionItem(
                name: name,
                quantity: quantity,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                confidence: dict["confidence"] as? Double ?? 0.8
            )
        }
    }
    
    private func validateNutritionItems(_ items: [NutritionItem]) -> [NutritionItem] {
        items.filter { item in
            let isValid = item.calories > 0 && item.calories < 10000 &&
                         item.protein >= 0 && item.carbs >= 0 && item.fat >= 0 &&
                         (item.protein * 4 + item.carbs * 4 + item.fat * 9) <= item.calories * 1.3
            
            if !isValid {
                AppLogger.warning(
                    "Rejected invalid nutrition: \(item.name) - \(item.calories) cal",
                    category: .ai
                )
            }
            
            return isValid
        }
    }
    
    private func extractJSON(from response: String) -> String {
        if let startIndex = response.firstIndex(of: "{"),
           let endIndex = response.lastIndex(of: "}") {
            return String(response[startIndex...endIndex])
        }
        return response
    }
    
    private func estimateTokenCount(_ text: String) -> Int {
        // ~4 characters per token for English
        max(text.count / 4, 1)
    }
    
    private func calculatePersonalization(_ content: String, userProfile: CoachingPlan) -> Double {
        var keywords: [String] = []
        
        keywords.append(userProfile.goal.family.displayName.lowercased())
        keywords.append(userProfile.lifeContext.workStyle.rawValue.lowercased())
        keywords.append(userProfile.motivationalStyle.styles.first?.rawValue.lowercased() ?? "encouraging")
        
        let mentions = keywords.reduce(0) { count, keyword in
            count + (content.localizedCaseInsensitiveContains(keyword) ? 1 : 0)
        }
        
        return keywords.isEmpty ? 0.5 : min(Double(mentions) / Double(keywords.count), 1.0)
    }
    
    private func classifyContentType(_ topic: String) -> String {
        let lowercased = topic.lowercased()
        
        if ["protein", "carbs", "fat", "calories", "macros", "nutrition"].contains(where: lowercased.contains) {
            return "nutrition"
        } else if ["muscle", "strength", "cardio", "workout", "exercise"].contains(where: lowercased.contains) {
            return "exercise"
        } else if ["sleep", "recovery", "rest"].contains(where: lowercased.contains) {
            return "recovery"
        } else {
            return "general"
        }
    }
    
}