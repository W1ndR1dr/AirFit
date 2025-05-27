import Foundation
import HealthKit

/// Manages HealthKit data type configurations
enum HealthKitDataTypes {
    /// All HealthKit data types that the app requests read access to
    static var readTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()

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

    /// All HealthKit data types that the app requests write access to
    static var writeTypes: Set<HKSampleType> {
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
}
