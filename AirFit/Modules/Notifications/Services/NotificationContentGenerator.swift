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

    init(
        coachEngine: CoachEngine,
        modelContext: ModelContext
    ) {
        self.coachEngine = coachEngine
        self.modelContext = modelContext
    }

    // MARK: - Morning Greeting
    func generateMorningGreeting(for user: User) async throws -> NotificationContent {
        // Gather context
        let context = await gatherMorningContext(for: user)

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
                    title: "Good morning, \(user.name ?? "there") ☀️",
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
                    NotificationAction(id: "START_WORKOUT", title: "Let's Go 💪"),
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
                title: "\(mealType.emoji) \(mealType.displayName) time",
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
                title: "🎉 Achievement Unlocked",
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
            "Time to crush your \(context.workoutType) 💪",
            "Ready for today's \(context.workoutType)?",
            "Your \(context.workoutType) awaits 🏋️",
            "Let's make today count 🎯"
        ]

        // Use streak to select title for variety
        let index = context.streak % titles.count
        return titles[index]
    }

    private func fetchLastNightSleep(for user: User) async throws -> SleepData? {
        // Get sleep data from HealthKit through daily logs
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Find daily log for yesterday
        if let yesterdayLog = user.dailyLogs.first(where: { log in
            calendar.isDate(log.date, inSameDayAs: yesterday)
        }), let sleepQuality = yesterdayLog.sleepQuality, sleepQuality > 0 {
            // Estimate sleep hours based on quality (simplified)
            let hours = Double(sleepQuality + 4) // 5-9 hours based on quality 1-5
            let duration = TimeInterval(hours * 3_600) // Convert to seconds

            // Determine quality based on hours
            let quality: SleepQuality
            switch hours {
            case 8...:
                quality = .excellent
            case 7..<8:
                quality = .good
            case 6..<7:
                quality = .fair
            default:
                quality = .poor
            }

            return SleepData(quality: quality, duration: duration)
        }

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
        let name = user.name ?? "champion"
        let greeting = getTimeBasedGreeting(context: context)

        // Build body with available context
        var body = greeting
        if !greeting.contains(name) && !greeting.contains("Day") {
            body += " \(name)"
        }

        return NotificationContent(
            title: "Good morning, \(name) ☀️",
            body: body
        )
    }

    func workoutReminder(context: WorkoutReminderContext) -> NotificationContent {
        // Generate contextual reminder based on streak and workout type
        let streakMessage = context.streak > 0 ? "Day \(context.streak + 1) - " : ""
        let body = "\(streakMessage)Your \(context.workoutType) is ready. Let's keep the momentum going."

        return NotificationContent(
            title: "Workout Time 🏋️",
            body: body
        )
    }

    func mealReminder(mealType: MealType, context: MealReminderContext) -> NotificationContent {
        // Simple contextual message without arrays
        let timeSensitive = context.lastMealLogged == nil ? "Start your nutrition tracking with " : "Time for "
        let body = "\(timeSensitive)\(mealType.displayName.lowercased()). Every meal logged brings you closer to your goals."

        return NotificationContent(
            title: "\(mealType.emoji) \(mealType.displayName) Reminder",
            body: body
        )
    }

    func achievement(achievement: Achievement, context: AchievementContext) -> NotificationContent {
        // Contextual achievement message
        let personalBestSuffix = context.personalBest ? " - a new personal best." : "."
        return NotificationContent(
            title: "🎉 Achievement Unlocked",
            body: "\(achievement.name)\(personalBestSuffix) \(achievement.description)"
        )
    }

    private func getTimeBasedGreeting(context: MorningContext) -> String {
        // Use context to build a meaningful greeting
        if context.currentStreak > 10 {
            return "Day \(context.currentStreak + 1) of excellence."
        } else if let workout = context.plannedWorkout {
            return "Ready for your \(workout.name)?"
        } else if let sleep = context.sleepQuality {
            switch sleep {
            case .excellent: return "Well-rested and ready."
            case .good: return "Good morning. Feeling refreshed?"
            case .fair, .poor: return "Morning. Let's take it easy today."
            }
        } else {
            return "Rise and shine."
        }
    }
}

