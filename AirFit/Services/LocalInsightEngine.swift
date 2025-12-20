import Foundation
import SwiftData

/// On-device insight generation using Gemini API.
///
/// Mirrors the server's insight_engine.py - gathers local data (HealthKit, SwiftData),
/// formats it compactly, sends to Gemini, and parses the response into InsightData.
///
/// Used when aiProvider == "gemini" to generate insights without server dependency.
actor LocalInsightEngine {
    private let geminiService = GeminiService()
    private let healthKit = HealthKitManager()

    // MARK: - Public API

    /// Generate insights from local data via Gemini.
    ///
    /// - Parameters:
    ///   - days: Number of days of history to analyze
    ///   - modelContext: SwiftData context for nutrition queries
    /// - Returns: Array of insights matching the server format
    @MainActor
    func generateInsights(days: Int = 7, modelContext: ModelContext) async throws -> [APIClient.InsightData] {
        // 1. Gather all data
        let snapshots = await gatherDailySnapshots(days: days, modelContext: modelContext)

        guard !snapshots.isEmpty else {
            return []
        }

        // 2. Format in compact form (same as server's format_all_data_compact)
        let context = formatAllDataCompact(snapshots)

        // 3. Send to Gemini
        let response = try await geminiService.chat(
            message: "Analyze this fitness data and return insights as JSON:\n\n\(context)",
            history: [],
            systemPrompt: Self.insightPrompt
        )

        // 4. Parse response
        return try parseInsights(response)
    }

    // MARK: - Data Gathering

    /// Combined daily snapshot with health + nutrition data.
    struct DailySnapshot {
        let date: String  // YYYY-MM-DD
        let health: DailyHealthSnapshot
        let nutrition: NutritionSummary
        let workout: WorkoutSummary?
    }

    struct NutritionSummary {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
        let entryCount: Int
    }

    struct WorkoutSummary {
        let count: Int
        let duration: Int
        let volume: Double
        let exercises: [ExerciseSummary]
    }

    struct ExerciseSummary {
        let name: String
        let sets: Int
        let reps: Int
        let weight: Double
    }

    /// Gather daily snapshots combining HealthKit and SwiftData.
    @MainActor
    private func gatherDailySnapshots(days: Int, modelContext: ModelContext) async -> [DailySnapshot] {
        var snapshots: [DailySnapshot] = []
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                continue
            }

            // Get health data
            let healthSnapshot = await healthKit.getDailySnapshot(for: date)

            // Get nutrition data from SwiftData
            let nutritionSummary = await getNutritionForDay(date, modelContext: modelContext)

            let snapshot = DailySnapshot(
                date: dateFormatter.string(from: date),
                health: healthSnapshot,
                nutrition: nutritionSummary,
                workout: nil  // TODO: Add from HevyCacheManager when implemented
            )

            snapshots.append(snapshot)
        }

        return snapshots
    }

    /// Get nutrition totals for a specific day.
    @MainActor
    private func getNutritionForDay(_ date: Date, modelContext: ModelContext) -> NutritionSummary {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let descriptor = FetchDescriptor<NutritionEntry>(
            predicate: #Predicate<NutritionEntry> { entry in
                entry.timestamp >= startOfDay && entry.timestamp < endOfDay
            }
        )

        do {
            let entries = try modelContext.fetch(descriptor)
            return NutritionSummary(
                calories: entries.reduce(0) { $0 + $1.calories },
                protein: entries.reduce(0) { $0 + $1.protein },
                carbs: entries.reduce(0) { $0 + $1.carbs },
                fat: entries.reduce(0) { $0 + $1.fat },
                entryCount: entries.count
            )
        } catch {
            print("[LocalInsightEngine] Failed to fetch nutrition: \(error)")
            return NutritionSummary(calories: 0, protein: 0, carbs: 0, fat: 0, entryCount: 0)
        }
    }

    // MARK: - Data Formatting (mirrors server's format_day_compact)

    /// Format all data in ultra-compact form for Gemini.
    nonisolated private func formatAllDataCompact(_ snapshots: [DailySnapshot]) -> String {
        var lines: [String] = []

        // Header with legend (helps Gemini understand the format)
        lines.append("=== RAW FITNESS DATA ===")
        lines.append("Format: DATE | N:cal|prot|carb|fat|entries | H:w(lbs),bf(%),sl(hrs),hr,hrv(ms),st(steps),ac(kcal) | W:count|dur|vol exercises")
        lines.append("")
        lines.append("--- DAILY DATA (newest first) ---")

        // Format each day compactly
        for snapshot in snapshots.sorted(by: { $0.date > $1.date }) {
            let dayStr = formatDayCompact(snapshot)
            if dayStr.count > 12 {  // Only include days with actual data
                lines.append(dayStr)
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Format a single day's data in ultra-compact form (~40-60 tokens).
    nonisolated private func formatDayCompact(_ snapshot: DailySnapshot) -> String {
        var parts: [String] = [snapshot.date]

        // Nutrition: cal|p|c|f|entries
        let n = snapshot.nutrition
        if n.calories > 0 {
            parts.append("N:\(n.calories)|\(n.protein)|\(n.carbs)|\(n.fat)|\(n.entryCount)")
        }

        // Health: w,bf,sl,hr,hrv,st,ac
        let h = snapshot.health
        var healthParts: [String] = []

        if let weight = h.weightLbs {
            healthParts.append("w\(String(format: "%.1f", weight))")
        }
        if let bf = h.bodyFatPct {
            healthParts.append("bf\(String(format: "%.1f", bf))")
        }
        if let sleep = h.sleepHours {
            healthParts.append("sl\(String(format: "%.1f", sleep))")
        }
        if let hr = h.restingHR {
            healthParts.append("hr\(hr)")
        }
        if let hrv = h.hrvMs {
            healthParts.append("hrv\(Int(hrv))")
        }
        if h.steps > 0 {
            healthParts.append("st\(h.steps)")
        }
        if h.activeCalories > 0 {
            healthParts.append("ac\(h.activeCalories)")
        }

        if !healthParts.isEmpty {
            parts.append("H:" + healthParts.joined(separator: ","))
        }

        // Workouts (from cache when available)
        if let w = snapshot.workout, w.count > 0 {
            var workoutStr = "W:\(w.count)x|\(w.duration)m|\(Int(w.volume))kg"
            if !w.exercises.isEmpty {
                let exStrs = w.exercises.prefix(8).map { ex in
                    "\(ex.name.prefix(12))(\(ex.sets)×\(ex.reps)@\(Int(ex.weight)))"
                }
                workoutStr += " " + exStrs.joined(separator: ",")
            }
            parts.append(workoutStr)
        }

        return parts.joined(separator: " | ")
    }

    // MARK: - Response Parsing

    /// Parse Gemini's JSON response into InsightData array.
    nonisolated private func parseInsights(_ response: String) throws -> [APIClient.InsightData] {
        // Clean response (remove markdown code blocks if present)
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to extract JSON if wrapped in other text
        if let startIndex = cleanedResponse.firstIndex(of: "{"),
           let endIndex = cleanedResponse.lastIndex(of: "}") {
            cleanedResponse = String(cleanedResponse[startIndex...endIndex])
        }

        guard let jsonData = cleanedResponse.data(using: .utf8) else {
            throw InsightError.invalidResponse("Failed to convert response to data")
        }

        // Parse the wrapper object
        let wrapper = try JSONDecoder().decode(InsightsWrapper.self, from: jsonData)
        return wrapper.insights.map { raw in
            raw.toInsightData()
        }
    }

    // MARK: - Error Types

    enum InsightError: LocalizedError {
        case invalidResponse(String)
        case noData

        var errorDescription: String? {
            switch self {
            case .invalidResponse(let message): return "Invalid response: \(message)"
            case .noData: return "No data available for insight generation"
            }
        }
    }

    // MARK: - JSON Parsing Types

    private struct InsightsWrapper: Decodable {
        let insights: [RawInsight]
    }

    private struct RawInsight: Decodable {
        let category: String
        let tier: Int?
        let title: String
        let body: String
        let importance: Double?
        let confidence: Double?
        let suggested_actions: [String]?
        let supporting_data: RawSupportingData?

        func toInsightData() -> APIClient.InsightData {
            return APIClient.InsightData(
                id: UUID().uuidString,
                category: category,
                tier: tier ?? 3,
                title: title,
                body: body,
                importance: importance ?? 0.5,
                created_at: ISO8601DateFormatter().string(from: Date()),
                suggested_actions: suggested_actions ?? [],
                supporting_data: supporting_data?.toSupportingData()
            )
        }
    }

    private struct RawSupportingData: Decodable {
        let metric: String?
        let values: [Double]?
        let current_value: Double?
        let previous_value: Double?
        let change_pct: Double?
        let target: Double?
        let trend_slope: Double?

        func toSupportingData() -> APIClient.SupportingData {
            return APIClient.SupportingData(
                metric: metric,
                values: values,
                dates: nil,
                target: target,
                trend_slope: trend_slope,
                current_value: current_value,
                previous_value: previous_value,
                change_pct: change_pct
            )
        }
    }

    // MARK: - Insight Prompt (mirrors server's INSIGHT_PROMPT)

    static let insightPrompt = """
    You are an expert fitness coach analyzing a client's data. You have access to their complete raw data - nutrition, health metrics, and workout history.

    Your job: Find what's interesting, important, or actionable. Look for patterns, correlations, anomalies, progress, and risks.

    Be specific and data-driven. Reference actual numbers from the data. Don't be generic - if you see something noteworthy, call it out with evidence.

    Focus on insights the user wouldn't easily notice themselves - especially cross-domain correlations (e.g., how sleep affects training, how protein timing correlates with weight changes, etc.)

    Respond in JSON format with an array of insights:
    ```json
    {
      "insights": [
        {
          "category": "correlation|trend|anomaly|milestone|nudge",
          "tier": 1-5,
          "title": "Short punchy title (max 8 words)",
          "body": "Conversational explanation with data references (2-3 sentences)",
          "importance": 0.0-1.0,
          "confidence": 0.0-1.0,
          "suggested_actions": ["action 1", "action 2"],
          "supporting_data": {
            "metric": "protein|weight|calories|sleep|steps|volume",
            "values": [145, 150, 155, 160, 165],
            "current_value": 165,
            "change_pct": 13.8,
            "target": 160
          }
        }
      ]
    }
    ```

    IMPORTANT for supporting_data:
    - Include "values" array with 5-10 recent data points for charting (oldest to newest)
    - Include "metric" to label the data type
    - Include "current_value" and "change_pct" when showing trends
    - Include "target" if there's a goal being measured against
    - This data powers inline sparkline visualizations in the app

    Categories:
    - correlation: Cross-domain patterns (highest value - things humans miss)
    - trend: Directional movement over time
    - anomaly: Something unusual that needs attention
    - milestone: Achievement or progress worth celebrating
    - nudge: Gentle reminder or suggestion

    Tiers (1=highest priority):
    1. Critical insights requiring immediate attention
    2. Important patterns affecting goals
    3. Noteworthy observations
    4. Nice-to-know information
    5. Minor observations

    Generate 3-5 insights based on what's actually interesting in the data. Quality over quantity.
    Return ONLY valid JSON, no additional text.
    """
}

