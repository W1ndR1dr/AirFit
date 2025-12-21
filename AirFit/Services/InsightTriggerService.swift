import Foundation
import SwiftData

/// Intelligent insight generation triggers.
///
/// Instead of clock-based ("every 6 hours"), uses event-driven + data-aware triggers:
/// - **Data events**: Workout logged, weight recorded, significant nutrition
/// - **Threshold-based**: N new data points since last analysis
/// - **LLM meta-decision**: Ask the AI if insight generation is worthwhile
///
/// AI-Native Philosophy: Let the data signal when insights are valuable.
actor InsightTriggerService {
    static let shared = InsightTriggerService()

    private let localInsightEngine = LocalInsightEngine()
    private let geminiService = GeminiService()

    // MARK: - Delta Tracking

    /// Tracks data changes since last insight generation
    struct DataDelta: Codable {
        var newWorkouts: Int = 0
        var newNutritionEntries: Int = 0
        var newWeightMeasurements: Int = 0
        var lastInsightGeneration: Date?

        var totalNewDataPoints: Int {
            newWorkouts + newNutritionEntries + newWeightMeasurements
        }

        var daysSinceLastGeneration: Int {
            guard let last = lastInsightGeneration else { return 999 }
            return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        }
    }

    private var delta: DataDelta
    private let deltaKey = "insightTriggerDelta"

    // MARK: - Thresholds

    /// Minimum new data points before considering insight generation
    private let minDataPointsThreshold = 5

    /// Maximum days without insights before forcing generation
    private let maxDaysWithoutInsights = 3

    /// Minimum new workouts to trigger immediate generation
    private let significantWorkoutThreshold = 2

    // MARK: - Initialization

    init() {
        // Load delta synchronously from UserDefaults
        if let data = UserDefaults.standard.data(forKey: deltaKey),
           let loaded = try? JSONDecoder().decode(DataDelta.self, from: data) {
            self.delta = loaded
        } else {
            self.delta = DataDelta()
        }
    }

    // MARK: - Event Recording

    /// Record a new workout was synced.
    /// Call this when Hevy sync completes with new workouts.
    func recordNewWorkouts(_ count: Int) {
        delta.newWorkouts += count
        saveDelta()
        print("[InsightTrigger] Recorded \(count) new workouts (total delta: \(delta.totalNewDataPoints))")
    }

    /// Record new nutrition entries were logged.
    /// Call this after nutrition parsing completes.
    func recordNewNutritionEntries(_ count: Int) {
        delta.newNutritionEntries += count
        saveDelta()
        print("[InsightTrigger] Recorded \(count) new nutrition entries (total delta: \(delta.totalNewDataPoints))")
    }

    /// Record a new weight measurement.
    /// Call this when HealthKit syncs new weight data.
    func recordNewWeightMeasurement() {
        delta.newWeightMeasurements += 1
        saveDelta()
        print("[InsightTrigger] Recorded new weight measurement (total delta: \(delta.totalNewDataPoints))")
    }

    // MARK: - Trigger Evaluation

    /// Check if insight generation should be triggered.
    ///
    /// Returns true if:
    /// - Enough new data has accumulated (threshold-based)
    /// - Too long since last generation (staleness)
    /// - Significant workout activity (event-based)
    func shouldTriggerGeneration() -> Bool {
        // Force if too long since last generation
        if delta.daysSinceLastGeneration >= maxDaysWithoutInsights {
            print("[InsightTrigger] Triggering: \(delta.daysSinceLastGeneration) days since last generation")
            return true
        }

        // Force if significant workout activity
        if delta.newWorkouts >= significantWorkoutThreshold {
            print("[InsightTrigger] Triggering: \(delta.newWorkouts) new workouts")
            return true
        }

        // Check if enough data has accumulated
        if delta.totalNewDataPoints >= minDataPointsThreshold {
            print("[InsightTrigger] Triggering: \(delta.totalNewDataPoints) new data points")
            return true
        }

        return false
    }

    /// AI-powered decision: Ask the LLM if insight generation is worthwhile.
    ///
    /// This is the most AI-native approach - let the AI decide when to think.
    /// Uses a cheap, fast call with minimal context.
    func shouldTriggerGenerationAI() async -> Bool {
        // Skip AI check if obviously should trigger
        if delta.daysSinceLastGeneration >= maxDaysWithoutInsights {
            return true
        }

        // Skip AI check if obviously shouldn't
        if delta.totalNewDataPoints < 2 {
            return false
        }

        // Ask the AI
        let prompt = """
        You are deciding if it's worth generating new fitness insights.

        Data since last analysis:
        - New workouts: \(delta.newWorkouts)
        - New nutrition entries: \(delta.newNutritionEntries)
        - New weight measurements: \(delta.newWeightMeasurements)
        - Days since last insight generation: \(delta.daysSinceLastGeneration)

        Is there enough new data to find meaningful patterns? Consider:
        - More workouts = more training patterns to analyze
        - More nutrition entries = better compliance/macro tracking
        - Weight changes = body composition trends

        Respond with ONLY "yes" or "no".
        """

        do {
            let response = try await geminiService.chat(
                message: prompt,
                history: [],
                systemPrompt: "You make quick yes/no decisions. Respond with only 'yes' or 'no'.",
                thinkingLevel: .low  // Fast, cheap decision
            )

            let shouldGenerate = response.lowercased().contains("yes")
            print("[InsightTrigger] AI decision: \(shouldGenerate ? "generate" : "skip")")
            return shouldGenerate

        } catch {
            // On error, fall back to threshold-based
            print("[InsightTrigger] AI decision failed, using threshold: \(error)")
            return shouldTriggerGeneration()
        }
    }

    // MARK: - Generation

    /// Trigger insight generation if conditions are met.
    ///
    /// Call from MainActor context (e.g., AutoSyncManager).
    ///
    /// - Parameter useAI: If true, uses LLM to decide. If false, uses thresholds only.
    /// - Parameter modelContext: SwiftData context for insight storage
    /// - Returns: Number of insights generated (0 if skipped)
    @MainActor
    func triggerIfNeeded(useAI: Bool = false, modelContext: ModelContext) async -> Int {
        // Check if we should generate (runs on actor, returns to MainActor)
        let shouldGenerate: Bool
        if useAI {
            shouldGenerate = await shouldTriggerGenerationAI()
        } else {
            shouldGenerate = await checkShouldTrigger()
        }

        guard shouldGenerate else {
            print("[InsightTrigger] Generation not needed")
            return 0
        }

        // Generate insights (runs on MainActor)
        do {
            let insights = try await localInsightEngine.generateAndSaveInsights(
                days: 7,
                modelContext: modelContext
            )

            // Reset delta on successful generation
            await markGenerationComplete()

            print("[InsightTrigger] Generated \(insights.count) insights")
            return insights.count

        } catch {
            print("[InsightTrigger] Generation failed: \(error)")
            return 0
        }
    }

    /// Force insight generation regardless of thresholds.
    @MainActor
    func forceGeneration(modelContext: ModelContext) async -> Int {
        do {
            let insights = try await localInsightEngine.generateAndSaveInsights(
                days: 7,
                modelContext: modelContext
            )
            await markGenerationComplete()
            return insights.count
        } catch {
            print("[InsightTrigger] Forced generation failed: \(error)")
            return 0
        }
    }

    /// Check if generation should trigger (actor-isolated helper)
    private func checkShouldTrigger() -> Bool {
        return shouldTriggerGeneration()
    }

    /// Mark generation as complete and reset delta
    private func markGenerationComplete() {
        delta = DataDelta(lastInsightGeneration: Date())
        saveDelta()
    }

    // MARK: - Delta Persistence

    private func resetDelta() {
        delta = DataDelta(lastInsightGeneration: Date())
        saveDelta()
    }

    private func saveDelta() {
        guard let data = try? JSONEncoder().encode(delta) else { return }
        UserDefaults.standard.set(data, forKey: deltaKey)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when new insights are generated
    static let insightsGenerated = Notification.Name("insightsGenerated")
}
