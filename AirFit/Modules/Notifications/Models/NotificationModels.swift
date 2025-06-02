import Foundation
import SwiftData

// MARK: - Notification Content
struct NotificationContent {
    let title: String
    let body: String
    var subtitle: String?
    var imageKey: String?
    var sound: NotificationSound = .default
    var actions: [NotificationAction] = []
    var badge: Int?
}

struct NotificationAction {
    let id: String
    let title: String
    let isDestructive: Bool = false
}

enum NotificationSound {
    case `default`
    case achievement
    case reminder
    case urgent
    
    var fileName: String? {
        switch self {
        case .default: return nil
        case .achievement: return "achievement.caf"
        case .reminder: return "reminder.caf"
        case .urgent: return "urgent.caf"
        }
    }
}

// MARK: - Engagement Metrics
struct EngagementMetrics {
    let totalUsers: Int
    let activeUsers: Int
    let lapsedUsers: Int
    let churnRiskUsers: Int
    let avgSessionsPerWeek: Double
    let avgSessionDuration: TimeInterval
    
    var engagementRate: Double {
        guard totalUsers > 0 else { return 0 }
        return Double(activeUsers) / Double(totalUsers)
    }
}

struct ReEngagementContext {
    let userName: String
    let daysSinceLastActive: Int
    let primaryGoal: String?
    let previousEngagementAttempts: Int
    let lastWorkoutType: String?
    let personalityTraits: PersonaProfile?
}

struct CommunicationPreferences: Codable {
    let absenceResponse: String // "give_me_space", "light_nudge", "check_in_on_me"
    let preferredTimes: [String]
    let frequency: String
}

// MARK: - Notification Preferences
struct NotificationPreferences: Codable {
    var systemEnabled: Bool = true
    var morningGreeting = true
    var morningTime = Date()
    var workoutReminders = true
    var workoutSchedule: [WorkoutSchedule] = []
    var mealReminders = true
    var hydrationReminders = true
    var hydrationFrequency: HydrationFrequency = .biHourly
    var dailyCheckins: Bool = true
    var achievementAlerts: Bool = true
    var coachMessages: Bool = true
}

enum HydrationFrequency: String, CaseIterable, Codable {
    case hourly = "hourly"
    case biHourly = "bi_hourly"
    case triDaily = "tri_daily"
}

struct WorkoutSchedule: Codable {
    let type: String
    let scheduledDate: Date
    let dateComponents: DateComponents
}

// MARK: - Content Generation Contexts
struct MorningContext {
    let userName: String
    let sleepQuality: SleepQuality?
    let sleepDuration: TimeInterval?
    let weather: WeatherData?
    let plannedWorkout: WorkoutTemplate?
    let currentStreak: Int
    let dayOfWeek: Int
    let motivationalStyle: MotivationalStyle
}

struct WorkoutReminderContext {
    let userName: String
    let workoutType: String
    let lastWorkoutDays: Int
    let streak: Int
    let motivationalStyle: MotivationalStyle
}

struct MealReminderContext {
    let userName: String
    let mealType: MealType
    let nutritionGoals: NutritionGoals?
    let lastMealLogged: Date?
    let favoritesFoods: [String]
}

struct AchievementContext {
    let userName: String
    let achievementName: String
    let achievementDescription: String
    let streak: Int?
    let personalBest: Bool
}

// MARK: - Placeholder Types (would be moved to appropriate modules)
enum SleepQuality {
    case poor, fair, good, excellent
}

struct SleepData {
    let quality: SleepQuality
    let duration: TimeInterval
}

struct WeatherData {
    enum Condition {
        case sunny, cloudy, rainy, snowy
    }
    let condition: Condition
    let temperature: Double
}

enum MotivationalStyle: String {
    case encouraging, challenging, supportive
}

struct NutritionGoals {
    let dailyCalories: Int
    let proteinGrams: Int
    let carbGrams: Int
    let fatGrams: Int
}

struct Achievement {
    let id: String
    let name: String
    let description: String
    let imageKey: String
    let isPersonalBest: Bool
    let streak: Int?
}
