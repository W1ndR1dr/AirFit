import Foundation
import UserNotifications
@testable import AirFit

@MainActor
final class MockNotificationManager: NSObject {
    static let shared = MockNotificationManager()
    
    // Test properties
    var authorizationStatus: UNAuthorizationStatus = .authorized
    var requestAuthorizationCalled = false
    var requestAuthorizationResult: Bool = true
    var requestAuthorizationError: Error?
    
    var scheduleNotificationCalled = false
    var scheduledNotifications: [(identifier: NotificationManager.NotificationIdentifier, title: String, body: String)] = []
    
    var cancelNotificationCalled = false
    var cancelledIdentifiers: [NotificationManager.NotificationIdentifier] = []
    
    var cancelAllNotificationsCalled = false
    var getPendingNotificationsCalled = false
    var pendingNotifications: [UNNotificationRequest] = []
    
    var updateBadgeCountCalled = false
    var badgeCount: Int = 0
    
    var getAuthorizationStatusCalled = false
    var updatePreferencesCalled = false
    var rescheduleWithQuietHoursCalled = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - NotificationManager Methods
    
    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCalled = true
        if let error = requestAuthorizationError {
            throw error
        }
        return requestAuthorizationResult
    }
    
    func scheduleNotification(
        identifier: NotificationManager.NotificationIdentifier,
        title: String,
        body: String,
        subtitle: String? = nil,
        badge: NSNumber? = nil,
        sound: UNNotificationSound? = .default,
        attachments: [UNNotificationAttachment] = [],
        categoryIdentifier: NotificationManager.NotificationCategory? = nil,
        userInfo: [String: Any] = [:],
        trigger: UNNotificationTrigger
    ) async throws {
        scheduleNotificationCalled = true
        scheduledNotifications.append((identifier: identifier, title: title, body: body))
    }
    
    func cancelNotification(identifier: NotificationManager.NotificationIdentifier) {
        cancelNotificationCalled = true
        cancelledIdentifiers.append(identifier)
    }
    
    func cancelAllNotifications() {
        cancelAllNotificationsCalled = true
        scheduledNotifications.removeAll()
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        getPendingNotificationsCalled = true
        return pendingNotifications
    }
    
    func updateBadgeCount(_ count: Int) async {
        updateBadgeCountCalled = true
        badgeCount = count
    }
    
    func clearBadge() async {
        await updateBadgeCount(0)
    }
    
    // MARK: - Settings Extensions
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        getAuthorizationStatusCalled = true
        return authorizationStatus
    }
    
    func updatePreferences(_ preferences: NotificationPreferences) async {
        updatePreferencesCalled = true
    }
    
    func rescheduleWithQuietHours(_ quietHours: QuietHours) async {
        rescheduleWithQuietHoursCalled = true
    }
}