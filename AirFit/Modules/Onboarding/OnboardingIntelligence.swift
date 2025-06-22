import SwiftUI
import HealthKit

/// Turn-based onboarding intelligence - simple, clean, effective
@MainActor
final class OnboardingIntelligence: ObservableObject {
    // MARK: - Published State
    
    @Published var currentPrompt = "What's your main\nfitness goal?"
    @Published var contextualSuggestions: [String] = []
    @Published var isAnalyzing = false
    @Published var coachingPlan: CoachingPlan?
    @Published var followUpQuestion: String?
    
    // Context quality - the only metric that matters
    @Published var contextQuality = ContextComponents(
        goalClarity: 0,
        obstacles: 0,
        exercisePreferences: 0,
        currentState: 0,
        lifestyle: 0,
        nutritionReadiness: 0,
        communicationStyle: 0,
        pastPatterns: 0,
        energyPatterns: 0,
        supportSystem: 0
    )
    
    // MARK: - Dependencies
    
    private let aiService: AIServiceProtocol
    private let contextAssembler: ContextAssembler
    private let llmOrchestrator: LLMOrchestrator
    private let healthKitProvider: HealthKitProvider
    
    private var healthContext: HealthContextSnapshot?
    private var conversationHistory: [String] = []
    private var conversationTurnCount = 0
    
    // MARK: - Initialization
    
    init(container: DIContainer) async throws {
        self.aiService = try await container.resolve(AIServiceProtocol.self)
        self.contextAssembler = try await container.resolve(ContextAssembler.self)
        self.llmOrchestrator = try await container.resolve(LLMOrchestrator.self)
        self.healthKitProvider = try await container.resolve(HealthKitProvider.self)
    }
    
    // MARK: - Public API
    
    /// Check if we have valid API keys
    func hasValidAPIKeys() async -> Bool {
        let configuredProviders = await llmOrchestrator.apiKeyManager.getAllConfiguredProviders()
        return !configuredProviders.isEmpty
    }
    
    /// Start health analysis in background during permission screen
    func startHealthAnalysis() async {
        do {
            _ = try await healthKitProvider.requestAuthorization()
            healthContext = await contextAssembler.assembleContext()
            
            if let context = healthContext {
                updatePromptsFromHealth(context)
                await generateSmartSuggestions(context)
            }
        } catch {
            // Continue without health data
            AppLogger.error("Health analysis failed", error: error, category: .health)
        }
    }
    
    /// Analyze user input and determine next step
    func analyzeConversation(_ input: String) async {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Add to conversation history
        conversationHistory.append(input)
        conversationTurnCount += 1
        
        // Analyze context quality
        await analyzeContextQuality(input)
        
        // Generate follow-up if needed
        if contextQuality.overall < 0.8 && conversationTurnCount < 10 {
            followUpQuestion = await generateFollowUpQuestion()
        } else {
            // Ready for persona generation
            followUpQuestion = nil
        }
    }
    
