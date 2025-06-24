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
    private let cache: OnboardingCache
    
    private var healthContext: HealthContextSnapshot?
    var conversationHistory: [String] = []
    private var conversationTurnCount = 0
    private var currentUserId: UUID?
    
    // MARK: - Initialization
    
    init(container: DIContainer) async throws {
        self.aiService = try await container.resolve(AIServiceProtocol.self)
        self.contextAssembler = try await container.resolve(ContextAssembler.self)
        self.llmOrchestrator = try await container.resolve(LLMOrchestrator.self)
        self.healthKitProvider = try await container.resolve(HealthKitPrefillProviding.self) as! HealthKitProvider
        self.cache = try await container.resolve(OnboardingCache.self)
        
        // Try to restore previous session
        await restoreSessionIfAvailable()
    }
    
    // MARK: - Public API
    
    /// Check if we have valid API keys
    func hasValidAPIKeys() async -> Bool {
        let configuredProviders = await llmOrchestrator.apiKeyManager.getAllConfiguredProviders()
        return !configuredProviders.isEmpty
    }
    
    /// Start health analysis in background during permission screen
    func startHealthAnalysis() async {
        AppLogger.info("Starting HealthKit authorization request", category: .health)
        
        // Request authorization without artificial timeout - let system handle it
        do {
            _ = try await self.healthKitProvider.requestAuthorization()
            AppLogger.info("HealthKit authorization completed, fetching context", category: .health)
            
            // Fetch health context in background - don't block onboarding
            Task { @MainActor in
                do {
                    if let context = await self.contextAssembler.assembleContext() {
                        self.healthContext = context
                        self.updatePromptsFromHealth(context)
                        await self.generateSmartSuggestions(context)
                        AppLogger.info("Health context loaded successfully", category: .health)
                    } else {
                        AppLogger.info("No health context available, proceeding without it", category: .health)
                    }
                } catch {
                    AppLogger.error("Failed to fetch health context", error: error, category: .health)
                    // Continue without health data - not critical for onboarding
                }
            }
        } catch {
            AppLogger.error("HealthKit authorization failed", error: error, category: .health)
            // Continue without health data - user can connect later
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
        
        // Save session state after each conversation turn
        await saveSessionState()
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
                maxTokens: 2_000
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
        Analyze this user input for fitness coaching context quality.
        
        User said: "\(input)"
        
        Previous conversation:
        \(conversationHistory.dropLast().isEmpty ? "None" : conversationHistory.dropLast().joined(separator: "\n"))
        
        Health data: \(healthSummary)
        
        Return ONLY valid JSON in this exact format (no other text):
        {
          "scores": {
            "goalClarity": 0.5,
            "obstacles": 0.3,
            "exercisePreferences": 0.4,
            "currentState": 0.6,
            "lifestyle": 0.5,
            "nutritionReadiness": 0.3,
            "communicationStyle": 0.4,
            "pastPatterns": 0.2,
            "energyPatterns": 0.3,
            "supportSystem": 0.2
          }
        }
        
        Each score should be 0.0 to 1.0 based on:
        - goalClarity: How specific and measurable are their goals?
        - obstacles: Have they mentioned what blocks them?
        - exercisePreferences: Do we know what activities they enjoy?
        - currentState: Do we know their fitness baseline?
        - lifestyle: Understanding of schedule/commitments?
        - nutritionReadiness: Willingness to track food?
        - communicationStyle: How they prefer to be coached?
        - pastPatterns: What has worked/failed before?
        - energyPatterns: When they feel most energetic?
        - supportSystem: Who helps or hinders them?
        """
        
        do {
            AppLogger.info("Sending context analysis request to AI service", category: .ai)
            let request = AIRequest(
                systemPrompt: "You are a JSON generator. Return ONLY valid JSON, no other text.",
                messages: [AIChatMessage(role: .user, content: prompt)],
                temperature: 0.1,  // Lower temperature for more consistent JSON
                maxTokens: 200,    // Don't need much for JSON response
                stream: false,
                user: "onboarding"
            )
            
            var response = ""
            for try await chunk in aiService.sendRequest(request) {
                if case .text(let text) = chunk { 
                    response = text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Try to extract JSON if there's extra text
            if let jsonStart = response.firstIndex(of: "{"),
               let jsonEnd = response.lastIndex(of: "}") {
                let jsonSubstring = response[jsonStart...jsonEnd]
                if let data = String(jsonSubstring).data(using: .utf8) {
                    parseContextScores(data)
                    return
                }
            }
            
            AppLogger.warning("Could not extract valid JSON from response: \(response.prefix(100))...", category: .ai)
            updateContextHeuristically(input)
        } catch {
            AppLogger.error("AI context analysis failed", error: error, category: .ai)
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
        
        if avgSteps < 3_000 {
            currentPrompt = "I see you're ready to\nstart moving more."
        } else if avgSteps < 6_000 {
            currentPrompt = "Let's take your fitness\nto the next level."
        } else if avgSteps < 10_000 {
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
            let hours = (sleep.totalSleepTime ?? 0) / 3_600
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
        // More intelligent fallback scoring based on conversation analysis
        let lowercased = input.lowercased()
        let allConversation = (conversationHistory + [input]).joined(separator: " ").lowercased()
        
        // Analyze for specific context components
        let goalKeywords = ["lose", "gain", "build", "improve", "pounds", "weight", "muscle", "stronger", "fitter", "healthier"]
        let hasSpecificGoal = goalKeywords.contains { allConversation.contains($0) }
        let hasNumbers = allConversation.contains(where: { $0.isNumber })
        
        let obstacleKeywords = ["can't", "hard", "difficult", "struggle", "fail", "busy", "tired", "stress", "time"]
        let hasObstacles = obstacleKeywords.contains { allConversation.contains($0) }
        
        let exerciseKeywords = ["run", "walk", "gym", "yoga", "swim", "bike", "lift", "cardio", "workout", "exercise"]
        let hasExercisePrefs = exerciseKeywords.contains { allConversation.contains($0) }
        
        let scheduleKeywords = ["morning", "evening", "night", "lunch", "work", "schedule", "time", "day", "week"]
        let hasSchedule = scheduleKeywords.contains { allConversation.contains($0) }
        
        let nutritionKeywords = ["eat", "food", "diet", "meal", "nutrition", "calories", "track", "healthy"]
        let hasNutrition = nutritionKeywords.contains { allConversation.contains($0) }
        
        // Update scores based on conversation content and health data
        contextQuality = ContextComponents(
            goalClarity: hasSpecificGoal && hasNumbers ? 0.7 : (hasSpecificGoal ? 0.4 : 0.2),
            obstacles: hasObstacles ? 0.6 : 0.2,
            exercisePreferences: hasExercisePrefs ? 0.6 : 0.2,
            currentState: healthContext != nil ? 0.8 : (hasExercisePrefs ? 0.4 : 0.2),
            lifestyle: hasSchedule ? 0.6 : (healthContext != nil ? 0.5 : 0.2),
            nutritionReadiness: hasNutrition ? 0.5 : 0.2,
            communicationStyle: allConversation.count > 200 ? 0.6 : 0.3,
            pastPatterns: allConversation.contains("before") || allConversation.contains("used to") ? 0.5 : 0.2,
            energyPatterns: hasSchedule ? 0.4 : 0.2,
            supportSystem: allConversation.contains("friend") || allConversation.contains("family") ? 0.4 : 0.1
        )
        
        AppLogger.info("Heuristic context scores - overall: \(contextQuality.overall)", category: .ai)
    }
    
    private func setDefaultSuggestions() {
        if let health = healthContext {
            let avgSteps = health.activity.steps ?? 0
            
            if avgSteps < 3_000 {
                contextualSuggestions = ["Lose 20 pounds", "Get back in shape", "Start exercising", "Feel more energetic"]
            } else if avgSteps < 10_000 {
                contextualSuggestions = ["Drop 15 pounds", "Build muscle", "Run a 5K", "Get stronger"]
            } else {
                contextualSuggestions = ["Run faster", "Build lean muscle", "Train for marathon", "Optimize recovery"]
            }
        } else {
            contextualSuggestions = ["Lose weight", "Build muscle", "Get healthier", "Start running"]
        }
    }
    
    func createFallbackPlan() -> CoachingPlan {
        // Create a more intelligent fallback based on actual conversation data
        let conversation = conversationHistory.joined(separator: " ").lowercased()
        
        // Analyze conversation for patterns
        let hasWeightGoal = conversation.contains("weight") || conversation.contains("lose") || conversation.contains("pounds")
        let hasMuscleGoal = conversation.contains("muscle") || conversation.contains("strength") || conversation.contains("stronger")
        let hasEnduranceGoal = conversation.contains("run") || conversation.contains("cardio") || conversation.contains("endurance")
        let isBeginner = conversation.contains("beginner") || conversation.contains("new to") || conversation.contains("never")
        let isBusy = conversation.contains("busy") || conversation.contains("time") || conversation.contains("schedule")
        
        // Determine coach personality based on conversation tone
        let needsMotivation = conversation.contains("motivation") || conversation.contains("lazy") || conversation.contains("struggle")
        let prefersSoft = conversation.contains("gentle") || conversation.contains("easy") || conversation.contains("slow")
        
        // Generate personalized elements
        let coachName = needsMotivation ? "Max" : (prefersSoft ? "Sarah" : "Alex")
        let archetype = needsMotivation ? "Motivational Energizer" : (prefersSoft ? "Gentle Guide" : "Balanced Mentor")
        
        let coachingApproach = [
            hasWeightGoal ? "Guide you toward sustainable weight management" : "Help you achieve your fitness goals",
            isBusy ? "Work around your busy schedule with flexible workout plans" : "Create a consistent routine that fits your life",
            needsMotivation ? "Keep you motivated with daily encouragement" : "Support your progress with regular check-ins",
            healthContext != nil ? "Leverage your health data for personalized insights" : "Track your progress and adapt as you grow",
            isBeginner ? "Start with the basics and build gradually" : "Challenge you appropriately based on your level"
        ]
        
        // Build system prompt from conversation insights
        let systemPrompt = """
        You are \(coachName), a \(archetype.lowercased()) focused on helping the user with their fitness journey.
        
        Based on our conversation:
        \(conversationHistory.isEmpty ? "The user is looking for general fitness guidance." : conversationHistory.joined(separator: "\n"))
        
        Key focus areas:
        - \(hasWeightGoal ? "Weight management and healthy habits" : hasMuscleGoal ? "Strength building and muscle development" : "Overall fitness and wellbeing")
        - \(isBusy ? "Time-efficient workouts for busy schedules" : "Consistent routine development")
        - \(needsMotivation ? "High-energy motivation and accountability" : "Supportive guidance and encouragement")
        
        Communication style:
        - \(prefersSoft ? "Gentle and understanding" : needsMotivation ? "Energetic and enthusiastic" : "Balanced and supportive")
        - Focus on progress over perfection
        - Celebrate small wins
        """
        
        return CoachingPlan(
            understandingSummary: buildUnderstandingSummary(),
            coachingApproach: coachingApproach,
            lifeContext: LifeContext(
                workStyle: isBusy ? .high : .moderate,
                fitnessLevel: isBeginner ? .beginner : .intermediate,
                workoutWindowPreference: detectWorkoutPreference()
            ),
            goal: Goal(
                family: hasWeightGoal ? .weightManagement : (hasMuscleGoal ? .strengthMuscle : .healthWellbeing),
                rawText: conversationHistory.joined(separator: " ")
            ),
            engagementPreferences: EngagementPreferences(
                checkInFrequency: needsMotivation ? .daily : .moderate,
                preferredTimes: detectPreferredTimes()
            ),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(
                styles: needsMotivation ? [.motivational, .celebratory] : (prefersSoft ? [.gentle, .encouraging] : [.encouraging, .balanced])
            ),
            timezone: TimeZone.current.identifier,
            generatedPersona: PersonaProfile(
                id: UUID(),
                name: coachName,
                archetype: archetype,
                systemPrompt: systemPrompt,
                coreValues: needsMotivation ? ["energy", "progress", "celebration"] : ["consistency", "balance", "growth"],
                backgroundStory: "I'm here to help you transform your fitness journey into a sustainable lifestyle.",
                voiceCharacteristics: VoiceCharacteristics(
                    energy: needsMotivation ? .high : (prefersSoft ? .calm : .moderate),
                    pace: prefersSoft ? .slow : .natural,
                    warmth: .warm,
                    vocabulary: .moderate,
                    sentenceStructure: .moderate
                ),
                interactionStyle: InteractionStyle(
                    greetingStyle: needsMotivation ? "Hey champion!" : (prefersSoft ? "Hello there" : "Hey!"),
                    closingStyle: needsMotivation ? "Keep crushing it!" : "Keep up the great work!",
                    encouragementPhrases: needsMotivation ? 
                        ["You're unstoppable!", "That's what I'm talking about!", "Champion mode activated!"] :
                        ["You've got this!", "Great progress!", "Well done!"],
                    acknowledgmentStyle: prefersSoft ? "I understand" : "I hear you",
                    correctionApproach: prefersSoft ? "very gentle" : "gentle",
                    humorLevel: needsMotivation ? .medium : .light,
                    formalityLevel: .balanced,
                    responseLength: .moderate
                ),
                adaptationRules: [],
                metadata: PersonaMetadata(
                    createdAt: Date(),
                    version: "1.0-fallback",
                    sourceInsights: ConversationPersonalityInsights(
                        dominantTraits: needsMotivation ? ["energetic", "motivational"] : ["supportive", "balanced"],
                        communicationStyle: .conversational,
                        motivationType: needsMotivation ? .cheerleader : .balanced,
                        energyLevel: needsMotivation ? .high : .moderate,
                        preferredComplexity: .moderate,
                        emotionalTone: ["encouraging", "positive"],
                        stressResponse: .needsSupport,
                        preferredTimes: detectPreferredTimes(),
                        extractedAt: Date()
                    ),
                    generationDuration: 0,
                    tokenCount: 0,
                    previewReady: true
                )
            )
        )
    }
    
    private func buildUnderstandingSummary() -> String {
        let components = [
            contextQuality.goalClarity > 0.5 ? "I understand your fitness goals" : "I'm here to help you clarify your fitness goals",
            healthContext != nil ? "and I've reviewed your health data" : nil,
            contextQuality.obstacles > 0.5 ? "I know what challenges you're facing" : nil,
            "Let's work together to create lasting change."
        ].compactMap { $0 }
        
        return components.joined(separator: ", ") + "."
    }
    
    private func detectWorkoutPreference() -> WorkoutTimePreference {
        let conversation = conversationHistory.joined(separator: " ").lowercased()
        if conversation.contains("morning") { return .morning }
        if conversation.contains("evening") || conversation.contains("night") { return .evening }
        if conversation.contains("lunch") { return .lunchtime }
        return .flexible
    }
    
    private func detectPreferredTimes() -> [String] {
        let conversation = conversationHistory.joined(separator: " ").lowercased()
        var times: [String] = []
        if conversation.contains("morning") { times.append("morning") }
        if conversation.contains("evening") { times.append("evening") }
        if conversation.contains("night") { times.append("night") }
        return times.isEmpty ? ["morning", "evening"] : times
    }
    
    // MARK: - Session Persistence
    
    private func saveSessionState() async {
        // Create or use existing user ID
        if currentUserId == nil {
            currentUserId = UUID()
        }
        
        guard let userId = currentUserId else { return }
        
        // Create conversation data
        let conversationData = ConversationData(
            messages: conversationHistory.enumerated().map { index, message in
                ConversationMessage(
                    role: .user,
                    content: message,
                    timestamp: Date().addingTimeInterval(Double(index * -60)) // Approximate timestamps
                )
            },
            currentNodeId: "onboarding",
            variables: [:]
        )
        
        // Create partial insights if we have enough context
        let insights: PersonalityInsights? = contextQuality.overall > 0.3 ? PersonalityInsights(
            dominantTraits: [],
            communicationStyle: .conversational,
            motivationType: .balanced,
            energyLevel: .moderate,
            preferredComplexity: .moderate,
            emotionalTone: ["supportive"],
            stressResponse: .needsSupport,
            preferredTimes: detectPreferredTimes(),
            extractedAt: Date()
        ) : nil
        
        // Save current state
        await cache.saveSession(
            userId: userId,
            conversationData: conversationData,
            insights: insights,
            currentStep: "conversation-\(conversationTurnCount)",
            responses: []
        )
    }
    
    private func restoreSessionIfAvailable() async {
        // Check for any active sessions
        let activeSessions = await cache.getActiveSessions()
        
        // Use the most recent session if available
        if let (userId, _) = activeSessions.max(by: { $0.value < $1.value }) {
            if let session = await cache.restoreSession(userId: userId) {
                currentUserId = userId
                
                // Restore conversation history
                conversationHistory = session.conversationData.messages.map { $0.content }
                conversationTurnCount = conversationHistory.count
                
                // Restore current prompt based on where we left off
                if conversationTurnCount > 0 {
                    currentPrompt = "Welcome back! Let's continue where we left off."
                    
                    // Re-analyze the last input to restore context quality
                    if let lastInput = conversationHistory.last {
                        await analyzeContextQuality(lastInput)
                    }
                }
                
                AppLogger.info("Restored onboarding session with \(conversationTurnCount) messages", category: .onboarding)
            }
        }
    }
    
    /// Clear session after successful completion
    func clearSession() async {
        if let userId = currentUserId {
            await cache.clearSession(userId: userId)
        }
    }
}
