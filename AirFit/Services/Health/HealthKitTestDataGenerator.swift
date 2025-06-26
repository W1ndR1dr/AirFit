import Foundation
import HealthKit

/// # HealthKitTestDataGenerator
///
/// ## Purpose
/// Generates realistic test data for HealthKit in the iOS Simulator.
/// This is only available in DEBUG builds to help with development and testing.
///
/// ## Features
/// - Generate activity data (steps, calories, distance, etc.)
/// - Create nutrition entries with realistic macros
/// - Add body measurements (weight, body fat, etc.)
/// - Create workout sessions
/// - Generate sleep data
/// - Add heart health metrics (heart rate, HRV, etc.)
///
/// ## Usage
/// ```swift
/// #if DEBUG
/// let generator = HealthKitTestDataGenerator(healthStore: healthStore)
/// try await generator.generateTestDataForToday()
/// ```
///
/// ## Important Notes
/// - Only available in DEBUG builds
/// - Designed for iOS Simulator testing
/// - Generates data that looks realistic in HealthKit
/// - All data is backdated to avoid interfering with real data

#if DEBUG

@MainActor
final class HealthKitTestDataGenerator {
    private let healthStore: HKHealthStore
    private let calendar = Calendar.current

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - Public Methods

    /// Generates a comprehensive set of test data for today
    func generateTestDataForToday() async throws {
        let today = Date()

        // Generate various types of data
        try await generateActivityData(for: today)
        try await generateNutritionData(for: today)
        try await generateBodyMetrics(for: today)
        try await generateWorkoutData(for: today)
        try await generateSleepData(for: today)
        try await generateHeartHealthData(for: today)

        AppLogger.info("Generated test HealthKit data for \(today)", category: .health)
    }

    /// Generates test data for the past N days
    func generateHistoricalData(days: Int) async throws {
        for daysAgo in 0..<days {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

            try await generateActivityData(for: date)
            try await generateNutritionData(for: date)

            // Add body metrics less frequently
            if daysAgo % 3 == 0 {
                try await generateBodyMetrics(for: date)
            }

            // Add workouts on some days
            if [0, 2, 4, 5].contains(daysAgo % 7) {
                try await generateWorkoutData(for: date)
            }

            // Add sleep data for all days
            try await generateSleepData(for: date)

            // Add heart health data
            try await generateHeartHealthData(for: date)
        }

        AppLogger.info("Generated \(days) days of historical HealthKit test data", category: .health)
    }

    // MARK: - Activity Data

    func generateActivityData(for date: Date) async throws {
        let startOfDay = calendar.startOfDay(for: date)

        // Generate hourly step data
        var stepSamples: [HKQuantitySample] = []
        var caloriesSamples: [HKQuantitySample] = []
        var distanceSamples: [HKQuantitySample] = []

        for hour in 6...22 { // Active hours from 6 AM to 10 PM
            let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay) ?? startOfDay
            let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? hourStart

            // Vary activity based on time of day
            let baseSteps = Double.random(in: 100...500)
            let multiplier: Double = {
                switch hour {
                case 7...9, 12...13, 17...19: return 2.5 // Commute and lunch times
                case 10...11, 14...16: return 1.5 // Work hours
                default: return 1.0
                }
            }()

            let steps = baseSteps * multiplier
            let calories = steps * 0.04 // Rough estimate
            let distance = steps * 0.762 // Average step length in meters

            // Steps
            if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
                let stepQuantity = HKQuantity(unit: .count(), doubleValue: steps)
                let stepSample = HKQuantitySample(
                    type: stepType,
                    quantity: stepQuantity,
                    start: hourStart,
                    end: hourEnd,
                    metadata: ["AirFitTestData": true]
                )
                stepSamples.append(stepSample)
            }

