import SwiftUI
import SwiftData

/// Coordinator for managing notification module navigation and dependencies
@MainActor
final class NotificationsCoordinator: ObservableObject {
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
    func startWorkoutLiveActivity(workoutType: String) async throws {
        try await liveActivityManager.startWorkoutActivity(
            workoutType: workoutType,
            startTime: Date()
        )
    }
    
    func updateWorkoutLiveActivity(
        elapsedTime: TimeInterval,
        heartRate: Int,
        activeCalories: Int,
        currentExercise: String?
    ) async {
        await liveActivityManager.updateWorkoutActivity(
            elapsedTime: elapsedTime,
            heartRate: heartRate,
            activeCalories: activeCalories,
            currentExercise: currentExercise
        )
    }
    
    func endWorkoutLiveActivity() async {
        await liveActivityManager.endWorkoutActivity()
    }
    
    func startMealTrackingLiveActivity(mealType: MealType) async throws {
        try await liveActivityManager.startMealTrackingActivity(mealType: mealType)
    }
    
    func updateMealTrackingLiveActivity(
        itemsLogged: Int,
        totalCalories: Int,
        totalProtein: Double,
        lastFoodItem: String?
    ) async {
        await liveActivityManager.updateMealTracking(
            itemsLogged: itemsLogged,
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            lastFoodItem: lastFoodItem
        )
    }
    
    func endMealTrackingLiveActivity() async {
        await liveActivityManager.endMealTrackingActivity()
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
