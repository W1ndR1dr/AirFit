import Foundation
import SwiftData

/// Provides health-related data for the dashboard.
protocol HealthKitServiceProtocol: Sendable {
    func getCurrentContext() async throws -> HealthContext
    func calculateRecoveryScore(for user: User) async throws -> RecoveryScore
    func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight
}

/// Generates AI-powered greetings and coaching snippets.
protocol AICoachServiceProtocol: Sendable {
    func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String
}

/// Supplies nutrition summaries and targets for dashboard display.
protocol DashboardNutritionServiceProtocol: Sendable {
    func getTodaysSummary(for user: User) async throws -> NutritionSummary
    func getTargets(from profile: OnboardingProfile) async throws -> NutritionTargets
}

/// Lightweight health context used by the dashboard.
struct HealthContext: Sendable {
    let lastNightSleepDurationHours: Double?
    let sleepQuality: Int?
    let currentWeatherCondition: String?
    let currentTemperatureCelsius: Double?
    let yesterdayEnergyLevel: Int?
    let currentHeartRate: Int?
    let hrv: Double?
    let steps: Int?
}
