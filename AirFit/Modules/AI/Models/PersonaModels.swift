import Foundation

// MARK: - Error Types

enum PersonaError: LocalizedError {
    case invalidResponse(String)
    case missingField(String)
    case invalidFormat(String, expected: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let message):
            return "Invalid AI response: \(message)"
        case .missingField(let field):
            return "Missing required field: \(field)"
        case .invalidFormat(let field, let expected):
            return "Invalid format for \(field). Expected: \(expected)"
        }
    }
}

// MARK: - Conversation Data Models

/// Raw conversation data from the onboarding flow
struct ConversationData: Codable, Sendable {
    let userName: String
    let primaryGoal: String
    let responses: [String: AnyCodable]
    let summary: String
    let nodeCount: Int
    
    init(userName: String, primaryGoal: String, responses: [String: Any]) {
        self.userName = userName
        self.primaryGoal = primaryGoal
        self.responses = responses.mapValues { AnyCodable($0) }
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
    
    // Codable conformance is now automatic with AnyCodable
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
    
    var conversationCommunicationStyle: ConversationCommunicationStyle {
        switch communicationStyle.preferredTone {
        case .formal, .balanced:
            return .analytical
        case .casual:
            return .conversational
        case .energetic:
            return .energetic
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
    
    var conversationEnergyLevel: ConversationEnergyLevel {
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
        if communicationStyle.preferredTone == .formal {
            tones.append("professional")
        }
        return tones
    }
    
    var preferredComplexity: ComplexityLevel {
        switch communicationStyle.detailLevel {
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

// Supporting enums and types for PersonalityInsights extensions
enum MotivationType: String, Codable {
    case achievement
    case health
    case social
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
    let sourceInsights: ConversationPersonalityInsights
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
        // Convert from ConversationPersonalityInsights to PersonalityInsights
        let sourceInsights = personaProfile.metadata.sourceInsights
        var insights = PersonalityInsights()
        insights.traits = [:] // Would need proper conversion from sourceInsights
        insights.communicationStyle = CommunicationProfile()
        insights.communicationStyle.preferredTone = .balanced
        insights.communicationStyle.detailLevel = .moderate
        insights.motivationalDrivers = Set([.achievement])
        insights.stressResponses = [:]
        insights.lastUpdated = sourceInsights.extractedAt
        self.profile = insights
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