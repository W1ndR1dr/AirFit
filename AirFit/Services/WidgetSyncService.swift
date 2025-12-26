import Foundation
import WidgetKit

/// Service that syncs app data to widgets via App Groups.
/// Pushes nutrition, readiness, insights, and other data to shared UserDefaults.
actor WidgetSyncService {
    static let shared = WidgetSyncService()

    private let suiteName = "group.com.airfit.shared"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Nutrition Sync

    func syncNutrition(
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        targetCalories: Int,
        targetProtein: Int,
        targetCarbs: Int,
        targetFat: Int,
        isTrainingDay: Bool
    ) {
        let data = WidgetNutritionData(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            targetCalories: targetCalories,
            targetProtein: targetProtein,
            targetCarbs: targetCarbs,
            targetFat: targetFat,
            isTrainingDay: isTrainingDay,
            lastUpdated: Date()
        )
        encode(data, key: "widget.nutritionData")
        reloadTimelines(kinds: ["ProteinCounter", "EnergyBalance", "MorningBrief", "WeeklyRhythm"])
    }

    // MARK: - Readiness Sync

    func syncReadiness(
        category: String,
        positiveCount: Int,
        totalCount: Int,
        sleepHours: Double?,
        hrvDeviation: Double?,
        isBaselineReady: Bool,
        baselineProgress: Int?
    ) {
        let data = WidgetReadinessData(
            category: category,
            positiveCount: positiveCount,
            totalCount: totalCount,
            sleepHours: sleepHours,
            hrvDeviation: hrvDeviation,
            isBaselineReady: isBaselineReady,
            baselineProgress: baselineProgress,
            lastUpdated: Date()
        )
        encode(data, key: "widget.readinessData")
        reloadTimelines(kinds: ["MorningReadiness", "MorningBrief"])
    }

    // MARK: - Insights Sync

    func syncInsights(_ insights: [WidgetInsight]) {
        encode(insights, key: "widget.insights")
        reloadTimelines(kinds: ["InsightTicker", "MorningBrief"])
    }

    func syncInsights(from apiInsights: [APIClient.InsightData]) {
        let widgetInsights = apiInsights.map { insight in
            WidgetInsight(
                id: insight.id,
                category: insight.category,
                title: insight.title,
                body: insight.body,
                sparklineValues: nil,  // Could extract from supporting_data if available
                createdAt: ISO8601DateFormatter().date(from: insight.createdAt) ?? Date()
            )
        }
        syncInsights(widgetInsights)
    }

    // MARK: - Energy Sync

    func syncEnergy(
        currentTDEE: Int,
        projectedTDEE: Int,
        projectedNet: Int,
        confidence: Double,
        isTrainingDay: Bool,
        caloriesConsumed: Int
    ) {
        let data = WidgetEnergyData(
            currentTDEE: currentTDEE,
            projectedTDEE: projectedTDEE,
            projectedNet: projectedNet,
            confidence: confidence,
            isTrainingDay: isTrainingDay,
            caloriesConsumed: caloriesConsumed,
            lastUpdated: Date()
        )
        encode(data, key: "widget.energyData")
        reloadTimelines(kinds: ["EnergyBalance", "MorningBrief"])
    }

    // MARK: - Strength Sync

    func syncStrength(
        muscleGroups: [WidgetStrengthData.MuscleGroupProgress],
        recentPR: WidgetStrengthData.PRInfo?,
        lastWorkout: WidgetStrengthData.WorkoutInfo?
    ) {
        let data = WidgetStrengthData(
            muscleGroups: muscleGroups,
            recentPR: recentPR,
            lastWorkout: lastWorkout,
            lastUpdated: Date()
        )
        encode(data, key: "widget.strengthData")
        reloadTimelines(kinds: ["StrengthTracker", "WeeklyRhythm"])
    }

    // MARK: - Weekly Data Sync

    func syncWeeklyData(_ days: [WidgetWeeklyData.DayData]) {
        let data = WidgetWeeklyData(days: days, lastUpdated: Date())
        encode(data, key: "widget.weeklyData")
        reloadTimelines(kinds: ["WeeklyRhythm"])
    }

    // MARK: - Coach Nudge Sync

    func syncCoachNudge(_ message: String, context: String? = nil) {
        let nudge = WidgetCoachNudge(
            message: message,
            context: context,
            generatedAt: Date()
        )
        encode(nudge, key: "widget.coachNudge")
        reloadTimelines(kinds: ["ContextualAction", "MorningBrief"])
    }

    // MARK: - Context Sync

    func syncContext(_ context: WidgetContext) {
        encode(context, key: "widget.context")
        reloadTimelines(kinds: ["MorningBrief", "ContextualAction"])
    }

    func updateContextBasedOnTime(isTrainingDay: Bool, hasWorkoutToday: Bool) {
        let context = WidgetContext.current(isTrainingDay: isTrainingDay, hasWorkoutToday: hasWorkoutToday)
        syncContext(context)
    }

    // MARK: - Batch Sync (Comprehensive update)

    func syncAll(
        nutrition: (calories: Int, protein: Int, carbs: Int, fat: Int, targetCalories: Int, targetProtein: Int, targetCarbs: Int, targetFat: Int, isTrainingDay: Bool),
        energy: (currentTDEE: Int, projectedTDEE: Int, projectedNet: Int, confidence: Double)
    ) {
        // Nutrition
        syncNutrition(
            calories: nutrition.calories,
            protein: nutrition.protein,
            carbs: nutrition.carbs,
            fat: nutrition.fat,
            targetCalories: nutrition.targetCalories,
            targetProtein: nutrition.targetProtein,
            targetCarbs: nutrition.targetCarbs,
            targetFat: nutrition.targetFat,
            isTrainingDay: nutrition.isTrainingDay
        )

        // Energy
        syncEnergy(
            currentTDEE: energy.currentTDEE,
            projectedTDEE: energy.projectedTDEE,
            projectedNet: energy.projectedNet,
            confidence: energy.confidence,
            isTrainingDay: nutrition.isTrainingDay,
            caloriesConsumed: nutrition.calories
        )

        // Context
        updateContextBasedOnTime(isTrainingDay: nutrition.isTrainingDay, hasWorkoutToday: false)
    }

    // MARK: - Force Refresh All

    func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Private Helpers

    private func encode<T: Encodable>(_ value: T?, key: String) {
        guard let value else {
            defaults?.removeObject(forKey: key)
            return
        }
        if let data = try? JSONEncoder().encode(value) {
            defaults?.set(data, forKey: key)
        }
    }

    private func reloadTimelines(kinds: [String]) {
        for kind in kinds {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
    }
}

// MARK: - Widget Data Models (Shared with Widget Extension)
// These are duplicated here for the main app to use. In a production app,
// you'd put these in a shared framework.

struct WidgetNutritionData: Codable, Sendable {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let targetCalories: Int
    let targetProtein: Int
    let targetCarbs: Int
    let targetFat: Int
    let isTrainingDay: Bool
    let lastUpdated: Date
}

struct WidgetReadinessData: Codable, Sendable {
    let category: String
    let positiveCount: Int
    let totalCount: Int
    let sleepHours: Double?
    let hrvDeviation: Double?
    let isBaselineReady: Bool
    let baselineProgress: Int?
    let lastUpdated: Date
}

struct WidgetInsight: Codable, Sendable, Identifiable {
    let id: String
    let category: String
    let title: String
    let body: String
    let sparklineValues: [Double]?
    let createdAt: Date
}

struct WidgetEnergyData: Codable, Sendable {
    let currentTDEE: Int
    let projectedTDEE: Int
    let projectedNet: Int
    let confidence: Double
    let isTrainingDay: Bool
    let caloriesConsumed: Int
    let lastUpdated: Date
}

struct WidgetStrengthData: Codable, Sendable {
    let muscleGroups: [MuscleGroupProgress]
    let recentPR: PRInfo?
    let lastWorkout: WorkoutInfo?
    let lastUpdated: Date

    struct MuscleGroupProgress: Codable, Sendable {
        let name: String
        let currentSets: Int
        let targetSets: Int
        let status: String
    }

    struct PRInfo: Codable, Sendable {
        let exerciseName: String
        let weight: Double
        let unit: String
        let date: Date
    }

    struct WorkoutInfo: Codable, Sendable {
        let name: String
        let duration: Int
        let volume: Double
        let date: Date
    }
}

struct WidgetWeeklyData: Codable, Sendable {
    let days: [DayData]
    let lastUpdated: Date

    struct DayData: Codable, Sendable {
        let date: Date
        let hasWorkout: Bool
        let workoutName: String?
        let nutritionCompliance: Double?
        let sleepQuality: Double?
    }
}

struct WidgetCoachNudge: Codable, Sendable {
    let message: String
    let context: String?
    let generatedAt: Date
}

enum WidgetContext: String, Codable, Sendable {
    case morning
    case preWorkout
    case postWorkout
    case afternoon
    case evening
    case night

    static func current(isTrainingDay: Bool, hasWorkoutToday: Bool) -> WidgetContext {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<10:
            return .morning
        case 10..<12:
            if isTrainingDay && !hasWorkoutToday {
                return .preWorkout
            }
            return .morning
        case 12..<17:
            if hasWorkoutToday {
                return .postWorkout
            }
            return .afternoon
        case 17..<22:
            return .evening
        default:
            return .night
        }
    }
}
