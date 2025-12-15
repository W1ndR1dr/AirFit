import UserNotifications
import SwiftData

/// Manages smart notifications for nutrition tracking.
/// Sends contextual reminders based on macro progress throughout the day.
actor NotificationManager {
    static let shared = NotificationManager()

    private var isAuthorized = false

    // Notification identifiers
    private enum NotificationID {
        static let proteinReminder = "protein-reminder"
        static let calorieReminder = "calorie-reminder"
        static let eveningCheckIn = "evening-checkin"
        static let morningBriefing = "morning-briefing"
        static let insightAlert = "insight-alert"
    }

    // Track notified insights to avoid duplicates
    private var notifiedInsightIds: Set<String> = []

    // MARK: - Authorization

    // Notifications disabled for now
    func requestAuthorization() async -> Bool {
        isAuthorized = false
        return false
    }

    func checkAuthorizationStatus() async -> Bool {
        isAuthorized = false
        return false
    }

    // MARK: - Insight Notifications

    /// Schedule notification for high-priority insights.
    /// Only notifies for tier 1-2 insights to avoid notification fatigue.
    func scheduleInsightNotification(
        insightId: String,
        title: String,
        body: String,
        category: String,
        tier: Int
    ) async {
        guard isAuthorized else { return }
        guard tier <= 2 else { return } // Only tier 1-2 get notifications
        guard !notifiedInsightIds.contains(insightId) else { return } // Already notified

        // Track this insight
        notifiedInsightIds.insert(insightId)

        let content = UNMutableNotificationContent()

        // Different treatment for milestones vs other insights
        if category == "milestone" {
            content.title = "🎉 " + title
            content.body = body
            content.sound = UNNotificationSound.default
        } else if category == "anomaly" {
            content.title = "⚠️ " + title
            content.body = body
            content.sound = UNNotificationSound.default
        } else {
            content.title = "💡 " + title
            // Truncate body for notification - tease to get them to open
            let truncatedBody = body.count > 100 ? String(body.prefix(100)) + "..." : body
            content.body = truncatedBody
            content.sound = UNNotificationSound.default
        }

        content.categoryIdentifier = "INSIGHT_ALERT"
        content.userInfo = ["insightId": insightId, "category": category]

        // Show after 2 second delay (feels more natural)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(NotificationID.insightAlert)-\(insightId)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("[NotificationManager] Scheduled insight notification: \(title)")
        } catch {
            print("Failed to schedule insight notification: \(error)")
        }
    }

    /// Check insights and notify for any high-tier ones
    func checkAndNotifyForInsights(_ insights: [APIClient.InsightData]) async {
        for insight in insights {
            await scheduleInsightNotification(
                insightId: insight.id,
                title: insight.title,
                body: insight.body,
                category: insight.category,
                tier: insight.tier
            )
        }
    }

    // MARK: - Smart Notifications

    /// Schedule protein gap notification if user is behind target.
    /// Called after each food log or periodically in background.
    func scheduleProteinReminderIfNeeded(
        currentProtein: Int,
        targetProtein: Int,
        hoursRemaining: Int
    ) async {
        guard isAuthorized else { return }
        guard hoursRemaining > 0 && hoursRemaining <= 6 else { return }

        let gap = targetProtein - currentProtein
        let percentComplete = Double(currentProtein) / Double(targetProtein)

        // Only notify if significantly behind (less than expected progress)
        // Expected: if 6 hours left, should be ~75% complete
        let expectedProgress = 1.0 - (Double(hoursRemaining) / 16.0) // Assuming 16 waking hours
        guard percentComplete < expectedProgress - 0.1 else { return }
        guard gap >= 30 else { return } // At least 30g behind

        let content = UNMutableNotificationContent()
        content.title = "Protein Check"
        content.body = "\(gap)g protein to go with \(hoursRemaining)h left. Quick protein hit?"
        content.sound = .default
        content.categoryIdentifier = "NUTRITION_REMINDER"

        // Schedule for 30 minutes from now (gives time to act)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)

        let request = UNNotificationRequest(
            identifier: NotificationID.proteinReminder,
            content: content,
            trigger: trigger
        )

        do {
            // Remove any existing protein reminder first
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [NotificationID.proteinReminder]
            )
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule protein reminder: \(error)")
        }
    }

    /// Schedule calorie warning if significantly over or under.
    func scheduleCalorieAlertIfNeeded(
        currentCalories: Int,
        targetCalories: Int,
        isTrainingDay: Bool
    ) async {
        guard isAuthorized else { return }

        let ratio = Double(currentCalories) / Double(targetCalories)

        // Over by 20%+
        if ratio > 1.2 {
            let over = currentCalories - targetCalories
            await scheduleNotification(
                id: NotificationID.calorieReminder,
                title: "Calorie Alert",
                body: "You're \(over) cal over target. Maybe a lighter dinner?",
                delay: 60 // 1 minute
            )
        }
        // Under by 30%+ with limited time (evening)
        else if ratio < 0.7 && isEvening() {
            let remaining = targetCalories - currentCalories
            await scheduleNotification(
                id: NotificationID.calorieReminder,
                title: "Low Intake",
                body: "Only \(currentCalories) cal logged today. \(remaining) to go.",
                delay: 60
            )
        }
    }

    /// Schedule evening check-in notification.
    func scheduleEveningCheckIn(at hour: Int = 20, minute: Int = 0) async {
        guard isAuthorized else { return }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Evening Check-in"
        content.body = "How'd today go? Tap to review your nutrition."
        content.sound = .default
        content.categoryIdentifier = "DAILY_CHECKIN"

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: NotificationID.eveningCheckIn,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule evening check-in: \(error)")
        }
    }

    /// Schedule morning briefing notification.
    func scheduleMorningBriefing(at hour: Int = 7, minute: Int = 30, isTrainingDay: Bool) async {
        guard isAuthorized else { return }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = isTrainingDay ? "Training Day" : "Rest Day"
        content.body = isTrainingDay
            ? "Higher carbs today. Target: 175g protein, 2600 cal."
            : "Rest day targets: 175g protein, 2200 cal."
        content.sound = .default
        content.categoryIdentifier = "DAILY_BRIEFING"

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: NotificationID.morningBriefing,
            content: content,
            trigger: trigger
        )

        do {
            // Remove previous briefing
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [NotificationID.morningBriefing]
            )
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule morning briefing: \(error)")
        }
    }

    // MARK: - Helpers

    private func scheduleNotification(id: String, title: String, body: String, delay: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule notification \(id): \(error)")
        }
    }

    private func isEvening() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 18
    }

    func hoursRemainingInDay() -> Int {
        let hour = Calendar.current.component(.hour, from: Date())
        // Assume day ends at 22:00 for nutrition purposes
        return max(0, 22 - hour)
    }

    // MARK: - Clear Notifications

    func clearAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func clearDelivered() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

// MARK: - Notification Categories (for actionable notifications)

extension NotificationManager {
    func registerCategories() {
        let logAction = UNNotificationAction(
            identifier: "LOG_FOOD",
            title: "Log Food",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: []
        )

        let nutritionCategory = UNNotificationCategory(
            identifier: "NUTRITION_REMINDER",
            actions: [logAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let checkInCategory = UNNotificationCategory(
            identifier: "DAILY_CHECKIN",
            actions: [logAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let briefingCategory = UNNotificationCategory(
            identifier: "DAILY_BRIEFING",
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let viewInsightAction = UNNotificationAction(
            identifier: "VIEW_INSIGHT",
            title: "View Details",
            options: [.foreground]
        )

        let insightCategory = UNNotificationCategory(
            identifier: "INSIGHT_ALERT",
            actions: [viewInsightAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            nutritionCategory,
            checkInCategory,
            briefingCategory,
            insightCategory
        ])
    }
}
