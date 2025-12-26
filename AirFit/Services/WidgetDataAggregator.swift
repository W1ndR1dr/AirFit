import Foundation
import SwiftData

/// Aggregates data from various sources for widget sync.
/// Handles strength data, weekly patterns, and coach nudge generation.
actor WidgetDataAggregator {
    static let shared = WidgetDataAggregator()

    private let healthKit = HealthKitManager()
    private let apiClient = APIClient()

    // MARK: - Strength Data Aggregation

    /// Build strength data for widgets from cached Hevy data.
    @MainActor
    func aggregateStrengthData(modelContext: ModelContext) async -> (
        muscleGroups: [WidgetStrengthData.MuscleGroupProgress],
        recentPR: WidgetStrengthData.PRInfo?,
        lastWorkout: WidgetStrengthData.WorkoutInfo?
    ) {
        // Fetch cached set tracker data
        let setTrackerDescriptor = FetchDescriptor<CachedSetTracker>(
            sortBy: [SortDescriptor(\CachedSetTracker.muscleGroup)]
        )

        let setTrackers = (try? modelContext.fetch(setTrackerDescriptor)) ?? []

        let muscleGroups = setTrackers.map { tracker in
            WidgetStrengthData.MuscleGroupProgress(
                name: tracker.muscleGroup,
                currentSets: tracker.currentSets,
                targetSets: tracker.optimalMax,
                status: tracker.status
            )
        }

        // Find most recent PR
        let liftProgressDescriptor = FetchDescriptor<CachedLiftProgress>(
            sortBy: [SortDescriptor(\CachedLiftProgress.currentPRDate, order: .reverse)]
        )

        let liftProgress = (try? modelContext.fetch(liftProgressDescriptor)) ?? []
        let recentPR: WidgetStrengthData.PRInfo?

        if let mostRecent = liftProgress.first,
           mostRecent.currentPRDate > Calendar.current.date(byAdding: .day, value: -7, to: Date())! {
            recentPR = WidgetStrengthData.PRInfo(
                exerciseName: mostRecent.exerciseName,
                weight: mostRecent.currentPRWeightLbs,
                unit: "lbs",
                date: mostRecent.currentPRDate
            )
        } else {
            recentPR = nil
        }

        // Get last workout
        let workoutDescriptor = FetchDescriptor<CachedWorkout>(
            sortBy: [SortDescriptor(\CachedWorkout.workoutDate, order: .reverse)]
        )

        let workouts = (try? modelContext.fetch(workoutDescriptor)) ?? []
        let lastWorkout: WidgetStrengthData.WorkoutInfo?

        if let recent = workouts.first {
            lastWorkout = WidgetStrengthData.WorkoutInfo(
                name: recent.title,
                duration: recent.durationMinutes,
                volume: recent.totalVolumeLbs,
                date: recent.workoutDate
            )
        } else {
            lastWorkout = nil
        }

        return (muscleGroups, recentPR, lastWorkout)
    }

    // MARK: - Weekly Data Aggregation

    /// Build weekly data for the WeeklyRhythm widget.
    /// Combines workout, nutrition, and sleep data for the past 7 days.
    @MainActor
    func aggregateWeeklyData(modelContext: ModelContext) async -> [WidgetWeeklyData.DayData] {
        let calendar = Calendar.current
        let today = Date()
        var days: [WidgetWeeklyData.DayData] = []

        // Get cached workouts for the week
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        let workoutPredicate = #Predicate<CachedWorkout> { $0.workoutDate >= weekAgo }
        let workoutDescriptor = FetchDescriptor<CachedWorkout>(predicate: workoutPredicate)
        let workouts = (try? modelContext.fetch(workoutDescriptor)) ?? []

        // Get nutrition entries for the week
        let nutritionPredicate = #Predicate<NutritionEntry> { $0.timestamp >= weekAgo }
        let nutritionDescriptor = FetchDescriptor<NutritionEntry>(predicate: nutritionPredicate)
        let nutritionEntries = (try? modelContext.fetch(nutritionDescriptor)) ?? []

        // Get sleep data for the week
        let sleepData = await healthKit.getRecentSleepBreakdowns(nights: 7)

        // Build day data for each of the last 7 days
        for dayOffset in -6...0 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            // Check for workout on this day
            let dayWorkouts = workouts.filter {
                $0.workoutDate >= dayStart && $0.workoutDate < dayEnd
            }
            let hasWorkout = !dayWorkouts.isEmpty
            let workoutName = dayWorkouts.first?.title

            // Calculate nutrition compliance
            let dayNutrition = nutritionEntries.filter {
                $0.timestamp >= dayStart && $0.timestamp < dayEnd
            }
            let totalProtein = dayNutrition.reduce(0) { $0 + $1.protein }
            let proteinTarget = hasWorkout ? 175 : 175  // Same target for now
            let nutritionCompliance: Double? = dayNutrition.isEmpty ? nil :
                min(1.0, Double(totalProtein) / Double(proteinTarget))

            // Get sleep quality for this night
            let sleepQuality: Double?
            if let sleepForNight = sleepData.first(where: {
                calendar.isDate($0.date, inSameDayAs: date)
            }) {
                // Normalize efficiency (80-100%) to 0-1 scale
                sleepQuality = min(1.0, max(0, (sleepForNight.efficiency - 70) / 30))
            } else {
                sleepQuality = nil
            }

            days.append(WidgetWeeklyData.DayData(
                date: date,
                hasWorkout: hasWorkout,
                workoutName: workoutName,
                nutritionCompliance: nutritionCompliance,
                sleepQuality: sleepQuality
            ))
        }

        return days
    }

    // MARK: - Coach Nudge Generation

    /// Generate a contextual coach nudge based on current state.
    /// Uses simple rules for now - could be AI-powered in the future.
    @MainActor
    func generateCoachNudge(
        nutrition: WidgetNutritionData?,
        readiness: WidgetReadinessData?,
        context: WidgetContext
    ) async -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        // Morning nudges
        if hour < 10 {
            if let readiness = readiness {
                switch readiness.category {
                case "Great":
                    return "All systems go. Make today count."
                case "Good":
                    return "Solid recovery. Normal training ahead."
                case "Moderate":
                    return "Mixed signals. Listen to your body today."
                case "Rest":
                    return "Recovery day recommended. Rest is productive."
                default:
                    return "Good morning. Let's make today count."
                }
            }
            return "Good morning. Ready to track your day."
        }

        // Midday nudges
        if hour < 14 {
            if let nutrition = nutrition {
                let proteinPercent = nutrition.proteinProgress
                if proteinPercent < 0.3 {
                    return "Protein's lagging. High-protein lunch incoming?"
                } else if proteinPercent > 0.6 {
                    return "Solid protein so far. Keep it up."
                }
            }
            return "Don't forget to log lunch."
        }

        // Afternoon nudges
        if hour < 18 {
            if let nutrition = nutrition {
                if nutrition.isTrainingDay && nutrition.proteinProgress < 0.5 {
                    return "Training day - prioritize protein at dinner."
                }
            }
            return "Afternoon check-in. How's the day going?"
        }

        // Evening nudges
        if hour < 22 {
            if let nutrition = nutrition {
                let remaining = nutrition.targetProtein - nutrition.protein
                if remaining > 30 && remaining <= 60 {
                    return "~\(remaining)g protein to go. Casein before bed?"
                } else if remaining <= 30 && remaining > 0 {
                    return "Almost there! Just \(remaining)g protein left."
                } else if remaining <= 0 {
                    return "Protein target hit. Solid day."
                }
            }
            return "Evening review. Don't forget to log dinner."
        }

        // Night nudges
        if let readiness = readiness, let sleep = readiness.sleepHours {
            if sleep >= 7.5 {
                return "Great sleep foundation. Keep it consistent."
            }
        }
        return "Rest well. Tomorrow's a new opportunity."
    }

    // MARK: - Full Widget Sync

    /// Perform a comprehensive widget sync from all data sources.
    @MainActor
    func syncAllWidgetData(modelContext: ModelContext) async {
        print("[WidgetDataAggregator] Starting comprehensive widget sync...")

        // Sync strength data
        let (muscleGroups, recentPR, lastWorkout) = await aggregateStrengthData(modelContext: modelContext)
        await WidgetSyncService.shared.syncStrength(
            muscleGroups: muscleGroups,
            recentPR: recentPR,
            lastWorkout: lastWorkout
        )

        // Sync weekly data
        let weeklyDays = await aggregateWeeklyData(modelContext: modelContext)
        await WidgetSyncService.shared.syncWeeklyData(weeklyDays)

        // Get current nutrition and readiness for nudge generation
        // These would typically be fetched from wherever they're stored
        // For now, generate a generic nudge based on time
        let nudge = await generateCoachNudge(nutrition: nil, readiness: nil, context: .current(isTrainingDay: false, hasWorkoutToday: false))
        await WidgetSyncService.shared.syncCoachNudge(nudge)

        // Update context
        let hasWorkoutToday = !weeklyDays.filter { Calendar.current.isDateInToday($0.date) && $0.hasWorkout }.isEmpty
        await WidgetSyncService.shared.updateContextBasedOnTime(isTrainingDay: false, hasWorkoutToday: hasWorkoutToday)

        print("[WidgetDataAggregator] Widget sync complete")
    }
}
