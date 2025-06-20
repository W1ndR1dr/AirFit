import Foundation

// MARK: - Goal & Persona Synthesis
extension OnboardingViewModel {
    
    func parseGoalsWithLLM() async -> String {
        // Early return with fallback if no goals text
        guard !functionalGoalsText.isEmpty else {
            return "Let's define your fitness goals together."
        }
        
        do {
            // Use the onboarding service which has access to LLM
            return try await onboardingService.parseGoalsConversationally(from: functionalGoalsText)
        } catch {
            // Fallback to acknowledging their input
            return "You want to \(functionalGoalsText). I'll help create a personalized plan for your fitness journey."
        }
    }
    
    func retrySynthesis() async {
        // Reset previous state
        synthesizedGoals = nil
        generatedPersona = nil
        error = nil
        
        // Retry the synthesis
        await synthesizePersona()
    }
    
    func continueWithDefaultPersona() {
        // Create a basic persona when synthesis fails
        let defaultVoice = VoiceCharacteristics(
            energy: .moderate,
            pace: .natural,
            warmth: .warm,
            vocabulary: .moderate,
            sentenceStructure: .moderate
        )
        
        let defaultInteraction = InteractionStyle(
            greetingStyle: "Hey there! Ready to make some progress today?",
            closingStyle: "Great work today! Keep it up!",
            encouragementPhrases: ["You've got this!", "Keep pushing!", "Great effort!"],
            acknowledgmentStyle: "I hear you. Let's work with that.",
            correctionApproach: "Let's adjust that approach slightly",
            humorLevel: .moderate,
            formalityLevel: .casual,
            responseLength: .moderate
        )
        
        let defaultInsights = ConversationPersonalityInsights(
            dominantTraits: ["Supportive", "Patient", "Encouraging"],
            communicationStyle: .conversational,
            motivationType: .health,
            energyLevel: .moderate,
            preferredComplexity: .moderate,
            emotionalTone: ["warm", "encouraging"],
            stressResponse: .needsSupport,
            preferredTimes: ["morning", "evening"],
            extractedAt: Date()
        )
        
        let defaultMetadata = PersonaMetadata(
            createdAt: Date(),
            version: "1.0",
            sourceInsights: defaultInsights,
            generationDuration: 0.0,
            tokenCount: 0,
            previewReady: true
        )
        
        let defaultPersona = PersonaProfile(
            id: UUID(),
            name: "Coach",
            archetype: "Supportive Guide",
            systemPrompt: "You are a supportive fitness coach focused on helping users achieve their health goals.",
            coreValues: ["Encouragement", "Progress over perfection", "Personalization"],
            backgroundStory: "I'm here to help you on your fitness journey with patience and support.",
            voiceCharacteristics: defaultVoice,
            interactionStyle: defaultInteraction,
            adaptationRules: [],
            metadata: defaultMetadata
        )
        
        self.generatedPersona = defaultPersona
        
        // Create basic synthesis output
        let defaultSynthesis = LLMGoalSynthesis(
            parsedFunctionalGoals: [],
            goalRelationships: [],
            unifiedStrategy: "achieve your fitness goals with consistent progress",
            recommendedTimeline: "Let's start with 12-week cycles",
            suggestedPersonaMode: nil,
            coachingFocus: ["Building healthy habits", "Sustainable progress", "Personalized support"],
            milestones: [],
            expectedChallenges: [],
            motivationalHooks: []
        )
        
        self.synthesizedGoals = defaultSynthesis
    }
}