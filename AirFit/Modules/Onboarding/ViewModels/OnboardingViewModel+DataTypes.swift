import Foundation

// MARK: - Supporting Types for OnboardingViewModel

struct HealthKitSnapshot: Codable, Sendable {
    let weight: Double?
    let height: Double?
    let age: Int?
    let sleepSchedule: SleepSchedule?
    let activityMetrics: OnboardingActivityMetrics?
    
    init(weight: Double? = nil, height: Double? = nil, age: Int? = nil, sleepSchedule: SleepSchedule? = nil, activityMetrics: OnboardingActivityMetrics? = nil) {
        self.weight = weight
        self.height = height
        self.age = age
        self.sleepSchedule = sleepSchedule
        self.activityMetrics = activityMetrics
    }
}

struct SleepSchedule: Codable, Sendable {
    let bedtime: Date
    let waketime: Date
}

// Communication styles from the enhancement doc
enum CommunicationStyle: String, Codable, CaseIterable {
    case encouraging = "encouraging_supportive"
    case direct = "direct_no_nonsense"
    case analytical = "data_driven_analytical"
    case motivational = "energetic_motivational"
    case patient = "patient_understanding"
    case challenging = "challenging_pushing"
    case educational = "educational_explanatory"
    case playful = "playful_humorous"
    
    var displayName: String {
        switch self {
        case .encouraging: return "Encouraging and supportive"
        case .direct: return "Direct and no-nonsense"
        case .analytical: return "Data-driven and analytical"
        case .motivational: return "Energetic and motivational"
        case .patient: return "Patient with setbacks"
        case .challenging: return "Challenging and pushing"
        case .educational: return "Educational and explanatory"
        case .playful: return "Playful and fun"
        }
    }
    
    var description: String {
        switch self {
        case .encouraging: return "\"You've got this!\""
        case .direct: return "\"Here's what needs to happen\""
        case .analytical: return "\"Let's look at the numbers\""
        case .motivational: return "\"Let's crush these goals!\""
        case .patient: return "\"Progress isn't always linear\""
        case .challenging: return "\"I know you can do better\""
        case .educational: return "\"Here's why this works\""
        case .playful: return "\"Fitness doesn't have to be serious!\""
        }
    }
}

enum InformationStyle: String, Codable, CaseIterable {
    case detailed = "detailed_explanations"
    case keyMetrics = "key_metrics_only"
    case celebrations = "progress_celebrations"
    case educational = "educational_content"
    case quickCheckins = "quick_check_ins"
    case inDepthAnalysis = "in_depth_analysis"
    case essentials = "just_essentials"
    
    var displayName: String {
        switch self {
        case .detailed: return "Detailed explanations"
        case .keyMetrics: return "Key metrics only"
        case .celebrations: return "Progress celebrations"
        case .educational: return "Educational content"
        case .quickCheckins: return "Quick check-ins"
        case .inDepthAnalysis: return "In-depth analysis"
        case .essentials: return "Just the essentials"
        }
    }
}