import Foundation
import SwiftData

/// Protocol for analytics and tracking operations
protocol AnalyticsServiceProtocol: AnyObject {
    func trackEvent(_ event: AnalyticsEvent) async
    func trackScreen(_ screen: String, properties: [String: Any]?) async
    func setUserProperties(_ properties: [String: Any]) async
    func trackWorkoutCompleted(_ workout: Workout) async
    func trackMealLogged(_ meal: FoodEntry) async
    func trackGoalProgress(_ goal: Goal, progress: Double) async
    func getInsights(for user: User) async throws -> UserInsights
}

// MARK: - Supporting Types

struct AnalyticsEvent: Sendable {
    let name: String
    let properties: [String: Any]
    let timestamp: Date
}

struct UserInsights: Sendable {
    let workoutFrequency: Double
    let averageWorkoutDuration: TimeInterval
    let caloriesTrend: Trend
    let macroBalance: MacroBalance
    let streakDays: Int
    let achievements: [Achievement]
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

struct Achievement: Sendable {
    let id: String
    let title: String
    let description: String
    let unlockedAt: Date
    let icon: String
}