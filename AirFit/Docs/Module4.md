**Modular Sub-Document 4: HealthKit & Context Aggregation Module**

**Version:** 2.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Modular Sub-Document 1: Core Project Setup & Configuration.
    *   Completion of Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers) – specifically `DailyLog` and potentially `Workout` if this module also saves HealthKit-derived workouts.
**Date:** May 25, 2025
**Updated For:** iOS 18+, macOS 15+, Xcode 16+, Swift 6+

**1. Module Overview**

*   **Purpose:** To provide comprehensive health data integration through Apple HealthKit, implementing privacy-first data access, real-time health metrics aggregation, and context assembly for AI-driven insights using iOS 18's enhanced HealthKit capabilities.
*   **Responsibilities:**
    *   HealthKit authorization with granular permissions
    *   Real-time and historical health data fetching
    *   Sleep analysis with iOS 18's enhanced sleep stages
    *   Activity metrics including new workout types
    *   Heart health monitoring (HR, HRV, VO2 Max)
    *   Body measurements and trends
    *   Background health data updates
    *   Context assembly for AI coaching
    *   Privacy-compliant data handling
*   **Key Components:**
    *   `HealthKitManager.swift` - Core HealthKit service with async/await
    *   `HealthContextSnapshot.swift` - Comprehensive health context model
    *   `ContextAssembler.swift` - Data aggregation service
    *   `HealthKitTypes.swift` - Type definitions and extensions
    *   Authorization UI components
    *   Background task handlers

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Master Architecture Specification (v1.2) – for the definition of `HealthContextSnapshot` and understanding what data the AI needs.
    *   Modular Sub-Document 1: `AppLogger`, `AppConstants`.
    *   Modular Sub-Document 2: `DailyLog` model (for fetching subjective energy), `Workout` model (if saving HealthKit workouts directly).
    *   (Future) `WeatherServiceAPIClient` (from Services Layer - Part 1) for weather data.
    *   iOS 18 HealthKit framework
    *   Design specifications for health features
*   **Outputs:**
    *   A `HealthKitManager` capable of requesting permissions and fetching data.
    *   A `ContextAssembler` capable of creating up-to-date `HealthContextSnapshot` instances.
    *   The app is correctly configured to request HealthKit permissions.
    *   Health data access for all app features
    *   Real-time context for AI coaching
    *   Background health monitoring

**3. Detailed Component Specifications & Agent Tasks**

*(AI Agent Tasks: These involve creating service classes, data structures, and configuring project settings for HealthKit.)*

---

**Task 4.0: Project Configuration for HealthKit**
    *   **Agent Task 4.0.1:**
        *   Instruction: "Enable HealthKit capability with background delivery"
        *   Details:
            *   Open project settings in Xcode
            *   Select "AirFit" iOS target
            *   Go to "Signing & Capabilities" tab
            *   Click "+" and add "HealthKit"
            *   Check "Background Delivery" option
            *   Do NOT check "Clinical Health Records"
        *   Acceptance Criteria:
            *   HealthKit capability enabled
            *   Background Delivery enabled
            *   AirFit.entitlements updated
    *   **Agent Task 4.0.2:**
        *   Instruction: "Configure Info.plist"
        *   File: `AirFit/Info.plist`
        *   Add these keys:
            ```xml
            <key>NSHealthShareUsageDescription</key>
            <string>AirFit personalizes your fitness journey by analyzing your activity, sleep, heart health, and body metrics. Your AI coach uses this data to provide tailored recommendations and track your progress. All health data remains private and is never shared without your explicit consent.</string>
            
            <key>NSHealthUpdateUsageDescription</key>
            <string>AirFit saves your workouts and body measurements to Apple Health, keeping all your fitness data synchronized. This helps you track progress across all your devices and contributes to your activity rings.</string>
            
            <key>NSHealthClinicalHealthRecordsShareUsageDescription</key>
            <string>AirFit does not access clinical health records.</string>
            ```
        *   Acceptance Criteria:
            *   Specified keys and their string values are present in the iOS target's `Info.plist`.

---

