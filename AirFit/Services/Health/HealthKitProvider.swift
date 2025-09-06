import Foundation
import HealthKit

// MARK: - HealthKitPrefillProviding Protocol
protocol HealthKitPrefillProviding: Actor {
    func fetchActivityMetrics() async throws -> OnboardingActivityMetrics
    func requestAuthorization() async throws -> Bool
}

// MARK: - HealthKitSnapshot
struct HealthKitSnapshot: Codable, Sendable {
    let activityMetrics: OnboardingActivityMetrics
    let timestamp: Date
}

// MARK: - OnboardingActivityMetrics
/// Simplified activity data for onboarding LLM synthesis
struct OnboardingActivityMetrics: Codable, Sendable {
    let averageDailySteps: Double
    let averageDailyActiveCalories: Double
    let weeklyExerciseMinutes: Int
    let weeklyWorkoutCount: Int
}

// MARK: - HealthKitProvider
/// Real HealthKit integration that actually fetches data
actor HealthKitProvider: HealthKitPrefillProviding {
    private let store = HKHealthStore()

    // MARK: - Types We Need
    // Use the same comprehensive set as HealthKitDataTypes for consistency
    private var readTypes: Set<HKObjectType> {
        // Reuse the centralized definition to ensure consistency
        return Set(HealthKitDataTypes.readTypes)
    }

    // MARK: - Authorization
    func requestAuthorization() async throws -> Bool {
        AppLogger.info("HealthKitProvider: Checking if HealthKit is available", category: .health)
        
        guard HKHealthStore.isHealthDataAvailable() else {
            AppLogger.error("HealthKitProvider: HealthKit not available on this device", category: .health)
            throw HealthKitError.notAvailable
        }
        
        AppLogger.info("HealthKitProvider: About to request authorization for \(readTypes.count) types", category: .health)
        
        do {
            // This should present the system permission dialog
            try await store.requestAuthorization(toShare: [], read: readTypes)
            AppLogger.info("HealthKitProvider: Authorization request completed", category: .health)
            return true
        } catch {
            AppLogger.error("HealthKitProvider: Authorization request failed", error: error, category: .health)
            throw error
        }
    }

    func checkAuthorizationStatus() -> HealthKitAuthorizationStatus {
        // Check authorization for each type
        let weightAuth = store.authorizationStatus(for: HKQuantityType(.bodyMass))
        let stepAuth = store.authorizationStatus(for: HKQuantityType(.stepCount))

        if weightAuth == .notDetermined || stepAuth == .notDetermined {
            return .notDetermined
        } else if weightAuth == .sharingDenied && stepAuth == .sharingDenied {
            return .denied
        } else {
            return .authorized
        }
    }

    // MARK: - Data Fetching
    func fetchCurrentWeight() async throws -> Double? {
        let weightType = HKQuantityType(.bodyMass)
        let sample = try await fetchMostRecentSample(type: weightType)
        return sample?.quantity.doubleValue(for: .pound())
    }

    func fetchHeight() async throws -> Double? {
        let heightType = HKQuantityType(.height)
        let sample = try await fetchMostRecentSample(type: heightType)
        return sample?.quantity.doubleValue(for: .inch())
    }

    func fetchTypicalSleepWindow() async throws -> (bed: Date, wake: Date)? {
        // Get sleep data from last 7 days
        let sleepType = HKCategoryType(.sleepAnalysis)
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let samples: [HKCategorySample]? = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
            }
            store.execute(query)
        }

        // Calculate typical bed/wake times from samples
        guard let samples = samples, !samples.isEmpty else { return nil }

        let sleepSamples = samples.filter { sample in
            sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue ||
                sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        }

        guard !sleepSamples.isEmpty else { return nil }

        // Calculate average bed and wake times
        let calendar = Calendar.current
        var bedHours: [Int] = []
        var wakeHours: [Int] = []

        for sample in sleepSamples.prefix(7) {
            let bedComponents = calendar.dateComponents([.hour, .minute], from: sample.startDate)
            let wakeComponents = calendar.dateComponents([.hour, .minute], from: sample.endDate)

            if let bedHour = bedComponents.hour {
                bedHours.append(bedHour)
            }
            if let wakeHour = wakeComponents.hour {
                wakeHours.append(wakeHour)
            }
        }

        guard !bedHours.isEmpty, !wakeHours.isEmpty else { return nil }

        // Create typical times
        let avgBedHour = bedHours.reduce(0, +) / bedHours.count
        let avgWakeHour = wakeHours.reduce(0, +) / wakeHours.count

        let today = Date()
        let bedTime = calendar.date(bySettingHour: avgBedHour, minute: 0, second: 0, of: today)!
        let wakeTime = calendar.date(bySettingHour: avgWakeHour, minute: 0, second: 0, of: today)!

        return (bed: bedTime, wake: wakeTime)
    }

    func fetchActivityMetrics() async throws -> OnboardingActivityMetrics {
        // Fetch multiple activity indicators in parallel
        async let avgSteps = fetchAverageSteps(days: 7)
        async let avgActiveCalories = fetchAverageActiveCalories(days: 7)
        async let exerciseMinutes = fetchWeeklyExerciseMinutes()
        async let workouts = fetchRecentWorkouts(days: 7)

        let (steps, calories, minutes, workoutCount) = try await (avgSteps, avgActiveCalories, exerciseMinutes, workouts)

        return OnboardingActivityMetrics(
            averageDailySteps: steps,
            averageDailyActiveCalories: calories,
            weeklyExerciseMinutes: minutes,
            weeklyWorkoutCount: workoutCount
        )
    }

    func fetchHealthSnapshot() async throws -> HealthKitSnapshot {
        // Fetch all data in parallel
        async let weight = fetchCurrentWeight()
        async let height = fetchHeight()
        async let sleepWindow = fetchTypicalSleepWindow()
        async let activityMetrics = fetchActivityMetrics()

        let (_, _, _, metricsResult) = try await (weight, height, sleepWindow, activityMetrics)

        return HealthKitSnapshot(
            activityMetrics: metricsResult,
            timestamp: Date()
        )
    }

    // MARK: - Private Helpers
    private func fetchMostRecentSample(type: HKQuantityType) async throws -> HKQuantitySample? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples?.first as? HKQuantitySample)
                }
            }
            store.execute(query)
        }
    }

    private func fetchAverageSteps(days: Int) async throws -> Double {
        let stepsType = HKQuantityType(.stepCount)
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sum = result?.sumQuantity() {
                    let totalSteps = sum.doubleValue(for: .count())
                    continuation.resume(returning: totalSteps / Double(days))
                } else {
                    continuation.resume(returning: 0)
                }
            }
            store.execute(query)
        }
    }

    private func fetchAverageActiveCalories(days: Int) async throws -> Double {
        let caloriesType = HKQuantityType(.activeEnergyBurned)
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: caloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sum = statistics?.sumQuantity() {
                    let totalCalories = sum.doubleValue(for: .kilocalorie())
                    continuation.resume(returning: totalCalories / Double(days))
                } else {
                    continuation.resume(returning: 0)
                }
            }
            store.execute(query)
        }
    }

    private func fetchWeeklyExerciseMinutes() async throws -> Int {
        let workoutType = HKObjectType.workoutType()
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let workouts = samples as? [HKWorkout] {
                    let totalMinutes = workouts.reduce(0) { total, workout in
                        total + Int(workout.duration / 60)
                    }
                    continuation.resume(returning: totalMinutes)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            store.execute(query)
        }
    }

    private func fetchRecentWorkouts(days: Int) async throws -> Int {
        let workoutType = HKObjectType.workoutType()
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples?.count ?? 0)
                }
            }
            store.execute(query)
        }
    }
}

// MARK: - Supporting Types
enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    case noData
    case dataNotAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Health data is not available on this device"
        case .authorizationDenied:
            return "Permission to access health data was denied"
        case .noData, .dataNotAvailable:
            return "No health data found"
        }
    }
}

// ActivityLevel is defined in GlobalEnums.swift but we use OnboardingActivityMetrics instead
