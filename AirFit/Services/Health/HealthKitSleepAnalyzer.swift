import Foundation
import HealthKit

/// Handles HealthKit sleep analysis operations
actor HealthKitSleepAnalyzer: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "healthkit-sleep-analyzer"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { true } // Always ready when health store is available

    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    /// Analyzes sleep samples to create a sleep session
    func analyzeSleepSamples(from startDate: Date, to endDate: Date, limit: Int = 200) async throws -> SleepAnalysis.SleepSession? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.noData
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: limit,  // Limit samples to avoid fetching entire history
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
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
    nonisolated private func createSleepSession(from samples: [HKCategorySample]) -> SleepAnalysis.SleepSession {
        let bedtime = samples.first?.startDate
        let wakeTime = samples.last?.endDate

        var totalSleepTime: TimeInterval = 0
        var remTime: TimeInterval = 0
        var coreTime: TimeInterval = 0
        var deepTime: TimeInterval = 0
        var awakeTime: TimeInterval = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            // Sleep stages analysis (available since iOS 16)
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
        }

        let timeInBed: TimeInterval?
        if let bedtime = bedtime, let wakeTime = wakeTime {
            timeInBed = wakeTime.timeIntervalSince(bedtime)
        } else {
            timeInBed = nil
        }
        
        let efficiency: Double?
        if let timeInBed = timeInBed, timeInBed > 0 {
            efficiency = (totalSleepTime / timeInBed) * 100
        } else {
            efficiency = nil
        }

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
}
