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
            
            // Generate a minimal persona based on collected data
            await generateMinimalPersona()
            
            // Cancel progress updates
            progressTask.cancel()
            self.synthesisProgress = 1.0
            
            // Navigate to ready screen
            currentScreen = .coachReady
            
        } catch {
            handleError(error)
            // Try to generate a minimal persona
            await generateMinimalPersona()
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
    
    func generateMinimalPersona() async {
        // Try to generate a persona using minimal collected data
        guard let llmService = onboardingLLMService else {
            // If no LLM service, use absolute minimal fallback
            createAbsoluteMinimalPersona()
            return
        }
        
        do {
            // Gather what we have
            let name = userName.isEmpty ? nil : userName
            let goals = functionalGoalsText.isEmpty ? nil : functionalGoalsText
            let styles = communicationStyles.map { $0.rawValue }
            
            // Generate persona with LLM
            let persona = try await llmService.generateFallbackPersona(
                userName: name,
                basicGoals: goals,
                communicationStyles: styles
            )
            
            self.generatedPersona = persona
            
            // Create synthesis output based on what we collected
            let synthesis = LLMGoalSynthesis(
                parsedFunctionalGoals: [],
                goalRelationships: [],
                unifiedStrategy: goals ?? "achieve your fitness goals",
                recommendedTimeline: "Let's take it one step at a time",
                suggestedPersonaMode: nil,
                coachingFocus: determineCoachingFocus(),
                milestones: [],
                expectedChallenges: [],
                motivationalHooks: []
            )
            
            self.synthesizedGoals = synthesis
            
        } catch {
            AppLogger.error("Failed to generate minimal persona: \(error)", category: .app)
            createAbsoluteMinimalPersona()
        }
    }
    
    private func createAbsoluteMinimalPersona() {
        // Absolute last resort - but still uses collected data
        let name = userName.isEmpty ? "there" : userName
        let hasWeightGoal = currentWeight != nil && targetWeight != nil
        let focusArea = hasWeightGoal ? "weight management" : "general fitness"
        
        let voice = VoiceCharacteristics(
            energy: .moderate,
            pace: .natural,
            warmth: .warm,
            vocabulary: .moderate,
            sentenceStructure: .moderate
        )
        
        let interaction = InteractionStyle(
            greetingStyle: "Hey \(name)! Ready to work on your \(focusArea)?",
            closingStyle: "Great progress today!",
            encouragementPhrases: ["Keep it up!", "You're doing great!", "Stay consistent!"],
            acknowledgmentStyle: "Got it. Let's work with that.",
            correctionApproach: "Let's try a different approach",
            humorLevel: .moderate,
            formalityLevel: .casual,
            responseLength: .moderate
        )
        
        let insights = ConversationPersonalityInsights(
            dominantTraits: ["Supportive"],
            communicationStyle: .conversational,
            motivationType: .health,
            energyLevel: .moderate,
            preferredComplexity: .moderate,
            emotionalTone: ["supportive"],
            stressResponse: .needsSupport,
            preferredTimes: ["flexible"],
            extractedAt: Date()
        )
        
        let metadata = PersonaMetadata(
            createdAt: Date(),
            version: "1.0-minimal",
            sourceInsights: insights,
            generationDuration: 0.0,
            tokenCount: 0,
            previewReady: true
        )
        
        self.generatedPersona = PersonaProfile(
            id: UUID(),
            name: "Coach",
            archetype: "AI Fitness Coach",
            systemPrompt: "You are a supportive AI coach helping \(name) with \(focusArea).",
            coreValues: ["Your progress", "Consistency", "Support"],
            backgroundStory: "I'm here to help you succeed.",
            voiceCharacteristics: voice,
            interactionStyle: interaction,
            adaptationRules: [],
            metadata: metadata
        )
        
        self.synthesizedGoals = LLMGoalSynthesis(
            parsedFunctionalGoals: [],
            goalRelationships: [],
            unifiedStrategy: "achieve your \(focusArea) goals",
            recommendedTimeline: "One day at a time",
            suggestedPersonaMode: nil,
            coachingFocus: ["\(focusArea.capitalized)", "Consistency", "Progress"],
            milestones: [],
            expectedChallenges: [],
            motivationalHooks: []
        )
    }
    
    private func determineCoachingFocus() -> [String] {
        var focus: [String] = []
        
        // Add focus based on collected data
        if currentWeight != nil && targetWeight != nil {
            if let current = currentWeight, let target = targetWeight {
                if current > target {
                    focus.append("Weight loss")
                } else if current < target {
                    focus.append("Muscle building")
                } else {
                    focus.append("Weight maintenance")
                }
            }
        }
        
        if !bodyRecompositionGoals.isEmpty {
            focus.append(contentsOf: bodyRecompositionGoals.prefix(2).map { $0.displayName })
        }
        
        if focus.isEmpty {
            focus = ["General fitness", "Healthy habits", "Consistent progress"]
        }
        
        return focus
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