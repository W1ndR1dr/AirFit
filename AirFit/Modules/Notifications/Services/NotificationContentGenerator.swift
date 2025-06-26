import Foundation
import SwiftData

@MainActor
final class NotificationContentGenerator: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "notification-content-generator"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }

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
            // Try AI generation with retry logic
            var lastError: Error?
            for attempt in 1...3 {
                do {
                    let aiContent = try await coachEngine.generateNotificationContent(
                        type: .morningGreeting,
                        context: context
                    )
                    
                    AppLogger.info("AI generated morning greeting successfully on attempt \(attempt)", category: .ai)
                    
                    return NotificationContent(
                        title: "Good morning, \(user.name ?? "there")! ☀️",
                        body: aiContent,
                        imageKey: selectMorningImage(context: context)
                    )
                } catch {
                    lastError = error
                    AppLogger.warning("AI generation attempt \(attempt) failed: \(error)", category: .ai)
                    if attempt < 3 {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay before retry
                    }
                }
            }
            
            // Log detailed failure before fallback
            AppLogger.error("AI generation failed after 3 attempts, using template fallback",
                            error: lastError ?? AppError.llm("Unknown error"),
                            category: .notifications)
            
            // Fallback to template only after retries exhausted
            return fallbackTemplates.morningGreeting(user: user, context: context)
        } catch {
            // This shouldn't happen but safety net
            AppLogger.error("Unexpected error in notification generation", error: error, category: .notifications)
            return fallbackTemplates.morningGreeting(user: user, context: context)
        }
    }

    // MARK: - Workout Reminders
    func generateWorkoutReminder(
        for user: User,
        workout: Workout?
    ) async throws -> NotificationContent {
        let motivationalStyle = await extractMotivationalStyle(from: user) ?? MotivationalStyle()
        let context = WorkoutReminderContext(
            userName: user.name ?? "there",
            workoutType: workout?.name ?? "workout",
            lastWorkoutDays: user.daysSinceLastWorkout,
            streak: user.workoutStreak,
            motivationalStyle: motivationalStyle
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
        let motivationalStyle = await extractMotivationalStyle(from: user) ?? MotivationalStyle()

        return MorningContext(
            userName: user.name ?? "there",
            sleepQuality: sleepData?.quality,
            sleepDuration: sleepData?.duration,
            weather: weather,
            plannedWorkout: todaysWorkout,
            currentStreak: currentStreak,
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            motivationalStyle: motivationalStyle
        )
    }

    // MARK: - Helper Methods
    private func selectMorningImage(context: MorningContext) -> String {
        if let weather = context.weather {
            // Map weather condition string to appropriate image
            switch weather.condition {
            case .clear: return "morning_sunny"
            case .cloudy, .partlyCloudy: return "morning_cloudy"
            case .rain: return "morning_rainy"
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

    private func fetchCurrentWeather() async throws -> ServiceWeatherData? {
        // Would integrate with weather service
        return nil
    }

    // MARK: - Helper to extract MotivationalStyle from OnboardingProfile
    private func extractMotivationalStyle(from user: User) async -> MotivationalStyle? {
        guard let profile = user.onboardingProfile,
              !profile.communicationPreferencesData.isEmpty else {
            return nil
        }

        // Try to decode coaching plan from raw profile data
        let decoder = JSONDecoder()
        if let coachingPlan = try? decoder.decode(CoachingPlan.self, from: profile.rawFullProfileData) {
            return coachingPlan.motivationalStyle
        }

        // Return default if we can't decode
        return MotivationalStyle()
    }

    // MARK: - ServiceProtocol Methods

    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }

    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }

    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: _isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: _isConfigured ? nil : "Service not configured",
            metadata: [
                "hasCoachEngine": "true",
                "templatesAvailable": "true"
            ]
        )
    }
}

// MARK: - Fallback Templates
struct NotificationTemplates {
    func morningGreeting(user: User, context: MorningContext) -> NotificationContent {
        // Instead of hardcoded messages, generate a contextual greeting
        let timeBasedGreeting = getTimeBasedGreeting(context: context)
        let body = "\(timeBasedGreeting) Let's make today count, \(user.name ?? "champion")!"

        return NotificationContent(
            title: "Good morning, \(user.name ?? "there")! ☀️",
            body: body
        )
    }

    func workoutReminder(context: WorkoutReminderContext) -> NotificationContent {
        // Generate contextual reminder based on streak and workout type
        let streakMessage = context.streak > 0 ? "Day \(context.streak + 1) - " : ""
        let body = "\(streakMessage)Your \(context.workoutType) is ready. Let's keep the momentum going!"

        return NotificationContent(
            title: "Workout Time! 🏋️",
            body: body
        )
    }

    func mealReminder(mealType: MealType, context: MealReminderContext) -> NotificationContent {
        // Simple contextual message without arrays
        let timeSensitive = context.lastMealLogged == nil ? "Start your nutrition tracking with " : "Time for "
        let body = "\(timeSensitive)\(mealType.displayName.lowercased()). Every meal logged brings you closer to your goals!"

        return NotificationContent(
            title: "\(mealType.emoji) \(mealType.displayName) Reminder",
            body: body
        )
    }

    func achievement(achievement: Achievement, context: AchievementContext) -> NotificationContent {
        // Contextual achievement message
        let personalBestSuffix = context.personalBest ? " - a new personal best!" : "!"
        return NotificationContent(
            title: "🎉 Achievement Unlocked!",
            body: "\(achievement.name)\(personalBestSuffix) \(achievement.description)"
        )
    }
    
    private func getTimeBasedGreeting(context: MorningContext) -> String {
        switch context.dayOfWeek {
        case 1: return "Happy Sunday!"
        case 2: return "Monday motivation time!"
        case 6: return "Friday energy activated!"
        case 7: return "Saturday vibes!"
        default: return "Another great day ahead!"
        }
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

    var plannedWorkoutForToday: Workout? {
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
        // For now, return simple placeholder until we properly implement AI generation
        // The real implementation should use the AI service with persona context
        switch type {
        case .morningGreeting:
            return "Good morning! Let's make today amazing!"
        case .workoutReminder:
            return "Time for your workout! You've got this!"
        case .mealReminder(let mealType):
            return "Don't forget to log your \(mealType.displayName.lowercased())!"
        case .achievement:
            return "Amazing work! You've earned this achievement!"
        }
    }
}
