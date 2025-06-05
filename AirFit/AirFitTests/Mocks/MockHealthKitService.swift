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
    var recoveryResult = RecoveryScore(score: 0, components: [])
    var performanceResult = PerformanceInsight(summary: "", trend: .steady, keyMetric: "", value: 0)

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