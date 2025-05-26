import SwiftData
import Foundation

@Model
final class DailyLog: Sendable {
    // MARK: - Properties
    @Attribute(.unique) var date: Date
    var subjectiveEnergyLevel: Int? // 1-5
    var sleepQuality: Int? // 1-5
    var stressLevel: Int? // 1-5
    var mood: String?
    var weight: Double? // kg
    var bodyFat: Double? // percentage
    var notes: String?
    var checkedIn: Bool = false
    
    // Activity Metrics
    var steps: Int?
    var activeCalories: Double?
    var exerciseMinutes: Int?
    var standHours: Int?
    
    // MARK: - Relationships
    var user: User?
    
    // MARK: - Computed Properties
    var overallWellness: Double? {
        let metrics = [subjectiveEnergyLevel, sleepQuality].compactMap { $0 }
        guard !metrics.isEmpty else { return nil }
        
        let stressAdjusted = stressLevel.map { 6 - $0 } // Invert stress (lower is better)
        let allMetrics = metrics + [stressAdjusted].compactMap { $0 }
        
        return Double(allMetrics.reduce(0, +)) / Double(allMetrics.count)
    }
    
    var hasHealthMetrics: Bool {
        steps != nil || activeCalories != nil || exerciseMinutes != nil
    }
    
    var hasSubjectiveMetrics: Bool {
        subjectiveEnergyLevel != nil || sleepQuality != nil || stressLevel != nil
    }
    
    // MARK: - Initialization
    init(
        date: Date = Date(),
        user: User? = nil
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.user = user
    }
    
    // MARK: - Methods
    func updateHealthMetrics(
        steps: Int? = nil,
        activeCalories: Double? = nil,
        exerciseMinutes: Int? = nil,
        standHours: Int? = nil
    ) {
        if let steps = steps { self.steps = steps }
        if let calories = activeCalories { self.activeCalories = calories }
        if let minutes = exerciseMinutes { self.exerciseMinutes = minutes }
        if let hours = standHours { self.standHours = hours }
    }
    
    func checkIn(
        energy: Int? = nil,
        sleep: Int? = nil,
        stress: Int? = nil,
        mood: String? = nil
    ) {
        self.subjectiveEnergyLevel = energy
        self.sleepQuality = sleep
        self.stressLevel = stress
        self.mood = mood
        self.checkedIn = true
    }
}
