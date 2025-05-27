import Foundation
import HealthKit

/// Handles HealthKit data fetching operations
@MainActor
final class HealthKitDataFetcher {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - Background Delivery

    /// Enables background delivery for key HealthKit data types
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

    // MARK: - Data Fetching Methods

    /// Fetches total quantity for a given identifier and date range
    func fetchTotalQuantity(
        identifier: HKQuantityTypeIdentifier,
        start: Date,
        end: Date,
        unit: HKUnit
    ) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthKitManager.HealthKitError.invalidData
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitManager.HealthKitError.queryFailed(error))
                    return
                }

                let value = statistics?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches the latest quantity sample for a given identifier
    func fetchLatestQuantitySample(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthKitManager.HealthKitError.invalidData
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
                    continuation.resume(throwing: HealthKitManager.HealthKitError.queryFailed(error))
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
}