// MARK: - User Extensions with Real Data
extension User {
    @MainActor
    var workoutStreak: Int {
        // Calculate actual streak from workout history
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get workouts sorted by date descending
        let sortedWorkouts = workouts
            .compactMap { workout -> (workout: Workout, date: Date)? in
                guard let date = workout.completedDate else { return nil }
                return (workout, date)
            }
            .sorted { $0.date > $1.date }
            .map { $0.workout }

        var streak = 0
        var checkDate = today

        for workout in sortedWorkouts {
            guard let completedDate = workout.completedDate else { continue }
            let workoutDate = calendar.startOfDay(for: completedDate)

            if workoutDate == checkDate {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if workoutDate < checkDate {
                // Gap in workouts, streak is broken
                break
            }
        }

        return streak
    }

    @MainActor
    var daysSinceLastWorkout: Int {
        // Find the most recent completed workout
        let completedWorkouts = workouts.compactMap { workout -> Date? in
            return workout.completedDate
        }

        guard let mostRecentDate = completedWorkouts.sorted(by: >).first else {
            return 999 // No workouts recorded
        }

        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: mostRecentDate, to: Date()).day ?? 0
        return max(0, days)
    }

    @MainActor
    var plannedWorkoutForToday: Workout? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return workouts.first { workout in
            if let plannedDate = workout.plannedDate {
                return calendar.isDate(plannedDate, inSameDayAs: today)
            }
            return false
        }
    }

    @MainActor
    var overallStreak: Int {
        // Calculate streak based on any daily activity (workout, meal logging, etc.)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var streak = 0
        var checkDate = today

        // Check up to 365 days back
        for _ in 0..<365 {
            let hasActivity = hasActivityOnDate(checkDate)

            if hasActivity {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        return streak
    }

    @MainActor
    var nutritionGoals: NutritionGoals? {
        // Calculate base goals using BMR and activity level
        let bmr = calculateBMR()
        let tdee = bmr * 1.5 // Moderate activity multiplier

        // TODO: Fetch actual weight from HealthKit using async context
        // For now, using population averages: 170 lbs for males, 140 lbs for females
        let weightLbs = self.biologicalSex == "male" ? 170.0 : 140.0

        // Calculate macros based on user preferences
        let proteinGrams = Int(self.proteinGramsPerPound * weightLbs)
        let fatGrams = Int(tdee * self.fatPercentage / 9) // 9 calories per gram of fat
        let carbCalories = tdee - (Double(proteinGrams) * 4) - (Double(fatGrams) * 9)
        let carbGrams = Int(carbCalories / 4) // 4 calories per gram of carbs

        return NutritionGoals(
            dailyCalories: Int(tdee),
            proteinGrams: proteinGrams,
            carbGrams: carbGrams,
            fatGrams: fatGrams
        )
    }

    private func calculateBMR() -> Double {
        // Mifflin-St Jeor equation using population averages
        // TODO: Fetch actual weight and height from HealthKit
        let weightLbs = self.biologicalSex == "male" ? 170.0 : 140.0
        let weightKg = weightLbs * 0.453592 // Convert to kg
        let age = self.age ?? 30
        let heightCm = self.biologicalSex == "male" ? 175.0 : 162.0 // Average heights

        if self.biologicalSex == "male" {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        } else {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
    }

    @MainActor
    var lastMealLoggedTime: Date? {
        // Get most recent food entry
        return foodEntries.map { $0.loggedAt }.max()
    }

    @MainActor
    var favoriteFoods: [String] {
        // Calculate top 5 most logged foods
        let foodCounts = foodEntries.reduce(into: [String: Int]()) { counts, entry in
            if let foodName = entry.items.first?.name {
                counts[foodName, default: 0] += 1
            }
        }

        return foodCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }

    // Helper method to check if user had any activity on a given date
    @MainActor
    private func hasActivityOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current

        // Check workouts
        let hasWorkout = workouts.contains { workout in
            if let completedDate = workout.completedDate {
                return calendar.isDate(completedDate, inSameDayAs: date)
            }
            return false
        }

        // Check food entries
        let hasFoodEntry = foodEntries.contains { entry in
            calendar.isDate(entry.loggedAt, inSameDayAs: date)
        }

        // Check daily logs
        let hasDailyLog = dailyLogs.contains { log in
            calendar.isDate(log.date, inSameDayAs: date)
        }

        return hasWorkout || hasFoodEntry || hasDailyLog
    }
}
