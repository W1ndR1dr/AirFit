import Foundation
import SwiftData

@MainActor
final class SwiftDataUserWriteRepository: UserWriteRepositoryProtocol {
    private let context: ModelContext
    
    init(modelContext: ModelContext) {
        self.context = modelContext
    }
    
    // MARK: - User Operations
    
    func create(name: String, email: String?) throws -> User {
        let user = User(name: name, email: email)
        context.insert(user)
        try context.save()
        return user
    }
    
    func save(_ user: User) throws {
        try context.save()
    }
    
    func delete(_ user: User) throws {
        context.delete(user)
        try context.save()
    }
    
    // MARK: - User Profile
    
    func updateProfile(_ user: User, name: String, email: String?) throws {
        user.name = name
        user.email = email
        try context.save()
    }
    
    func updateOnboardingStatus(_ user: User, completed: Bool) throws {
        user.hasCompletedOnboarding = completed
        try context.save()
    }
    
    func updateLastActiveDate(_ user: User, date: Date) throws {
        user.lastActiveDate = date
        try context.save()
    }
    
    // MARK: - User Preferences
    
    func updatePreferences(_ user: User, preferences: UserPreferences) throws {
        user.preferredUnits = preferences.preferredUnits
        user.appearanceMode = preferences.appearanceMode
        user.hapticFeedback = preferences.hapticFeedback
        user.analyticsEnabled = preferences.analyticsEnabled
        try context.save()
    }
    
    func updateAISettings(_ user: User, provider: AIProvider, model: String) throws {
        user.selectedProvider = provider
        user.selectedModel = model
        try context.save()
    }
    
    func updateNotificationSettings(_ user: User, preferences: NotificationPreferences) throws {
        user.notificationPreferences = preferences
        try context.save()
    }
    
    // MARK: - User Data Management
    
    func clearUserData(_ user: User, preserveProfile: Bool) throws {
        // Clear all user-related data
        user.foodEntries.removeAll()
        user.workouts.removeAll()
        user.dailyLogs.removeAll()
        user.chatSessions.removeAll()
        
        if !preserveProfile {
            // Reset preferences to defaults but keep the user record
            user.hasCompletedOnboarding = false
            user.coachPersona = nil
        }
        
        try context.save()
    }
    
    func deleteAllUsers() throws {
        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)
        
        for user in users {
            context.delete(user)
        }
        
        try context.save()
    }
    
    func setActiveUser(_ user: User) throws {
        // First, clear any existing active user status
        let descriptor = FetchDescriptor<User>()
        let allUsers = try context.fetch(descriptor)
        
        for existingUser in allUsers {
            existingUser.isActive = false
        }
        
        // Set the new active user
        user.isActive = true
        try context.save()
    }
    
    // MARK: - Bulk Operations
    
    func saveUsers(_ users: [User]) throws {
        for user in users {
            context.insert(user)
        }
        try context.save()
    }
}