**Task 4.1: Define Health Data Models**
    *   **Agent Task 4.1.1:**
        *   Instruction: "Create HealthContextSnapshot"
        *   File: `AirFit/Core/Models/HealthContextSnapshot.swift`
        *   Complete Implementation:
            ```swift
            import Foundation
            import HealthKit
            
            struct HealthContextSnapshot: Sendable {
                // MARK: - Metadata
                let id: UUID
                let timestamp: Date
                let date: Date // Start of day for context
                
                // MARK: - Subjective Data
                let subjectiveData: SubjectiveData
                
                // MARK: - Environmental Context
                let environment: EnvironmentContext
                
                // MARK: - Activity Metrics
                let activity: ActivityMetrics
                
                // MARK: - Sleep Analysis
                let sleep: SleepAnalysis
                
                // MARK: - Heart Health
                let heartHealth: HeartHealthMetrics
                
                // MARK: - Body Metrics
                let body: BodyMetrics
                
                // MARK: - App Context
                let appContext: AppSpecificContext
                
                // MARK: - Trends
                let trends: HealthTrends
                
                init(
                    id: UUID = UUID(),
                    timestamp: Date = Date(),
                    date: Date = Calendar.current.startOfDay(for: Date()),
                    subjectiveData: SubjectiveData = SubjectiveData(),
                    environment: EnvironmentContext = EnvironmentContext(),
                    activity: ActivityMetrics = ActivityMetrics(),
                    sleep: SleepAnalysis = SleepAnalysis(),
                    heartHealth: HeartHealthMetrics = HeartHealthMetrics(),
                    body: BodyMetrics = BodyMetrics(),
                    appContext: AppSpecificContext = AppSpecificContext(),
                    trends: HealthTrends = HealthTrends()
                ) {
                    self.id = id
                    self.timestamp = timestamp
                    self.date = date
                    self.subjectiveData = subjectiveData
                    self.environment = environment
                    self.activity = activity
                    self.sleep = sleep
                    self.heartHealth = heartHealth
                    self.body = body
                    self.appContext = appContext
                    self.trends = trends
                }
            }
            
            // MARK: - Component Structures
            
            struct SubjectiveData: Sendable {
                var energyLevel: Int? // 1-5
                var mood: Int? // 1-5
                var stress: Int? // 1-5
                var motivation: Int? // 1-5
                var soreness: Int? // 1-5
                var notes: String?
            }
            
            struct EnvironmentContext: Sendable {
                var weatherCondition: String?
                var temperature: Measurement<UnitTemperature>?
                var humidity: Double? // 0-100%
                var airQualityIndex: Int?
                var timeOfDay: TimeOfDay
                
                enum TimeOfDay: String, Sendable {
                    case earlyMorning = "early_morning" // 5-8am
                    case morning = "morning" // 8-12pm
                    case afternoon = "afternoon" // 12-5pm
                    case evening = "evening" // 5-9pm
                    case night = "night" // 9pm-5am
                    
                    init(from date: Date = Date()) {
                        let hour = Calendar.current.component(.hour, from: date)
                        switch hour {
                        case 5..<8: self = .earlyMorning
                        case 8..<12: self = .morning
                        case 12..<17: self = .afternoon
                        case 17..<21: self = .evening
                        default: self = .night
                        }
                    }
                }
            }
            
            struct ActivityMetrics: Sendable {
                // Daily totals
                var activeEnergyBurned: Measurement<UnitEnergy>?
                var basalEnergyBurned: Measurement<UnitEnergy>?
                var steps: Int?
                var distance: Measurement<UnitLength>?
                var flightsClimbed: Int?
                var exerciseMinutes: Int?
                var standHours: Int?
                var moveMinutes: Int?
                
                // Current activity
                var currentHeartRate: Int?
                var isWorkoutActive: Bool = false
                var workoutType: HKWorkoutActivityType?
                
                // Ring progress (0-1)
                var moveProgress: Double?
                var exerciseProgress: Double?
                var standProgress: Double?
            }
            
            struct SleepAnalysis: Sendable {
                var lastNight: SleepSession?
                var weeklyAverage: SleepAverages?
                
                struct SleepSession: Sendable {
                    let bedtime: Date?
                    let wakeTime: Date?
                    let totalSleepTime: TimeInterval?
                    let timeInBed: TimeInterval?
                    let efficiency: Double? // 0-100%
                    
                    // iOS 18 sleep stages
                    let remTime: TimeInterval?
                    let coreTime: TimeInterval?
                    let deepTime: TimeInterval?
                    let awakeTime: TimeInterval?
                    
                    var quality: SleepQuality? {
                        guard let efficiency = efficiency else { return nil }
                        switch efficiency {
                        case 85...: return .excellent
                        case 75..<85: return .good
                        case 65..<75: return .fair
                        default: return .poor
                        }
                    }
                }
                
                struct SleepAverages: Sendable {
                    let averageBedtime: Date?
                    let averageWakeTime: Date?
                    let averageDuration: TimeInterval?
                    let averageEfficiency: Double?
                    let consistency: Double? // 0-100%
                }
                
                enum SleepQuality: String, Sendable {
                    case excellent, good, fair, poor
                }
            }
            
            struct HeartHealthMetrics: Sendable {
                // Resting metrics
                var restingHeartRate: Int?
                var hrv: Measurement<UnitDuration>? // milliseconds
                var respiratoryRate: Double? // breaths/min
                
                // Fitness metrics
                var vo2Max: Double? // ml/kg/min
                var cardioFitness: CardioFitnessLevel?
                
                // Recovery metrics
                var recoveryHeartRate: Int? // 1 min post-workout
                var heartRateRecovery: Int? // Drop from peak
                
                enum CardioFitnessLevel: String, Sendable {
                    case low, belowAverage, average, aboveAverage, high
                }
            }
            
            struct BodyMetrics: Sendable {
                var weight: Measurement<UnitMass>?
                var bodyFatPercentage: Double?
                var leanBodyMass: Measurement<UnitMass>?
                var bmi: Double?
                var bodyMassIndex: BMICategory?
                
                // Trends
                var weightTrend: Trend?
                var bodyFatTrend: Trend?
                
                enum BMICategory: String, Sendable {
                    case underweight, normal, overweight, obese
                    
                    init?(bmi: Double) {
                        switch bmi {
                        case ..<18.5: self = .underweight
                        case 18.5..<25: self = .normal
                        case 25..<30: self = .overweight
                        case 30...: self = .obese
                        default: return nil
                        }
                    }
                }
                
                enum Trend: String, Sendable {
                    case increasing, stable, decreasing
                }
            }
            
            struct AppSpecificContext: Sendable {
                var activeWorkoutName: String?
                var lastMealTime: Date?
                var lastMealSummary: String?
                var waterIntakeToday: Measurement<UnitVolume>?
                var lastCoachInteraction: Date?
                var upcomingWorkout: String?
                var currentStreak: Int?
            }
            
            struct HealthTrends: Sendable {
                var weeklyActivityChange: Double? // percentage
                var sleepConsistencyScore: Double? // 0-100
                var recoveryTrend: RecoveryTrend?
                var performanceTrend: PerformanceTrend?
                
                enum RecoveryTrend: String, Sendable {
                    case wellRecovered, normal, needsRecovery, overreaching
                }
                
                enum PerformanceTrend: String, Sendable {
                    case peaking, improving, maintaining, declining
                }
            }
            ```
        *   Acceptance Criteria: `HealthContextSnapshot.swift` struct is created and compiles. It includes all specified fields with appropriate optionality.

