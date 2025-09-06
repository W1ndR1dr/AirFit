import Foundation
import HealthKit
@testable import AirFit

/// Fake HealthKit manager for testing
/// Provides configurable responses and behavior for all HealthKit operations
@MainActor
final class HealthKitManagerFake: HealthKitManaging {
    
    // MARK: - Configuration Properties
    
    var shouldThrowAuthorizationError = false
    var shouldThrowDataError = false
    var authorizationDelay: TimeInterval = 0
    var dataFetchDelay: TimeInterval = 0
    
    // MARK: - HealthKitManaging Protocol
    
    private(set) var authorizationStatus: HealthKitManager.AuthorizationStatus = .notDetermined
    
    // MARK: - Configurable Test Data
    
    var mockActivityMetrics = ActivityMetrics()
    var mockHeartHealthMetrics = HeartHealthMetrics()
    var mockBodyMetrics = BodyMetrics()
    var mockSleepSession: SleepAnalysis.SleepSession?
    var mockWorkoutData: [WorkoutData] = []
    var mockDailyBiometrics: [DailyBiometrics] = []
    var mockNutritionSummary = HealthKitNutritionSummary(
        date: Date(),
        calories: 0,
        protein: 0,
        carbohydrates: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0
    )
    var mockBodyMetricsHistory: [BodyMetrics] = []
    
    // MARK: - Call Tracking
    
    private(set) var refreshAuthorizationStatusCallCount = 0
    private(set) var requestAuthorizationCallCount = 0
    private(set) var fetchTodayActivityMetricsCallCount = 0
    private(set) var fetchHeartHealthMetricsCallCount = 0
    private(set) var fetchLatestBodyMetricsCallCount = 0
    private(set) var fetchLastNightSleepCallCount = 0
    private(set) var getWorkoutDataCallCount = 0
    private(set) var fetchRecentWorkoutsCallCount = 0
    private(set) var saveFoodEntryCallCount = 0
    private(set) var saveWorkoutCallCount = 0
    private(set) var deleteWorkoutCallCount = 0
    private(set) var saveBodyMassCallCount = 0
    private(set) var saveBodyFatPercentageCallCount = 0
    private(set) var saveLeanBodyMassCallCount = 0
    private(set) var observeBodyMetricsCallCount = 0
    
    // MARK: - Saved Data Tracking
    
    private(set) var savedFoodEntries: [FoodEntry] = []
    private(set) var savedWorkouts: [Workout] = []
    private(set) var deletedWorkoutIDs: [String] = []
    private(set) var savedBodyMassEntries: [(weight: Double, date: Date)] = []
    private(set) var savedBodyFatEntries: [(percentage: Double, date: Date)] = []
    private(set) var savedLeanMassEntries: [(mass: Double, date: Date)] = []
    
    // MARK: - Observer Management
    
    private var observers: [Any] = []
    private var bodyMetricsHandlers: [@Sendable () -> Void] = []
    
    // MARK: - Authorization Methods
    
    func refreshAuthorizationStatus() {
        refreshAuthorizationStatusCallCount += 1
    }
    
