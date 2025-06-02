import Foundation
import SwiftData

@MainActor
final class NotificationContentGenerator {
    private let coachEngine: CoachEngine
    private let modelContext: ModelContext
    
    // Content templates for fallback
    private let fallbackTemplates = NotificationTemplates()
    
    init(coachEngine: CoachEngine, modelContext: ModelContext) {
        self.coachEngine = coachEngine
        self.modelContext = modelContext
    }
    
    // MARK: - Morning Greeting
    func generateMorningGreeting(for user: User) async throws -> NotificationContent {
        // Gather context
        let context = await gatherMorningContext(for: user)
        
        do {
            // Try AI generation
            let aiContent = try await coachEngine.generateNotificationContent(
                type: .morningGreeting,
                context: context
            )
            
            return NotificationContent(
                title: "Good morning, \(user.name ?? "there")! ☀️",
                body: aiContent,
                imageKey: selectMorningImage(context: context)
            )
            
        } catch {
            // Fallback to template
            AppLogger.error("AI generation failed, using template", error: error, category: .ai)
            return fallbackTemplates.morningGreeting(user: user, context: context)
        }
    }
    
    // MARK: - Workout Reminders
    func generateWorkoutReminder(
        for user: User,
        workout: WorkoutTemplate?
    ) async throws -> NotificationContent {
        let context = WorkoutReminderContext(
            userName: user.name ?? "there",
            workoutType: workout?.name ?? "workout",
            lastWorkoutDays: user.daysSinceLastWorkout,
            streak: user.workoutStreak,
            motivationalStyle: user.onboardingProfile?.motivationalStyle ?? .encouraging
        )
        
        do {
            let aiContent = try await coachEngine.generateNotificationContent(
                type: .workoutReminder,
                context: context
            )
            
            return NotificationContent(
                title: selectWorkoutTitle(context: context),
                body: aiContent,
                actions: [
                    NotificationAction(id: "START_WORKOUT", title: "Let's Go! 💪"),
                    NotificationAction(id: "SNOOZE_30", title: "In 30 min")
                ]
            )
            
        } catch {
            return fallbackTemplates.workoutReminder(context: context)
        }
    }
    
    // MARK: - Meal Reminders
    func generateMealReminder(
        for user: User,
        mealType: MealType
    ) async throws -> NotificationContent {
        let context = MealReminderContext(
            userName: user.name ?? "there",
            mealType: mealType,
            nutritionGoals: user.nutritionGoals,
            lastMealLogged: user.lastMealLoggedTime,
            favoritesFoods: user.favoriteFoods
        )
        
        do {
            let aiContent = try await coachEngine.generateNotificationContent(
                type: .mealReminder(mealType),
                context: context
            )
            
            return NotificationContent(
                title: "\(mealType.emoji) \(mealType.displayName) time!",
                body: aiContent,
                actions: [
                    NotificationAction(id: "LOG_MEAL", title: "Log Meal"),
                    NotificationAction(id: "QUICK_ADD", title: "Quick Add")
                ]
            )
            
        } catch {
            return fallbackTemplates.mealReminder(mealType: mealType, context: context)
        }
    }
    
    // MARK: - Achievement Notifications
    func generateAchievementNotification(
        for user: User,
        achievement: Achievement
    ) async throws -> NotificationContent {
        let context = AchievementContext(
            userName: user.name ?? "there",
            achievementName: achievement.name,
            achievementDescription: achievement.description,
            streak: achievement.streak,
            personalBest: achievement.isPersonalBest
        )
        
        do {
            let aiContent = try await coachEngine.generateNotificationContent(
                type: .achievement,
                context: context
            )
            
            return NotificationContent(
                title: "🎉 Achievement Unlocked!",
                body: aiContent,
                imageKey: achievement.imageKey,
                sound: .achievement
            )
            
        } catch {
            return fallbackTemplates.achievement(achievement: achievement, context: context)
        }
    }
    
    // MARK: - Context Gathering
    private func gatherMorningContext(for user: User) async -> MorningContext {
        // Fetch recent data
        let sleepData = try? await fetchLastNightSleep(for: user)
        let weather = try? await fetchCurrentWeather()
        let todaysWorkout = user.plannedWorkoutForToday
        let currentStreak = user.overallStreak
        
        return MorningContext(
            userName: user.name ?? "there",
            sleepQuality: sleepData?.quality,
            sleepDuration: sleepData?.duration,
            weather: weather,
            plannedWorkout: todaysWorkout,
            currentStreak: currentStreak,
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            motivationalStyle: user.onboardingProfile?.motivationalStyle ?? .encouraging
        )
    }
    
