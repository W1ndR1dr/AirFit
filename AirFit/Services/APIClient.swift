import Foundation

actor APIClient {
    private let baseURL: URL

    /// Initialize with server URL from shared configuration.
    /// Each APIClient instance reads the current URL at init time.
    /// For Tailscale/TestFlight: URL is configured during onboarding or in Settings.
    init() {
        // Thread-safe read from UserDefaults via ServerConfiguration
        self.baseURL = ServerConfiguration.configuredBaseURL
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

    /// Shared macro data - used by both parse and correct responses
    struct MacroData: Decodable {
        let name: String?
        let calories: Int?
        let protein: Int?
        let carbs: Int?
        let fat: Int?
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

        /// Convert to MacroData for common handling
        var macros: MacroData {
            MacroData(name: name, calories: calories, protein: protein, carbs: carbs, fat: fat)
        }
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

        /// Convert to MacroData for common handling
        var macros: MacroData {
            MacroData(name: name, calories: calories, protein: protein, carbs: carbs, fat: fat)
        }
    }

    struct ProfileInsight: Decodable {
        let date: String
        let insight: String
        let source: String
    }

    struct ProfileResponse: Decodable {
        let name: String?
        let summary: String?  // One-liner: "Surgeon. Father. Chasing 15%."
        let goals: [String]
        let constraints: [String]
        let preferences: [String]
        let context: [String]
        let patterns: [String]
        let communication_style: String
        let insights_count: Int
        let recent_insights: [ProfileInsight]
        let has_profile: Bool
        let onboarding_complete: Bool

        // Phase tracking
        let current_phase: String?
        let phase_context: String?

        var needsOnboarding: Bool {
            !onboarding_complete
        }
    }

    struct FinalizeOnboardingResponse: Decodable {
        let status: String
        let name: String?
        let has_personality: Bool
        let preview: String?
    }

    struct ProfileCompleteness: Decodable {
        let has_name: Bool
        let has_goals: Bool
        let has_training: Bool
        let has_style: Bool
    }

    struct OnboardingChatRequest: Encodable {
        let message: String
        let session_id: String?
    }

    struct OnboardingChatResponse: Decodable {
        let response: String
        let session_id: String
        let profile_completeness: ProfileCompleteness?
    }

    struct ServerStatusResponse: Decodable {
        let status: String
        let providers: [String]
        let hevy_configured: Bool
        let version: String
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

    // MARK: - Direct Gemini Support

    /// Fetch context bundle for direct Gemini API calls.
    ///
    /// Returns system prompt, memory context, and data context that iOS
    /// uses when calling Gemini directly (bypassing the server for chat).
    func getChatContext() async throws -> ChatContext {
        let url = baseURL.appendingPathComponent("chat/context")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(ChatContext.self, from: data)
    }

    /// Send a conversation excerpt for profile evolution processing.
    ///
    /// Called after Gemini conversations to extract memories and update
    /// the user profile. This keeps the "getting to know you" evolution working.
    func processConversation(userMessage: String, aiResponse: String) async throws {
        let url = baseURL.appendingPathComponent("chat/process-conversation")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct ConversationExcerpt: Encodable {
            let user_message: String
            let ai_response: String
        }

        let body = ConversationExcerpt(user_message: userMessage, ai_response: aiResponse)
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
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

    // MARK: - Profile Export/Import

    struct ProfileImportResponse: Decodable {
        let success: Bool
        let name: String?
        let goals_count: Int?
        let has_personality: Bool?
        let error: String?
    }

    /// Export the full profile as JSON data for backup.
    func exportProfile() async throws -> Data {
        let url = baseURL.appendingPathComponent("profile/export")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return data
    }

    /// Import a previously exported profile.
    func importProfile(data: Data) async throws -> ProfileImportResponse {
        let url = baseURL.appendingPathComponent("profile/import")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(ProfileImportResponse.self, from: responseData)
    }

    // MARK: - Profile Item Editing

    struct ProfileItemUpdateRequest: Encodable {
        let category: String
        let old_value: String
        let new_value: String?
    }

    /// Update a profile item (or delete if newValue is nil)
    func updateProfileItem(category: String, oldValue: String, newValue: String?) async throws {
        let url = baseURL.appendingPathComponent("profile/item")

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ProfileItemUpdateRequest(
            category: category,
            old_value: oldValue,
            new_value: newValue
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
    }

    func finalizeOnboarding() async throws -> FinalizeOnboardingResponse {
        let url = baseURL.appendingPathComponent("profile/finalize-onboarding")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60  // Personality synthesis can take time

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(FinalizeOnboardingResponse.self, from: data)
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

    // MARK: - Onboarding

    func sendOnboardingMessage(_ message: String, sessionId: String? = nil) async throws -> OnboardingChatResponse {
        let url = baseURL.appendingPathComponent("chat/onboarding")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body = OnboardingChatRequest(message: message, session_id: sessionId)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(OnboardingChatResponse.self, from: data)
    }

    func getStatus() async throws -> ServerStatusResponse {
        let url = baseURL.appendingPathComponent("health")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(ServerStatusResponse.self, from: data)
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

        // Recovery metrics (Phase 1: HealthKit Dashboard Expansion)
        let sleep_efficiency: Double?           // 0.0-1.0, time asleep / time in bed
        let sleep_deep_pct: Double?             // Proportion of deep sleep (0.0-1.0)
        let sleep_core_pct: Double?             // Proportion of core/light sleep (0.0-1.0)
        let sleep_rem_pct: Double?              // Proportion of REM sleep (0.0-1.0)
        let sleep_onset_minutes: Int?           // Minutes from midnight (for bedtime tracking)
        let hrv_baseline_ms: Double?            // 7-day rolling mean HRV
        let hrv_deviation_pct: Double?          // Today's deviation from baseline (%)
        let bedtime_consistency: String?        // "stable", "variable", or "irregular"
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
        let supporting_data: SupportingData?

        // Custom decoding to handle flexible supporting_data structure
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            category = try container.decode(String.self, forKey: .category)
            tier = try container.decode(Int.self, forKey: .tier)
            title = try container.decode(String.self, forKey: .title)
            body = try container.decode(String.self, forKey: .body)
            importance = try container.decode(Double.self, forKey: .importance)
            created_at = try container.decode(String.self, forKey: .created_at)
            suggested_actions = try container.decodeIfPresent([String].self, forKey: .suggested_actions) ?? []
            supporting_data = try? container.decode(SupportingData.self, forKey: .supporting_data)
        }

        private enum CodingKeys: String, CodingKey {
            case id, category, tier, title, body, importance, created_at, suggested_actions, supporting_data
        }

        /// Manual initializer for creating InsightData locally (e.g., from Gemini response).
        init(
            id: String,
            category: String,
            tier: Int,
            title: String,
            body: String,
            importance: Double,
            created_at: String,
            suggested_actions: [String],
            supporting_data: SupportingData?
        ) {
            self.id = id
            self.category = category
            self.tier = tier
            self.title = title
            self.body = body
            self.importance = importance
            self.created_at = created_at
            self.suggested_actions = suggested_actions
            self.supporting_data = supporting_data
        }
    }

    /// Supporting data for insight visualization
    struct SupportingData: Decodable {
        let metric: String?
        let values: [Double]?
        let dates: [String]?
        let target: Double?
        let trend_slope: Double?
        let current_value: Double?
        let previous_value: Double?
        let change_pct: Double?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            metric = try? container.decode(String.self, forKey: .metric)
            values = try? container.decode([Double].self, forKey: .values)
            dates = try? container.decode([String].self, forKey: .dates)
            target = try? container.decode(Double.self, forKey: .target)
            trend_slope = try? container.decode(Double.self, forKey: .trend_slope)
            current_value = try? container.decode(Double.self, forKey: .current_value)
            previous_value = try? container.decode(Double.self, forKey: .previous_value)
            change_pct = try? container.decode(Double.self, forKey: .change_pct)
        }

        private enum CodingKeys: String, CodingKey {
            case metric, values, dates, target, trend_slope, current_value, previous_value, change_pct
        }

        /// Manual initializer for creating SupportingData locally.
        init(
            metric: String?,
            values: [Double]?,
            dates: [String]?,
            target: Double?,
            trend_slope: Double?,
            current_value: Double?,
            previous_value: Double?,
            change_pct: Double?
        ) {
            self.metric = metric
            self.values = values
            self.dates = dates
            self.target = target
            self.trend_slope = trend_slope
            self.current_value = current_value
            self.previous_value = previous_value
            self.change_pct = change_pct
        }
    }

    /// Daily nutrition data point for sparklines
    struct DailyNutritionPoint: Decodable {
        let date: String
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
    }

    /// Daily health data point for sparklines
    struct DailyHealthPoint: Decodable {
        let date: String
        let sleep_hours: Double?
        let weight_lbs: Double?
        let steps: Int
        let active_calories: Int
    }

    /// Context summary with both averages AND daily breakdown
    /// ARCHITECTURE NOTE: Server stores daily aggregates, not individual meals.
    /// iOS device owns granular entries; server receives totals per day.
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

        // Daily breakdown for sparklines (NEW)
        // Exposes actual day-to-day values instead of just averages
        let daily_nutrition: [DailyNutritionPoint]?
        let daily_health: [DailyHealthPoint]?
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

    // MARK: - Insight Discussion (Tell Me More)

    struct InsightDiscussRequest: Encodable {
        let message: String
    }

    struct InsightDiscussResponse: Decodable {
        let response: String
        let provider: String
        let success: Bool
        let insight_title: String
        let error: String?
    }

    /// Discuss a specific insight with full context (for "Tell me more" feature)
    func discussInsight(id: String, message: String) async throws -> String {
        let url = baseURL.appendingPathComponent("insights/\(id)/discuss")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60  // Give AI time to respond with context

        let body = InsightDiscussRequest(message: message)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let result = try JSONDecoder().decode(InsightDiscussResponse.self, from: data)

        if !result.success {
            throw APIError.llmError(result.error ?? "Failed to discuss insight")
        }

        return result.response
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

    // MARK: - Server Status

    struct StatusResponse: Decodable {
        let status: String
        let available_providers: [String]
        let session_id: String?
        let message_count: Int?
    }

    func getServerStatus() async throws -> ServerInfo {
        let url = baseURL.appendingPathComponent("status")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let result = try JSONDecoder().decode(StatusResponse.self, from: data)

        return ServerInfo(
            host: baseURL.host ?? "unknown",
            activeProvider: result.available_providers.first ?? "none",
            availableProviders: result.available_providers,
            sessionId: result.session_id,
            messageCount: result.message_count
        )
    }

    func clearSession() async throws {
        try await clearChatSession()
    }

    // MARK: - Training Tab (Hevy Data)

    struct MuscleGroupData: Decodable {
        let current: Int
        let min: Int
        let max: Int
        let status: String  // in_zone, below, at_floor, above
    }

    struct SetTrackerResponse: Decodable {
        let window_days: Int
        let muscle_groups: [String: MuscleGroupData]
        let last_sync: String?
    }

    struct PRData: Decodable {
        let weight_lbs: Double
        let reps: Int
        let date: String
    }

    struct HistoryPoint: Decodable {
        let date: String
        let weight_lbs: Double
    }

    struct LiftData: Decodable, Identifiable {
        let name: String
        let workout_count: Int
        let current_pr: PRData
        let history: [HistoryPoint]

        var id: String { name }
    }

    struct LiftProgressResponse: Decodable {
        let lifts: [LiftData]
    }

    struct WorkoutSummary: Decodable, Identifiable {
        let id: String
        let title: String
        let date: String
        let days_ago: Int
        let duration_minutes: Int
        let exercises: [String]
        let total_volume_lbs: Double
    }

    struct RecentWorkoutsResponse: Decodable {
        let workouts: [WorkoutSummary]
    }

    /// Get rolling 7-day set counts by muscle group
    func getSetTracker(days: Int = 7) async throws -> SetTrackerResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("hevy/set-tracker"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "days", value: String(days))]

        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(SetTrackerResponse.self, from: data)
    }

    /// Get all-time PR progress for top lifts
    func getLiftProgress(topN: Int = 6) async throws -> LiftProgressResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("hevy/lift-progress"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "top_n", value: String(topN))]

        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(LiftProgressResponse.self, from: data)
    }

    /// Get recent workout summaries
    func getRecentWorkouts(limit: Int = 7) async throws -> [WorkoutSummary] {
        var components = URLComponents(url: baseURL.appendingPathComponent("hevy/recent-workouts"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]

        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let result = try JSONDecoder().decode(RecentWorkoutsResponse.self, from: data)
        return result.workouts
    }

    // MARK: - Body Metrics

    struct MetricPoint: Decodable {
        let date: String
        let value: Double
    }

    struct CurrentBodyMetrics: Decodable {
        let weight_lbs: Double?
        let body_fat_pct: Double?
        let lean_mass_lbs: Double?
    }

    struct BodyTrends: Decodable {
        let weight_change_30d: Double?
        let body_fat_change_30d: Double?
        let lean_mass_change_30d: Double?
    }

    struct BodyMetricsResponse: Decodable {
        let current: CurrentBodyMetrics
        let weight_history: [MetricPoint]
        let body_fat_history: [MetricPoint]
        let lean_mass_history: [MetricPoint]
        let trends: BodyTrends
    }

    /// Get body composition history for charts
    func getBodyMetrics(days: Int = 90) async throws -> BodyMetricsResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("health/body-metrics"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "days", value: String(days))]

        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(BodyMetricsResponse.self, from: data)
    }

    // MARK: - Strength Tracking

    /// Personal record for an exercise with estimated 1RM
    struct ExercisePR: Decodable, Equatable {
        let weight_lbs: Double
        let reps: Int
        let date: String
        let e1rm: Double  // Estimated 1RM (Epley formula)
    }

    /// Sort options for exercise list
    enum ExerciseSortOption: String, CaseIterable {
        case frequency = "frequency"
        case mostImproved = "most_improved"
        case leastImproved = "least_improved"

        var displayName: String {
            switch self {
            case .frequency: return "Most Frequent"
            case .mostImproved: return "Most Improved"
            case .leastImproved: return "Least Improved"
            }
        }
    }

    /// Time window options for filtering
    enum TimeWindow: Int, CaseIterable {
        case oneMonth = 30
        case threeMonths = 90
        case sixMonths = 180
        case oneYear = 365
        case allTime = 0

        var displayName: String {
            switch self {
            case .oneMonth: return "1M"
            case .threeMonths: return "3M"
            case .sixMonths: return "6M"
            case .oneYear: return "1Y"
            case .allTime: return "All"
            }
        }

        var days: Int? {
            self == .allTime ? nil : rawValue
        }
    }

    /// A tracked exercise with PR and trend data
    struct TrackedExercise: Decodable, Identifiable, Equatable {
        let name: String
        let workout_count: Int
        let current_pr: ExercisePR?
        let recent_trend: [Double]  // Last 8 e1RM values for mini sparkline
        let improvement: Double?  // lbs e1RM per month

        var id: String { name }
    }

    struct TrackedExercisesResponse: Decodable {
        let exercises: [TrackedExercise]
        let last_sync: String?
    }

    /// Single data point for strength chart
    struct StrengthHistoryPoint: Decodable {
        let date: String
        let e1rm: Double
        let weight_lbs: Double
        let reps: Int
    }

    struct StrengthHistoryResponse: Decodable {
        let exercise: String
        let history: [StrengthHistoryPoint]
        let current_pr: ExercisePR?
        let trend: Double?  // lbs per month
    }

    struct ExerciseSyncResponse: Decodable {
        let status: String
        let workouts_processed: Int
        let exercises_updated: Int
        let error: String?
    }

    /// Get top tracked exercises with current PRs
    func getTrackedExercises(
        limit: Int = 20,
        sortBy: ExerciseSortOption = .frequency,
        timeWindow: TimeWindow = .allTime
    ) async throws -> TrackedExercisesResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("training/exercises"), resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "sort_by", value: sortBy.rawValue)
        ]

        if let days = timeWindow.days {
            queryItems.append(URLQueryItem(name: "days", value: String(days)))
        }

        components.queryItems = queryItems

        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(TrackedExercisesResponse.self, from: data)
    }

    /// Get performance history for a specific exercise
    func getStrengthHistory(exercise: String, days: Int = 365) async throws -> StrengthHistoryResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("training/strength-history"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "exercise", value: exercise),
            URLQueryItem(name: "days", value: String(days))
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(StrengthHistoryResponse.self, from: data)
    }

    /// Sync exercise history from Hevy workouts
    func syncExerciseHistory(full: Bool = false) async throws -> ExerciseSyncResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("training/sync"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "full", value: String(full))]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        return try JSONDecoder().decode(ExerciseSyncResponse.self, from: data)
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
