//
//  ContextAssembler.swift
//  AirFit
//
//  Refactored for: • Real progress reporting • Resilient error handling • Intelligent
//  in-memory caching with TTL • True concurrency where safe • Partial-results return
//  • Battery-friendly HealthKit usage (no redundant queries) 
//

import Foundation
import SwiftData
import os.log

/// Aggregates health and environmental data into `HealthContextSnapshot` instances.
@MainActor
final class ContextAssembler: ContextAssemblerProtocol, ServiceProtocol {
    // MARK: - Public (ServiceProtocol)
    nonisolated let serviceIdentifier = "context-assembler"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { MainActor.assumeIsolated { _isConfigured } }

    // MARK: - Dependencies
    private let healthKitManager: HealthKitManaging
    private let goalService: GoalServiceProtocol?
    private let muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol?
    private let strengthProgressionService: StrengthProgressionServiceProtocol?
    // Future: private let weatherService: WeatherServiceProtocol
    
    // MARK: - Caching
    private let cache = HealthContextCache()

    init(
        healthKitManager: HealthKitManaging,
        goalService: GoalServiceProtocol? = nil,
        muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol? = nil,
        strengthProgressionService: StrengthProgressionServiceProtocol? = nil
    ) {
        self.healthKitManager = healthKitManager
        self.goalService = goalService
        self.muscleGroupVolumeService = muscleGroupVolumeService
        self.strengthProgressionService = strengthProgressionService
    }

    // MARK: - Public API
    
    /// Original convenience entry-point (no explicit progress / caching flags).  
    /// Equivalent to calling `assembleContext(forceRefresh:false,progressReporter:nil)`.
    func assembleContext() async -> HealthContextSnapshot {
        await assembleContext(forceRefresh: false, progressReporter: nil)
    }
    
