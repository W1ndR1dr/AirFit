import Foundation

// MARK: - AI-Generated Dashboard Content
struct AIDashboardContent: Sendable, Equatable {
    let primaryInsight: String              // Main AI-generated message
    let nutritionData: DashboardNutritionData?       // Only shown if relevant to current context
    let muscleGroupVolumes: [MuscleGroupVolume]? // Only shown if user strength trains
    let guidance: String?                   // What to do next/today
    let celebration: String?                // Recent achievements to highlight
    let contextualMetrics: [ContextualMetric]? // Any other metrics AI deems important

    init(
        primaryInsight: String,
        nutritionData: DashboardNutritionData? = nil,
        muscleGroupVolumes: [MuscleGroupVolume]? = nil,
        guidance: String? = nil,
        celebration: String? = nil,
        contextualMetrics: [ContextualMetric]? = nil
    ) {
        self.primaryInsight = primaryInsight
        self.nutritionData = nutritionData
        self.muscleGroupVolumes = muscleGroupVolumes
        self.guidance = guidance
        self.celebration = celebration
        self.contextualMetrics = contextualMetrics
    }
}

// MARK: - Nutrition Data for Visual Display
struct DashboardNutritionData: Sendable, Equatable {
    let calories: Double
    let calorieTarget: Double
    let protein: Double
    let proteinTarget: Double
    let carbs: Double
    let carbTarget: Double
    let fat: Double
    let fatTarget: Double

    var calorieProgress: Double {
        guard calorieTarget > 0 else { return 0 }
        return min(calories / calorieTarget, 1.0)
    }

    var proteinProgress: Double {
        guard proteinTarget > 0 else { return 0 }
        return min(protein / proteinTarget, 1.0)
    }

    var carbProgress: Double {
        guard carbTarget > 0 else { return 0 }
        return min(carbs / carbTarget, 1.0)
    }

    var fatProgress: Double {
        guard fatTarget > 0 else { return 0 }
        return min(fat / fatTarget, 1.0)
    }
}

// MARK: - Muscle Group Volume
struct MuscleGroupVolume: Sendable, Identifiable, Equatable {
    let id = UUID()
    let name: String          // e.g., "Chest", "Back", "Legs"
    let sets: Int            // Hard sets completed in last 7 days
    let target: Int          // Weekly target sets
    let color: String        // Color name for the bar

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(sets) / Double(target), 1.0)
    }

    var isOnTrack: Bool {
        progress >= 0.8
    }
}

// MARK: - Contextual Metrics
struct ContextualMetric: Sendable, Identifiable, Equatable {
    let id = UUID()
    let label: String
    let value: String
    let emphasis: MetricEmphasis

    enum MetricEmphasis: String, Sendable {
        case high      // Large, prominent display
        case normal    // Standard display
        case subtle    // De-emphasized, secondary info
    }
}
