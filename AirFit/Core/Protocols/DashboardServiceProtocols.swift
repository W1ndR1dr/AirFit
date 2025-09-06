import Foundation
import SwiftData

/// Protocol for assembling health context snapshots
@MainActor
protocol ContextAssemblerProtocol: Sendable {
    func assembleContext() async -> HealthContextSnapshot
}

/// Provides health-related data for the dashboard.
protocol HealthKitServiceProtocol: Sendable {
    func getCurrentContext() async throws -> HealthContext
    func calculateRecoveryScore(for user: User) async throws -> RecoveryScore
    func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight
}

/// Generates AI-powered greetings and coaching snippets.
protocol AICoachServiceProtocol: Sendable {
    func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String
    func generateDashboardContent(for user: User) async throws -> AIDashboardContent
}

// DashboardNutritionServiceProtocol removed - use NutritionServiceProtocol directly

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
