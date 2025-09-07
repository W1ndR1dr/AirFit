import Foundation
import SwiftData

@MainActor
final class SwiftDataSettingsRepository: SettingsRepositoryProtocol {
    private let context: ModelContext
    
    init(modelContext: ModelContext) {
        self.context = modelContext
    }
    
    // MARK: - User Preference Operations
    
    func updateUserPreferences(_ user: User, preferences: UserPreferences) throws {
        user.preferredUnits = preferences.preferredUnits
        user.appearanceMode = preferences.appearanceMode
        user.hapticFeedback = preferences.hapticFeedback
        user.analyticsEnabled = preferences.analyticsEnabled
        try context.save()
    }
    
    func getUserPreferences(for user: User) throws -> UserPreferences {
        return UserPreferences(
            preferredUnits: user.preferredUnits,
            appearanceMode: user.appearanceMode,
            hapticFeedback: user.hapticFeedback,
            analyticsEnabled: user.analyticsEnabled
        )
    }
    
    // MARK: - AI Configuration
    
    func updateAIConfiguration(_ user: User, configuration: AIConfiguration) throws {
        user.selectedProvider = configuration.selectedProvider
        user.selectedModel = configuration.selectedModel
        user.isDemoModeEnabled = configuration.isDemoModeEnabled
        try context.save()
    }
    
    func getAIConfiguration(for user: User) throws -> AIConfiguration {
        return AIConfiguration(
            selectedProvider: user.selectedProvider,
            selectedModel: user.selectedModel,
            availableProviders: [], // This would be populated by the service layer
            installedAPIKeys: [], // This would be populated by the service layer
            isDemoModeEnabled: user.isDemoModeEnabled
        )
    }
    
    // MARK: - Notification Preferences
    
    func updateNotificationPreferences(_ user: User, preferences: NotificationPreferences) throws {
        user.notificationPreferences = preferences
        try context.save()
    }
    
    func getNotificationPreferences(for user: User) throws -> NotificationPreferences {
        return user.notificationPreferences
    }
    
    // MARK: - Coach Persona
    
    func updateCoachPersona(_ user: User, persona: CoachPersona) throws {
        user.coachPersona = persona
        try context.save()
    }
    
    func getCoachPersona(for user: User) throws -> CoachPersona? {
        return user.coachPersona
    }
    
    func updatePersonaEvolution(_ user: User, evolution: PersonaEvolutionTracker) throws {
        user.personaEvolution = evolution
        try context.save()
    }
    
    // MARK: - Data Management
    
    func clearUserData(_ user: User) throws {
        // Clear all user-related data but keep the user record
        user.foodEntries.removeAll()
        user.workouts.removeAll()
        user.dailyLogs.removeAll()
        user.chatSessions.removeAll()
        try context.save()
    }
    
    func exportUserData(_ user: User) throws -> UserDataExport {
        // This would need to be implemented based on the specific export format needed
        // For now, return a placeholder
        return UserDataExport(
            userData: Data(),
            exportDate: Date(),
            format: "json"
        )
    }
    
    // MARK: - User Management
    
    func save(_ user: User) throws {
        try context.save()
    }
    
    func deleteUser(_ user: User) throws {
        context.delete(user)
        try context.save()
    }
    
    func getAllUsers() throws -> [User] {
        let descriptor = FetchDescriptor<User>()
        return try context.fetch(descriptor)
    }
}