import Foundation
import HealthKit
import Observation

/// # HealthKitManager
/// 
/// ## Purpose
/// Comprehensive health data integration service that manages all HealthKit operations.
/// Provides bidirectional sync between AirFit and Apple Health for fitness and nutrition data.
///
/// ## Dependencies
/// - `HealthKitDataFetcher`: Handles complex HealthKit queries and data aggregation
/// - `HealthKitSleepAnalyzer`: Specialized sleep data analysis and pattern detection
///
/// ## Key Responsibilities
/// - Request and manage HealthKit authorization
/// - Fetch activity metrics (steps, calories, distance, etc.)
/// - Read and write nutrition data (macros, water intake)
/// - Sync workout data bidirectionally
/// - Analyze sleep patterns and recovery metrics
/// - Track heart health indicators (HRV, resting HR, VO2 Max)
/// - Monitor body composition metrics
///
/// ## Usage
/// ```swift
/// let healthKit = await container.resolve(HealthKitManagerProtocol.self)
/// 
/// // Request authorization
/// try await healthKit.requestAuthorization()
/// 
/// // Fetch today's metrics
/// let activity = try await healthKit.fetchTodayActivityMetrics()
/// 
/// // Save nutrition data
/// let sampleIDs = try await healthKit.saveFoodEntry(foodEntry)
/// ```
///
/// ## Important Notes
/// - @MainActor isolated for UI updates and @Observable support
/// - Handles background delivery for continuous sync
/// - Automatically manages HealthKit session lifecycle
@MainActor
@Observable
final class HealthKitManager: HealthKitManaging, ServiceProtocol {
    // MARK: - Properties
    private let healthStore = HKHealthStore()
    private let dataFetcher: HealthKitDataFetcher
    private let sleepAnalyzer: HealthKitSleepAnalyzer
    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "healthkit-manager"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // Since this is @MainActor, we need to check on main thread
        return MainActor.assumeIsolated { _isConfigured }
    }

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
    init() {
        self.dataFetcher = HealthKitDataFetcher(healthStore: healthStore)
        self.sleepAnalyzer = HealthKitSleepAnalyzer(healthStore: healthStore)
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        
        refreshAuthorizationStatus()
        _isConfigured = true
        
        AppLogger.info("HealthKitManager configured", category: .health)
    }
    
    func reset() async {
        authorizationStatus = .notDetermined
        _isConfigured = false
        AppLogger.info("HealthKitManager reset", category: .health)
    }
    
    nonisolated func healthCheck() async -> ServiceHealth {
        await MainActor.run {
            let canAccessHealthKit = HKHealthStore.isHealthDataAvailable()
            let hasAuthorization = authorizationStatus == .authorized
            
            let status: ServiceHealth.Status
            let errorMessage: String?
            
            if !canAccessHealthKit {
                status = .unhealthy
                errorMessage = "HealthKit not available on this device"
            } else if !hasAuthorization {
                status = authorizationStatus == .notDetermined ? .degraded : .unhealthy
                errorMessage = authorizationStatus == .notDetermined ? "Authorization not requested" : "Authorization denied"
            } else {
                status = .healthy
                errorMessage = nil
            }
            
            return ServiceHealth(
                status: status,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: errorMessage,
                metadata: [
                    "authorizationStatus": authorizationStatus.rawValue,
                    "healthKitAvailable": "\(canAccessHealthKit)"
                ]
            )
        }
    }

    // MARK: - Authorization
    func requestAuthorization() async throws {
        AppLogger.info("HealthKit: Starting authorization request", category: .health)
        
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .restricted
            AppLogger.error("HealthKit: Not available on this device", category: .health)
            throw AppError.from(HealthKitError.notAvailable)
        }

        do {
            AppLogger.info("HealthKit: Requesting authorization for \(HealthKitDataTypes.readTypes.count) read types and \(HealthKitDataTypes.writeTypes.count) write types", category: .health)
            
            try await healthStore.requestAuthorization(
                toShare: HealthKitDataTypes.writeTypes,
                read: HealthKitDataTypes.readTypes
            )
            
            // Check actual authorization status after request
            refreshAuthorizationStatus()
            
            AppLogger.info("HealthKit: Authorization request completed, status: \(authorizationStatus)", category: .health)

            // Enable background delivery after successful authorization
            if authorizationStatus == .authorized {
                do {
                    try await dataFetcher.enableBackgroundDelivery()
                    AppLogger.info("HealthKit: Background delivery enabled", category: .health)
                } catch {
                    AppLogger.error("Failed to enable HealthKit background delivery", error: error, category: .health)
                }
            }
        } catch let error as NSError {
            authorizationStatus = .denied
            AppLogger.error("HealthKit authorization failed with NSError code: \(error.code), domain: \(error.domain), description: \(error.localizedDescription)", category: .health)
            throw error
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
            identifier: .heartRate, 
            unit: HKUnit.count().unitDivided(by: HKUnit.minute()),
            daysBack: 1  // Only look at today's HR
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
        // Check for active workout
        let activeWorkout = try await fetchActiveWorkout()
        metrics.isWorkoutActive = activeWorkout != nil
        metrics.workoutType = activeWorkout?.workoutActivityType
        // Calculate progress from goals
        let (moveGoal, exerciseGoal, standGoal) = try await fetchActivityGoals()
        
        if let calories = metrics.activeEnergyBurned?.value, let goal = moveGoal {
            metrics.moveProgress = calories / goal
        }
        
        if let minutes = metrics.exerciseMinutes, let goal = exerciseGoal {
            metrics.exerciseProgress = Double(minutes) / Double(goal)
        }
        
        if let hours = metrics.standHours, let goal = standGoal {
            metrics.standProgress = Double(hours) / Double(goal)
        }

        return metrics
    }

    /// Fetches heart health metrics
    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
        // Fetch only the most critical metrics with tight time bounds
        async let restingHR = dataFetcher.fetchLatestQuantitySample(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute()),
            daysBack: 3  // Only look at last 3 days
        )

        async let hrv = dataFetcher.fetchLatestQuantitySample(
            identifier: .heartRateVariabilitySDNN,
            unit: HKUnit.secondUnit(with: .milli),
            daysBack: 3  // HRV from last 3 days is sufficient
        )

        // Skip less critical metrics for initial load
        let respiratoryRate: Double? = nil
        let vo2Max: Double? = nil
        let recovery: Double? = nil
        
        // Await only the critical metrics
        let restingHRValue = try await restingHR
        let hrvValue = try await hrv

        return HeartHealthMetrics(
            restingHeartRate: restingHRValue.map { Int($0) },
            hrv: hrvValue.map { Measurement(value: $0, unit: UnitDuration.milliseconds) },
            respiratoryRate: respiratoryRate,
            vo2Max: vo2Max,
            cardioFitness: vo2Max.flatMap {
                HeartHealthMetrics.CardioFitnessLevel.from(vo2Max: $0)
            },
            recoveryHeartRate: recovery.map { Int($0) },
            heartRateRecovery: nil  // Skip expensive calculation for initial load
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
            weightTrend: await calculateWeightTrend(),
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

        // Limit sleep analysis to reduce data volume
        return try await sleepAnalyzer.analyzeSleepSamples(from: startDate, to: endDate, limit: 100)
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
                    limit: 20,  // Limit to recent 20 workouts instead of unlimited
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
            throw AppError.from(HealthKitError.notAvailable)
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
            throw AppError.from(HealthKitError.invalidData)
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
        
        // Create workout using HKWorkoutBuilder for iOS 17+
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = hkWorkoutType
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)
        
        try await builder.beginCollection(at: startDate)
        
        // Add metadata
        try await builder.addMetadata(metadata)
        
        // Add energy burned if available
        if let totalEnergy = totalEnergy {
            let energySample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                quantity: totalEnergy,
                start: startDate,
                end: endDate
            )
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder.add([energySample]) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
        
        // Add distance if available
        if let distance = workout.distance {
            let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: distance)
            let distanceSample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                quantity: distanceQuantity,
                start: startDate,
                end: endDate
            )
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder.add([distanceSample]) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
        
        // End collection and finish workout
        try await builder.endCollection(at: endDate)
        let hkWorkout = try await builder.finishWorkout()
        
        guard let hkWorkout = hkWorkout else {
            throw AppError.from(HealthKitError.invalidData)
        }
        
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
            throw AppError.from(HealthKitError.invalidData)
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
            throw AppError.from(HealthKitError.dataNotFound)
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
    
    // MARK: - Workout Detection
    
    /// Fetches currently active workout if any
    private func fetchActiveWorkout() async throws -> HKWorkout? {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3_600)
        
        // Create predicate for workouts that started within the last hour and have no end date
        let startDatePredicate = HKQuery.predicateForSamples(withStart: oneHourAgo, end: now, options: .strictStartDate)
        let noEndDatePredicate = NSPredicate(format: "endDate == nil")
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [startDatePredicate, noEndDatePredicate])
        
        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
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
        
        return workouts.first
    }
    
    /// Fetches activity goals from HealthKit
    private func fetchActivityGoals() async throws -> (move: Double?, exercise: Int?, stand: Int?) {
        // Get activity summary for today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let goalData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(move: Double?, exercise: Int?, stand: Int?), Error>) in
            let components = calendar.dateComponents([.year, .month, .day], from: today)
            let endComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: components, end: endComponents)
            
            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let summary = summaries?.first {
                    // Extract data within the completion handler
                    let moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: HKUnit.kilocalorie())
                    let exerciseGoal = Int(summary.appleExerciseTimeGoal.doubleValue(for: HKUnit.minute()))
                    let standGoal = Int(summary.appleStandHoursGoal.doubleValue(for: HKUnit.count()))
                    
                    continuation.resume(returning: (
                        move: moveGoal > 0 ? moveGoal : nil,
                        exercise: exerciseGoal > 0 ? exerciseGoal : nil,
                        stand: standGoal > 0 ? standGoal : nil
                    ))
                } else {
                    // No summary found, use defaults
                    continuation.resume(returning: (move: 500, exercise: 30, stand: 12))
                }
            }
            
            healthStore.execute(query)
        }
        
        return goalData
    }
    
    /// Calculates heart rate recovery based on recent workout data
    private func calculateHeartRateRecovery() async -> Int? {
        // Get recent workouts (last 7 days)
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        do {
            let workouts = try await dataFetcher.fetchWorkouts(from: startDate, to: endDate)
            
            // Find workouts with heart rate recovery data
            var recoveryValues: [Int] = []
            
            for workout in workouts {
                // Get heart rate samples during and after workout
                let workoutEnd = workout.endDate
                let recoveryWindow = workoutEnd.addingTimeInterval(60) // 1 minute after workout
                
                let hrSamples = try await dataFetcher.fetchQuantitySamples(
                    identifier: .heartRate,
                    unit: HKUnit.count().unitDivided(by: HKUnit.minute()),
                    from: workoutEnd,
                    to: recoveryWindow
                )
                
                // Get peak HR during workout
                let peakHR = try await dataFetcher.fetchQuantitySamples(
                    identifier: .heartRate,
                    unit: HKUnit.count().unitDivided(by: HKUnit.minute()),
                    from: workout.startDate,
                    to: workoutEnd
                ).max(by: { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) <
                          $1.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) })
                
                guard let peak = peakHR,
                      let recoveryHR = hrSamples.last else { continue }
                
                let peakValue = Int(peak.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                let recoveryValue = Int(recoveryHR.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                let recovery = peakValue - recoveryValue
                
                if recovery > 0 {
                    recoveryValues.append(recovery)
                }
            }
            
            // Calculate average recovery
            guard !recoveryValues.isEmpty else { return nil }
            
            let avgRecovery = recoveryValues.reduce(0, +) / recoveryValues.count
            
            // Return average recovery (beats dropped in 1 minute)
            return avgRecovery
            
        } catch {
            AppLogger.error("Failed to calculate heart rate recovery: \(error)", category: .health)
            return nil
        }
    }
    
    /// Calculates weight trend over the last 30 days
    private func calculateWeightTrend() async -> BodyMetrics.Trend? {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        do {
            let samples = try await dataFetcher.fetchQuantitySamples(
                identifier: HKQuantityTypeIdentifier.bodyMass,
                unit: HKUnit.gramUnit(with: .kilo),
                from: startDate,
                to: endDate
            )
            
            guard samples.count >= 2 else { return nil }
            
            // Sort by date
            let sortedSamples = samples.sorted { $0.startDate < $1.startDate }
            
            // Get first and last week averages
            let firstWeek = sortedSamples.prefix(7)
            let lastWeek = sortedSamples.suffix(7)
            
            guard !firstWeek.isEmpty && !lastWeek.isEmpty else { return nil }
            
            let firstAvg = firstWeek.reduce(0.0) { sum, sample in
                sum + sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            } / Double(firstWeek.count)
            
            let lastAvg = lastWeek.reduce(0.0) { sum, sample in
                sum + sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            } / Double(lastWeek.count)
            
            let change = lastAvg - firstAvg
            let percentChange = (change / firstAvg) * 100
            
            // Determine trend based on change
            if abs(percentChange) < 1 {
                return .stable
            } else if change > 0 {
                return .increasing
            } else {
                return .decreasing
            }
            
        } catch {
            AppLogger.error("Failed to calculate weight trend: \(error)", category: .health)
            return nil
        }
    }

}

// MARK: - Authorization Status Extension
extension HealthKitManager.AuthorizationStatus: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        switch rawValue {
        case "notDetermined": self = .notDetermined
        case "authorized": self = .authorized
        case "denied": self = .denied
        case "restricted": self = .restricted
        default: return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .restricted: return "restricted"
        }
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
