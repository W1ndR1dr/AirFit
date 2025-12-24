import Foundation
import WidgetKit

/// Shared data store for cross-process communication between Watch app and complications.
/// Uses App Groups UserDefaults since WidgetKit extensions run in separate processes.
struct SharedDataStore {
    static let suiteName = "group.com.airfit.shared"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Macro Progress

    static var macroProgress: MacroProgress? {
        get { decode(key: "macroProgress") }
        set {
            encode(newValue, key: "macroProgress")
            reloadTimeline(kind: "MacroComplication")
        }
    }

    // MARK: - Readiness Data

    static var readinessData: ReadinessData? {
        get { decode(key: "readinessData") }
        set {
            encode(newValue, key: "readinessData")
            reloadTimeline(kind: "ReadinessComplication")
        }
    }

    // MARK: - Volume Progress

    static var volumeProgress: VolumeProgress? {
        get { decode(key: "volumeProgress") }
        set {
            encode(newValue, key: "volumeProgress")
            reloadTimeline(kind: "VolumeComplication")
        }
    }

    // MARK: - HRR Session Data (Live workout tracking)

    static var hrrSessionData: HRRSessionData? {
        get { decode(key: "hrrSessionData") }
        set {
            encode(newValue, key: "hrrSessionData")
            reloadTimeline(kind: "HRRComplication")
        }
    }

    // MARK: - Last Update Time

    static var lastUpdateTime: Date? {
        get { defaults?.object(forKey: "lastUpdateTime") as? Date }
        set { defaults?.set(newValue, forKey: "lastUpdateTime") }
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

    private static func reloadTimeline(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    /// Reload all AirFit complications
    static func reloadAllComplications() {
        WidgetCenter.shared.reloadTimelines(ofKind: "MacroComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "ReadinessComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "VolumeComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "HRRComplication")
    }
}

// MARK: - Data Models (mirrored from WatchDataModels for widget extension)

struct MacroProgress: Codable, Sendable {
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

    var calorieProgress: Double {
        guard targetCalories > 0 else { return 0 }
        return Double(calories) / Double(targetCalories)
    }

    var proteinProgress: Double {
        guard targetProtein > 0 else { return 0 }
        return Double(protein) / Double(targetProtein)
    }

    var proteinRemaining: Int {
        max(0, targetProtein - protein)
    }

    var caloriesRemaining: Int {
        targetCalories - calories
    }

    static let placeholder = MacroProgress(
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

struct ReadinessData: Codable, Sendable {
    let category: String  // "Great", "Good", "Moderate", "Rest"
    let positiveCount: Int
    let totalCount: Int
    let hrvDeviation: Double?
    let sleepHours: Double?
    let rhrDeviation: Double?
    let isBaselineReady: Bool
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

    static let placeholder = ReadinessData(
        category: "Good",
        positiveCount: 2,
        totalCount: 3,
        hrvDeviation: nil,
        sleepHours: 7.5,
        rhrDeviation: nil,
        isBaselineReady: true,
        lastUpdated: Date()
    )
}

struct VolumeProgress: Codable, Sendable {
    let muscleGroups: [MuscleGroupVolume]
    let lastUpdated: Date

    struct MuscleGroupVolume: Codable, Sendable, Identifiable {
        var id: String { name }
        let name: String
        let currentSets: Int
        let targetSets: Int
        let status: String  // "in_zone", "below", "above", "at_floor"

        var progress: Double {
            guard targetSets > 0 else { return 0 }
            return min(1.0, Double(currentSets) / Double(targetSets))
        }

        var isComplete: Bool {
            currentSets >= targetSets
        }
    }

    static let placeholder = VolumeProgress(
        muscleGroups: [
            MuscleGroupVolume(name: "Chest", currentSets: 8, targetSets: 16, status: "below"),
            MuscleGroupVolume(name: "Back", currentSets: 14, targetSets: 15, status: "in_zone"),
            MuscleGroupVolume(name: "Legs", currentSets: 16, targetSets: 16, status: "in_zone")
        ],
        lastUpdated: Date()
    )
}

// MARK: - HRR Session Data (Live Workout Tracking)

struct HRRSessionData: Codable, Sendable {
    let isWorkoutActive: Bool
    let currentPhase: String  // "idle", "exertion", "recovery", "resting"
    let currentHR: Double
    let peakHR: Double
    let restPeriods: [RestPeriod]
    let fatigueLevel: String  // "fresh", "productive", "fatigued", "asymptote", "depleted"
    let degradationPercent: Double
    let setsCompleted: Int

    struct RestPeriod: Codable, Sendable {
        let startHR: Double
        let endHR: Double
        let duration: TimeInterval
        let recoveryRate: Double  // bpm/second
    }

    var latestRecoveryRate: Double? {
        restPeriods.last?.recoveryRate
    }

    var averageRecoveryRate: Double {
        guard !restPeriods.isEmpty else { return 0 }
        return restPeriods.map(\.recoveryRate).reduce(0, +) / Double(restPeriods.count)
    }

    /// Phase display for complications
    var phaseDisplayName: String {
        switch currentPhase {
        case "exertion": return "Working"
        case "recovery": return "Recovering"
        case "resting": return "Rest"
        default: return "Ready"
        }
    }

    /// Phase icon for complications
    var phaseIcon: String {
        switch currentPhase {
        case "exertion": return "flame.fill"
        case "recovery": return "arrow.down.heart.fill"
        case "resting": return "pause.circle.fill"
        default: return "heart.fill"
        }
    }

    /// Fatigue color for visual feedback
    var fatigueColor: String {
        switch fatigueLevel {
        case "fresh": return "green"
        case "productive": return "blue"
        case "fatigued": return "orange"
        case "asymptote": return "red"
        case "depleted": return "purple"
        default: return "gray"
        }
    }

    static let placeholder = HRRSessionData(
        isWorkoutActive: false,
        currentPhase: "idle",
        currentHR: 72,
        peakHR: 72,
        restPeriods: [],
        fatigueLevel: "fresh",
        degradationPercent: 0,
        setsCompleted: 0
    )

    static let workoutPreview = HRRSessionData(
        isWorkoutActive: true,
        currentPhase: "recovery",
        currentHR: 142,
        peakHR: 165,
        restPeriods: [
            RestPeriod(startHR: 160, endHR: 130, duration: 60, recoveryRate: 0.5),
            RestPeriod(startHR: 158, endHR: 128, duration: 55, recoveryRate: 0.55)
        ],
        fatigueLevel: "productive",
        degradationPercent: 15,
        setsCompleted: 4
    )
}
