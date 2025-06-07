import Foundation
import SwiftData

/// Protocol for analytics and tracking operations
protocol AnalyticsServiceProtocol: AnyObject, Sendable {
    func trackEvent(_ event: AnalyticsEvent) async
    func trackScreen(_ screen: String, properties: [String: String]?) async
    func setUserProperties(_ properties: [String: String]) async
    func trackWorkoutCompleted(_ workout: Workout) async
    func trackMealLogged(_ meal: FoodEntry) async
    func getInsights(for user: User) async throws -> UserInsights
}

// MARK: - Supporting Types

struct AnalyticsEvent: Sendable {
    let name: String
    let properties: [String: String]
    let timestamp: Date
}

struct UserInsights: Sendable {
    let workoutFrequency: Double
    let averageWorkoutDuration: TimeInterval
    let caloriesTrend: Trend
    let macroBalance: MacroBalance
    let streakDays: Int
    let achievements: [UserAchievement]
}

struct Trend: Sendable {
    enum Direction: String, Sendable {
        case up
        case down
        case stable
    }
    
    let direction: Direction
    let changePercentage: Double
}

struct MacroBalance: Sendable {
    let proteinPercentage: Double
    let carbsPercentage: Double
    let fatPercentage: Double
}

struct UserAchievement: Sendable {
    let id: String
    let title: String
    let description: String
    let unlockedAt: Date
    let icon: String
}