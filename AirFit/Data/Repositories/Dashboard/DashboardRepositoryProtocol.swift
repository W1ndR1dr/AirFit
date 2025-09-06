import Foundation

@MainActor
protocol DashboardRepositoryProtocol: Sendable {
    // MARK: - Energy Logging
    /// Gets or creates today's DailyLog and updates energy level
    func logEnergyLevel(_ level: Int, for user: User) throws -> DailyLog
    
    /// Fetches current energy level for today
    func getCurrentEnergyLevel(for user: User) throws -> Int?
    
    // MARK: - Dashboard Preferences
    /// Saves dashboard preferences for the user
    func saveDashboardPreferences(_ preferences: [String: Any], for user: User) throws
    
    /// Loads dashboard preferences for the user
    func getDashboardPreferences(for user: User) throws -> [String: Any]
}