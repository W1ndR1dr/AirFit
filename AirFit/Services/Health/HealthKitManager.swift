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
        case dataNotFound
        case queryFailed(Error)
        case invalidData

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "HealthKit is not available on this device"
            case .authorizationDenied:
                return "HealthKit authorization was denied"
            case .dataNotFound:
                return "Requested health data not found"
            case .queryFailed(let error):
                return "HealthKit query failed: \(error.localizedDescription)"
            case .invalidData:
                return "Invalid health data received"
            }
        }
    }

    // MARK: - Data Types Configuration
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()

        // Quantity types
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
            .oxygenSaturation,
            // Nutrition
            .dietaryWater
        ]

        for identifier in quantityIdentifiers {
            if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        // Category types
        let categoryIdentifiers: [HKCategoryTypeIdentifier] = [
            .sleepAnalysis,
            .mindfulSession
        ]

        for identifier in categoryIdentifiers {
            if let type = HKObjectType.categoryType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        // iOS 16+ sleep stages (not iOS 18 - correcting the specification)
        if #available(iOS 16.0, *) {
            // Sleep stages were introduced in iOS 16, not iOS 18
            // Using the correct category type for sleep analysis which includes stages
            if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                types.insert(sleepType)
            }
        }

        // Workout type
        types.insert(HKObjectType.workoutType())

        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()

        let writeIdentifiers: [HKQuantityTypeIdentifier] = [
            .bodyMass,
            .bodyFatPercentage,
            .dietaryWater
        ]

        for identifier in writeIdentifiers {
            if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        types.insert(HKObjectType.workoutType())
        return types
    }

    // MARK: - Initialization
    private init() {
        refreshAuthorizationStatus()
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

            // Enable background delivery after successful authorization
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

        // Check authorization status using a representative type
        let status = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .stepCount)!)
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
    private func enableBackgroundDelivery() async throws {
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

    // MARK: - Data Fetching Methods

    /// Fetches today's activity metrics
    func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now

        async let activeEnergy = fetchTotalQuantity(
            identifier: .activeEnergyBurned,
            start: startOfDay,
            end: endOfDay,
            unit: HKUnit.kilocalorie()
        )

        async let basalEnergy = fetchTotalQuantity(
            identifier: .basalEnergyBurned,
            start: startOfDay,
            end: endOfDay,
            unit: HKUnit.kilocalorie()
        )

        async let steps = fetchTotalQuantity(
            identifier: .stepCount,
            start: startOfDay,
            end: endOfDay,
            unit: HKUnit.count()
        )

        async let distance = fetchTotalQuantity(
            identifier: .distanceWalkingRunning,
            start: startOfDay,
            end: endOfDay,
            unit: HKUnit.meter()
        )

        async let flights = fetchTotalQuantity(
            identifier: .flightsClimbed,
            start: startOfDay,
            end: endOfDay,
            unit: HKUnit.count()
        )

        async let exerciseTime = fetchTotalQuantity(
            identifier: .appleExerciseTime,
            start: startOfDay,
            end: endOfDay,
            unit: HKUnit.minute()
        )

        async let standHours = fetchTotalQuantity(
            identifier: .appleStandTime,
            start: startOfDay,
            end: endOfDay,
            unit: HKUnit.count()
        )

        async let moveTime = fetchTotalQuantity(
            identifier: .appleMoveTime,
            start: startOfDay,
            end: endOfDay,
            unit: HKUnit.minute()
        )

        async let currentHR = fetchLatestQuantitySample(
            identifier: .heartRate,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        // Await all results
        let results = await (
            activeEnergy: activeEnergy,
            basalEnergy: basalEnergy,
            steps: steps,
            distance: distance,
            flights: flights,
            exerciseTime: exerciseTime,
            standHours: standHours,
            moveTime: moveTime,
            currentHR: currentHR
        )

        return ActivityMetrics(
            activeEnergyBurned: results.activeEnergy.map { Measurement(value: $0, unit: UnitEnergy.kilocalories) },
            basalEnergyBurned: results.basalEnergy.map { Measurement(value: $0, unit: UnitEnergy.kilocalories) },
            steps: results.steps.map { Int($0) },
            distance: results.distance.map { Measurement(value: $0, unit: UnitLength.meters) },
            flightsClimbed: results.flights.map { Int($0) },
            exerciseMinutes: results.exerciseTime.map { Int($0) },
            standHours: results.standHours.map { Int($0) },
            moveMinutes: results.moveTime.map { Int($0) },
            currentHeartRate: results.currentHR.map { Int($0) },
            isWorkoutActive: false, // TODO: Implement workout detection
            workoutType: nil,
            moveProgress: nil, // TODO: Calculate from goals
            exerciseProgress: nil,
            standProgress: nil
        )
    }

    /// Fetches heart health metrics
    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
        async let restingHR = fetchLatestQuantitySample(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        async let hrv = fetchLatestQuantitySample(
            identifier: .heartRateVariabilitySDNN,
            unit: HKUnit.secondUnit(with: .milli)
        )

        async let respiratoryRate = fetchLatestQuantitySample(
            identifier: .respiratoryRate,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        async let vo2Max = fetchLatestQuantitySample(
            identifier: .vo2Max,
            unit: HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo)).unitDivided(by: HKUnit.minute())
        )

        async let recovery = fetchLatestQuantitySample(
            identifier: .heartRateRecoveryOneMinute,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        let results = await (
            restingHR: restingHR,
            hrv: hrv,
            respiratoryRate: respiratoryRate,
            vo2Max: vo2Max,
            recovery: recovery
        )

        return HeartHealthMetrics(
            restingHeartRate: results.restingHR.map { Int($0) },
            hrv: results.hrv.map { Measurement(value: $0, unit: UnitDuration.milliseconds) },
            respiratoryRate: results.respiratoryRate,
            vo2Max: results.vo2Max,
            cardioFitness: results.vo2Max.flatMap { HeartHealthMetrics.CardioFitnessLevel.from(vo2Max: $0) },
            recoveryHeartRate: results.recovery.map { Int($0) },
            heartRateRecovery: nil // TODO: Calculate from workout data
        )
    }

    /// Fetches latest body metrics
    func fetchLatestBodyMetrics() async throws -> BodyMetrics {
        async let weight = fetchLatestQuantitySample(
            identifier: .bodyMass,
            unit: HKUnit.gramUnit(with: .kilo)
        )

        async let bodyFat = fetchLatestQuantitySample(
            identifier: .bodyFatPercentage,
            unit: HKUnit.percent()
        )

        async let leanMass = fetchLatestQuantitySample(
            identifier: .leanBodyMass,
            unit: HKUnit.gramUnit(with: .kilo)
        )

        async let bmi = fetchLatestQuantitySample(
            identifier: .bodyMassIndex,
            unit: HKUnit.count()
        )

        let results = await (
            weight: weight,
            bodyFat: bodyFat,
            leanMass: leanMass,
            bmi: bmi
        )

        return BodyMetrics(
            weight: results.weight.map { Measurement(value: $0, unit: UnitMass.kilograms) },
            bodyFatPercentage: results.bodyFat.map { $0 * 100 }, // Convert to percentage
            leanBodyMass: results.leanMass.map { Measurement(value: $0, unit: UnitMass.kilograms) },
            bmi: results.bmi,
            weightTrend: nil, // TODO: Calculate trends
            bodyFatTrend: nil
        )
    }

    /// Fetches last night's sleep session
    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {
        let calendar = Calendar.current
        let now = Date()

        // Look for sleep data from yesterday evening to this morning
        let startDate = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) ?? now
        let endDate = calendar.date(byAdding: .hour, value: 12, to: calendar.startOfDay(for: now)) ?? now

        return try await analyzeSleepSamples(from: startDate, to: endDate)
    }

    // MARK: - Helper Methods

    /// Fetches total quantity for a given identifier and date range
    private func fetchTotalQuantity(
        identifier: HKQuantityTypeIdentifier,
        start: Date,
        end: Date,
        unit: HKUnit
    ) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthKitError.invalidData
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                let value = statistics?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches the latest quantity sample for a given identifier
    private func fetchLatestQuantitySample(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthKitError.invalidData
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
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

    /// Analyzes sleep samples to create a sleep session
    private func analyzeSleepSamples(from startDate: Date, to endDate: Date) async throws -> SleepAnalysis.SleepSession? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.invalidData
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let session = self.createSleepSession(from: sleepSamples)
                continuation.resume(returning: session)
            }

            healthStore.execute(query)
        }
    }

    /// Creates a sleep session from sleep samples
    private func createSleepSession(from samples: [HKCategorySample]) -> SleepAnalysis.SleepSession {
        let bedtime = samples.first?.startDate
        let wakeTime = samples.last?.endDate

        var totalSleepTime: TimeInterval = 0
        var remTime: TimeInterval = 0
        var coreTime: TimeInterval = 0
        var deepTime: TimeInterval = 0
        var awakeTime: TimeInterval = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            // iOS 16+ sleep stages analysis
            if #available(iOS 16.0, *) {
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    remTime += duration
                    totalSleepTime += duration
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    coreTime += duration
                    totalSleepTime += duration
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    deepTime += duration
                    totalSleepTime += duration
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    awakeTime += duration
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                    totalSleepTime += duration
                default:
                    break
                }
            } else {
                // Fallback for older iOS versions
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                    totalSleepTime += duration
                } else if sample.value == HKCategoryValueSleepAnalysis.awake.rawValue {
                    awakeTime += duration
                }
            }
        }

        let timeInBed = bedtime != nil && wakeTime != nil ? wakeTime!.timeIntervalSince(bedtime!) : nil
        let efficiency = timeInBed != nil && timeInBed! > 0 ? (totalSleepTime / timeInBed!) * 100 : nil

        return SleepAnalysis.SleepSession(
            bedtime: bedtime,
            wakeTime: wakeTime,
            totalSleepTime: totalSleepTime > 0 ? totalSleepTime : nil,
            timeInBed: timeInBed,
            efficiency: efficiency,
            remTime: remTime > 0 ? remTime : nil,
            coreTime: coreTime > 0 ? coreTime : nil,
            deepTime: deepTime > 0 ? deepTime : nil,
            awakeTime: awakeTime > 0 ? awakeTime : nil
        )
    }
}

// MARK: - Extensions

extension HeartHealthMetrics.CardioFitnessLevel {
    static func from(vo2Max: Double) -> HeartHealthMetrics.CardioFitnessLevel? {
        // Simplified VO2 Max categorization (would need age/gender specific ranges in production)
        switch vo2Max {
        case 0..<25: return .low
        case 25..<35: return .belowAverage
        case 35..<45: return .average
        case 45..<55: return .aboveAverage
        case 55...: return .high
        default: return nil
        }
    }
}
