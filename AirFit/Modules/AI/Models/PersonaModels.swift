import Foundation

// MARK: - Conversation Data Models

/// Raw conversation data from the onboarding flow
struct ConversationData: Codable, Sendable {
    let userName: String
    let primaryGoal: String
    let responses: [String: Any]
    let summary: String
    let nodeCount: Int
    
    init(userName: String, primaryGoal: String, responses: [String: Any]) {
        self.userName = userName
        self.primaryGoal = primaryGoal
        self.responses = responses
        self.summary = Self.generateSummary(from: responses, userName: userName, goal: primaryGoal)
        self.nodeCount = responses.count
    }
    
    private static func generateSummary(from responses: [String: Any], userName: String, goal: String) -> String {
        var summary = "\(userName) wants to \(goal). "
        
        // Extract key information from responses
        if let lifestyle = responses["lifestyle"] as? String {
            summary += "Lifestyle: \(lifestyle). "
        }
        if let experience = responses["experience"] as? String {
            summary += "Experience: \(experience). "
        }
        if let preferences = responses["preferences"] as? [String] {
            summary += "Preferences: \(preferences.joined(separator: ", ")). "
        }
        
        return summary
    }
    
    // Codable conformance for [String: Any]
    enum CodingKeys: String, CodingKey {
        case userName, primaryGoal, responses, summary, nodeCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userName = try container.decode(String.self, forKey: .userName)
        primaryGoal = try container.decode(String.self, forKey: .primaryGoal)
        summary = try container.decode(String.self, forKey: .summary)
        nodeCount = try container.decode(Int.self, forKey: .nodeCount)
        
        // Decode responses as Data and convert back
        if let data = try? container.decode(Data.self, forKey: .responses),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            responses = dict
        } else {
            responses = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userName, forKey: .userName)
        try container.encode(primaryGoal, forKey: .primaryGoal)
        try container.encode(summary, forKey: .summary)
        try container.encode(nodeCount, forKey: .nodeCount)
        
        // Encode responses as Data
        if let data = try? JSONSerialization.data(withJSONObject: responses) {
            try container.encode(data, forKey: .responses)
        }
    }
}

// MARK: - Enhanced Personality Insights

/// Enhanced personality insights that PersonaSynthesizer expects
extension PersonalityInsights {
    // Computed properties to bridge to expected format
    var dominantTraits: [String] {
        traits
            .sorted { abs($0.value) > abs($1.value) }
            .prefix(3)
            .map { dimension, score in
                formatTrait(dimension: dimension, score: score)
            }
    }
    
    var communicationStyle: CommunicationStyleSimple {
        switch communicationProfile.preferredTone {
        case .formal, .balanced:
            return .explanatory
        case .casual, .energetic:
            return .conversational
        }
    }
    
    var motivationType: MotivationType {
        if motivationalDrivers.contains(.achievement) || motivationalDrivers.contains(.performance) {
            return .achievement
        } else if motivationalDrivers.contains(.social) || motivationalDrivers.contains(.enjoyment) {
            return .social
        } else {
            return .health
        }
    }
    
    var energyLevel: EnergyLevel {
        if let intensity = traits[.intensityPreference], intensity > 0.5 {
            return .high
        } else if let intensity = traits[.intensityPreference], intensity < -0.5 {
            return .low
        }
        return .moderate
    }
    
    var emotionalTone: [String] {
        var tones: [String] = []
        if let support = traits[.emotionalSupport], support > 0.5 {
            tones.append("supportive")
        }
        if communicationProfile.preferredTone == .formal {
            tones.append("professional")
        }
        return tones
    }
    
    var preferredComplexity: ComplexityLevel {
        switch communicationProfile.detailLevel {
        case .minimal:
            return .simple
        case .moderate:
            return .moderate
        case .comprehensive:
            return .detailed
        }
    }
    
    var preferredTimes: [String] {
        // This would be extracted from conversation data
        ["morning", "evening"]
    }
    
    var stressResponse: StressResponseType {
        if let copingStyle = stressResponses.values.first {
            switch copingStyle {
            case .emotionalSupport:
                return .needsSupport
            case .directGuidance:
                return .needsDirection
            default:
                return .independent
            }
        }
        return .needsSupport
    }
    
    private func formatTrait(dimension: PersonalityDimension, score: Double) -> String {
        switch dimension {
        case .authorityPreference:
            return score > 0.5 ? "Structured" : "Independent"
        case .socialOrientation:
            return score > 0.5 ? "Social" : "Focused"
        case .structureNeed:
            return score > 0.5 ? "Organized" : "Flexible"
        case .intensityPreference:
            return score > 0.5 ? "High-Energy" : "Steady"
        case .dataOrientation:
            return score > 0.5 ? "Analytical" : "Intuitive"
        case .emotionalSupport:
            return score > 0.5 ? "Supportive" : "Direct"
        }
    }
}

// Supporting enums for PersonalityInsights extensions
enum CommunicationStyleSimple: String, Codable {
    case direct
    case explanatory
    case conversational
}

