import Foundation
import SwiftData

/// Aggregates health and environmental data into `HealthContextSnapshot` instances.
@MainActor
final class ContextAssembler {
    private let healthKitManager: HealthKitManaging
    // Future: private let weatherService: WeatherServiceProtocol

    init(healthKitManager: HealthKitManaging = HealthKitManager.shared) {
        self.healthKitManager = healthKitManager
    }

    /// Creates a `HealthContextSnapshot` using data from HealthKit and SwiftData models.
    /// - Parameter modelContext: The `ModelContext` used to fetch app data.
    func assembleSnapshot(modelContext: ModelContext) async -> HealthContextSnapshot {
        async let activityMetrics = fetchActivityMetrics()
        async let heartMetrics = fetchHeartHealthMetrics()
        async let bodyMetrics = fetchBodyMetrics()
        async let sleepSession = fetchSleepSession()

        // Fetch subjective data synchronously to avoid data races with ModelContext
        let subjectiveData = await fetchSubjectiveData(using: modelContext)

        // Mock data until services are implemented
        let environment = createMockEnvironmentContext()
        let appContext = await createMockAppContext(using: modelContext)

        // Await all HealthKit calls
        let (activity, heartHealth, body, sleep) = await (
            activityMetrics,
            heartMetrics,
            bodyMetrics,
            sleepSession
        )

        let trends = calculateTrends(
            activity: activity,
            body: body,
            sleep: sleep,
            context: modelContext
        )

        return HealthContextSnapshot(
            subjectiveData: subjectiveData,
            environment: environment,
            activity: activity ?? ActivityMetrics(),
            sleep: SleepAnalysis(lastNight: sleep),
            heartHealth: heartHealth ?? HeartHealthMetrics(),
            body: body ?? BodyMetrics(),
            appContext: appContext,
            trends: trends
        )
    }

    // MARK: - Private Helpers
    private func fetchActivityMetrics() async -> ActivityMetrics? {
        do {
            return try await healthKitManager.fetchTodayActivityMetrics()
        } catch {
            AppLogger.error("Failed to fetch activity metrics", error: error, category: .health)
            return nil
        }
    }

    private func fetchHeartHealthMetrics() async -> HeartHealthMetrics? {
        do {
            return try await healthKitManager.fetchHeartHealthMetrics()
        } catch {
            AppLogger.error("Failed to fetch heart health metrics", error: error, category: .health)
            return nil
        }
    }

    private func fetchBodyMetrics() async -> BodyMetrics? {
        do {
            return try await healthKitManager.fetchLatestBodyMetrics()
        } catch {
            AppLogger.error("Failed to fetch body metrics", error: error, category: .health)
            return nil
        }
    }

    private func fetchSleepSession() async -> SleepAnalysis.SleepSession? {
        do {
            return try await healthKitManager.fetchLastNightSleep()
        } catch {
            AppLogger.error("Failed to fetch last night sleep data", error: error, category: .health)
            return nil
        }
    }

    private func fetchSubjectiveData(using context: ModelContext) async -> SubjectiveData {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let predicate = #Predicate<DailyLog> { log in
            log.date == todayStart
        }
        var descriptor = FetchDescriptor<DailyLog>(predicate: predicate)
        descriptor.fetchLimit = 1

