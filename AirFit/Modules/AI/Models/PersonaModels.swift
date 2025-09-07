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

/// Raw conversation data from the onboarding flow - simple and LLM-friendly
struct ConversationData: Codable, Sendable {
    let messages: [ConversationMessage]
    let currentNodeId: String?
    let variables: [String: String] // Just strings, let LLM handle complexity

    init(messages: [ConversationMessage], currentNodeId: String? = nil, variables: [String: String] = [:]) {
        self.messages = messages
        self.currentNodeId = currentNodeId
        self.variables = variables
    }

    // Helper to get conversation as text
    var conversationText: String {
        messages.map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n")
    }

    // Helper to get just user messages
    var userMessages: [String] {
        messages.filter { $0.role == .user }.map { $0.content }
    }

    // Helper to get user name (with fallback)
    var userName: String {
        variables["userName"] ?? "there"
    }

    // Helper to get primary goal
    var primaryGoal: String {
        variables["primary_goal"] ?? "improve fitness"
    }
}

struct ConversationMessage: Codable, Sendable {
    let role: ConversationRole
    let content: String
    let timestamp: Date

    enum ConversationRole: String, Codable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
    }
}

// MARK: - Missing Type Definitions

enum MotivationType: String, Codable, Sendable {
    case achievement
    case health
    case social
    case enjoyment
}

enum ComplexityLevel: String, Codable, Sendable {
    case simple
    case moderate
    case complex
    case detailed
}

enum StressResponseType: String, Codable, Sendable {
    case needsSupport
    case needsDirection
    case independent
    case balanced
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
enum WorkStyle: String, Codable {
    case sedentary
    case moderate
    case high
}

enum FitnessLevel: String, Codable {
    case beginner
    case intermediate
    case advanced
}

enum WorkoutTimePreference: String, Codable {
    case morning
    case lunchtime
    case evening
    case flexible
}

enum CheckInFrequency: String, Codable {
    case daily
    case moderate
    case minimal
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
    let nutritionRecommendations: NutritionRecommendations?
}

/// AI-generated nutrition recommendations based on user's goals and conversation
struct NutritionRecommendations: Codable, Sendable {
    let approach: String                    // e.g., "Fuel for performance", "Sustainable habits"
    let proteinGramsPerPound: Double       // e.g., 1.3 for muscle building, 0.8 for general health
    let fatPercentage: Double              // e.g., 0.25 for low fat, 0.35 for keto-leaning
    let carbStrategy: String               // e.g., "Fill remaining", "Minimum 150g for performance"
    let rationale: String                  // Why these macros fit their goals
    let flexibilityNotes: String           // How to handle adherence
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
            encouragementStyle: personaProfile.interactionStyle.encouragementPhrases.first ?? "Great job.",
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
