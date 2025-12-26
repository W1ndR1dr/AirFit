import Foundation
import WidgetKit

/// Shared data store for cross-process communication between iOS app and widgets.
/// Uses App Groups UserDefaults since WidgetKit extensions run in separate processes.
struct WidgetDataStore {
    static let suiteName = "group.com.airfit.shared"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Nutrition Data

    static var nutritionData: WidgetNutritionData? {
        get { decode(key: "widget.nutritionData") }
        set {
            encode(newValue, key: "widget.nutritionData")
            reloadTimelines(kinds: ["ProteinCounter", "EnergyBalance", "MorningBrief", "WeeklyRhythm"])
        }
    }

    // MARK: - Readiness Data

    static var readinessData: WidgetReadinessData? {
        get { decode(key: "widget.readinessData") }
        set {
            encode(newValue, key: "widget.readinessData")
            reloadTimelines(kinds: ["MorningReadiness", "MorningBrief"])
        }
    }

    // MARK: - Insights

    static var insights: [WidgetInsight] {
        get { decode(key: "widget.insights") ?? [] }
        set {
            encode(newValue, key: "widget.insights")
            reloadTimelines(kinds: ["InsightTicker", "MorningBrief"])
        }
    }

    // MARK: - Energy Balance

    static var energyData: WidgetEnergyData? {
        get { decode(key: "widget.energyData") }
        set {
            encode(newValue, key: "widget.energyData")
            reloadTimelines(kinds: ["EnergyBalance", "MorningBrief"])
        }
    }

    // MARK: - Strength/Volume Data

    static var strengthData: WidgetStrengthData? {
        get { decode(key: "widget.strengthData") }
        set {
            encode(newValue, key: "widget.strengthData")
            reloadTimelines(kinds: ["StrengthTracker", "WeeklyRhythm"])
        }
    }

    // MARK: - Weekly Data

    static var weeklyData: WidgetWeeklyData? {
        get { decode(key: "widget.weeklyData") }
        set {
            encode(newValue, key: "widget.weeklyData")
            reloadTimelines(kinds: ["WeeklyRhythm"])
        }
    }

    // MARK: - Coach Nudge

    static var coachNudge: WidgetCoachNudge? {
        get { decode(key: "widget.coachNudge") }
        set {
            encode(newValue, key: "widget.coachNudge")
            reloadTimelines(kinds: ["ContextualAction", "MorningBrief"])
        }
    }

    // MARK: - Context for Smart Widgets

    static var currentContext: WidgetContext {
        get { decode(key: "widget.context") ?? .morning }
        set {
            encode(newValue, key: "widget.context")
            reloadTimelines(kinds: ["MorningBrief", "ContextualAction"])
        }
    }

    // MARK: - Private Helpers

    private static func encode<T: Encodable>(_ value: T?, key: String) {
        guard let value else {
            defaults?.removeObject(forKey: key)
            return
        }
        if let data = try? JSONEncoder().encode(value) {
            defaults?.set(data, forKey: key)
        }
    }

    private static func decode<T: Decodable>(key: String) -> T? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func reloadTimelines(kinds: [String]) {
        for kind in kinds {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
    }

    /// Reload all AirFit widgets
    static func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Widget Data Models

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

    var proteinProgress: Double {
        guard targetProtein > 0 else { return 0 }
        return min(1.0, Double(protein) / Double(targetProtein))
    }

    var calorieProgress: Double {
        guard targetCalories > 0 else { return 0 }
        return min(1.0, Double(calories) / Double(targetCalories))
    }

    var proteinRemaining: Int {
        max(0, targetProtein - protein)
    }

    var caloriesRemaining: Int {
        targetCalories - calories
    }

    static let placeholder = WidgetNutritionData(
        calories: 1450,
        protein: 98,
        carbs: 180,
        fat: 45,
        targetCalories: 2600,
        targetProtein: 175,
        targetCarbs: 330,
        targetFat: 67,
        isTrainingDay: true,
        lastUpdated: Date()
    )
}

struct WidgetReadinessData: Codable, Sendable {
    let category: String  // "Great", "Good", "Moderate", "Rest"
    let positiveCount: Int
    let totalCount: Int
    let sleepHours: Double?
    let hrvDeviation: Double?  // % from baseline
    let isBaselineReady: Bool
    let baselineProgress: Int?  // Days toward 14-day baseline
    let lastUpdated: Date

