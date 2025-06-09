import Foundation
import SwiftData
import BackgroundTasks
import UserNotifications

@MainActor
final class EngagementEngine: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "engagement-engine"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }
    
    private let modelContext: ModelContext
    private let notificationManager: NotificationManager
    private let coachEngine: CoachEngine
    
    // Background task identifiers
    static let lapseDetectionTaskIdentifier = "com.airfit.lapseDetection"
    static let engagementAnalysisTaskIdentifier = "com.airfit.engagementAnalysis"
    
    // Engagement thresholds
    private let inactivityThresholdDays = 3
    private let churnRiskThresholdDays = 7
    
    init(modelContext: ModelContext, coachEngine: CoachEngine, notificationManager: NotificationManager) {
        self.modelContext = modelContext
        self.coachEngine = coachEngine
        self.notificationManager = notificationManager
        registerBackgroundTasks()
    }
    
    // MARK: - Background Task Registration
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.lapseDetectionTaskIdentifier,
            using: nil
        ) { task in
            Task {
                guard let processingTask = task as? BGProcessingTask else {
                    AppLogger.error("Unexpected task type for lapse detection", category: .notifications)
                    task.setTaskCompleted(success: false)
                    return
                }
                await self.handleLapseDetection(task: processingTask)
            }
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.engagementAnalysisTaskIdentifier,
            using: nil
        ) { task in
            Task {
                guard let processingTask = task as? BGProcessingTask else {
                    AppLogger.error("Unexpected task type for engagement analysis", category: .notifications)
                    task.setTaskCompleted(success: false)
                    return
                }
                await self.handleEngagementAnalysis(task: processingTask)
            }
        }
    }
    
    // MARK: - Background Task Scheduling
    func scheduleBackgroundTasks() {
        scheduleLapseDetection()
        scheduleEngagementAnalysis()
    }
    
    private func scheduleLapseDetection() {
        let request = BGProcessingTaskRequest(
            identifier: Self.lapseDetectionTaskIdentifier
        )
        request.requiresNetworkConnectivity = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours
        
        do {
            try BGTaskScheduler.shared.submit(request)
            AppLogger.info("Scheduled lapse detection task", category: .general)
        } catch {
            AppLogger.error("Failed to schedule lapse detection", error: error, category: .general)
        }
    }
    
    private func scheduleEngagementAnalysis() {
        let request = BGProcessingTaskRequest(
            identifier: Self.engagementAnalysisTaskIdentifier
        )
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 72 * 60 * 60) // 72 hours
        
        do {
            try BGTaskScheduler.shared.submit(request)
            AppLogger.info("Scheduled engagement analysis task", category: .general)
        } catch {
            AppLogger.error("Failed to schedule engagement analysis", error: error, category: .general)
        }
    }
    
    // MARK: - Lapse Detection
    private func handleLapseDetection(task: BGProcessingTask) async {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        do {
            let users = try await detectLapsedUsers()
            
            for user in users {
                await sendReEngagementNotification(for: user)
            }
            
            task.setTaskCompleted(success: true)
            
            // Reschedule
            scheduleLapseDetection()
            
        } catch {
            AppLogger.error("Lapse detection failed", error: error, category: .general)
            task.setTaskCompleted(success: false)
        }
    }
    
    func detectLapsedUsers() async throws -> [User] {
        let calendar = Calendar.current
        let thresholdDate = calendar.date(
            byAdding: .day,
            value: -inactivityThresholdDays,
            to: Date()
        )!
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.lastActiveAt < thresholdDate
            }
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Engagement Analysis
    private func handleEngagementAnalysis(task: BGProcessingTask) async {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        do {
            let metrics = try await analyzeEngagementMetrics()
            await updateEngagementStrategies(based: metrics)
            
            task.setTaskCompleted(success: true)
            
            // Reschedule
            scheduleEngagementAnalysis()
            
        } catch {
            AppLogger.error("Engagement analysis failed", error: error, category: .general)
            task.setTaskCompleted(success: false)
        }
    }
    
    private func analyzeEngagementMetrics() async throws -> EngagementMetrics {
        let descriptor = FetchDescriptor<User>()
        let users = try modelContext.fetch(descriptor)
        
        var totalUsers = users.count
        var activeUsers = 0
        var lapsedUsers = 0
        var churnRiskUsers = 0
        
        let calendar = Calendar.current
        let now = Date()
        
        for user in users {
            let daysSinceActive = calendar.dateComponents(
                [.day],
                from: user.lastActiveAt,
                to: now
            ).day ?? 0
            
            if daysSinceActive <= 1 {
                activeUsers += 1
            } else if daysSinceActive <= inactivityThresholdDays {
                // Still considered active
            } else if daysSinceActive <= churnRiskThresholdDays {
                lapsedUsers += 1
            } else {
                churnRiskUsers += 1
            }
        }
        
        return EngagementMetrics(
            totalUsers: totalUsers,
            activeUsers: activeUsers,
            lapsedUsers: lapsedUsers,
            churnRiskUsers: churnRiskUsers,
            avgSessionsPerWeek: calculateAverageSessionsPerWeek(users),
            avgSessionDuration: calculateAverageSessionDuration(users)
        )
    }
    
    // MARK: - Re-engagement
    func sendReEngagementNotification(for user: User) async {
        do {
            // Check user preferences
            guard let preferences = user.onboardingProfile?.communicationPreferencesData,
                  let commPrefs = try? JSONDecoder().decode(CommunicationPreferences.self, from: preferences) else {
                return
            }
            
            // Respect user's absence response preference
            switch commPrefs.absenceResponse {
            case "give_me_space":
                AppLogger.info("User prefers space, skipping re-engagement", category: .general)
                return
            case "light_nudge", "check_in_on_me":
                break
            default:
                break
            }
            
            // Generate personalized message using AI
            let message = try await generateReEngagementMessage(for: user)
            
            // Schedule notification
            try await notificationManager.scheduleNotification(
                identifier: NotificationManager.NotificationIdentifier.lapse(user.daysSinceLastActive),
                title: message.title,
                body: message.body,
                categoryIdentifier: NotificationManager.NotificationCategory.reEngagement,
                userInfo: ["userId": user.id.uuidString, "type": "reengagement"],
                trigger: UNTimeIntervalNotificationTrigger(
                    timeInterval: 1,
                    repeats: false
                )
            )
            
            // Track re-engagement attempt
            user.reEngagementAttempts += 1
            try modelContext.save()
            
        } catch {
            AppLogger.error("Failed to send re-engagement notification", error: error, category: .general)
        }
    }
    
    private func generateReEngagementMessage(for user: User) async throws -> (title: String, body: String) {
        let context = ReEngagementContext(
            userName: user.name ?? "there",
            daysSinceLastActive: user.daysSinceLastActive,
            primaryGoal: nil, // TODO: Extract from persona or conversation data
            previousEngagementAttempts: user.reEngagementAttempts,
            lastWorkoutType: user.workouts.last?.workoutType,
            personalityTraits: user.onboardingProfile?.persona
        )
        
        let message = try await coachEngine.generateReEngagementMessage(context)
        
        // Parse AI response
        let components = message.split(separator: "|", maxSplits: 1)
        let title = String(components.first ?? "We miss you!")
        let body = String(components.last ?? "Your coach is waiting to help you get back on track.")
        
        return (title: title, body: body)
    }
    
    // MARK: - Smart Notification Scheduling
    func scheduleSmartNotifications(for user: User) async {
        let preferences = user.notificationPreferences ?? NotificationPreferences()
        
        // Morning greeting
        if preferences.morningGreeting {
            await scheduleMorningGreeting(for: user, time: preferences.morningTime)
        }
        
        // Workout reminders
        if preferences.workoutReminders {
            await scheduleWorkoutReminders(for: user, schedule: preferences.workoutSchedule)
        }
        
        // Meal reminders
        if preferences.mealReminders {
            await scheduleMealReminders(for: user)
        }
        
        // Hydration reminders
        if preferences.hydrationReminders {
            await scheduleHydrationReminders(frequency: preferences.hydrationFrequency)
        }
    }
    
    private func scheduleMorningGreeting(for user: User, time: Date) async {
        do {
            // Generate personalized greeting
            let greeting = try await coachEngine.generateMorningGreeting(for: user)
            
            // Create daily trigger
            let dateComponents = Calendar.current.dateComponents(
                [.hour, .minute],
                from: time
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            try await notificationManager.scheduleNotification(
                identifier: NotificationManager.NotificationIdentifier.morning,
                title: "Good morning, \(user.name ?? "there")! ☀️",
                body: greeting,
                categoryIdentifier: NotificationManager.NotificationCategory.dailyCheck,
                userInfo: ["type": "morning"],
                trigger: trigger
            )
            
        } catch {
            AppLogger.error("Failed to schedule morning greeting", error: error, category: .general)
        }
    }
    
    private func scheduleWorkoutReminders(for user: User, schedule: [WorkoutSchedule]) async {
        for workout in schedule {
            do {
                let content = try await coachEngine.generateWorkoutReminder(
                    workoutType: workout.type,
                    userName: user.name ?? "there"
                )
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: workout.dateComponents,
                    repeats: true
                )
                
                try await notificationManager.scheduleNotification(
                    identifier: NotificationManager.NotificationIdentifier.workout(workout.scheduledDate),
                    title: content.title,
                    body: content.body,
                    categoryIdentifier: NotificationManager.NotificationCategory.workout,
                    userInfo: ["type": "workout", "workoutType": workout.type],
                    trigger: trigger
                )
            } catch {
                AppLogger.error("Failed to schedule workout reminder", error: error, category: .general)
            }
        }
    }
    
    private func scheduleMealReminders(for user: User) async {
        let mealTimes = [
            (MealType.breakfast, DateComponents(hour: 8, minute: 0)),
            (MealType.lunch, DateComponents(hour: 12, minute: 30)),
            (MealType.dinner, DateComponents(hour: 18, minute: 30)),
            (MealType.snack, DateComponents(hour: 15, minute: 0))
        ]
        
        for (mealType, dateComponents) in mealTimes {
            do {
                let content = try await coachEngine.generateMealReminder(
                    mealType: mealType,
                    userName: user.name ?? "there"
                )
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: true
                )
                
                try await notificationManager.scheduleNotification(
                    identifier: NotificationManager.NotificationIdentifier.meal(mealType),
                    title: content.title,
                    body: content.body,
                    categoryIdentifier: NotificationManager.NotificationCategory.meal,
                    userInfo: ["type": "meal", "mealType": mealType.rawValue],
                    trigger: trigger
                )
            } catch {
                AppLogger.error("Failed to schedule meal reminder", error: error, category: .general)
            }
        }
    }
    
    private func scheduleHydrationReminders(frequency: HydrationFrequency) async {
        let interval: TimeInterval
        switch frequency {
        case .hourly:
            interval = 60 * 60
        case .biHourly:
            interval = 2 * 60 * 60
        case .triDaily:
            interval = 8 * 60 * 60
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: true
        )
        
        do {
            try await notificationManager.scheduleNotification(
                identifier: NotificationManager.NotificationIdentifier.hydration,
                title: "💧 Hydration Time!",
                body: "Time for a water break. Stay hydrated!",
                categoryIdentifier: NotificationManager.NotificationCategory.hydration,
                userInfo: ["type": "hydration"],
                trigger: trigger
            )
        } catch {
            AppLogger.error("Failed to schedule hydration reminder", error: error, category: .general)
        }
    }
    
    // MARK: - Helper Methods
    private func calculateAverageSessionsPerWeek(_ users: [User]) -> Double {
        // Implementation would analyze DailyLog entries
        return 4.2 // Placeholder
    }
    
    private func calculateAverageSessionDuration(_ users: [User]) -> TimeInterval {
        // Implementation would analyze session data
        return 15 * 60 // 15 minutes placeholder
    }
    
    private func updateEngagementStrategies(based metrics: EngagementMetrics) async {
        // Analyze metrics and adjust notification strategies
        if metrics.engagementRate < 0.5 {
            // Increase engagement efforts
            AppLogger.info("Low engagement detected: \(metrics.engagementRate)", category: .general)
        }
    }
    
    // MARK: - Update Last Active
    func updateUserActivity(for user: User) {
        user.lastActiveAt = Date()
        do {
            try modelContext.save()
        } catch {
            AppLogger.error("Failed to update user activity", error: error, category: .data)
        }
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        registerBackgroundTasks()
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        do {
            let metrics = try await analyzeEngagementMetrics()
            
            return ServiceHealth(
                status: metrics.engagementRate > 0.3 ? .healthy : .degraded,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: nil,
                metadata: [
                    "totalUsers": "\(metrics.totalUsers)",
                    "activeUsers": "\(metrics.activeUsers)",
                    "engagementRate": String(format: "%.2f%%", metrics.engagementRate * 100),
                    "backgroundTasksRegistered": "true"
                ]
            )
        } catch {
            return ServiceHealth(
                status: .unhealthy,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: error.localizedDescription,
                metadata: [:]
            )
        }
    }
}

