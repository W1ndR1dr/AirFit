import Foundation
import SwiftUI
import SwiftData
import UserNotifications

/// Coordinator for managing notification module navigation and dependencies
@MainActor
final class NotificationsCoordinator {
    private let modelContext: ModelContext
    private let notificationManager: NotificationManager
    private let engagementEngine: EngagementEngine
    private let liveActivityManager: LiveActivityManager
    private let notificationContentGenerator: NotificationContentGenerator

    init(modelContext: ModelContext,
         coachEngine: CoachEngine,
         notificationManager: NotificationManager,
         liveActivityManager: LiveActivityManager) {
        self.modelContext = modelContext
        self.notificationManager = notificationManager
        self.liveActivityManager = liveActivityManager
        self.engagementEngine = EngagementEngine(
            modelContext: modelContext,
            coachEngine: coachEngine,
            notificationManager: notificationManager
        )
        self.notificationContentGenerator = NotificationContentGenerator(
            coachEngine: coachEngine,
            modelContext: modelContext
        )
    }

    // MARK: - Notification Setup
    func setupNotifications() async throws {
        // Request notification authorization
        let authorized = try await notificationManager.requestAuthorization()

        if authorized {
            // Schedule background tasks for engagement monitoring
            engagementEngine.scheduleBackgroundTasks()
        }
    }

    // MARK: - User Activity
    func updateUserActivity(for user: User) {
        engagementEngine.updateUserActivity(for: user)
    }

    // MARK: - Smart Notifications
    func scheduleSmartNotifications(for user: User) async {
        await engagementEngine.scheduleSmartNotifications(for: user)
    }

    // MARK: - Live Activities
    // Note: Workout activities removed per user request - no workout logging
    
    func startNutritionLiveActivity(dailyGoals: LiveActivityNutritionGoals) async throws {
        try await liveActivityManager.startNutritionActivity(dailyGoal: dailyGoals)
    }

    func updateNutritionLiveActivity(
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        mealsLogged: Int,
        lastMealTime: Date? = nil
    ) async {
        await liveActivityManager.updateNutritionActivity(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            mealsLogged: mealsLogged,
            lastMealTime: lastMealTime
        )
    }

    func endNutritionLiveActivity() async {
        await liveActivityManager.endNutritionActivity()
    }

    // MARK: - Manual Notification Scheduling
    func scheduleMorningGreeting(for user: User) async throws {
        let content = try await notificationContentGenerator.generateMorningGreeting(for: user)

        // Schedule for tomorrow morning at user's preferred time
        let preferences = user.notificationPreferences ?? NotificationPreferences()
        let dateComponents = Calendar.current.dateComponents(
            [.hour, .minute],
            from: preferences.morningTime
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        try await notificationManager.scheduleNotification(
            identifier: .morning,
            title: content.title,
            body: content.body,
            categoryIdentifier: .dailyCheck,
            trigger: trigger
        )
    }

    // MARK: - Re-engagement
    func checkAndHandleLapsedUsers() async throws {
        let lapsedUsers = try await engagementEngine.detectLapsedUsers()

        for user in lapsedUsers {
            await engagementEngine.sendReEngagementNotification(for: user)
        }
    }

    // MARK: - Achievement Notifications
    func sendAchievementNotification(for user: User, achievement: Achievement) async throws {
        let content = try await notificationContentGenerator.generateAchievementNotification(
            for: user,
            achievement: achievement
        )

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )

        try await notificationManager.scheduleNotification(
            identifier: .achievement(achievement.id),
            title: content.title,
            body: content.body,
            sound: content.sound != .default ? UNNotificationSound(named: UNNotificationSoundName(content.sound.fileName ?? "")) : .default,
            categoryIdentifier: .achievement,
            trigger: trigger
        )
    }

    // MARK: - Notification Management
    func cancelAllNotifications() {
        notificationManager.cancelAllNotifications()
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationManager.getPendingNotifications()
    }
}
