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

    // Additional properties for UserService
    var name: String?
    var email: String?
    var isComplete: Bool = false
    var birthDate: Date?
    var biologicalSex: String?

    // Persona data (stored as JSON)
    var personaData: Data?

    // MARK: - Relationships
    var user: User?

    // MARK: - Computed Properties
    var persona: PersonaProfile? {
        get {
            guard let data = personaData else { return nil }
            return try? JSONDecoder().decode(PersonaProfile.self, from: data)
        }
        set {
            if let newValue = newValue {
                personaData = try? JSONEncoder().encode(newValue)
            } else {
                personaData = nil
            }
        }
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
}