            // Active calories
            if let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
                let calorieSample = HKQuantitySample(
                    type: calorieType,
                    quantity: calorieQuantity,
                    start: hourStart,
                    end: hourEnd,
                    metadata: ["AirFitTestData": true]
                )
                caloriesSamples.append(calorieSample)
            }

            // Distance
            if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
                let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: distance)
                let distanceSample = HKQuantitySample(
                    type: distanceType,
                    quantity: distanceQuantity,
                    start: hourStart,
                    end: hourEnd,
                    metadata: ["AirFitTestData": true]
                )
                distanceSamples.append(distanceSample)
            }
        }

        // Save all samples
        let allSamples = stepSamples + caloriesSamples + distanceSamples
        try await saveHealthKitSamples(allSamples)

        // Add stand hours
        try await generateStandHours(for: date)

        // Add exercise minutes
        try await generateExerciseMinutes(for: date)
    }

    private func generateStandHours(for date: Date) async throws {
        let startOfDay = calendar.startOfDay(for: date)
        var standSamples: [HKCategorySample] = []

        guard let standType = HKCategoryType.categoryType(forIdentifier: .appleStandHour) else { return }

        for hour in 7...21 { // Stand hours from 7 AM to 9 PM
            // 80% chance of standing each hour
            if Double.random(in: 0...1) < 0.8 {
                let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay) ?? startOfDay

                let standSample = HKCategorySample(
                    type: standType,
                    value: HKCategoryValueAppleStandHour.stood.rawValue,
                    start: hourStart,
                    end: hourStart,
                    metadata: ["AirFitTestData": true]
                )
                standSamples.append(standSample)
            }
        }

        try await saveHealthKitSamples(standSamples)
    }

    private func generateExerciseMinutes(for date: Date) async throws {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return }

        let startOfDay = calendar.startOfDay(for: date)
        var exerciseSamples: [HKQuantitySample] = []

        // Morning exercise
        if Double.random(in: 0...1) < 0.6 {
            let morningStart = calendar.date(byAdding: .hour, value: 7, to: startOfDay) ?? startOfDay
            let morningEnd = calendar.date(byAdding: .minute, value: 30, to: morningStart) ?? morningStart

            let morningQuantity = HKQuantity(unit: .minute(), doubleValue: 30)
            let morningSample = HKQuantitySample(
                type: exerciseType,
                quantity: morningQuantity,
                start: morningStart,
                end: morningEnd,
                metadata: ["AirFitTestData": true]
            )
            exerciseSamples.append(morningSample)
        }

        // Evening exercise
        if Double.random(in: 0...1) < 0.5 {
            let eveningStart = calendar.date(byAdding: .hour, value: 18, to: startOfDay) ?? startOfDay
            let eveningEnd = calendar.date(byAdding: .minute, value: 45, to: eveningStart) ?? eveningStart

            let eveningQuantity = HKQuantity(unit: .minute(), doubleValue: 45)
            let eveningSample = HKQuantitySample(
                type: exerciseType,
                quantity: eveningQuantity,
                start: eveningStart,
                end: eveningEnd,
                metadata: ["AirFitTestData": true]
            )
            exerciseSamples.append(eveningSample)
        }

        try await saveHealthKitSamples(exerciseSamples)
    }

    // MARK: - Nutrition Data

    func generateNutritionData(for date: Date) async throws {
        let startOfDay = calendar.startOfDay(for: date)

        // Breakfast
        let breakfastTime = calendar.date(byAdding: .hour, value: 8, to: startOfDay) ?? startOfDay
        try await generateMeal(
            at: breakfastTime,
            calories: Double.random(in: 300...500),
            protein: Double.random(in: 15...30),
            carbs: Double.random(in: 40...70),
            fat: Double.random(in: 10...20),
            fiber: Double.random(in: 3...8),
            sugar: Double.random(in: 10...25),
            sodium: Double.random(in: 200...400)
        )

        // Lunch
        let lunchTime = calendar.date(byAdding: .hour, value: 12, to: startOfDay) ?? startOfDay
        try await generateMeal(
            at: lunchTime,
            calories: Double.random(in: 500...700),
            protein: Double.random(in: 25...40),
            carbs: Double.random(in: 50...80),
            fat: Double.random(in: 15...30),
            fiber: Double.random(in: 5...10),
            sugar: Double.random(in: 15...30),
            sodium: Double.random(in: 400...800)
        )

        // Dinner
        let dinnerTime = calendar.date(byAdding: .hour, value: 19, to: startOfDay) ?? startOfDay
        try await generateMeal(
            at: dinnerTime,
            calories: Double.random(in: 600...800),
            protein: Double.random(in: 30...50),
            carbs: Double.random(in: 60...90),
            fat: Double.random(in: 20...35),
            fiber: Double.random(in: 7...12),
            sugar: Double.random(in: 10...20),
            sodium: Double.random(in: 500...1_000)
        )

        // Snacks
        if Double.random(in: 0...1) < 0.7 {
            let snackTime = calendar.date(byAdding: .hour, value: 15, to: startOfDay) ?? startOfDay
            try await generateMeal(
                at: snackTime,
                calories: Double.random(in: 100...200),
                protein: Double.random(in: 5...15),
                carbs: Double.random(in: 15...30),
                fat: Double.random(in: 5...10),
                fiber: Double.random(in: 1...3),
                sugar: Double.random(in: 10...20),
                sodium: Double.random(in: 50...200)
            )
        }

        // Water intake throughout the day
        try await generateWaterIntake(for: date)
    }

    private func generateMeal(
        at time: Date,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double,
        sugar: Double,
        sodium: Double
    ) async throws {
        var samples: [HKQuantitySample] = []
        let metadata: [String: Any] = ["AirFitTestData": true, "MealType": "Generated"]

        // Calories
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: time, end: time, metadata: metadata)
            samples.append(sample)
        }

        // Protein
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: protein)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: time, end: time, metadata: metadata)
            samples.append(sample)
        }

        // Carbs
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: carbs)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: time, end: time, metadata: metadata)
            samples.append(sample)
        }

        // Fat
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: fat)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: time, end: time, metadata: metadata)
            samples.append(sample)
        }

        // Fiber
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryFiber) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: fiber)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: time, end: time, metadata: metadata)
            samples.append(sample)
        }

        // Sugar
        if let type = HKQuantityType.quantityType(forIdentifier: .dietarySugar) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: sugar)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: time, end: time, metadata: metadata)
            samples.append(sample)
        }

        // Sodium
        if let type = HKQuantityType.quantityType(forIdentifier: .dietarySodium) {
            let quantity = HKQuantity(unit: .gramUnit(with: .milli), doubleValue: sodium)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: time, end: time, metadata: metadata)
            samples.append(sample)
        }

        try await saveHealthKitSamples(samples)
    }

    private func generateWaterIntake(for date: Date) async throws {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }

        let startOfDay = calendar.startOfDay(for: date)
        var waterSamples: [HKQuantitySample] = []

        // Generate water intake throughout the day
        for hour in stride(from: 7, to: 22, by: 3) {
            let drinkTime = calendar.date(byAdding: .hour, value: hour, to: startOfDay) ?? startOfDay
            let amount = Double.random(in: 200...500) // ml

            let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amount)
            let sample = HKQuantitySample(
                type: waterType,
                quantity: quantity,
                start: drinkTime,
                end: drinkTime,
                metadata: ["AirFitTestData": true]
            )
            waterSamples.append(sample)
        }

        try await saveHealthKitSamples(waterSamples)
    }

    // MARK: - Body Metrics

    func generateBodyMetrics(for date: Date) async throws {
        let measurementTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date) ?? date
        var samples: [HKQuantitySample] = []

        // Weight (varying slightly)
        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            let baseWeight = 75.0 // kg
            let variation = Double.random(in: -0.5...0.5)
            let weight = baseWeight + variation

            let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weight)
            let sample = HKQuantitySample(
                type: weightType,
                quantity: quantity,
                start: measurementTime,
                end: measurementTime,
                metadata: ["AirFitTestData": true]
            )
            samples.append(sample)
        }

        // Body fat percentage
        if let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) {
            let bodyFat = Double.random(in: 0.15...0.25) // 15-25%

            let quantity = HKQuantity(unit: .percent(), doubleValue: bodyFat)
            let sample = HKQuantitySample(
                type: bodyFatType,
                quantity: quantity,
                start: measurementTime,
                end: measurementTime,
                metadata: ["AirFitTestData": true]
            )
            samples.append(sample)
        }

        // BMI
        if let bmiType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) {
            let bmi = Double.random(in: 20...27)

            let quantity = HKQuantity(unit: .count(), doubleValue: bmi)
            let sample = HKQuantitySample(
                type: bmiType,
                quantity: quantity,
                start: measurementTime,
                end: measurementTime,
                metadata: ["AirFitTestData": true]
            )
            samples.append(sample)
        }

        try await saveHealthKitSamples(samples)
    }

    // MARK: - Workout Data

    func generateWorkoutData(for date: Date) async throws {
        let workoutTypes: [HKWorkoutActivityType] = [
            .running,
            .cycling,
            .walking,
            .functionalStrengthTraining,
            .traditionalStrengthTraining,
            .yoga,
            .swimming
        ]

        let selectedType = workoutTypes.randomElement() ?? .running
        let startOfDay = calendar.startOfDay(for: date)

        // Morning or evening workout
        let isMorning = Double.random(in: 0...1) < 0.5
        let workoutHour = isMorning ? 7 : 18

        let workoutStart = calendar.date(byAdding: .hour, value: workoutHour, to: startOfDay) ?? startOfDay
        let duration = Double.random(in: 1_800...5_400) // 30-90 minutes
        let workoutEnd = workoutStart.addingTimeInterval(duration)

        // Calculate calories based on workout type and duration
        let caloriesPerMinute: Double = {
            switch selectedType {
            case .running: return 10
            case .cycling: return 8
            case .swimming: return 11
            case .functionalStrengthTraining, .traditionalStrengthTraining: return 6
            case .yoga: return 3
            case .walking: return 4
            default: return 5
            }
        }()

        let totalCalories = (duration / 60) * caloriesPerMinute

        // Create workout
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = selectedType

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)

        try await builder.beginCollection(at: workoutStart)

        // Add metadata
        let metadata: [String: Any] = [
            "AirFitTestData": true,
            "WorkoutType": selectedType.name
        ]
        try await builder.addMetadata(metadata)

        // Add samples during workout

        // Active energy
        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: totalCalories)
            let energySample = HKQuantitySample(
                type: energyType,
                quantity: energyQuantity,
                start: workoutStart,
                end: workoutEnd
            )
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                builder.add([energySample]) { _, _ in
                    continuation.resume()
                }
            }
        }

        // Distance for applicable workouts
        if [.running, .cycling, .walking, .swimming].contains(selectedType) {
            if let distanceType = HKQuantityType.quantityType(forIdentifier: selectedType == .swimming ? .distanceSwimming : .distanceWalkingRunning) {
                let distancePerMinute: Double = {
                    switch selectedType {
                    case .running: return 160 // meters per minute
                    case .cycling: return 300
                    case .walking: return 80
                    case .swimming: return 30
                    default: return 100
                    }
                }()

                let totalDistance = (duration / 60) * distancePerMinute
                let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: totalDistance)
                let distanceSample = HKQuantitySample(
                    type: distanceType,
                    quantity: distanceQuantity,
                    start: workoutStart,
                    end: workoutEnd
                )
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    builder.add([distanceSample]) { _, _ in
                        continuation.resume()
                    }
                }
            }
        }

        // Heart rate samples during workout
        try await generateWorkoutHeartRate(for: builder, start: workoutStart, end: workoutEnd, activityType: selectedType)

        // End collection and finish workout
        try await builder.endCollection(at: workoutEnd)
        _ = try await builder.finishWorkout()
    }

    private func generateWorkoutHeartRate(
        for builder: HKWorkoutBuilder,
        start: Date,
        end: Date,
        activityType: HKWorkoutActivityType
    ) async throws {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        // Base heart rate based on activity
        let baseHR: Double = {
            switch activityType {
            case .running: return 150
            case .cycling: return 140
            case .swimming: return 145
            case .functionalStrengthTraining, .traditionalStrengthTraining: return 120
            case .yoga: return 85
            case .walking: return 100
            default: return 110
            }
        }()

        var hrSamples: [HKQuantitySample] = []
        let sampleInterval: TimeInterval = 60 // One sample per minute

        var currentTime = start
        while currentTime < end {
            let variation = Double.random(in: -10...10)
            let heartRate = baseHR + variation

            let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: heartRate)
            let sample = HKQuantitySample(
                type: hrType,
                quantity: quantity,
                start: currentTime,
                end: currentTime
            )
            hrSamples.append(sample)

            currentTime = currentTime.addingTimeInterval(sampleInterval)
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            builder.add(hrSamples) { _, _ in
                continuation.resume()
            }
        }
    }

    // MARK: - Sleep Data

    func generateSleepData(for date: Date) async throws {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let startOfDay = calendar.startOfDay(for: date)

        // Previous night's sleep (ending in the morning of the given date)
        let bedtime = calendar.date(byAdding: .hour, value: -2, to: startOfDay) ?? startOfDay // 10 PM previous day
        let wakeTime = calendar.date(byAdding: .hour, value: 7, to: startOfDay) ?? startOfDay // 7 AM

        var sleepSamples: [HKCategorySample] = []

        // In bed sample
        let inBedSample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.inBed.rawValue,
            start: bedtime,
            end: wakeTime,
            metadata: ["AirFitTestData": true]
        )
        sleepSamples.append(inBedSample)

        // Asleep samples with some awake periods
        var currentTime = bedtime.addingTimeInterval(600) // Fall asleep after 10 minutes

        while currentTime < wakeTime.addingTimeInterval(-600) { // Wake up 10 minutes before alarm
            let sleepDuration = Double.random(in: 2_700...5_400) // 45-90 minutes
            let sleepEnd = min(currentTime.addingTimeInterval(sleepDuration), wakeTime.addingTimeInterval(-600))

            // Core sleep
            let coreSleepSample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                start: currentTime,
                end: sleepEnd,
                metadata: ["AirFitTestData": true]
            )
            sleepSamples.append(coreSleepSample)

            // REM sleep (20% chance)
            if Double.random(in: 0...1) < 0.2 {
                let remDuration = Double.random(in: 600...1_800) // 10-30 minutes
                let remStart = currentTime.addingTimeInterval(sleepDuration * 0.7)
                let remEnd = min(remStart.addingTimeInterval(remDuration), sleepEnd)

                let remSample = HKCategorySample(
                    type: sleepType,
                    value: HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    start: remStart,
                    end: remEnd,
                    metadata: ["AirFitTestData": true]
                )
                sleepSamples.append(remSample)
            }

            // Deep sleep (30% chance)
            if Double.random(in: 0...1) < 0.3 {
                let deepDuration = Double.random(in: 900...2_700) // 15-45 minutes
                let deepStart = currentTime.addingTimeInterval(sleepDuration * 0.3)
                let deepEnd = min(deepStart.addingTimeInterval(deepDuration), sleepEnd)

                let deepSample = HKCategorySample(
                    type: sleepType,
                    value: HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    start: deepStart,
                    end: deepEnd,
                    metadata: ["AirFitTestData": true]
                )
                sleepSamples.append(deepSample)
            }

            currentTime = sleepEnd

            // Brief awake period
            if currentTime < wakeTime.addingTimeInterval(-1_800) { // Not in the last 30 minutes
                let awakeDuration = Double.random(in: 60...300) // 1-5 minutes
                currentTime = currentTime.addingTimeInterval(awakeDuration)
            }
        }

        try await saveHealthKitSamples(sleepSamples)
    }

    // MARK: - Heart Health Data

    func generateHeartHealthData(for date: Date) async throws {
        let startOfDay = calendar.startOfDay(for: date)

        // Resting heart rate (morning measurement)
        if let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            let morningTime = calendar.date(byAdding: .hour, value: 7, to: startOfDay) ?? startOfDay
            let restingHR = Double.random(in: 55...75)

            let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: restingHR)
            let sample = HKQuantitySample(
                type: restingHRType,
                quantity: quantity,
                start: morningTime,
                end: morningTime,
                metadata: ["AirFitTestData": true]
            )
            try await saveHealthKitSamples([sample])
        }

        // Heart rate throughout the day
        if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            var hrSamples: [HKQuantitySample] = []

            for hour in stride(from: 7, to: 23, by: 2) {
                let measurementTime = calendar.date(byAdding: .hour, value: hour, to: startOfDay) ?? startOfDay

                // Vary based on time of day
                let baseHR: Double = {
                    switch hour {
                    case 7...9: return 70 // Morning
                    case 10...12: return 75 // Mid-morning
                    case 13...15: return 80 // Afternoon
                    case 16...18: return 75 // Late afternoon
                    case 19...22: return 70 // Evening
                    default: return 65
                    }
                }()

                let hr = baseHR + Double.random(in: -5...10)
                let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: hr)
                let sample = HKQuantitySample(
                    type: hrType,
                    quantity: quantity,
                    start: measurementTime,
                    end: measurementTime,
                    metadata: ["AirFitTestData": true]
                )
                hrSamples.append(sample)
            }

            try await saveHealthKitSamples(hrSamples)
        }

        // HRV (morning measurement)
        if let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            let morningTime = calendar.date(byAdding: .hour, value: 7, to: startOfDay) ?? startOfDay
            let hrv = Double.random(in: 30...60) // milliseconds

            let quantity = HKQuantity(unit: .secondUnit(with: .milli), doubleValue: hrv)
            let sample = HKQuantitySample(
                type: hrvType,
                quantity: quantity,
                start: morningTime,
                end: morningTime,
                metadata: ["AirFitTestData": true]
            )
            try await saveHealthKitSamples([sample])
        }

        // VO2 Max (weekly measurement)
        if calendar.component(.weekday, from: date) == 2 { // Only on Mondays
            if let vo2Type = HKQuantityType.quantityType(forIdentifier: .vo2Max) {
                let measurementTime = calendar.date(byAdding: .hour, value: 12, to: startOfDay) ?? startOfDay
                let vo2Max = Double.random(in: 35...55) // ml/kg/min

                let quantity = HKQuantity(
                    unit: HKUnit.literUnit(with: .milli)
                        .unitDivided(by: HKUnit.gramUnit(with: .kilo))
                        .unitDivided(by: .minute()),
                    doubleValue: vo2Max
                )
                let sample = HKQuantitySample(
                    type: vo2Type,
                    quantity: quantity,
                    start: measurementTime,
                    end: measurementTime,
                    metadata: ["AirFitTestData": true]
                )
                try await saveHealthKitSamples([sample])
            }
        }
    }

    // MARK: - Helper Methods

    private func saveHealthKitSamples(_ samples: [HKSample]) async throws {
        guard !samples.isEmpty else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(samples) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitManager.HealthKitError.queryFailed(
                        NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save samples"])
                    ))
                }
            }
        }
    }
}


#endif // DEBUG
