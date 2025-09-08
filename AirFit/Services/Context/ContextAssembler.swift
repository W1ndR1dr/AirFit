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
    private let modelContainer: ModelContainer
    // Future: private let weatherService: WeatherServiceProtocol
    
    // MARK: - Caching
    private let cache = HealthContextCache()

    init(
        healthKitManager: HealthKitManaging,
        goalService: GoalServiceProtocol? = nil,
        muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol? = nil,
        strengthProgressionService: StrengthProgressionServiceProtocol? = nil,
        modelContainer: ModelContainer
    ) {
        self.healthKitManager = healthKitManager
        self.goalService = goalService
        self.muscleGroupVolumeService = muscleGroupVolumeService
        self.strengthProgressionService = strengthProgressionService
        self.modelContainer = modelContainer
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

        // Fast return: if a fresh snapshot exists in cache and we're not forcing, return it immediately
        if let cached = await cache.snapshot(forced: forceRefresh) {
            return cached
        }

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
                let context = ModelContext(modelContainer)
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
                let context = ModelContext(modelContainer)
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

            // Use HealthKit summaries (no local tracking) for workout context
            let hkContext = await assembleWorkoutContextHK(now: now, sevenDaysAgo: sevenDaysAgo)
            workoutContext = hkContext
            activeWorkoutName = hkContext.activeWorkout?.name
            upcomingWorkout = hkContext.upcomingWorkout?.name
            currentStreak = hkContext.streakDays

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
        // Deprecated path (local models removed). Use HealthKit summaries instead.
        return await assembleWorkoutContextHK(now: now, sevenDaysAgo: sevenDaysAgo)
    }

    // MARK: - HealthKit Workout Context (no local tracking)
    private func assembleWorkoutContextHK(now: Date, sevenDaysAgo: Date) async -> WorkoutContext {
        do {
            let workouts = try await healthKitManager.fetchHistoricalWorkouts(from: sevenDaysAgo, to: now)

            // Map to CompactWorkout using available HK data
            let compact: [CompactWorkout] = workouts.suffix(5).map { w in
                CompactWorkout(
                    name: "Workout",
                    type: w.workoutType,
                    date: w.startDate,
                    duration: w.duration,
                    exerciseCount: 0,
                    totalVolume: w.totalEnergyBurned, // use kcal as proxy for volume
                    avgRPE: nil,
                    muscleGroups: [],
                    keyExercises: [],
                    exercisePerformance: [:]
                )
            }

            // Simple streak: consecutive days with workouts ending today
            let calendar = Calendar.current
            let daysWithWorkouts = Set(workouts.map { calendar.startOfDay(for: $0.startDate) })
            var streak = 0
            var cursor = calendar.startOfDay(for: now)
            while streak < 30 { // cap
                if daysWithWorkouts.contains(cursor) {
                    streak += 1
                    cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
                } else {
                    break
                }
            }

            // Weekly volume as sum of kcal for last 7 days
            let weeklyVolume = workouts
                .filter { $0.startDate >= sevenDaysAgo && $0.startDate <= now }
                .reduce(0.0) { $0 + $1.totalEnergyBurned }

            // Basic intensity trend heuristic from avg heart rate deltas (if available)
            let recent = workouts.suffix(3).map { $0.averageHeartRate }
            let older = workouts.dropLast(3).suffix(3).map { $0.averageHeartRate }
            let intensityTrend: IntensityTrend = {
                guard recent.count == 3, older.count == 3 else { return .stable }
                let r = recent.reduce(0, +) / 3.0
                let o = older.reduce(0, +) / 3.0
                if r > o + 2 { return .increasing }
                if r < o - 2 { return .decreasing }
                return .stable
            }()

            // Recovery status by days since last workout
            let daysSinceLast = workouts.sorted { $0.startDate > $1.startDate }.first.map {
                calendar.dateComponents([.day], from: calendar.startOfDay(for: $0.startDate), to: calendar.startOfDay(for: now)).day ?? 7
            } ?? 7
            let recoveryStatus: WorkoutFrequencyStatus = {
                switch daysSinceLast {
                case 0...1: return .active
                case 2...3: return .recovered
                case 4...7: return .wellRested
                default: return .detraining
                }
            }()

            return WorkoutContext(
                recentWorkouts: compact,
                activeWorkout: nil,
                upcomingWorkout: nil,
                plannedWorkouts: [],
                streakDays: streak,
                weeklyVolume: weeklyVolume,
                muscleGroupBalance: [:],
                intensityTrend: intensityTrend,
                recoveryStatus: recoveryStatus
            )
        } catch {
            AppLogger.error("Failed to fetch HealthKit workouts", error: error, category: .health)
            return WorkoutContext()
        }
    }


    /// Calculates current workout streak with intelligent gap handling
    /// TODO: Implement with HealthKit workout data analysis
    private func calculateWorkoutStreak(context: ModelContext, endDate: Date) -> Int { 0 }


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
    /// TODO: Implement with HealthKit strength workout analysis
    private func assembleStrengthContext(
        user: User,
        context: ModelContext
    ) async -> StrengthContext? {
        // Return minimal StrengthContext with empty/default values
        // Local workout tracking has been removed in favor of HealthKit analysis
        return StrengthContext(
            recentPRs: [],
            topExercises: [],
            muscleGroupVolumes: [],
            volumeTargets: [:],
            strengthTrends: [:]
        )
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
