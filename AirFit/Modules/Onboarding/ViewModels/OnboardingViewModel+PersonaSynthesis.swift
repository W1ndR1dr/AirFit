import Foundation

// MARK: - Persona Synthesis
extension OnboardingViewModel {
    
    func synthesizePersona() async {
        currentScreen = .synthesis
        isLoading = true
        error = nil
        
        do {
            // Create weight objective
            let weightObjective = WeightObjective(
                currentWeight: currentWeight,
                targetWeight: targetWeight,
                timeframe: nil
            )
            
            // Build raw data for synthesis
            let rawData = OnboardingRawData(
                userName: userName.isEmpty ? "Friend" : userName,
                lifeContextText: lifeContext,
                weightObjective: weightObjective,
                bodyRecompositionGoals: bodyRecompositionGoals,
                functionalGoalsText: functionalGoalsText,
                communicationStyles: communicationStyles,
                informationPreferences: informationPreferences,
                healthKitData: healthKitData,
                manualHealthData: nil
            )
            
            // Synthesize goals with LLM
            synthesizedGoals = try await onboardingService.synthesizeGoals(from: rawData)
            
            // Check for cancellation
            try Task.checkCancellation()
            
            // Generate persona
            guard let userId = await userService.getCurrentUserId() else {
                throw AppError.authentication("No user ID found")
            }
            
            let session = ConversationSession(
                userId: userId,
                startedAt: Date()
            )
            session.responses = createResponsesFromData(rawData)
            
            generatedPersona = try await personaService.generatePersona(from: session)
            
            // Check for cancellation before showing results
            try Task.checkCancellation()
            
            // Show coach ready screen
            currentScreen = .coachReady
            
        } catch {
            // Don't show error for cancellations
            if !(error is CancellationError) {
                self.error = error as? AppError ?? .unknown(message: error.localizedDescription)
                isShowingError = true
            }
        }
        
        isLoading = false
    }
    
    func createResponsesFromData(_ data: OnboardingRawData) -> [ConversationResponse] {
        var responses: [ConversationResponse] = []
        let sessionId = UUID()
        
        // Helper to create response
        func addResponse(nodeId: String, value: ResponseValue) {
            let response = ConversationResponse(
                sessionId: sessionId,
                nodeId: nodeId,
                responseData: try! JSONEncoder().encode(value)
            )
            responses.append(response)
        }
        
        // Add responses
        addResponse(nodeId: "userName", value: .text(data.userName))
        addResponse(nodeId: "lifeContext", value: .text(data.lifeContextText))
        addResponse(nodeId: "functionalGoals", value: .text(data.functionalGoalsText))
        
        if let weight = data.weightObjective {
            if let current = weight.currentWeight {
                addResponse(nodeId: "currentWeight", value: .text("\(current)"))
            }
            if let target = weight.targetWeight {
                addResponse(nodeId: "targetWeight", value: .text("\(target)"))
            }
        }
        
        addResponse(nodeId: "bodyGoals", value: .multiChoice(data.bodyRecompositionGoals.map(\.rawValue)))
        addResponse(nodeId: "communicationStyles", value: .multiChoice(data.communicationStyles.map(\.rawValue)))
        addResponse(nodeId: "informationPreferences", value: .multiChoice(data.informationPreferences.map(\.rawValue)))
        
        return responses
    }
}