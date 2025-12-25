import Foundation
import SwiftData

/// Local execution of AI function calls (Tier 3 tools).
///
/// Enables Gemini mode to work completely offline by executing
/// tool calls locally instead of routing to the server.
///
/// ## Architecture
/// ```
/// Gemini API → function call → LocalToolExecutor → SwiftData/HealthKit/Hevy cache
/// ```
///
/// ## Supported Tools
/// - `query_workouts`: Workout history from Hevy cache
/// - `query_nutrition`: Nutrition trends from SwiftData
/// - `query_body_comp`: Weight/BF trends from HealthKit
/// - `query_recovery`: Sleep/HRV from HealthKit
/// - `query_insights`: AI-generated insights (Phase 2)
///
/// ## Offline-First Design
/// Returns partial data with "(N/A)" indicators rather than failing.
/// This ensures the AI always gets a response it can reason about.
@MainActor
final class LocalToolExecutor {
    static let shared = LocalToolExecutor()

    private let hevyCacheManager = HevyCacheManager()
    private let healthKitManager = HealthKitManager()

    private init() {}

    // MARK: - Tool Execution

    /// Execute a tool by name with given arguments.
    ///
    /// - Parameters:
    ///   - name: Tool name (e.g., "query_workouts")
    ///   - arguments: Dictionary of tool arguments
    ///   - modelContext: SwiftData context for queries
    /// - Returns: Formatted string result for AI consumption
    func execute(
        name: String,
        arguments: [String: Any],
        modelContext: ModelContext
    ) async -> String {
        switch name {
        case "query_workouts":
            return await queryWorkouts(arguments: arguments, modelContext: modelContext)
        case "query_nutrition":
            return await queryNutrition(arguments: arguments, modelContext: modelContext)
        case "query_body_comp":
            return await queryBodyComp(arguments: arguments)
        case "query_recovery":
            return await queryRecovery(arguments: arguments)
        case "query_insights":
            return await queryInsights(arguments: arguments, modelContext: modelContext)
        default:
            return "Unknown tool: \(name)"
        }
    }

    // MARK: - Query Workouts

    /// Query workout history from local Hevy cache.
    ///
    /// Matches server's `query_workouts()` in tools.py.
    private func queryWorkouts(
        arguments: [String: Any],
        modelContext: ModelContext
    ) async -> String {
        let exercise = arguments["exercise"] as? String
        let muscleGroup = arguments["muscle_group"] as? String
        let days = min(max(arguments["days"] as? Int ?? 14, 1), 90)

        // Get cached workouts
        let workouts = hevyCacheManager.getRecentWorkouts(modelContext: modelContext, limit: 20)

        guard !workouts.isEmpty else {
            return "No workouts found in the local cache. Try refreshing Hevy data."
        }

        // Filter by date range
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let filteredWorkouts = workouts.filter { $0.workoutDate >= cutoff }

        // Filter by exercise if specified
        if let exercise = exercise?.lowercased() {
            var matchingResults: [[String: Any]] = []

            for workout in filteredWorkouts {
                // Check full exercises if available
                let matchingExercises: [String]
                if !workout.fullExercises.isEmpty {
                    matchingExercises = workout.fullExercises
                        .filter { $0.name.lowercased().contains(exercise) }
                        .map { $0.name }
                } else {
                    matchingExercises = workout.exercises
                        .filter { $0.lowercased().contains(exercise) }
                }

                if !matchingExercises.isEmpty {
                    matchingResults.append([
                        "date": formatDate(workout.workoutDate),
                        "title": workout.title,
                        "exercises": matchingExercises
                    ])
                }
            }

            if matchingResults.isEmpty {
                return "No workouts with '\(exercise)' in the last \(days) days"
            }

            return formatResult([
                "workouts": matchingResults,
                "count": matchingResults.count
            ])
        }

        // Filter by muscle group if specified
        if let muscleGroup = muscleGroup?.lowercased() {
            let setTracker = hevyCacheManager.getSetTracker(modelContext: modelContext)
            if let match = setTracker.first(where: { $0.muscleGroup.lowercased() == muscleGroup }) {
                return formatResult([
                    "muscle_group": muscleGroup,
                    "sets": match.currentSets,
                    "target_range": "\(match.optimalMin)-\(match.optimalMax)",
                    "status": match.status,
                    "period": "\(days) days"
                ])
            }
        }

        // General workout summary
        var summaries: [[String: Any]] = []
        for workout in filteredWorkouts.prefix(10) {
            var summary: [String: Any] = [
                "date": formatDate(workout.workoutDate),
                "title": workout.title,
                "duration": "\(workout.durationMinutes)min",
                "volume": "\(Int(workout.totalVolumeLbs))lbs"
            ]

            if !workout.fullExercises.isEmpty {
                summary["exercises"] = workout.fullExercises.prefix(5).map { $0.name }
            } else {
                summary["exercises"] = Array(workout.exercises.prefix(5))
            }

            summaries.append(summary)
        }

        // Add lift progress (PRs)
        let lifts = hevyCacheManager.getLiftProgress(modelContext: modelContext, topN: 5)
        var prInfo: [[String: Any]] = []
        for lift in lifts {
            prInfo.append([
                "exercise": lift.exerciseName,
                "pr_weight": "\(Int(lift.currentPRWeightLbs))lbs",
                "pr_reps": lift.currentPRReps,
                "sessions": lift.workoutCount
            ])
        }

        return formatResult([
            "workouts": summaries,
            "total_count": filteredWorkouts.count,
            "personal_records": prInfo
        ])
    }

