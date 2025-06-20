import Foundation

// MARK: - LLM Integration
extension OnboardingViewModel {
    
    // MARK: - Types
    
    /// Sendable container for previous responses
    struct PreviousResponses: Sendable {
        let name: String?
        let lifeContext: String?
        let currentWeight: Double?
        let targetWeight: Double?
        let bodyGoals: [String]?
        let functionalGoals: String?
        let communicationStyles: [String]?
        let informationPreferences: [String]?
        
        var asDictionary: [String: Any] {
            var dict: [String: Any] = [:]
            if let name = name { dict["name"] = name }
            if let lifeContext = lifeContext { dict["lifeContext"] = lifeContext }
            if let currentWeight = currentWeight { dict["currentWeight"] = currentWeight }
            if let targetWeight = targetWeight { dict["targetWeight"] = targetWeight }
            if let bodyGoals = bodyGoals { dict["bodyGoals"] = bodyGoals }
            if let functionalGoals = functionalGoals { dict["functionalGoals"] = functionalGoals }
            if let communicationStyles = communicationStyles { dict["communicationStyles"] = communicationStyles }
            if let informationPreferences = informationPreferences { dict["informationPreferences"] = informationPreferences }
            return dict
        }
    }
    
    // MARK: - Dynamic Content Generation
    
    /// Get LLM-generated prompt for the current screen
    @MainActor
    func getLLMPrompt(for screen: OnboardingScreen) async -> String {
        guard let llmService = onboardingLLMService else {
            // Fallback to friendly defaults if LLM service unavailable
            return getFallbackPrompt(for: screen)
        }
        
        do {
            guard let userId = await userService.getCurrentUserId() else {
                return getFallbackPrompt(for: screen)
            }
            let previousResponses = collectPreviousResponses()
            
            let content = try await llmService.generateScreenContent(
                for: screen,
                userId: userId,
                previousResponses: previousResponses.asDictionary
            )
            
            return content.mainPrompt
        } catch {
            AppLogger.error("Failed to get LLM prompt: \(error)", category: .app)
            return getFallbackPrompt(for: screen)
        }
    }
    
    /// Get LLM-generated placeholder text
    @MainActor
    func getLLMPlaceholder(for screen: OnboardingScreen) async -> String? {
        guard let llmService = onboardingLLMService else {
            return getFallbackPlaceholder(for: screen)
        }
        
        do {
            guard let userId = await userService.getCurrentUserId() else {
                return getFallbackPlaceholder(for: screen)
            }
            let previousResponses = collectPreviousResponses()
            
            let content = try await llmService.generateScreenContent(
                for: screen,
                userId: userId,
                previousResponses: previousResponses.asDictionary
            )
            
            return content.placeholderText
        } catch {
            return getFallbackPlaceholder(for: screen)
        }
    }
    
    /// Get LLM-suggested defaults for multi-select screens
    @MainActor
    func getLLMDefaults(for screen: OnboardingScreen) async -> [String] {
        guard let llmService = onboardingLLMService else {
            return []
        }
        
        do {
            guard let userId = await userService.getCurrentUserId() else {
                return []
            }
            
            let responses = collectPreviousResponses()
            return try await llmService.generateSmartDefaults(
                for: screen,
                userId: userId,
                previousResponses: responses.asDictionary
            )
        } catch {
            AppLogger.error("Failed to get LLM defaults: \(error)", category: .app)
            return []
        }
    }
    
    /// Process user's free text input through LLM
    @MainActor
    func interpretUserInput(_ input: String, for screen: OnboardingScreen) async -> String? {
        guard let llmService = onboardingLLMService else {
            return nil
        }
        
        do {
            guard let userId = await userService.getCurrentUserId() else {
                return nil
            }
            
            let responses = collectPreviousResponses()
            let interpretation = try await llmService.interpretUserInput(
                input,
                screen: screen,
                userId: userId,
                previousResponses: responses.asDictionary
            )
            
            // Store any identified goals or constraints
            if let goals = interpretation.suggestedGoals {
                // These could be used to pre-populate the goals screen
                AppLogger.info("LLM identified goals: \(goals)", category: .app)
            }
            
            return interpretation.parsedMeaning
        } catch {
            AppLogger.error("Failed to interpret user input: \(error)", category: .app)
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func collectPreviousResponses() -> PreviousResponses {
        PreviousResponses(
            name: userName.isEmpty ? nil : userName,
            lifeContext: lifeContext.isEmpty ? nil : lifeContext,
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            bodyGoals: bodyRecompositionGoals.isEmpty ? nil : bodyRecompositionGoals.map { $0.rawValue },
            functionalGoals: functionalGoalsText.isEmpty ? nil : functionalGoalsText,
            communicationStyles: communicationStyles.isEmpty ? nil : communicationStyles.map { $0.rawValue },
            informationPreferences: informationPreferences.isEmpty ? nil : informationPreferences.map { $0.rawValue }
        )
    }
    
    // MARK: - Fallback Content
    
    private func getFallbackPrompt(for screen: OnboardingScreen) -> String {
        switch screen {
        case .lifeContext:
            return "Tell me a bit about your daily life - work, family, whatever shapes your routine..."
        case .goals:
            return "What are you hoping to accomplish?"
        case .weightObjectives:
            return "Let's talk about your weight goals (if you have any)"
        case .bodyComposition:
            return "Any specific body composition goals in mind?"
        case .communicationStyle:
            return "How can I best support you?"
        default:
            return "Let's continue setting up your personalized coach"
        }
    }
    
    private func getFallbackPlaceholder(for screen: OnboardingScreen) -> String? {
        switch screen {
        case .lifeContext:
            return "Like: I'm a desk warrior with two kids, or I travel constantly for work..."
        case .goals:
            return "I want to get stronger and have more energy..."
        default:
            return nil
        }
    }
}