import Foundation
import SwiftData

/// Smart context caching manager for Gemini direct calls.
///
/// Handles fetching and caching context from the server with intelligent
/// refresh logic based on message intent and time-based staleness.
///
/// In Gemini mode, can build context entirely from local sources (SwiftData, HealthKit).
/// Privacy settings for Gemini data sharing (read from UserDefaults)
struct GeminiPrivacySettings {
    let shareNutrition: Bool
    let shareWorkouts: Bool
    let shareHealth: Bool
    let shareProfile: Bool
    let paranoidMode: Bool

    static var current: GeminiPrivacySettings {
        let defaults = UserDefaults.standard
        return GeminiPrivacySettings(
            shareNutrition: defaults.bool(forKey: "geminiShareNutrition"),
            shareWorkouts: defaults.bool(forKey: "geminiShareWorkouts"),
            shareHealth: defaults.bool(forKey: "geminiShareHealth"),
            shareProfile: defaults.bool(forKey: "geminiShareProfile"),
            paranoidMode: defaults.bool(forKey: "geminiParanoidMode")
        )
    }

    /// Initialize defaults if not set (nutrition and workouts ON, others OFF)
    static func initializeDefaults() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "geminiShareNutrition") == nil {
            defaults.set(true, forKey: "geminiShareNutrition")
        }
        if defaults.object(forKey: "geminiShareWorkouts") == nil {
            defaults.set(true, forKey: "geminiShareWorkouts")
        }
        // Health, profile, paranoid default to false (no action needed)
    }
}

