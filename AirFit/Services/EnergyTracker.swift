import Foundation
import HealthKit
import Observation

// Note: HKWorkoutActivityType.name extension is in HealthKitManager.swift

/// Real-time energy tracking with observer queries for live TDEE updates
/// Includes predictive end-of-day TDEE based on historical patterns
/// Now with training vs rest day differentiation for better accuracy
@Observable
@MainActor
final class EnergyTracker {
    private let healthStore = HKHealthStore()

    // Real-time values (updated when Apple Watch syncs)
    var todayTDEE: Int = 0
    var todayActiveCalories: Int = 0
    var todayBasalCalories: Int = 0
    var isAuthorized = false
    var lastUpdated: Date?

    // Training day detection
    var isTrainingDay: Bool = false
    var todayWorkoutName: String?

    // Predictive model outputs
    var projectedEndOfDayTDEE: Int = 0
    var projectedConfidence: Double = 0.0  // 0.0 to 1.0
    var projectedNet: Int = 0  // Projected surplus/deficit (requires calories in)

    // Separate patterns for training vs rest days (cumulative % by hour 0-23)
    private var trainingDayPattern: [Double] = Array(repeating: 0, count: 24)
    private var restDayPattern: [Double] = Array(repeating: 0, count: 24)
    private var patternLoaded = false

    private let activeEnergyType = HKQuantityType(.activeEnergyBurned)
    private let basalEnergyType = HKQuantityType(.basalEnergyBurned)
    private let workoutType = HKObjectType.workoutType()

    init() {
        Task {
            await setup()
        }
    }

    private func setup() async {
        #if targetEnvironment(simulator)
        // Use mock data in simulator (no Apple Watch)
        loadMockData()
        return
        #endif

        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToRead: Set<HKObjectType> = [activeEnergyType, basalEnergyType, workoutType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            await checkTodayTrainingStatus()
            await loadHistoricalPatterns()
            await fetchTodayEnergy()
            setupObservers()
        } catch {
            print("EnergyTracker auth failed: \(error)")
        }
    }

