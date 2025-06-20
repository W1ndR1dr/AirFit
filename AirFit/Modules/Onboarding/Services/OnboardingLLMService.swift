import Foundation

/// Central service for all LLM interactions during onboarding
/// Replaces hardcoded logic with intelligent, context-aware responses
actor OnboardingLLMService: ServiceProtocol {
    
    // MARK: - Types
    
    struct ScreenContent: Codable, Sendable {
        let mainPrompt: String
        let placeholderText: String?
        let suggestedDefaults: [String]?
        let encouragementMessage: String?
    }
    
    struct InterpretedInput: Codable, Sendable {
        let parsedMeaning: String
        let suggestedGoals: [String]?
        let identifiedConstraints: [String]?
        let followUpQuestions: [String]?
    }
    
    enum LLMRequestType {
        case generatePrompt(for: OnboardingScreen)
        case suggestDefaults(for: OnboardingScreen)
        case interpretResponse(text: String, context: OnboardingScreen)
        case synthesizePersona
    }
    
    // MARK: - Properties
    
    private let llmOrchestrator: LLMOrchestrator
    private let healthKitManager: HealthKitManager
    
    // MARK: - Initialization
    
    init(llmOrchestrator: LLMOrchestrator, healthKitManager: HealthKitManager) {
        self.llmOrchestrator = llmOrchestrator
        self.healthKitManager = healthKitManager
    }
    
    // MARK: - ServiceProtocol
    
    private var configured = false
    
    nonisolated var isConfigured: Bool { 
        // Since we don't need configuration, always return true
        true 
    }
    
    nonisolated var serviceIdentifier: String { "OnboardingLLMService" }
    
    func configure() async throws {
        configured = true
    }
    
    func reset() async {
        configured = false
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: ["service": "OnboardingLLMService"]
        )
    }
    
    // MARK: - Public Methods
    
    /// Generate dynamic content for any onboarding screen based on full context
    func generateScreenContent(
        for screen: OnboardingScreen,
        userId: UUID,
        previousResponses: [String: Any]
    ) async throws -> ScreenContent {
        let context = try await buildContext(userId: userId, previousResponses: previousResponses)
        
        let prompt = buildPromptForScreen(screen, context: context)
        
        let response = try await llmOrchestrator.complete(
            prompt: prompt,
            task: .quickResponse,
            model: nil
        )
        
        return try parseScreenContent(from: response.content, screen: screen)
    }
    
    /// Interpret user's free-text input with full context awareness
    func interpretUserInput(
        _ input: String,
        screen: OnboardingScreen,
        userId: UUID,
        previousResponses: [String: Any]
    ) async throws -> InterpretedInput {
        let context = try await buildContext(userId: userId, previousResponses: previousResponses)
        
        let prompt = """
        User is on the \(screen) screen of fitness app onboarding.
        
        Their input: "\(input)"
        
        Context:
        \(context)
        
        Interpret their input and provide:
        1. What they mean in plain language
        2. Any specific goals mentioned
        3. Life constraints you identify
        4. Follow-up questions if needed
        
        Return as JSON:
        {
            "parsedMeaning": "string",
            "suggestedGoals": ["string"],
            "identifiedConstraints": ["string"],
            "followUpQuestions": ["string"]
        }
        """
        
        let response = try await llmOrchestrator.complete(
            prompt: prompt,
            task: .quickResponse,
            model: nil
        )
        
        return try parseInterpretedInput(from: response.content)
    }
    
    /// Generate smart defaults based on comprehensive user understanding
    func generateSmartDefaults(
        for screen: OnboardingScreen,
        userId: UUID,
        previousResponses: [String: Any]
    ) async throws -> [String] {
        let context = try await buildContext(userId: userId, previousResponses: previousResponses)
        
        let prompt = """
        Based on this user's profile, suggest smart defaults for \(screen):
        
        Context:
        \(context)
        
        Return 2-4 options that would resonate with this specific person.
        Consider their health data patterns, life situation, and goals.
        
        Return as JSON array: ["option1", "option2", ...]
        """
        
        let response = try await llmOrchestrator.complete(
            prompt: prompt,
            task: .quickResponse,
            model: nil
        )
        
        return try parseStringArray(from: response.content)
    }
    
    // MARK: - Private Methods
    
    private func buildContext(userId: UUID, previousResponses: [String: Any]) async throws -> String {
        // Gather all available context
        var context = "Health Data:\n"
        
        // Fetch available health metrics
        if let activityMetrics = try? await healthKitManager.fetchTodayActivityMetrics() {
            if let steps = activityMetrics.steps {
                context += "- Daily steps: \(steps)\n"
            }
            if let activeEnergy = activityMetrics.activeEnergyBurned {
                context += "- Active calories: \(Int(activeEnergy.converted(to: .kilocalories).value))\n"
            }
            if let exerciseMinutes = activityMetrics.exerciseMinutes {
                context += "- Exercise minutes: \(exerciseMinutes)\n"
            }
        }
        
        if let bodyMetrics = try? await healthKitManager.fetchLatestBodyMetrics() {
            if let weight = bodyMetrics.weight {
                let weightInPounds = weight.converted(to: .pounds).value
                context += "- Weight: \(Int(weightInPounds)) lbs\n"
            }
            if let bmi = bodyMetrics.bmi {
                context += "- BMI: \(String(format: "%.1f", bmi))\n"
            }
        }
        
        // Add previous responses
        context += "\nPrevious responses:\n"
        for (key, value) in previousResponses {
            context += "- \(key): \(value)\n"
        }
        
        return context
    }
    
    private func buildPromptForScreen(_ screen: OnboardingScreen, context: String) -> String {
        switch screen {
        case .lifeContext:
            return """
            Analyze this user's health data and generate a conversational,
            insightful prompt to understand their lifestyle.
            
            \(context)
            
            Requirements:
            - Sound like a knowledgeable friend noticing patterns
            - Be specific to what you see in their data
            - Invite them to share context
            - Max 2 sentences
            - Return as JSON: {"mainPrompt": "your prompt", "placeholderText": "example response"}
            """
            
        case .goals:
            return """
            Based on this user's health data and life context,
            generate a personalized prompt for goal setting.
            
            \(context)
            
            Requirements:
            - Reference something specific from their data or context
            - Encourage them to think broadly
            - Suggest a relevant placeholder based on their patterns
            - Return as JSON: {"mainPrompt": "your prompt", "placeholderText": "example", "suggestedDefaults": ["goal1", "goal2"]}
            """
            
        case .weightObjectives:
            return """
            Create an encouraging prompt for weight objectives based on their current state.
            
            \(context)
            
            Requirements:
            - If weight data exists, reference it naturally
            - Be supportive regardless of their starting point
            - Avoid assumptions about direction (lose/gain/maintain)
            - Return as JSON: {"mainPrompt": "your prompt", "encouragementMessage": "supportive message"}
            """
            
        case .bodyComposition:
            return """
            Suggest relevant body composition goals based on their profile.
            
            \(context)
            
            Requirements:
            - Consider their stated goals and current fitness level
            - Pre-select 1-2 options that make sense
            - Avoid overwhelming with too many suggestions
            - Return as JSON: {"mainPrompt": "your prompt", "suggestedDefaults": ["goal1", "goal2"]}
            """
            
        case .communicationStyle:
            return """
            Based on their personality evident in responses and health patterns,
            suggest communication styles that would resonate.
            
            \(context)
            
            Requirements:
            - Consider their goals and life situation
            - Suggest 2-3 styles that complement each other
            - Think about their apparent personality
            - Return as JSON: {"mainPrompt": "your prompt", "suggestedDefaults": ["style1", "style2", "style3"]}
            """
            
        default:
            return """
            Generate appropriate content for \(screen) screen.
            
            \(context)
            
            Return as JSON: {"mainPrompt": "your prompt"}
            """
        }
    }
    
    private func parseScreenContent(from json: String, screen: OnboardingScreen) throws -> ScreenContent {
        guard let data = json.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let mainPrompt = parsed["mainPrompt"] as? String else {
            // Fallback content if parsing fails
            return ScreenContent(
                mainPrompt: getFallbackPrompt(for: screen),
                placeholderText: nil,
                suggestedDefaults: nil,
                encouragementMessage: nil
            )
        }
        
        return ScreenContent(
            mainPrompt: mainPrompt,
            placeholderText: parsed["placeholderText"] as? String,
            suggestedDefaults: parsed["suggestedDefaults"] as? [String],
            encouragementMessage: parsed["encouragementMessage"] as? String
        )
    }
    
    private func parseInterpretedInput(from json: String) throws -> InterpretedInput {
        guard let data = json.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError.llm("Failed to parse LLM response")
        }
        
        return InterpretedInput(
            parsedMeaning: parsed["parsedMeaning"] as? String ?? "",
            suggestedGoals: parsed["suggestedGoals"] as? [String],
            identifiedConstraints: parsed["identifiedConstraints"] as? [String],
            followUpQuestions: parsed["followUpQuestions"] as? [String]
        )
    }
    
    private func parseStringArray(from json: String) throws -> [String] {
        guard let data = json.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return [] // Return empty array as fallback
        }
        return parsed
    }
    
    private func getFallbackPrompt(for screen: OnboardingScreen) -> String {
        // Friendly fallback prompts if LLM fails
        switch screen {
        case .lifeContext:
            return "Tell me a bit about your daily life - work, family, whatever shapes your routine..."
        case .goals:
            return "What are you hoping to accomplish? Dream big - I'm here to help!"
        case .weightObjectives:
            return "Let's talk about your weight goals (if you have any)"
        case .bodyComposition:
            return "Any specific body composition goals in mind?"
        case .communicationStyle:
            return "How can I best support you? Pick whatever feels right..."
        default:
            return "Let's continue setting up your personalized coach"
        }
    }
}

// MARK: - OnboardingScreen Extension

extension OnboardingScreen: CustomStringConvertible {
    public var description: String {
        switch self {
        case .opening: return "opening"
        case .healthKit: return "health data"
        case .lifeContext: return "life context"
        case .goals: return "goals"
        case .weightObjectives: return "weight objectives"
        case .bodyComposition: return "body composition"
        case .communicationStyle: return "communication style"
        case .synthesis: return "synthesis"
        case .coachReady: return "completion"
        }
    }
}