---

**Task 4.2: Implement HealthKitManager**
    *   **Agent Task 4.2.1:**
        *   Instruction: "Create HealthKitManager"
        *   File: `AirFit/Services/Health/HealthKitManager.swift`
        *   Complete Implementation:
            ```swift
            import HealthKit
            import Observation
            
            @MainActor
            @Observable
            final class HealthKitManager {
                // MARK: - Properties
                private let healthStore = HKHealthStore()
                private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
                
                // MARK: - Types
                enum AuthorizationStatus {
                    case notDetermined
                    case authorized
                    case denied
                    case restricted
                }
                
                // MARK: - Data Types Configuration
                private var readTypes: Set<HKObjectType> {
                    let quantityTypes: [HKQuantityTypeIdentifier] = [
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
                        .restingHeartRate,
                        .heartRateVariabilitySDNN,
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
                        
                        // Other
                        .dietaryWater
                    ]
                    
                    var types: Set<HKObjectType> = Set(quantityTypes.compactMap {
                        HKObjectType.quantityType(forIdentifier: $0)
                    })
                    
                    // Category types
                    types.insert(HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
                    types.insert(HKObjectType.categoryType(forIdentifier: .mindfulSession)!)
                    
                    // Workout type
                    types.insert(HKObjectType.workoutType())
                    
                    // iOS 18 - new sleep stages
                    if #available(iOS 18.0, *) {
                        types.insert(HKObjectType.categoryType(forIdentifier: .sleepStages)!)
                    }
                    
                    return types
                }
                
                private var writeTypes: Set<HKSampleType> {
                    [
                        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
                        HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
                        HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
                        HKObjectType.workoutType()
                    ]
                }
                
                // MARK: - Authorization
                func requestAuthorization() async throws {
                    guard HKHealthStore.isHealthDataAvailable() else {
                        authorizationStatus = .restricted
                        throw HealthKitError.notAvailable
                    }
                    
                    do {
                        try await healthStore.requestAuthorization(
                            toShare: writeTypes,
                            read: readTypes
                        )
                        
                        authorizationStatus = .authorized
                        AppLogger.info("HealthKit authorization granted", category: .health)
                        
                    } catch {
                        authorizationStatus = .denied
                        AppLogger.error("HealthKit authorization failed", error: error, category: .health)
                        throw error
                    }
                }
                
                // MARK: - Activity Data Fetching
                func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
                    let calendar = Calendar.current
                    let now = Date()
                    let startOfDay = calendar.startOfDay(for: now)
                    let predicate = HKQuery.predicateForSamples(
                        withStart: startOfDay,
                        end: now,
                        options: .strictStartDate
                    )
                    
                    async let activeEnergy = fetchTotalQuantity(
                        type: .activeEnergyBurned,
                        unit: .kilocalorie(),
                        predicate: predicate
                    )
                    
                    async let steps = fetchTotalQuantity(
                        type: .stepCount,
                        unit: .count(),
                        predicate: predicate
                    )
                    
                    async let distance = fetchTotalQuantity(
                        type: .distanceWalkingRunning,
                        unit: .meter(),
                        predicate: predicate
                    )
                    
                    async let exerciseTime = fetchTotalQuantity(
                        type: .appleExerciseTime,
                        unit: .minute(),
                        predicate: predicate
                    )
                    
                    async let standHours = fetchStandHours(for: now)
                    async let currentHR = fetchLatestHeartRate()
                    
                    let (energy, stepCount, dist, exercise, stand, hr) = try await (
                        activeEnergy,
                        steps,
                        distance,
                        exerciseTime,
                        standHours,
                        currentHR
                    )
                    
                    return ActivityMetrics(
                        activeEnergyBurned: energy.map { Measurement(value: $0, unit: .kilocalories) },
                        steps: stepCount.map { Int($0) },
                        distance: dist.map { Measurement(value: $0, unit: .meters) },
                        exerciseMinutes: exercise.map { Int($0) },
                        standHours: stand,
                        currentHeartRate: hr
                    )
                }
                
                // MARK: - Sleep Data Fetching
                func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {
                    let calendar = Calendar.current
                    let now = Date()
                    
                    // Look for sleep in the past 24 hours
                    guard let startDate = calendar.date(byAdding: .hour, value: -24, to: now) else {
                        return nil
                    }
                    
                    let predicate = HKQuery.predicateForSamples(
                        withStart: startDate,
                        end: now,
                        options: .strictStartDate
                    )
                    
                    let sleepType = HKCategoryType(.sleepAnalysis)
                    
                    return try await withCheckedThrowingContinuation { continuation in
                        let query = HKSampleQuery(
                            sampleType: sleepType,
                            predicate: predicate,
                            limit: HKObjectQueryNoLimit,
                            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
                        ) { _, samples, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                                return
                            }
                            
                            guard let sleepSamples = samples as? [HKCategorySample] else {
                                continuation.resume(returning: nil)
                                return
                            }
                            
                            let session = self.analyzeSleepSamples(sleepSamples)
                            continuation.resume(returning: session)
                        }
                        
                        healthStore.execute(query)
                    }
                }
                
                // MARK: - Heart Health Data
                func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
                    async let rhr = fetchLatestQuantitySample(type: .restingHeartRate, unit: .count().unitDivided(by: .minute()))
                    async let hrv = fetchLatestQuantitySample(type: .heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
                    async let vo2 = fetchLatestQuantitySample(type: .vo2Max, unit: .literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute()))
                    
                    let (restingHR, heartRateVariability, vo2Max) = try await (rhr, hrv, vo2)
                    
                    return HeartHealthMetrics(
                        restingHeartRate: restingHR.map { Int($0) },
                        hrv: heartRateVariability.map { Measurement(value: $0, unit: .milliseconds) },
                        vo2Max: vo2Max
                    )
                }
                
                // MARK: - Body Metrics
                func fetchLatestBodyMetrics() async throws -> BodyMetrics {
                    async let weight = fetchLatestQuantitySample(
                        type: .bodyMass,
                        unit: .gramUnit(with: .kilo)
                    )
                    
                    async let bodyFat = fetchLatestQuantitySample(
                        type: .bodyFatPercentage,
                        unit: .percent()
                    )
                    
                    async let bmi = fetchLatestQuantitySample(
                        type: .bodyMassIndex,
                        unit: .count()
                    )
                    
                    let (weightKg, fatPercent, bmiValue) = try await (weight, bodyFat, bmi)
                    
                    return BodyMetrics(
                        weight: weightKg.map { Measurement(value: $0, unit: .kilograms) },
                        bodyFatPercentage: fatPercent.map { $0 * 100 }, // Convert from decimal
                        bmi: bmiValue,
                        bodyMassIndex: bmiValue.flatMap { BMICategory(bmi: $0) }
                    )
                }
                
                // MARK: - Background Delivery
                func enableBackgroundDelivery() async throws {
                    let types: [(HKQuantityTypeIdentifier, HKUpdateFrequency)] = [
                        (.stepCount, .hourly),
                        (.activeEnergyBurned, .hourly),
                        (.heartRate, .immediate),
                        (.bodyMass, .daily)
                    ]
                    
                    for (identifier, frequency) in types {
                        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
                        
                        try await healthStore.enableBackgroundDelivery(
                            for: type,
                            frequency: frequency
                        )
                    }
                    
                    AppLogger.info("HealthKit background delivery enabled", category: .health)
                }
                
                // MARK: - Private Helper Methods
                private func fetchTotalQuantity(
                    type: HKQuantityTypeIdentifier,
                    unit: HKUnit,
                    predicate: NSPredicate
                ) async throws -> Double? {
                    guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else {
                        return nil
                    }
                    
                    return try await withCheckedThrowingContinuation { continuation in
                        let query = HKStatisticsQuery(
                            quantityType: quantityType,
                            quantitySamplePredicate: predicate,
                            options: .cumulativeSum
                        ) { _, statistics, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                                return
                            }
                            
                            let sum = statistics?.sumQuantity()?.doubleValue(for: unit)
                            continuation.resume(returning: sum)
                        }
                        
                        healthStore.execute(query)
                    }
                }
                
                private func fetchLatestQuantitySample(
                    type: HKQuantityTypeIdentifier,
                    unit: HKUnit
                ) async throws -> Double? {
                    guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else {
                        return nil
                    }
                    
                    return try await withCheckedThrowingContinuation { continuation in
                        let query = HKSampleQuery(
                            sampleType: quantityType,
                            predicate: nil,
                            limit: 1,
                            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                        ) { _, samples, error in
                            if let error = error {
                                continuation.resume(throwing: error)
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
                
                private func fetchLatestHeartRate() async throws -> Int? {
                    try await fetchLatestQuantitySample(
                        type: .heartRate,
                        unit: .count().unitDivided(by: .minute())
                    ).map { Int($0) }
                }
                
                private func fetchStandHours(for date: Date) async throws -> Int? {
                    // Implementation for stand hours calculation
                    // This would involve querying stand samples for each hour of the day
                    return nil // Placeholder
                }
                
                private func analyzeSleepSamples(_ samples: [HKCategorySample]) -> SleepAnalysis.SleepSession? {
                    guard !samples.isEmpty else { return nil }
                    
                    var bedtime = Date.distantFuture
                    var wakeTime = Date.distantPast
                    var totalAsleep: TimeInterval = 0
                    var totalInBed: TimeInterval = 0
                    
                    // iOS 18 sleep stages
                    var remTime: TimeInterval = 0
                    var coreTime: TimeInterval = 0
                    var deepTime: TimeInterval = 0
                    var awakeTime: TimeInterval = 0
                    
                    for sample in samples {
                        let duration = sample.endDate.timeIntervalSince(sample.startDate)
                        
                        if sample.startDate < bedtime {
                            bedtime = sample.startDate
                        }
                        if sample.endDate > wakeTime {
                            wakeTime = sample.endDate
                        }
                        
                        totalInBed += duration
                        
                        switch HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                        case .inBed:
                            // Count as in bed but awake
                            awakeTime += duration
                        case .asleepUnspecified, .asleep:
                            totalAsleep += duration
                        case .awake:
                            awakeTime += duration
                        case .asleepREM:
                            totalAsleep += duration
                            remTime += duration
                        case .asleepCore:
                            totalAsleep += duration
                            coreTime += duration
                        case .asleepDeep:
                            totalAsleep += duration
                            deepTime += duration
                        default:
                            break
                        }
                    }
                    
                    let efficiency = totalInBed > 0 ? (totalAsleep / totalInBed) * 100 : 0
                    
                    return SleepAnalysis.SleepSession(
                        bedtime: bedtime == Date.distantFuture ? nil : bedtime,
                        wakeTime: wakeTime == Date.distantPast ? nil : wakeTime,
                        totalSleepTime: totalAsleep,
                        timeInBed: totalInBed,
                        efficiency: efficiency,
                        remTime: remTime > 0 ? remTime : nil,
                        coreTime: coreTime > 0 ? coreTime : nil,
                        deepTime: deepTime > 0 ? deepTime : nil,
                        awakeTime: awakeTime > 0 ? awakeTime : nil
                    )
                }
            }
            
            // MARK: - Error Types
            enum HealthKitError: LocalizedError {
                case notAvailable
                case authorizationDenied
                case dataNotFound
                case invalidDataType
                
                var errorDescription: String? {
                    switch self {
                    case .notAvailable:
                        return "HealthKit is not available on this device"
                    case .authorizationDenied:
                        return "HealthKit authorization was denied"
                    case .dataNotFound:
                        return "No health data found for the requested type"
                    case .invalidDataType:
                        return "Invalid health data type requested"
                    }
                }
            }
            ```
        *   Acceptance Criteria: `HealthKitManager.swift` created with `healthStore` and data type sets.
    *   **Agent Task 4.2.2 (Authorization):**
        *   Instruction: "Implement `requestHealthKitAuthorization(completion: @escaping (Bool, Error?) -> Void)` method in `HealthKitManager.swift`."
        *   Details:
            *   Check if HealthKit is available using `HKHealthStore.isHealthDataAvailable()`. If not, complete with `false` and an error.
            *   Call `healthStore.requestAuthorization(toShare: writeDataTypes, read: readDataTypes) { success, error in ... }`.
            *   Handle the completion block, log success/failure using `AppLogger`, and call the method's completion handler on the main thread.
        *   Acceptance Criteria: Authorization method correctly requests permissions for defined data types.
    *   **Agent Task 4.2.3 (Data Fetching Methods - Examples):**
        *   Instruction: "Implement asynchronous methods in `HealthKitManager.swift` to fetch key metrics. Start with: `fetchLatestRestingHeartRate() async -> Double?`, `fetchLatestHRV() async -> Double?`, `fetchTodayStepCount() async -> Int?`, `fetchLastNightSleepAnalysis() async -> (duration: Double?, efficiency: Double?, bedtime: Date?, waketime: Date?)`."
        *   Details (Example for one, agent to replicate pattern):
            ```swift
            // In HealthKitManager.swift

            func fetchLastNightSleepAnalysis() async -> (durationInHours: Double?, efficiencyPercentage: Double?, bedtime: Date?, waketime: Date?) {
                guard HKHealthStore.isHealthDataAvailable(),
                      healthStore.authorizationStatus(for: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!) == .sharingAuthorized else {
                    AppLogger.log("HealthKit not available or sleep analysis not authorized.", category: .healthKit, level: .info)
                    return (nil, nil, nil, nil)
                }

                let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
                let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                
                // Predicate for the last 24 hours (adjust as needed for "last night")
                let calendar = Calendar.current
                let endDate = Date()
                guard let startDate = calendar.date(byAdding: .hour, value: -24, to: endDate) else { // More robust "last night" logic might be needed
                    return (nil, nil, nil, nil)
                }
                let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

                return await withCheckedContinuation { continuation in
                    let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                        if let error = error {
                            AppLogger.error("Failed to fetch sleep samples: \(error.localizedDescription)", category: .healthKit, error: error)
                            continuation.resume(returning: (nil, nil, nil, nil))
                            return
                        }

                        guard let sleepSamples = samples as? [HKCategorySample] else {
                            continuation.resume(returning: (nil, nil, nil, nil))
                            return
                        }
                        
                        var totalTimeInBedSeconds: TimeInterval = 0
                        var totalTimeAsleepSeconds: TimeInterval = 0
                        var overallBedtime: Date? = Date.distantFuture // Find earliest start
                        var overallWaketime: Date? = Date.distantPast // Find latest end

                        for sample in sleepSamples {
                            let duration = sample.endDate.timeIntervalSince(sample.startDate)
                            totalTimeInBedSeconds += duration
                            if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue { // Includes InBed, Awake, Asleep, REM, Core, Deep
                                totalTimeAsleepSeconds += duration
                            }
                            if sample.startDate < overallBedtime! { overallBedtime = sample.startDate }
                            if sample.endDate > overallWaketime! { overallWaketime = sample.endDate }
                        }
                        
                        if totalTimeInBedSeconds == 0 {
                            continuation.resume(returning: (nil, nil, nil, nil))
                            return
                        }

                        let durationHours = totalTimeAsleepSeconds / 3600.0
                        let efficiency = (totalTimeAsleepSeconds / totalTimeInBedSeconds) * 100.0
                        
                        let finalBedtime = (overallBedtime == Date.distantFuture) ? nil : overallBedtime
                        let finalWaketime = (overallWaketime == Date.distantPast) ? nil : overallWaketime

                        continuation.resume(returning: (durationHours, efficiency, finalBedtime, finalWaketime))
                    }
                    healthStore.execute(query)
                }
            }
            // Agent to implement other fetch methods (RHR, HRV, Steps, Active Energy, Weight, etc.)
            // For quantity types, use HKStatisticsQuery or HKSampleQuery with appropriate predicates (e.g., for today, or latest sample).
            // Example for a quantity type (latest resting heart rate):
            // Use HKSampleQuery, sort by endDate descending, limit 1.
            // For daily totals (steps, active energy), use HKStatisticsQuery for sum over today's date range.
            ```
        *   Acceptance Criteria: Asynchronous fetching methods for specified HealthKit data are implemented, use appropriate query types, handle errors, and return optional values.
    *   **Agent Task 4.2.4 (Human/Designer Task - Refine "Last Night" Logic):**
        *   The logic for "last night's sleep" can be tricky (e.g., user goes to bed after midnight). Review and refine the predicate for `fetchLastNightSleepAnalysis` to accurately capture the primary sleep session preceding the current day. Common approach: query samples from (yesterday 12 PM) to (today 12 PM), then find the longest "inBed" session. This needs careful thought and testing.