    // MARK: - Query Nutrition

    /// Query nutrition history from SwiftData.
    ///
    /// Matches server's `query_nutrition()` in tools.py.
    private func queryNutrition(
        arguments: [String: Any],
        modelContext: ModelContext
    ) async -> String {
        let days = min(max(arguments["days"] as? Int ?? 7, 1), 30)
        let includeMeals = arguments["include_meals"] as? Bool ?? false

        // Query nutrition entries
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<NutritionEntry>(
            predicate: #Predicate { $0.timestamp >= cutoff },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let entries = try? modelContext.fetch(descriptor), !entries.isEmpty else {
            return "No nutrition data tracked in the last \(days) days"
        }

        // Group by date
        var dailyData: [String: (calories: Int, protein: Int, carbs: Int, fat: Int, count: Int)] = [:]

        for entry in entries {
            let dateKey = formatDate(entry.timestamp)
            let existing = dailyData[dateKey] ?? (0, 0, 0, 0, 0)
            dailyData[dateKey] = (
                existing.calories + entry.calories,
                existing.protein + entry.protein,
                existing.carbs + entry.carbs,
                existing.fat + entry.fat,
                existing.count + 1
            )
        }

        let trackedDays = dailyData.count
        guard trackedDays > 0 else {
            return "No nutrition data found"
        }

        // Calculate averages
        let totals = dailyData.values.reduce((0, 0, 0, 0)) { acc, day in
            (acc.0 + day.calories, acc.1 + day.protein, acc.2 + day.carbs, acc.3 + day.fat)
        }

        let avgCalories = totals.0 / trackedDays
        let avgProtein = totals.1 / trackedDays
        let avgCarbs = totals.2 / trackedDays
        let avgFat = totals.3 / trackedDays

        // Get targets from profile
        let profile = LocalProfile.current(in: modelContext)
        let targetProtein = profile?.proteinTarget ?? 175
        let targetCalories = profile?.calorieTargetTraining ?? 2400

        var result: [String: Any] = [
            "period": "\(days) days",
            "tracked_days": trackedDays,
            "averages": [
                "calories": avgCalories,
                "protein": avgProtein,
                "carbs": avgCarbs,
                "fat": avgFat
            ],
            "targets": [
                "calories": targetCalories,
                "protein": targetProtein
            ],
            "protein_compliance": "\(Int(Double(avgProtein) / Double(targetProtein) * 100))%"
        ]

        if includeMeals {
            result["daily_data"] = dailyData.map { date, data in
                [
                    "date": date,
                    "calories": data.calories,
                    "protein": data.protein,
                    "carbs": data.carbs,
                    "fat": data.fat
                ]
            }.sorted { ($0["date"] as? String ?? "") > ($1["date"] as? String ?? "") }
        }

        return formatResult(result)
    }

