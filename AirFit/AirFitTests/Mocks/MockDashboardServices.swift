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

@MainActor
final class MockAICoachService: AICoachServiceProtocol, @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

    var mockGreeting: String = "Hello"

    func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
        recordInvocation(#function, arguments: user, context)
        return mockGreeting
    }
}

@MainActor
final class MockDashboardNutritionService: DashboardNutritionServiceProtocol, @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

    var mockSummary = NutritionSummary()
    var mockTargets = NutritionTargets.default

    func getTodaysSummary(for user: User) async throws -> NutritionSummary {
        recordInvocation(#function, arguments: user)
        return mockSummary
    }

    func getTargets(from profile: OnboardingProfile) async throws -> NutritionTargets {
        recordInvocation(#function, arguments: profile)
        return mockTargets
    }
}
