import Foundation
import UserNotifications

// MARK: - NotificationManager Extensions for Settings
extension NotificationManager {
    /// Get authorization status async
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Update preferences based on user settings
    func updatePreferences(_ preferences: NotificationPreferences) async {
        // Remove all pending notifications if disabled
        if !preferences.systemEnabled {
            cancelAllNotifications()
            AppLogger.info("Removed all pending notifications", category: .notifications)
            return
        }
        
        // Update individual notification types
        await rescheduleNotifications(preferences: preferences)
    }
    
    /// Reschedule notifications with quiet hours
    func rescheduleWithQuietHours(_ quietHours: QuietHours) async {
        guard quietHours.enabled else { return }
        
        // Get all pending notifications
        let pendingRequests = await getPendingNotifications()
        
        // Reschedule each notification to respect quiet hours
        for request in pendingRequests {
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { continue }
            
            // Check if notification falls within quiet hours
            if let adjustedTrigger = adjustTriggerForQuietHours(trigger, quietHours: quietHours) {
                // Remove old notification
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
                
                // Create new request with adjusted trigger
                let newRequest = UNNotificationRequest(
                    identifier: request.identifier,
                    content: request.content,
                    trigger: adjustedTrigger
                )
                
                try? await UNUserNotificationCenter.current().add(newRequest)
            }
        }
        
        AppLogger.info("Rescheduled notifications with quiet hours", category: .notifications)
    }
    
    // MARK: - Private Helpers
    
    private func rescheduleNotifications(preferences: NotificationPreferences) async {
        // This would typically integrate with Module 9 (Notifications & Engagement Engine)
        // For now, we'll handle basic notification types
        
        cancelAllNotifications()
        
        if preferences.workoutReminders {
            await scheduleWorkoutReminders()
        }
        
        if preferences.mealReminders {
            await scheduleMealReminders()
        }
        
        if preferences.dailyCheckins {
            await scheduleDailyCheckins()
        }
    }
    
    private func scheduleWorkoutReminders() async {
        // Schedule morning workout reminder at 7 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 7
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        try? await scheduleNotification(
            identifier: .morning,
            title: "Time to Move! 💪",
            body: "Ready for today's workout? Your AI coach is here to help.",
            categoryIdentifier: .workout,
            trigger: trigger
        )
    }
    
    private func scheduleMealReminders() async {
        // Schedule meal reminders at typical meal times
        let mealTimes = [
            (hour: 8, type: MealType.breakfast, title: "Breakfast Time", body: "Start your day with a nutritious meal"),
            (hour: 12, type: MealType.lunch, title: "Lunch Break", body: "Time to refuel! Don't forget to log your meal"),
            (hour: 18, type: MealType.dinner, title: "Dinner Time", body: "End your day with a balanced dinner")
        ]
        
        for meal in mealTimes {
            var dateComponents = DateComponents()
            dateComponents.hour = meal.hour
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            try? await scheduleNotification(
                identifier: .meal(meal.type),
                title: meal.title,
                body: meal.body,
                categoryIdentifier: .meal,
                trigger: trigger
            )
        }
    }
    
    private func scheduleDailyCheckins() async {
        // Schedule evening check-in at 8 PM
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        try? await scheduleNotification(
            identifier: NotificationIdentifier.lapse(0), // Using lapse for daily check-in
            title: "Daily Check-in 📊",
            body: "How was your day? Log your progress and mood.",
            categoryIdentifier: .dailyCheck,
            trigger: trigger
        )
    }
    
    private func adjustTriggerForQuietHours(_ trigger: UNCalendarNotificationTrigger, quietHours: QuietHours) -> UNCalendarNotificationTrigger? {
        guard var dateComponents = trigger.dateComponents.date else { return trigger }
        
        let calendar = Calendar.current
        let quietStart = calendar.dateComponents([.hour, .minute], from: quietHours.startTime)
        let quietEnd = calendar.dateComponents([.hour, .minute], from: quietHours.endTime)
        
        guard let startHour = quietStart.hour,
              let endHour = quietEnd.hour,
              let triggerHour = trigger.dateComponents.hour else { return trigger }
        
        // Check if trigger falls within quiet hours
        let isInQuietHours: Bool
        if startHour < endHour {
            // Quiet hours don't cross midnight
            isInQuietHours = triggerHour >= startHour && triggerHour < endHour
        } else {
            // Quiet hours cross midnight
            isInQuietHours = triggerHour >= startHour || triggerHour < endHour
        }
        
        if isInQuietHours {
            // Adjust to after quiet hours end
            var adjustedComponents = trigger.dateComponents
            adjustedComponents.hour = endHour
            adjustedComponents.minute = 0
            
            return UNCalendarNotificationTrigger(
                dateMatching: adjustedComponents,
                repeats: trigger.repeats
            )
        }
        
        return trigger
    }
}