    // MARK: - Query Body Comp

    /// Query body composition trends from HealthKit.
    ///
    /// Matches server's `query_body_comp()` in tools.py.
    private func queryBodyComp(arguments: [String: Any]) async -> String {
        let days = min(max(arguments["days"] as? Int ?? 90, 30), 365)

        // Fetch weight and body fat history
        async let weightHistory = healthKitManager.getWeightHistory(days: days)
        async let bodyFatHistory = healthKitManager.getBodyFatHistory(days: days)

        let (weights, bodyFats) = await (weightHistory, bodyFatHistory)

        var result: [String: Any] = ["period": "\(days) days"]

        if !weights.isEmpty {
            let firstWeight = weights.first!.weightLbs
            let lastWeight = weights.last!.weightLbs
            result["weight"] = [
                "current": round(lastWeight * 10) / 10,
                "start": round(firstWeight * 10) / 10,
                "change": round((lastWeight - firstWeight) * 10) / 10,
                "readings": weights.count
            ]
        }

        if !bodyFats.isEmpty {
            let firstBF = bodyFats.first!.bodyFatPct
            let lastBF = bodyFats.last!.bodyFatPct
            result["body_fat"] = [
                "current": round(lastBF * 10) / 10,
                "start": round(firstBF * 10) / 10,
                "change": round((lastBF - firstBF) * 10) / 10,
                "readings": bodyFats.count
            ]
        }

        // Calculate lean mass if we have both
        if !weights.isEmpty && !bodyFats.isEmpty {
            // Find most recent weight and body fat
            if let latestWeight = weights.last?.weightLbs,
               let latestBF = bodyFats.last?.bodyFatPct {
                let leanMass = latestWeight * (1 - latestBF / 100)
                let fatMass = latestWeight * (latestBF / 100)
                result["composition"] = [
                    "lean_mass_lbs": round(leanMass * 10) / 10,
                    "fat_mass_lbs": round(fatMass * 10) / 10
                ]
            }
        }

        if result.count == 1 {
            return "No body composition data found in HealthKit"
        }

        return formatResult(result)
    }

    // MARK: - Query Recovery

    /// Query recovery metrics from HealthKit.
    ///
    /// Matches server's `query_recovery()` in tools.py.
    private func queryRecovery(arguments: [String: Any]) async -> String {
        let days = min(max(arguments["days"] as? Int ?? 14, 7), 30)

        // Get daily snapshots
        let snapshots = await healthKitManager.getRecentSnapshots(days: days)

        guard !snapshots.isEmpty else {
            return "No recovery data found in HealthKit"
        }

        var result: [String: Any] = ["period": "\(days) days"]

        // Sleep analysis
        let sleepData = snapshots.compactMap { $0.sleepHours }
        if !sleepData.isEmpty {
            let avgSleep = sleepData.reduce(0, +) / Double(sleepData.count)
            result["sleep"] = [
                "average": round(avgSleep * 10) / 10,
                "nights_tracked": sleepData.count,
                "recent": Array(sleepData.suffix(3))
            ]
        }

        // HRV analysis
        let hrvData = snapshots.compactMap { $0.hrvMs }
        if !hrvData.isEmpty {
            let avgHRV = hrvData.reduce(0, +) / Double(hrvData.count)
            // Calculate trend (simple: compare first vs last third)
            let thirdCount = max(1, hrvData.count / 3)
            let earlyAvg = hrvData.prefix(thirdCount).reduce(0, +) / Double(thirdCount)
            let lateAvg = hrvData.suffix(thirdCount).reduce(0, +) / Double(thirdCount)
            let trend = lateAvg > earlyAvg * 1.05 ? "improving" :
                       lateAvg < earlyAvg * 0.95 ? "declining" : "stable"

            result["hrv"] = [
                "average": Int(avgHRV),
                "readings": hrvData.count,
                "trend": trend
            ]
        }

        // Resting HR analysis
        let rhrData = snapshots.compactMap { $0.restingHR }
        if !rhrData.isEmpty {
            let avgRHR = rhrData.reduce(0, +) / rhrData.count
            result["resting_hr"] = [
                "average": avgRHR,
                "readings": rhrData.count
            ]
        }

        return formatResult(result)
    }

