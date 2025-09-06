import Foundation

/// ConversationPersonalityInsights structure for conversation-based persona generation
/// This is used by PersonaService and PersonaSynthesizer
struct ConversationPersonalityInsights: Codable, Sendable {
    let dominantTraits: [String]
    let communicationStyle: ConversationCommunicationStyle
    let motivationType: ConversationMotivationType
    let energyLevel: ConversationEnergyLevel
    let preferredComplexity: ConversationComplexity
    let emotionalTone: [String]
    let stressResponse: ConversationStressResponse
    let preferredTimes: [String]
    let extractedAt: Date
}

enum ConversationCommunicationStyle: String, Codable, CaseIterable {
    case direct = "direct"
    case conversational = "conversational"
    case supportive = "supportive"
    case analytical = "analytical"
    case energetic = "energetic"
}

enum ConversationMotivationType: String, Codable, CaseIterable {
    case achievement = "achievement"
    case health = "health"
    case social = "social"
    case balanced = "balanced"
    case performance = "performance"
}

enum ConversationEnergyLevel: String, Codable, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
}

enum ConversationComplexity: String, Codable, CaseIterable {
    case simple = "simple"
    case moderate = "moderate"
    case detailed = "detailed"
}

enum ConversationStressResponse: String, Codable, CaseIterable {
    case needsSupport = "needs_support"
    case prefersDirectness = "prefers_directness"
    case wantsEncouragement = "wants_encouragement"
    case requiresBreakdown = "requires_breakdown"
}
