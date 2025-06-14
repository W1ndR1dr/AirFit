import Foundation
import SwiftData

/// Intelligent serialization of health context for LLM consumption
/// Balances token efficiency with coaching relevance using configurable detail levels
actor ContextSerializer: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "context-serializer"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // Actor services are always ready for configuration
        true
    }

    // MARK: - Configuration
    enum DetailLevel {
        case minimal    // ~50 tokens - basic stats only
        case standard   // ~150 tokens - patterns and trends
        case detailed   // ~300 tokens - full coaching context
        case workout    // ~400 tokens - optimized for workout generation
    }

    private struct TokenLimits {
        static let minimal = 50
        static let standard = 150
        static let detailed = 300
        static let workout = 400
    }

    // MARK: - Public Interface

    /// Serializes health context into LLM-optimized coaching text
    func serializeContext(
        _ healthContext: HealthContextSnapshot,
        detailLevel: DetailLevel = .standard,
        focusArea: String? = nil
    ) async -> String {
        switch detailLevel {
        case .minimal:
            return await buildMinimalContext(healthContext, focusArea: focusArea)
        case .standard:
            return await buildStandardContext(healthContext, focusArea: focusArea)
        case .detailed:
            return await buildDetailedContext(healthContext, focusArea: focusArea)
        case .workout:
            return await buildWorkoutContext(healthContext, focusArea: focusArea)
        }
    }

    /// Quick context for simple responses - optimized for token efficiency
    func serializeQuickContext(_ healthContext: HealthContextSnapshot) async -> String {
        return await buildMinimalContext(healthContext, focusArea: nil)
    }

    /// Workout-optimized context for AI workout generation
    func serializeWorkoutContext(
        _ healthContext: HealthContextSnapshot,
        workoutType: String? = nil
    ) async -> String {
        return await buildWorkoutContext(healthContext, focusArea: workoutType)
    }

    // MARK: - Context Builders

    private func buildMinimalContext(
        _ context: HealthContextSnapshot,
        focusArea: String?
    ) async -> String {
        var sections: [String] = []

        // Essential fitness state
        if let workoutContext = context.appContext.workoutContext {
            sections.append("Fitness: \(workoutContext.recentWorkouts.count) workouts this week, \(workoutContext.streakDays) day streak")

            if workoutContext.recoveryStatus != .unknown {
                sections.append("Recovery: \(workoutContext.recoveryStatus.displayName)")
            }
        }

        // Current activity level
        if let steps = context.activity.steps {
            sections.append("Today: \(formatNumber(steps)) steps")
        }

        // Energy level if available
        if let energy = context.subjectiveData.energyLevel {
            sections.append("Energy: \(energy)/10")
        }

        return sections.joined(separator: " | ")
    }

    private func buildStandardContext(
        _ context: HealthContextSnapshot,
        focusArea: String?
    ) async -> String {
        var sections: [String] = []

        // Workout intelligence
        if let workoutContext = context.appContext.workoutContext {
            sections.append(formatWorkoutIntelligence(workoutContext, detailed: false))
        }

        // Recent activity patterns
        sections.append(formatActivityContext(context))

        // Recovery and readiness
        sections.append(formatRecoveryContext(context))

        // Nutrition context if relevant
        if focusArea?.lowercased().contains("nutrition") == true || focusArea?.lowercased().contains("meal") == true {
            sections.append(formatNutritionContext(context))
        }

        return sections.joined(separator: "\n")
    }

    private func buildDetailedContext(
        _ context: HealthContextSnapshot,
        focusArea: String?
    ) async -> String {
        var sections: [String] = []

        // Comprehensive workout analysis
        if let workoutContext = context.appContext.workoutContext {
            sections.append(formatWorkoutIntelligence(workoutContext, detailed: true))
            sections.append(formatMuscleGroupBalance(workoutContext))
        }

        // Activity and health trends
        sections.append(formatActivityTrends(context))
        sections.append(formatHealthMetrics(context))

        // Sleep and recovery
        sections.append(formatSleepRecovery(context))

        // Subjective wellness
        sections.append(formatSubjectiveData(context))

        // Goals context if available
        if let goalsContext = context.appContext.goalsContext {
            sections.append(formatGoalsContext(goalsContext))
        }

        return sections.joined(separator: "\n")
    }

    private func buildWorkoutContext(
        _ context: HealthContextSnapshot,
        focusArea: String?
    ) async -> String {
        var sections: [String] = []

        // Workout planning intelligence
        if let workoutContext = context.appContext.workoutContext {
            sections.append("WORKOUT HISTORY:")
            sections.append(formatRecentWorkouts(workoutContext))
            sections.append("")
            sections.append("TRAINING ANALYSIS:")
            sections.append(formatTrainingPatterns(workoutContext))
            sections.append("")
            sections.append("RECOVERY STATUS:")
            sections.append(formatRecoveryForWorkouts(context, workoutContext))
        }

        // Equipment and preferences (placeholder for future)
        sections.append("")
        sections.append("SESSION CONTEXT:")
        sections.append(formatSessionContext(context, focusArea))

        return sections.joined(separator: "\n")
    }

    // MARK: - Format Helpers

    private func formatWorkoutIntelligence(_ workoutContext: WorkoutContext, detailed: Bool) -> String {
        var parts: [String] = []

        parts.append("Workouts: \(workoutContext.recentWorkouts.count) this week")

        if workoutContext.streakDays > 0 {
            parts.append("\(workoutContext.streakDays) day streak")
        }

        if detailed {
            parts.append("Volume: \(formatVolume(workoutContext.weeklyVolume))")
            parts.append("Trend: \(workoutContext.intensityTrend.displayName)")
        }

        parts.append("Recovery: \(workoutContext.recoveryStatus.displayName)")

        return parts.joined(separator: " | ")
    }

    private func formatRecentWorkouts(_ workoutContext: WorkoutContext) -> String {
        let recentWorkouts = Array(workoutContext.recentWorkouts.prefix(3))

        return recentWorkouts.enumerated().map { index, workout in
            let duration = workout.duration.map { "\(Int($0 / 60))min" } ?? ""
            let daysSince = Calendar.current.dateComponents([.day], from: workout.date, to: Date()).day ?? 0
            let timing = daysSince == 0 ? "today" : daysSince == 1 ? "yesterday" : "\(daysSince)d ago"

            var workoutLines = ["• \(workout.name) (\(timing)): \(duration)"]

            // Show detailed exercise performance (top 3-4 exercises)
            let topExercises = Array(workout.exercisePerformance.values)
                .sorted { $0.volumeTotal > $1.volumeTotal }
                .prefix(4)

            for exercise in topExercises {
                let performance = exercise.contextSummary
                let progressionNote = findProgressionNote(
                    for: exercise.exerciseName,
                    currentWorkout: workout,
                    recentWorkouts: recentWorkouts,
                    currentIndex: index
                )

                let line = progressionNote.isEmpty
                    ? "  - \(exercise.exerciseName): \(performance)"
                    : "  - \(exercise.exerciseName): \(performance) \(progressionNote)"

                workoutLines.append(line)
            }

            return workoutLines.joined(separator: "\n")
        }.joined(separator: "\n")
    }

    /// Find progression notes by comparing exercise performance across recent workouts
    private func findProgressionNote(
        for exerciseName: String,
        currentWorkout: CompactWorkout,
        recentWorkouts: [CompactWorkout],
        currentIndex: Int
    ) -> String {
        // Check if this exercise appears in recent workouts
        let otherWorkouts = Array(recentWorkouts.dropFirst(currentIndex + 1))

        for olderWorkout in otherWorkouts {
            if olderWorkout.keyExercises.contains(exerciseName) {
                let daysBetween = Calendar.current.dateComponents([.day],
                                                                  from: olderWorkout.date, to: currentWorkout.date).day ?? 0

                // Only show progression for workouts within reasonable timeframe
                guard daysBetween > 0 && daysBetween <= 14 else { continue }

                let timeframe = daysBetween <= 7 ? "last week" : "\(daysBetween)d ago"
                return "(repeated from \(timeframe))"
            }
        }

        return ""
    }

    private func formatTrainingPatterns(_ workoutContext: WorkoutContext) -> String {
        var patterns: [String] = []

        // Enhanced volume status reporting (like ChatGPT examples)
        let muscleGroups = workoutContext.muscleGroupBalance
            .sorted { $0.value > $1.value }

        if !muscleGroups.isEmpty {
            patterns.append("VOLUME STATUS (7-day rolling):")

            // Show top muscle groups with status
            for (muscle, sets) in muscleGroups.prefix(6) {
                let status = formatVolumeStatus(muscle: muscle, sets: sets)
                patterns.append("• \(muscle): \(sets) sets \(status)")
            }
            patterns.append("")
        }

        // Weekly totals and trends
        patterns.append("Weekly total: \(formatVolume(workoutContext.weeklyVolume)) volume")
        patterns.append("Intensity trend: \(workoutContext.intensityTrend.displayName)")

        return patterns.joined(separator: "\n")
    }

    /// Format volume status for muscle groups (let LLM interpret targets naturally)
    private func formatVolumeStatus(muscle: String, sets: Int) -> String {
        // Provide context cues that help LLM assess volume appropriateness
        // without hard-coding targets
        switch sets {
        case 0...3:
            return "(light volume)"
        case 4...6:
            return "(moderate)"
        case 7...10:
            return "(solid)"
        case 11...15:
            return "(high volume)"
        default:
            return "(very high)"
        }
    }

    private func formatRecoveryForWorkouts(_ context: HealthContextSnapshot, _ workoutContext: WorkoutContext) -> String {
        var recovery: [String] = []

        recovery.append("Status: \(workoutContext.recoveryStatus.displayName)")

        // Enhanced sleep analysis
        if let sleep = context.sleep.lastNight {
            let duration = sleep.totalSleepTime ?? sleep.timeInBed ?? 0
            let efficiency = sleep.efficiency.map { String(format: "%.0f%%", $0 * 100) } ?? "unknown"
            let quality = sleep.quality?.rawValue ?? "unknown"

            var sleepLine = "Sleep: \(formatDuration(duration)) (\(efficiency) efficiency, \(quality) quality)"

            // Add sleep stage breakdown if available
            if let deep = sleep.deepTime, let rem = sleep.remTime {
                let deepPercent = duration > 0 ? Int((deep / duration) * 100) : 0
                let remPercent = duration > 0 ? Int((rem / duration) * 100) : 0
                sleepLine += " - Deep: \(deepPercent)%, REM: \(remPercent)%"
            }

            recovery.append(sleepLine)
        }

        // Heart health with trend context
        var heartMetrics: [String] = []

        if let hrv = context.heartHealth.hrv?.value {
            heartMetrics.append("HRV: \(String(format: "%.0f", hrv))ms")
        }

        if let rhr = context.heartHealth.restingHeartRate {
            heartMetrics.append("RHR: \(rhr)bpm")
        }

        if let vo2 = context.heartHealth.vo2Max {
            heartMetrics.append("VO2 Max: \(String(format: "%.1f", vo2)) ml/kg/min")
        }

        if !heartMetrics.isEmpty {
            recovery.append("Heart health: \(heartMetrics.joined(separator: ", "))")
        }

        // Body composition trends (our smart scale advantage)
        var bodyMetrics: [String] = []

        if let weight = context.body.weight?.value {
            let weightDisplay = String(format: "%.1f", weight)
            let trend = context.body.weightTrend?.rawValue ?? "stable"
            bodyMetrics.append("Weight: \(weightDisplay)kg (\(trend))")
        }

        if let bodyFat = context.body.bodyFatPercentage {
            let bfTrend = context.body.bodyFatTrend?.rawValue ?? "stable"
            bodyMetrics.append("BF: \(String(format: "%.1f", bodyFat))% (\(bfTrend))")
        }

        if !bodyMetrics.isEmpty {
            recovery.append("Body: \(bodyMetrics.joined(separator: ", "))")
        }

        // Subjective wellness
        var subjective: [String] = []

        if let energy = context.subjectiveData.energyLevel {
            subjective.append("Energy: \(energy)/10")
        }

        if let stress = context.subjectiveData.stress {
            subjective.append("Stress: \(stress)/10")
        }

        if !subjective.isEmpty {
            recovery.append("Subjective: \(subjective.joined(separator: ", "))")
        }

        return recovery.joined(separator: "\n")
    }

    private func formatSessionContext(_ context: HealthContextSnapshot, _ focusArea: String?) -> String {
        var session: [String] = []

        // Time of day optimization
        let timeOfDay = context.environment.timeOfDay
        session.append("Time: \(timeOfDay.displayName)")

        // Last meal timing
        if let lastMeal = context.appContext.lastMealTime {
            let hoursSince = Date().timeIntervalSince(lastMeal) / 3_600
            session.append("Last meal: \(String(format: "%.1f", hoursSince))h ago")
        }

        // Focus area if specified
        if let focus = focusArea, !focus.isEmpty {
            session.append("Focus: \(focus)")
        }

        return session.joined(separator: "\n")
    }

    private func formatActivityContext(_ context: HealthContextSnapshot) -> String {
        var activity: [String] = []

        if let steps = context.activity.steps {
            activity.append("Steps: \(formatNumber(steps))")
        }

        if let calories = context.activity.activeEnergyBurned?.value {
            activity.append("Active calories: \(formatNumber(Int(calories)))")
        }

        return "Today: \(activity.joined(separator: ", "))"
    }

    private func formatRecoveryContext(_ context: HealthContextSnapshot) -> String {
        var recovery: [String] = []

        if let sleep = context.sleep.lastNight {
            let duration = formatDuration(sleep.totalSleepTime ?? sleep.timeInBed ?? 0)
            recovery.append("Sleep: \(duration)")
        }

        if let energy = context.subjectiveData.energyLevel {
            recovery.append("Energy: \(energy)/10")
        }

        return recovery.isEmpty ? "Recovery: data pending" : recovery.joined(separator: " | ")
    }

    private func formatNutritionContext(_ context: HealthContextSnapshot) -> String {
        var nutrition: [String] = []

        // Last meal context with timing
        if let lastMeal = context.appContext.lastMealSummary {
            var mealLine = "Last meal: \(lastMeal)"

            if let lastMealTime = context.appContext.lastMealTime {
                let hoursSince = Date().timeIntervalSince(lastMealTime) / 3_600
                if hoursSince < 24 {
                    mealLine += " (\(String(format: "%.1f", hoursSince))h ago)"
                }
            }

            nutrition.append(mealLine)
        }

        // Training day context for macro targets
        let isTrainingDay = context.appContext.workoutContext?.recentWorkouts.contains { workout in
            Calendar.current.isDateInToday(workout.date)
        } ?? false

        // Activity level context for calorie needs
        let activeCalories = context.activity.activeEnergyBurned?.value ?? 0
        let activityLevel = activeCalories > 400 ? "high" : activeCalories > 250 ? "moderate" : "light"

        // Provide macro guidance context (LLM will use this for natural recommendations)
        if isTrainingDay {
            nutrition.append("Training day: Higher carb needs, prioritize post-workout nutrition")
        } else {
            nutrition.append("Rest day: Standard macro targets, focus on protein and recovery")
        }

        nutrition.append("Activity level: \(activityLevel) (\(Int(activeCalories)) active calories)")

        // Body composition goal context
        if let weight = context.body.weight?.value,
           let trend = context.body.weightTrend {
            let goalContext = trend == .increasing ? "lean gain phase" :
                trend == .decreasing ? "fat loss phase" : "maintenance phase"
            nutrition.append("Phase: \(goalContext) (weight \(trend.rawValue))")
        }

        return nutrition.isEmpty ? "Nutrition: no recent data" : nutrition.joined(separator: "\n")
    }

    private func formatActivityTrends(_ context: HealthContextSnapshot) -> String {
        if let trend = context.trends.weeklyActivityChange {
            let direction = trend > 0 ? "↗" : trend < 0 ? "↘" : "→"
            return "Activity trend: \(direction) \(String(format: "%.0f", abs(trend)))% vs last week"
        }
        return "Activity trend: establishing baseline"
    }

    private func formatHealthMetrics(_ context: HealthContextSnapshot) -> String {
        var metrics: [String] = []

        if let rhr = context.heartHealth.restingHeartRate {
            metrics.append("RHR: \(rhr)bpm")
        }

        if let weight = context.body.weight?.value {
            metrics.append("Weight: \(String(format: "%.1f", weight))kg")
        }

        return metrics.isEmpty ? "Health metrics: data pending" : metrics.joined(separator: " | ")
    }

    private func formatSleepRecovery(_ context: HealthContextSnapshot) -> String {
        guard let sleep = context.sleep.lastNight else {
            return "Sleep: no recent data"
        }

        let duration = formatDuration(sleep.totalSleepTime ?? sleep.timeInBed ?? 0)
        let efficiency = sleep.efficiency.map { String(format: "%.0f%%", $0 * 100) } ?? "unknown"
        let deep = sleep.deepTime.map { formatDuration($0) } ?? "unknown"

        return "Sleep: \(duration) total, \(efficiency) efficiency, \(deep) deep"
    }

    private func formatSubjectiveData(_ context: HealthContextSnapshot) -> String {
        var subjective: [String] = []

        if let energy = context.subjectiveData.energyLevel {
            subjective.append("Energy: \(energy)/10")
        }

        if let stress = context.subjectiveData.stress {
            subjective.append("Stress: \(stress)/10")
        }

        return subjective.isEmpty ? "Wellness: no self-reported data" : subjective.joined(separator: " | ")
    }

    private func formatGoalsContext(_ goalsContext: GoalsContext) -> String {
        if goalsContext.activeGoals.isEmpty {
            return "Goals: none set"
        }

        let activeCount = goalsContext.activeGoals.count
        let recentProgress = goalsContext.recentAchievements.isEmpty ? "establishing baseline" : "tracking progress"

        return "Goals: \(activeCount) active, \(recentProgress)"
    }

    private func formatMuscleGroupBalance(_ workoutContext: WorkoutContext) -> String {
        let sorted = workoutContext.muscleGroupBalance
            .sorted { $0.value > $1.value }
            .prefix(4)
            .map { "\($0.key): \($0.value)" }

        return "Muscle focus: \(sorted.joined(separator: ", "))"
    }

    // MARK: - Utility Helpers

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000 {
            return String(format: "%.1fk", Double(number) / 1_000)
        }
        return "\(number)"
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000 {
            return String(format: "%.1fk", volume / 1_000)
        }
        return String(format: "%.0f", volume)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3_600
        let minutes = (Int(duration) % 3_600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    // MARK: - ServiceProtocol Methods

    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }

    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }

    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: _isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: _isConfigured ? nil : "Service not configured",
            metadata: [
                "supportedDetailLevels": "minimal,standard,detailed,workout",
                "tokenLimits": "50-400 tokens"
            ]
        )
    }
}

// MARK: - Extensions for Display Names

private extension RecoveryStatus {
    var displayName: String {
        switch self {
        case .active: return "active"
        case .recovered: return "recovered"
        case .wellRested: return "well-rested"
        case .detraining: return "detraining"
        case .unknown: return "unknown"
        }
    }
}

private extension IntensityTrend {
    var displayName: String {
        switch self {
        case .increasing: return "increasing"
        case .stable: return "stable"
        case .decreasing: return "decreasing"
        }
    }
}

private extension EnvironmentContext.TimeOfDay {
    var displayName: String {
        switch self {
        case .earlyMorning: return "early morning"
        case .morning: return "morning"
        case .afternoon: return "afternoon"
        case .evening: return "evening"
        case .night: return "night"
        }
    }
}
