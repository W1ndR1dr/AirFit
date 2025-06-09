import Foundation
import HealthKit

/// Handles HealthKit sleep analysis operations
actor HealthKitSleepAnalyzer {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    /// Analyzes sleep samples to create a sleep session
    func analyzeSleepSamples(from startDate: Date, to endDate: Date) async throws -> SleepAnalysis.SleepSession? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitManager.HealthKitError.invalidData
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
                    continuation.resume(throwing: HealthKitManager.HealthKitError.queryFailed(error))
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
