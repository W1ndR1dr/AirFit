import Foundation

// MARK: - Personality Insights
struct PersonalityInsights: Sendable {
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

extension PersonalityInsights: Codable {
    enum CodingKeys: String, CodingKey {
        case traits, communicationStyle, motivationalDrivers, stressResponses, confidenceScores, lastUpdated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode traits as [String: Double] then convert
        let traitsDict = try container.decode([String: Double].self, forKey: .traits)
        self.traits = Dictionary(uniqueKeysWithValues: traitsDict.compactMap { key, value in
            guard let dimension = PersonalityDimension(rawValue: key) else { return nil }
            return (dimension, value)
        })
        
        self.communicationStyle = try container.decode(CommunicationProfile.self, forKey: .communicationStyle)
        
        // Decode Set as Array then convert
        let driversArray = try container.decode([MotivationalDriver].self, forKey: .motivationalDrivers)
        self.motivationalDrivers = Set(driversArray)
        
        // Decode stress responses as [String: CopingStyle] then convert
        let stressDict = try container.decode([String: CopingStyle].self, forKey: .stressResponses)
        self.stressResponses = Dictionary(uniqueKeysWithValues: stressDict.compactMap { key, value in
            guard let trigger = StressTrigger(rawValue: key) else { return nil }
            return (trigger, value)
        })
        
        // Decode confidence scores as [String: Double] then convert
        let scoresDict = try container.decode([String: Double].self, forKey: .confidenceScores)
        self.confidenceScores = Dictionary(uniqueKeysWithValues: scoresDict.compactMap { key, value in
            guard let dimension = PersonalityDimension(rawValue: key) else { return nil }
            return (dimension, value)
        })
        
        self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Convert traits to [String: Double]
        let traitsDict = Dictionary(uniqueKeysWithValues: traits.map { ($0.key.rawValue, $0.value) })
        try container.encode(traitsDict, forKey: .traits)
        
        try container.encode(communicationStyle, forKey: .communicationStyle)
        
        // Convert Set to Array
        try container.encode(Array(motivationalDrivers), forKey: .motivationalDrivers)
        
        // Convert stress responses to [String: CopingStyle]
        let stressDict = Dictionary(uniqueKeysWithValues: stressResponses.map { ($0.key.rawValue, $0.value) })
        try container.encode(stressDict, forKey: .stressResponses)
        
        // Convert confidence scores to [String: Double]
        let scoresDict = Dictionary(uniqueKeysWithValues: confidenceScores.map { ($0.key.rawValue, $0.value) })
        try container.encode(scoresDict, forKey: .confidenceScores)
        
        try container.encode(lastUpdated, forKey: .lastUpdated)
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
    
    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .moderate: return "Moderate"
        case .comprehensive: return "Comprehensive"
        }
    }
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
struct GeneratedPersonaProfile: Codable, Sendable {
    let id: UUID
    let name: String
    let archetype: String
    let personalityPrompt: String
    let voiceCharacteristics: GeneratedVoiceCharacteristics
    let interactionStyle: GeneratedInteractionStyle
    let createdAt: Date
    let sourceInsights: PersonalityInsights
    
    init(
        name: String,
        archetype: String,
        personalityPrompt: String,
        voiceCharacteristics: GeneratedVoiceCharacteristics,
        interactionStyle: GeneratedInteractionStyle,
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

struct GeneratedVoiceCharacteristics: Codable, Sendable {
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

struct GeneratedInteractionStyle: Codable, Sendable {
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
