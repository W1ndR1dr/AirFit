import Foundation

// MARK: - Personality Insights
struct PersonalityInsights: Codable, Sendable {
    var traits: [PersonalityDimension: Double]
    var communicationStyle: CommunicationProfile
    var motivationalDrivers: Set<MotivationalDriver>
    var stressResponses: [StressTrigger: CopingStyle]
    var confidenceScores: [PersonalityDimension: Double]
    var lastUpdated: Date
    
    init() {
        self.traits = [:]
        self.communicationStyle = CommunicationProfile()
        self.motivationalDrivers = []
        self.stressResponses = [:]
        self.confidenceScores = [:]
        self.lastUpdated = Date()
    }
}

enum PersonalityDimension: String, Codable, CaseIterable {
    case authorityPreference
    case socialOrientation
    case structureNeed
    case intensityPreference
    case dataOrientation
    case emotionalSupport
}

struct CommunicationProfile: Codable, Sendable {
    var preferredTone: CommunicationTone
    var detailLevel: DetailLevel
    var encouragementStyle: EncouragementStyle
    var feedbackTiming: FeedbackTiming
    
    init() {
        self.preferredTone = .balanced
        self.detailLevel = .moderate
        self.encouragementStyle = .balanced
        self.feedbackTiming = .periodic
    }
}

enum CommunicationTone: String, Codable {
    case formal
    case casual
    case balanced
    case energetic
}

enum DetailLevel: String, Codable {
    case minimal
    case moderate
    case comprehensive
}

enum EncouragementStyle: String, Codable {
    case cheerleader
    case analytical
    case balanced
    case tough
}

enum FeedbackTiming: String, Codable {
    case immediate
    case periodic
    case milestone
}

enum MotivationalDriver: String, Codable {
    case achievement
    case health
    case appearance
    case performance
    case social
    case discipline
    case enjoyment
    case knowledge
}

enum StressTrigger: String, Codable {
    case timeConstraints
    case socialPressure
    case lackOfProgress
    case complexity
    case uncertainty
}

enum CopingStyle: String, Codable {
    case directGuidance
    case emotionalSupport
    case simplification
    case dataAndFacts
    case flexibility
}

// MARK: - Persona Profile (Generated from Insights)
struct PersonaProfile: Codable, Sendable {
    let id: UUID
    let name: String
    let archetype: String
    let personalityPrompt: String
    let voiceCharacteristics: VoiceCharacteristics
    let interactionStyle: InteractionStyle
    let createdAt: Date
    let sourceInsights: PersonalityInsights
    
    init(
        name: String,
        archetype: String,
        personalityPrompt: String,
        voiceCharacteristics: VoiceCharacteristics,
        interactionStyle: InteractionStyle,
        sourceInsights: PersonalityInsights
    ) {
        self.id = UUID()
        self.name = name
        self.archetype = archetype
        self.personalityPrompt = personalityPrompt
        self.voiceCharacteristics = voiceCharacteristics
        self.interactionStyle = interactionStyle
        self.createdAt = Date()
        self.sourceInsights = sourceInsights
    }
}

struct VoiceCharacteristics: Codable, Sendable {
    let pace: VoicePace
    let energy: VoiceEnergy
    let warmth: VoiceWarmth
    
    enum VoicePace: String, Codable {
        case slow
        case moderate
        case fast
    }
    
    enum VoiceEnergy: String, Codable {
        case calm
        case balanced
        case energetic
    }
    
    enum VoiceWarmth: String, Codable {
        case professional
        case friendly
        case enthusiastic
    }
}

struct InteractionStyle: Codable, Sendable {
    let greetingStyle: String
    let signoffStyle: String
    let encouragementPhrases: [String]
    let correctionStyle: String
    let humorLevel: HumorLevel
    
    enum HumorLevel: String, Codable {
        case none
        case occasional
        case frequent
    }
}