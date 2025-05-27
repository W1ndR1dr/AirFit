@testable import AirFit
import Foundation

final class MockHealthKitManager: HealthKitManaging, @unchecked Sendable {
    var authorizationStatus: HealthKitManager.AuthorizationStatus = .authorized
    private(set) var refreshCalled = false
    private(set) var requestAuthCalled = false

    var activityResult: Result<ActivityMetrics, Error> = .success(ActivityMetrics())
    var heartResult: Result<HeartHealthMetrics, Error> = .success(HeartHealthMetrics())
    var bodyResult: Result<BodyMetrics, Error> = .success(BodyMetrics())
    var sleepResult: Result<SleepAnalysis.SleepSession?, Error> = .success(nil)

    func refreshAuthorizationStatus() {
        refreshCalled = true
    }

    func requestAuthorization() async throws {
        requestAuthCalled = true
    }

    func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
        switch activityResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
        switch heartResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func fetchLatestBodyMetrics() async throws -> BodyMetrics {
        switch bodyResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {
        switch sleepResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
