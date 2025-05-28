import SwiftData
import Foundation

@Model
final class User: @unchecked Sendable {
    // MARK: - Properties
    @Attribute(.unique)
    var id: UUID
    var createdAt: Date
    var lastActiveAt: Date
    var email: String?
    var name: String?
    var preferredUnits: String // "imperial" or "metric"

    // MARK: - Computed Properties
    var isMetric: Bool {
        preferredUnits == "metric"
    }

    var daysActive: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    var isInactive: Bool {
        let daysSinceActive = Calendar.current.dateComponents([.day], from: lastActiveAt, to: Date()).day ?? 0
        return daysSinceActive > 7
    }

    var activeChats: [ChatSession] {
        chatSessions.filter { $0.isActive }
    }

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \OnboardingProfile.user)
    var onboardingProfile: OnboardingProfile?

    @Relationship(deleteRule: .cascade, inverse: \FoodEntry.user)
    var foodEntries: [FoodEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \Workout.user)
    var workouts: [Workout] = []

    @Relationship(deleteRule: .cascade, inverse: \DailyLog.user)
    var dailyLogs: [DailyLog] = []

    @Relationship(deleteRule: .cascade, inverse: \CoachMessage.user)
    var coachMessages: [CoachMessage] = []

    @Relationship(deleteRule: .cascade, inverse: \HealthKitSyncRecord.user)
    var healthKitSyncRecords: [HealthKitSyncRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \ChatSession.user)
    var chatSessions: [ChatSession] = []

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        email: String? = nil,
        name: String? = nil,
        preferredUnits: String = "imperial"
    ) {
        self.id = id
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.email = email
        self.name = name
        self.preferredUnits = preferredUnits
    }

    // MARK: - Methods
    func updateActivity() {
        lastActiveAt = Date()
    }

    func getTodaysLog() -> DailyLog? {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    func getRecentMeals(days: Int = 7) -> [FoodEntry] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return foodEntries
            .filter { $0.loggedAt > cutoffDate }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    func getRecentWorkouts(days: Int = 7) -> [Workout] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return workouts
            .compactMap { $0.completedDate != nil ? $0 : nil }
            .filter { $0.completedDate! > cutoffDate }
            .sorted { $0.completedDate! > $1.completedDate! }
    }
}
