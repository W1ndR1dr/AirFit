@testable import AirFit
import Foundation
import SwiftData

@MainActor
final class MockHealthKitService: HealthKitServiceProtocol, @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

    var mockContext = HealthContext(
        lastNightSleepDurationHours: nil,
        sleepQuality: nil,
        currentWeatherCondition: nil,
        currentTemperatureCelsius: nil,
        yesterdayEnergyLevel: nil,
        currentHeartRate: nil,
        hrv: nil,
        steps: nil
    )
    var recoveryResult = RecoveryScore(score: 75, status: .good, factors: ["Good sleep", "Low stress"])
    var performanceResult = PerformanceInsight(trend: .stable, metric: "VO2 Max", value: "45", insight: "Your fitness level is stable")

    func getCurrentContext() async throws -> HealthContext {
        recordInvocation(#function)
        return mockContext
    }

    func calculateRecoveryScore(for user: User) async throws -> RecoveryScore {
        recordInvocation(#function, arguments: user)
        return recoveryResult
    }

    func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight {
        recordInvocation(#function, arguments: user, days)
        return performanceResult
    }
}
