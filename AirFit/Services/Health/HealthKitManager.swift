import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class HealthKitManager {
    // MARK: - Singleton
    static let shared = HealthKitManager()

    // MARK: - Properties
    private let healthStore = HKHealthStore()
    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    // MARK: - Authorization Status
    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    // MARK: - HealthKit Errors
    enum HealthKitError: LocalizedError {
        case notAvailable
        case authorizationDenied

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "HealthKit is not available on this device"
            case .authorizationDenied:
                return "HealthKit authorization was denied"
            }
        }
    }

    // MARK: - Data Types Configuration
    private var readTypes: Set<HKObjectType> {
        let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
            // Activity
            .activeEnergyBurned,
            .basalEnergyBurned,
            .stepCount,
            .distanceWalkingRunning,
            .distanceCycling,
            .flightsClimbed,
            .appleExerciseTime,
            .appleStandTime,
            .appleMoveTime,
            // Heart
            .heartRate,
            .heartRateVariabilitySDNN,
            .restingHeartRate,
            .heartRateRecoveryOneMinute,
            .vo2Max,
            .respiratoryRate,
            // Body
            .bodyMass,
            .bodyFatPercentage,
            .leanBodyMass,
            .bodyMassIndex,
            // Vitals
            .bloodPressureSystolic,
            .bloodPressureDiastolic,
            .bodyTemperature,
            .oxygenSaturation
        ]

        var types = Set(quantityIdentifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) })

        if let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepAnalysis)
        }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }

        if #available(iOS 18.0, *), let stages = HKObjectType.categoryType(forIdentifier: .sleepStages) {
            types.insert(stages)
        }

        types.insert(HKObjectType.workoutType())
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        if let bodyFat = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) {
            types.insert(bodyFat)
        }
        if let water = HKObjectType.quantityType(forIdentifier: .dietaryWater) {
            types.insert(water)
        }
        types.insert(HKObjectType.workoutType())
        return types
    }

    // MARK: - Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .restricted
            throw HealthKitError.notAvailable
        }

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            authorizationStatus = .authorized
            AppLogger.info("HealthKit authorization granted", category: .health)

            do {
                try await enableBackgroundDelivery()
            } catch {
                AppLogger.error("Failed to enable HealthKit background delivery", error: error, category: .health)
            }
        } catch {
            authorizationStatus = .denied
            AppLogger.error("HealthKit authorization failed", error: error, category: .health)
            throw error
        }
    }

    func refreshAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .restricted
            return
        }
        let status = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .sharingDenied:
            authorizationStatus = .denied
        case .sharingAuthorized:
            authorizationStatus = .authorized
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }

    // MARK: - Background Delivery
    func enableBackgroundDelivery() async throws {
        let configurations: [(HKQuantityTypeIdentifier, HKUpdateFrequency)] = [
            (.stepCount, .hourly),
            (.activeEnergyBurned, .hourly),
            (.heartRate, .immediate),
            (.bodyMass, .daily)
        ]

        for (identifier, frequency) in configurations {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            try await healthStore.enableBackgroundDelivery(for: type, frequency: frequency)
        }

        AppLogger.info("HealthKit background delivery enabled", category: .health)
    }

    // MARK: - Activity Data Fetching
    func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        async let activeEnergy = fetchTotalQuantity(
            type: .activeEnergyBurned,
            unit: .kilocalorie(),
            predicate: predicate
        )

        async let steps = fetchTotalQuantity(
            type: .stepCount,
            unit: .count(),
            predicate: predicate
        )

        async let distance = fetchTotalQuantity(
            type: .distanceWalkingRunning,
            unit: .meter(),
            predicate: predicate
        )

        async let exerciseTime = fetchTotalQuantity(
            type: .appleExerciseTime,
            unit: .minute(),
            predicate: predicate
        )

        async let standHours = fetchStandHours(for: now)
        async let currentHR = fetchLatestHeartRate()

        let (energy, stepCount, dist, exercise, stand, hr) = try await (
            activeEnergy,
            steps,
            distance,
            exerciseTime,
            standHours,
            currentHR
        )

        return ActivityMetrics(
            activeEnergyBurned: energy.map { Measurement(value: $0, unit: .kilocalories) },
            steps: stepCount.map { Int($0) },
            distance: dist.map { Measurement(value: $0, unit: .meters) },
            exerciseMinutes: exercise.map { Int($0) },
            standHours: stand,
            currentHeartRate: hr
        )
    }

    // MARK: - Sleep Data Fetching
    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {
        let calendar = Calendar.current
        let now = Date()

        guard let startDate = calendar.date(byAdding: .hour, value: -24, to: now) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: now,
            options: .strictStartDate
        )

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                let session = self.analyzeSleepSamples(sleepSamples)
                continuation.resume(returning: session)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Heart Health Data
    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
        async let rhr = fetchLatestQuantitySample(
            type: .restingHeartRate,
            unit: .count().unitDivided(by: .minute())
        )
        async let hrv = fetchLatestQuantitySample(
            type: .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli)
        )
        async let vo2 = fetchLatestQuantitySample(
            type: .vo2Max,
            unit: .literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute())
        )

        let (restingHR, heartRateVariability, vo2Max) = try await (rhr, hrv, vo2)

        return HeartHealthMetrics(
            restingHeartRate: restingHR.map { Int($0) },
            hrv: heartRateVariability.map { Measurement(value: $0, unit: .milliseconds) },
            vo2Max: vo2Max
        )
    }

    // MARK: - Body Metrics
    func fetchLatestBodyMetrics() async throws -> BodyMetrics {
        async let weight = fetchLatestQuantitySample(
            type: .bodyMass,
            unit: .gramUnit(with: .kilo)
        )

        async let bodyFat = fetchLatestQuantitySample(
            type: .bodyFatPercentage,
            unit: .percent()
        )

        async let bmi = fetchLatestQuantitySample(
            type: .bodyMassIndex,
            unit: .count()
        )

        let (weightKg, fatPercent, bmiValue) = try await (weight, bodyFat, bmi)

        return BodyMetrics(
            weight: weightKg.map { Measurement(value: $0, unit: .kilograms) },
            bodyFatPercentage: fatPercent.map { $0 * 100 },
            bmi: bmiValue,
            bodyMassIndex: bmiValue.flatMap { BodyMetrics.BMICategory(bmi: $0) }
        )
    }

    // MARK: - Private Helper Methods
    private func fetchTotalQuantity(
        type: HKQuantityTypeIdentifier,
        unit: HKUnit,
        predicate: NSPredicate
    ) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = statistics?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: sum)
            }

            healthStore.execute(query)
        }
    }

    private func fetchLatestQuantitySample(
        type: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    private func fetchLatestHeartRate() async throws -> Int? {
        try await fetchLatestQuantitySample(
            type: .heartRate,
            unit: .count().unitDivided(by: .minute())
        ).map { Int($0) }
    }

    private func fetchStandHours(for date: Date) async throws -> Int? {
        // Implementation for stand hours calculation
        // This would involve querying stand samples for each hour of the day
        return nil // Placeholder
    }

    private func analyzeSleepSamples(_ samples: [HKCategorySample]) -> SleepAnalysis.SleepSession? {
        guard !samples.isEmpty else { return nil }

        var bedtime = Date.distantFuture
        var wakeTime = Date.distantPast
        var totalAsleep: TimeInterval = 0
        var totalInBed: TimeInterval = 0

        var remTime: TimeInterval = 0
        var coreTime: TimeInterval = 0
        var deepTime: TimeInterval = 0
        var awakeTime: TimeInterval = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            if sample.startDate < bedtime {
                bedtime = sample.startDate
            }
            if sample.endDate > wakeTime {
                wakeTime = sample.endDate
            }

            totalInBed += duration

            switch HKCategoryValueSleepAnalysis(rawValue: sample.value) {
            case .inBed:
                awakeTime += duration
            case .asleepUnspecified, .asleep:
                totalAsleep += duration
            case .awake:
                awakeTime += duration
            case .asleepREM:
                totalAsleep += duration
                remTime += duration
            case .asleepCore:
                totalAsleep += duration
                coreTime += duration
            case .asleepDeep:
                totalAsleep += duration
                deepTime += duration
            default:
                break
            }
        }

        let efficiency = totalInBed > 0 ? (totalAsleep / totalInBed) * 100 : 0

        return SleepAnalysis.SleepSession(
            bedtime: bedtime == Date.distantFuture ? nil : bedtime,
            wakeTime: wakeTime == Date.distantPast ? nil : wakeTime,
            totalSleepTime: totalAsleep,
            timeInBed: totalInBed,
            efficiency: efficiency,
            remTime: remTime > 0 ? remTime : nil,
            coreTime: coreTime > 0 ? coreTime : nil,
            deepTime: deepTime > 0 ? deepTime : nil,
            awakeTime: awakeTime > 0 ? awakeTime : nil
        )
    }
}