---

**Task 4.3: Implement ContextAssembler Service**
    *   **Agent Task 4.3.1:**
        *   Instruction: "Create a new Swift file named `ContextAssembler.swift` in `AirFit/Services/Context/` (or `AirFit/Services/AI/`)."
        *   Details:
            *   Define a class `ContextAssembler`.
            *   It should have access to `HealthKitManager` (via dependency injection or as a shared instance).
            *   (Future) It will also access other services like `WeatherServiceAPIClient` and the app's SwiftData `ModelContext` (passed in or accessed via environment).
        *   Acceptance Criteria: `ContextAssembler.swift` class structure created.
    *   **Agent Task 4.3.2:**
        *   Instruction: "Implement an asynchronous method `assembleSnapshot(modelContext: ModelContext) async -> HealthContextSnapshot` in `ContextAssembler.swift`."
        *   Details:
            *   This method will call the various fetching methods on `HealthKitManager`.
            *   It will fetch subjective data (e.g., `subjectiveEnergyLevel`) from `DailyLog` for the current day using the provided `modelContext`. (Agent needs to implement a fetch request for `DailyLog` for today's date).
            *   (Stub for now) It will call (mocked) `WeatherService` to get weather data.
            *   (Stub for now) It will fetch app-specific context (active workout, last meal summary - this might require querying `Workout` and `FoodEntry` from `modelContext`).
            *   Populate all fields of a `HealthContextSnapshot` instance with the fetched/stubbed data.
            *   Return the `HealthContextSnapshot`.
            *   Use `AppLogger` for any errors during assembly.
            ```swift
            // In ContextAssembler.swift
            import SwiftData
            import Foundation // For ModelContext if not directly in SwiftUI environment

            class ContextAssembler {
                private let healthKitManager: HealthKitManager
                // private let weatherService: WeatherServiceAPIClient // Add when WeatherService is available
                // Add other services as needed

                init(healthKitManager: HealthKitManager /*, weatherService: WeatherServiceAPIClient */) {
                    self.healthKitManager = healthKitManager
                    // self.weatherService = weatherService
                }

                func assembleSnapshot(modelContext: ModelContext) async -> HealthContextSnapshot {
                    // Fetch HealthKit Data (concurrently if possible)
                    async let rhr = healthKitManager.fetchLatestRestingHeartRate()
                    async let hrv = healthKitManager.fetchLatestHRV()
                    async let steps = healthKitManager.fetchTodayStepCount()
                    // ... other HealthKit calls (active energy, exercise time, stand hours, weight, body fat)
                    async let sleepData = healthKitManager.fetchLastNightSleepAnalysis()
                    
                    // Fetch Subjective Data from DailyLog for today
                    var subjectiveEnergy: Int? = nil
                    let todayStart = Calendar.current.startOfDay(for: Date())
                    let predicate = #Predicate<DailyLog> { log in log.date == todayStart }
                    var descriptor = FetchDescriptor<DailyLog>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
                    descriptor.fetchLimit = 1
                    do {
                        let logs = try modelContext.fetch(descriptor)
                        subjectiveEnergy = logs.first?.subjectiveEnergyLevel
                    } catch {
                        AppLogger.error("Failed to fetch today's DailyLog: \(error.localizedDescription)", category: .data, error: error)
                    }

                    // Fetch Weather Data (Mock for now)
                    let weatherCondition: String? = "Sunny (Mock)" // await weatherService.getCurrentWeather().condition
                    let temperature: Double? = 22.0 // await weatherService.getCurrentWeather().temperatureCelsius

                    // Fetch App-Specific Context (Stubs for now)
                    let activeWorkoutName: String? = nil // Logic to check current app state
                    let timeSinceLastInteraction: Int? = 60 // Logic to check last CoachMessage timestamp
                    // Logic to get last meal summary from FoodEntry
                    let lastMealLoggedSummary: String? = "Breakfast, 1 hour ago (Mock)"
                    // Logic to get upcoming planned workout from Workout
                    let upcomingWorkoutName: String? = "Upper Body Strength (Mock)"


                    // Await all HealthKit results
                    let (rhrValue, hrvValue, stepsValue, sleep) = await (rhr, hrv, steps, sleepData)
                    // ... await other healthKit results

                    return HealthContextSnapshot(
                        subjectiveEnergyLevel: subjectiveEnergy,
                        currentWeatherCondition: weatherCondition,
                        currentTemperatureCelsius: temperature,
                        restingHeartRateBPM: rhrValue,
                        heartRateVariabilitySDNNms: hrvValue,
                        stepCountToday: stepsValue,
                        // ... populate all other fields from fetched/stubbed data
                        lastNightSleepDurationHours: sleep.durationInHours,
                        lastNightSleepEfficiencyPercentage: sleep.efficiencyPercentage,
                        lastNightBedtime: sleep.bedtime,
                        lastNightWaketime: sleep.waketime,
                        activeWorkoutNameInProgress: activeWorkoutName,
                        timeSinceLastCoachInteractionMinutes: timeSinceLastInteraction,
                        lastMealLogged: lastMealLoggedSummary,
                        upcomingPlannedWorkoutName: upcomingWorkoutName
                        // ... etc.
                    )
                }
            }
            ```
        *   Acceptance Criteria: `assembleSnapshot` method implemented, calls (mocked or real) services, and constructs a `HealthContextSnapshot`.

---

**Task 4.4: Integrate HealthKit Authorization into App Flow**
    *   **Agent Task 4.4.1:**
        *   Instruction: "Determine where and when to request HealthKit authorization. A common place is during onboarding (e.g., after explaining its benefits) or on first access to a feature that requires it."
        *   Details: For AirFit, a good point might be towards the end of the "Persona Blueprint Flow" (e.g., before the "Generating Coach" screen) or when the user first lands on the Dashboard if they skipped/deferred onboarding authorization.
        *   Create a method in `OnboardingViewModel` (or a shared app state manager) like `func requestHealthKitAccessIfNeeded(healthKitManager: HealthKitManager, completion: @escaping (Bool) -> Void)`. This method would call `healthKitManager.requestHealthKitAuthorization`.
        *   The UI (e.g., a specific onboarding screen or a modal on the dashboard) should then call this method.
        *   Acceptance Criteria: A clear strategy for triggering HealthKit authorization is defined, and placeholder for UI interaction is noted. The method to trigger it is added to an appropriate ViewModel/Manager.
    *   **Agent Task 4.4.2 (UI - Placeholder):**
        *   Instruction: "Designate a specific point in the UI flow (e.g., a new Onboarding screen or a button on the Dashboard) where the `requestHealthKitAccessIfNeeded` method will be called."
        *   Details: Agent to note this down. Actual UI implementation for this trigger can be a separate task in the Onboarding or Dashboard module. For now, ensure the logic hook exists.
        *   Acceptance Criteria: The trigger point is documented.

---

**Task 4.5: Final Review & Commit**
    *   **Agent Task 4.5.1:**
        *   Instruction: "Review `HealthKitManager.swift`, `ContextAssembler.swift`, and `HealthContextSnapshot.swift` for correctness, adherence to specifications, error handling, and asynchronous operation best practices."
        *   Acceptance Criteria: All components function as intended, code is clean, and follows styling guidelines.
    *   **Agent Task 4.5.2:**
        *   Instruction: "Ensure HealthKit entitlements and `Info.plist` descriptions are correctly configured."
        *   Acceptance Criteria: Project configuration for HealthKit is complete.
    *   **Agent Task 4.5.3:**
        *   Instruction: "Stage all new and modified files related to this module."
        *   Acceptance Criteria: `git status` shows all relevant files staged.
    *   **Agent Task 4.5.4:**
        *   Instruction: "Commit the staged changes with a descriptive message."
        *   Details: Commit message: "Feat: Implement HealthKitManager and ContextAssembler for health data aggregation".
        *   Acceptance Criteria: Git history shows the new commit. Project builds successfully.

**Task 4.6: Add Unit Tests**
    *   **Agent Task 4.6.1 (HealthKitManager Unit Tests):**
        *   Instruction: "Create `HealthKitManagerTests.swift` in `AirFitTests/`."
        *   Details: Use in-memory containers and mocks for HealthKit as outlined in `TESTING_GUIDELINES.md`.
        *   Acceptance Criteria: Tests compile and pass.
    *   **Agent Task 4.6.2 (ContextAssembler Unit Tests):**
        *   Instruction: "Create `ContextAssemblerTests.swift` in `AirFitTests/`."
        *   Details: Mock dependencies and verify assembled snapshots.
        *   Acceptance Criteria: Tests compile and pass.

---

**4. Acceptance Criteria for Module Completion**

*   The Xcode project is correctly configured with HealthKit capabilities and `Info.plist` usage descriptions.
*   The `HealthContextSnapshot` struct is defined with all required fields.
*   `HealthKitManager` can request user authorization and fetch specified HealthKit data types asynchronously.
*   `ContextAssembler` can create a `HealthContextSnapshot` by gathering data from `HealthKitManager` and other (mocked for now) sources.
*   A clear point in the app flow is identified for triggering HealthKit authorization.
*   All code passes SwiftLint checks and adheres to project conventions.
*   The module is committed to Git.
*   Unit tests for `HealthKitManager` and `ContextAssembler` are implemented and pass.

**5. Code Style Reminders for this Module**

*   Use `async/await` for all HealthKit data fetching operations.
*   Handle HealthKit authorization status and errors gracefully.
*   Ensure all HealthKit queries are efficient and only request necessary data.
*   Use `AppLogger` extensively for debugging HealthKit interactions and context assembly.
*   When dealing with `Date` predicates for HealthKit, be very careful about time zones and start/end of day logic. HealthKit stores data in UTC but usually queries are made based on local calendar days.

---

This module involves significant interaction with a platform framework (HealthKit) and requires careful handling of permissions, asynchronous operations, and data transformation. Clear, testable methods in `HealthKitManager` will be key. The `ContextAssembler` will grow in complexity as more data sources (like live weather, detailed app state) are integrated.
