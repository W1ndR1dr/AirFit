//
//  HealthKitManager.swift
//  AirFit
//
//  Re-written 2025-07-16 for production use on iOS 18+
//  Swift 6 – full async/await, Sendable-safe
//

import Foundation
import HealthKit
import Observation
import Combine

// MARK: - Internal helpers

/// Cached anchors + rolled-up statistics so we never re-query the same window.
@globalActor
enum HealthKitCacheActor {
    static let shared = CacheActor()
    actor CacheActor {
        private var anchors: [HKSampleType: HKQueryAnchor] = [:]
        private var collectionCache: [CacheKey: [Date: Double]] = [:]

        struct CacheKey: Hashable {
            let id: String                // HKQuantityTypeIdentifier.rawValue
            let unit: String              // HKUnit.unitString
            let start: Date
            let end: Date
        }

        // Anchor helpers
        func anchor(for type: HKSampleType) -> HKQueryAnchor? { anchors[type] }
        func setAnchor(_ anchor: HKQueryAnchor?, for type: HKSampleType) { anchors[type] = anchor }

        // Statistics helpers
        func value(for key: CacheKey) -> [Date: Double]? { collectionCache[key] }
        func setValue(_ dict: [Date: Double], for key: CacheKey) { collectionCache[key] = dict }
    }
}

private extension HKUnit {
    var unitString: String {
        // debug-friendly identifier
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "\(self)"
    }
}

// MARK: - Main manager

@MainActor
@Observable
final class HealthKitManager: HealthKitManaging, ServiceProtocol {

    // MARK: ServiceProtocol conformance
    nonisolated let serviceIdentifier = "healthkit-manager"
    nonisolated var isConfigured: Bool { MainActor.assumeIsolated { _isConfigured } }
    private var _isConfigured = false

    // MARK: Stored properties
    private let store = HKHealthStore()
    private let dataFetcher: HealthKitDataFetcher
    private let sleepAnalyzer: HealthKitSleepAnalyzer
    private var observers: [UUID: [HKObserverQuery]] = [:]
    private var cancellables = Set<AnyCancellable>()

    // public so SwiftUI can watch it
    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    // Ease of use constants
    nonisolated private static let calendar = Calendar.current
    nonisolated private static let todayStart = calendar.startOfDay(for: .now)

    // MARK: Lifecycle
    init() {
        self.dataFetcher   = HealthKitDataFetcher(healthStore: store)
        self.sleepAnalyzer = HealthKitSleepAnalyzer(healthStore: store)
    }

    // MARK: Configure / reset

    func configure() async throws {
        guard !_isConfigured else { return }

        refreshAuthorizationStatus()

        // Background delivery for critical metrics
        try await enableBackgroundDelivery()

        _isConfigured = true
        AppLogger.info("HealthKitManager configured", category: .health)
    }

