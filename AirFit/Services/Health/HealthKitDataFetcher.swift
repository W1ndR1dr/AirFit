import Foundation
import HealthKit

/// Handles HealthKit data fetching operations
actor HealthKitDataFetcher: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "healthkit-data-fetcher"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { true } // Always ready when health store is available
    
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
        unit: HKUnit,
        daysBack: Int = 7  // Limit how far back we look
    ) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthKitManager.HealthKitError.invalidData
        }

        // Only look for recent data to avoid scanning entire history
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
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
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: HKHealthStore.isHealthDataAvailable() ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: HKHealthStore.isHealthDataAvailable() ? nil : "HealthKit not available",
            metadata: [
                "healthDataAvailable": "\(HKHealthStore.isHealthDataAvailable())"
            ]
        )
    }
    
    // MARK: - Additional Data Fetching Methods
    
    /// Fetches quantity samples for a given identifier and date range
    func fetchQuantitySamples(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKQuantitySample] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthKitManager.HealthKitError.invalidData
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitManager.HealthKitError.queryFailed(error))
                    return
                }
                
                let quantitySamples = (samples as? [HKQuantitySample]) ?? []
                continuation.resume(returning: quantitySamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetches workouts for a given date range
    func fetchWorkouts(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitManager.HealthKitError.queryFailed(error))
                    return
                }
                
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
}
