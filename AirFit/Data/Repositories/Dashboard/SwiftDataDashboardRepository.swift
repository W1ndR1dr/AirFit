import Foundation
import SwiftData

@MainActor
final class SwiftDataDashboardRepository: DashboardRepositoryProtocol {
    private let context: ModelContext
    
    init(modelContext: ModelContext) {
        self.context = modelContext
    }
    
    // MARK: - Energy Logging
    
    func logEnergyLevel(_ level: Int, for user: User) throws -> DailyLog {
        // Get or create today's log
        let today = Calendar.current.startOfDay(for: Date())
        var descriptor = FetchDescriptor<DailyLog>()
        descriptor.predicate = #Predicate { log in
            log.date == today
        }
        
        let logs = try context.fetch(descriptor)
        let dailyLog: DailyLog
        
        if let existingLog = logs.first {
            dailyLog = existingLog
        } else {
            dailyLog = DailyLog(date: today, user: user)
            context.insert(dailyLog)
        }
        
        // Update energy level
        dailyLog.subjectiveEnergyLevel = level
        dailyLog.checkedIn = true
        try context.save()
        
        return dailyLog
    }
    
    func getCurrentEnergyLevel(for user: User) throws -> Int? {
        let today = Calendar.current.startOfDay(for: Date())
        var descriptor = FetchDescriptor<DailyLog>()
        descriptor.predicate = #Predicate { log in
            log.date == today
        }
        
        let logs = try context.fetch(descriptor)
        return logs.first?.subjectiveEnergyLevel
    }
    
    // MARK: - Dashboard Preferences
    
    func saveDashboardPreferences(_ preferences: [String: Any], for user: User) throws {
        // For now, we'll store preferences as part of the user model
        // In the future, this could be extended to a separate DashboardPreferences entity
        // user.dashboardPreferences = preferences
        // try context.save()
        
        // Currently not implemented as User model doesn't have preferences field
        // This method exists for future extensibility
    }
    
    func getDashboardPreferences(for user: User) throws -> [String: Any] {
        // Return empty preferences for now
        // In the future: return user.dashboardPreferences ?? [:]
        return [:]
    }
}