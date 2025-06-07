@testable import AirFit
import Foundation

final class MockHealthKitManager: HealthKitManaging, MockProtocol, @unchecked Sendable {
    // MARK: - MockProtocol
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    var authorizationStatus: HealthKitManager.AuthorizationStatus = .authorized
    private(set) var refreshCalled = false
    private(set) var requestAuthCalled = false
    
    // Test configuration options
    var simulateDelay: TimeInterval = 0
    var callCount = 0
    var shouldFailAfterCalls: Int? = nil
    var shouldThrowError = false
    var errorToThrow: Error = HealthKitManager.HealthKitError.queryFailed(NSError(domain: "MockError", code: -1))

    var activityResult: Result<ActivityMetrics, Error> = .success(ActivityMetrics())
    var heartResult: Result<HeartHealthMetrics, Error> = .success(HeartHealthMetrics())
    var bodyResult: Result<BodyMetrics, Error> = .success(BodyMetrics())
    var sleepResult: Result<SleepAnalysis.SleepSession?, Error> = .success(nil)
    
    // New HealthKit integration results
    var workoutDataResult: [WorkoutData] = []
    var nutritionSummaryResult: Result<HealthKitNutritionSummary, Error> = .success(HealthKitNutritionSummary(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0,
        water: 0,
        date: Date()
    ))
    var saveFoodEntryResult: Result<[String], Error> = .success([])
    var saveWaterIntakeResult: Result<String?, Error> = .success(nil)
    var saveWorkoutResult: Result<String, Error> = .success("mock-workout-id")
    var deleteWorkoutResult: Result<Void, Error> = .success(())
    
    // Track method calls for verification
    private(set) var fetchActivityCallCount = 0
    private(set) var fetchHeartCallCount = 0
    private(set) var fetchBodyCallCount = 0
    private(set) var fetchSleepCallCount = 0
    private(set) var getWorkoutDataCallCount = 0
    private(set) var saveFoodEntryCallCount = 0
    private(set) var saveWaterIntakeCallCount = 0
    private(set) var getNutritionDataCallCount = 0
    private(set) var saveWorkoutCallCount = 0
    private(set) var deleteWorkoutCallCount = 0

    func refreshAuthorizationStatus() {
        refreshCalled = true
    }

