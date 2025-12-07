import Foundation

actor APIClient {
    private let baseURL: URL

    // Simulator uses localhost, real device uses Mac's IP
    init() {
        #if targetEnvironment(simulator)
        self.baseURL = URL(string: "http://localhost:8080")!
        #else
        self.baseURL = URL(string: "http://192.168.86.50:8080")!
        #endif
    }

    struct ChatRequest: Encodable {
        let message: String
        let system_prompt: String?
        let health_context: [String: String]?
        let nutrition_context: NutritionContext?
    }

    struct NutritionContext: Encodable {
        let total_calories: Int
        let total_protein: Int
        let total_carbs: Int
        let total_fat: Int
        let entry_count: Int
        let entries: [NutritionEntryContext]  // Today's food
        var recent_entries: [NutritionEntryContext] = []  // Last 2-3 days
    }

    struct NutritionEntryContext: Encodable {
        let name: String
        let calories: Int
        let protein: Int
    }

    struct ChatResponse: Decodable {
        let response: String
        let provider: String
        let success: Bool
        let error: String?
    }

    struct NutritionParseRequest: Encodable {
        let food_text: String
    }

    struct NutritionComponentResponse: Decodable {
        let name: String
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
    }

    struct NutritionParseResponse: Decodable {
        let success: Bool
        let name: String?
        let calories: Int?
        let protein: Int?
        let carbs: Int?
        let fat: Int?
        let confidence: String?
        let components: [NutritionComponentResponse]?
        let error: String?
    }

    struct MacroStatusRequest: Encodable {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
        let is_training_day: Bool
    }

    struct MacroStatusResponse: Decodable {
        let feedback: String
    }

    struct TrainingDayResponse: Decodable {
        let is_training_day: Bool
        let workout_name: String?
    }

    struct NutritionCorrectRequest: Encodable {
        let original_name: String
        let original_calories: Int
        let original_protein: Int
        let original_carbs: Int
        let original_fat: Int
        let correction: String
    }

    struct NutritionCorrectResponse: Decodable {
        let success: Bool
        let name: String?
        let calories: Int?
        let protein: Int?
        let carbs: Int?
        let fat: Int?
        let error: String?
    }

    struct ProfileInsight: Decodable {
        let date: String
        let insight: String
        let source: String
    }

    struct ProfileResponse: Decodable {
        let goals: [String]
        let constraints: [String]
        let preferences: [String]
        let context: [String]
        let patterns: [String]
        let communication_style: String
        let insights_count: Int
        let recent_insights: [ProfileInsight]
        let has_profile: Bool
    }

    func sendMessage(
        _ message: String,
        systemPrompt: String? = nil,
        healthContext: [String: String]? = nil,
        nutritionContext: NutritionContext? = nil
    ) async throws -> String {
        let url = baseURL.appendingPathComponent("chat")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatRequest(
            message: message,
            system_prompt: systemPrompt,
            health_context: healthContext,
            nutrition_context: nutritionContext
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

        if !chatResponse.success {
            throw APIError.llmError(chatResponse.error ?? "Unknown error")
        }

        return chatResponse.response
    }

    func checkHealth() async -> Bool {
        let url = baseURL.appendingPathComponent("health")

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    func parseNutrition(_ foodText: String) async throws -> NutritionParseResponse {
        let url = baseURL.appendingPathComponent("nutrition/parse")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = NutritionParseRequest(food_text: foodText)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(NutritionParseResponse.self, from: data)
    }

    func getMacroFeedback(calories: Int, protein: Int, carbs: Int, fat: Int, isTrainingDay: Bool) async throws -> String {
        let url = baseURL.appendingPathComponent("nutrition/status")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = MacroStatusRequest(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            is_training_day: isTrainingDay
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let result = try JSONDecoder().decode(MacroStatusResponse.self, from: data)
        return result.feedback
    }

    func checkTrainingDay() async -> (isTraining: Bool, workoutName: String?) {
        let url = baseURL.appendingPathComponent("nutrition/training-day")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return (false, nil)
            }

            let result = try JSONDecoder().decode(TrainingDayResponse.self, from: data)
            return (result.is_training_day, result.workout_name)
        } catch {
            return (false, nil)
        }
    }

    func correctNutrition(
        originalName: String,
        originalCalories: Int,
        originalProtein: Int,
        originalCarbs: Int,
        originalFat: Int,
        correction: String
    ) async throws -> NutritionCorrectResponse {
        let url = baseURL.appendingPathComponent("nutrition/correct")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = NutritionCorrectRequest(
            original_name: originalName,
            original_calories: originalCalories,
            original_protein: originalProtein,
            original_carbs: originalCarbs,
            original_fat: originalFat,
            correction: correction
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(NutritionCorrectResponse.self, from: data)
    }

    func getProfile() async throws -> ProfileResponse {
        let url = baseURL.appendingPathComponent("profile")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(ProfileResponse.self, from: data)
    }

    func clearProfile() async throws {
        let url = baseURL.appendingPathComponent("profile")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
    }

    func clearChatSession() async throws {
        let url = baseURL.appendingPathComponent("chat/session")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
    }

    // MARK: - Insights Sync

    struct DailySyncData: Encodable {
        let date: String  // YYYY-MM-DD
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
        let nutrition_entries: Int
        let steps: Int
        let active_calories: Int
        let weight_lbs: Double?
        let body_fat_pct: Double?
        let sleep_hours: Double?
        let resting_hr: Int?
        let hrv_ms: Double?
    }

    struct SyncRequest: Encodable {
        let days: [DailySyncData]
    }

    struct SyncResponse: Decodable {
        let status: String
        let dates_synced: [String]
        let count: Int
    }

    struct InsightData: Decodable, Identifiable {
        let id: String
        let category: String
        let tier: Int
        let title: String
        let body: String
        let importance: Double
        let created_at: String
        let suggested_actions: [String]
    }

    struct ContextSummary: Decodable {
        let period_days: Int
        let nutrition_days: Int
        let avg_calories: Int
        let avg_protein: Int
        let avg_carbs: Int
        let avg_fat: Int
        let avg_weight: Double?
        let weight_change: Double?
        let avg_sleep: Double?
        let avg_steps: Int
        let total_workouts: Int
        let avg_volume_per_workout: Double
        let protein_compliance: Double?
        let calorie_compliance: Double?
    }

    /// Sync daily data (nutrition + health) to the server for insights
    func syncInsightsData(_ days: [DailySyncData]) async throws -> SyncResponse {
        let url = baseURL.appendingPathComponent("insights/sync")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = SyncRequest(days: days)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(SyncResponse.self, from: data)
    }

    /// Get aggregated context for a time range
    func getInsightsContext(range: String = "week") async throws -> ContextSummary {
        var components = URLComponents(url: baseURL.appendingPathComponent("insights/context"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "range", value: range)]

        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(ContextSummary.self, from: data)
    }

    /// Get AI-generated insights
    func getInsights(category: String? = nil, limit: Int = 10) async throws -> [InsightData] {
        var components = URLComponents(url: baseURL.appendingPathComponent("insights"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: String(limit))]
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        components.queryItems = queryItems

        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode([InsightData].self, from: data)
    }

    /// Record engagement with an insight
    func engageInsight(id: String, action: String, feedback: String? = nil) async throws {
        var components = URLComponents(url: baseURL.appendingPathComponent("insights/\(id)/engage"), resolvingAgainstBaseURL: false)!
        var queryItems = [URLQueryItem(name: "action", value: action)]
        if let feedback = feedback {
            queryItems.append(URLQueryItem(name: "feedback", value: feedback))
        }
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
    }

    // MARK: - Insight Generation

    struct GenerateInsightsRequest: Encodable {
        let days: Int
        let force: Bool
    }

    struct GenerateInsightsResponse: Decodable {
        let success: Bool
        let insights_generated: Int
        let token_estimate: Int
        let insights: [InsightData]
        let error: String?
    }

    /// Generate new AI insights from all available data (uses CLI, no API cost)
    func generateInsights(days: Int = 90, force: Bool = false) async throws -> GenerateInsightsResponse {
        let url = baseURL.appendingPathComponent("insights/generate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120  // Give CLI time to respond

        let body = GenerateInsightsRequest(days: days, force: force)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(GenerateInsightsResponse.self, from: data)
    }
}

enum APIError: Error, LocalizedError {
    case serverError
    case llmError(String)

    var errorDescription: String? {
        switch self {
        case .serverError:
            return "Could not connect to server"
        case .llmError(let message):
            return message
        }
    }
}
