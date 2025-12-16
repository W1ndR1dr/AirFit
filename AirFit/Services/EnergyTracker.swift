import Foundation
import HealthKit
import Observation

/// Real-time energy tracking with observer queries for live TDEE updates
/// Includes predictive end-of-day TDEE based on historical patterns
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

    // Predictive model outputs
    var projectedEndOfDayTDEE: Int = 0
    var projectedConfidence: Double = 0.0  // 0.0 to 1.0
    var projectedNet: Int = 0  // Projected surplus/deficit (requires calories in)

    // Historical hourly pattern (cumulative % of daily TDEE by hour 0-23)
    private var hourlyPattern: [Double] = Array(repeating: 0, count: 24)
    private var patternLoaded = false

    private let activeEnergyType = HKQuantityType(.activeEnergyBurned)
    private let basalEnergyType = HKQuantityType(.basalEnergyBurned)

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

        let typesToRead: Set<HKObjectType> = [activeEnergyType, basalEnergyType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            await loadHistoricalPattern()
            await fetchTodayEnergy()
            setupObservers()
        } catch {
            print("EnergyTracker auth failed: \(error)")
        }
    }

    /// Mock data for simulator testing
    private func loadMockData() {
        isAuthorized = true

        // Simulate data based on current time of day
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        let hourFraction = Double(currentHour) / 24.0

        // Simulate typical daily totals scaling with time
        let expectedDailyActive = 600  // Target end-of-day active
        let expectedDailyBasal = 1850  // Target end-of-day basal

        todayActiveCalories = Int(Double(expectedDailyActive) * hourFraction * Double.random(in: 0.9...1.1))
        todayBasalCalories = Int(Double(expectedDailyBasal) * hourFraction)
        todayTDEE = todayActiveCalories + todayBasalCalories
        lastUpdated = Date()

        // Set up mock pattern (typical office worker curve)
        hourlyPattern = [
            0.00, 0.04, 0.08, 0.12, 0.16, 0.20,  // 12am-5am (sleeping)
            0.25, 0.30, 0.36, 0.42, 0.48, 0.54,  // 6am-11am (waking, active)
            0.60, 0.65, 0.70, 0.75, 0.80, 0.84,  // 12pm-5pm (afternoon)
            0.88, 0.92, 0.95, 0.97, 0.99, 1.00   // 6pm-11pm (evening, winding down)
        ]
        patternLoaded = true

        // Update projection with mock data
        updateProjection()

        // Simulate periodic updates
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                // Slowly increment as day progresses
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
    func updateProjection(caloriesConsumed: Int = 0) {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())

        // Confidence increases as day progresses (0% at midnight, 100% at 11pm)
        projectedConfidence = min(1.0, Double(currentHour) / 22.0)

        // If we don't have pattern data yet, use current TDEE as projection
        guard patternLoaded, currentHour > 0 else {
            projectedEndOfDayTDEE = todayTDEE
            projectedNet = caloriesConsumed - projectedEndOfDayTDEE
            return
        }

        // Get expected % of daily TDEE burned by this hour
        let expectedPercent = hourlyPattern[currentHour]

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

    /// Load historical hourly pattern from last 14 days
    /// Calculates cumulative % of daily TDEE burned by each hour
    private func loadHistoricalPattern() async {
        let calendar = Calendar.current
        guard let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) else { return }

        // Collect hourly data for each day
        var dailyTotals: [Date: Double] = [:]  // Day -> total TDEE
        var hourlyTotals: [Date: [Double]] = [:]  // Day -> [hourly cumulative]

        // Get each day's total TDEE first
        for dayOffset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: day)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
            let active = await fetchSum(for: activeEnergyType, predicate: predicate)
            let basal = await fetchSum(for: basalEnergyType, predicate: predicate)
            let total = active + basal

            if total > 500 {  // Only count days with meaningful data
                dailyTotals[startOfDay] = total
            }
        }

        // Now get hourly cumulative for each day
        for (startOfDay, dayTotal) in dailyTotals {
            var hourlyForDay: [Double] = Array(repeating: 0, count: 24)

            for hour in 0..<24 {
                guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay),
                      let hourEnd = calendar.date(byAdding: .hour, value: hour + 1, to: startOfDay) else { continue }

                let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: hourEnd, options: .strictStartDate)
                let active = await fetchSum(for: activeEnergyType, predicate: predicate)
                let basal = await fetchSum(for: basalEnergyType, predicate: predicate)
                let cumulative = active + basal

                // Store as percentage of daily total
                hourlyForDay[hour] = dayTotal > 0 ? cumulative / dayTotal : 0
            }

            hourlyTotals[startOfDay] = hourlyForDay
        }

        // Average the patterns across all days
        guard !hourlyTotals.isEmpty else { return }

        var avgPattern: [Double] = Array(repeating: 0, count: 24)
        let dayCount = Double(hourlyTotals.count)

        for hour in 0..<24 {
            var sum = 0.0
            for (_, hourly) in hourlyTotals {
                sum += hourly[hour]
            }
            avgPattern[hour] = sum / dayCount
        }

        hourlyPattern = avgPattern
        patternLoaded = true
        print("[EnergyTracker] Loaded pattern from \(Int(dayCount)) days")
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
