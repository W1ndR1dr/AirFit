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
}