        do {
            if let log = try context.fetch(descriptor).first {
                return SubjectiveData(
                    energyLevel: log.subjectiveEnergyLevel,
                    mood: nil, // Mood tracking TBD
                    stress: log.stressLevel,
                    motivation: nil,
                    soreness: nil,
                    notes: log.notes
                )
            }
        } catch {
            AppLogger.error("Failed to fetch today's DailyLog", error: error, category: .data)
        }
        return SubjectiveData()
    }

    private func createMockEnvironmentContext() -> EnvironmentContext {
        EnvironmentContext(
            weatherCondition: "Clear",
            temperature: Measurement(value: 21, unit: .celsius),
            humidity: 55,
            airQualityIndex: 42,
            timeOfDay: .init(from: Date())
        )
    }

    private func createMockAppContext(using context: ModelContext) async -> AppSpecificContext {
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        _ = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now

        var lastMealTime: Date?
        var lastMealSummary: String?
        var activeWorkoutName: String?
        var upcomingWorkout: String?
        var currentStreak: Int?
        var workoutContext: WorkoutContext?

        do {
            // Meal context (unchanged)
            var mealDescriptor = FetchDescriptor<FoodEntry>(
                sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
            )
            mealDescriptor.fetchLimit = 1
            if let meal = try context.fetch(mealDescriptor).first {
                lastMealTime = meal.loggedAt
                let itemCount = meal.items.count
                let mealName = meal.mealTypeEnum?.displayName ?? "Meal"
                lastMealSummary = "\(mealName), \(itemCount) item\(itemCount == 1 ? "" : "s")"
            }

            // Enhanced workout context - rolling 7-day window with intelligent selection
            workoutContext = await assembleWorkoutContext(
                context: context,
                now: now,
                sevenDaysAgo: sevenDaysAgo
            )

            // Extract simplified fields for backward compatibility
            activeWorkoutName = workoutContext?.activeWorkout?.name
            upcomingWorkout = workoutContext?.upcomingWorkout?.name
            currentStreak = workoutContext?.streakDays

        } catch {
            AppLogger.error("Failed to assemble app context", error: error, category: .data)
        }

        return AppSpecificContext(
            activeWorkoutName: activeWorkoutName,
            lastMealTime: lastMealTime,
            lastMealSummary: lastMealSummary,
            waterIntakeToday: nil,
            lastCoachInteraction: nil,
            upcomingWorkout: upcomingWorkout,
            currentStreak: currentStreak,
            workoutContext: workoutContext
        )
    }

    /// Assembles comprehensive workout context optimized for AI coaching
    /// Rolling 7-day window with intelligent workout selection for context efficiency
    private func assembleWorkoutContext(
        context: ModelContext,
        now: Date,
        sevenDaysAgo: Date
    ) async -> WorkoutContext {
        do {
            // Fetch ALL workouts first, then filter in memory to avoid complex predicates
            var allWorkoutsDescriptor = FetchDescriptor<Workout>(
                sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
            )
            allWorkoutsDescriptor.fetchLimit = 50 // Reasonable limit
            
            let allWorkouts = try context.fetch(allWorkoutsDescriptor)
            
            // Filter recent completed workouts in memory
            let recentWorkouts = allWorkouts.filter { workout in
                guard let completedDate = workout.completedDate else { return false }
                return completedDate >= sevenDaysAgo && completedDate <= now
            }.prefix(10)
            
            // Find active workout (no completed date)
            let activeWorkout = allWorkouts.first { workout in
                workout.completedDate == nil
            }
            
            // Find upcoming workouts
            let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: now) ?? now
            let upcomingWorkouts = allWorkouts.filter { workout in
                guard workout.completedDate == nil,
                      let plannedDate = workout.plannedDate else { return false }
                return plannedDate > now && plannedDate <= threeDaysFromNow
            }.sorted { ($0.plannedDate ?? Date()) < ($1.plannedDate ?? Date()) }.prefix(3)

            // Calculate workout streak
            let streak = calculateWorkoutStreak(context: context, endDate: now)

            // Analyze recent performance patterns
            let patterns = analyzeWorkoutPatterns(Array(recentWorkouts))

            return WorkoutContext(
                recentWorkouts: recentWorkouts.map { compressWorkoutForContext($0) },
                activeWorkout: activeWorkout.map { compressWorkoutForContext($0) },
                upcomingWorkout: upcomingWorkouts.first.map { compressWorkoutForContext($0) },
                plannedWorkouts: Array(upcomingWorkouts.dropFirst()).map { compressWorkoutForContext($0) },
                streakDays: streak,
                weeklyVolume: patterns.weeklyVolume,
                muscleGroupBalance: patterns.muscleGroupBalance,
                intensityTrend: patterns.intensityTrend,
                recoveryStatus: patterns.recoveryStatus
            )

        } catch {
            AppLogger.error("Failed to assemble workout context", error: error, category: .data)
            return WorkoutContext()
        }
    }

    /// Compresses workout data for efficient API context while preserving coaching value
    private func compressWorkoutForContext(_ workout: Workout) -> CompactWorkout {
        let totalVolume = workout.exercises.reduce(into: 0.0) { total, exercise in
            total += exercise.sets.reduce(into: 0.0) { setTotal, set in
                let weight = set.completedWeightKg ?? set.targetWeightKg ?? 0
                let reps = Double(set.completedReps ?? set.targetReps ?? 0)
                setTotal += (weight * reps)
            }
        }

        let avgRPE = workout.exercises.flatMap { $0.sets }
            .compactMap { $0.rpe }
            .reduce(0, +) / Double(max(workout.exercises.flatMap { $0.sets }.count, 1))

        let muscleGroups = Set(workout.exercises.flatMap { $0.muscleGroups }).sorted()

        return CompactWorkout(
            name: workout.name,
            type: workout.workoutTypeEnum?.displayName ?? "Unknown",
            date: workout.completedDate ?? workout.plannedDate ?? Date(),
            duration: workout.durationSeconds,
            exerciseCount: workout.exercises.count,
            totalVolume: totalVolume,
            avgRPE: avgRPE.isFinite ? avgRPE : nil,
            muscleGroups: muscleGroups,
            keyExercises: workout.exercises.prefix(3).map { $0.name } // Top 3 exercises
        )
    }

    /// Calculates current workout streak with intelligent gap handling
    private func calculateWorkoutStreak(context: ModelContext, endDate: Date) -> Int {
        do {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate

            // Fetch all workouts and filter in memory
            var descriptor = FetchDescriptor<Workout>(
                sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
            )
            descriptor.fetchLimit = 50

            let allWorkouts = try context.fetch(descriptor)
            
            // Filter in memory to avoid predicate issues
            let workouts = allWorkouts.filter { workout in
                guard let completedDate = workout.completedDate else { return false }
                return completedDate >= thirtyDaysAgo && completedDate <= endDate
            }
            
            guard !workouts.isEmpty else { return 0 }

            var streak = 0
            var currentDate = Calendar.current.startOfDay(for: endDate)

            // Allow 1-day gaps for rest days (intelligent streak calculation)
            var gapDays = 0
            let maxGapDays = 2

            for workout in workouts {
                guard let completedDate = workout.completedDate else { continue }
                let workoutDay = Calendar.current.startOfDay(for: completedDate)

                let daysDiff = Calendar.current.dateComponents([.day], from: workoutDay, to: currentDate).day ?? 0

                if daysDiff <= 1 + gapDays {
                    streak += 1
                    currentDate = workoutDay
                    gapDays = 0 // Reset gap counter
                } else if daysDiff <= maxGapDays {
                    gapDays += daysDiff - 1
                    currentDate = workoutDay
                } else {
                    break // Streak broken
                }
            }

            return streak

        } catch {
            AppLogger.error("Failed to calculate workout streak", error: error, category: .data)
            return 0
        }
    }

    /// Analyzes workout patterns for intelligent coaching insights
    private func analyzeWorkoutPatterns(_ workouts: [Workout]) -> WorkoutPatterns {
        guard !workouts.isEmpty else {
            return WorkoutPatterns(
                weeklyVolume: 0,
                muscleGroupBalance: [:],
                intensityTrend: .stable,
                recoveryStatus: .unknown
            )
        }

        // Calculate weekly volume
        let totalVolume = workouts.reduce(into: 0.0) { total, workout in
            total += workout.exercises.reduce(into: 0.0) { exerciseTotal, exercise in
                exerciseTotal += exercise.sets.reduce(into: 0.0) { setTotal, set in
                    let weight = set.completedWeightKg ?? set.targetWeightKg ?? 0
                    let reps = Double(set.completedReps ?? set.targetReps ?? 0)
                    setTotal += (weight * reps)
                }
            }
        }

        // Muscle group distribution
        var muscleGroupCounts: [String: Int] = [:]
        for workout in workouts {
            for exercise in workout.exercises {
                for muscle in exercise.muscleGroups {
                    muscleGroupCounts[muscle, default: 0] += 1
                }
            }
        }

        // Intensity trend analysis
        let intensityTrend: IntensityTrend
        if workouts.count >= 3 {
            let recentAvgRPE = workouts.prefix(3).flatMap { $0.exercises.flatMap { $0.sets } }
                .compactMap { $0.rpe }.reduce(0, +) / Double(max(workouts.prefix(3).flatMap { $0.exercises.flatMap { $0.sets } }.count, 1))

            let olderAvgRPE = workouts.dropFirst(3).flatMap { $0.exercises.flatMap { $0.sets } }
                .compactMap { $0.rpe }.reduce(0, +) / Double(max(workouts.dropFirst(3).flatMap { $0.exercises.flatMap { $0.sets } }.count, 1))

            if recentAvgRPE > olderAvgRPE + 0.5 {
                intensityTrend = .increasing
            } else if recentAvgRPE < olderAvgRPE - 0.5 {
                intensityTrend = .decreasing
            } else {
                intensityTrend = .stable
            }
        } else {
            intensityTrend = .stable
        }

        // Recovery status (simplified heuristic)
        let recoveryStatus: RecoveryStatus
        let daysSinceLastWorkout = workouts.first?.completedDate.map {
            Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0
        } ?? 7

        switch daysSinceLastWorkout {
        case 0...1: recoveryStatus = .active
        case 2...3: recoveryStatus = .recovered
        case 4...7: recoveryStatus = .wellRested
        default: recoveryStatus = .detraining
        }

        return WorkoutPatterns(
            weeklyVolume: totalVolume,
            muscleGroupBalance: muscleGroupCounts,
            intensityTrend: intensityTrend,
            recoveryStatus: recoveryStatus
        )
    }

    private func calculateTrends(
        activity: ActivityMetrics?,
        body: BodyMetrics?,
        sleep: SleepAnalysis.SleepSession?,
        context: ModelContext
    ) -> HealthTrends {
        var weeklyChange: Double?

        do {
            // Defensive programming: Only fetch what we need with proper date bounds
            let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
            
            // Simplified predicate to avoid complex queries
            var descriptor = FetchDescriptor<DailyLog>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            descriptor.fetchLimit = 14
            
            let allLogs = try context.fetch(descriptor)
            
            // Filter in memory to avoid predicate issues
            let logs = allLogs.filter { log in
                log.date >= fourteenDaysAgo && log.steps != nil
            }

            // Bulletproof data validation
            guard logs.count >= 7 else {
                AppLogger.info("Insufficient data for trend calculation: \(logs.count) logs", category: .data)
                return HealthTrends(weeklyActivityChange: nil)
            }

            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

            let recentLogs = logs.filter { $0.date >= sevenDaysAgo }
            let previousLogs = logs.filter { $0.date < sevenDaysAgo }

            let recentSteps = recentLogs.compactMap(\.steps).filter { $0 > 0 }
            let previousSteps = previousLogs.compactMap(\.steps).filter { $0 > 0 }

            guard !recentSteps.isEmpty, !previousSteps.isEmpty else {
                AppLogger.info("No valid step data for trend calculation", category: .data)
                return HealthTrends(weeklyActivityChange: nil)
            }

            let recentAvg = Double(recentSteps.reduce(0, +)) / Double(recentSteps.count)
            let previousAvg = Double(previousSteps.reduce(0, +)) / Double(previousSteps.count)

            guard previousAvg > 0 else {
                AppLogger.info("Previous average is zero, cannot calculate percentage change", category: .data)
                return HealthTrends(weeklyActivityChange: nil)
            }

            weeklyChange = ((recentAvg - previousAvg) / previousAvg) * 100.0

            // Sanity check: Cap extreme values
            if let change = weeklyChange {
                weeklyChange = max(-500.0, min(500.0, change))
            }

        } catch {
            AppLogger.error("Failed to calculate trends", error: error, category: .data)
            // Return safe default instead of crashing
            return HealthTrends(weeklyActivityChange: nil)
        }

        return HealthTrends(weeklyActivityChange: weeklyChange)
    }
}
