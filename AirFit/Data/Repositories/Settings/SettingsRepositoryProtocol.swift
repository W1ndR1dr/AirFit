import Foundation

@MainActor
protocol SettingsRepositoryProtocol: Sendable {
    // MARK: - User Preference Operations
    func updateUserPreferences(_ user: User, preferences: UserPreferences) throws
    func getUserPreferences(for user: User) throws -> UserPreferences
    
    // MARK: - AI Configuration
    func updateAIConfiguration(_ user: User, configuration: AIConfiguration) throws
    func getAIConfiguration(for user: User) throws -> AIConfiguration
    
    // MARK: - Notification Preferences
    func updateNotificationPreferences(_ user: User, preferences: NotificationPreferences) throws
    func getNotificationPreferences(for user: User) throws -> NotificationPreferences
    
    // MARK: - Coach Persona
    func updateCoachPersona(_ user: User, persona: CoachPersona) throws
    func getCoachPersona(for user: User) throws -> CoachPersona?
    func updatePersonaEvolution(_ user: User, evolution: PersonaEvolutionTracker) throws
    
    // MARK: - Data Management
    func clearUserData(_ user: User) throws
    func exportUserData(_ user: User) throws -> UserDataExportPackage
    
    // MARK: - User Management
    func save(_ user: User) throws
    func deleteUser(_ user: User) throws
    func getAllUsers() throws -> [User]
}

// Supporting types for settings operations
struct UserPreferences: Sendable {
    let preferredUnits: MeasurementSystem
    let appearanceMode: AppearanceMode
    let hapticFeedback: Bool
    let analyticsEnabled: Bool
}

struct AIConfiguration: Sendable {
    let selectedProvider: AIProvider
    let selectedModel: String
    let availableProviders: [AIProvider]
    let installedAPIKeys: Set<AIProvider>
    let isDemoModeEnabled: Bool
}

struct UserDataExportPackage: Sendable {
    let userData: Data
    let exportDate: Date
    let format: String
}