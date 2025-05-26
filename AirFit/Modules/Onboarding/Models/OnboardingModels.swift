import Foundation

// MARK: - Navigation
enum OnboardingScreen: String, CaseIterable, Sendable {
    case openingScreen = "opening"
    case lifeSnapshot = "lifeSnapshot"
    case coreAspiration = "coreAspiration"
    case coachingStyle = "coachingStyle"
    case engagementPreferences = "engagement"
    case typicalAvailability = "availability"
    case sleepAndBoundaries = "sleep"
    case motivationAndCheckins = "motivation"
    case generatingCoach = "generating"
    case coachProfileReady = "ready"

    var title: String {
        switch self {
        case .openingScreen: return ""
        case .lifeSnapshot: return "Life Snapshot"
        case .coreAspiration: return "Core Aspiration"
        case .coachingStyle: return "Coaching Style"
        case .engagementPreferences: return "Engagement"
        case .typicalAvailability: return "Availability"
        case .sleepAndBoundaries: return "Sleep & Recovery"
        case .motivationAndCheckins: return "Motivation"
        case .generatingCoach: return "Creating Your Coach"
        case .coachProfileReady: return "Coach Ready"
        }
    }

    var progress: Double {
        guard let index = Self.allCases.firstIndex(of: self) else { return 0 }
        return Double(index) / Double(Self.allCases.count - 2)
    }
}

// MARK: - Life Snapshot
struct LifeSnapshotSelections: Codable, Sendable {
    var busyProfessional = false
    var parentCaregiver = false
    var student = false
    var shiftWorker = false
    var travelFrequently = false
    var workFromHome = false
    var recovering = false
    var newToFitness = false

    var selectedItems: [String] {
        var items: [String] = []
        if busyProfessional { items.append("Busy Professional") }
        if parentCaregiver { items.append("Parent/Caregiver") }
        if student { items.append("Student") }
        if shiftWorker { items.append("Shift Worker") }
        if travelFrequently { items.append("Travel Frequently") }
        if workFromHome { items.append("Work From Home") }
        if recovering { items.append("Recovering from Injury/Illness") }
        if newToFitness { items.append("New to Fitness") }
        return items
    }
}

// MARK: - Core Aspiration
struct StructuredGoal: Codable, Sendable {
    let goalType: String
    let primaryMetric: String
    let timeframe: String?
    let specificTarget: String?
    let whyImportant: String?
}

// MARK: - Coaching Style
struct CoachingStylePreferences: Codable, Sendable {
    var authoritativeDirect: Double = 0.25
    var empatheticEncouraging: Double = 0.25
    var analyticalPrecise: Double = 0.25
    var playfulMotivating: Double = 0.25

    var isValid: Bool {
        abs((authoritativeDirect + empatheticEncouraging + analyticalPrecise + playfulMotivating) - 1.0) < 0.01
    }

    mutating func normalize() {
        let total = authoritativeDirect + empatheticEncouraging + analyticalPrecise + playfulMotivating
        guard total > 0 else { return }
        authoritativeDirect /= total
        empatheticEncouraging /= total
        analyticalPrecise /= total
        playfulMotivating /= total
    }
}

// MARK: - Engagement
enum EngagementPreset: String, Codable, CaseIterable, Sendable {
    case dataDrivenPartnership = "data_driven"
    case consistentBalanced = "consistent_balanced"
    case guidanceOnDemand = "guidance_on_demand"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .dataDrivenPartnership: return "Data-Driven Partnership"
        case .consistentBalanced: return "Consistent & Balanced"
        case .guidanceOnDemand: return "Guidance On-Demand"
        case .custom: return "Custom"
        }
    }
}

struct CustomEngagementSettings: Codable, Sendable {
    var detailedTracking = false
    var dailyInsights = false
    var autoRecoveryAdjust = false
}

// MARK: - Availability
struct WorkoutAvailabilityBlock: Codable, Identifiable, Sendable {
    let id = UUID()
    var dayOfWeek: Int
    var startTime: Date
    var endTime: Date

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let date = Calendar.current.date(from: DateComponents(weekday: dayOfWeek))!
        return formatter.string(from: date)
    }
}

// MARK: - Sleep
enum SleepRhythmType: String, Codable, CaseIterable, Sendable {
    case consistent = "consistent"
    case weekendsDifferent = "weekends_different"
    case highlyVariable = "highly_variable"

    var displayName: String {
        switch self {
        case .consistent: return "Consistent"
        case .weekendsDifferent: return "Weekends Different"
        case .highlyVariable: return "Highly Variable"
        }
    }
}

struct SleepSchedule: Codable, Sendable {
    let bedtime: Date
    let wakeTime: Date
    let rhythm: SleepRhythmType
}

// MARK: - Motivation
enum AchievementStyle: String, Codable, CaseIterable, Sendable {
    case enthusiasticCelebration = "enthusiastic"
    case subtleAffirming = "subtle"
    case dataFocused = "data_focused"
    case privateReflection = "private"

    var displayName: String {
        switch self {
        case .enthusiasticCelebration: return "Enthusiastic Celebration"
        case .subtleAffirming: return "Subtle & Affirming"
        case .dataFocused: return "Data-Focused"
        case .privateReflection: return "Private Reflection"
        }
    }
}

enum InactivityResponseStyle: String, Codable, CaseIterable, Sendable {
    case motivationalPush = "motivational"
    case gentleNudge = "gentle"
    case factualReminder = "factual"
    case waitForMe = "wait"

    var displayName: String {
        switch self {
        case .motivationalPush: return "Motivational Push"
        case .gentleNudge: return "Gentle Nudge"
        case .factualReminder: return "Factual Reminder"
        case .waitForMe: return "Wait for Me"
        }
    }
}

struct MotivationStyle: Codable, Sendable {
    let achievementStyle: AchievementStyle
    let inactivityStyle: InactivityResponseStyle
}

// MARK: - Complete Profile
struct PersonaProfile: Codable, Sendable {
    let lifeContext: LifeSnapshotSelections
    let coreAspiration: String
    let structuredGoal: StructuredGoal?
    let coachingStyle: CoachingStylePreferences
    let engagementPreference: EngagementPreset
    let customEngagement: CustomEngagementSettings
    let availability: [WorkoutAvailabilityBlock]
    let sleepSchedule: SleepSchedule
    let motivationStyle: MotivationStyle
    let establishBaseline: Bool
}
