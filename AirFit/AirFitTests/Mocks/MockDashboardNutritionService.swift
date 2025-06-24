@testable import AirFit
import Foundation
import SwiftData

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
