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

    // Health baseline data
    var baselineHRV: Double?

    // Biological data for BMR calculation
    var biologicalSex: String? // "male" or "female"
    var birthDate: Date?

    // Personalized macro preferences (from AI or user-adjusted)
    var proteinGramsPerPound: Double = 0.9  // Default, overridden by persona
    var fatPercentage: Double = 0.30         // Default 30%, overridden by persona
    var macroFlexibility: String = "balanced" // "strict", "balanced", "flexible"

    // Muscle group volume targets (sets per week) - AI configurable
    var muscleGroupTargets: [String: Int] = [
        "Chest": 16,
        "Back": 16,
        "Shoulders": 12,
        "Biceps": 10,
        "Triceps": 10,
        "Quads": 12,
        "Hamstrings": 10,
        "Glutes": 10,
        "Calves": 8,
        "Core": 12
    ]

    // Onboarding status
    var isOnboarded: Bool = false
    var onboardingCompletedDate: Date?
    var lastActiveDate: Date = Date()

    // Additional timestamps
    var lastModifiedDate: Date = Date()
    var createdDate: Date = Date()

    // MARK: - Computed Properties
    var isMetric: Bool {
        preferredUnits == "metric"
    }

    var age: Int? {
        guard let birthDate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }

    var nutritionPreferences: NutritionPreferences {
        NutritionPreferences(
            dietaryRestrictions: [],
            allergies: [],
            preferredUnits: preferredUnits,
            calorieGoal: 2_000, // Temporary default until dynamic calculation
            proteinGoal: 150,  // Temporary default until dynamic calculation
            carbGoal: 250,     // Temporary default until dynamic calculation
            fatGoal: 65        // Temporary default until dynamic calculation
        )
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

    @Relationship(deleteRule: .cascade, inverse: \StrengthRecord.user)
    var strengthRecords: [StrengthRecord] = []

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        email: String? = nil,
        name: String? = nil,
        preferredUnits: String = "imperial",
        biologicalSex: String? = nil,
        birthDate: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.email = email
        self.name = name
        self.preferredUnits = preferredUnits
        self.biologicalSex = biologicalSex
        self.birthDate = birthDate
    }

    // MARK: - Methods
    func updateActivity() {
        lastActiveAt = Date()
        lastModifiedDate = Date()
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
            .filter { ($0.completedDate ?? Date.distantPast) > cutoffDate }
            .sorted { ($0.completedDate ?? Date.distantPast) > ($1.completedDate ?? Date.distantPast) }
    }

    func getMuscleGroupTargets() -> [String: Int] {
        return muscleGroupTargets
    }

    // MARK: - Test Support
    #if DEBUG
    static let example = User(
        email: "john@example.com",
        name: "John Doe",
        preferredUnits: "imperial"
    )
    #endif
}
