import Foundation
import SwiftData

/// # AnalyticsService
/// 
/// ## Purpose
/// Tracks user behavior, app usage, and generates insights for personalized coaching.
/// Provides analytics data that helps the AI coach understand user patterns and progress.
///
/// ## Dependencies
/// - `ModelContext`: SwiftData context for accessing user data and history
///
/// ## Key Responsibilities
/// - Track user events (workouts completed, meals logged, etc.)
/// - Monitor screen views and user flow
/// - Calculate user insights (trends, streaks, achievements)
/// - Generate statistics for goal tracking
/// - Provide behavioral data for AI personalization
///
/// ## Usage
/// ```swift
/// let analytics = await container.resolve(AnalyticsServiceProtocol.self)
/// 
/// // Track an event
/// await analytics.trackWorkoutCompleted(workout)
/// 
/// // Get user insights
/// let insights = try await analytics.getInsights(for: user)
/// ```
///
/// ## Important Notes
/// - Events are queued in memory for batch processing
/// - In production, would integrate with external analytics services
/// - Provides critical data for AI coach personalization
@MainActor
final class AnalyticsService: AnalyticsServiceProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "analytics-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // For @MainActor classes, we need to return a simple value
        // The actual state is tracked in _isConfigured
        true
    }
    
    // MARK: - Properties
    private let modelContext: ModelContext
    private var eventQueue: [AnalyticsEvent] = []
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        eventQueue.removeAll()
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: [
                "queuedEvents": "\(eventQueue.count)",
                "modelContext": "true"
            ]
        )
    }
    
    // MARK: - AnalyticsServiceProtocol
    func trackEvent(_ event: AnalyticsEvent) async {
        AppLogger.debug("Analytics event: \(event.name) - \(event.properties)", category: .services)
        eventQueue.append(event)
        
        // In a production app, this would send to an analytics service
        // For now, we just log it
        if eventQueue.count > 100 {
            eventQueue.removeFirst(50) // Keep queue manageable
        }
    }
    
    func trackScreen(_ screen: String, properties: [String: String]?) async {
        let event = AnalyticsEvent(
            name: "screen_view",
            properties: ["screen": screen] + (properties ?? [:]),
            timestamp: Date()
        )
        await trackEvent(event)
    }
    
    func setUserProperties(_ properties: [String: String]) async {
        AppLogger.debug("Setting user properties: \(properties)", category: .services)
        // In production, this would update user profile in analytics service
    }
    
    func trackWorkoutCompleted(_ workout: Workout) async {
        let properties: [String: String] = [
            "workout_id": workout.id.uuidString,
            "type": workout.workoutType,
            "duration": String(Int(workout.durationSeconds ?? 0)),
            "exercises": String(workout.exercises.count),
            "sets": String(workout.totalSets),
            "volume": String(Int(workout.totalVolume))
        ]
        
        let event = AnalyticsEvent(
            name: "workout_completed",
            properties: properties,
            timestamp: Date()
        )
        await trackEvent(event)
    }
    
    func trackMealLogged(_ meal: FoodEntry) async {
        let properties: [String: String] = [
            "meal_id": meal.id.uuidString,
            "meal_type": meal.mealType,
            "calories": String(meal.totalCalories),
            "protein": String(Int(meal.totalProtein)),
            "carbs": String(Int(meal.totalCarbs)),
            "fat": String(Int(meal.totalFat))
        ]
        
        let event = AnalyticsEvent(
            name: "meal_logged",
            properties: properties,
            timestamp: Date()
        )
        await trackEvent(event)
    }
    
    func getInsights(for user: User) async throws -> UserInsights {
        AppLogger.info("Generating insights for user \(user.id)", category: .services)
        
        // Calculate workout frequency (workouts per week)
        let recentWorkouts = user.getRecentWorkouts(days: 30)
        let workoutFrequency = Double(recentWorkouts.count) / 4.3 // Average weeks in a month
        
        // Calculate average workout duration
        let totalDuration = recentWorkouts.compactMap { $0.durationSeconds }.reduce(0, +)
        let averageWorkoutDuration = recentWorkouts.isEmpty ? 0 : totalDuration / Double(recentWorkouts.count)
        
        // Calculate calorie trend
        let recentMeals = user.getRecentMeals(days: 14)
        let caloriesTrend = calculateCalorieTrend(from: recentMeals)
        
        // Calculate macro balance
        let macroBalance = calculateMacroBalance(from: recentMeals)
        
        // Calculate streak
        let streakDays = calculateStreakDays(for: user)
        
        // Generate achievements
        let achievements = generateAchievements(for: user, workouts: recentWorkouts, meals: recentMeals)
        
        return UserInsights(
            workoutFrequency: workoutFrequency,
            averageWorkoutDuration: averageWorkoutDuration,
            caloriesTrend: caloriesTrend,
            macroBalance: macroBalance,
            streakDays: streakDays,
            achievements: achievements
        )
    }
    
    // MARK: - Private Methods
    private func calculateCalorieTrend(from meals: [FoodEntry]) -> Trend {
        guard meals.count >= 7 else {
            return Trend(direction: .stable, changePercentage: 0)
        }
        
        let sorted = meals.sorted { $0.loggedAt < $1.loggedAt }
        let midpoint = sorted.count / 2
        
        let firstHalf = sorted.prefix(midpoint)
        let secondHalf = sorted.suffix(sorted.count - midpoint)
        
        let firstHalfAvg = Double(firstHalf.map(\.totalCalories).reduce(0, +)) / Double(firstHalf.count)
        let secondHalfAvg = Double(secondHalf.map(\.totalCalories).reduce(0, +)) / Double(secondHalf.count)
        
        let changePercentage = ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100
        
        let direction: Trend.Direction = {
            if abs(changePercentage) < 5 {
                return .stable
            } else if changePercentage > 0 {
                return .up
            } else {
                return .down
            }
        }()
        
        return Trend(direction: direction, changePercentage: abs(changePercentage))
    }
    
    private func calculateMacroBalance(from meals: [FoodEntry]) -> MacroBalance {
        let totalProtein = meals.map(\.totalProtein).reduce(0, +)
        let totalCarbs = meals.map(\.totalCarbs).reduce(0, +)
        let totalFat = meals.map(\.totalFat).reduce(0, +)
        
        let total = totalProtein + totalCarbs + totalFat
        guard total > 0 else {
            return MacroBalance(proteinPercentage: 33.3, carbsPercentage: 33.3, fatPercentage: 33.3)
        }
        
        return MacroBalance(
            proteinPercentage: (totalProtein / total) * 100,
            carbsPercentage: (totalCarbs / total) * 100,
            fatPercentage: (totalFat / total) * 100
        )
    }
    
    private func calculateStreakDays(for user: User) -> Int {
        let logs = user.dailyLogs.sorted { $0.date > $1.date }
        var streak = 0
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        
        for log in logs {
            let logDate = calendar.startOfDay(for: log.date)
            
            if logDate == currentDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if logDate < currentDate {
                // Gap in logs, streak is broken
                break
            }
        }
        
        return streak
    }
    
    private func generateAchievements(for user: User, workouts: [Workout], meals: [FoodEntry]) -> [UserAchievement] {
        var achievements: [UserAchievement] = []
        
        // First workout achievement
        if !workouts.isEmpty {
            achievements.append(UserAchievement(
                id: "first_workout",
                title: "First Step",
                description: "Completed your first workout",
                unlockedAt: workouts.last?.completedDate ?? Date(),
                icon: "figure.run"
            ))
        }
        
        // 7-day streak achievement
        if calculateStreakDays(for: user) >= 7 {
            achievements.append(UserAchievement(
                id: "week_streak",
                title: "Week Warrior",
                description: "Logged activity for 7 days straight",
                unlockedAt: Date(),
                icon: "flame.fill"
            ))
        }
        
        // 10 workouts achievement
        if user.workouts.count >= 10 {
            achievements.append(UserAchievement(
                id: "ten_workouts",
                title: "Committed",
                description: "Completed 10 workouts",
                unlockedAt: Date(),
                icon: "star.fill"
            ))
        }
        
        // Balanced nutrition achievement
        let macroBalance = calculateMacroBalance(from: meals)
        if abs(macroBalance.proteinPercentage - 30) < 10 &&
           abs(macroBalance.carbsPercentage - 40) < 10 &&
           abs(macroBalance.fatPercentage - 30) < 10 {
            achievements.append(UserAchievement(
                id: "balanced_nutrition",
                title: "Balanced Eater",
                description: "Maintained balanced macros",
                unlockedAt: Date(),
                icon: "leaf.fill"
            ))
        }
        
        return achievements
    }
}

// MARK: - Dictionary Extension
private extension Dictionary where Key == String, Value == String {
    static func +(lhs: [String: String], rhs: [String: String]) -> [String: String] {
        var result = lhs
        for (key, value) in rhs {
            result[key] = value
        }
        return result
    }
}