    var categoryIcon: String {
        switch category {
        case "Great": return "flame.fill"
        case "Good": return "checkmark.circle.fill"
        case "Moderate": return "exclamationmark.circle.fill"
        case "Rest": return "bed.double.fill"
        default: return "questionmark.circle"
        }
    }

    var score: Double {
        guard totalCount > 0 else { return 0.5 }
        return Double(positiveCount) / Double(totalCount)
    }

    var summaryText: String {
        if !isBaselineReady, let progress = baselineProgress {
            return "Day \(progress)/14"
        }

        var parts: [String] = []
        if let sleep = sleepHours {
            parts.append(String(format: "%.1fh sleep", sleep))
        }
        if let hrv = hrvDeviation {
            let sign = hrv >= 0 ? "+" : ""
            parts.append("HRV \(sign)\(Int(hrv))%")
        }
        return parts.isEmpty ? "\(positiveCount)/\(totalCount) signals" : parts.joined(separator: ", ")
    }

    static let placeholder = WidgetReadinessData(
        category: "Good",
        positiveCount: 2,
        totalCount: 3,
        sleepHours: 7.5,
        hrvDeviation: 5,
        isBaselineReady: true,
        baselineProgress: nil,
        lastUpdated: Date()
    )
}

struct WidgetInsight: Codable, Sendable, Identifiable {
    let id: String
    let category: String  // "correlation", "trend", "anomaly", "milestone", "nudge"
    let title: String
    let body: String
    let sparklineValues: [Double]?
    let createdAt: Date

    var categoryIcon: String {
        switch category {
        case "correlation": return "link"
        case "trend": return "chart.line.uptrend.xyaxis"
        case "anomaly": return "exclamationmark.triangle.fill"
        case "milestone": return "star.fill"
        case "nudge": return "hand.point.right.fill"
        default: return "lightbulb.fill"
        }
    }

    var categoryColor: String {
        switch category {
        case "correlation": return "purple"
        case "trend": return "blue"
        case "anomaly": return "orange"
        case "milestone": return "yellow"
        case "nudge": return "green"
        default: return "gray"
        }
    }

    static let placeholder = WidgetInsight(
        id: "placeholder",
        category: "correlation",
        title: "Protein drops on high-stress days",
        body: "On days with elevated HRV deviation, your protein intake averages 30g lower.",
        sparklineValues: [145, 160, 120, 155, 110, 165, 140],
        createdAt: Date()
    )
}

struct WidgetEnergyData: Codable, Sendable {
    let currentTDEE: Int
    let projectedTDEE: Int
    let projectedNet: Int  // calories consumed - projected burn
    let confidence: Double  // 0.0-1.0
    let isTrainingDay: Bool
    let caloriesConsumed: Int
    let lastUpdated: Date

    /// Position on the -500 to +500 scale
    var dialPosition: Double {
        // Clamp to -500...+500, normalize to 0...1
        let clamped = max(-500, min(500, projectedNet))
        return (Double(clamped) + 500) / 1000
    }

    var netLabel: String {
        if projectedNet > 0 {
            return "+\(projectedNet)"
        } else {
            return "\(projectedNet)"
        }
    }

    var isDeficit: Bool { projectedNet < 0 }
    var isSurplus: Bool { projectedNet > 0 }

    static let placeholder = WidgetEnergyData(
        currentTDEE: 1800,
        projectedTDEE: 2650,
        projectedNet: -150,
        confidence: 0.7,
        isTrainingDay: true,
        caloriesConsumed: 2500,
        lastUpdated: Date()
    )
}

struct WidgetStrengthData: Codable, Sendable {
    let muscleGroups: [MuscleGroupProgress]
    let recentPR: PRInfo?
    let lastWorkout: WorkoutInfo?
    let lastUpdated: Date

    struct MuscleGroupProgress: Codable, Sendable, Identifiable {
        var id: String { name }
        let name: String
        let currentSets: Int
        let targetSets: Int  // Typically 10-20
        let status: String  // "below", "in_zone", "above"