    func requestAuthorization() async throws {
        recordInvocation(#function)
        requestAuthCalled = true
        
        if shouldThrowError {
            authorizationStatus = .denied
            throw errorToThrow
        }
        
        authorizationStatus = .authorized
    }

    func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
        fetchActivityCallCount += 1
        callCount += 1
        
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        if let failAfter = shouldFailAfterCalls, callCount > failAfter {
            throw HealthKitManager.HealthKitError.queryFailed(NSError(domain: "MockError", code: -1))
        }
        
        switch activityResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
        fetchHeartCallCount += 1
        callCount += 1
        
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        if let failAfter = shouldFailAfterCalls, callCount > failAfter {
            throw HealthKitManager.HealthKitError.queryFailed(NSError(domain: "MockError", code: -1))
        }
        
        switch heartResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func fetchLatestBodyMetrics() async throws -> BodyMetrics {
        fetchBodyCallCount += 1
        callCount += 1
        
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        if let failAfter = shouldFailAfterCalls, callCount > failAfter {
            throw HealthKitManager.HealthKitError.queryFailed(NSError(domain: "MockError", code: -1))
        }
        
        switch bodyResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {
        fetchSleepCallCount += 1
        callCount += 1
        
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        if let failAfter = shouldFailAfterCalls, callCount > failAfter {
            throw HealthKitManager.HealthKitError.queryFailed(NSError(domain: "MockError", code: -1))
        }
        
        switch sleepResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Legacy Nutrition Methods (for test compatibility)
    
    func saveNutritionToHealthKit(_ nutrition: NutritionData, date: Date) async throws -> Bool {
        recordInvocation(#function, arguments: nutrition, date)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let stubbed = stubbedResults["saveNutritionToHealthKit"] as? Bool {
            return stubbed
        }
        
        return true
    }
    
    func syncFoodEntryToHealthKit(_ entry: FoodEntry) async throws -> String {
        recordInvocation(#function, arguments: entry)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let stubbed = stubbedResults["syncFoodEntryToHealthKit"] as? String {
            return stubbed
        }
        
        return "mock-healthkit-id"
    }
    
    func deleteFoodEntryFromHealthKit(_ entry: FoodEntry) async throws -> Bool {
        recordInvocation(#function, arguments: entry)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let stubbed = stubbedResults["deleteFoodEntryFromHealthKit"] as? Bool {
            return stubbed
        }
        
        return true
    }
    
    // MARK: - New HealthKit Integration Methods
    
    func getWorkoutData(from startDate: Date, to endDate: Date) async -> [WorkoutData] {
        getWorkoutDataCallCount += 1
        callCount += 1
        
        if simulateDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        return workoutDataResult
    }
    
    func saveFoodEntry(_ entry: FoodEntry) async throws -> [String] {
        saveFoodEntryCallCount += 1
        callCount += 1
        
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        if let failAfter = shouldFailAfterCalls, callCount > failAfter {
            throw HealthKitManager.HealthKitError.queryFailed(NSError(domain: "MockError", code: -1))
        }
        
        switch saveFoodEntryResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    func saveWaterIntake(amountML: Double, date: Date = Date()) async throws -> String? {
        saveWaterIntakeCallCount += 1
        callCount += 1
        
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        if let failAfter = shouldFailAfterCalls, callCount > failAfter {
            throw HealthKitManager.HealthKitError.queryFailed(NSError(domain: "MockError", code: -1))
        }
        
        switch saveWaterIntakeResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    func getNutritionData(for date: Date) async throws -> HealthKitNutritionSummary {
        getNutritionDataCallCount += 1
        callCount += 1
        
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        if let failAfter = shouldFailAfterCalls, callCount > failAfter {
            throw HealthKitManager.HealthKitError.queryFailed(NSError(domain: "MockError", code: -1))
        }
        
        switch nutritionSummaryResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    func saveWorkout(_ workout: Workout) async throws -> String {
        saveWorkoutCallCount += 1
        callCount += 1
        
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        if let failAfter = shouldFailAfterCalls, callCount > failAfter {
            throw HealthKitManager.HealthKitError.queryFailed(NSError(domain: "MockError", code: -1))
        }
        
        switch saveWorkoutResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    func deleteWorkout(healthKitID: String) async throws {
        deleteWorkoutCallCount += 1
        callCount += 1
        
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }
        
        if let failAfter = shouldFailAfterCalls, callCount > failAfter {
            throw HealthKitManager.HealthKitError.queryFailed(NSError(domain: "MockError", code: -1))
        }
        
        switch deleteWorkoutResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Test Utility Methods
    
    func invocationCount(for method: String) -> Int {
        mockLock.lock()
        defer { mockLock.unlock() }
        return invocations[method]?.count ?? 0
    }
    
    func reset() {
        mockLock.lock()
        defer { mockLock.unlock() }
        
        // Reset MockProtocol properties
        invocations.removeAll()
        stubbedResults.removeAll()
        
        // Reset other properties
        refreshCalled = false
        requestAuthCalled = false
        callCount = 0
        shouldThrowError = false
        errorToThrow = HealthKitManager.HealthKitError.queryFailed(NSError(domain: "MockError", code: -1))
        fetchActivityCallCount = 0
        fetchHeartCallCount = 0
        fetchBodyCallCount = 0
        fetchSleepCallCount = 0
        getWorkoutDataCallCount = 0
        saveFoodEntryCallCount = 0
        saveWaterIntakeCallCount = 0
        getNutritionDataCallCount = 0
        saveWorkoutCallCount = 0
        deleteWorkoutCallCount = 0
        simulateDelay = 0
        shouldFailAfterCalls = nil
        authorizationStatus = .authorized
        activityResult = .success(ActivityMetrics())
        heartResult = .success(HeartHealthMetrics())
        bodyResult = .success(BodyMetrics())
        sleepResult = .success(nil)
        workoutDataResult = []
        nutritionSummaryResult = .success(HealthKitNutritionSummary(
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            water: 0,
            date: Date()
        ))
        saveFoodEntryResult = .success([])
        saveWaterIntakeResult = .success(nil)
        saveWorkoutResult = .success("mock-workout-id")
        deleteWorkoutResult = .success(())
    }
}