    func requestAuthorization() async throws {
        requestAuthorizationCallCount += 1
        
        if authorizationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(authorizationDelay * 1_000_000_000))
        }
        
        if shouldThrowAuthorizationError {
            throw AppError.from(HealthKitError.authorizationDenied)
        }
        
        authorizationStatus = .authorized
    }
    
    // MARK: - Fetch Methods
    
    func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
        fetchTodayActivityMetricsCallCount += 1
        
        if dataFetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(dataFetchDelay * 1_000_000_000))
        }
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        return mockActivityMetrics
    }
    
    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
        fetchHeartHealthMetricsCallCount += 1
        
        if dataFetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(dataFetchDelay * 1_000_000_000))
        }
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        return mockHeartHealthMetrics
    }
    
    func fetchLatestBodyMetrics() async throws -> BodyMetrics {
        fetchLatestBodyMetricsCallCount += 1
        
        if dataFetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(dataFetchDelay * 1_000_000_000))
        }
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        return mockBodyMetrics
    }
    
    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {
        fetchLastNightSleepCallCount += 1
        
        if dataFetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(dataFetchDelay * 1_000_000_000))
        }
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        return mockSleepSession
    }
    
    func getWorkoutData(from startDate: Date, to endDate: Date) async -> [WorkoutData] {
        getWorkoutDataCallCount += 1
        return mockWorkoutData.filter { workout in
            workout.startDate >= startDate && workout.startDate <= endDate
        }
    }
    
    func fetchRecentWorkouts(limit: Int) async throws -> [WorkoutData] {
        fetchRecentWorkoutsCallCount += 1
        
        if dataFetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(dataFetchDelay * 1_000_000_000))
        }
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        return Array(mockWorkoutData.suffix(limit))
    }
    
    func fetchDailyBiometrics(from startDate: Date, to endDate: Date) async throws -> [DailyBiometrics] {
        if dataFetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(dataFetchDelay * 1_000_000_000))
        }
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        return mockDailyBiometrics.filter { biometric in
            biometric.date >= startDate && biometric.date <= endDate
        }
    }
    
    func fetchHistoricalWorkouts(from startDate: Date, to endDate: Date) async throws -> [WorkoutData] {
        if dataFetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(dataFetchDelay * 1_000_000_000))
        }
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        return mockWorkoutData.filter { workout in
            workout.startDate >= startDate && workout.startDate <= endDate
        }
    }
    
    func getNutritionData(for date: Date) async throws -> HealthKitNutritionSummary {
        if dataFetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(dataFetchDelay * 1_000_000_000))
        }
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        return mockNutritionSummary
    }
    
    func fetchBodyMetricsHistory(from startDate: Date, to endDate: Date) async throws -> [BodyMetrics] {
        if dataFetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(dataFetchDelay * 1_000_000_000))
        }
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        return mockBodyMetricsHistory.filter { metrics in
            guard let date = metrics.date else { return false }
            return date >= startDate && date <= endDate
        }
    }
    
    // MARK: - Save Methods
    
    func saveFoodEntry(_ entry: FoodEntry) async throws -> [String] {
        saveFoodEntryCallCount += 1
        savedFoodEntries.append(entry)
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        // Return mock IDs
        return (0..<3).map { _ in UUID().uuidString }
    }
    
    func saveWorkout(_ workout: Workout) async throws -> String {
        saveWorkoutCallCount += 1
        savedWorkouts.append(workout)
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
        
        return UUID().uuidString
    }
    
    func deleteWorkout(healthKitID: String) async throws {
        deleteWorkoutCallCount += 1
        deletedWorkoutIDs.append(healthKitID)
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
    }
    
    func saveBodyMass(weightKg: Double, date: Date) async throws {
        saveBodyMassCallCount += 1
        savedBodyMassEntries.append((weight: weightKg, date: date))
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
    }
    
    func saveBodyFatPercentage(percentage: Double, date: Date) async throws {
        saveBodyFatPercentageCallCount += 1
        savedBodyFatEntries.append((percentage: percentage, date: date))
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
    }
    
    func saveLeanBodyMass(massKg: Double, date: Date) async throws {
        saveLeanBodyMassCallCount += 1
        savedLeanMassEntries.append((mass: massKg, date: date))
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
    }
    
    // MARK: - Observer Methods
    
    func observeHealthKitChanges(handler: @escaping @Sendable () -> Void) -> Any {
        let token = UUID()
        observers.append(token)
        return token
    }
    
    func stopObserving(token: Any) {
        if let index = observers.firstIndex(where: { _ in true }) {
            observers.remove(at: index)
        }
    }
    
    func observeBodyMetrics(handler: @escaping @Sendable () -> Void) async throws {
        observeBodyMetricsCallCount += 1
        bodyMetricsHandlers.append(handler)
        
        if shouldThrowDataError {
            throw AppError.from(HealthKitError.dataNotAvailable)
        }
    }
    
    func removeObserver(_ observer: Any) {
        // Implementation for removing specific observer
    }
    
    // MARK: - Test Helper Methods
    
    func reset() {
        // Reset all call counts
        refreshAuthorizationStatusCallCount = 0
        requestAuthorizationCallCount = 0
        fetchTodayActivityMetricsCallCount = 0
        fetchHeartHealthMetricsCallCount = 0
        fetchLatestBodyMetricsCallCount = 0
        fetchLastNightSleepCallCount = 0
        getWorkoutDataCallCount = 0
        fetchRecentWorkoutsCallCount = 0
        saveFoodEntryCallCount = 0
        saveWorkoutCallCount = 0
        deleteWorkoutCallCount = 0
        saveBodyMassCallCount = 0
        saveBodyFatPercentageCallCount = 0
        saveLeanBodyMassCallCount = 0
        observeBodyMetricsCallCount = 0
        
        // Reset saved data
        savedFoodEntries.removeAll()
        savedWorkouts.removeAll()
        deletedWorkoutIDs.removeAll()
        savedBodyMassEntries.removeAll()
        savedBodyFatEntries.removeAll()
        savedLeanMassEntries.removeAll()
        
        // Reset observers
        observers.removeAll()
        bodyMetricsHandlers.removeAll()
        
        // Reset configuration
        shouldThrowAuthorizationError = false
        shouldThrowDataError = false
        authorizationDelay = 0
        dataFetchDelay = 0
        authorizationStatus = .notDetermined
        
        // Reset mock data to defaults
        mockActivityMetrics = ActivityMetrics()
        mockHeartHealthMetrics = HeartHealthMetrics()
        mockBodyMetrics = BodyMetrics()
        mockSleepSession = nil
        mockWorkoutData.removeAll()
        mockDailyBiometrics.removeAll()
        mockBodyMetricsHistory.removeAll()
    }
    
    /// Trigger all body metrics observers (for testing observer functionality)
    func triggerBodyMetricsObservers() {
        bodyMetricsHandlers.forEach { $0() }
    }
    
    /// Set up realistic mock data for testing
    func setupRealisticMockData() {
        let now = Date()
        let calendar = Calendar.current
        
        // Activity metrics
        mockActivityMetrics.steps = 8542
        mockActivityMetrics.activeEnergyBurned = Measurement(value: 450, unit: .kilocalories)
        mockActivityMetrics.exerciseMinutes = 32
        mockActivityMetrics.standHours = 9
        
        // Heart health
        mockHeartHealthMetrics.restingHeartRate = 68
        mockHeartHealthMetrics.hrv = Measurement(value: 35.2, unit: .milliseconds)
        mockHeartHealthMetrics.vo2Max = 42.5
        
        // Body metrics
        mockBodyMetrics.weight = Measurement(value: 75.5, unit: .kilograms)
        mockBodyMetrics.height = Measurement(value: 178, unit: .centimeters)
        mockBodyMetrics.bodyFatPercentage = 15.2
        mockBodyMetrics.bmi = 23.8
        mockBodyMetrics.date = now
        
        // Sleep
        let bedtime = calendar.date(byAdding: .hour, value: -8, to: now) ?? now
        let wakeTime = now
        mockSleepSession = SleepAnalysis.SleepSession(
            bedtime: bedtime,
            wakeTime: wakeTime,
            totalSleepTime: 7.5 * 3600,
            timeInBed: 8 * 3600,
            efficiency: 93.8,
            remTime: 1.8 * 3600,
            coreTime: 4.2 * 3600,
            deepTime: 1.5 * 3600,
            awakeTime: 0.5 * 3600
        )
        
        // Workout data
        let workoutStart = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        mockWorkoutData = [
            WorkoutData(
                workoutType: "Running",
                startDate: workoutStart,
                duration: 2100, // 35 minutes
                totalEnergyBurned: 350,
                averageHeartRate: 145
            ),
            WorkoutData(
                workoutType: "Strength Training",
                startDate: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                duration: 3600, // 60 minutes
                totalEnergyBurned: 280,
                averageHeartRate: 120
            )
        ]
        
        // Daily biometrics (last 7 days)
        mockDailyBiometrics = (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            return DailyBiometrics(
                date: calendar.startOfDay(for: date),
                heartRate: Double.random(in: 65...75),
                hrv: Double.random(in: 30...40),
                restingHeartRate: Double.random(in: 62...72),
                heartRateRecovery: Double.random(in: 15...25),
                vo2Max: Double.random(in: 40...45),
                respiratoryRate: Double.random(in: 14...18),
                bedtime: calendar.date(byAdding: .hour, value: -8, to: date) ?? date,
                wakeTime: date,
                sleepDuration: Double.random(in: 6.5...8.5) * 3600,
                remSleep: Double.random(in: 1.2...2.0) * 3600,
                coreSleep: Double.random(in: 3.5...4.5) * 3600,
                deepSleep: Double.random(in: 1.0...2.0) * 3600,
                awakeTime: Double.random(in: 0.2...0.8) * 3600,
                sleepEfficiency: Double.random(in: 85...95),
                activeEnergyBurned: Double.random(in: 300...600),
                basalEnergyBurned: Double.random(in: 1400...1600),
                steps: Int.random(in: 6000...12000),
                exerciseTime: Double.random(in: 20...60),
                standHours: Int.random(in: 8...12)
            )
        }
    }
}