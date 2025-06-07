@testable import AirFit
import Foundation
import SwiftData

@MainActor
final class MockPersonaService: @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - Stubbed Results
    var stubbedGeneratePersonaResult: Result<PersonaProfile, Error> = .success(PersonaProfile.mock)
    var stubbedAdjustPersonaResult: Result<PersonaProfile, Error> = .success(PersonaProfile.mock)
    var stubbedSavePersonaResult: Result<Void, Error> = .success(())
    
    // MARK: - Configuration
    var generationDelay: TimeInterval = 0.0
    var shouldSimulateProgress = false
    var progressUpdates: [Double] = []
    
    // MARK: - Public Methods
    func generatePersona(from session: ConversationSession) async throws -> PersonaProfile {
        recordInvocation(#function, arguments: session)
        
        // Simulate delay if configured
        if generationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(generationDelay * 1_000_000_000))
        }
        
        // Simulate progress updates
        if shouldSimulateProgress {
            for progress in progressUpdates {
                // In real implementation, this would update some observable progress
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s between updates
            }
        }
        
        switch stubbedGeneratePersonaResult {
        case .success(let persona):
            return persona
        case .failure(let error):
            throw error
        }
    }
    
    func adjustPersona(_ persona: PersonaProfile, adjustment: String) async throws -> PersonaProfile {
        recordInvocation(#function, arguments: persona, adjustment)
        
        switch stubbedAdjustPersonaResult {
        case .success(let adjustedPersona):
            return adjustedPersona
        case .failure(let error):
            throw error
        }
    }
    
    func savePersona(_ persona: PersonaProfile, for userId: UUID) async throws {
        recordInvocation(#function, arguments: persona, userId)
        
        switch stubbedSavePersonaResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Mock PersonaProfile
extension PersonaProfile {
    static var mock: PersonaProfile {
        PersonaProfile(
            id: UUID(),
            name: "Coach Sarah",
            archetype: "Supportive Mentor",
            systemPrompt: "You are Coach Sarah, a supportive and encouraging fitness coach...",
            coreValues: ["Empowerment", "Consistency", "Balance"],
            backgroundStory: "Former athlete turned wellness coach...",
            voiceCharacteristics: VoiceCharacteristics(
                energy: .moderate,
                pace: .natural,
                warmth: .warm,
                vocabulary: .moderate,
                sentenceStructure: .moderate
            ),
            interactionStyle: InteractionStyle(
                greetingStyle: "Hey there!",
                closingStyle: "Keep up the great work!",
                encouragementPhrases: ["You've got this!", "Every step counts!"],
                acknowledgmentStyle: "celebratory",
                correctionApproach: "gentle",
                humorLevel: .moderate,
                formalityLevel: .casual,
                responseLength: .moderate
            ),
            adaptationRules: [],
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "1.0",
                sourceInsights: ConversationPersonalityInsights(
                    dominantTraits: ["Supportive", "Analytical", "Flexible"],
                    communicationStyle: .supportive,
                    motivationType: .balanced,
                    energyLevel: .moderate,
                    preferredComplexity: .moderate,
                    emotionalTone: ["supportive", "encouraging"],
                    stressResponse: .wantsEncouragement,
                    preferredTimes: ["morning", "evening"],
                    extractedAt: Date()
                ),
                generationDuration: 2.5,
                tokenCount: 1500,
                previewReady: true
            )
        )
    }
    
    static func mockWithName(_ name: String) -> PersonaProfile {
        PersonaProfile(
            id: UUID(),
            name: name,
            archetype: "Supportive Mentor",
            systemPrompt: "You are \(name), a supportive and encouraging fitness coach...",
            coreValues: ["Empowerment", "Consistency", "Balance"],
            backgroundStory: "Former athlete turned wellness coach...",
            voiceCharacteristics: mock.voiceCharacteristics,
            interactionStyle: mock.interactionStyle,
            adaptationRules: [],
            metadata: mock.metadata
        )
    }
    
    static func mockWithArchetype(_ archetype: String) -> PersonaProfile {
        PersonaProfile(
            id: UUID(),
            name: "Coach Sarah",
            archetype: archetype,
            systemPrompt: "You are Coach Sarah, a \(archetype.lowercased()) fitness coach...",
            coreValues: ["Empowerment", "Consistency", "Balance"],
            backgroundStory: "Former athlete turned wellness coach...",
            voiceCharacteristics: mock.voiceCharacteristics,
            interactionStyle: mock.interactionStyle,
            adaptationRules: [],
            metadata: mock.metadata
        )
    }
}