    /// **Enhanced** API — caller may supply a live progress reporter and choose to bypass cache.
    ///
    /// - Parameters:
    ///   - forceRefresh: Set `true` to ignore cached values and fetch everything again.
    ///   - progressReporter: Optional reporter that receives granular `HealthDataLoadingProgress`.
    ///
    /// The method **never** throws — any underlying failures are captured and logged,
    /// but the returned `HealthContextSnapshot` is _always_ populated with whatever
    /// data could be acquired (nil fields fall back to the empty-value structs).
    func assembleContext(
        forceRefresh: Bool = false,
        progressReporter: HealthDataLoadingProgressReporting?
    ) async -> HealthContextSnapshot {
        // Stage 1: Initialising
        await progressReporter?.reportProgress(.init(stage: .initializing))

        // MARK: Stage 2–5 ───────── Concurrent HealthKit fetches ───────────────

        // Kick off all HealthKit calls immediately so they can overlap;
        // Many will queue internally on the HealthKit background thread pool.
        async let activityMetrics: ActivityMetrics? = {
            await progressReporter?.reportProgress(.init(stage: .fetchingActivity, subProgress: 0.0))
            do {
                if let cached = await cache.activity(forced: forceRefresh) { return cached }
                let result = try await healthKitManager.fetchTodayActivityMetrics()
                await cache.setActivity(result)
                return result
            } catch {
                AppLogger.error("Activity fetch failed", error: error, category: .health)
                return nil
            }
        }()

        async let heartMetrics: HeartHealthMetrics? = {
            await progressReporter?.reportProgress(.init(stage: .fetchingHeart, subProgress: 0.0))
            do {
                if let cached = await cache.heart(forced: forceRefresh) { return cached }
                let result = try await healthKitManager.fetchHeartHealthMetrics()
                await cache.setHeart(result)
                return result
            } catch {
                AppLogger.error("Heart fetch failed", error: error, category: .health)
                return nil
            }
        }()

        async let bodyMetrics: BodyMetrics? = {
            await progressReporter?.reportProgress(.init(stage: .fetchingBody, subProgress: 0.0))
            do {
                if let cached = await cache.body(forced: forceRefresh) { return cached }
                let result = try await healthKitManager.fetchLatestBodyMetrics()
                await cache.setBody(result)
                return result
            } catch {
                AppLogger.error("Body fetch failed", error: error, category: .health)
                return nil
            }
        }()

        async let sleepSession: SleepAnalysis.SleepSession? = {
            await progressReporter?.reportProgress(.init(stage: .fetchingSleep, subProgress: 0.0))
            do {
                if let cached = await cache.sleep(forced: forceRefresh) { return cached }
                let result = try await healthKitManager.fetchLastNightSleep()
                await cache.setSleep(result)
                return result
            } catch {
                AppLogger.error("Sleep fetch failed", error: error, category: .health)
                return nil
            }
        }()

        // Subjective & SwiftData work can proceed on a background context
        let (subjectiveData, appSpecificCtx) = await { () async -> (SubjectiveData, AppSpecificContext) in
            do {
                let container = try ModelContainer(for: User.self)
                let context = ModelContext(container)
                context.autosaveEnabled = false
                
                let subjective = await self.fetchSubjectiveData(using: context)
                let appContext = await self.createMockAppContext(using: context)
                return (subjective, appContext)
            } catch {
                AppLogger.error("Failed to create ModelContext", error: error, category: .data)
                return (SubjectiveData(), AppSpecificContext())
            }
        }()

        // MARK: Stage 6 ───────── Wait for metrics, compute trends ────────────
        await progressReporter?.reportProgress(.init(stage: .analyzingTrends, subProgress: 0.0))

        // Collect all async-lets
        let (
            activity,
            heart,
            body,
            sleep
        ) = await (
            activityMetrics,
            heartMetrics,
            bodyMetrics,
            sleepSession
        )

        // Calculate trends with a fresh context
        let trends: HealthTrends = await { () async -> HealthTrends in
            do {
                let container = try ModelContainer(for: User.self)
                let context = ModelContext(container)
                context.autosaveEnabled = false
                return await calculateTrends(
                    activity: activity,
                    body: body,
                    sleep: sleep,
                    context: context
                )
            } catch {
                AppLogger.error("Failed to create context for trends", error: error, category: .data)
                return HealthTrends()
            }
        }()

        // MARK: Stage 7 ───────── Assemble snapshot ──────────────────────
        await progressReporter?.reportProgress(.init(stage: .assemblingContext))

        let snapshot = HealthContextSnapshot(
            subjectiveData: subjectiveData,
            environment: createMockEnvironmentContext(),
            activity: activity ?? ActivityMetrics(),
            sleep: SleepAnalysis(lastNight: sleep),
            heartHealth: heart ?? HeartHealthMetrics(),
            body: body ?? BodyMetrics(),
            appContext: appSpecificCtx,
            trends: trends
        )

        // MARK: Stage 8 ───────── Complete & cache full snapshot ────────────
        await cache.setSnapshot(snapshot)
        await progressReporter?.reportProgress(.complete)


        return snapshot
    }

