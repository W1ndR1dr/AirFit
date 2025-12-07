import HealthKit

actor HealthKitManager {
    private let healthStore = HKHealthStore()
    private var isAuthorized = false

    // Types we want to read
    private let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.bodyMass),
        HKQuantityType(.heartRate),
        HKQuantityType(.restingHeartRate),
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
        let sleepType = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current

        // Look for sleep ending today (last night's sleep)
        let endOfToday = calendar.startOfDay(for: Date()).addingTimeInterval(86400)
        let startOfYesterday = calendar.startOfDay(for: Date().addingTimeInterval(-86400))
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: endOfToday, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Sum up asleep time (exclude inBed, awake)
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                ]

                let totalSeconds = samples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                let hours = totalSeconds / 3600.0
                continuation.resume(returning: hours > 0 ? hours : nil)
            }
            healthStore.execute(query)
        }
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
