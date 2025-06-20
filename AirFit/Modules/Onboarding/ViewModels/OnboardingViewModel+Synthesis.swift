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
        let defaultPersona = PersonaProfile(
            id: UUID(),
            name: "Coach",
            archetype: "Supportive Guide",
            systemPrompt: "You are a supportive fitness coach focused on helping users achieve their health goals.",
            coreValues: ["Encouragement", "Progress over perfection", "Personalization"],
            backgroundStory: "I'm here to help you on your fitness journey with patience and support.",
            voiceCharacteristics: VoiceCharacteristics(
                energy: .moderate,
                pace: .natural,
                warmth: .warm,
                formality: .casual,
                emphasis: .balanced
            ),
            traitsAndQuirks: ["Patient", "Encouraging", "Knowledge-focused"],
            adaptationStrategies: AdaptationStrategies(
                timeBasedAdaptation: true,
                healthMetricsAdaptation: true,
                goalProgressAdaptation: true,
                energyMatching: true,
                stressAwareness: true
            ),
            preferredTopics: ["Goal setting", "Progress tracking", "Health education"],
            boundaries: ["Supportive", "Non-judgmental", "Educational"],
            decisionStyle: .balanced,
            creativityLevel: .moderate,
            dateCreated: Date()
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