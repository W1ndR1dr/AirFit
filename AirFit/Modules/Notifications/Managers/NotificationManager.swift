@preconcurrency import UserNotifications
import UIKit

@MainActor
final class NotificationManager: NSObject, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "notification-manager"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }
    
    private let center = UNUserNotificationCenter.current()
    private var pendingNotifications: Set<String> = []
    
    // Notification categories
    enum NotificationCategory: String {
        case dailyCheck = "DAILY_CHECK"
        case workout = "WORKOUT"
        case meal = "MEAL"
        case hydration = "HYDRATION"
        case achievement = "ACHIEVEMENT"
        case reEngagement = "RE_ENGAGEMENT"
    }
    
    // Notification identifiers
    enum NotificationIdentifier {
        case morning
        case workout(Date)
        case meal(MealType)
        case hydration
        case achievement(String)
        case lapse(Int)
        
        var stringValue: String {
            switch self {
            case .morning: return "morning_greeting"
            case .workout(let date): return "workout_\(date.timeIntervalSince1970)"
            case .meal(let type): return "meal_\(type.rawValue)"
            case .hydration: return "hydration_reminder"
            case .achievement(let id): return "achievement_\(id)"
            case .lapse(let days): return "lapse_\(days)"
            }
        }
    }
    
    override init() {
        super.init()
        center.delegate = self
        setupNotificationCategories()
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        pendingNotifications.removeAll()
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        let settings = await center.notificationSettings()
        let status: ServiceHealth.Status = settings.authorizationStatus == .authorized ? .healthy : .degraded
        
        return ServiceHealth(
            status: status,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: status == .healthy ? nil : "Notifications not authorized",
            metadata: [
                "authorizationStatus": "\(settings.authorizationStatus.rawValue)",
                "pendingNotifications": "\(pendingNotifications.count)"
            ]
        )
    }
    
    // MARK: - Authorization
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [
            .alert, .badge, .sound, .provisional, .providesAppNotificationSettings
        ]
        
        let granted = try await center.requestAuthorization(options: options)
        
        if granted {
            await registerForRemoteNotifications()
        }
        
        AppLogger.info("Notification authorization: \(granted)", category: .general)
        return granted
    }
    
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Category Setup
    private func setupNotificationCategories() {
        let categories: Set<UNNotificationCategory> = [
            // Daily check category
            UNNotificationCategory(
                identifier: NotificationCategory.dailyCheck.rawValue,
                actions: [
                    UNNotificationAction(
                        identifier: "LOG_MOOD",
                        title: "Log Mood",
                        options: .foreground
                    ),
                    UNNotificationAction(
                        identifier: "QUICK_CHAT",
                        title: "Chat with Coach",
                        options: .foreground
                    )
                ],
                intentIdentifiers: []
            ),
            
            // Workout category
            UNNotificationCategory(
                identifier: NotificationCategory.workout.rawValue,
                actions: [
                    UNNotificationAction(
                        identifier: "START_WORKOUT",
                        title: "Start Workout",
                        options: .foreground
                    ),
                    UNNotificationAction(
                        identifier: "SNOOZE_30",
                        title: "Remind in 30 min",
                        options: []
                    )
                ],
                intentIdentifiers: []
            ),
            
            // Meal category
            UNNotificationCategory(
                identifier: NotificationCategory.meal.rawValue,
                actions: [
                    UNNotificationAction(
                        identifier: "LOG_MEAL",
                        title: "Log Meal",
                        options: .foreground
                    ),
                    UNNotificationAction(
                        identifier: "QUICK_ADD",
                        title: "Quick Add",
                        options: .foreground
                    )
                ],
                intentIdentifiers: []
            )
        ]
        
        center.setNotificationCategories(categories)
    }
    
    // MARK: - Scheduling
    func scheduleNotification(
        identifier: NotificationIdentifier,
        title: String,
        body: String,
        subtitle: String? = nil,
        badge: NSNumber? = nil,
        sound: UNNotificationSound? = .default,
        attachments: [UNNotificationAttachment] = [],
        categoryIdentifier: NotificationCategory? = nil,
        userInfo: [String: Any] = [:],
        trigger: UNNotificationTrigger
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        
        if let badge = badge {
            content.badge = badge
        }
        
        content.sound = sound
        content.attachments = attachments
        
        if let category = categoryIdentifier {
            content.categoryIdentifier = category.rawValue
        }
        
        content.userInfo = userInfo
        content.interruptionLevel = determineInterruptionLevel(for: categoryIdentifier)
        
        let request = UNNotificationRequest(
            identifier: identifier.stringValue,
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
        pendingNotifications.insert(identifier.stringValue)
        
        AppLogger.info("Scheduled notification: \(identifier.stringValue)", category: .general)
    }
    
    // MARK: - Management
    func cancelNotification(identifier: NotificationIdentifier) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier.stringValue])
        pendingNotifications.remove(identifier.stringValue)
        
        AppLogger.info("Cancelled notification: \(identifier.stringValue)", category: .general)
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        pendingNotifications.removeAll()
        
        AppLogger.info("Cancelled all notifications", category: .general)
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }
    
    // MARK: - Rich Content
    func createAttachment(from imageData: Data, identifier: String) throws -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(tmpSubFolderName, isDirectory: true)
        
        try fileManager.createDirectory(
            at: tmpSubFolderURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let imageFileIdentifier = identifier + ".png"
        let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
        
        try imageData.write(to: fileURL)
        
        let attachment = try UNNotificationAttachment(
            identifier: identifier,
            url: fileURL,
            options: [:]
        )
        
        return attachment
    }
    
    // MARK: - Helpers
    private func determineInterruptionLevel(for category: NotificationCategory?) -> UNNotificationInterruptionLevel {
        guard let category = category else { return .active }
        
        switch category {
        case .achievement:
            return .passive
        case .reEngagement:
            return .timeSensitive
        default:
            return .active
        }
    }
    
    // MARK: - Badge Management
    func updateBadgeCount(_ count: Int) async {
        await MainActor.run {
            if #available(iOS 17.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(count) { error in
                    if let error = error {
                        AppLogger.error("Failed to set badge count: \(error)", category: .notifications)
                    }
                }
            } else {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }
    
    func clearBadge() async {
        await updateBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notifications even when app is in foreground
        return [.banner, .sound, .badge]
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await handleNotificationResponse(response)
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "LOG_MOOD":
            await navigateToMoodLogging()
        case "QUICK_CHAT":
            await navigateToChat()
        case "START_WORKOUT":
            await navigateToWorkout()
        case "LOG_MEAL":
            await navigateToMealLogging()
        case UNNotificationDefaultActionIdentifier:
            await handleDefaultAction(userInfo: userInfo)
        default:
            break
        }
        
        AppLogger.info("Handled notification action: \(actionIdentifier)", category: .general)
    }
    
    private func navigateToMoodLogging() async {
        NotificationCenter.default.post(
            name: .navigateToMoodLogging,
            object: nil
        )
    }
    
    private func navigateToChat() async {
        NotificationCenter.default.post(
            name: .navigateToChat,
            object: nil
        )
    }
    
    private func navigateToWorkout() async {
        NotificationCenter.default.post(
            name: .navigateToWorkout,
            object: nil
        )
    }
    
    private func navigateToMealLogging() async {
        NotificationCenter.default.post(
            name: .navigateToMealLogging,
            object: nil
        )
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) async {
        // Handle based on notification type in userInfo
        if let type = userInfo["type"] as? String {
            switch type {
            case "workout":
                await navigateToWorkout()
            case "meal":
                await navigateToMealLogging()
            default:
                break
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToMoodLogging = Notification.Name("navigateToMoodLogging")
    static let navigateToChat = Notification.Name("navigateToChat")
    static let navigateToWorkout = Notification.Name("navigateToWorkout")
    static let navigateToMealLogging = Notification.Name("navigateToMealLogging")
}