    /// Generate final coaching plan when context is sufficient
    func generatePersona() async {
        guard contextQuality.overall >= 0.8 || conversationTurnCount >= 10 else { return }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            let prompt = buildPersonaPrompt()
            
            let response = try await llmOrchestrator.complete(
                prompt: prompt,
                task: .personaSynthesis,
                model: .claude4Opus,
                temperature: 0.7,
                maxTokens: 2000
            )
            
            if let planData = response.content.data(using: .utf8),
               let plan = try? JSONDecoder().decode(CoachingPlan.self, from: planData) {
                self.coachingPlan = plan
            } else {
                self.coachingPlan = createFallbackPlan()
            }
        } catch {
            AppLogger.error("Persona generation failed", error: error, category: .ai)
            self.coachingPlan = createFallbackPlan()
        }
    }
    
    // MARK: - Private Methods
    
    private func analyzeContextQuality(_ input: String) async {
        let healthSummary = buildHealthSummary()
        
        let prompt = """
        User said: "\(input)"
        
        Previous conversation:
        \(conversationHistory.dropLast().isEmpty ? "None" : conversationHistory.dropLast().joined(separator: "\n"))
        
        Health data: \(healthSummary)
        
        Score these context components (0-1):
        - goalClarity: How specific and measurable?
        - obstacles: What's blocking them?
        - exercisePreferences: What they enjoy?
        - currentState: Fitness baseline?
        - lifestyle: Schedule/commitments?
        - nutritionReadiness: Willing to track food?
        - communicationStyle: How they want coaching?
        - pastPatterns: What worked/failed?
        - energyPatterns: When they feel best?
        - supportSystem: Who helps/hinders?
        
        Return JSON with scores and suggested follow-up if overall < 0.8.
        """
        
        do {
            let request = AIRequest(
                systemPrompt: "Analyze fitness coaching context. Return only JSON.",
                messages: [AIChatMessage(role: .user, content: prompt)],
                temperature: 0.3,
                maxTokens: 500,
                stream: false,
                user: "onboarding"
            )
            
            var response = ""
            for try await chunk in aiService.sendRequest(request) {
                if case .text(let text) = chunk { response = text }
            }
            
            if let data = response.data(using: .utf8) {
                parseContextScores(data)
            }
        } catch {
            // Simple fallback scoring
            updateContextHeuristically(input)
        }
    }
    
    private func generateFollowUpQuestion() async -> String? {
        // Find ALL components that need improvement
        var lowComponents = [(String, Double)]() 
        if contextQuality.goalClarity < 0.7 { lowComponents.append(("goals", contextQuality.goalClarity)) }
        if contextQuality.obstacles < 0.7 { lowComponents.append(("obstacles", contextQuality.obstacles)) }
        if contextQuality.exercisePreferences < 0.6 { lowComponents.append(("preferences", contextQuality.exercisePreferences)) }
        if contextQuality.currentState < 0.6 { lowComponents.append(("fitness level", contextQuality.currentState)) }
        if contextQuality.lifestyle < 0.6 { lowComponents.append(("schedule", contextQuality.lifestyle)) }
        if contextQuality.nutritionReadiness < 0.5 { lowComponents.append(("nutrition", contextQuality.nutritionReadiness)) }
        if contextQuality.communicationStyle < 0.5 { lowComponents.append(("coaching style", contextQuality.communicationStyle)) }
        if contextQuality.pastPatterns < 0.5 { lowComponents.append(("past experience", contextQuality.pastPatterns)) }
        
        // Sort by lowest score first
        lowComponents.sort { $0.1 < $1.1 }
        let weakest = lowComponents.first?.0 ?? "goals"
        
        let prompt = """
        The user needs clarity on: \(weakest)
        
        Conversation so far:
        \(conversationHistory.joined(separator: "\n"))
        
        Health data: \(buildHealthSummary())
        
        Generate ONE natural follow-up question to understand their \(weakest).
        Be conversational and specific. 20 words max.
        
        Examples for each category:
        - goals: "How much weight are you hoping to lose, and by when?"
        - obstacles: "What's stopped you from sticking to fitness routines before?"
        - preferences: "What types of exercise do you actually enjoy doing?"
        - fitness level: "How often do you currently work out?"
        - schedule: "When during your day could you realistically exercise?"
        - nutrition: "Are you interested in tracking what you eat?"
        - coaching style: "Do you prefer gentle encouragement or tough love?"
        - past experience: "What's worked well for you in the past?"
        """
        
        do {
            let request = AIRequest(
                systemPrompt: "Generate a natural follow-up question.",
                messages: [AIChatMessage(role: .user, content: prompt)],
                temperature: 0.7,
                maxTokens: 50,
                stream: false,
                user: "onboarding"
            )
            
            var response = ""
            for try await chunk in aiService.sendRequest(request) {
                if case .text(let text) = chunk { response = text }
            }
            
            return response.isEmpty ? nil : response
        } catch {
            return nil
        }
    }
    
    private func updatePromptsFromHealth(_ context: HealthContextSnapshot) {
        let avgSteps = context.activity.steps ?? 0
        
        if avgSteps < 3000 {
            currentPrompt = "I see you're ready to\nstart moving more."
        } else if avgSteps < 6000 {
            currentPrompt = "Let's take your fitness\nto the next level."
        } else if avgSteps < 10000 {
            currentPrompt = "You're already active.\nWhat's next?"
        } else {
            currentPrompt = "You're crushing it.\nHow can I help?"
        }
    }
    
    private func generateSmartSuggestions(_ health: HealthContextSnapshot) async {
        let healthSummary = buildHealthSummary()
        let prompt = """
        Health data: \(healthSummary)
        
        Generate 4-6 relevant fitness goals based on their current state.
        Consider their activity level, recovery status, trends, and overall health.
        2-5 words each, specific and actionable.
        Return as JSON array.
        
        Examples:
        - If low steps: "Walk 8,000 steps daily"
        - If poor sleep: "Improve sleep quality"  
        - If declining weight trend: "Stabilize weight"
        - If well recovered: "Increase workout intensity"
        """
        
        do {
            let request = AIRequest(
                systemPrompt: "Generate fitness goals as JSON array.",
                messages: [AIChatMessage(role: .user, content: prompt)],
                temperature: 0.7,
                maxTokens: 200,
                stream: false,
                user: "onboarding"
            )
            
            var response = ""
            for try await chunk in aiService.sendRequest(request) {
                if case .text(let text) = chunk { response = text }
            }
            
            if let data = response.data(using: .utf8),
               let suggestions = try? JSONDecoder().decode([String].self, from: data) {
                contextualSuggestions = suggestions
            }
        } catch {
            setDefaultSuggestions()
        }
    }
    
    private func buildPersonaPrompt() -> String {
        """
        Create a unique fitness coach persona.
        
        Conversation:
        \(conversationHistory.joined(separator: "\n"))
        
        Health data: \(buildHealthSummary())
        
        Context scores:
        - Goal clarity: \(contextQuality.goalClarity)
        - Obstacles: \(contextQuality.obstacles)
        - Preferences: \(contextQuality.exercisePreferences)
        - Current state: \(contextQuality.currentState)
        - Lifestyle: \(contextQuality.lifestyle)
        
        Generate complete CoachingPlan JSON with:
        1. understandingSummary: 2-3 sentences showing deep understanding
        2. coachingApproach: 5-7 specific points about how you'll help them
        3. generatedPersona: {
           - name: Unique coach name (not generic like "Coach")
           - archetype: Descriptive title (e.g. "The Pragmatic Motivator")
           - systemPrompt: DETAILED 300+ word system prompt that captures:
             * Their specific goals and obstacles
             * Their communication preferences
             * Their lifestyle constraints
             * Specific motivational approaches that will work
             * Personality quirks that make the coach feel real
             * How to adapt based on their energy/mood
           - coreValues: 3-5 values aligned with user needs
           - backgroundStory: Brief coach backstory (2-3 sentences)
           - voiceCharacteristics: Match their energy level
           - interactionStyle: Align with their preferences
        }
        4. Life context, goals, and preferences
        
        The systemPrompt should be rich and detailed for maximum personalization,
        but the understandingSummary should be simple and clear.
        """
    }
    
    private func buildHealthSummary() -> String {
        guard let health = healthContext else { return "No health data" }
        
        var summary = [String]()
        
        // Activity level
        if let steps = health.activity.steps {
            summary.append("Steps: \(steps)/day")
        }
        if let activeEnergy = health.activity.activeEnergyBurned {
            summary.append("Active calories: \(Int(activeEnergy.value))cal")
        }
        if let exerciseMinutes = health.activity.exerciseMinutes {
            summary.append("Exercise: \(exerciseMinutes)min")
        }
        
        // Sleep quality
        if let sleep = health.sleep.lastNight {
            let hours = (sleep.totalSleepTime ?? 0) / 3600
            summary.append("Sleep: \(String(format: "%.1f", hours))h")
            if let efficiency = sleep.efficiency {
                summary.append("Sleep efficiency: \(Int(efficiency))%")
            }
        }
        
        // Heart health
        if let hrv = health.heartHealth.hrv {
            summary.append("HRV: \(Int(hrv.value))ms")
        }
        if let rhr = health.heartHealth.restingHeartRate {
            summary.append("RHR: \(rhr)bpm")
        }
        if let vo2 = health.heartHealth.vo2Max {
            summary.append("VO2Max: \(Int(vo2))")
        }
        
        // Body metrics
        if let weight = health.body.weight {
            summary.append("Weight: \(String(format: "%.1f", weight.converted(to: .pounds).value))lbs")
        }
        if let trend = health.body.weightTrend {
            summary.append("Weight trend: \(trend.rawValue)")
        }
        
        // Workout context
        if let workouts = health.appContext.workoutContext?.recentWorkouts {
            summary.append("Workouts this week: \(workouts.count)")
            if let lastWorkout = workouts.first {
                summary.append("Last workout: \(lastWorkout.type)")
            }
        }
        if let streak = health.appContext.workoutContext?.streakDays {
            summary.append("Streak: \(streak) days")
        }
        
        // Recovery status
        if let recovery = health.appContext.workoutContext?.recoveryStatus {
            summary.append("Recovery: \(recovery.rawValue)")
        }
        
        return summary.isEmpty ? "No health data" : summary.joined(separator: ", ")
    }
    
    private func parseContextScores(_ data: Data) {
        struct Response: Decodable {
            struct Scores: Decodable {
                let goalClarity: Double
                let obstacles: Double
                let exercisePreferences: Double
                let currentState: Double
                let lifestyle: Double
                let nutritionReadiness: Double
                let communicationStyle: Double
                let pastPatterns: Double
                let energyPatterns: Double
                let supportSystem: Double
            }
            let scores: Scores
        }
        
        if let response = try? JSONDecoder().decode(Response.self, from: data) {
            contextQuality = ContextComponents(
                goalClarity: response.scores.goalClarity,
                obstacles: response.scores.obstacles,
                exercisePreferences: response.scores.exercisePreferences,
                currentState: response.scores.currentState,
                lifestyle: response.scores.lifestyle,
                nutritionReadiness: response.scores.nutritionReadiness,
                communicationStyle: response.scores.communicationStyle,
                pastPatterns: response.scores.pastPatterns,
                energyPatterns: response.scores.energyPatterns,
                supportSystem: response.scores.supportSystem
            )
        }
    }
    
    private func updateContextHeuristically(_ input: String) {
        // Simple fallback scoring based on keywords and length
        let words = input.split(separator: " ").count
        let hasNumbers = input.contains(where: { $0.isNumber })
        let hasGoalKeywords = ["lose", "gain", "build", "improve"].contains { 
            input.lowercased().contains($0) 
        }
        
        contextQuality = ContextComponents(
            goalClarity: hasGoalKeywords && hasNumbers ? 0.8 : 0.3,
            obstacles: healthContext != nil ? 0.6 : 0.2,
            exercisePreferences: 0.3,
            currentState: healthContext != nil ? 0.8 : 0.2,
            lifestyle: healthContext != nil ? 0.6 : 0.2,
            nutritionReadiness: 0.2,
            communicationStyle: words > 20 ? 0.6 : 0.3,
            pastPatterns: 0.2,
            energyPatterns: 0.2,
            supportSystem: 0.1
        )
    }
    
    private func setDefaultSuggestions() {
        if let health = healthContext {
            let avgSteps = health.activity.steps ?? 0
            
            if avgSteps < 3000 {
                contextualSuggestions = ["Lose 20 pounds", "Get back in shape", "Start exercising", "Feel more energetic"]
            } else if avgSteps < 10000 {
                contextualSuggestions = ["Drop 15 pounds", "Build muscle", "Run a 5K", "Get stronger"]
            } else {
                contextualSuggestions = ["Run faster", "Build lean muscle", "Train for marathon", "Optimize recovery"]
            }
        } else {
            contextualSuggestions = ["Lose weight", "Build muscle", "Get healthier", "Start running"]
        }
    }
    
    private func createFallbackPlan() -> CoachingPlan {
        // Minimal viable coaching plan if AI fails
        CoachingPlan(
            understandingSummary: "I'll help you improve your fitness with a personalized approach.",
            coachingApproach: [
                "Focus on sustainable habits",
                "Daily check-ins to keep you motivated",
                "Adapt to your schedule and energy"
            ],
            lifeContext: LifeContext(
                workStyle: .moderate,
                fitnessLevel: .intermediate,
                workoutWindowPreference: .morning
            ),
            goal: Goal(
                family: .healthWellbeing,
                rawText: conversationHistory.joined(separator: " ")
            ),
            engagementPreferences: EngagementPreferences(
                checkInFrequency: .daily,
                preferredTimes: ["morning", "evening"]
            ),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(styles: [.encouraging]),
            timezone: TimeZone.current.identifier,
            generatedPersona: PersonaProfile(
                id: UUID(),
                name: "Coach",
                archetype: "Supportive Guide",
                systemPrompt: "You are a supportive fitness coach focused on sustainable progress.",
                coreValues: ["consistency", "progress", "balance"],
                backgroundStory: "I'm here to help you achieve lasting fitness success.",
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
                    encouragementPhrases: ["You've got this!", "Great progress!"],
                    acknowledgmentStyle: "I hear you",
                    correctionApproach: "gentle",
                    humorLevel: .light,
                    formalityLevel: .balanced,
                    responseLength: .moderate
                ),
                adaptationRules: [],
                metadata: PersonaMetadata(
                    createdAt: Date(),
                    version: "1.0",
                    sourceInsights: ConversationPersonalityInsights(
                        dominantTraits: ["supportive"],
                        communicationStyle: .conversational,
                        motivationType: .balanced,
                        energyLevel: .moderate,
                        preferredComplexity: .moderate,
                        emotionalTone: ["encouraging"],
                        stressResponse: .needsSupport,
                        preferredTimes: ["morning", "evening"],
                        extractedAt: Date()
                    ),
                    generationDuration: 0,
                    tokenCount: 0,
                    previewReady: true
                )
            )
        )
    }
}