import Foundation
import SwiftData

/// Represents a user's trackable goal with progress tracking
@Model
final class TrackedGoal {
    // MARK: - Properties
    
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var title: String
    var goalDescription: String?
    var type: TrackedGoalType
    var category: TrackedGoalCategory
    var status: TrackedGoalStatus
    var priority: TrackedGoalPriority
    
    // Target and Progress
    var targetValue: String?
    var targetUnit: String?
    var currentProgress: Double
    var progressUnit: String?
    
    // Dates
    var createdDate: Date
    var deadline: Date?
    var completedDate: Date?
    var lastProgressUpdate: Date?
    var lastModifiedDate: Date
    
    // Milestones and Metadata
    var milestones: [TrackedGoalMilestone]
    var reminderSettings: ReminderSettings?
    var metadata: [String: String]
    
    // MARK: - Initialization
    
    init(
        userId: UUID,
        title: String,
        type: TrackedGoalType,
        category: TrackedGoalCategory,
        priority: TrackedGoalPriority = .medium,
        targetValue: String? = nil,
        targetUnit: String? = nil,
        deadline: Date? = nil,
        description: String? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.title = title
        self.type = type
        self.category = category
        self.status = .active
        self.priority = priority
        self.targetValue = targetValue
        self.targetUnit = targetUnit
        self.currentProgress = 0
        self.deadline = deadline
        self.goalDescription = description
        self.createdDate = Date()
        self.lastModifiedDate = Date()
        self.milestones = []
        self.metadata = [:]
    }
    
    // MARK: - Computed Properties
    
    /// Progress as a percentage (0-100)
    var progressPercentage: Double {
        guard let targetNumeric = targetValueNumeric, targetNumeric > 0 else {
            return 0
        }
        return min((currentProgress / targetNumeric) * 100, 100)
    }
    
    /// Target value as a numeric value (if applicable)
    var targetValueNumeric: Double? {
        guard let targetValue = targetValue else { return nil }
        return Double(targetValue)
    }
    
    /// Days remaining until deadline
    var daysRemaining: Int? {
        guard let deadline = deadline else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        return max(0, days)
    }
    
    /// Total days from creation to deadline
    var totalDays: Int? {
        guard let deadline = deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: createdDate, to: deadline).day
    }
    
    /// Whether the goal is on track based on time elapsed and progress
    var isOnTrack: Bool {
        guard let totalDays = totalDays,
              let daysRemaining = daysRemaining,
              totalDays > 0 else {
            return true // No deadline means always on track
        }
        
        let timeElapsedPercentage = Double(totalDays - daysRemaining) / Double(totalDays) * 100
        
        // Allow 10% buffer
        return progressPercentage >= (timeElapsedPercentage * 0.9)
    }
}

// MARK: - Supporting Types

enum TrackedGoalType: String, Codable, CaseIterable {
    case weight = "weight"
    case performance = "performance"
    case habit = "habit"
    case nutrition = "nutrition"
    case endurance = "endurance"
    case strength = "strength"
    case flexibility = "flexibility"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .weight: return "Weight"
        case .performance: return "Performance"
        case .habit: return "Habit"
        case .nutrition: return "Nutrition"
        case .endurance: return "Endurance"
        case .strength: return "Strength"
        case .flexibility: return "Flexibility"
        case .custom: return "Custom"
        }
    }
}

enum TrackedGoalCategory: String, Codable, CaseIterable {
    case fitness = "fitness"
    case nutrition = "nutrition"
    case wellness = "wellness"
    case mindfulness = "mindfulness"
    case recovery = "recovery"
    
    var displayName: String {
        switch self {
        case .fitness: return "Fitness"
        case .nutrition: return "Nutrition"
        case .wellness: return "Wellness"
        case .mindfulness: return "Mindfulness"
        case .recovery: return "Recovery"
        }
    }
}

enum TrackedGoalStatus: String, Codable {
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case abandoned = "abandoned"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .abandoned: return "Abandoned"
        }
    }
}

enum TrackedGoalPriority: String, Codable, Comparable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
    
    static func < (lhs: TrackedGoalPriority, rhs: TrackedGoalPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

/// Represents a milestone within a goal
struct TrackedGoalMilestone: Codable {
    let id: UUID
    let title: String
    let targetValue: Double?
    let achievedDate: Date?
    let notes: String?
    
    init(
        title: String,
        targetValue: Double? = nil,
        achievedDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.targetValue = targetValue
        self.achievedDate = achievedDate
        self.notes = notes
    }
}

/// Reminder settings for a goal
struct ReminderSettings: Codable {
    let enabled: Bool
    let frequency: ReminderFrequency
    let time: Date?
    let daysOfWeek: [Int]? // 1-7, Sunday = 1
    
    enum ReminderFrequency: String, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case biweekly = "biweekly"
        case monthly = "monthly"
        case custom = "custom"
    }
}