enum MotivationType: String, Codable {
    case achievement
    case health
    case social
}

enum EnergyLevel: String, Codable {
    case high
    case moderate
    case low
}

enum ComplexityLevel: String, Codable {
    case simple
    case moderate
    case detailed
}

enum StressResponseType: String, Codable {
    case needsSupport
    case needsDirection
    case independent
}

// MARK: - Persona Components

/// Core identity of the AI coach
struct PersonaIdentity: Codable, Sendable {
    let name: String
    let archetype: String
    let coreValues: [String]
    let backgroundStory: String
}

/// Voice characteristics for text generation
struct VoiceCharacteristics: Codable, Sendable {
    let energy: Energy
    let pace: Pace
    let warmth: Warmth
    let vocabulary: Vocabulary
    let sentenceStructure: SentenceStructure
    
    enum Energy: String, Codable {
        case high
        case moderate
        case calm
    }
    
    enum Pace: String, Codable {
        case brisk
        case measured
        case natural
    }
    
    enum Warmth: String, Codable {
        case warm
        case neutral
        case friendly
    }
    
    enum Vocabulary: String, Codable {
        case simple
        case moderate
        case advanced
    }
    
    enum SentenceStructure: String, Codable {
        case simple
        case moderate
        case complex
    }
}

/// Interaction style parameters
struct InteractionStyle: Codable, Sendable {
    let greetingStyle: String
    let closingStyle: String
    let encouragementPhrases: [String]
    let acknowledgmentStyle: String
    let correctionApproach: String
    let humorLevel: HumorLevel
    let formalityLevel: FormalityLevel
    let responseLength: ResponseLength
    
    enum HumorLevel: String, Codable {
        case none
        case light
        case moderate
        case playful
    }
    
    enum FormalityLevel: String, Codable {
        case casual
        case balanced
        case professional
    }
    
    enum ResponseLength: String, Codable {
        case concise
        case moderate
        case detailed
    }
}

/// Rules for adapting persona behavior
struct AdaptationRule: Codable, Sendable {
    let trigger: Trigger
    let condition: String
    let adjustment: String
    
    enum Trigger: String, Codable {
        case timeOfDay
        case stress
        case progress
        case mood
    }
}

/// Metadata about persona generation
struct PersonaMetadata: Codable, Sendable {
    let createdAt: Date
    let version: String
    let sourceInsights: PersonalityInsights
    let generationDuration: TimeInterval
    let tokenCount: Int
    let previewReady: Bool
}

/// Complete persona profile
struct PersonaProfile: Codable, Sendable {
    let id: UUID
    let name: String
    let archetype: String
    let systemPrompt: String
    let coreValues: [String]
    let backgroundStory: String
    let voiceCharacteristics: VoiceCharacteristics
    let interactionStyle: InteractionStyle
    let adaptationRules: [AdaptationRule]
    let metadata: PersonaMetadata
}

// MARK: - Coach Persona (Final Model)

/// The complete coach persona used throughout the app
struct CoachPersona: Codable, Sendable {
    let id: UUID
    let identity: PersonaIdentity
    let communication: VoiceCharacteristics
    let philosophy: CoachingPhilosophy
    let behaviors: CoachingBehaviors
    let quirks: [PersonaQuirk]
    let profile: PersonalityInsights
    let systemPrompt: String
    let generatedAt: Date
    
    init(from personaProfile: PersonaProfile) {
        self.id = personaProfile.id
        self.identity = PersonaIdentity(
            name: personaProfile.name,
            archetype: personaProfile.archetype,
            coreValues: personaProfile.coreValues,
            backgroundStory: personaProfile.backgroundStory
        )
        self.communication = personaProfile.voiceCharacteristics
        self.philosophy = CoachingPhilosophy(
            approach: "Supportive and encouraging",
            principles: personaProfile.coreValues,
            motivationalStyle: "Positive reinforcement"
        )
        self.behaviors = CoachingBehaviors(
            greetingStyle: personaProfile.interactionStyle.greetingStyle,
            feedbackStyle: personaProfile.interactionStyle.acknowledgmentStyle,
            encouragementStyle: personaProfile.interactionStyle.encouragementPhrases.first ?? "Great job!",
            adaptations: personaProfile.adaptationRules
        )
        self.quirks = []
        self.profile = personaProfile.metadata.sourceInsights
        self.systemPrompt = personaProfile.systemPrompt
        self.generatedAt = personaProfile.metadata.createdAt
    }
}

struct CoachingPhilosophy: Codable, Sendable {
    let approach: String
    let principles: [String]
    let motivationalStyle: String
}

struct CoachingBehaviors: Codable, Sendable {
    let greetingStyle: String
    let feedbackStyle: String
    let encouragementStyle: String
    let adaptations: [AdaptationRule]
}

struct PersonaQuirk: Codable, Sendable {
    let trait: String
    let expression: String
    let frequency: String
}