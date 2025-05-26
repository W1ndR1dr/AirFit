import SwiftData
import Foundation

@Model
final class OnboardingProfile: @unchecked Sendable {
    // MARK: - Properties
    var id: UUID
    var createdAt: Date
    var personaPromptData: Data
    var communicationPreferencesData: Data
    @Attribute(.externalStorage)
    var rawFullProfileData: Data

    // MARK: - Relationships
    var user: User?

    // MARK: - Computed Properties
    var personaProfile: PersonaProfile? {
        try? JSONDecoder().decode(PersonaProfile.self, from: personaPromptData)
    }

    var communicationPreferences: CommunicationPreferences? {
        try? JSONDecoder().decode(CommunicationPreferences.self, from: communicationPreferencesData)
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        personaPromptData: Data,
        communicationPreferencesData: Data,
        rawFullProfileData: Data,
        user: User? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.personaPromptData = personaPromptData
        self.communicationPreferencesData = communicationPreferencesData
        self.rawFullProfileData = rawFullProfileData
        self.user = user
    }

    // MARK: - Convenience Initializer
    init(
        user: User,
        personaProfile: PersonaProfile,
        communicationPreferences: CommunicationPreferences
    ) throws {
        self.id = UUID()
        self.createdAt = Date()
        self.user = user

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        self.personaPromptData = try encoder.encode(personaProfile)
        self.communicationPreferencesData = try encoder.encode(communicationPreferences)
        self.rawFullProfileData = try encoder.encode(personaProfile) // Full profile for v1
    }
}

// MARK: - Supporting Types
struct PersonaProfile: Codable, Sendable {
    let lifeContext: LifeSnapshotSelections
    let coreAspiration: String
    let structuredGoal: StructuredGoal?
    let coachingStyle: CoachingStylePreferences
    let engagementPreference: EngagementPreset
    let customEngagement: CustomEngagementSettings
    let availability: [WorkoutAvailabilityBlock]
    let sleepSchedule: SleepSchedule
    let motivationStyle: MotivationStyle
    let establishBaseline: Bool
}

struct CommunicationPreferences: Codable, Sendable {
    let coachingStyleBlend: CoachingStylePreferences
    let achievementAcknowledgement: AchievementStyle
    let inactivityResponse: InactivityResponseStyle
    let preferredCheckInTimes: [Date]?
    let quietHoursEnabled: Bool
    let quietHoursStart: Date?
    let quietHoursEnd: Date?
}

struct LifeSnapshotSelections: Codable, Sendable {
    let baseDemographics: BaseDemographics
    let currentLifeSituation: CurrentLifeSituation
    let healthContext: HealthContext
    let motivationalFactors: MotivationalFactors
}

struct BaseDemographics: Codable, Sendable {
    let age: Int
    let gender: String
    let height: Double // cm
    let weight: Double // kg
}

struct CurrentLifeSituation: Codable, Sendable {
    let occupation: String
    let workSchedule: String
    let familyStatus: String
    let activityLevel: String
}

struct HealthContext: Codable, Sendable {
    let fitnessLevel: String
    let healthConditions: [String]
    let injuries: [String]
    let medications: [String]
}

struct MotivationalFactors: Codable, Sendable {
    let primaryGoals: [String]
    let challenges: [String]
    let preferences: [String]
}

struct StructuredGoal: Codable, Sendable {
    let type: String
    let target: Double
    let timeframe: Int // days
    let metric: String
}

struct CoachingStylePreferences: Codable, Sendable {
    let firmness: Double // 0-1
    let warmth: Double // 0-1
    let technicalDetail: Double // 0-1
    let dataFocus: Double // 0-1
}

struct EngagementPreset: Codable, Sendable, RawRepresentable {
    static let minimal = EngagementPreset(rawValue: "minimal")
    static let standard = EngagementPreset(rawValue: "standard")
    static let engaged = EngagementPreset(rawValue: "engaged")
    static let intense = EngagementPreset(rawValue: "intense")

    let rawValue: String
}

struct CustomEngagementSettings: Codable, Sendable {
    let weeklyInteractions: Int
    let initiateConversations: Bool
    let adaptiveFrequency: Bool
}

struct WorkoutAvailabilityBlock: Codable, Sendable {
    let dayOfWeek: Int // 1-7
    let startTime: Date
    let endTime: Date
    let preferred: Bool
}

struct SleepSchedule: Codable, Sendable {
    let bedtime: Date
    let wakeTime: Date
}

struct MotivationStyle: Codable, Sendable {
    let competitiveness: Double // 0-1
    let externalValidation: Double // 0-1
    let processOriented: Double // 0-1
    let outcomeOriented: Double // 0-1
}

struct AchievementStyle: Codable, Sendable, RawRepresentable {
    static let celebrate = AchievementStyle(rawValue: "celebrate")
    static let acknowledge = AchievementStyle(rawValue: "acknowledge")
    static let minimal = AchievementStyle(rawValue: "minimal")

    let rawValue: String
}

struct InactivityResponseStyle: Codable, Sendable, RawRepresentable {
    static let gentle = InactivityResponseStyle(rawValue: "gentle")
    static let motivating = InactivityResponseStyle(rawValue: "motivating")
    static let concerned = InactivityResponseStyle(rawValue: "concerned")

    let rawValue: String
}