    /// Check if today has any workouts recorded
    private func checkTodayTrainingStatus() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let workouts = await fetchWorkouts(predicate: predicate)
        isTrainingDay = !workouts.isEmpty
        todayWorkoutName = workouts.first?.workoutActivityType.name
    }

    private func fetchWorkouts(predicate: NSPredicate) async -> [HKWorkout] {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    /// Mock data for simulator testing
    private func loadMockData() {
        isAuthorized = true

        // Simulate training day (50% chance)
        isTrainingDay = Bool.random()
        todayWorkoutName = isTrainingDay ? "Strength Training" : nil

        // Simulate data based on current time of day
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        let hourFraction = Double(currentHour) / 24.0

        // Training days have higher active calories
        let expectedDailyActive = isTrainingDay ? 800 : 500
        let expectedDailyBasal = 1850

        todayActiveCalories = Int(Double(expectedDailyActive) * hourFraction * Double.random(in: 0.9...1.1))
        todayBasalCalories = Int(Double(expectedDailyBasal) * hourFraction)
        todayTDEE = todayActiveCalories + todayBasalCalories
        lastUpdated = Date()

        // Training day pattern (gym in evening, higher burn)
        trainingDayPattern = [
            0.00, 0.04, 0.08, 0.12, 0.16, 0.20,  // 12am-5am (sleeping)
            0.24, 0.28, 0.33, 0.38, 0.43, 0.48,  // 6am-11am (waking)
            0.52, 0.56, 0.60, 0.64, 0.68, 0.74,  // 12pm-5pm (afternoon)
            0.82, 0.90, 0.95, 0.98, 0.99, 1.00   // 6pm-11pm (gym + evening)
        ]

        // Rest day pattern (more even distribution)
        restDayPattern = [
            0.00, 0.04, 0.08, 0.12, 0.16, 0.20,  // 12am-5am (sleeping)
            0.25, 0.30, 0.36, 0.42, 0.48, 0.54,  // 6am-11am (waking)
            0.60, 0.65, 0.70, 0.75, 0.80, 0.84,  // 12pm-5pm (afternoon)
            0.88, 0.92, 0.95, 0.97, 0.99, 1.00   // 6pm-11pm (evening)
        ]
        patternLoaded = true

        // Update projection with mock data
        updateProjection()

        // Simulate periodic updates
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.todayActiveCalories += Int.random(in: 5...15)
                self?.todayBasalCalories += Int.random(in: 10...20)
                self?.todayTDEE = (self?.todayActiveCalories ?? 0) + (self?.todayBasalCalories ?? 0)
                self?.lastUpdated = Date()
                self?.updateProjection()
            }
        }
    }

    /// Fetch current energy totals and update projections
    func fetchTodayEnergy() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        // Fetch sequentially to avoid Swift 6 data race issues
        let active = await fetchSum(for: activeEnergyType, predicate: predicate)
        let basal = await fetchSum(for: basalEnergyType, predicate: predicate)

        todayActiveCalories = Int(active)
        todayBasalCalories = Int(basal)
        todayTDEE = todayActiveCalories + todayBasalCalories
        lastUpdated = Date()

        // Update projections
        updateProjection()
    }

    /// Calculate projected end-of-day TDEE and confidence
    /// Uses historical pattern: if by 2pm you've burned X% of your typical daily TDEE,
    /// project final = current / X%
    /// Now uses separate patterns for training vs rest days
    func updateProjection(caloriesConsumed: Int = 0) {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())

        // Confidence increases as day progresses (0% at midnight, 100% at 11pm)
        // Training days get slightly higher confidence (more predictable pattern)
        let baseConfidence = Double(currentHour) / 22.0
        projectedConfidence = min(1.0, isTrainingDay ? baseConfidence * 1.1 : baseConfidence)

        // If we don't have pattern data yet, use current TDEE as projection
        guard patternLoaded, currentHour > 0 else {
            projectedEndOfDayTDEE = todayTDEE
            projectedNet = caloriesConsumed - projectedEndOfDayTDEE
            return
        }

        // Select the appropriate pattern based on training day status
        let pattern = isTrainingDay ? trainingDayPattern : restDayPattern
        let expectedPercent = pattern[currentHour]

        // If we've burned more than expected %, we're on track for higher TDEE
        // projection = current / expected%
        if expectedPercent > 0.1 {  // Need at least 10% for meaningful projection
            let projected = Double(todayTDEE) / expectedPercent
            projectedEndOfDayTDEE = Int(projected)
        } else {
            // Too early in day for reliable projection, use simple extrapolation
            // Assume linear burn rate: current * (24 / hoursElapsed)
            let hoursElapsed = max(1, currentHour)
            projectedEndOfDayTDEE = todayTDEE * 24 / hoursElapsed
        }

        // Calculate projected net (surplus/deficit)
        projectedNet = caloriesConsumed - projectedEndOfDayTDEE
    }

    /// Load historical hourly patterns from last 14 days
    /// Separates training days vs rest days for better prediction accuracy
    private func loadHistoricalPatterns() async {
        let calendar = Calendar.current

        // Collect data for each day, categorized by training status
        var trainingDays: [Date: [Double]] = [:]  // Day -> [hourly cumulative %]
        var restDays: [Date: [Double]] = [:]

        // Analyze last 14 days
        for dayOffset in 1...14 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: day)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            // Check if this was a training day
            let workoutPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
            let workouts = await fetchWorkouts(predicate: workoutPredicate)
            let wasTrainingDay = !workouts.isEmpty

            // Get total TDEE for this day
            let energyPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
            let active = await fetchSum(for: activeEnergyType, predicate: energyPredicate)
            let basal = await fetchSum(for: basalEnergyType, predicate: energyPredicate)
            let dayTotal = active + basal

            guard dayTotal > 500 else { continue }  // Skip days with insufficient data

            // Build hourly cumulative pattern for this day
            var hourlyForDay: [Double] = Array(repeating: 0, count: 24)
            for hour in 0..<24 {
                guard let hourEnd = calendar.date(byAdding: .hour, value: hour + 1, to: startOfDay) else { continue }
                let hourPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: hourEnd, options: .strictStartDate)
                let hourActive = await fetchSum(for: activeEnergyType, predicate: hourPredicate)
                let hourBasal = await fetchSum(for: basalEnergyType, predicate: hourPredicate)
                hourlyForDay[hour] = (hourActive + hourBasal) / dayTotal
            }

            // Store in appropriate category
            if wasTrainingDay {
                trainingDays[startOfDay] = hourlyForDay
            } else {
                restDays[startOfDay] = hourlyForDay
            }
        }

        // Average each category's patterns
        trainingDayPattern = averagePattern(from: trainingDays)
        restDayPattern = averagePattern(from: restDays)

        // If one category is empty, use the other as fallback
        if trainingDays.isEmpty { trainingDayPattern = restDayPattern }
        if restDays.isEmpty { restDayPattern = trainingDayPattern }

        patternLoaded = !trainingDays.isEmpty || !restDays.isEmpty
        print("[EnergyTracker] Loaded patterns: \(trainingDays.count) training days, \(restDays.count) rest days")
    }

    private func averagePattern(from days: [Date: [Double]]) -> [Double] {
        guard !days.isEmpty else { return Array(repeating: 0, count: 24) }

        var avgPattern: [Double] = Array(repeating: 0, count: 24)
        let dayCount = Double(days.count)

        for hour in 0..<24 {
            var sum = 0.0
            for (_, hourly) in days {
                sum += hourly[hour]
            }
            avgPattern[hour] = sum / dayCount
        }

        return avgPattern
    }

    private func fetchSum(for type: HKQuantityType, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let sum = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: sum)
            }
            healthStore.execute(query)
        }
    }

    /// Set up observer queries for real-time updates from Apple Watch
    private func setupObservers() {
        // Observer for active energy (exercise calories)
        let activeQuery = HKObserverQuery(sampleType: activeEnergyType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            Task { @MainActor in
                await self?.fetchTodayEnergy()
            }
        }
        healthStore.execute(activeQuery)

        // Observer for basal energy (resting calories)
        let basalQuery = HKObserverQuery(sampleType: basalEnergyType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            Task { @MainActor in
                await self?.fetchTodayEnergy()
            }
        }
        healthStore.execute(basalQuery)
    }
}
