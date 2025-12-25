import HealthKit

/// Notification posted when a new workout is detected in HealthKit.
/// AutoSyncManager listens for this to trigger immediate Hevy sync.
extension Notification.Name {
    static let healthKitWorkoutDetected = Notification.Name("healthKitWorkoutDetected")
}

/// In-memory cache for HealthKit queries with TTL support
private actor HealthKitCache {
    struct CachedSnapshot {
        let snapshot: DailyHealthSnapshot
        let timestamp: Date
    }

    private var snapshotCache: [String: CachedSnapshot] = [:]

    private let todayTTL: TimeInterval = 30  // 30 seconds for "today"
    private let historyTTL: TimeInterval = 300  // 5 min for historical

    func getCachedSnapshot(for dateKey: String, isToday: Bool) -> DailyHealthSnapshot? {
        guard let cached = snapshotCache[dateKey] else { return nil }
        let ttl = isToday ? todayTTL : historyTTL
        guard Date().timeIntervalSince(cached.timestamp) < ttl else {
            snapshotCache.removeValue(forKey: dateKey)
            return nil
        }
        return cached.snapshot
    }

    func setCachedSnapshot(_ snapshot: DailyHealthSnapshot, for dateKey: String) {
        snapshotCache[dateKey] = CachedSnapshot(snapshot: snapshot, timestamp: Date())
    }

    func invalidateToday() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayKey = formatter.string(from: Date())
        snapshotCache.removeValue(forKey: todayKey)
    }

    func invalidateAll() {
        snapshotCache.removeAll()
    }
}