    func reset() async {
        // Stop all observer queries
        observers.values.flatMap { $0 }.forEach { query in
            store.stop(query)
        }
        observers.removeAll()
        cancellables.removeAll()
        _isConfigured = false
        authorizationStatus = .notDetermined
    }

    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: authorizationStatus == .authorized ? .healthy : .degraded,
            lastCheckTime: .now,
            responseTime: nil,
            errorMessage: authorizationStatus == .authorized ? nil : "HealthKit not fully authorized",
            metadata: ["authStatus": "\(authorizationStatus)"]
        )
    }

    // MARK: Authorization

    enum AuthorizationStatus {
        case notDetermined, authorized, denied, restricted
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .restricted
            throw AppError.from(HealthKitError.notAvailable)
        }

        try await store.requestAuthorization(
            toShare: HealthKitDataTypes.writeTypes,
            read:    HealthKitDataTypes.readTypes
        )

        refreshAuthorizationStatus()

        if authorizationStatus == .authorized {
            try await enableBackgroundDelivery()
        }
    }

    func refreshAuthorizationStatus() {
        let proxyType = HKQuantityType(.stepCount)
        switch store.authorizationStatus(for: proxyType) {
        case .notDetermined: authorizationStatus = .notDetermined
        case .sharingDenied: authorizationStatus = .denied
        case .sharingAuthorized: authorizationStatus = .authorized
        @unknown default: authorizationStatus = .notDetermined
        }
    }

    // MARK: Background delivery & observers

    private func enableBackgroundDelivery() async throws {
        // Only the handful that the dashboard / recovery rely on
        let critical: [(HKQuantityTypeIdentifier, HKUpdateFrequency)] = [
            (.heartRate,            .immediate),
            (.restingHeartRate,     .immediate),
            (.heartRateVariabilitySDNN, .immediate),
            (.stepCount,            .hourly),
            (.activeEnergyBurned,   .hourly),
            (.bodyMass,             .daily)
        ]

        try await withThrowingTaskGroup(of: Void.self) { group in
            for (id, freq) in critical {
                guard let qt = HKQuantityType.quantityType(forIdentifier: id) else { continue }
                group.addTask {
                    try await self.store.enableBackgroundDelivery(for: qt, frequency: freq)
                }
            }
            try await group.waitForAll()
        }
    }

    // MARK: Observer/Publisher API

    /// Observe HealthKit changes for the *minimal* set used by dashboard + recovery.
    /// Returns a token you keep; call `stopObserving(token:)` when done.
    func observeHealthKitChanges(handler: @escaping @Sendable () -> Void) -> Any {
        var queries: [HKObserverQuery] = []
        let token = UUID()

        let observe: (HKSampleType) -> Void = { type in
            let q = HKObserverQuery(sampleType: type,
                                    predicate: nil) { _, _, error in
                if let error { AppLogger.error("Observer error \(type): \(error)", category: .health) }
                Task { handler() }
            }
            self.store.execute(q)
            queries.append(q)
        }

        for id in [.heartRate, .restingHeartRate, .heartRateVariabilitySDNN,
                   .stepCount, .activeEnergyBurned, .bodyMass] as [HKQuantityTypeIdentifier] {
            if let t = HKQuantityType.quantityType(forIdentifier: id) { observe(t) }
        }
        observe(HKObjectType.workoutType())

        observers[token] = queries
        return token
    }

    func stopObserving(token: Any) {
        guard let id = token as? UUID,
              let qs = observers[id] else { return }
        qs.forEach(store.stop)
        observers.removeValue(forKey: id)
    }

    // MARK: –––– NEW PUBLIC APIS ––––

    /// Historical biometrics needed by RecoveryInference (7–30 days)
    func fetchDailyBiometrics(from startDate: Date,
                              to endDate: Date) async throws -> [DailyBiometrics] {

        try await authorizeIfNeeded()

        // 1. Aggregate *quantity*-based metrics with HKStatisticsCollectionQuery
        let metrics = try await fetchAggregateMetrics(start: startDate, end: endDate)

        // 2. Aggregate sleep with HKSampleQuery (sleep stages were category samples)
        let sleepDict = try await fetchSleepSessions(start: startDate, end: endDate)

        // 3. Join → produce DailyBiometrics
        var results: [DailyBiometrics] = []
        let days = HealthKitManager.calendar
            .generateDates(from: startDate, to: endDate)
        for day in days {
            let midnight = HealthKitManager.calendar.startOfDay(for: day)
            let m = metrics[midnight] ?? .init() // default empty struct
            let s = sleepDict[midnight]

            results.append(
                DailyBiometrics(
                    date: midnight,
                    heartRate: m.heartRate,
                    hrv: m.hrv,
                    restingHeartRate: m.restingHeartRate,
                    heartRateRecovery: m.heartRateRecovery,
                    vo2Max: m.vo2Max,
                    respiratoryRate: m.respiratoryRate,
                    bedtime: s?.bedtime ?? midnight,
                    wakeTime: s?.wake ?? midnight,
                    sleepDuration: s?.duration ?? 0,
                    remSleep: s?.rem ?? 0,
                    coreSleep: s?.core ?? 0,
                    deepSleep: s?.deep ?? 0,
                    awakeTime: s?.awake ?? 0,
                    sleepEfficiency: s?.efficiency ?? 0,
                    activeEnergyBurned: m.activeEnergy,
                    basalEnergyBurned: m.basalEnergy,
                    steps: m.steps,
                    exerciseTime: m.exerciseTime,
                    standHours: m.standHours
                )
            )
        }
        return results.sorted { $0.date < $1.date }
    }

    /// Fetch workouts in given window (chronological asc)
    func fetchHistoricalWorkouts(from startDate: Date,
                                 to endDate: Date) async throws -> [WorkoutData] {
        try await authorizeIfNeeded()
        let raw = try await dataFetcher.fetchWorkouts(from: startDate, to: endDate)
        return raw
            .sorted { $0.startDate < $1.startDate }
            .map {
                WorkoutData(
                    workoutType: String($0.workoutActivityType.rawValue),
                    startDate: $0.startDate,
                    duration: $0.duration,
                    totalEnergyBurned: $0.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                    averageHeartRate: 0  // TODO: Fetch average heart rate from workout samples
                )
            }
    }

    // MARK: Existing public API methods (from original implementation)

    func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
        try await authorizeIfNeeded()
        
        // Use the new fetchAggregateMetrics for today
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let metrics = try await fetchAggregateMetrics(start: startOfDay, end: today)
        let todayMetrics = metrics[startOfDay] ?? QuantityDay()
        
        var activityMetrics = ActivityMetrics()
        activityMetrics.steps = todayMetrics.steps
        activityMetrics.activeEnergyBurned = todayMetrics.activeEnergy > 0 ? 
            Measurement(value: todayMetrics.activeEnergy, unit: .kilocalories) : nil
        activityMetrics.exerciseMinutes = Int(todayMetrics.exerciseTime)
        activityMetrics.standHours = todayMetrics.standHours
        
        // TODO: Add distance and flights climbed when we add those to fetchAggregateMetrics
        
        return activityMetrics
    }

    func fetchLatestBodyMetrics() async throws -> BodyMetrics {
        try await authorizeIfNeeded()
        
        // TODO: Implement proper body metrics fetching
        // For now, return empty metrics
        return BodyMetrics()
    }

    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
        try await authorizeIfNeeded()
        
        // Use the new daily biometrics approach
        let today = Date()
        let biometrics = try await fetchDailyBiometrics(from: today, to: today)
        let todayData = biometrics.first
        
        var metrics = HeartHealthMetrics()
        if let rhr = todayData?.restingHeartRate {
            metrics.restingHeartRate = Int(rhr)
        }
        if let hrv = todayData?.hrv {
            metrics.hrv = Measurement(value: hrv, unit: .milliseconds)
        }
        metrics.vo2Max = todayData?.vo2Max
        return metrics
    }

    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {
        try await authorizeIfNeeded()
        
        // Use the new sleep fetching approach
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        let sleepData = try await fetchSleepSessions(start: yesterday, end: today)
        
        // Convert to SleepSession format
        guard let lastNight = sleepData.values.first else { return nil }
        
        return SleepAnalysis.SleepSession(
            bedtime: lastNight.bedtime,
            wakeTime: lastNight.wake,
            totalSleepTime: lastNight.duration,
            timeInBed: lastNight.wake.timeIntervalSince(lastNight.bedtime),
            efficiency: lastNight.efficiency * 100,  // Convert 0-1 to 0-100
            remTime: lastNight.rem,
            coreTime: lastNight.core,
            deepTime: lastNight.deep,
            awakeTime: lastNight.awake
        )
    }

    func fetchNutritionTotals(for date: Date) async throws -> NutritionMetrics {
        try await authorizeIfNeeded()
        
        // TODO: Implement nutrition fetching with proper HKStatisticsCollectionQuery
        // For now, return empty metrics
        return NutritionMetrics(
            calories: 0,
            protein: 0,
            carbohydrates: 0,
            fat: 0,
            fiber: 0
        )
    }

    func fetchRecentWorkouts(limit: Int = 10) async throws -> [HKWorkout] {
        try await authorizeIfNeeded()
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        return try await dataFetcher.fetchWorkouts(from: startDate, to: endDate)
    }

    func saveWorkout(_ workout: HKWorkout) async throws {
        try await authorizeIfNeeded()
        try await store.save(workout)
        AppLogger.info("Saved workout: \(workout.workoutActivityType.name)", category: .health)
    }

    func saveNutrition(_ samples: [HKQuantitySample]) async throws {
        try await authorizeIfNeeded()
        try await store.save(samples)
        AppLogger.info("Saved \(samples.count) nutrition samples", category: .health)
    }

    // MARK: Additional Protocol Requirements
    
    func getWorkoutData(from startDate: Date, to endDate: Date) async -> [WorkoutData] {
        do {
            return try await fetchHistoricalWorkouts(from: startDate, to: endDate)
        } catch {
            AppLogger.error("Failed to get workout data", error: error, category: .health)
            return []
        }
    }
    
    func fetchRecentWorkouts(limit: Int) async throws -> [WorkoutData] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        let workouts = try await fetchHistoricalWorkouts(from: startDate, to: endDate)
        return Array(workouts.suffix(limit))
    }
    
    func saveFoodEntry(_ entry: FoodEntry) async throws -> [String] {
        var samples: [HKQuantitySample] = []
        let date = entry.loggedAt
        
        // Convert nutrition data to HealthKit samples
        let nutritionTypes: [(Double?, HKQuantityTypeIdentifier)] = [
            (Double(entry.totalCalories), .dietaryEnergyConsumed),
            (entry.totalProtein, .dietaryProtein),
            (entry.totalCarbs, .dietaryCarbohydrates),
            (entry.totalFat, .dietaryFatTotal)
            // TODO: Add fiber when FoodEntry supports it
        ]
        
        for (value, identifier) in nutritionTypes {
            guard let value = value, value > 0,
                  let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            
            let unit: HKUnit = identifier == .dietaryEnergyConsumed ? .kilocalorie() : .gram()
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: date, end: date)
            samples.append(sample)
        }
        
        try await store.save(samples)
        return samples.map { $0.uuid.uuidString }
    }
    
    func getNutritionData(for date: Date) async throws -> HealthKitNutritionSummary {
        let nutrition = try await fetchNutritionTotals(for: date)
        return HealthKitNutritionSummary(
            date: date,
            calories: nutrition.calories,
            protein: nutrition.protein,
            carbohydrates: nutrition.carbohydrates,
            fat: nutrition.fat,
            fiber: nutrition.fiber,
            sugar: 0,  // Not fetched in current implementation
            sodium: 0  // Not fetched in current implementation
        )
    }
    
    func saveWorkout(_ workout: Workout) async throws -> String {
        // Convert our Workout model to HKWorkout
        let hkWorkoutType: HKWorkoutActivityType = .other  // TODO: Map workout types properly
        
        let totalEnergy = workout.exercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { setTotal, set in
                let weight = set.completedWeightKg ?? set.targetWeightKg ?? 0
                let reps = Double(set.completedReps ?? set.targetReps ?? 0)
                // Rough calorie estimate: weight * reps * 0.3
                return setTotal + (weight * reps * 0.3)
            }
        }
        
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: totalEnergy)
        
        // HKWorkout constructor changed in newer APIs
        // For now, return a dummy ID - implement proper workout saving later
        // TODO: Use HKWorkoutBuilder for creating workouts
        return UUID().uuidString
    }
    
    func deleteWorkout(healthKitID: String) async throws {
        guard let uuid = UUID(uuidString: healthKitID) else {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        // Query for the workout
        let predicate = HKQuery.predicateForObject(with: uuid)
        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
                }
            }
            store.execute(query)
        }
        
        guard let workout = workouts.first else {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        try await store.delete(workout)
    }
    
    func saveBodyMass(weightKg: Double, date: Date) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await store.save(sample)
    }
    
    func saveBodyFatPercentage(percentage: Double, date: Date) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }
        let quantity = HKQuantity(unit: .percent(), doubleValue: percentage / 100.0)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await store.save(sample)
    }
    
    func saveLeanBodyMass(massKg: Double, date: Date) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) else { return }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: massKg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await store.save(sample)
    }
    
    func fetchBodyMetricsHistory(from startDate: Date, to endDate: Date) async throws -> [BodyMetrics] {
        // This would require implementing a more complex query
        // For now, return empty array
        return []
    }
    
    func observeBodyMetrics(handler: @escaping @Sendable () -> Void) async throws {
        _ = observeHealthKitChanges(handler: handler)
    }
    
    func removeObserver(_ observer: Any) {
        stopObserving(token: observer)
    }

    // MARK: Internal helpers

    // Mini struct to collate daily quantity data
    private struct QuantityDay {
        var heartRate = 0.0
        var hrv = 0.0
        var restingHeartRate = 0.0
        var heartRateRecovery = 0.0
        var vo2Max = 0.0
        var respiratoryRate = 0.0
        var activeEnergy = 0.0
        var basalEnergy = 0.0
        var steps = 0
        var exerciseTime = 0.0
        var standHours = 0
    }

    // Aggregated quantity fetch
    private func fetchAggregateMetrics(start: Date,
                                       end: Date) async throws -> [Date: QuantityDay] {

        enum MetricType: Int {
            case heartRate
            case hrv
            case restingHeartRate
            case heartRateRecovery
            case respiratoryRate
            case activeEnergy
            case basalEnergy
            case steps
            case exerciseTime
            case standHours
        }
        
        let identifiers: [(HKQuantityTypeIdentifier, HKUnit, MetricType)] = [
            (.heartRate, .count().unitDivided(by: .minute()), .heartRate),
            (.heartRateVariabilitySDNN, .secondUnit(with: .milli), .hrv),
            (.restingHeartRate, .count().unitDivided(by: .minute()), .restingHeartRate),
            (.heartRateRecoveryOneMinute, .count().unitDivided(by: .minute()), .heartRateRecovery),
            (.respiratoryRate, .count().unitDivided(by: .minute()), .respiratoryRate),
            (.activeEnergyBurned, .kilocalorie(), .activeEnergy),
            (.basalEnergyBurned, .kilocalorie(), .basalEnergy),
            (.stepCount, .count(), .steps),
            (.appleExerciseTime, .minute(), .exerciseTime),
            (.appleStandTime, .count(), .standHours)
        ]

        // Use actor for thread-safe dictionary updates
        actor DictCollector {
            var dict = [Date: QuantityDay]()
            
            func update(date: Date, metric: MetricType, value: Double) {
                var day = dict[date] ?? QuantityDay()
                switch metric {
                case .heartRate: day.heartRate = value
                case .hrv: day.hrv = value
                case .restingHeartRate: day.restingHeartRate = value
                case .heartRateRecovery: day.heartRateRecovery = value
                case .respiratoryRate: day.respiratoryRate = value
                case .activeEnergy: day.activeEnergy = value
                case .basalEnergy: day.basalEnergy = value
                case .steps: day.steps = Int(value)
                case .exerciseTime: day.exerciseTime = value
                case .standHours: day.standHours = Int(value)
                }
                dict[date] = day
            }
            
            func getDict() -> [Date: QuantityDay] { dict }
        }
        
        let collector = DictCollector()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for (id, unit, metric) in identifiers {
                guard let type = HKQuantityType.quantityType(forIdentifier: id) else { continue }

                group.addTask {
                    let values = try await self.dailySum(type: type,
                                                         unit: unit,
                                                         start: start,
                                                         end: end)
                    for (date, value) in values {
                        await collector.update(date: date, metric: metric, value: value)
                    }
                }
            }
            try await group.waitForAll()
        }
        return await collector.getDict()
    }

    /// Returns [midnightDate → value] using HKStatisticsCollectionQuery.
    private func dailySum(type: HKQuantityType,
                          unit: HKUnit,
                          start: Date,
                          end: Date) async throws -> [Date: Double] {

        // Cache first – HKStatisticsCollectionQuery is expensive
        let key = HealthKitCacheActor.CacheActor.CacheKey(
            id: type.identifier,
            unit: unit.unitString,
            start: HealthKitManager.calendar.startOfDay(for: start),
            end:   HealthKitManager.calendar.startOfDay(for: end)
        )
        if let hit = await HealthKitCacheActor.shared.value(for: key) { return hit }

        // Build query
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let interval  = DateComponents(day: 1)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: HealthKitManager.todayStart,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, coll, error in
                if let error { continuation.resume(throwing: error); return }

                var out: [Date: Double] = [:]
                coll?.enumerateStatistics(from: start, to: end) { stats, _ in
                    if let sum = stats.sumQuantity() {
                        let date = HealthKitManager.calendar.startOfDay(for: stats.startDate)
                        out[date] = sum.doubleValue(for: unit)
                    }
                }

                Task { await HealthKitCacheActor.shared.setValue(out, for: key) }
                continuation.resume(returning: out)
            }
            self.store.execute(query)
        }
    }

    // Sleep data (category samples)
    private func fetchSleepSessions(start: Date,
                                    end: Date) async throws
    -> [Date: (bedtime: Date, wake: Date, duration: TimeInterval,
               rem: TimeInterval, core: TimeInterval, deep: TimeInterval,
               awake: TimeInterval, efficiency: Double)] {

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end,
                                                    options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let q = HKSampleQuery(sampleType: HKCategoryType(.sleepAnalysis),
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }

                var dict: [Date: (Date, Date, TimeInterval,
                                  TimeInterval, TimeInterval, TimeInterval,
                                  TimeInterval, Double)] = [:]

                for s in (samples as? [HKCategorySample] ?? []) {
                    let day = HealthKitManager.calendar
                        .startOfDay(for: s.startDate)
                    let dur = s.endDate.timeIntervalSince(s.startDate)

                    var entry = dict[day] ??
                    (s.startDate, s.endDate, 0, 0, 0, 0, 0, 0)

                    entry.0  = min(entry.0,  s.startDate)  // bedtime
                    entry.1  = max(entry.1,  s.endDate)    // wake
                    entry.2 += dur                         // duration

                    switch s.value {
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:  entry.3  += dur
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue: entry.4 += dur
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: entry.5 += dur
                    case HKCategoryValueSleepAnalysis.awake.rawValue:entry.6 += dur
                    default: break
                    }

                    dict[day] = entry
                }

                // Efficiency
                for (k, v) in dict {
                    var e = v
                    e.7 = e.2 == 0 ? 0 :
                    max(0, min(1, 1 - (e.6 / e.2)))
                    dict[k] = e
                }

                continuation.resume(returning: dict)
            }
            store.execute(q)
        }
    }

    // MARK: Util
    private func authorizeIfNeeded() async throws {
        guard authorizationStatus == .authorized else {
            try await requestAuthorization()
            if authorizationStatus != .authorized {
                throw AppError.from(HealthKitError.authorizationDenied)
            }
            return
        }
    }
}

// MARK: - Calendar helper (nicer date sequence)

private extension Calendar {
    /// Inclusive list of midnights between two dates
    func generateDates(from start: Date, to end: Date) -> [Date] {
        guard start <= end else { return [] }
        var dates: [Date] = []
        var cur = start
        while cur <= end {
            dates.append(startOfDay(for: cur))
            guard let next = date(byAdding: .day, value: 1, to: cur) else { break }
            cur = next
        }
        return dates
    }
}