// MARK: - User Extensions
extension User {
    var daysSinceLastActive: Int {
        Calendar.current.dateComponents(
            [.day],
            from: lastActiveAt,
            to: Date()
        ).day ?? 0
    }
    
    var reEngagementAttempts: Int {
        get { 0 } // Placeholder - would need to add this property to User model
        set { _ = newValue } // Placeholder
    }
    
    // notificationPreferences is defined in UserSettingsExtensions.swift
}

// MARK: - CoachEngine Extensions
extension CoachEngine {
    func generateReEngagementMessage(_ context: ReEngagementContext) async throws -> String {
        // Placeholder - would call AI service
        return "Hey \(context.userName)!|We've missed you! Ready to get back on track?"
    }
    
    func generateMorningGreeting(for user: User) async throws -> String {
        // Placeholder - would call AI service
        return "Ready to make today amazing? Let's start with a quick check-in!"
    }
    
    func generateWorkoutReminder(workoutType: String, userName: String) async throws -> (title: String, body: String) {
        // Placeholder - would call AI service
        return (
            title: "Time for your \(workoutType)!",
            body: "Let's get moving, \(userName)! Your body will thank you."
        )
    }
    
    func generateMealReminder(mealType: MealType, userName: String) async throws -> (title: String, body: String) {
        // Placeholder - would call AI service
        return (
            title: "\(mealType.emoji) \(mealType.displayName) time!",
            body: "Don't forget to log your meal, \(userName)!"
        )
    }
}
