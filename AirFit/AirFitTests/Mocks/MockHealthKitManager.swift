@testable import AirFit
import Foundation

final class MockHealthKitManager: HealthKitManaging, @unchecked Sendable {
    var authorizationStatus: HealthKitManager.AuthorizationStatus = .authorized
    private(set) var refreshCalled = false
    private(set) var requestAuthCalled = false
    
    // Test configuration options
    var simulateDelay: TimeInterval = 0
    var callCount = 0
    var shouldFailAfterCalls: Int? = nil

    var activityResult: Result<ActivityMetrics, Error> = .success(ActivityMetrics())
    var heartResult: Result<HeartHealthMetrics, Error> = .success(HeartHealthMetrics())
    var bodyResult: Result<BodyMetrics, Error> = .success(BodyMetrics())
    var sleepResult: Result<SleepAnalysis.SleepSession?, Error> = .success(nil)
    
    // Track method calls for verification
    private(set) var fetchActivityCallCount = 0
    private(set) var fetchHeartCallCount = 0
    private(set) var fetchBodyCallCount = 0
    private(set) var fetchSleepCallCount = 0

    func refreshAuthorizationStatus() {
        refreshCalled = true
    }

    func requestAuthorization() async throws {
        requestAuthCalled = true
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
    
    // Test utility methods
    func reset() {
        refreshCalled = false
        requestAuthCalled = false
        callCount = 0
        fetchActivityCallCount = 0
        fetchHeartCallCount = 0
        fetchBodyCallCount = 0
        fetchSleepCallCount = 0
        simulateDelay = 0
        shouldFailAfterCalls = nil
        authorizationStatus = .authorized
        activityResult = .success(ActivityMetrics())
        heartResult = .success(HeartHealthMetrics())
        bodyResult = .success(BodyMetrics())
        sleepResult = .success(nil)
    }
}
