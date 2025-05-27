@testable import AirFit
import Foundation

@MainActor
final class MockHealthKitManager: @unchecked Sendable, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]

    var activityResult: Result<ActivityMetrics, Error> = .success(ActivityMetrics())
    var heartResult: Result<HeartHealthMetrics, Error> = .success(HeartHealthMetrics())
    var bodyResult: Result<BodyMetrics, Error> = .success(BodyMetrics())
    var sleepResult: Result<SleepAnalysis.SleepSession?, Error> = .success(nil)

    func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
        recordInvocation(#function)
        switch activityResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
        recordInvocation(#function)
        switch heartResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    func fetchLatestBodyMetrics() async throws -> BodyMetrics {
        recordInvocation(#function)
        switch bodyResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {
        recordInvocation(#function)
        switch sleepResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