    // MARK: - ServiceProtocol
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .app)
    }

    func reset() async {
        _isConfigured = false
        await cache.clearAll()
        AppLogger.info("\(serviceIdentifier) reset", category: .app)
    }

    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: _isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: _isConfigured ? nil : "Service not configured",
            metadata: [:]
        )
    }

    // MARK: - Private Helpers
    // The individual fetch methods have been integrated into the main assembleContext method
    // for better concurrency and error handling

    private func fetchSubjectiveData(using context: ModelContext) async -> SubjectiveData {
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
        var goalsContext: GoalsContext?
        var strengthContext: StrengthContext?

        do {
            // Meal context (unchanged)
            var mealDescriptor = FetchDescriptor<FoodEntry>(
                sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
            )
            mealDescriptor.fetchLimit = 1

            // Fetch meals more efficiently
            let meals = try context.fetch(mealDescriptor)

            if let meal = meals.first {
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

            // Fetch user for strength context
            let userDescriptor = FetchDescriptor<User>(
                sortBy: [SortDescriptor(\.lastActiveDate, order: .reverse)]
            )
            let users = try context.fetch(userDescriptor)

            if let currentUser = users.first {
                // Assemble strength context
                strengthContext = await assembleStrengthContext(
                    user: currentUser,
                    context: context
                )
            }

            // Fetch goals context if goalService is available
            if let goalService = self.goalService {
                // Get current user ID - for now, using a fetch
                let userDescriptor = FetchDescriptor<User>(
                    sortBy: [SortDescriptor(\.lastActiveDate, order: .reverse)]
                )

                // Fetch user without detached task for simple query
                let users = try context.fetch(userDescriptor)

                if let currentUser = users.first {
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
            lastCoachInteraction: nil,
            upcomingWorkout: upcomingWorkout,
            currentStreak: currentStreak,
            workoutContext: workoutContext,
            goalsContext: goalsContext,
            strengthContext: strengthContext
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
            allWorkoutsDescriptor.fetchLimit = 20 // Reduced limit for faster loading

            // Fetch workouts without detached task
            let allWorkouts = try context.fetch(allWorkoutsDescriptor)

            // Filter recent completed workouts in memory
            let recentWorkouts = allWorkouts
                .filter { workout in
                    guard let completedDate = workout.completedDate else { return false }
                    return completedDate >= sevenDaysAgo && completedDate <= now
                }
                .prefix(5)  // Reduce to 5 recent workouts for context

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
                .prefix(2)  // Only 2 upcoming workouts needed

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
            descriptor.fetchLimit = 30  // Limit for streak calculation

            // Fetch workouts for streak calculation
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
            // Fetch logs without detached task
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

    // MARK: - ServiceProtocol Methods (removed duplicates - already defined above)

    // MARK: - Strength Context Assembly

    /// Assembles comprehensive strength context for AI workout generation
    private func assembleStrengthContext(
        user: User,
        context: ModelContext
    ) async -> StrengthContext? {
        do {
            // Use injected services, return nil if not available
            guard let strengthService = strengthProgressionService,
                  let volumeService = muscleGroupVolumeService else {
                AppLogger.warning("Strength services not available for context assembly", category: .data)
                return nil
            }

            // Fetch recent PRs (last 5)
            let allPRs = try await strengthService.getAllCurrentPRs(user: user)
            let recentRecords = user.strengthRecords
                .sorted { $0.recordedDate > $1.recordedDate }
                .prefix(5)

            var recentPRs: [ExercisePR] = []
            for record in recentRecords {
                // Calculate improvement if possible
                let history = try await strengthService.getStrengthHistory(
                    exercise: record.exerciseName,
                    user: user,
                    days: 90
                )

                var improvement: Double?
                if history.count >= 2 {
                    let previousPR = history[history.count - 2].oneRepMax
                    improvement = ((record.oneRepMax - previousPR) / previousPR) * 100
                }

                recentPRs.append(ExercisePR(
                    exercise: record.exerciseName,
                    oneRepMax: record.oneRepMax,
                    date: record.recordedDate,
                    improvement: improvement,
                    actualWeight: record.actualWeight,
                    actualReps: record.actualReps
                ))
            }

            // Get top 10 exercises by 1RM
            var topExercises: [ExerciseStrength] = []
            let sortedPRs = allPRs.sorted { $0.value > $1.value }.prefix(10)

            for (exercise, oneRM) in sortedPRs {
                let trend = try await strengthService.getStrengthTrend(
                    exercise: exercise,
                    user: user
                )

                // Count recent sets for this exercise
                let recentSets = user.workouts
                    .filter { workout in
                        guard let completedDate = workout.completedDate else { return false }
                        return completedDate >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                    }
                    .flatMap { $0.exercises }
                    .filter { $0.name.lowercased() == exercise.lowercased() }
                    .flatMap { $0.sets }
                    .filter { $0.isCompleted }
                    .count

                // Find last update date
                let lastRecord = user.strengthRecords
                    .filter { $0.exerciseName.lowercased() == exercise.lowercased() }
                    .max { $0.recordedDate < $1.recordedDate }

                topExercises.append(ExerciseStrength(
                    exercise: exercise,
                    currentOneRM: oneRM,
                    lastUpdated: lastRecord?.recordedDate ?? Date(),
                    trend: trend,
                    recentSets: recentSets
                ))
            }

            // Get muscle group volumes
            let volumeData = try await volumeService.getWeeklyVolumes(for: user)

            // Convert to MuscleVolume for context
            let muscleVolumes = volumeData.map { volume in
                MuscleVolume(
                    muscleGroup: volume.name,
                    completedSets: volume.sets,
                    targetSets: volume.target
                )
            }

            // Get strength trends for key exercises
            var strengthTrends: [String: StrengthTrend] = [:]
            for exercise in topExercises.prefix(5) {
                let trend = try await strengthService.getStrengthTrend(
                    exercise: exercise.exercise,
                    user: user
                )
                strengthTrends[exercise.exercise] = trend
            }

            return StrengthContext(
                recentPRs: recentPRs,
                topExercises: topExercises,
                muscleGroupVolumes: muscleVolumes,
                volumeTargets: user.muscleGroupTargets,
                strengthTrends: strengthTrends
            )

        } catch {
            AppLogger.error("Failed to assemble strength context", error: error, category: .data)
            return nil
        }
    }
}

// MARK: - Lightweight In-Memory Cache (actor) ──────────────────────────────────────

private actor HealthContextCache {

    /// Generic cache entry with expiry
    struct Entry<T: Sendable>: Sendable {
        let value: T
        let expiry: Date
    }

    // TTLs
    private let shortTTL: TimeInterval = 5 * 60      // 5 min
    private let bodyTTL : TimeInterval = 60 * 60     // 1 hr

    // Buckets
    private var activityEntry : Entry<ActivityMetrics>?
    private var heartEntry    : Entry<HeartHealthMetrics>?
    private var bodyEntry     : Entry<BodyMetrics>?
    private var sleepEntry    : Entry<SleepAnalysis.SleepSession>?
    private var snapshotEntry : Entry<HealthContextSnapshot>?

    // MARK: Fetch helpers
    func activity(forced: Bool) -> ActivityMetrics? {
        guard !forced, let entry = activityEntry, entry.expiry > Date() else { return nil }
        return entry.value
    }
    func heart(forced: Bool) -> HeartHealthMetrics? {
        guard !forced, let entry = heartEntry, entry.expiry > Date() else { return nil }
        return entry.value
    }
    func body(forced: Bool) -> BodyMetrics? {
        guard !forced, let entry = bodyEntry, entry.expiry > Date() else { return nil }
        return entry.value
    }
    func sleep(forced: Bool) -> SleepAnalysis.SleepSession? {
        guard !forced, let entry = sleepEntry, entry.expiry > Date() else { return nil }
        return entry.value
    }
    func snapshot(forced: Bool) -> HealthContextSnapshot? {
        guard !forced, let entry = snapshotEntry, entry.expiry > Date() else { return nil }
        return entry.value
    }

    // MARK: Store helpers
    func setActivity(_ value: ActivityMetrics) {
        activityEntry = .init(value: value, expiry: Date().addingTimeInterval(shortTTL))
    }
    func setHeart(_ value: HeartHealthMetrics) {
        heartEntry = .init(value: value, expiry: Date().addingTimeInterval(shortTTL))
    }
    func setBody(_ value: BodyMetrics) {
        bodyEntry = .init(value: value, expiry: Date().addingTimeInterval(bodyTTL))
    }
    func setSleep(_ value: SleepAnalysis.SleepSession?) {
        guard let value else { return }
        sleepEntry = .init(value: value, expiry: Date().addingTimeInterval(shortTTL))
    }
    func setSnapshot(_ value: HealthContextSnapshot) {
        snapshotEntry = .init(value: value, expiry: Date().addingTimeInterval(shortTTL))
    }

    /// Wipe everything (called on logout or service reset)
    func clearAll() {
        activityEntry = nil
        heartEntry    = nil
        bodyEntry     = nil
        sleepEntry    = nil
        snapshotEntry = nil
    }
}
