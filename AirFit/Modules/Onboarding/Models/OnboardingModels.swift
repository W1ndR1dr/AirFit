import Foundation

// Phase 4 Refactor: Clean v1 implementation with PersonaMode

// MARK: - Navigation (9 screens per OnboardingFlow.md v3.2)
enum OnboardingScreen: String, CaseIterable, Sendable {
    case openingScreen = "opening"
    case lifeSnapshot = "lifeSnapshot"
    case coreAspiration = "coreAspiration"
    case coachingStyle = "coachingStyle"
    case engagementPreferences = "engagement"
    case sleepAndBoundaries = "sleep"
    case motivationalAccents = "motivation"
    case generatingCoach = "generating"
    case coachProfileReady = "ready"

    var title: String {
        switch self {
        case .openingScreen: return ""
        case .lifeSnapshot: return "Life Snapshot"
        case .coreAspiration: return "Your Core Aspiration"
        case .coachingStyle: return "Coaching Style Profile"
        case .engagementPreferences: return "Engagement Preferences"
        case .sleepAndBoundaries: return "Sleep & Notification Boundaries"
        case .motivationalAccents: return "Motivational Accents"
        case .generatingCoach: return "Crafting Your AirFit Coach"
        case .coachProfileReady: return "Your AirFit Coach Profile Is Ready"
        }
    }

    var progress: Double {
        // 7 segments for main steps (excluding opening, generating, ready)
        let mainSteps = Self.allCases.filter {
            $0 != .openingScreen && $0 != .generatingCoach && $0 != .coachProfileReady
        }
        guard let index = mainSteps.firstIndex(of: self) else { return 0 }
        return Double(index) / Double(mainSteps.count - 1)
    }
}

// MARK: - Life Context
struct LifeContext: Codable, Sendable {
    var isDeskJob = false
    var isPhysicallyActiveWork = false
    var travelsFrequently = false
    var hasChildrenOrFamilyCare = false
    var scheduleType: ScheduleType = .predictable
    var workoutWindowPreference: WorkoutWindow = .varies

    enum ScheduleType: String, Codable, CaseIterable, Sendable {
        case predictable = "predictable"
        case unpredictableChaotic = "unpredictable_chaotic"

        var displayName: String {
            switch self {
            case .predictable: return "My schedule is generally predictable"
            case .unpredictableChaotic: return "My schedule is often unpredictable or chaotic"
            }
        }
    }

    enum WorkoutWindow: String, Codable, CaseIterable, Sendable {
        case earlyBird = "early_bird"
        case midDay = "mid_day"
        case nightOwl = "night_owl"
        case varies = "varies"

        var displayName: String {
            switch self {
            case .earlyBird: return "Early Bird (e.g., 5-8 AM)"
            case .midDay: return "Mid-Day (e.g., 11 AM - 2 PM)"
            case .nightOwl: return "Evening / Night Owl (e.g., 6 PM onwards)"
            case .varies: return "It Varies Greatly"
            }
        }
    }
}

// MARK: - Goal
struct Goal: Codable, Sendable {
    var family: GoalFamily = .healthWellbeing
    var rawText: String = ""

    enum GoalFamily: String, Codable, CaseIterable, Sendable {
        case strengthTone = "strength_tone"
        case endurance = "endurance"
        case performance = "performance"
        case healthWellbeing = "health_wellbeing"
        case recoveryRehab = "recovery_rehab"

        var displayName: String {
            switch self {
            case .strengthTone: return "Enhance Strength & Physical Tone"
            case .endurance: return "Improve Cardiovascular Endurance"
            case .performance: return "Optimize Athletic Performance"
            case .healthWellbeing: return "Cultivate Lasting Health & Wellbeing"
            case .recoveryRehab: return "Support Injury Recovery & Pain-Free Movement"
            }
        }
    }
}

// MARK: - Engagement Preferences
struct EngagementPreferences: Codable, Sendable {
    var trackingStyle: TrackingStyle = .dataDrivenPartnership
    var informationDepth: InformationDepth = .keyMetrics
    var updateFrequency: UpdateFrequency = .weekly
    var autoRecoveryLogicPreference = true

    enum TrackingStyle: String, Codable, CaseIterable, Sendable {
        case dataDrivenPartnership = "data_driven_partnership"
        case balancedConsistent = "balanced_consistent"
        case guidanceOnDemand = "guidance_on_demand"
        case custom = "custom"

        var displayName: String {
            switch self {
            case .dataDrivenPartnership: return "Data-Driven Partnership"
            case .balancedConsistent: return "Balanced & Consistent"
            case .guidanceOnDemand: return "Guidance on Demand"
            case .custom: return "Customise My Preferences"
            }
        }

        var description: String {
            switch self {
            case .dataDrivenPartnership: return "Detailed tracking, daily updates, proactive auto-recovery"
            case .balancedConsistent: return "Key metric tracking, weekly updates, proactive auto-recovery"
            case .guidanceOnDemand: return "User-initiated tracking focus, updates when asked, user-decides recovery"
            case .custom: return "Customise individual preferences"
            }
        }
    }

    enum InformationDepth: String, Codable, CaseIterable, Sendable {
        case detailed = "detailed"
        case keyMetrics = "key_metrics"
        case essentialOnly = "essential_only"

        var displayName: String {
            switch self {
            case .detailed: return "Detailed"
            case .keyMetrics: return "Key Metrics"
            case .essentialOnly: return "Essential Only"
            }
        }

