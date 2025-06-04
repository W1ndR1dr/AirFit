import Foundation
import Combine

@MainActor
final class PreviewGenerator: ObservableObject {
    @Published private(set) var currentStage: SynthesisStage = .notStarted
    @Published private(set) var preview: PersonaPreview?
    @Published private(set) var progress: Double = 0
    @Published private(set) var error: Error?
    
    private let synthesizer: PersonaSynthesizer
    private var synthesisTask: Task<Void, Never>?
    
    init(synthesizer: PersonaSynthesizer) {
        self.synthesizer = synthesizer
    }
    
    // MARK: - Public API
    
    func startSynthesis(
        insights: PersonalityInsights,
        conversationData: ConversationData
    ) {
        synthesisTask?.cancel()
        
        synthesisTask = Task {
            await performSynthesis(insights: insights, conversationData: conversationData)
        }
    }
    
    func cancelSynthesis() {
        synthesisTask?.cancel()
        currentStage = .cancelled
        progress = 0
    }
    
    // MARK: - Private Implementation
    
    private func performSynthesis(
        insights: PersonalityInsights,
        conversationData: ConversationData
    ) async {
        do {
            // Stage 1: Analyzing personality
            updateStage(.analyzingPersonality)
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s for effect
            
            // Create initial preview during analysis
            preview = PersonaPreview(
                name: "Analyzing...",
                archetype: "Discovering your ideal coach type",
                sampleGreeting: "Getting to know you...",
                voiceDescription: "Understanding your preferences"
            )
            
            // Stage 2: Creating identity
            updateStage(.creatingIdentity)
            
            // Simulate streaming effect with preview updates
            let placeholderNames = ["Creating", "Creating your", "Creating your unique", "Creating your unique coach..."]
            for (index, text) in placeholderNames.enumerated() {
                preview = PersonaPreview(
                    name: text,
                    archetype: "Crafting personality...",
                    sampleGreeting: "Preparing to meet you...",
                    voiceDescription: "Building communication style"
                )
                progress = 0.2 + (Double(index) / Double(placeholderNames.count)) * 0.2
                try await Task.sleep(nanoseconds: 200_000_000)
            }
            
            // Stage 3: Building personality
            updateStage(.buildingPersonality)
            
            // Convert PersonalityInsights to ConversationPersonalityInsights
            let conversationInsights = ConversationPersonalityInsights(
                dominantTraits: insights.dominantTraits,
                communicationStyle: insights.conversationCommunicationStyle,
                motivationType: convertMotivationType(insights.motivationType),
                energyLevel: insights.conversationEnergyLevel,
                preferredComplexity: convertComplexity(insights.preferredComplexity),
                emotionalTone: insights.emotionalTone,
                stressResponse: convertStressResponse(insights.stressResponse),
                preferredTimes: insights.preferredTimes,
                extractedAt: Date()
            )
            
            // Generate actual persona
            let persona = try await synthesizer.synthesizePersona(
                from: conversationData,
                insights: conversationInsights
            )
            
            // Update preview with real data
            // Update preview with real data
            preview = PersonaPreview(
                name: persona.name,
                archetype: persona.archetype,
                sampleGreeting: generateSampleGreeting(for: persona),
                voiceDescription: generateVoiceDescription(for: persona)
            )
            progress = 0.7
            
            // Stage 4: Finalizing
            updateStage(.finalizing)
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1s
            
            // Stage 5: Complete
            updateStage(.complete(persona))
            progress = 1.0
            
            // Update final preview
            preview = PersonaPreview(
                name: persona.name,
                archetype: persona.archetype,
                sampleGreeting: generateFinalGreeting(for: persona),
                voiceDescription: generateFinalVoiceDescription(for: persona)
            )
            
        } catch {
            if error is CancellationError {
                currentStage = .cancelled
            } else {
                self.error = error
                currentStage = .failed(error)
            }
            progress = 0
        }
    }
    
