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
        // Store units in User model (as String)
        user.preferredUnits = preferences.preferredUnits == .metric ? "metric" : "imperial"
        
        // Store other preferences in UserDefaults since User model doesn't have these properties
        UserDefaults.standard.set(preferences.appearanceMode.rawValue, forKey: "appearanceMode")
        UserDefaults.standard.set(preferences.hapticFeedback, forKey: "hapticFeedback")
        UserDefaults.standard.set(preferences.analyticsEnabled, forKey: "analyticsEnabled")
        
        try context.save()
    }
    
    func getUserPreferences(for user: User) throws -> UserPreferences {
        return UserPreferences(
            preferredUnits: user.preferredUnits == "metric" ? .metric : .imperial,
            appearanceMode: AppearanceMode(rawValue: UserDefaults.standard.string(forKey: "appearanceMode") ?? "system") ?? .system,
            hapticFeedback: UserDefaults.standard.bool(forKey: "hapticFeedback"),
            analyticsEnabled: UserDefaults.standard.bool(forKey: "analyticsEnabled")
        )
    }
    
    // MARK: - AI Configuration
    
    func updateAIConfiguration(_ user: User, configuration: AIConfiguration) throws {
        // Store AI configuration in UserDefaults since User model doesn't have these properties
        UserDefaults.standard.set(configuration.selectedProvider.rawValue, forKey: "selectedProvider")
        UserDefaults.standard.set(configuration.selectedModel, forKey: "selectedModel")
        UserDefaults.standard.set(configuration.isDemoModeEnabled, forKey: "isDemoModeEnabled")
        // No need to save context as nothing changed in User model
    }
    
    func getAIConfiguration(for user: User) throws -> AIConfiguration {
        return AIConfiguration(
            selectedProvider: AIProvider(rawValue: UserDefaults.standard.string(forKey: "selectedProvider") ?? "openAI") ?? .openAI,
            selectedModel: UserDefaults.standard.string(forKey: "selectedModel") ?? "gpt-4",
            availableProviders: [], // This would be populated by the service layer
            installedAPIKeys: [], // This would be populated by the service layer
            isDemoModeEnabled: UserDefaults.standard.bool(forKey: "isDemoModeEnabled")
        )
    }
    
    // MARK: - Notification Preferences
    
    func updateNotificationPreferences(_ user: User, preferences: NotificationPreferences) throws {
        // Store notification preferences in UserDefaults since User model doesn't have this property
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "notificationPreferences")
        }
        // No need to save context as nothing changed in User model
    }
    
    func getNotificationPreferences(for user: User) throws -> NotificationPreferences {
        if let data = UserDefaults.standard.data(forKey: "notificationPreferences"),
           let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            return preferences
        }
        // Return default preferences if none stored
        return NotificationPreferences()
    }
    
    // MARK: - Coach Persona
    
    func updateCoachPersona(_ user: User, persona: CoachPersona) throws {
        // Store coach persona as encoded data in UserDefaults
        if let encoded = try? JSONEncoder().encode(persona) {
            UserDefaults.standard.set(encoded, forKey: "coachPersona")
        }
        // No need to save context as nothing changed in User model
    }
    
    func getCoachPersona(for user: User) throws -> CoachPersona? {
        if let data = UserDefaults.standard.data(forKey: "coachPersona"),
           let persona = try? JSONDecoder().decode(CoachPersona.self, from: data) {
            return persona
        }
        return nil
    }
    
    func updatePersonaEvolution(_ user: User, evolution: PersonaEvolutionTracker) throws {
        // TODO: PersonaEvolutionTracker needs to conform to Codable to be stored
        // For now, just track the adaptation level
        UserDefaults.standard.set(evolution.adaptationLevel, forKey: "personaEvolutionLevel")
        UserDefaults.standard.set(evolution.lastUpdateDate, forKey: "personaEvolutionDate")
    }
    
    // MARK: - Data Management
    
    func clearUserData(_ user: User) throws {
        // Clear all user-related data but keep the user record
        user.foodEntries.removeAll()
        // WORKOUT TRACKING REMOVED - workouts removed from User model
        // user.workouts.removeAll()
        user.dailyLogs.removeAll()
        user.chatSessions.removeAll()
        try context.save()
    }
    
    func exportUserData(_ user: User) throws -> UserDataExportPackage {
        // This would need to be implemented based on the specific export format needed
        // For now, return a placeholder
        return UserDataExportPackage(
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