        var description: String {
            switch self {
            case .detailed: return "e.g., macro tracking, in-depth analysis"
            case .keyMetrics: return "e.g., calorie balance, core performance indicators"
            case .essentialOnly: return "e.g., workout completion, basic trends"
            }
        }
    }

    enum UpdateFrequency: String, Codable, CaseIterable, Sendable {
        case daily = "daily"
        case weekly = "weekly"
        case onDemand = "on_demand"

        var displayName: String {
            switch self {
            case .daily: return "Daily Insights & Check-ins"
            case .weekly: return "Weekly Summaries & Reviews"
            case .onDemand: return "Primarily When I Ask"
            }
        }
    }
}

// MARK: - Sleep Window
struct SleepWindow: Codable, Sendable {
    var bedTime: String = "22:30"  // "HH:mm" format
    var wakeTime: String = "06:30" // "HH:mm" format
    var consistency: SleepConsistency = .consistent

    enum SleepConsistency: String, Codable, CaseIterable, Sendable {
        case consistent = "consistent"
        case weekSplit = "week_split"
        case variable = "variable"

        var displayName: String {
            switch self {
            case .consistent: return "Consistent"
            case .weekSplit: return "Different on Weekends"
            case .variable: return "Highly Variable"
            }
        }
    }
}

// MARK: - Motivational Style
struct MotivationalStyle: Codable, Sendable {
    var celebrationStyle: CelebrationStyle = .subtleAffirming
    var absenceResponse: AbsenceResponse = .gentleNudge

    enum CelebrationStyle: String, Codable, CaseIterable, Sendable {
        case subtleAffirming = "subtle_affirming"
        case enthusiasticCelebratory = "enthusiastic_celebratory"

        var displayName: String {
            switch self {
            case .subtleAffirming: return "Subtle & Affirming"
            case .enthusiasticCelebratory: return "Enthusiastic & Encouraging"
            }
        }

        var description: String {
            switch self {
            case .subtleAffirming: return "e.g., \"Solid progress.\", \"Noted.\""
            case .enthusiasticCelebratory: return "e.g., \"Fantastic work!\", \"That's a huge win!\""
            }
        }
    }

    enum AbsenceResponse: String, Codable, CaseIterable, Sendable {
        case gentleNudge = "gentle_nudge"
        case respectSpace = "respect_space"

        var displayName: String {
            switch self {
            case .gentleNudge: return "A Gentle Nudge from Your Coach"
            case .respectSpace: return "Coach Respects Your Space"
            }
        }

        var description: String {
            switch self {
            case .gentleNudge: return "e.g., \"Checking in – how are things?\""
            case .respectSpace: return "Waits for you to re-engage unless critical"
            }
        }
    }
}

// MARK: - USER_PROFILE_JSON_BLOB (Phase 4 Refactored)
struct UserProfileJsonBlob: Codable, Sendable {
    let lifeContext: LifeContext
    let goal: Goal
    let personaMode: PersonaMode  // Phase 4: Discrete persona modes
    let engagementPreferences: EngagementPreferences
    let sleepWindow: SleepWindow
    let motivationalStyle: MotivationalStyle
    let timezone: String
    let baselineModeEnabled: Bool
    
    // Legacy support for migration
    let blend: Blend?

    init(
        lifeContext: LifeContext,
        goal: Goal,
        personaMode: PersonaMode,
        engagementPreferences: EngagementPreferences,
        sleepWindow: SleepWindow,
        motivationalStyle: MotivationalStyle,
        timezone: String = TimeZone.current.identifier,
        baselineModeEnabled: Bool = true
    ) {
        self.lifeContext = lifeContext
        self.goal = goal
        self.personaMode = personaMode
        self.engagementPreferences = engagementPreferences
        self.sleepWindow = sleepWindow
        self.motivationalStyle = motivationalStyle
        self.timezone = timezone
        self.baselineModeEnabled = baselineModeEnabled
        self.blend = nil  // New profiles don't need legacy blend
    }
    
    // Legacy initializer for migration support
    init(
        lifeContext: LifeContext,
        goal: Goal,
        blend: Blend,
        engagementPreferences: EngagementPreferences,
        sleepWindow: SleepWindow,
        motivationalStyle: MotivationalStyle,
        timezone: String = TimeZone.current.identifier,
        baselineModeEnabled: Bool = true
    ) {
        self.lifeContext = lifeContext
        self.goal = goal
        self.blend = blend
        self.personaMode = PersonaMigrationUtility.migrateBlendToPersonaMode(blend)
        self.engagementPreferences = engagementPreferences
        self.sleepWindow = sleepWindow
        self.motivationalStyle = motivationalStyle
        self.timezone = timezone
        self.baselineModeEnabled = baselineModeEnabled
    }
}

// MARK: - Blend (Legacy - kept for backward compatibility during migration)
struct Blend: Codable, Sendable {
    var authoritativeDirect: Double = 0.25
    var encouragingEmpathetic: Double = 0.35
    var analyticalInsightful: Double = 0.30
    var playfullyProvocative: Double = 0.10
    
    mutating func normalize() {
        let total = authoritativeDirect + encouragingEmpathetic + analyticalInsightful + playfullyProvocative
        guard total > 0 else { return }
        
        authoritativeDirect /= total
        encouragingEmpathetic /= total
        analyticalInsightful /= total
        playfullyProvocative /= total
    }
}

// MARK: - Migration Support
// PersonaMigrationUtility moved to Core/Utilities/PersonaMigrationUtility.swift
