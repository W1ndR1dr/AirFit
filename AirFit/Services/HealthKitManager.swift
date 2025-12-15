import HealthKit

actor HealthKitManager {
    private let healthStore = HKHealthStore()
    private var isAuthorized = false

    // Types we want to read
    private let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.bodyMass),
        HKQuantityType(.bodyFatPercentage),
        HKQuantityType(.leanBodyMass),
        HKQuantityType(.heartRate),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.vo2Max),
        HKCategoryType(.sleepAnalysis),
        HKWorkoutType.workoutType()
    ]

    /// Request HealthKit authorization
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
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
        // Query a window that captures the typical sleep session (6pm previous day to noon today)
        // then filter to samples where endDate falls on the target date.
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Query window: 6pm previous day to noon today (captures most sleep patterns)
        let queryStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay)!  // 6pm previous day
        let queryEnd = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!    // noon today

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

struct WorkoutSummary: Sendable {
    let type: String
    let date: Date
    let durationMinutes: Int
    let caloriesBurned: Int?
}

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

/// Combined body composition data point
struct BodyCompositionReading: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let weightLbs: Double?
    let bodyFatPct: Double?
    let leanMassLbs: Double?
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
