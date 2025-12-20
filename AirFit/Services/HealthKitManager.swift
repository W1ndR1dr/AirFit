import HealthKit

/// Notification posted when a new workout is detected in HealthKit.
/// AutoSyncManager listens for this to trigger immediate Hevy sync.
extension Notification.Name {
    static let healthKitWorkoutDetected = Notification.Name("healthKitWorkoutDetected")
}

actor HealthKitManager {
    private let healthStore = HKHealthStore()
    private var isAuthorized = false
    private var workoutObserverQuery: HKObserverQuery?
    private var lastObservedWorkoutDate: Date?

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

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
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
        async let weight = fetchLatest(.bodyMass, unit: .pound())
        async let restingHR = fetchLatest(.restingHeartRate, unit: .count().unitDivided(by: .minute()))
        async let sleepHours = fetchLastNightSleep()
        async let recentWorkouts = fetchRecentWorkouts(days: 7)

        return await HealthContext(
            steps: Int(steps ?? 0),
            activeCalories: Int(calories ?? 0),
            weightLbs: weight,
            restingHeartRate: restingHR.map { Int($0) },
            sleepHours: sleepHours,
            recentWorkouts: recentWorkouts
        )
    }

    // MARK: - Private Helpers

    private func fetchTodaySum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
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

    private func fetchLatest(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
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
                    let calories: Int? = workout.totalEnergyBurned.map { Int($0.doubleValue(for: .kilocalorie())) }
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
                    let calories: Int? = workout.totalEnergyBurned.map { Int($0.doubleValue(for: .kilocalorie())) }
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
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        async let steps = fetchDaySum(.stepCount, unit: .count(), start: startOfDay, end: endOfDay)
        async let calories = fetchDaySum(.activeEnergyBurned, unit: .kilocalorie(), start: startOfDay, end: endOfDay)
        async let weight = fetchDayLatest(.bodyMass, unit: .pound(), start: startOfDay, end: endOfDay)
        async let bodyFat = fetchDayLatest(.bodyFatPercentage, unit: .percent(), start: startOfDay, end: endOfDay)
        async let restingHR = fetchDayLatest(.restingHeartRate, unit: .count().unitDivided(by: .minute()), start: startOfDay, end: endOfDay)
        async let hrv = fetchDayLatest(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: startOfDay, end: endOfDay)
        async let sleepHours = fetchSleepForNight(endingOn: date)

        return await DailyHealthSnapshot(
            date: date,
            steps: Int(steps ?? 0),
            activeCalories: Int(calories ?? 0),
            weightLbs: weight,
            bodyFatPct: bodyFat.map { $0 * 100 }, // Convert from 0-1 to percentage
            sleepHours: sleepHours,
            restingHR: restingHR.map { Int($0) },
            hrvMs: hrv
        )
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

    /// Get body fat percentage history
    func getBodyFatHistory(days: Int) async -> [BodyFatReading] {
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

    /// Get lean body mass history
    func getLeanMassHistory(days: Int) async -> [LeanMassReading] {
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

    /// Get all weight history (no day limit - for "All Time" view)
    func getAllWeightHistory() async -> [WeightReading] {
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

    /// Get all body fat history (no day limit)
    func getAllBodyFatHistory() async -> [BodyFatReading] {
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

    /// Get all lean mass history (no day limit)
    func getAllLeanMassHistory() async -> [LeanMassReading] {
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

    // MARK: - Extended Private Helpers

    private func fetchDaySum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
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

    private func fetchDayLatest(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
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
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [calendar, startOfDay, endOfDay] _, samples, _ in
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
}

// MARK: - Data Models

struct HealthContext: Sendable {
    let steps: Int
    let activeCalories: Int
    let weightLbs: Double?
    let restingHeartRate: Int?
    let sleepHours: Double?
    let recentWorkouts: [WorkoutSummary]

    /// Convert to dictionary for API
    func toDictionary() -> [String: String] {
        var dict: [String: String] = [
            "steps_today": "\(steps)",
            "active_calories_today": "\(activeCalories)"
        ]

        if let weight = weightLbs {
            dict["weight_lbs"] = String(format: "%.1f", weight)
        }
        if let hr = restingHeartRate {
            dict["resting_heart_rate"] = "\(hr) bpm"
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
