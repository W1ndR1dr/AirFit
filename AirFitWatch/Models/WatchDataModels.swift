import Foundation

// MARK: - Macro Progress (for complications)

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
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        targetCalories: 2600,
        targetProtein: 175,
        targetCarbs: 330,
        targetFat: 67,
        isTrainingDay: true,
        lastUpdated: Date()
    )
}

// MARK: - Readiness Data (for complications)

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
        sleepHours: nil,
        rhrDeviation: nil,
        isBaselineReady: false,
        lastUpdated: Date()
    )
}

// MARK: - Volume Progress (for complications)

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
            MuscleGroupVolume(name: "Back", currentSets: 12, targetSets: 15, status: "in_zone"),
            MuscleGroupVolume(name: "Legs", currentSets: 16, targetSets: 16, status: "in_zone")
        ],
        lastUpdated: Date()
    )
}

// MARK: - HRR Session Data (for Phase 3)

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
}
