import Foundation

// MARK: - Context Quality System (The Core Innovation)

/// The mathematical foundation of coaching quality - determines when we have enough context
struct ContextComponents: Sendable {
    let goalClarity: Double              // 0.25 weight - Without clear goals, we're guessing
    let obstacles: Double                // 0.25 weight - Must work around constraints
    let exercisePreferences: Double      // 0.15 weight - Adherence requires enjoyment
    let currentState: Double             // 0.10 weight - Baseline fitness matters
    let lifestyle: Double                // 0.10 weight - Schedule determines feasibility
    let nutritionReadiness: Double       // 0.05 weight - Nice to have
    let communicationStyle: Double       // 0.05 weight - Helps with tone
    let pastPatterns: Double             // 0.03 weight - Historical context
    let energyPatterns: Double           // 0.01 weight - Minor optimization
    let supportSystem: Double            // 0.01 weight - Minimal direct impact
    
    /// Weighted overall score - must be > 0.8 for quality coaching
    var overall: Double {
        (goalClarity * 0.25) +
        (obstacles * 0.25) +
        (exercisePreferences * 0.15) +
        (currentState * 0.10) +
        (lifestyle * 0.10) +
        (nutritionReadiness * 0.05) +
        (communicationStyle * 0.05) +
        (pastPatterns * 0.03) +
        (energyPatterns * 0.01) +
        (supportSystem * 0.01)
    }
    
    /// Ready to proceed with coaching
    var readyForCoaching: Bool { overall > 0.8 }
    
    /// Components that need improvement (with higher standards)
    var missingCritical: [String] {
        var missing: [String] = []
        if goalClarity < 0.7 { missing.append("specific goals") }
        if obstacles < 0.7 { missing.append("challenges") }
        if exercisePreferences < 0.6 { missing.append("exercise preferences") }
        if currentState < 0.6 { missing.append("current fitness") }
        if lifestyle < 0.6 { missing.append("daily schedule") }
        if nutritionReadiness < 0.5 { missing.append("nutrition approach") }
        if communicationStyle < 0.5 { missing.append("coaching style") }
        if pastPatterns < 0.5 { missing.append("past experience") }
        return missing
    }
    
    /// Which component needs the most work
    var lowestComponent: String {
        let components = [
            ("goals", goalClarity),
            ("obstacles", obstacles),
            ("preferences", exercisePreferences),
            ("fitness level", currentState),
            ("schedule", lifestyle),
            ("nutrition approach", nutritionReadiness),
            ("communication style", communicationStyle)
        ]
        return components.min(by: { $0.1 < $1.1 })?.0 ?? "goals"
    }
}

// MARK: - Coaching Plan

/// The coaching plan generated from onboarding analysis
struct CoachingPlan: Codable {
    let understandingSummary: String  // 2-3 sentences showing we understand them
    let coachingApproach: [String]    // 3-4 bullet points about how we'll coach
    
    // User profile data needed for the app
    let lifeContext: LifeContext
    let goal: Goal
    let engagementPreferences: EngagementPreferences
    let sleepWindow: SleepWindow
    let motivationalStyle: MotivationalStyle
    let timezone: String              // User's timezone identifier
    
    // Generated persona profile - completely unique, not based on archetypes
    let generatedPersona: PersonaProfile
}

// MARK: - Goal (Simplified for Manifesto)
struct Goal: Codable, Sendable {
    var family: GoalFamily = .healthWellbeing
    var rawText: String = ""
    
    // Extended properties for compatibility
    var weightObjective: WeightObjective?
    var bodyRecompositionGoals: [BodyRecompositionGoal] = []
    var functionalGoalsText: String = ""
    
    enum GoalFamily: String, Codable, CaseIterable, Sendable {
        case strengthTone = "strength_tone"
        case endurance = "endurance"
        case performance = "performance"
        case healthWellbeing = "health_wellbeing"
        case recoveryRehab = "recovery_rehab"
        
        var displayName: String {
            switch self {
            case .strengthTone: return "Build Strength"
            case .endurance: return "Improve Endurance"
            case .performance: return "Enhance Performance"
            case .healthWellbeing: return "Health & Wellbeing"
            case .recoveryRehab: return "Recovery & Rehab"
            }
        }
    }
}

// MARK: - Weight Objective
struct WeightObjective: Codable, Sendable {
    var currentWeight: Double?
    var targetWeight: Double?
    var direction: WeightDirection = .maintain
    
    enum WeightDirection: String, Codable, CaseIterable {
        case lose = "lose"
        case gain = "gain"
        case maintain = "maintain"
        
        var displayName: String {
            switch self {
            case .lose: return "Lose Weight"
            case .gain: return "Gain Weight"
            case .maintain: return "Maintain Weight"
            }
        }
    }
}

// MARK: - Body Recomposition Goal
enum BodyRecompositionGoal: String, Codable, CaseIterable, Sendable {
    case buildMuscle = "build_muscle"
    case loseFat = "lose_fat"
    case improveTone = "improve_tone"
    case coreStrength = "core_strength"
    
    var displayName: String {
        switch self {
        case .buildMuscle: return "Build Muscle"
        case .loseFat: return "Lose Fat"
        case .improveTone: return "Improve Muscle Tone"
        case .coreStrength: return "Strengthen Core"
        }
    }
}

// MARK: - Life Context
struct LifeContext: Codable, Sendable {
    var workStyle: WorkStyle = .moderate
    var fitnessLevel: FitnessLevel = .intermediate
    var workoutWindowPreference: WorkoutWindow = .morning
    
    enum WorkStyle: String, Codable, CaseIterable {
        case sedentary = "sedentary"
        case moderate = "moderate"
        case active = "active"
        case veryActive = "very_active"
    }
    
    enum FitnessLevel: String, Codable, CaseIterable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case athlete = "athlete"
    }
    
    enum WorkoutWindow: String, Codable, CaseIterable {
        case earlyMorning = "early_morning"  // 5-7 AM
        case morning = "morning"              // 7-9 AM
        case midday = "midday"                // 11 AM-1 PM
        case afternoon = "afternoon"          // 2-5 PM
        case evening = "evening"              // 5-8 PM
        case night = "night"                  // 8-10 PM
        
        var displayName: String {
            switch self {
            case .earlyMorning: return "Early Morning (5-7 AM)"
            case .morning: return "Morning (7-9 AM)"
            case .midday: return "Midday (11 AM-1 PM)"
            case .afternoon: return "Afternoon (2-5 PM)"
            case .evening: return "Evening (5-8 PM)"
            case .night: return "Night (8-10 PM)"
            }
        }
    }
}

// MARK: - Engagement Preferences
struct EngagementPreferences: Codable, Sendable {
    var checkInFrequency: CheckInFrequency = .daily
    var preferredTimes: [String] = ["morning", "evening"]
    
    enum CheckInFrequency: String, Codable, CaseIterable {
        case multiple = "multiple_daily"
        case daily = "daily"
        case fewTimes = "few_times_weekly"
        case weekly = "weekly"
    }
}

// MARK: - Sleep Window
struct SleepWindow: Codable, Sendable {
    var bedtime: String = "10:30 PM"
    var waketime: String = "6:30 AM"
}

// MARK: - Motivational Style
struct MotivationalStyle: Codable, Sendable {
    var styles: [Style] = [.encouraging]
    
    enum Style: String, Codable, CaseIterable {
        case tough = "tough_love"
        case encouraging = "encouraging"
        case analytical = "analytical"
        case buddy = "buddy"
    }
}