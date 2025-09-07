import Foundation

@MainActor
protocol UserWriteRepositoryProtocol: Sendable {
    // MARK: - User Operations
    func create(name: String, email: String?) throws -> User
    func save(_ user: User) throws
    func delete(_ user: User) throws
    
    // MARK: - User Profile
    func updateProfile(_ user: User, name: String, email: String?) throws
    func updateOnboardingStatus(_ user: User, completed: Bool) throws
    func updateLastActiveDate(_ user: User, date: Date) throws
    
    // MARK: - User Preferences
    func updatePreferences(_ user: User, preferences: UserPreferences) throws
    func updateAISettings(_ user: User, provider: AIProvider, model: String) throws
    func updateNotificationSettings(_ user: User, preferences: NotificationPreferences) throws
    
    // MARK: - User Data Management
    func clearUserData(_ user: User, preserveProfile: Bool) throws
    func deleteAllUsers() throws
    func setActiveUser(_ user: User) throws
    
    // MARK: - Bulk Operations  
    func saveUsers(_ users: [User]) throws
}