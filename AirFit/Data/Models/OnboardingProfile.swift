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
}
