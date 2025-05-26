import Foundation
import UserNotifications

/// Protocol for scheduling and managing local notifications.
protocol NotificationManagerProtocol {
    func requestNotificationPermission(completion: @escaping (Bool, Error?) -> Void)
    func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void)
    func scheduleProactiveCheckInNotification(title: String, body: String, timeInterval: TimeInterval)
}