    // MARK: - Helper Methods
    private func selectMorningImage(context: MorningContext) -> String {
        if let weather = context.weather {
            switch weather.condition {
            case .sunny: return "morning_sunny"
            case .cloudy: return "morning_cloudy"
            case .rainy: return "morning_rainy"
            default: return "morning_default"
            }
        }
        return "morning_default"
    }
    
    private func selectWorkoutTitle(context: WorkoutReminderContext) -> String {
        let titles = [
            "Time to crush your \(context.workoutType)! 💪",
            "Ready for today's \(context.workoutType)?",
            "Your \(context.workoutType) awaits! 🏋️",
            "Let's make today count! 🎯"
        ]
        
        // Use streak to select title for variety
        let index = context.streak % titles.count
        return titles[index]
    }
    
    private func fetchLastNightSleep(for user: User) async throws -> SleepData? {
        // Would integrate with HealthKit
        return nil
    }
    
    private func fetchCurrentWeather() async throws -> WeatherData? {
        // Would integrate with weather service
        return nil
    }
}

// MARK: - Fallback Templates
struct NotificationTemplates {
    func morningGreeting(user: User, context: MorningContext) -> NotificationContent {
        let greetings = [
            "Rise and shine! Ready to make today amazing?",
            "Good morning! Your coach is here to support you today.",
            "A new day, new opportunities! What will you achieve today?",
            "Morning champion! Let's make today count."
        ]
        
        let body = greetings.randomElement() ?? greetings[0]
        
        return NotificationContent(
            title: "Good morning, \(user.name ?? "there")! ☀️",
            body: body
        )
    }
    
    func workoutReminder(context: WorkoutReminderContext) -> NotificationContent {
        let messages = [
            "Your \(context.workoutType) is waiting! Keep that \(context.streak)-day streak going! 🔥",
            "Time to move! Your body will thank you. 💪",
            "Ready to feel amazing? Your \(context.workoutType) starts now!",
            "Let's go! Every workout counts towards your goals."
        ]
        
        return NotificationContent(
            title: "Workout Time! 🏋️",
            body: messages.randomElement() ?? messages[0]
        )
    }
    
    func mealReminder(mealType: MealType, context: MealReminderContext) -> NotificationContent {
        let messages = [
            "Time to fuel your body with a nutritious \(mealType.displayName.lowercased())!",
            "Don't forget to log your \(mealType.displayName.lowercased()) - every meal counts!",
            "Hungry? Let's track that \(mealType.displayName.lowercased()) and stay on top of your nutrition.",
            "\(mealType.displayName) time! Quick tip: log it now while it's fresh in your mind."
        ]
        
        return NotificationContent(
            title: "\(mealType.emoji) \(mealType.displayName) Reminder",
            body: messages.randomElement() ?? messages[0]
        )
    }
    
    func achievement(achievement: Achievement, context: AchievementContext) -> NotificationContent {
        return NotificationContent(
            title: "🎉 Achievement Unlocked!",
            body: "Incredible! You've earned '\(achievement.name)'. \(achievement.description)"
        )
    }
}

// MARK: - User Extensions
extension User {
    var workoutStreak: Int {
        // Would calculate from workout history
        return 5
    }
    
    var daysSinceLastWorkout: Int {
        // Would calculate from last workout date
        return 2
    }
    
    var plannedWorkoutForToday: WorkoutTemplate? {
        // Would fetch from planned workouts
        return nil
    }
    
    var overallStreak: Int {
        // Would calculate from daily logs
        return 10
    }
    
    var nutritionGoals: NutritionGoals? {
        // Would fetch from user profile
        return nil
    }
    
    var lastMealLoggedTime: Date? {
        // Would fetch from food entries
        return nil
    }
    
    var favoriteFoods: [String] {
        // Would fetch from food history
        return []
    }
}

// MARK: - CoachEngine Extensions
extension CoachEngine {
    enum NotificationContentType {
        case morningGreeting
        case workoutReminder
        case mealReminder(MealType)
        case achievement
    }
    
    func generateNotificationContent<T>(type: NotificationContentType, context: T) async throws -> String {
        // Placeholder - would call AI service with appropriate prompts
        switch type {
        case .morningGreeting:
            return "Ready to make today amazing? Let's start with a quick check-in!"
        case .workoutReminder:
            return "Your body is ready for action! Let's make this workout count."
        case .mealReminder(let mealType):
            return "Time to fuel your body with a healthy \(mealType.displayName.lowercased())!"
        case .achievement:
            return "You're crushing it! Keep up the amazing work!"
        }
    }
}
