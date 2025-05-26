import Foundation
import UserNotifications
@testable import AirFit

final class MockNotificationManager: NotificationManagerProtocol {
    var permissionRequested = false
    var permissionResponse: Bool = true
    var getSettingsCalled = false
    var scheduleCalledWith: (title: String, body: String, interval: TimeInterval)?

    func requestNotificationPermission(completion: @escaping (Bool, Error?) -> Void) {
        permissionRequested = true
        completion(permissionResponse, nil)
    }

    func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        getSettingsCalled = true
        completion(UNNotificationSettings())
    }

    func scheduleProactiveCheckInNotification(title: String, body: String, timeInterval: TimeInterval) {
        scheduleCalledWith = (title, body, timeInterval)
    }
}
