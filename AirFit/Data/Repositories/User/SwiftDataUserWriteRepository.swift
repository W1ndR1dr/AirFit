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
        let user = User(email: email, name: name)
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
        user.isOnboarded = completed
        if completed {
            user.onboardingCompletedDate = Date()
        }
        try context.save()
    }
    
    func updateLastActiveDate(_ user: User, date: Date) throws {
        user.lastActiveDate = date
        try context.save()
    }
    
    // MARK: - User Preferences
    
    func updatePreferences(_ user: User, preferences: UserPreferences) throws {
        // Store units in User model (as String)
        user.preferredUnits = preferences.preferredUnits == .metric ? "metric" : "imperial"
        
        // Store other preferences in UserDefaults since User model doesn't have these properties
        UserDefaults.standard.set(preferences.appearanceMode.rawValue, forKey: "appearanceMode")
        UserDefaults.standard.set(preferences.hapticFeedback, forKey: "hapticFeedback")
        UserDefaults.standard.set(preferences.analyticsEnabled, forKey: "analyticsEnabled")
        
        try context.save()
    }
    
    func updateAISettings(_ user: User, provider: AIProvider, model: String) throws {
        // Store AI settings in UserDefaults since User model doesn't have these properties
        UserDefaults.standard.set(provider.rawValue, forKey: "selectedProvider")
        UserDefaults.standard.set(model, forKey: "selectedModel")
        try context.save()
    }
    
    func updateNotificationSettings(_ user: User, preferences: NotificationPreferences) throws {
        // Store notification preferences in UserDefaults since User model doesn't have this property
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "notificationPreferences")
        }
        // No need to save context as nothing changed in User model
    }
    
    // MARK: - User Data Management
    
    func clearUserData(_ user: User, preserveProfile: Bool) throws {
        // Clear all user-related data
        user.foodEntries.removeAll()
        // WORKOUT TRACKING REMOVED - workouts removed from User model
        // user.workouts.removeAll()
        user.dailyLogs.removeAll()
        user.chatSessions.removeAll()
        
        if !preserveProfile {
            // Reset preferences to defaults but keep the user record
            user.isOnboarded = false
            user.onboardingCompletedDate = nil
            // Clear coach persona from UserDefaults
            UserDefaults.standard.removeObject(forKey: "coachPersona")
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
        
        // Store active user ID in UserDefaults since User model doesn't have isActive property
        UserDefaults.standard.set(user.id.uuidString, forKey: "activeUserId")
        
        // Update last active date
        user.lastActiveAt = Date()
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