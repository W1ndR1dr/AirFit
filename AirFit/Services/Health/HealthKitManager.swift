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
    private let dataFetcher: HealthKitDataFetcher
    private let sleepAnalyzer: HealthKitSleepAnalyzer
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

    // MARK: - Initialization
    private init() {
        self.dataFetcher = HealthKitDataFetcher(healthStore: healthStore)
        self.sleepAnalyzer = HealthKitSleepAnalyzer(healthStore: healthStore)
        refreshAuthorizationStatus()
    }

    // MARK: - Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .restricted
            throw HealthKitError.notAvailable
        }

        do {
            try await healthStore.requestAuthorization(
                toShare: HealthKitDataTypes.writeTypes,
                read: HealthKitDataTypes.readTypes
            )
            authorizationStatus = .authorized
            AppLogger.info("HealthKit authorization granted", category: .health)

            // Enable background delivery after successful authorization
            do {
                try await dataFetcher.enableBackgroundDelivery()
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

    // MARK: - Data Fetching Methods

    /// Fetches today's activity metrics
    func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now

        return try await fetchActivityMetrics(from: startOfDay, to: endOfDay)
    }

    /// Fetches activity metrics for a specific date range
    private func fetchActivityMetrics(from startDate: Date, to endDate: Date) async throws -> ActivityMetrics {
        async let activeEnergy = dataFetcher.fetchTotalQuantity(
            identifier: .activeEnergyBurned, start: startDate, end: endDate, unit: HKUnit.kilocalorie()
        )
        async let basalEnergy = dataFetcher.fetchTotalQuantity(
            identifier: .basalEnergyBurned, start: startDate, end: endDate, unit: HKUnit.kilocalorie()
        )
        async let steps = dataFetcher.fetchTotalQuantity(
            identifier: .stepCount, start: startDate, end: endDate, unit: HKUnit.count()
        )
        async let distance = dataFetcher.fetchTotalQuantity(
            identifier: .distanceWalkingRunning, start: startDate, end: endDate, unit: HKUnit.meter()
        )
        async let flights = dataFetcher.fetchTotalQuantity(
            identifier: .flightsClimbed, start: startDate, end: endDate, unit: HKUnit.count()
        )
        async let exerciseTime = dataFetcher.fetchTotalQuantity(
            identifier: .appleExerciseTime, start: startDate, end: endDate, unit: HKUnit.minute()
        )
        async let standHours = dataFetcher.fetchTotalQuantity(
            identifier: .appleStandTime, start: startDate, end: endDate, unit: HKUnit.count()
        )
        async let moveTime = dataFetcher.fetchTotalQuantity(
            identifier: .appleMoveTime, start: startDate, end: endDate, unit: HKUnit.minute()
        )
        async let currentHR = dataFetcher.fetchLatestQuantitySample(
            identifier: .heartRate, unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        var metrics = ActivityMetrics()
        metrics.activeEnergyBurned = (try await activeEnergy).map { Measurement(value: $0, unit: UnitEnergy.kilocalories) }
        metrics.basalEnergyBurned = (try await basalEnergy).map { Measurement(value: $0, unit: UnitEnergy.kilocalories) }
        metrics.steps = (try await steps).map { Int($0) }
        metrics.distance = (try await distance).map { Measurement(value: $0, unit: UnitLength.meters) }
        metrics.flightsClimbed = (try await flights).map { Int($0) }
        metrics.exerciseMinutes = (try await exerciseTime).map { Int($0) }
        metrics.standHours = (try await standHours).map { Int($0) }
        metrics.moveMinutes = (try await moveTime).map { Int($0) }
        metrics.currentHeartRate = (try await currentHR).map { Int($0) }
        metrics.isWorkoutActive = false // TODO: Implement workout detection
        metrics.workoutType = nil
        metrics.moveProgress = nil // TODO: Calculate from goals
        metrics.exerciseProgress = nil
        metrics.standProgress = nil

        return metrics
    }

    /// Fetches heart health metrics
    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
        async let restingHR = dataFetcher.fetchLatestQuantitySample(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        async let hrv = dataFetcher.fetchLatestQuantitySample(
            identifier: .heartRateVariabilitySDNN,
            unit: HKUnit.secondUnit(with: .milli)
        )

        async let respiratoryRate = dataFetcher.fetchLatestQuantitySample(
            identifier: .respiratoryRate,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        async let vo2Max = dataFetcher.fetchLatestQuantitySample(
            identifier: .vo2Max,
            unit: HKUnit.literUnit(with: .milli)
                .unitDivided(by: HKUnit.gramUnit(with: .kilo))
                .unitDivided(by: HKUnit.minute())
        )

        async let recovery = dataFetcher.fetchLatestQuantitySample(
            identifier: .heartRateRecoveryOneMinute,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute())
        )

        return HeartHealthMetrics(
            restingHeartRate: (try await restingHR).map { Int($0) },
            hrv: (try await hrv).map { Measurement(value: $0, unit: UnitDuration.milliseconds) },
            respiratoryRate: try await respiratoryRate,
            vo2Max: try await vo2Max,
            cardioFitness: (try await vo2Max).flatMap {
                HeartHealthMetrics.CardioFitnessLevel.from(vo2Max: $0)
            },
            recoveryHeartRate: (try await recovery).map { Int($0) },
            heartRateRecovery: nil // TODO: Calculate from workout data
        )
    }

    /// Fetches latest body metrics
    func fetchLatestBodyMetrics() async throws -> BodyMetrics {
        async let weight = dataFetcher.fetchLatestQuantitySample(
            identifier: .bodyMass,
            unit: HKUnit.gramUnit(with: .kilo)
        )

        async let bodyFat = dataFetcher.fetchLatestQuantitySample(
            identifier: .bodyFatPercentage,
            unit: HKUnit.percent()
        )

        async let leanMass = dataFetcher.fetchLatestQuantitySample(
            identifier: .leanBodyMass,
            unit: HKUnit.gramUnit(with: .kilo)
        )

        async let bmi = dataFetcher.fetchLatestQuantitySample(
            identifier: .bodyMassIndex,
            unit: HKUnit.count()
        )

        return BodyMetrics(
            weight: (try await weight).map { Measurement(value: $0, unit: UnitMass.kilograms) },
            bodyFatPercentage: (try await bodyFat).map { $0 * 100 }, // Convert to percentage
            leanBodyMass: (try await leanMass).map { Measurement(value: $0, unit: UnitMass.kilograms) },
            bmi: try await bmi,
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

        return try await sleepAnalyzer.analyzeSleepSamples(from: startDate, to: endDate)
    }
    
    /// Fetches workout data within date range
    func getWorkoutData(from startDate: Date, to endDate: Date) async -> [WorkoutData] {
        // Create predicate for date range
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Create query
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        // Use HKWorkoutType
        let workoutType = HKObjectType.workoutType()
        
        // Execute query with async/await
        return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: workoutType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { (_, samples, error) in
                    if let error = error {
                        AppLogger.error("Failed to fetch workouts", error: error, category: .health)
                        continuation.resume(returning: [])
                        return
                    }
                    
                    let workouts = (samples as? [HKWorkout] ?? []).map { workout in
                        // Use statistics for activeEnergyBurned instead of deprecated totalEnergyBurned
                        let activeEnergy = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()
                        
                        return WorkoutData(
                            id: workout.uuid,
                            duration: workout.duration,
                            totalCalories: activeEnergy?.doubleValue(for: .kilocalorie()),
                            workoutType: workout.workoutActivityType,
                            startDate: workout.startDate,
                            endDate: workout.endDate
                        )
                    }
                    
                    continuation.resume(returning: workouts)
                }
                
                healthStore.execute(query)
            }
    }
    
    // MARK: - Nutrition Writing
    
    /// Saves nutrition data from a food entry to HealthKit
    func saveFoodEntry(_ entry: FoodEntry) async throws -> [String] {
        var savedSampleIDs: [String] = []
        var samples: [HKQuantitySample] = []
        
        // Calculate totals from all food items
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0
        var totalFiber: Double = 0
        var totalSugar: Double = 0
        var totalSodium: Double = 0
        
        for item in entry.items {
            totalCalories += item.calories ?? 0
            totalProtein += item.proteinGrams ?? 0
            totalCarbs += item.carbGrams ?? 0
            totalFat += item.fatGrams ?? 0
            totalFiber += item.fiberGrams ?? 0
            totalSugar += item.sugarGrams ?? 0
            totalSodium += item.sodiumMg ?? 0
        }
        
        let metadata: [String: Any] = [
            "AirFitFoodEntryID": entry.id.uuidString,
            "AirFitMealType": entry.mealType,
            "AirFitSource": "User Input",
            "AirFitItemCount": entry.items.count
        ]
        
        let date = entry.loggedAt
        
        // Create samples for each nutrient
        if totalCalories > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: totalCalories)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date, metadata: metadata)
            samples.append(sample)
        }
        
        if totalProtein > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: totalProtein)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date, metadata: metadata)
            samples.append(sample)
        }
        
        if totalCarbs > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: totalCarbs)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date, metadata: metadata)
            samples.append(sample)
        }
        
        if totalFat > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: totalFat)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date, metadata: metadata)
            samples.append(sample)
        }
        
        if totalFiber > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryFiber) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: totalFiber)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date, metadata: metadata)
            samples.append(sample)
        }
        
        if totalSugar > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietarySugar) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: totalSugar)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date, metadata: metadata)
            samples.append(sample)
        }
        
        if totalSodium > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietarySodium) {
            let quantity = HKQuantity(unit: .gramUnit(with: .milli), doubleValue: totalSodium)
            let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date, metadata: metadata)
            samples.append(sample)
        }
        
        // Save all samples
        guard !samples.isEmpty else {
            AppLogger.warning("No nutrition data to save for food entry", category: .health)
            return []
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(samples) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitError.queryFailed(NSError(domain: "HealthKit", code: -1)))
                }
            }
        }
        
        // Collect sample IDs
        savedSampleIDs = samples.map { $0.uuid.uuidString }
        
        AppLogger.info("Saved \(samples.count) nutrition samples to HealthKit for food entry", category: .health)
        return savedSampleIDs
    }
    
    /// Saves water intake to HealthKit
    func saveWaterIntake(amountML: Double, date: Date = Date()) async throws -> String? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthKitError.notAvailable
        }
        
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amountML)
        let metadata: [String: Any] = [
            "AirFitSource": "Water Tracking",
            "AirFitTimestamp": date.timeIntervalSince1970
        ]
        
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date, metadata: metadata)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(sample) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitError.queryFailed(NSError(domain: "HealthKit", code: -1)))
                }
            }
        }
        
        AppLogger.info("Saved water intake of \(amountML)ml to HealthKit", category: .health)
        return sample.uuid.uuidString
    }
    
    // MARK: - Nutrition Reading
    
    /// Fetches nutrition data for a specific date
    func getNutritionData(for date: Date) async throws -> HealthKitNutritionSummary {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        // Fetch all nutrition types
        let calories = try await fetchNutritionSum(for: .dietaryEnergyConsumed, unit: .kilocalorie(), predicate: predicate)
        let protein = try await fetchNutritionSum(for: .dietaryProtein, unit: .gram(), predicate: predicate)
        let carbs = try await fetchNutritionSum(for: .dietaryCarbohydrates, unit: .gram(), predicate: predicate)
        let fat = try await fetchNutritionSum(for: .dietaryFatTotal, unit: .gram(), predicate: predicate)
        let fiber = try await fetchNutritionSum(for: .dietaryFiber, unit: .gram(), predicate: predicate)
        let sugar = try await fetchNutritionSum(for: .dietarySugar, unit: .gram(), predicate: predicate)
        let sodium = try await fetchNutritionSum(for: .dietarySodium, unit: .gramUnit(with: .milli), predicate: predicate)
        let water = try await fetchNutritionSum(for: .dietaryWater, unit: .literUnit(with: .milli), predicate: predicate)
        
        return HealthKitNutritionSummary(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            water: water,
            date: date
        )
    }
    
    private nonisolated func fetchNutritionSum(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        predicate: NSPredicate
    ) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return 0
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sum = statistics?.sumQuantity() {
                    continuation.resume(returning: sum.doubleValue(for: unit))
                } else {
                    continuation.resume(returning: 0)
                }
            }
            
            HKHealthStore().execute(query)
        }
    }
    
    // MARK: - Workout Writing
    
    /// Saves a workout to HealthKit
    func saveWorkout(_ workout: Workout) async throws -> String {
        guard let workoutType = workout.workoutTypeEnum else {
            throw HealthKitError.invalidData
        }
        
        let hkWorkoutType = workoutType.toHealthKitType()
        let startDate = workout.plannedDate ?? Date()
        let endDate = workout.completedDate ?? Date()
        
        // Create energy burned quantity
        var totalEnergy: HKQuantity?
        if let calories = workout.caloriesBurned {
            totalEnergy = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        }
        
        // Create workout metadata
        let metadata: [String: Any] = [
            "AirFitWorkoutID": workout.id.uuidString,
            "AirFitWorkoutName": workout.name,
            "AirFitIntensity": workout.intensity ?? "moderate",
            "AirFitSource": "AirFit App"
        ]
        
        // Build workout
        let hkWorkout = HKWorkout(
            activityType: hkWorkoutType,
            start: startDate,
            end: endDate,
            duration: workout.duration ?? 0,
            totalEnergyBurned: totalEnergy,
            totalDistance: nil, // TODO: Add distance tracking when available
            metadata: metadata
        )
        
        // Save workout
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(hkWorkout) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitError.queryFailed(NSError(domain: "HealthKit", code: -1)))
                }
            }
        }
        
        AppLogger.info("Saved workout to HealthKit: \(workout.name)", category: .health)
        return hkWorkout.uuid.uuidString
    }
    
    /// Deletes a workout from HealthKit
    func deleteWorkout(healthKitID: String) async throws {
        guard let uuid = UUID(uuidString: healthKitID) else {
            throw HealthKitError.invalidData
        }
        
        // Create predicate to find the workout
        let predicate = HKQuery.predicateForObject(with: uuid)
        
        // Query for the workout
        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let workouts = (samples as? [HKWorkout]) ?? []
                    continuation.resume(returning: workouts)
                }
            }
            healthStore.execute(query)
        }
        
        guard let workout = workouts.first else {
            throw HealthKitError.dataNotFound
        }
        
        // Delete the workout
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.delete(workout) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitError.queryFailed(NSError(domain: "HealthKit", code: -1)))
                }
            }
        }
        
        AppLogger.info("Deleted workout from HealthKit", category: .health)
    }

}

// MARK: - Nutrition Summary Model
struct HealthKitNutritionSummary {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let water: Double
    let date: Date
}

// MARK: - Workout Data Model
struct WorkoutData {
    let id: UUID
    let duration: TimeInterval
    let totalCalories: Double?
    let workoutType: HKWorkoutActivityType
    let startDate: Date
    let endDate: Date
}