    // MARK: - Query Insights

    /// Query AI-generated insights from LocalInsight storage.
    ///
    /// Uses the LocalInsight SwiftData model to return rich insight data
    /// including supporting data for visualizations.
    private func queryInsights(
        arguments: [String: Any],
        modelContext: ModelContext
    ) async -> String {
        let category = arguments["category"] as? String
        let limit = min(max(arguments["limit"] as? Int ?? 5, 1), 10)
        let includeSupporting = arguments["include_supporting_data"] as? Bool ?? true

        // Build query for LocalInsight
        let descriptor = FetchDescriptor<LocalInsight>(
            predicate: LocalInsight.active,
            sortBy: [
                SortDescriptor(\LocalInsight.tier),  // Lower tier = higher priority
                SortDescriptor(\LocalInsight.createdAt, order: .reverse)
            ]
        )

        do {
            var insights = try modelContext.fetch(descriptor)

            // Filter by category if specified
            if let category = category {
                insights = insights.filter { $0.category == category }
            }

            // Limit results
            insights = Array(insights.prefix(limit))

            guard !insights.isEmpty else {
                let msg = category != nil
                    ? "No insights in category '\(category!)'"
                    : "No insights generated yet. Insights are generated automatically in Gemini Direct mode."
                return msg
            }

            // Format insights for AI consumption
            let formatted = insights.map { insight -> [String: Any] in
                var dict: [String: Any] = [
                    "category": insight.categoryDisplayName,
                    "tier": insight.tier,
                    "title": insight.title,
                    "body": insight.body,
                    "importance": String(format: "%.0f%%", insight.importance * 100),
                    "created": formatDate(insight.createdAt)
                ]

                // Add suggested actions if available
                if !insight.suggestedActions.isEmpty {
                    dict["suggested_actions"] = insight.suggestedActions
                }

                // Add supporting data if requested and available
                if includeSupporting, let metric = insight.metricName {
                    var supporting: [String: Any] = ["metric": metric]
                    if let current = insight.currentValue {
                        supporting["current_value"] = current
                    }
                    if let change = insight.changePct {
                        supporting["change_pct"] = "\(Int(change))%"
                    }
                    if let target = insight.targetValue {
                        supporting["target"] = target
                    }
                    if !insight.values.isEmpty {
                        supporting["trend_values"] = insight.values.suffix(5)
                    }
                    dict["supporting_data"] = supporting
                }

                return dict
            }

            // Group by category for summary
            let categoryCounts = Dictionary(grouping: insights, by: { $0.category })
                .mapValues { $0.count }

            return formatResult([
                "insights": formatted,
                "total_count": formatted.count,
                "by_category": categoryCounts
            ])

        } catch {
            print("[LocalToolExecutor] Failed to fetch insights: \(error)")
            return "Error querying insights: \(error.localizedDescription)"
        }
    }

    // MARK: - Formatting Helpers

    /// Format a date as YYYY-MM-DD
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Format a dictionary as readable output for LLM consumption.
    private func formatResult(_ dict: [String: Any]) -> String {
        var lines: [String] = []
        formatDict(dict, lines: &lines, indent: 0)
        return lines.joined(separator: "\n")
    }

    private func formatDict(_ dict: [String: Any], lines: inout [String], indent: Int) {
        let prefix = String(repeating: "  ", count: indent)

        for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
            if let subDict = value as? [String: Any] {
                lines.append("\(prefix)\(key):")
                formatDict(subDict, lines: &lines, indent: indent + 1)
            } else if let array = value as? [[String: Any]] {
                lines.append("\(prefix)\(key):")
                for item in array {
                    formatDict(item, lines: &lines, indent: indent + 1)
                    lines.append("")
                }
            } else if let array = value as? [Any] {
                let items = array.prefix(5).map { "\($0)" }.joined(separator: ", ")
                lines.append("\(prefix)\(key): \(items)")
            } else {
                lines.append("\(prefix)\(key): \(value)")
            }
        }
    }
}

