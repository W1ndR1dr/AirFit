import Foundation
import SwiftData

/// Aggregates health and environmental data into `HealthContextSnapshot` instances.
@MainActor
final class ContextAssembler: ContextAssemblerProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "context-assembler"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }
    
    private let healthKitManager: HealthKitManaging
    private let goalService: GoalServiceProtocol?
    // Future: private let weatherService: WeatherServiceProtocol

    init(
        healthKitManager: HealthKitManaging,
        goalService: GoalServiceProtocol? = nil
    ) {
        self.healthKitManager = healthKitManager
        self.goalService = goalService
    }
    
    /// Simplified context assembly for dashboard
    func assembleContext() async -> HealthContextSnapshot {
        let modelContext = try? ModelContainer(for: User.self).mainContext
        if let context = modelContext {
            return await assembleSnapshot(modelContext: context)
        } else {
            // Return minimal context if no model context available
            return HealthContextSnapshot(
                subjectiveData: SubjectiveData(),
                environment: createMockEnvironmentContext(),
                activity: ActivityMetrics(),
                sleep: SleepAnalysis(lastNight: nil),
                heartHealth: HeartHealthMetrics(),
                body: BodyMetrics(),
                appContext: AppSpecificContext(),
                trends: HealthTrends(weeklyActivityChange: nil)
            )
        }
    }

    /// Creates a `HealthContextSnapshot` using data from HealthKit and SwiftData models.
    /// - Parameter modelContext: The `ModelContext` used to fetch app data.
    func assembleSnapshot(modelContext: ModelContext) async -> HealthContextSnapshot {
        // Fetch all async data concurrently
        async let activityMetrics = fetchActivityMetrics()
        async let heartMetrics = fetchHeartHealthMetrics()
        async let bodyMetrics = fetchBodyMetrics()
        async let sleepSession = fetchSleepSession()

        // Fetch subjective data safely on main actor
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

        let trends = await calculateTrends(
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
        return await MainActor.run {
            do {
        let todayStart = Calendar.current.startOfDay(for: Date())
                
                // Use a simpler, safer approach to avoid SwiftData predicate issues
                let descriptor = FetchDescriptor<DailyLog>(
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                
                let allLogs = try context.fetch(descriptor)
                
                // Filter in memory to avoid complex predicate issues
                if let todayLog = allLogs.first(where: { log in
                    Calendar.current.isDate(log.date, inSameDayAs: todayStart)
                }) {
                return SubjectiveData(
                        energyLevel: todayLog.subjectiveEnergyLevel,
                    mood: nil, // Mood tracking TBD
                        stress: todayLog.stressLevel,
                    motivation: nil,
                    soreness: nil,
                        notes: todayLog.notes
                )
            }
                
                return SubjectiveData()
                
        } catch {
            AppLogger.error("Failed to fetch today's DailyLog", error: error, category: .data)
                return SubjectiveData()
            }
        }
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
        let _ = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now

        var lastMealTime: Date?
        var lastMealSummary: String?
        var activeWorkoutName: String?
        var upcomingWorkout: String?
        var currentStreak: Int?
        var workoutContext: WorkoutContext?
        var goalsContext: GoalsContext?

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

            // Fetch goals context if goalService is available
            if let goalService = self.goalService {
                // Get current user ID - for now, using a fetch
                let userDescriptor = FetchDescriptor<User>(
                    sortBy: [SortDescriptor(\.lastActiveDate, order: .reverse)]
                )
                if let currentUser = try context.fetch(userDescriptor).first {
                    goalsContext = try await goalService.getGoalsContext(for: currentUser.id)
                }
            }

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
            workoutContext: workoutContext,
            goalsContext: goalsContext
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
            let recentWorkouts = allWorkouts
                .filter { workout in
                    guard let completedDate = workout.completedDate else { return false }
                    return completedDate >= sevenDaysAgo && completedDate <= now
                }
                .prefix(10)

            // Find active workout (no completed date)
            let activeWorkout = allWorkouts.first { workout in
                workout.completedDate == nil
            }

            // Find upcoming workouts
            let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: now) ?? now
            let upcomingWorkouts = allWorkouts
                .filter { workout in
                    guard workout.completedDate == nil,
                          let plannedDate = workout.plannedDate else { return false }
                    return plannedDate > now && plannedDate <= threeDaysFromNow
                }
                .sorted { ($0.plannedDate ?? Date()) < ($1.plannedDate ?? Date()) }
                .prefix(3)

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

        // Build exercise performance data
        var exercisePerformance: [String: ExercisePerformance] = [:]
        for exercise in workout.exercises.prefix(3) {
            let exerciseVolume = exercise.sets.reduce(into: 0.0) { total, set in
                let weight = set.completedWeightKg ?? set.targetWeightKg ?? 0
                let reps = Double(set.completedReps ?? set.targetReps ?? 0)
                total += (weight * reps)
            }
            
            let topSet = exercise.sets.max { set1, set2 in
                let vol1 = (set1.completedWeightKg ?? set1.targetWeightKg ?? 0) * Double(set1.completedReps ?? set1.targetReps ?? 0)
                let vol2 = (set2.completedWeightKg ?? set2.targetWeightKg ?? 0) * Double(set2.completedReps ?? set2.targetReps ?? 0)
                return vol1 < vol2
            }
            
            let topSetPerformance = topSet.map { set in
                SetPerformance(
                    weight: set.completedWeightKg ?? set.targetWeightKg ?? 0,
                    reps: set.completedReps ?? set.targetReps ?? 0,
                    volume: (set.completedWeightKg ?? set.targetWeightKg ?? 0) * Double(set.completedReps ?? set.targetReps ?? 0)
                )
            }
            
            exercisePerformance[exercise.name] = ExercisePerformance(
                exerciseName: exercise.name,
                volumeTotal: exerciseVolume,
                topSet: topSetPerformance,
                contextSummary: "\(exercise.sets.count) sets, top: \(topSetPerformance?.weight ?? 0)kg x \(topSetPerformance?.reps ?? 0)"
            )
        }

        return CompactWorkout(
            name: workout.name,
            type: workout.workoutTypeEnum?.displayName ?? "Unknown",
            date: workout.completedDate ?? workout.plannedDate ?? Date(),
            duration: workout.durationSeconds,
            exerciseCount: workout.exercises.count,
            totalVolume: totalVolume,
            avgRPE: avgRPE.isFinite ? avgRPE : nil,
            muscleGroups: muscleGroups,
            keyExercises: workout.exercises.prefix(3).map { $0.name }, // Top 3 exercises
            exercisePerformance: exercisePerformance
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
            let recentAvgRPE = workouts.prefix(3)
                .flatMap { $0.exercises.flatMap { $0.sets } }
                .compactMap { $0.rpe }
                .reduce(0, +) / Double(max(workouts.prefix(3).flatMap { $0.exercises.flatMap { $0.sets } }.count, 1))

            let olderAvgRPE = workouts.dropFirst(3)
                .flatMap { $0.exercises.flatMap { $0.sets } }
                .compactMap { $0.rpe }
                .reduce(0, +) / Double(max(workouts.dropFirst(3).flatMap { $0.exercises.flatMap { $0.sets } }.count, 1))

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
    ) async -> HealthTrends {
        // Ensure all SwiftData operations happen on the main actor
        return await MainActor.run {
            var weeklyChange: Double?

            // Defensive programming: Only fetch what we need with proper date bounds
            let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()

            // Create a simple, safe descriptor
            let descriptor = FetchDescriptor<DailyLog>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )

            // Fetch with error handling
            let allLogs: [DailyLog]
            do {
                allLogs = try context.fetch(descriptor)
            } catch {
                AppLogger.error("Failed to fetch DailyLog for trends", error: error, category: .data)
                return HealthTrends(weeklyActivityChange: nil)
            }

            // Filter in memory to avoid predicate issues
            let logs = allLogs.filter { log in
                guard let steps = log.steps, steps > 0 else { return false }
                return log.date >= fourteenDaysAgo
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

            return HealthTrends(weeklyActivityChange: weeklyChange)
        }
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
                "hasHealthKitManager": "true",
                "hasGoalService": "\(goalService != nil)"
            ]
        )
    }
}