        var progress: Double {
            guard targetSets > 0 else { return 0 }
            return min(1.0, Double(currentSets) / Double(targetSets))
        }

        var isBehind: Bool { status == "below" }
    }

    struct PRInfo: Codable, Sendable {
        let exerciseName: String
        let weight: Double
        let unit: String  // "kg" or "lbs"
        let date: Date
    }

    struct WorkoutInfo: Codable, Sendable {
        let name: String
        let duration: Int  // minutes
        let volume: Double
        let date: Date
    }

    var behindMuscleGroups: [MuscleGroupProgress] {
        muscleGroups.filter { $0.isBehind }
    }

    static let placeholder = WidgetStrengthData(
        muscleGroups: [
            MuscleGroupProgress(name: "Chest", currentSets: 8, targetSets: 16, status: "below"),
            MuscleGroupProgress(name: "Back", currentSets: 14, targetSets: 15, status: "in_zone"),
            MuscleGroupProgress(name: "Legs", currentSets: 18, targetSets: 16, status: "above"),
            MuscleGroupProgress(name: "Shoulders", currentSets: 6, targetSets: 12, status: "below"),
            MuscleGroupProgress(name: "Arms", currentSets: 10, targetSets: 12, status: "in_zone")
        ],
        recentPR: PRInfo(exerciseName: "Bench Press", weight: 100, unit: "kg", date: Date().addingTimeInterval(-86400)),
        lastWorkout: WorkoutInfo(name: "Push Day", duration: 65, volume: 12500, date: Date().addingTimeInterval(-86400)),
        lastUpdated: Date()
    )
}

struct WidgetWeeklyData: Codable, Sendable {
    let days: [DayData]
    let lastUpdated: Date

    struct DayData: Codable, Sendable, Identifiable {
        var id: Date { date }
        let date: Date
        let hasWorkout: Bool
        let workoutName: String?
        let nutritionCompliance: Double?  // 0.0-1.0, nil if no data
        let sleepQuality: Double?  // 0.0-1.0, nil if no data

        var dayOfWeek: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return formatter.string(from: date)
        }

        var isToday: Bool {
            Calendar.current.isDateInToday(date)
        }
    }

    static let placeholder: WidgetWeeklyData = {
        let calendar = Calendar.current
        let today = Date()
        var days: [DayData] = []

        for offset in -6...0 {
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            days.append(DayData(
                date: date,
                hasWorkout: offset % 2 == 0,
                workoutName: offset % 2 == 0 ? "Push" : nil,
                nutritionCompliance: Double.random(in: 0.7...1.0),
                sleepQuality: Double.random(in: 0.6...1.0)
            ))
        }

        return WidgetWeeklyData(days: days, lastUpdated: Date())
    }()
}

struct WidgetCoachNudge: Codable, Sendable {
    let message: String
    let context: String?  // Optional deep-link context
    let generatedAt: Date

    static let placeholder = WidgetCoachNudge(
        message: "Solid protein day. Rest well tonight.",
        context: nil,
        generatedAt: Date()
    )
}

enum WidgetContext: String, Codable, Sendable {
    case morning      // 5am-10am
    case preWorkout   // Detected training day, before workout
    case postWorkout  // After workout logged
    case afternoon    // 12pm-5pm
    case evening      // 5pm-10pm
    case night        // 10pm-5am

    var suggestedAction: String {
        switch self {
        case .morning: return "Log breakfast"
        case .preWorkout: return "Check readiness"
        case .postWorkout: return "Sync workout"
        case .afternoon: return "Log lunch"
        case .evening: return "Review day"
        case .night: return "See insights"
        }
    }

    var actionIcon: String {
        switch self {
        case .morning: return "sun.horizon.fill"
        case .preWorkout: return "figure.strengthtraining.traditional"
        case .postWorkout: return "arrow.triangle.2.circlepath"
        case .afternoon: return "fork.knife"
        case .evening: return "chart.bar.fill"
        case .night: return "moon.stars.fill"
        }
    }

    static func current(isTrainingDay: Bool = false, hasWorkoutToday: Bool = false) -> WidgetContext {
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