actor HealthKitManager {
    // NOTE: Multiple instances are intentional and efficient!
    // Each instance has its own HKHealthStore, allowing parallel queries.
    // Actor isolation would serialize all queries through a singleton.
    // Apple's HealthKit is designed for multiple HKHealthStore instances.

    // Use UserDefaults to track auth request across instances and app launches
    private static let authRequestedKey = "healthKitAuthRequested"

    private let healthStore = HKHealthStore()
    private var isAuthorized = false
    private var workoutObserverQuery: HKObserverQuery?
    private var lastObservedWorkoutDate: Date?
    private let cache = HealthKitCache()

    // MARK: - HealthKit Types

    // Types we can write (nutrition for food logging)
    // Note: HKCorrelationType(.food) requires special entitlements, so we write individual samples
    private let writeTypes: Set<HKSampleType> = [
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryFatTotal)
    ]

    // HealthKit types - comprehensive but realistic (no CGM/BP cuff/power meters)
    private let readTypes: Set<HKObjectType> = [
        // Activity & Movement
        HKQuantityType(.stepCount),
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.distanceCycling),
        HKQuantityType(.distanceSwimming),
        HKQuantityType(.flightsClimbed),
        HKQuantityType(.appleExerciseTime),
        HKQuantityType(.appleMoveTime),
        HKQuantityType(.appleStandTime),

        // Energy
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.basalEnergyBurned),

        // Body Composition
        HKQuantityType(.bodyMass),
        HKQuantityType(.bodyFatPercentage),
        HKQuantityType(.leanBodyMass),
        HKQuantityType(.height),

        // Heart & Cardio (Apple Watch provides all of these)
        HKQuantityType(.heartRate),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.walkingHeartRateAverage),
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.heartRateRecoveryOneMinute),  // HRR - key recovery metric!
        HKQuantityType(.vo2Max),
        HKQuantityType(.oxygenSaturation),

        // Respiratory
        HKQuantityType(.respiratoryRate),

        // Running Metrics (Apple Watch provides these)
        HKQuantityType(.runningStrideLength),
        HKQuantityType(.runningVerticalOscillation),
        HKQuantityType(.runningGroundContactTime),
        HKQuantityType(.runningSpeed),
        HKQuantityType(.walkingSpeed),  // Walking pace for daily mobility

        // Cycling Metrics (basic - no power meter needed)
        HKQuantityType(.cyclingCadence),
        HKQuantityType(.cyclingSpeed),

        // Sleep & Recovery
        HKCategoryType(.sleepAnalysis),

        // Stand hours
        HKCategoryType(.appleStandHour),

        // Workouts
        HKWorkoutType.workoutType()
    ]

    /// Request HealthKit authorization for reading health data and writing nutrition
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        // Skip if already authorized this session
        if isAuthorized {
            return true
        }

        // Skip if we've already requested (persisted across instances and restarts)
        // User must go to Settings to re-request permissions
        if UserDefaults.standard.bool(forKey: Self.authRequestedKey) {
            // Still check actual auth status for at least one type
            let status = healthStore.authorizationStatus(for: HKQuantityType(.bodyMass))
            isAuthorized = (status == .sharingAuthorized)
            return isAuthorized
        }

        // Mark that we've requested (before async call to prevent race)
        UserDefaults.standard.set(true, forKey: Self.authRequestedKey)

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }

    /// Reset the authorization request flag (call from Settings when user wants to re-request)
    static func resetAuthorizationFlag() {
        UserDefaults.standard.removeObject(forKey: authRequestedKey)
    }

    // MARK: - Workout Observer

    /// Start observing HealthKit for new workouts.
    ///
    /// When a workout is saved (from Apple Watch, Hevy, etc.), this posts
    /// a `.healthKitWorkoutDetected` notification that AutoSyncManager listens to
    /// for immediate Hevy sync.
    ///
    /// Call this once at app launch after authorization.
    func startWorkoutObserver() {
        guard workoutObserverQuery == nil else {
            print("[HealthKit] Workout observer already running")
            return
        }

        let workoutType = HKWorkoutType.workoutType()

        // Store the current time as baseline
        lastObservedWorkoutDate = Date()

        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("[HealthKit] Workout observer error: \(error)")
                completionHandler()
                return
            }

            // Check for new workouts since last check
            Task { [weak self] in
                await self?.checkForNewWorkouts()
            }

            completionHandler()
        }

        workoutObserverQuery = query
        healthStore.execute(query)

        // Enable background delivery for workouts
        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
            if success {
                print("[HealthKit] Background workout delivery enabled")
            } else if let error = error {
                print("[HealthKit] Background delivery failed: \(error)")
            }
        }

        print("[HealthKit] Workout observer started")
    }

    /// Stop the workout observer.
    func stopWorkoutObserver() {
        guard let query = workoutObserverQuery else { return }
        healthStore.stop(query)
        workoutObserverQuery = nil
        print("[HealthKit] Workout observer stopped")
    }

    /// Check for workouts newer than our last check and post notification.
    private func checkForNewWorkouts() async {
        guard let lastCheck = lastObservedWorkoutDate else { return }

        let workoutType = HKWorkoutType.workoutType()
        let predicate = HKQuery.predicateForSamples(
            withStart: lastCheck,
            end: Date(),
            options: .strictStartDate
        )

        let newWorkouts = await withCheckedContinuation { (continuation: CheckedContinuation<[HKWorkout], Never>) in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 5,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }

        // Update last check time
        lastObservedWorkoutDate = Date()

        if !newWorkouts.isEmpty {
            print("[HealthKit] Detected \(newWorkouts.count) new workout(s), posting notification")

            // Post notification on main thread
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .healthKitWorkoutDetected,
                    object: nil,
                    userInfo: ["workoutCount": newWorkouts.count]
                )
            }
        }
    }

    /// Get a summary of today's health data for the AI
    func getTodayContext() async -> HealthContext {
        async let steps = fetchTodaySum(.stepCount, unit: .count())
        async let calories = fetchTodaySum(.activeEnergyBurned, unit: .kilocalorie())
        async let weightWithDate = fetchLatestWithDate(.bodyMass, unit: .pound())
        async let restingHRWithDate = fetchLatestWithDate(.restingHeartRate, unit: .count().unitDivided(by: .minute()))
        async let sleepHours = fetchLastNightSleep()
        async let recentWorkouts = fetchRecentWorkouts(days: 7)

        // Await raw values
        let rawSteps = await steps
        let rawCalories = await calories
        let rawWeightData = await weightWithDate
        let rawRestingHRData = await restingHRWithDate
        let rawSleep = await sleepHours
        let workouts = await recentWorkouts

        // Apply hard exclusions and compute quality
        let validatedWeight = validateWeight(rawWeightData?.value)
        let validatedRestingHR = validateRestingHR(rawRestingHRData.map { Int($0.value) })
        let validatedSleep = validateSleep(rawSleep)
        let validatedSteps = validateSteps(Int(rawSteps ?? 0))
        let validatedCalories = validateActiveCalories(Int(rawCalories ?? 0))

        let quality = computeQuality(
            steps: validatedSteps,
            activeCalories: validatedCalories,
            sleep: validatedSleep,
            restingHR: validatedRestingHR,
            hrvMs: nil  // Not fetched in basic context
        )

        return HealthContext(
            steps: validatedSteps,
            activeCalories: validatedCalories,
            weightLbs: validatedWeight,
            weightDate: validatedWeight != nil ? rawWeightData?.date : nil,
            restingHeartRate: validatedRestingHR,
            restingHRDate: validatedRestingHR != nil ? rawRestingHRData?.date : nil,
            sleepHours: validatedSleep,
            recentWorkouts: workouts,
            quality: quality
        )
    }

    // MARK: - Data Quality Validation

    /// Apply hard exclusion to weight (returns nil if physiologically impossible)
    private func validateWeight(_ weight: Double?) -> Double? {
        guard let w = weight else { return nil }
        guard w >= DataQualityThresholds.weightLbsMin,
              w <= DataQualityThresholds.weightLbsMax else {
            return nil  // Hard exclusion
        }
        return w
    }

    /// Apply hard exclusion to body fat percentage
    private func validateBodyFat(_ bodyFat: Double?) -> Double? {
        guard let bf = bodyFat else { return nil }
        guard bf >= DataQualityThresholds.bodyFatPctMin,
              bf <= DataQualityThresholds.bodyFatPctMax else {
            return nil
        }
        return bf
    }

    /// Apply hard exclusion to resting heart rate
    private func validateRestingHR(_ hr: Int?) -> Int? {
        guard let h = hr else { return nil }
        guard h >= DataQualityThresholds.restingHRMin,
              h <= DataQualityThresholds.restingHRMax else {
            return nil
        }
        return h
    }

    /// Apply hard exclusion to HRV
    private func validateHRV(_ hrv: Double?) -> Double? {
        guard let h = hrv else { return nil }
        guard h >= DataQualityThresholds.hrvMsMin,
              h <= DataQualityThresholds.hrvMsMax else {
            return nil
        }
        return h
    }

    /// Apply hard exclusion to sleep hours
    private func validateSleep(_ sleep: Double?) -> Double? {
        guard let s = sleep else { return nil }
        guard s >= DataQualityThresholds.sleepHoursMin,
              s <= DataQualityThresholds.sleepHoursMax else {
            return nil
        }
        return s
    }

    /// Apply hard exclusion to steps
    private func validateSteps(_ steps: Int) -> Int {
        guard steps >= 0, steps <= DataQualityThresholds.stepsMax else {
            return 0  // Reset to 0 if impossible
        }
        return steps
    }

    /// Apply hard exclusion to active calories
    private func validateActiveCalories(_ calories: Int) -> Int {
        guard calories >= 0, calories <= DataQualityThresholds.activeCaloriesMax else {
            return 0
        }
        return calories
    }

    /// Compute quality score and flags based on available data
    private func computeQuality(
        steps: Int,
        activeCalories: Int,
        sleep: Double?,
        restingHR: Int?,
        hrvMs: Double?,
        sleepBreakdown: SleepBreakdown? = nil
    ) -> DataQualityInfo {
        var score: Double = 1.0
        var flags: [String] = []

        // Check for incomplete sleep (watch died mid-sleep pattern)
        if let s = sleep, s > 0, s < 4, sleepBreakdown == nil {
            score -= 0.3
            flags.append("incomplete_sleep")
        } else if sleep == nil {
            score -= 0.2
            flags.append("no_sleep_data")
        }

        // Check for minimal activity (watch likely off for extended period)
        if steps < 500 && activeCalories > 50 {
            score -= 0.1
            flags.append("minimal_activity")
        } else if steps == 0 && activeCalories == 0 {
            score -= 0.2
            flags.append("watch_likely_off")
        }

        // Check for missing critical metrics
        if restingHR == nil {
            score -= 0.1
            flags.append("no_rhr_data")
        }

        if hrvMs == nil {
            score -= 0.1
            flags.append("no_hrv_data")
        }

        // Ensure score stays in valid range
        score = max(0.0, min(1.0, score))

        let isComplete = sleep != nil && restingHR != nil && steps > 0

        return DataQualityInfo(
            overallScore: score,
            flags: flags,
            watchWornEstimate: nil,  // Could be computed from activity patterns
            isComplete: isComplete
        )
    }

    // MARK: - Private Helpers

    private func fetchTodaySum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        await withQueryTimeoutOptional { [healthStore] in
            let type = HKQuantityType(identifier)
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                    let value = result?.sumQuantity()?.doubleValue(for: unit)
                    continuation.resume(returning: value)
                }
                healthStore.execute(query)
            }
        }
    }

    private func fetchLatest(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        await withQueryTimeoutOptional { [healthStore] in
            let type = HKQuantityType(identifier)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                    continuation.resume(returning: value)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Fetch the most recent value with its date for staleness tracking
    private func fetchLatestWithDate(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> (value: Double, date: Date)? {
        await withQueryTimeoutOptional { [healthStore] in
            let type = HKQuantityType(identifier)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: unit)
                        continuation.resume(returning: (value: value, date: sample.endDate))
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
                healthStore.execute(query)
            }
        }
    }

    private func fetchLastNightSleep() async -> Double? {
        // Delegate to the shared implementation for today's date
        return await fetchSleepForNight(endingOn: Date())
    }

    /// Merge overlapping sleep intervals to avoid double-counting from multiple sources
    /// (e.g., Apple Watch + AutoSleep both recording the same sleep session)
    private func mergeOverlappingIntervals(_ samples: [HKCategorySample]) -> Double {
        guard !samples.isEmpty else { return 0 }

        // Sort by start time
        let sorted = samples.sorted { $0.startDate < $1.startDate }

        var mergedIntervals: [(start: Date, end: Date)] = []
        var currentStart = sorted[0].startDate
        var currentEnd = sorted[0].endDate

        for sample in sorted.dropFirst() {
            if sample.startDate <= currentEnd {
                // Overlapping - extend current interval
                currentEnd = max(currentEnd, sample.endDate)
            } else {
                // Non-overlapping - save current and start new
                mergedIntervals.append((currentStart, currentEnd))
                currentStart = sample.startDate
                currentEnd = sample.endDate
            }
        }
        // Don't forget the last interval
        mergedIntervals.append((currentStart, currentEnd))

        // Sum the merged intervals
        return mergedIntervals.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
    }

    private func fetchRecentWorkouts(days: Int) async -> [WorkoutSummary] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                let workouts: [WorkoutSummary] = (samples as? [HKWorkout])?.compactMap { workout -> WorkoutSummary in
                    let caloriesQuantity = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()
                    let calories: Int? = caloriesQuantity.map { Int($0.doubleValue(for: .kilocalorie())) }
                    return WorkoutSummary(
                        type: workout.workoutActivityType.name,
                        date: workout.startDate,
                        durationMinutes: Int(workout.duration / 60),
                        caloriesBurned: calories
                    )
                } ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Public Workout Access

    /// Get recent workouts from HealthKit.
    ///
    /// Used as fallback when Hevy cache is not available.
    func getRecentWorkouts(days: Int = 7) async -> [WorkoutSummary] {
        await fetchRecentWorkouts(days: days)
    }

    // MARK: - Training Day Detection

    /// Check if today is a training day based on HealthKit workouts.
    ///
    /// Returns true if there's a strength training workout logged today,
    /// or if there was one yesterday and it's before noon (might still be recovery).
    ///
    /// - Returns: Tuple with (isTrainingDay, workoutName if applicable)
    func isTrainingDay() async -> (isTraining: Bool, workoutName: String?) {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        // Check today's workouts
        let todayWorkouts = await fetchWorkoutsForDay(startOfToday)
        let strengthWorkout = todayWorkouts.first { workout in
            isStrengthWorkout(workout.type)
        }

        if let workout = strengthWorkout {
            return (true, workout.type)
        }

        // If before noon, also check yesterday (might still be in recovery/high calorie mode)
        let hour = calendar.component(.hour, from: now)
        if hour < 12 {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
            let yesterdayWorkouts = await fetchWorkoutsForDay(yesterday)
            if let workout = yesterdayWorkouts.first(where: { isStrengthWorkout($0.type) }) {
                return (true, "\(workout.type) (yesterday)")
            }
        }

        return (false, nil)
    }

    /// Fetch workouts for a specific day.
    private func fetchWorkoutsForDay(_ date: Date) async -> [WorkoutSummary] {
        let calendar = Calendar.current
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: date)!

        let predicate = HKQuery.predicateForSamples(withStart: date, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                let workouts: [WorkoutSummary] = (samples as? [HKWorkout])?.compactMap { workout in
                    let caloriesQuantity = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()
                    let calories: Int? = caloriesQuantity.map { Int($0.doubleValue(for: .kilocalorie())) }
                    return WorkoutSummary(
                        type: workout.workoutActivityType.name,
                        date: workout.startDate,
                        durationMinutes: Int(workout.duration / 60),
                        caloriesBurned: calories
                    )
                } ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    /// Check if a workout type is considered strength training.
    private func isStrengthWorkout(_ type: String) -> Bool {
        let strengthTypes = [
            "traditional strength training",
            "functional strength training",
            "strength training",
            "cross training",
            "core training",
            "high intensity interval training"
        ]
        return strengthTypes.contains { type.lowercased().contains($0) }
    }

    // MARK: - Extended Data for Insights

    /// Get comprehensive health data for a specific date (for insights sync)
    func getDailySnapshot(for date: Date) async -> DailyHealthSnapshot {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)
        let isToday = calendar.isDateInToday(date)

        // Check cache first
        if let cached = await cache.getCachedSnapshot(for: dateKey, isToday: isToday) {
            return cached
        }

        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Existing metrics
        async let steps = fetchDaySum(.stepCount, unit: .count(), start: startOfDay, end: endOfDay)
        async let calories = fetchDaySum(.activeEnergyBurned, unit: .kilocalorie(), start: startOfDay, end: endOfDay)
        async let weight = fetchDayLatest(.bodyMass, unit: .pound(), start: startOfDay, end: endOfDay)
        async let bodyFat = fetchDayLatest(.bodyFatPercentage, unit: .percent(), start: startOfDay, end: endOfDay)
        async let restingHR = fetchDayLatest(.restingHeartRate, unit: .count().unitDivided(by: .minute()), start: startOfDay, end: endOfDay)
        async let hrv = fetchDayLatest(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: startOfDay, end: endOfDay)
        async let sleepHours = fetchSleepForNight(endingOn: date)

        // Recovery metrics (Phase 1: HealthKit Dashboard Expansion)
        async let sleepBreakdown = getSleepBreakdown(for: date)
        async let sleepOnset = getSleepOnsetMinutes(for: date)
        async let hrvBaseline = getHRVBaseline()

        // Await all raw values
        let rawSteps = await steps
        let rawCalories = await calories
        let rawWeight = await weight
        let rawBodyFat = await bodyFat
        let rawRestingHR = await restingHR
        let hrvValue = await hrv
        let rawSleep = await sleepHours
        let baselineResult = await hrvBaseline
        let breakdownResult = await sleepBreakdown

        // Apply hard exclusions
        let validatedSteps = validateSteps(Int(rawSteps ?? 0))
        let validatedCalories = validateActiveCalories(Int(rawCalories ?? 0))
        let validatedWeight = validateWeight(rawWeight)
        let validatedBodyFat = validateBodyFat(rawBodyFat.map { $0 * 100 })  // Convert to % first
        let validatedRestingHR = validateRestingHR(rawRestingHR.map { Int($0) })
        let validatedHRV = validateHRV(hrvValue)
        let validatedSleep = validateSleep(rawSleep)

        // Compute HRV deviation from baseline
        var hrvDeviationPct: Double? = nil
        if let currentHRV = validatedHRV, let baseline = baselineResult, baseline.isReliable {
            hrvDeviationPct = baseline.percentDeviation(for: currentHRV)
        }

        // Compute sleep stage proportions
        var sleepEfficiency: Double? = nil
        var sleepDeepPct: Double? = nil
        var sleepCorePct: Double? = nil
        var sleepREMPct: Double? = nil

        if let breakdown = breakdownResult, breakdown.totalSleep > 0 {
            sleepEfficiency = breakdown.efficiency / 100.0  // Convert from 0-100 to 0-1
            sleepDeepPct = breakdown.deepSleep / breakdown.totalSleep
            sleepCorePct = breakdown.coreSleep / breakdown.totalSleep
            sleepREMPct = breakdown.remSleep / breakdown.totalSleep
        }

        // Compute quality with sleep breakdown context
        let quality = computeQuality(
            steps: validatedSteps,
            activeCalories: validatedCalories,
            sleep: validatedSleep,
            restingHR: validatedRestingHR,
            hrvMs: validatedHRV,
            sleepBreakdown: breakdownResult
        )

        let snapshot = await DailyHealthSnapshot(
            date: date,
            steps: validatedSteps,
            activeCalories: validatedCalories,
            weightLbs: validatedWeight,
            bodyFatPct: validatedBodyFat,
            sleepHours: validatedSleep,
            restingHR: validatedRestingHR,
            hrvMs: validatedHRV,
            // Recovery metrics
            sleepEfficiency: sleepEfficiency,
            sleepDeepPct: sleepDeepPct,
            sleepCorePct: sleepCorePct,
            sleepREMPct: sleepREMPct,
            sleepOnsetMinutes: await sleepOnset,
            hrvBaselineMs: baselineResult?.mean,
            hrvDeviationPct: hrvDeviationPct,
            quality: quality
        )

        // Cache before returning
        await cache.setCachedSnapshot(snapshot, for: dateKey)
        return snapshot
    }

    /// Get daily snapshots for the last N days (for bulk sync)
    func getRecentSnapshots(days: Int) async -> [DailyHealthSnapshot] {
        var snapshots: [DailyHealthSnapshot] = []
        let calendar = Calendar.current

        for dayOffset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let snapshot = await getDailySnapshot(for: date)
                snapshots.append(snapshot)
            }
        }

        return snapshots
    }

    /// Get weight history for trend analysis
    func getWeightHistory(days: Int) async -> [WeightReading] {
        await withQueryTimeout(default: []) { [healthStore] in
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
            let type = HKQuantityType(.bodyMass)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [WeightReading] = (samples as? [HKQuantitySample])?.map { sample in
                        WeightReading(
                            date: sample.endDate,
                            weightLbs: sample.quantity.doubleValue(for: .pound())
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Get body fat percentage history
    func getBodyFatHistory(days: Int) async -> [BodyFatReading] {
        await withQueryTimeout(default: []) { [healthStore] in
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
            let type = HKQuantityType(.bodyFatPercentage)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [BodyFatReading] = (samples as? [HKQuantitySample])?.map { sample in
                        BodyFatReading(
                            date: sample.endDate,
                            bodyFatPct: sample.quantity.doubleValue(for: .percent()) * 100 // Convert to percentage
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Get lean body mass history
    func getLeanMassHistory(days: Int) async -> [LeanMassReading] {
        await withQueryTimeout(default: []) { [healthStore] in
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
            let type = HKQuantityType(.leanBodyMass)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [LeanMassReading] = (samples as? [HKQuantitySample])?.map { sample in
                        LeanMassReading(
                            date: sample.endDate,
                            leanMassLbs: sample.quantity.doubleValue(for: .pound())
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Get all weight history (no day limit - for "All Time" view)
    func getAllWeightHistory() async -> [WeightReading] {
        await withQueryTimeout(default: [], timeout: 15.0) { [healthStore] in
            let type = HKQuantityType(.bodyMass)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [WeightReading] = (samples as? [HKQuantitySample])?.map { sample in
                        WeightReading(
                            date: sample.endDate,
                            weightLbs: sample.quantity.doubleValue(for: .pound())
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Get all body fat history (no day limit)
    func getAllBodyFatHistory() async -> [BodyFatReading] {
        await withQueryTimeout(default: [], timeout: 15.0) { [healthStore] in
            let type = HKQuantityType(.bodyFatPercentage)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [BodyFatReading] = (samples as? [HKQuantitySample])?.map { sample in
                        BodyFatReading(
                            date: sample.endDate,
                            bodyFatPct: sample.quantity.doubleValue(for: .percent()) * 100
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Get all lean mass history (no day limit)
    func getAllLeanMassHistory() async -> [LeanMassReading] {
        await withQueryTimeout(default: [], timeout: 15.0) { [healthStore] in
            let type = HKQuantityType(.leanBodyMass)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [LeanMassReading] = (samples as? [HKQuantitySample])?.map { sample in
                        LeanMassReading(
                            date: sample.endDate,
                            leanMassLbs: sample.quantity.doubleValue(for: .pound())
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    // MARK: - Recovery & Readiness Metrics

    /// Get HRV history for baseline calculation and trend analysis.
    ///
    /// Returns all HRV readings (SDNN) over the specified period.
    /// Apple Watch typically records 1-2 HRV samples per day during sleep.
    func getHRVHistory(days: Int) async -> [HRVReading] {
        await withQueryTimeout(default: []) { [healthStore] in
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
            let type = HKQuantityType(.heartRateVariabilitySDNN)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [HRVReading] = (samples as? [HKQuantitySample])?.map { sample in
                        HRVReading(
                            date: sample.endDate,
                            hrvMs: sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Calculate HRV baseline from the last 7 days of data.
    ///
    /// Uses the coefficient of variation (CV) method which is more robust than
    /// simple mean comparison. Research shows daily HRV varies 20-30% even when stable,
    /// so comparing to personal baseline is essential.
    ///
    /// - Returns: HRVBaseline with mean, SD, and CV, or nil if insufficient data
    func getHRVBaseline() async -> HRVBaseline? {
        let readings = await getHRVHistory(days: 7)

        guard readings.count >= 3 else { return nil }

        let values = readings.map { $0.hrvMs }
        let mean = values.reduce(0, +) / Double(values.count)

        // Calculate standard deviation
        let sumSquaredDiffs = values.reduce(0) { $0 + pow($1 - mean, 2) }
        let variance = sumSquaredDiffs / Double(values.count)
        let standardDeviation = sqrt(variance)

        // Coefficient of variation (CV = SD / mean)
        let cv = mean > 0 ? standardDeviation / mean : 0

        return HRVBaseline(
            mean: mean,
            standardDeviation: standardDeviation,
            coefficientOfVariation: cv,
            sampleCount: readings.count,
            startDate: readings.first?.date ?? Date(),
            endDate: readings.last?.date ?? Date()
        )
    }

    /// Get extended HRV baseline from the last 14 days for more robust comparison.
    func getExtendedHRVBaseline() async -> HRVBaseline? {
        let readings = await getHRVHistory(days: 14)

        guard readings.count >= 5 else { return nil }

        let values = readings.map { $0.hrvMs }
        let mean = values.reduce(0, +) / Double(values.count)

        let sumSquaredDiffs = values.reduce(0) { $0 + pow($1 - mean, 2) }
        let variance = sumSquaredDiffs / Double(values.count)
        let standardDeviation = sqrt(variance)
        let cv = mean > 0 ? standardDeviation / mean : 0

        return HRVBaseline(
            mean: mean,
            standardDeviation: standardDeviation,
            coefficientOfVariation: cv,
            sampleCount: readings.count,
            startDate: readings.first?.date ?? Date(),
            endDate: readings.last?.date ?? Date()
        )
    }

    /// Get Heart Rate Recovery history for fitness trend analysis.
    ///
    /// HRR is measured 1 minute after workout ends. Higher is better:
    /// - Poor: < 20 bpm
    /// - OK: 20-30 bpm
    /// - Good: 30-40 bpm
    /// - Excellent: > 40 bpm
    ///
    /// This is a fitness/adaptation marker (improves over weeks of training),
    /// NOT a daily readiness indicator.
    func getHRRecoveryHistory(days: Int) async -> [HRRecoveryReading] {
        await withQueryTimeout(default: []) { [healthStore] in
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
            let type = HKQuantityType(.heartRateRecoveryOneMinute)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [HRRecoveryReading] = (samples as? [HKQuantitySample])?.map { sample in
                        HRRecoveryReading(
                            date: sample.endDate,
                            recoveryBpm: sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    // MARK: - VO2max History

    /// Get VO2max history for cardiorespiratory fitness tracking.
    /// Note: Apple Watch estimates VO2max from outdoor walking/running with GPS.
    func getVO2maxHistory(days: Int) async -> [VO2maxReading] {
        await withQueryTimeout(default: []) { [healthStore] in
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
            let type = HKQuantityType(.vo2Max)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [VO2maxReading] = (samples as? [HKQuantitySample])?.map { sample in
                        VO2maxReading(
                            date: sample.endDate,
                            vo2max: sample.quantity.doubleValue(for: HKUnit(from: "ml/kg*min"))
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Get all VO2max history (no day limit - for "All Time" view)
    func getAllVO2maxHistory() async -> [VO2maxReading] {
        await withQueryTimeout(default: [], timeout: 15.0) { [healthStore] in
            let type = HKQuantityType(.vo2Max)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [VO2maxReading] = (samples as? [HKQuantitySample])?.map { sample in
                        VO2maxReading(
                            date: sample.endDate,
                            vo2max: sample.quantity.doubleValue(for: HKUnit(from: "ml/kg*min"))
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Get resting heart rate history for baseline and trend analysis.
    func getRestingHRHistory(days: Int) async -> [(date: Date, bpm: Double)] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let type = HKQuantityType(.restingHeartRate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                let readings: [(date: Date, bpm: Double)] = (samples as? [HKQuantitySample])?.map { sample in
                    (
                        date: sample.endDate,
                        bpm: sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                    )
                } ?? []
                continuation.resume(returning: readings)
            }
            healthStore.execute(query)
        }
    }

    /// Get resting heart rate history for specified days as typed readings
    func getRestingHRHistoryAsReadings(days: Int) async -> [RestingHRReading] {
        await withQueryTimeout(default: []) { [healthStore] in
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
            let type = HKQuantityType(.restingHeartRate)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [RestingHRReading] = (samples as? [HKQuantitySample])?.map { sample in
                        RestingHRReading(
                            date: sample.endDate,
                            bpm: sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Get all resting heart rate history (no day limit - for "All Time" view)
    func getAllRestingHRHistory() async -> [RestingHRReading] {
        await withQueryTimeout(default: [], timeout: 15.0) { [healthStore] in
            let type = HKQuantityType(.restingHeartRate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [RestingHRReading] = (samples as? [HKQuantitySample])?.map { sample in
                        RestingHRReading(
                            date: sample.endDate,
                            bpm: sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    // MARK: - Walking/Running Speed History

    /// Get walking speed history for specified days
    /// NOTE: Walking speed queries can hang on fresh HealthKit authorization
    func getWalkingSpeedHistory(days: Int) async -> [WalkingSpeedReading] {
        await withQueryTimeout(default: []) { [healthStore] in
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
            let type = HKQuantityType(.walkingSpeed)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [WalkingSpeedReading] = (samples as? [HKQuantitySample])?.map { sample in
                        WalkingSpeedReading(
                            date: sample.endDate,
                            metersPerSecond: sample.quantity.doubleValue(for: .meter().unitDivided(by: .second()))
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Get all walking speed history (no day limit)
    /// NOTE: Walking speed queries can hang on fresh HealthKit authorization
    func getAllWalkingSpeedHistory() async -> [WalkingSpeedReading] {
        await withQueryTimeout(default: [], timeout: 15.0) { [healthStore] in
            let type = HKQuantityType(.walkingSpeed)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [WalkingSpeedReading] = (samples as? [HKQuantitySample])?.map { sample in
                        WalkingSpeedReading(
                            date: sample.endDate,
                            metersPerSecond: sample.quantity.doubleValue(for: .meter().unitDivided(by: .second()))
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Get running speed history for specified days
    func getRunningSpeedHistory(days: Int) async -> [RunningSpeedReading] {
        await withQueryTimeout(default: []) { [healthStore] in
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
            let type = HKQuantityType(.runningSpeed)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [RunningSpeedReading] = (samples as? [HKQuantitySample])?.map { sample in
                        RunningSpeedReading(
                            date: sample.endDate,
                            metersPerSecond: sample.quantity.doubleValue(for: .meter().unitDivided(by: .second()))
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    /// Get all running speed history (no day limit)
    func getAllRunningSpeedHistory() async -> [RunningSpeedReading] {
        await withQueryTimeout(default: [], timeout: 15.0) { [healthStore] in
            let type = HKQuantityType(.runningSpeed)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let readings: [RunningSpeedReading] = (samples as? [HKQuantitySample])?.map { sample in
                        RunningSpeedReading(
                            date: sample.endDate,
                            metersPerSecond: sample.quantity.doubleValue(for: .meter().unitDivided(by: .second()))
                        )
                    } ?? []
                    continuation.resume(returning: readings)
                }
                healthStore.execute(query)
            }
        }
    }

    // MARK: - Timeout Protection

    /// Default timeout for HealthKit queries (8 seconds)
    /// Motion/gait metrics can hang indefinitely on fresh authorization
    private let queryTimeout: Double = 8.0

    /// Execute a HealthKit query with timeout protection.
    ///
    /// Some HealthKit queries (especially motion metrics) can hang indefinitely
    /// on fresh authorization. This wrapper ensures queries either complete or
    /// return a default value within the timeout period.
    ///
    /// - Parameters:
    ///   - defaultValue: Value to return if query times out
    ///   - timeout: Timeout in seconds (defaults to 8s)
    ///   - operation: The async query operation to execute
    /// - Returns: The query result, or defaultValue if timeout occurred
    private func withQueryTimeout<T: Sendable>(
        default defaultValue: T,
        timeout: Double? = nil,
        operation: @Sendable @escaping () async -> T
    ) async -> T {
        let timeoutSeconds = timeout ?? queryTimeout

        return await withTaskGroup(of: T.self) { group in
            group.addTask {
                await operation()
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(timeoutSeconds))
                return defaultValue
            }

            // Return first completed result (either query or timeout)
            if let result = await group.next() {
                group.cancelAll()
                return result
            }
            return defaultValue
        }
    }

    /// Execute a HealthKit query with timeout, returning nil on timeout.
    private func withQueryTimeoutOptional<T: Sendable>(
        timeout: Double? = nil,
        operation: @Sendable @escaping () async -> T?
    ) async -> T? {
        await withQueryTimeout(default: nil, timeout: timeout, operation: operation)
    }

    /// Calculate resting HR baseline from last 14 days.
    func getRestingHRBaseline() async -> (mean: Double, standardDeviation: Double, sampleCount: Int)? {
        let readings = await getRestingHRHistory(days: 14)

        guard readings.count >= 5 else { return nil }

        let values = readings.map { $0.bpm }
        let mean = values.reduce(0, +) / Double(values.count)

        let sumSquaredDiffs = values.reduce(0) { $0 + pow($1 - mean, 2) }
        let variance = sumSquaredDiffs / Double(values.count)
        let standardDeviation = sqrt(variance)

        return (mean: mean, standardDeviation: standardDeviation, sampleCount: readings.count)
    }

    /// Get bedtime consistency over the last N days.
    ///
    /// Analyzes the standard deviation of sleep onset times. Research shows
    /// bedtime consistency is the strongest predictor of feeling rested.
    ///
    /// - Stable: < 30 min std dev
    /// - Variable: 30-60 min std dev
    /// - Irregular: > 60 min std dev (social jet lag territory)
    func getBedtimeConsistency(days: Int = 14) async -> BedtimeConsistency? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Filter to sleep onset samples (in bed or first asleep)
                let sleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.inBed.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                ]

                // Group by night (wake-up date) and find earliest start time
                var nightStarts: [Date: Date] = [:]

                for sample in samples where sleepValues.contains(sample.value) {
                    let hour = calendar.component(.hour, from: sample.startDate)
                    // Only consider bedtimes between 6pm and 4am
                    guard hour >= 18 || hour <= 4 else { continue }

                    let wakeDate = calendar.startOfDay(for: sample.endDate)

                    if let existing = nightStarts[wakeDate] {
                        if sample.startDate < existing {
                            nightStarts[wakeDate] = sample.startDate
                        }
                    } else {
                        nightStarts[wakeDate] = sample.startDate
                    }
                }

                guard nightStarts.count >= 3 else {
                    continuation.resume(returning: nil)
                    return
                }

                // Convert to minutes from midnight (normalized)
                var bedtimeMinutes: [Double] = []
                for startTime in nightStarts.values {
                    var hour = calendar.component(.hour, from: startTime)
                    let minute = calendar.component(.minute, from: startTime)

                    // Normalize: times after midnight as 24+
                    if hour < 12 {
                        hour += 24
                    }

                    bedtimeMinutes.append(Double(hour * 60 + minute))
                }

                // Calculate mean and standard deviation
                let mean = bedtimeMinutes.reduce(0, +) / Double(bedtimeMinutes.count)
                let sumSquaredDiffs = bedtimeMinutes.reduce(0) { $0 + pow($1 - mean, 2) }
                let variance = sumSquaredDiffs / Double(bedtimeMinutes.count)
                let standardDeviation = sqrt(variance)

                // Convert mean back to time components
                var avgHour = Int(mean) / 60
                let avgMinute = Int(mean) % 60
                if avgHour >= 24 { avgHour -= 24 }

                var components = DateComponents()
                components.hour = avgHour
                components.minute = avgMinute

                let consistency = BedtimeConsistency(
                    averageBedtime: components,
                    standardDeviationMinutes: standardDeviation,
                    sampleCount: nightStarts.count
                )

                continuation.resume(returning: consistency)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Extended Private Helpers

    private func fetchDaySum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        await withQueryTimeoutOptional { [healthStore] in
            let type = HKQuantityType(identifier)
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                    let value = result?.sumQuantity()?.doubleValue(for: unit)
                    continuation.resume(returning: value)
                }
                healthStore.execute(query)
            }
        }
    }

    private func fetchDayLatest(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        await withQueryTimeoutOptional { [healthStore] in
            let type = HKQuantityType(identifier)
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                    continuation.resume(returning: value)
                }
                healthStore.execute(query)
            }
        }
    }

    private func fetchSleepForNight(endingOn date: Date) async -> Double? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current

        // For "sleep ending on date", we want sleep where you woke up on that morning.
        // Query a window that captures the typical sleep session (6pm previous day to 6pm today)
        // then filter to samples where endDate falls on the target date.
        // Extended to 6pm to capture late sleepers and unusual schedules.
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Query window: 6pm previous day to 6pm today (full 24 hours, captures all patterns)
        let queryStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay)!  // 6pm previous day
        let queryEnd = calendar.date(byAdding: .hour, value: 18, to: startOfDay)!    // 6pm today

        let predicate = HKQuery.predicateForSamples(withStart: queryStart, end: queryEnd, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [startOfDay, endOfDay] _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                ]

                // Filter to only asleep samples that ended on the target date
                // This ensures we count "last night's sleep" correctly
                let asleepSamples = samples.filter { sample in
                    guard asleepValues.contains(sample.value) else { return false }
                    // Only include samples where endDate is on the target date
                    return sample.endDate >= startOfDay && sample.endDate < endOfDay
                }

                // Merge overlapping intervals to avoid double-counting from multiple sources
                let totalSeconds = self.mergeOverlappingIntervals(asleepSamples)

                let hours = totalSeconds / 3600.0
                continuation.resume(returning: hours > 0 ? hours : nil)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Sleep Stage Breakdown

    /// Get detailed sleep stage breakdown for a specific night.
    ///
    /// Returns time spent in each sleep stage: REM, deep, core, plus awake time and total in bed.
    /// - Parameter date: The date to get sleep breakdown for (sleep ending on this date's morning)
    /// - Returns: SleepBreakdown with all stage durations, or nil if no data
    func getSleepBreakdown(for date: Date) async -> SleepBreakdown? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current

        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Query window: 6pm previous day to 6pm today
        let queryStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay)!
        let queryEnd = calendar.date(byAdding: .hour, value: 18, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: queryStart, end: queryEnd, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [self, startOfDay, endOfDay] _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Filter to samples ending on target date
                let relevantSamples = samples.filter { sample in
                    sample.endDate >= startOfDay && sample.endDate < endOfDay
                }

                guard !relevantSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Categorize by sleep stage
                var inBedSamples: [HKCategorySample] = []
                var remSamples: [HKCategorySample] = []
                var deepSamples: [HKCategorySample] = []
                var coreSamples: [HKCategorySample] = []
                var awakeSamples: [HKCategorySample] = []

                for sample in relevantSamples {
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.inBed.rawValue:
                        inBedSamples.append(sample)
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        remSamples.append(sample)
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deepSamples.append(sample)
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        coreSamples.append(sample)
                    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        // Treat unspecified as core sleep
                        coreSamples.append(sample)
                    case HKCategoryValueSleepAnalysis.awake.rawValue:
                        awakeSamples.append(sample)
                    default:
                        break
                    }
                }

                // Calculate durations (merging overlaps)
                let remHours = self.mergeOverlappingIntervals(remSamples) / 3600.0
                let deepHours = self.mergeOverlappingIntervals(deepSamples) / 3600.0
                let coreHours = self.mergeOverlappingIntervals(coreSamples) / 3600.0
                let awakeHours = self.mergeOverlappingIntervals(awakeSamples) / 3600.0

                // Total sleep = sum of all asleep stages
                let totalSleep = remHours + deepHours + coreHours

                // Time in bed: either from explicit inBed samples, or infer from sleep session span
                var timeInBed: Double
                if !inBedSamples.isEmpty {
                    timeInBed = self.mergeOverlappingIntervals(inBedSamples) / 3600.0
                } else {
                    // Infer from total span of sleep samples
                    let allSleepSamples = remSamples + deepSamples + coreSamples + awakeSamples
                    if let earliest = allSleepSamples.min(by: { $0.startDate < $1.startDate }),
                       let latest = allSleepSamples.max(by: { $0.endDate < $1.endDate }) {
                        timeInBed = latest.endDate.timeIntervalSince(earliest.startDate) / 3600.0
                    } else {
                        timeInBed = totalSleep + awakeHours
                    }
                }

                // Ensure time in bed is at least as large as sleep + awake
                timeInBed = max(timeInBed, totalSleep + awakeHours)

                let breakdown = SleepBreakdown(
                    date: date,
                    timeInBed: timeInBed,
                    totalSleep: totalSleep,
                    remSleep: remHours,
                    deepSleep: deepHours,
                    coreSleep: coreHours,
                    awakeTime: awakeHours
                )

                continuation.resume(returning: breakdown)
            }
            healthStore.execute(query)
        }
    }

    /// Get sleep breakdown for the last N nights.
    func getRecentSleepBreakdowns(nights: Int = 7) async -> [SleepBreakdown] {
        var breakdowns: [SleepBreakdown] = []
        let calendar = Calendar.current

        for dayOffset in 0..<nights {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                if let breakdown = await getSleepBreakdown(for: date) {
                    breakdowns.append(breakdown)
                }
            }
        }

        return breakdowns.reversed()  // Oldest first
    }

    // MARK: - Bedtime Detection

    /// Get the user's typical bedtime by analyzing their sleep history.
    /// Returns the average start time of sleep sessions over the past 14 days.
    func getTypicalBedtime() async -> DateComponents? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -14, to: Date())!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Filter to "in bed" or first asleep sample of each night
                let inBedValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.inBed.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                ]

                // Group samples by the night they belong to (date of wake-up)
                var nightStarts: [Date: Date] = [:] // [wakeDate: earliestStartTime]

                for sample in samples where inBedValues.contains(sample.value) {
                    // Only consider sleep sessions starting between 6pm and 4am
                    let hour = calendar.component(.hour, from: sample.startDate)
                    guard hour >= 18 || hour <= 4 else { continue }

                    // Determine which "night" this belongs to
                    let wakeDate = calendar.startOfDay(for: sample.endDate)

                    if let existing = nightStarts[wakeDate] {
                        // Keep the earliest start time for this night
                        if sample.startDate < existing {
                            nightStarts[wakeDate] = sample.startDate
                        }
                    } else {
                        nightStarts[wakeDate] = sample.startDate
                    }
                }

                guard !nightStarts.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Calculate average bedtime (as minutes from midnight)
                var totalMinutes = 0
                for startTime in nightStarts.values {
                    var hour = calendar.component(.hour, from: startTime)
                    let minute = calendar.component(.minute, from: startTime)

                    // Normalize: treat times after midnight as 24+
                    if hour < 12 {
                        hour += 24
                    }

                    totalMinutes += hour * 60 + minute
                }

                let avgMinutes = totalMinutes / nightStarts.count

                // Convert back to hour/minute (handling wrap around midnight)
                var avgHour = avgMinutes / 60
                let avgMinute = avgMinutes % 60

                if avgHour >= 24 {
                    avgHour -= 24
                }

                var components = DateComponents()
                components.hour = avgHour
                components.minute = avgMinute

                continuation.resume(returning: components)
            }
            healthStore.execute(query)
        }
    }

    /// Get sleep onset time for a specific night as minutes from midnight.
    ///
    /// Returns negative values for times before midnight (e.g., -120 = 10pm),
    /// positive values for times after midnight (e.g., 60 = 1am).
    func getSleepOnsetMinutes(for date: Date) async -> Int? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current

        // Sleep for a given date = sleep that ENDS on that date's morning
        // So we look for samples ending between midnight and noon
        let startOfDay = calendar.startOfDay(for: date)
        let noon = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!

        // Look back to 6pm previous day for start time
        let lookbackStart = calendar.date(byAdding: .hour, value: -30, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: lookbackStart, end: noon, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let inBedValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.inBed.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                ]

                // Find earliest sleep sample that ends on this date (the night's sleep onset)
                let nightSamples = samples.filter { sample in
                    guard inBedValues.contains(sample.value) else { return false }
                    // Ends on the target date
                    let endsOnDate = calendar.isDate(sample.endDate, inSameDayAs: date) ||
                                     (sample.endDate > startOfDay && sample.endDate < noon)
                    return endsOnDate
                }

                guard let earliest = nightSamples.min(by: { $0.startDate < $1.startDate }) else {
                    continuation.resume(returning: nil)
                    return
                }

                // Calculate minutes from midnight
                let previousMidnight = calendar.startOfDay(for: date)
                let minutesFromMidnight = Int(earliest.startDate.timeIntervalSince(previousMidnight) / 60)

                continuation.resume(returning: minutesFromMidnight)
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - Data Quality

/// Hard exclusion thresholds - values outside these ranges are physiologically impossible
/// and indicate sensor error, data corruption, or measurement artifacts.
enum DataQualityThresholds {
    // Sleep
    static let sleepHoursMin: Double = 0
    static let sleepHoursMax: Double = 16  // Nobody sleeps 16+ hours without medical condition

    // Heart Rate Variability (SDNN in milliseconds)
    static let hrvMsMin: Double = 5
    static let hrvMsMax: Double = 300

    // Resting Heart Rate
    static let restingHRMin: Int = 25
    static let restingHRMax: Int = 120

    // Activity
    static let stepsMax: Int = 100_000      // ~50 miles of walking
    static let activeCaloriesMax: Int = 10_000

    // Body Composition
    static let weightLbsMin: Double = 50
    static let weightLbsMax: Double = 700
    static let bodyFatPctMin: Double = 3
    static let bodyFatPctMax: Double = 60

    // Population defaults for cold start (before 14-day personal baseline)
    static let populationHRVRange: ClosedRange<Double> = 40...60
    static let populationRHRRange: ClosedRange<Int> = 55...75
    static let populationSleepRange: ClosedRange<Double> = 6.5...8.5
}

/// Quality information for health data, used to flag incomplete or suspicious readings.
/// Computed at the iOS level and propagated to both Gemini (local) and Claude (server) contexts.
struct DataQualityInfo: Sendable, Codable {
    /// Overall quality score from 0.0 (bad) to 1.0 (complete/valid)
    let overallScore: Double

    /// Human-readable flags describing data quality issues
    let flags: [String]

    /// Estimated hours the watch was worn (if detectable)
    let watchWornEstimate: Double?

    /// Whether all expected metrics are present with valid values
    let isComplete: Bool

    /// Perfect quality - all data present and valid
    static let perfect = DataQualityInfo(
        overallScore: 1.0,
        flags: [],
        watchWornEstimate: nil,
        isComplete: true
    )

    /// No data available
    static let noData = DataQualityInfo(
        overallScore: 0.0,
        flags: ["no_data"],
        watchWornEstimate: nil,
        isComplete: false
    )

    /// Format flags for LLM context injection
    func contextNote() -> String? {
        guard !flags.isEmpty else { return nil }
        let formatted = flags.map { flag in
            // Convert snake_case flags to readable text
            flag.replacingOccurrences(of: "_", with: " ")
        }.joined(separator: ", ")
        return "[Data quality note: \(formatted)]"
    }
}

// MARK: - Data Models

struct HealthContext: Sendable {
    let steps: Int
    let activeCalories: Int
    let weightLbs: Double?
    let weightDate: Date?
    let restingHeartRate: Int?
    let restingHRDate: Date?
    let sleepHours: Double?
    let recentWorkouts: [WorkoutSummary]

    /// Data quality assessment for this context
    let quality: DataQualityInfo

    init(
        steps: Int,
        activeCalories: Int,
        weightLbs: Double?,
        weightDate: Date? = nil,
        restingHeartRate: Int?,
        restingHRDate: Date? = nil,
        sleepHours: Double?,
        recentWorkouts: [WorkoutSummary],
        quality: DataQualityInfo = .perfect
    ) {
        self.steps = steps
        self.activeCalories = activeCalories
        self.weightLbs = weightLbs
        self.weightDate = weightDate
        self.restingHeartRate = restingHeartRate
        self.restingHRDate = restingHRDate
        self.sleepHours = sleepHours
        self.recentWorkouts = recentWorkouts
        self.quality = quality
    }

    /// Convert to dictionary for API
    func toDictionary() -> [String: String] {
        var dict: [String: String] = [
            "steps_today": "\(steps)",
            "active_calories_today": "\(activeCalories)"
        ]

        if let weight = weightLbs {
            dict["weight_lbs"] = String(format: "%.1f", weight)
            if let date = weightDate {
                dict["weight_date"] = ISO8601DateFormatter().string(from: date)
            }
        }
        if let hr = restingHeartRate {
            dict["resting_heart_rate"] = "\(hr) bpm"
            if let date = restingHRDate {
                dict["resting_hr_date"] = ISO8601DateFormatter().string(from: date)
            }
        }
        if let sleep = sleepHours {
            dict["sleep_last_night"] = String(format: "%.1f hours", sleep)
        }
        if !recentWorkouts.isEmpty {
            let workoutStr = recentWorkouts.prefix(3).map { "\($0.type) (\($0.durationMinutes)min)" }.joined(separator: ", ")
            dict["recent_workouts"] = workoutStr
        }

        return dict
    }

    /// Human-readable summary
    func summary() -> String {
        var parts: [String] = []

        parts.append("\(steps) steps")
        parts.append("\(activeCalories) cal burned")

        if let sleep = sleepHours {
            parts.append(String(format: "%.1fh sleep", sleep))
        }
        if let hr = restingHeartRate {
            parts.append("\(hr) bpm resting HR")
        }
        if !recentWorkouts.isEmpty {
            parts.append("\(recentWorkouts.count) workouts this week")
        }

        return parts.joined(separator: " • ")
    }
}

struct WorkoutSummary: Sendable, Identifiable {
    let id: UUID
    let type: String
    let date: Date
    let durationMinutes: Int
    let caloriesBurned: Int?

    init(type: String, date: Date, durationMinutes: Int, caloriesBurned: Int?) {
        self.id = UUID()
        self.type = type
        self.date = date
        self.durationMinutes = durationMinutes
        self.caloriesBurned = caloriesBurned
    }
}

/// Type alias for clarity in dashboard fallback
typealias HealthKitWorkout = WorkoutSummary

/// Comprehensive daily health snapshot for insights sync
struct DailyHealthSnapshot: Sendable {
    let date: Date
    let steps: Int
    let activeCalories: Int
    let weightLbs: Double?
    let bodyFatPct: Double?
    let sleepHours: Double?
    let restingHR: Int?
    let hrvMs: Double?

    // Recovery metrics (Phase 1: HealthKit Dashboard Expansion)
    let sleepEfficiency: Double?        // 0.0-1.0, time asleep / time in bed
    let sleepDeepPct: Double?           // Proportion of deep sleep (0.0-1.0)
    let sleepCorePct: Double?           // Proportion of core/light sleep (0.0-1.0)
    let sleepREMPct: Double?            // Proportion of REM sleep (0.0-1.0)
    let sleepOnsetMinutes: Int?         // Minutes from midnight (for bedtime tracking)
    let hrvBaselineMs: Double?          // 7-day rolling mean HRV
    let hrvDeviationPct: Double?        // Today's deviation from baseline (%)

    // Data quality assessment
    let quality: DataQualityInfo

    /// Format date as YYYY-MM-DD for API
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

/// Weight reading for history/trend analysis
struct WeightReading: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let weightLbs: Double
}

/// Body fat reading for history
struct BodyFatReading: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let bodyFatPct: Double
}

/// Lean mass reading for history
struct LeanMassReading: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let leanMassLbs: Double
}

/// HRV reading for recovery/readiness analysis
struct HRVReading: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let hrvMs: Double  // SDNN in milliseconds
}

/// Heart Rate Recovery reading (1-min post-exercise)
struct HRRecoveryReading: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let recoveryBpm: Double  // How much HR dropped in first minute
}

/// Resting heart rate reading for long-term cardio fitness trends
struct RestingHRReading: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let bpm: Double
}

/// VO2max reading for cardiorespiratory fitness tracking
/// Note: Apple Watch estimates this from outdoor walking/running with GPS
struct VO2maxReading: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let vo2max: Double  // ml/kg/min

    /// Fitness category based on typical ranges for 30-40 year old male
    var category: VO2maxCategory {
        switch vo2max {
        case ..<35: return .belowAverage
        case 35..<40: return .average
        case 40..<45: return .aboveAverage
        case 45..<50: return .good
        default: return .excellent
        }
    }

    enum VO2maxCategory: String {
        case belowAverage = "Below Average"
        case average = "Average"
        case aboveAverage = "Above Average"
        case good = "Good"
        case excellent = "Excellent"

        var color: String {
            switch self {
            case .belowAverage: return "error"
            case .average: return "warning"
            case .aboveAverage: return "accent"
            case .good: return "success"
            case .excellent: return "success"
            }
        }
    }
}

/// Walking speed reading for cardio/mobility trends (m/s)
struct WalkingSpeedReading: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let metersPerSecond: Double

    /// Convert to minutes per mile (pace format)
    var minutesPerMile: Double {
        guard metersPerSecond > 0 else { return 0 }
        let milesPerSecond = metersPerSecond / 1609.34
        return 1.0 / (milesPerSecond * 60.0)
    }

    /// Convert to mph for easier interpretation
    var mph: Double {
        metersPerSecond * 2.23694
    }
}

/// Running speed reading for fitness trends (m/s)
struct RunningSpeedReading: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let metersPerSecond: Double

    /// Convert to minutes per mile (pace format)
    var minutesPerMile: Double {
        guard metersPerSecond > 0 else { return 0 }
        let milesPerSecond = metersPerSecond / 1609.34
        return 1.0 / (milesPerSecond * 60.0)
    }

    /// Convert to mph for easier interpretation
    var mph: Double {
        metersPerSecond * 2.23694
    }
}

/// HRV baseline with coefficient of variation for personalized comparison
struct HRVBaseline: Sendable {
    let mean: Double           // 7-day rolling mean (ms)
    let standardDeviation: Double
    let coefficientOfVariation: Double  // CV = SD / mean
    let sampleCount: Int
    let startDate: Date
    let endDate: Date

    /// Whether we have enough data for a reliable baseline (need 5+ readings)
    var isReliable: Bool { sampleCount >= 5 }

    /// Calculate z-score for a given HRV value vs this baseline
    func zScore(for hrv: Double) -> Double {
        guard standardDeviation > 0 else { return 0 }
        return (hrv - mean) / standardDeviation
    }

    /// Interpret deviation as percentage above/below baseline
    func percentDeviation(for hrv: Double) -> Double {
        guard mean > 0 else { return 0 }
        return ((hrv - mean) / mean) * 100
    }
}

/// Bedtime consistency metrics
struct BedtimeConsistency: Sendable {
    let averageBedtime: DateComponents  // Average time of sleep onset
    let standardDeviationMinutes: Double  // How variable bedtime is
    let sampleCount: Int

    /// Consistency category based on std dev
    var category: ConsistencyCategory {
        switch standardDeviationMinutes {
        case 0..<30: return .stable
        case 30..<60: return .variable
        default: return .irregular
        }
    }

    enum ConsistencyCategory: String, Sendable {
        case stable = "Stable"
        case variable = "Variable"
        case irregular = "Irregular"
    }
}

/// Sleep stage breakdown for detailed sleep analysis
struct SleepBreakdown: Sendable {
    let date: Date
    let timeInBed: Double      // Total time in bed (hours)
    let totalSleep: Double     // Total actual sleep (hours)
    let remSleep: Double       // REM stage (hours)
    let deepSleep: Double      // Deep/slow-wave sleep (hours)
    let coreSleep: Double      // Core/light sleep (hours)
    let awakeTime: Double      // Time awake in bed (hours)

    /// Sleep efficiency percentage (actual sleep / time in bed)
    var efficiency: Double {
        guard timeInBed > 0 else { return 0 }
        return (totalSleep / timeInBed) * 100
    }

    /// Quality score based on deep + REM proportion (0-100)
    var qualityScore: Double {
        guard totalSleep > 0 else { return 0 }
        // Ideal: ~20-25% REM, ~15-20% deep = ~40% high quality
        let highQualityPct = (remSleep + deepSleep) / totalSleep
        // Score: 40%+ = 100, 20% = 50, 0% = 0
        return min(100, highQualityPct * 250)
    }
}

/// Combined body composition data point
struct BodyCompositionReading: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let weightLbs: Double?
    let bodyFatPct: Double?
    let leanMassLbs: Double?
}

// MARK: - HealthKitManager Nutrition Extension

extension HealthKitManager {
    // MARK: - Nutrition Writing

    /// Metadata key for linking HealthKit entries to SwiftData entries
    private static var airFitEntryIDKey: String { "AirFitEntryID" }

    /// Save a nutrition entry to HealthKit as individual dietary samples.
    ///
    /// Creates separate HKQuantitySample for each macro (calories, protein, carbs, fat).
    /// The entry's UUID is stored in metadata for later update/delete operations.
    ///
    /// Note: We use individual samples instead of HKCorrelation because Food correlation
    /// requires a special entitlement from Apple. The metadata linking approach allows
    /// us to track and delete our own samples.
    ///
    /// - Parameter entry: NutritionEntry to save
    /// - Throws: HealthKitError if save fails
    func saveNutritionEntry(_ entry: NutritionEntry) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        // Metadata to link all samples back to this entry
        let metadata: [String: Any] = [
            Self.airFitEntryIDKey: entry.id.uuidString,
            HKMetadataKeyFoodType: entry.name
        ]

        // Create samples for each macro
        var samples: [HKSample] = []

        // Calories
        if entry.calories > 0 {
            let calorieType = HKQuantityType(.dietaryEnergyConsumed)
            let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: Double(entry.calories))
            let calorieSample = HKQuantitySample(
                type: calorieType,
                quantity: calorieQuantity,
                start: entry.timestamp,
                end: entry.timestamp,
                metadata: metadata
            )
            samples.append(calorieSample)
        }

        // Protein
        if entry.protein > 0 {
            let proteinType = HKQuantityType(.dietaryProtein)
            let proteinQuantity = HKQuantity(unit: .gram(), doubleValue: Double(entry.protein))
            let proteinSample = HKQuantitySample(
                type: proteinType,
                quantity: proteinQuantity,
                start: entry.timestamp,
                end: entry.timestamp,
                metadata: metadata
            )
            samples.append(proteinSample)
        }

        // Carbs
        if entry.carbs > 0 {
            let carbType = HKQuantityType(.dietaryCarbohydrates)
            let carbQuantity = HKQuantity(unit: .gram(), doubleValue: Double(entry.carbs))
            let carbSample = HKQuantitySample(
                type: carbType,
                quantity: carbQuantity,
                start: entry.timestamp,
                end: entry.timestamp,
                metadata: metadata
            )
            samples.append(carbSample)
        }

        // Fat
        if entry.fat > 0 {
            let fatType = HKQuantityType(.dietaryFatTotal)
            let fatQuantity = HKQuantity(unit: .gram(), doubleValue: Double(entry.fat))
            let fatSample = HKQuantitySample(
                type: fatType,
                quantity: fatQuantity,
                start: entry.timestamp,
                end: entry.timestamp,
                metadata: metadata
            )
            samples.append(fatSample)
        }

        guard !samples.isEmpty else {
            print("[HealthKit] No nutrition data to save")
            return
        }

        // Save samples with metadata linking them to this entry
        try await healthStore.save(samples)
        print("[HealthKit] Saved nutrition entry: \(entry.name) (\(entry.calories) cal, \(samples.count) samples)")
    }

    /// Update an existing nutrition entry in HealthKit.
    ///
    /// Deletes the old correlation and creates a new one with updated values.
    /// Uses the AirFitEntryID metadata to find the existing entry.
    ///
    /// - Parameter entry: Updated NutritionEntry
    /// - Throws: HealthKitError if update fails
    func updateNutritionEntry(_ entry: NutritionEntry) async throws {
        // Delete existing and save new
        try await deleteNutritionEntry(id: entry.id)
        try await saveNutritionEntry(entry)
        print("[HealthKit] Updated nutrition entry: \(entry.name)")
    }

    /// Update a nutrition entry in HealthKit using a Sendable snapshot.
    /// Use this overload when crossing actor boundaries (e.g., from @MainActor views).
    func updateNutritionEntry(_ snapshot: NutritionSnapshot) async throws {
        try await deleteNutritionEntry(id: snapshot.id)
        try await saveNutritionEntry(snapshot)
        print("[HealthKit] Updated nutrition entry: \(snapshot.name)")
    }

    /// Save a nutrition entry to HealthKit using a Sendable snapshot.
    /// Use this overload when crossing actor boundaries (e.g., from @MainActor views).
    func saveNutritionEntry(_ snapshot: NutritionSnapshot) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let metadata: [String: Any] = [
            Self.airFitEntryIDKey: snapshot.id.uuidString,
            HKMetadataKeyFoodType: snapshot.name
        ]

        var samples: [HKSample] = []

        if snapshot.calories > 0 {
            let calorieType = HKQuantityType(.dietaryEnergyConsumed)
            let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: Double(snapshot.calories))
            let calorieSample = HKQuantitySample(
                type: calorieType,
                quantity: calorieQuantity,
                start: snapshot.timestamp,
                end: snapshot.timestamp,
                metadata: metadata
            )
            samples.append(calorieSample)
        }

        if snapshot.protein > 0 {
            let proteinType = HKQuantityType(.dietaryProtein)
            let proteinQuantity = HKQuantity(unit: .gram(), doubleValue: Double(snapshot.protein))
            let proteinSample = HKQuantitySample(
                type: proteinType,
                quantity: proteinQuantity,
                start: snapshot.timestamp,
                end: snapshot.timestamp,
                metadata: metadata
            )
            samples.append(proteinSample)
        }

        if snapshot.carbs > 0 {
            let carbsType = HKQuantityType(.dietaryCarbohydrates)
            let carbsQuantity = HKQuantity(unit: .gram(), doubleValue: Double(snapshot.carbs))
            let carbsSample = HKQuantitySample(
                type: carbsType,
                quantity: carbsQuantity,
                start: snapshot.timestamp,
                end: snapshot.timestamp,
                metadata: metadata
            )
            samples.append(carbsSample)
        }

        if snapshot.fat > 0 {
            let fatType = HKQuantityType(.dietaryFatTotal)
            let fatQuantity = HKQuantity(unit: .gram(), doubleValue: Double(snapshot.fat))
            let fatSample = HKQuantitySample(
                type: fatType,
                quantity: fatQuantity,
                start: snapshot.timestamp,
                end: snapshot.timestamp,
                metadata: metadata
            )
            samples.append(fatSample)
        }

        guard !samples.isEmpty else {
            print("[HealthKit] No samples to save for: \(snapshot.name)")
            return
        }

        try await healthStore.save(samples)
        print("[HealthKit] Saved \(samples.count) samples for: \(snapshot.name)")
    }

    /// Delete a nutrition entry from HealthKit.
    ///
    /// Finds all samples with matching AirFitEntryID metadata and deletes them.
    /// Only samples created by AirFit can be deleted (HealthKit enforces this).
    ///
    /// - Parameter id: UUID of the NutritionEntry to delete
    func deleteNutritionEntry(id: UUID) async throws {
        let entryIDString = id.uuidString

        // Query each dietary type for samples with our metadata
        let dietaryTypes: [HKQuantityType] = [
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal)
        ]

        var samplesToDelete: [HKSample] = []

        for type in dietaryTypes {
            let samples = try await querySamplesWithEntryID(type: type, entryID: entryIDString)
            samplesToDelete.append(contentsOf: samples)
        }

        if samplesToDelete.isEmpty {
            print("[HealthKit] No samples found for entry: \(id)")
            return
        }

        // Delete all matching samples
        for sample in samplesToDelete {
            try await healthStore.delete(sample)
        }

        print("[HealthKit] Deleted \(samplesToDelete.count) samples for entry: \(id)")
    }

    /// Query samples with a specific AirFit entry ID
    private func querySamplesWithEntryID(type: HKQuantityType, entryID: String) async throws -> [HKSample] {
        return try await withCheckedThrowingContinuation { continuation in
            // We need to query and filter by metadata
            // Unfortunately, HKQuery doesn't support direct metadata filtering,
            // so we query recent samples and filter in memory
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

            // Query samples from today (most common case for edits/deletes)
            let predicate = HKQuery.predicateForSamples(
                withStart: calendar.date(byAdding: .day, value: -7, to: startOfToday),
                end: endOfToday,
                options: .strictStartDate
            )

            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                // Filter to samples with matching metadata
                let matchingSamples = (samples ?? []).filter { sample in
                    guard let metadata = sample.metadata,
                          let sampleEntryID = metadata[Self.airFitEntryIDKey] as? String else {
                        return false
                    }
                    return sampleEntryID == entryID
                }

                continuation.resume(returning: matchingSamples)
            }

            healthStore.execute(query)
        }
    }

    /// Check if an entry exists in HealthKit.
    ///
    /// Queries for any sample with matching AirFitEntryID metadata.
    ///
    /// - Parameter id: UUID of the NutritionEntry
    /// - Returns: True if samples with this entry ID exist
    func nutritionEntryExists(id: UUID) async -> Bool {
        let entryIDString = id.uuidString

        // Check just one type (calories) for efficiency
        do {
            let samples = try await querySamplesWithEntryID(
                type: HKQuantityType(.dietaryEnergyConsumed),
                entryID: entryIDString
            )
            return !samples.isEmpty
        } catch {
            print("[HealthKit] Failed to check if entry exists: \(error)")
            return false
        }
    }

    /// Sync all local nutrition entries to HealthKit.
    ///
    /// Checks each entry and saves if not already present.
    /// Used for initial sync or recovery.
    ///
    /// - Parameter entries: Array of NutritionEntry to sync
    /// - Returns: Number of entries synced
    func syncNutritionEntries(_ entries: [NutritionEntry]) async -> Int {
        var syncedCount = 0

        for entry in entries {
            let exists = await nutritionEntryExists(id: entry.id)
            if !exists {
                do {
                    try await saveNutritionEntry(entry)
                    syncedCount += 1
                } catch {
                    print("[HealthKit] Failed to sync entry \(entry.name): \(error)")
                }
            }
        }

        print("[HealthKit] Synced \(syncedCount) nutrition entries to HealthKit")
        return syncedCount
    }
}

// MARK: - HealthKit Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case saveFailed(Error)
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .saveFailed(let error):
            return "Failed to save to HealthKit: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "HealthKit query failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Workout Type Names

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Training"
        case .coreTraining: return "Core Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .pilates: return "Pilates"
        case .dance: return "Dance"
        case .cooldown: return "Cooldown"
        case .crossTraining: return "Cross Training"
        default: return "Workout"
        }
    }
}