actor ContextManager {
    static let shared = ContextManager()

    // MARK: - Cached State

    private var cachedContext: ChatContext?
    private var lastRefresh: Date?
    private let apiClient = APIClient()
    private let healthKit = HealthKitManager()
    private let memorySyncService = MemorySyncService()
    private let hevyCacheManager = HevyCacheManager()

    // MARK: - Staleness Thresholds (seconds)

    private let defaultStaleness: TimeInterval = 1800      // 30 min for general chat
    private let workoutStaleness: TimeInterval = 300       // 5 min for workout discussion
    private let nutritionStaleness: TimeInterval = 600     // 10 min for nutrition discussion
    private let dataStaleness: TimeInterval = 60           // 1 min for "how am I doing" questions

    // MARK: - Context Age

    private var contextAge: TimeInterval {
        guard let lastRefresh = lastRefresh else { return .infinity }
        return Date().timeIntervalSince(lastRefresh)
    }

    // MARK: - Public API

    /// Get context, refreshing if stale or intent suggests fresh data is needed.
    ///
    /// - Parameter messageIntent: Optional hint about what the user is asking about
    /// - Returns: Cached or fresh ChatContext
    func getContext(for messageIntent: MessageIntent? = nil) async -> ChatContext {
        let needsRefresh = cachedContext == nil
            || contextAge > defaultStaleness
            || shouldRefreshForIntent(messageIntent)

        if needsRefresh {
            await refreshContext()
        }

        return cachedContext ?? ChatContext.empty
    }

    /// Force a context refresh regardless of staleness.
    func forceRefresh() async {
        await refreshContext()
    }

    /// Clear cached context (e.g., on logout or profile change).
    func clearCache() {
        cachedContext = nil
        lastRefresh = nil
    }

    /// Check if we have any cached context.
    var hasCachedContext: Bool {
        cachedContext != nil
    }

    // MARK: - Local Context Building (for Gemini mode)

    /// Build context entirely from local sources (SwiftData, HealthKit).
    ///
    /// Used in Gemini mode where AI calls don't need the server.
    /// Gathers profile, memory, health data, nutrition, and cached workout data.
    /// Respects privacy settings - only includes data categories the user has enabled.
    ///
    /// - Parameter modelContext: SwiftData context for local queries
    /// - Returns: Complete ChatContext built from local data (filtered by privacy settings)
    @MainActor
    func buildLocalContext(modelContext: ModelContext) async -> ChatContext {
        let privacy = GeminiPrivacySettings.current

        // 1. Get local profile and memories (only if profile sharing enabled)
        let localContext: ChatContext
        if privacy.shareProfile {
            localContext = await memorySyncService.buildFullContext(modelContext: modelContext)
        } else {
            // Use generic coach persona without personal memories
            localContext = ChatContext(
                systemPrompt: ChatContext.universalCoachingPhilosophy,
                memoryContext: "",
                dataContext: "",
                profileSummary: "",
                onboardingComplete: true
            )
        }

        // 2. Get today's health data from HealthKit (only if health sharing enabled)
        let healthDataString: String
        let trainingDayString: String
        if privacy.shareHealth {
            let healthContext = await healthKit.getTodayContext()
            healthDataString = formatHealthContext(healthContext)

            // Training day status is derived from health data
            let (isTrainingDay, workoutName) = await healthKit.isTrainingDay()
            trainingDayString = formatTrainingDayStatus(isTrainingDay: isTrainingDay, workoutName: workoutName)
        } else {
            healthDataString = ""
            trainingDayString = ""
        }

        // 3. Get nutrition from SwiftData (only if nutrition sharing enabled)
        let nutritionString: String
        let weeklyNutritionString: String
        if privacy.shareNutrition {
            nutritionString = getNutritionContext(modelContext: modelContext)
            weeklyNutritionString = getWeeklyNutritionContext(modelContext: modelContext)
        } else {
            nutritionString = ""
            weeklyNutritionString = ""
        }

        // 4. Get cached Hevy data (only if workout sharing enabled)
        let workoutString: String
        if privacy.shareWorkouts {
            workoutString = await hevyCacheManager.buildWorkoutContext(modelContext: modelContext)
        } else {
            workoutString = ""
        }

        // 5. Combine data context (only enabled categories)
        var dataContextParts: [String] = []

        // Day status first (training vs rest) - requires health sharing
        if !trainingDayString.isEmpty {
            dataContextParts.append(trainingDayString)
        }

        if !healthDataString.isEmpty {
            dataContextParts.append("--- TODAY'S HEALTH ---\n\(healthDataString)")
        }
        if !nutritionString.isEmpty {
            dataContextParts.append("--- TODAY'S NUTRITION ---\n\(nutritionString)")
        }
        if !weeklyNutritionString.isEmpty {
            dataContextParts.append("--- WEEKLY NUTRITION TRENDS ---\n\(weeklyNutritionString)")
        }
        if !workoutString.isEmpty {
            dataContextParts.append(workoutString)
        }

        let combinedDataContext = dataContextParts.joined(separator: "\n\n")

        // 6. Build final context
        return ChatContext(
            systemPrompt: localContext.systemPrompt,
            memoryContext: privacy.shareProfile ? localContext.memoryContext : "",
            dataContext: combinedDataContext,
            profileSummary: privacy.shareProfile ? localContext.profileSummary : "",
            onboardingComplete: localContext.onboardingComplete
        )
    }

    /// Build context for Gemini that excludes disabled categories.
    /// Returns a summary of what was excluded for hybrid routing decisions.
    @MainActor
    func buildPrivacyAwareContext(modelContext: ModelContext) async -> (context: ChatContext, excludedCategories: Set<String>) {
        let privacy = GeminiPrivacySettings.current
        var excluded: Set<String> = []

        if !privacy.shareNutrition { excluded.insert("nutrition") }
        if !privacy.shareWorkouts { excluded.insert("workouts") }
        if !privacy.shareHealth { excluded.insert("health") }
        if !privacy.shareProfile { excluded.insert("profile") }

        let context = await buildLocalContext(modelContext: modelContext)
        return (context, excluded)
    }

    /// Format training day status for context.
    nonisolated private func formatTrainingDayStatus(isTrainingDay: Bool, workoutName: String?) -> String {
        if isTrainingDay {
            if let workout = workoutName {
                return "--- DAY STATUS ---\nTraining Day (\(workout))\nTargets: Higher calories, focus on recovery nutrition"
            } else {
                return "--- DAY STATUS ---\nTraining Day\nTargets: Higher calories, focus on recovery nutrition"
            }
        } else {
            return "--- DAY STATUS ---\nRest Day\nTargets: Lower calories, maintenance nutrition"
        }
    }

    /// Format HealthKit context for chat injection.
    nonisolated private func formatHealthContext(_ context: HealthContext) -> String {
        var parts: [String] = []

        parts.append("Steps: \(context.steps)")
        parts.append("Active calories: \(context.activeCalories)")

        if let weight = context.weightLbs {
            parts.append("Weight: \(String(format: "%.1f", weight)) lbs")
        }
        if let hr = context.restingHeartRate {
            parts.append("Resting HR: \(hr) bpm")
        }
        if let sleep = context.sleepHours {
            parts.append("Sleep last night: \(String(format: "%.1f", sleep)) hrs")
        }

        return parts.joined(separator: "\n")
    }

    /// Get today's nutrition from SwiftData.
    @MainActor
    private func getNutritionContext(modelContext: ModelContext) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let descriptor = FetchDescriptor<NutritionEntry>(
            predicate: #Predicate<NutritionEntry> { entry in
                entry.timestamp >= startOfDay && entry.timestamp < endOfDay
            },
            sortBy: [SortDescriptor(\NutritionEntry.timestamp)]
        )

        guard let entries = try? modelContext.fetch(descriptor), !entries.isEmpty else {
            return ""
        }

        // Calculate totals
        let totalCalories = entries.reduce(0) { $0 + $1.calories }
        let totalProtein = entries.reduce(0) { $0 + $1.protein }
        let totalCarbs = entries.reduce(0) { $0 + $1.carbs }
        let totalFat = entries.reduce(0) { $0 + $1.fat }

        var parts: [String] = []
        parts.append("Logged today (\(entries.count) entries):")
        parts.append("  Calories: \(totalCalories)")
        parts.append("  Protein: \(totalProtein)g")
        parts.append("  Carbs: \(totalCarbs)g")
        parts.append("  Fat: \(totalFat)g")

        // List recent entries
        let recentEntries = entries.suffix(5)
        if !recentEntries.isEmpty {
            parts.append("\nRecent foods:")
            for entry in recentEntries {
                parts.append("  • \(entry.name) (\(entry.calories) cal, \(entry.protein)g protein)")
            }
        }

        return parts.joined(separator: "\n")
    }

    /// Get weekly nutrition trends from SwiftData.
    @MainActor
    private func getWeeklyNutritionContext(modelContext: ModelContext) -> String {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            return ""
        }

        let descriptor = FetchDescriptor<NutritionEntry>(
            predicate: #Predicate<NutritionEntry> { entry in
                entry.timestamp >= startDate && entry.timestamp < endDate
            }
        )

        guard let entries = try? modelContext.fetch(descriptor), !entries.isEmpty else {
            return ""
        }

        // Group by day
        let groupedByDay = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }

        let daysTracked = groupedByDay.count
        guard daysTracked > 0 else { return "" }

        // Calculate daily averages
        var totalCalories = 0
        var totalProtein = 0
        var totalCarbs = 0
        var totalFat = 0

        for (_, dayEntries) in groupedByDay {
            totalCalories += dayEntries.reduce(0) { $0 + $1.calories }
            totalProtein += dayEntries.reduce(0) { $0 + $1.protein }
            totalCarbs += dayEntries.reduce(0) { $0 + $1.carbs }
            totalFat += dayEntries.reduce(0) { $0 + $1.fat }
        }

        let avgCalories = totalCalories / daysTracked
        let avgProtein = totalProtein / daysTracked
        let avgCarbs = totalCarbs / daysTracked
        let avgFat = totalFat / daysTracked

        var parts: [String] = []
        parts.append("7-day averages (\(daysTracked) days tracked):")
        parts.append("  Calories: \(avgCalories)/day")
        parts.append("  Protein: \(avgProtein)g/day")
        parts.append("  Carbs: \(avgCarbs)g/day")
        parts.append("  Fat: \(avgFat)g/day")

        return parts.joined(separator: "\n")
    }

    // MARK: - Intent Detection

    /// Detect the intent of a message for smart refresh decisions.
    ///
    /// - Parameter message: The user's message
    /// - Returns: Detected intent, or .generalChat if no specific intent found
    static func detectIntent(from message: String) -> MessageIntent {
        let lowercased = message.lowercased()

        // Data/progress questions - always want fresh data
        let dataKeywords = ["how am i doing", "progress", "stats", "numbers", "trending", "weight", "body fat", "how's my"]
        if dataKeywords.contains(where: { lowercased.contains($0) }) {
            return .dataQuestion
        }

        // Workout discussion
        let workoutKeywords = ["workout", "training", "gym", "sets", "reps", "lift", "exercise", "bench", "squat", "deadlift", "volume", "hevy"]
        if workoutKeywords.contains(where: { lowercased.contains($0) }) {
            return .workoutDiscussion
        }

        // Nutrition discussion
        let nutritionKeywords = ["food", "meal", "eat", "calories", "protein", "carbs", "fat", "macro", "diet", "nutrition", "hungry"]
        if nutritionKeywords.contains(where: { lowercased.contains($0) }) {
            return .nutritionDiscussion
        }

        return .generalChat
    }

    // MARK: - Private Helpers

    private func shouldRefreshForIntent(_ intent: MessageIntent?) -> Bool {
        guard let intent = intent else { return false }

        let threshold: TimeInterval
        switch intent {
        case .workoutDiscussion:
            threshold = workoutStaleness
        case .nutritionDiscussion:
            threshold = nutritionStaleness
        case .dataQuestion:
            threshold = dataStaleness
        case .generalChat:
            threshold = defaultStaleness
        }

        return contextAge > threshold
    }

    private func refreshContext() async {
        do {
            let response = try await apiClient.getChatContext()
            cachedContext = response
            lastRefresh = Date()
        } catch {
            // On error, keep stale cache rather than failing
            print("Context refresh failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Message Intent

/// Detected intent of a user message, used for smart context refresh.
enum MessageIntent {
    /// Discussing workouts, training, gym, etc.
    case workoutDiscussion

    /// Discussing food, calories, macros, etc.
    case nutritionDiscussion

    /// Asking about progress, stats, "how am I doing"
    case dataQuestion

    /// General conversation
    case generalChat
}

// MARK: - Chat Context (Response from Server)

/// Context bundle received from the server.
struct ChatContext: Codable {
    let systemPrompt: String
    let memoryContext: String
    let dataContext: String
    let profileSummary: String
    let onboardingComplete: Bool

    enum CodingKeys: String, CodingKey {
        case systemPrompt = "system_prompt"
        case memoryContext = "memory_context"
        case dataContext = "data_context"
        case profileSummary = "profile_summary"
        case onboardingComplete = "onboarding_complete"
    }

    /// Universal coaching philosophy - applies regardless of personality
    ///
    /// This is the "warmth layer" that ALL users get. User-specific personality
    /// (bro energy, supportive, analytical) layers on TOP of this foundation.
    ///
    /// Research insight: Warmth is what makes roasting feel like friendship,
    /// directness feel caring, and humor land naturally.
    static let universalCoachingPhilosophy = """
    You are the user's AI fitness coach - genuinely invested in them as a person.

    --- WARMTH PRINCIPLES (UNIVERSAL) ---
    These apply regardless of user's personality preferences:

    CONVERSATIONAL RESTRAINT:
    • Skip flattery - never open with "Great question!" or "That's fascinating!" Just respond.
    • Don't preach - when correcting or declining, keep it brief with alternatives
    • One question at a time - don't overwhelm with multiple questions per response
    • Match depth to depth - casual check-in ≠ metrics analysis

    EMOTIONAL INTELLIGENCE:
    • Be genuinely curious - people can tell when you're collecting data vs. actually engaged
    • Provide support alongside information when relevant - facts + empathy, not just facts
    • Read the room - technical detail when problem-solving, brevity when chatting
    • If uncertain, say so plainly - intellectual humility builds trust

    WHAT MAKES YOU REAL:
    • You're not just helpful - you're someone they want to talk to
    • Humor is welcome but never forced - let it emerge naturally from conversation
    • You have perspective and can respectfully disagree when their logic is flawed
    • You remember what matters to them as a person, not just as data points

    --- DATA PHILOSOPHY ---
    • You have rich context about their health, workouts, and nutrition
    • This is your AWARENESS, not your AGENDA - real friends don't recite your numbers
    • "How's it going?" → respond as friend who's paying attention (data-light)
    • "Why am I so tired?" → NOW the HRV/sleep/training data matters
    • Cite specifics when they support your point, not to show you have them
    • Look for patterns, not just numbers

    --- COACHING PRINCIPLES ---
    • Your personality and communication style are calibrated to THEM
    • Some users want a bro who roasts them, others want gentle encouragement
    • No unsolicited meal/workout recommendations
    • Keep progression coherent across sessions
    • Respond appropriately - celebrate wins, support struggles
    • Be direct but calibrate intensity to their preferences

    --- HUMOR CALIBRATION ---
    Base layer (always):
    • Affiliative humor works - humor that builds connection, not at their expense
    • Timing > cleverness - a well-timed quip beats a forced joke
    • Context is king - if they're struggling, support first, lighten later
    • Natural > performative - let humor emerge from conversation, don't inject it

    (User-specific humor preferences come from their calibration choices)

    --- MEMORY MARKERS ---
    Use sparingly (1-3 per conversation max) when you learn something worth remembering:
    - <memory:remember>General things to remember about them</memory:remember>
    - <memory:callback>Inside jokes, phrases that landed well</memory:callback>
    - <memory:tone>Communication style observations</memory:tone>
    - <memory:thread>Topics to follow up on next time</memory:thread>

    These markers are stripped from the displayed response but used to evolve the relationship.
    Only use when something is genuinely meaningful - not every conversation needs markers.
    """

    /// Empty context for when server is unavailable (uses universal coaching philosophy)
    static let empty = ChatContext(
        systemPrompt: universalCoachingPhilosophy,
        memoryContext: "",
        dataContext: "",
        profileSummary: "",
        onboardingComplete: false
    )
}
