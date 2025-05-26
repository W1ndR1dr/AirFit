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
struct CommunicationPreferences: Codable, Sendable {
    let coachingStyleBlend: CoachingStylePreferences
    let achievementAcknowledgement: AchievementStyle
    let inactivityResponse: InactivityResponseStyle
    let preferredCheckInTimes: [Date]?
    let quietHoursEnabled: Bool
    let quietHoursStart: Date?
    let quietHoursEnd: Date?
}
