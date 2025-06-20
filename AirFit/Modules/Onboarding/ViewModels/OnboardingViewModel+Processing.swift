import Foundation

// MARK: - Data Processing & Synthesis Methods

extension OnboardingViewModel {
    
    // MARK: - Goal Parsing
    
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
    
    // MARK: - Persona Synthesis
    
    func synthesizePersona() async {
        currentScreen = .synthesis
        isLoading = true
        synthesisProgress = 0.0
        
        do {
            // Process weight values
            if !currentWeightText.isEmpty {
                currentWeight = Double(currentWeightText)
            }
            if !targetWeightText.isEmpty {
                targetWeight = Double(targetWeightText)
            }
            
            // Create raw data for synthesis
            let rawData = createRawDataForSave()
            
            // Start synthesis with progress updates
            let progressTask = Task { @MainActor in
                for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s per step
                    self.synthesisProgress = progress
                }
            }
            
            // Synthesize goals with all collected data
            let synthesis = try await onboardingService.synthesizeGoals(from: rawData)
            self.synthesizedGoals = synthesis
            
            // Use default persona for now since PersonaService expects ConversationSession
            // This will be refactored when PersonaService is updated to accept OnboardingRawData
            continueWithDefaultPersona()
            
            // Cancel progress updates
            progressTask.cancel()
            self.synthesisProgress = 1.0
            
            // Navigate to ready screen
            currentScreen = .coachReady
            
        } catch {
            handleError(error)
            // Try fallback
            continueWithDefaultPersona()
            currentScreen = .coachReady
        }
        
        isLoading = false
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
    
    // MARK: - Completion
    
    func completeOnboarding() async {
        guard let persona = generatedPersona,
              let userId = await userService.getCurrentUserId() else {
            error = .validationError(message: "Missing persona or user")
            isShowingError = true
            return
        }
        
        isLoading = true
        
        do {
            // Save the complete onboarding profile
            try await saveOnboardingProfile(userId: userId, persona: persona)
            
            // Save persona
            try await personaService.savePersona(persona, for: userId)
            
            // Update user with coach persona
            let coachPersona = CoachPersona(from: persona)
            try await userService.setCoachPersona(coachPersona)
            
            // Complete onboarding
            try await userService.completeOnboarding()
            
            // Track completion
            // await analytics.trackEvent(.onboardingCompleted)
            
            // Notify completion
            onCompletionCallback?()
            
        } catch {
            self.error = error as? AppError ?? .unknown(message: error.localizedDescription)
            isShowingError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error) {
        self.error = error as? AppError ?? .unknown(message: error.localizedDescription)
        isShowingError = true
        HapticService.play(.error)
    }
    
    func clearError() {
        error = nil
        isShowingError = false
    }
    
    // MARK: - Private Helpers
    
    private func saveOnboardingProfile(userId: UUID, persona: PersonaProfile) async throws {
        let rawData = createRawDataForSave()
        
        // Create OnboardingProfile
        let profile = OnboardingProfile(
            personaPromptData: Data(), // Will be set below
            communicationPreferencesData: Data(), // Will be set below
            rawFullProfileData: Data() // Will be set below
        )
        
        // Encode persona prompt data
        if let personaData = try? JSONEncoder().encode(persona) {
            profile.personaPromptData = personaData
        }
        
        // Encode communication preferences
        let communicationPrefs = [
            "styles": communicationStyles.map { $0.rawValue },
            "informationPreferences": informationPreferences.map { $0.rawValue }
        ]
        if let commData = try? JSONEncoder().encode(communicationPrefs) {
            profile.communicationPreferencesData = commData
        }
        
        // Encode full raw data
        if let rawDataEncoded = try? JSONEncoder().encode(rawData) {
            profile.rawFullProfileData = rawDataEncoded
        }
        
        // Set additional properties
        profile.name = userName
        profile.isComplete = true
        profile.persona = persona
        
        // Save through service
        try await onboardingService.saveProfile(profile)
    }
    
    private func createRawDataForSave() -> OnboardingRawData {
        OnboardingRawData(
            userName: userName,
            lifeContextText: lifeContext,
            weightObjective: createWeightObjective(),
            bodyRecompositionGoals: bodyRecompositionGoals,
            functionalGoalsText: functionalGoalsText,
            communicationStyles: communicationStyles,
            informationPreferences: informationPreferences,
            healthKitData: healthKitData,
            manualHealthData: nil
        )
    }
    
    private func createWeightObjective() -> WeightObjective? {
        guard currentWeight != nil || targetWeight != nil else { return nil }
        return WeightObjective(
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            timeframe: nil
        )
    }
    
}