import Foundation
import UserNotifications

/// Default implementation of NotificationManagerProtocol
final class DefaultNotificationManager: NotificationManagerProtocol {
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        AppLogger.info("Initialized DefaultNotificationManager", category: .notifications)
    }
    
    func requestNotificationPermission(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        notificationCenter.requestAuthorization(options: options) { granted, error in
            if let error = error {
                AppLogger.error("Failed to request notification permission", error: error, category: .notifications)
            } else {
                AppLogger.info("Notification permission granted: \(granted)", category: .notifications)
            }
            
            completion(granted, error)
        }
    }
    
    func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            AppLogger.debug("Current notification settings: \(settings.authorizationStatus.rawValue)", category: .notifications)
            completion(settings)
        }
    }
    
    func scheduleProactiveCheckInNotification(title: String, body: String, timeInterval: TimeInterval) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "CHECK_IN"
        
        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        // Create request
        let identifier = "proactive_check_in_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        notificationCenter.add(request) { error in
            if let error = error {
                AppLogger.error("Failed to schedule notification", error: error, category: .notifications)
            } else {
                AppLogger.info("Scheduled check-in notification for \(timeInterval) seconds from now", category: .notifications)
            }
        }
    }
}