    private func updateStage(_ stage: SynthesisStage) {
        currentStage = stage
        
        // Update progress based on stage
        switch stage {
        case .notStarted:
            progress = 0
        case .analyzingPersonality:
            progress = 0.2
        case .creatingIdentity:
            progress = 0.4
        case .buildingPersonality:
            progress = 0.6
        case .finalizing:
            progress = 0.8
        case .complete:
            progress = 1.0
        case .failed, .cancelled:
            break // Keep current progress
        }
    }
    
    private func extractTopTraits(from insights: PersonalityInsights) -> [String] {
        insights.traits
            .sorted { abs($0.value) > abs($1.value) }
            .prefix(3)
            .map { dimension, score in
                formatTrait(dimension: dimension, score: score)
            }
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
    
    private func generateSampleGreeting(for persona: PersonaProfile) -> String {
        let greetings = [
            "Meet \(persona.name), your \(persona.archetype) coach!",
            "\(persona.name) is ready to guide your fitness journey!",
            "Say hello to \(persona.name) - \(persona.archetype)!"
        ]
        
        return greetings.randomElement() ?? "Your coach is ready!"
    }
    
    private func generateVoiceDescription(for persona: PersonaProfile) -> String {
        let energy = persona.voiceCharacteristics.energy.rawValue
        let warmth = persona.voiceCharacteristics.warmth.rawValue
        return "\(energy.capitalized) energy with \(warmth) tone"
    }
    
    private func generateFinalGreeting(for persona: PersonaProfile) -> String {
        return "\(persona.interactionStyle.greetingStyle) I'm \(persona.name), and I'm excited to help you reach your goals!"
    }
    
    private func generateFinalVoiceDescription(for persona: PersonaProfile) -> String {
        return persona.interactionStyle.greetingStyle
    }
    
    // MARK: - Mapping Functions
    
    private func convertMotivationType(_ motivation: MotivationType) -> ConversationMotivationType {
        switch motivation {
        case .achievement:
            return .achievement
        case .health:
            return .health
        case .social:
            return .social
        }
    }
    
    private func convertComplexity(_ complexity: ComplexityLevel) -> ConversationComplexity {
        switch complexity {
        case .simple:
            return .simple
        case .moderate:
            return .moderate
        case .detailed:
            return .detailed
        }
    }
    
    private func convertStressResponse(_ response: StressResponseType) -> ConversationStressResponse {
        switch response {
        case .needsSupport:
            return .needsSupport
        case .needsDirection:
            return .prefersDirectness
        case .independent:
            return .requiresBreakdown
        }
    }
}

// MARK: - Supporting Types

enum SynthesisStage: Equatable {
    case notStarted
    case analyzingPersonality
    case creatingIdentity
    case buildingPersonality
    case finalizing
    case complete(PersonaProfile)
    case failed(Error)
    case cancelled
    
    var displayText: String {
        switch self {
        case .notStarted:
            return "Ready to create your coach"
        case .analyzingPersonality:
            return "Analyzing your personality..."
        case .creatingIdentity:
            return "Creating unique identity..."
        case .buildingPersonality:
            return "Building personality..."
        case .finalizing:
            return "Adding final touches..."
        case .complete:
            return "Your coach is ready!"
        case .failed:
            return "Something went wrong"
        case .cancelled:
            return "Synthesis cancelled"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .analyzingPersonality, .creatingIdentity, .buildingPersonality, .finalizing:
            return true
        default:
            return false
        }
    }
    
    static func == (lhs: SynthesisStage, rhs: SynthesisStage) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
             (.analyzingPersonality, .analyzingPersonality),
             (.creatingIdentity, .creatingIdentity),
             (.buildingPersonality, .buildingPersonality),
             (.finalizing, .finalizing),
             (.cancelled, .cancelled):
            return true
        case (.complete(let p1), .complete(let p2)):
            return p1.id == p2.id
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// PersonaPreview is defined in PersonaSynthesizer.swift