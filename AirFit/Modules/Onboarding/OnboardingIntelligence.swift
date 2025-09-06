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
    @Published var extractedInsights: ExtractedInsights?
    @Published var personaSynthesisProgress: PersonaSynthesisProgress?
    @Published var isLoadingHealthData = false
    @Published var healthDataProgress: Double = 0.0
    @Published var healthDataStatus = ""

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
    private let healthKitProvider: HealthKitProvider
    private let cache: OnboardingCache
    private let personaSynthesizer: PersonaSynthesizer

    private var healthContext: HealthContextSnapshot?
    var conversationHistory: [String] = []
    private var conversationTurnCount = 0
    private var currentUserId: UUID?
    private var conversationVariables: [String: String] = [:]

    // Model selection for persona synthesis
    @Published var selectedModel: LLMModel?

    // MARK: - Public Methods

    /// Set the preferred model for persona generation based on user selection
    func setPreferredModel(provider: AIProvider, modelId: String) {
        // Map provider and model ID to LLMModel enum
        switch provider {
        case .anthropic:
            if modelId.contains("opus") {
                selectedModel = .claude4Opus
            } else if modelId.contains("sonnet") {
                selectedModel = .claude4Sonnet
            }
        // Note: No Haiku in Claude 4 series yet

        case .openAI:
            if modelId.contains("gpt-5") && !modelId.contains("mini") {
                selectedModel = .gpt5
            } else if modelId.contains("gpt-5-mini") {
                selectedModel = .gpt5Mini
            }

        case .gemini:
            if modelId.contains("2.5-flash-thinking") || modelId.contains("thinking") {
                selectedModel = .gemini25FlashThinking
            } else if modelId.contains("2.5-pro") || modelId.contains("1.5-pro") {
                selectedModel = .gemini25Pro
            } else if modelId.contains("2.5-flash") || modelId.contains("1.5-flash") {
                selectedModel = .gemini25Flash
            }
        // Note: 2.0 models map to 2.5 equivalents
        }

        if let model = selectedModel {
            AppLogger.info("Set preferred model for persona generation: \(model.identifier)", category: .onboarding)
        }
    }

    // MARK: - Initialization

    init(
        aiService: AIServiceProtocol,
        contextAssembler: ContextAssembler,
        healthKitProvider: HealthKitProvider,
        cache: OnboardingCache,
        personaSynthesizer: PersonaSynthesizer
    ) {
        self.aiService = aiService
        self.contextAssembler = contextAssembler
        self.healthKitProvider = healthKitProvider
        self.cache = cache
        self.personaSynthesizer = personaSynthesizer
        
        // Validate services in background (non-blocking)
        validateServicesInBackground()
    }

    /// Validate services asynchronously (non-blocking)
    private func validateServicesInBackground() {
        Task {
            do {
                // Check API keys
                let hasKeys = await hasValidAPIKeys()
                if !hasKeys {
                    AppLogger.warning("AI services not properly configured", category: .onboarding)
                    // Don't throw - let user continue with limited functionality
                }
                
                // Validate configuration (but don't block UI)
                let isValid = try await aiService.validateConfiguration()
                if !isValid {
                    AppLogger.warning("AI service configuration invalid", category: .onboarding)
                }
                
                // Check health in background
                let health = await aiService.checkHealth()
                if health.status != .healthy {
                    AppLogger.warning("AI service unhealthy: \(health.status)", category: .onboarding)
                }
            } catch {
                AppLogger.error("Service validation failed", error: error, category: .onboarding)
                // Don't crash - continue with degraded functionality
            }
        }
        
        // Restore session if available
        Task { @MainActor in
            await restoreSessionIfAvailable()
        }
    }

    // MARK: - Public API

    /// Check if we have valid API keys
    func hasValidAPIKeys() async -> Bool {
        // Check if AI service is configured
        return (try? await aiService.validateConfiguration()) ?? false
    }

    /// Start health analysis - simplified without detached task
    func startHealthAnalysis() async {
        AppLogger.info("Starting HealthKit authorization request", category: .health)
        
        // Ensure AI service is configured before proceeding
        let isConfigured = await hasValidAPIKeys()
        guard isConfigured else {
            AppLogger.error("AI service not configured, cannot proceed with health analysis", category: .health)
            healthDataStatus = "AI service not configured"
            healthDataProgress = 0.0
            isLoadingHealthData = false
            return
        }
        
        // Show loading state
        isLoadingHealthData = true
        healthDataProgress = 0.0
        healthDataStatus = "Requesting permission..."
        
        do {
            // Simple, direct authorization request - let HealthKit handle the UI
            let authorized = try await healthKitProvider.requestAuthorization()
            AppLogger.info("HealthKit authorization completed: \(authorized)", category: .health)
            
            healthDataProgress = 0.2
            healthDataStatus = "Loading activity data..."
            
            if authorized {
                // Load health data in background
                Task {
                    // Create progress reporter
                    let progressReporter = HealthDataLoadingProgressReporter()
                    let progressStream = await progressReporter.makeProgressStream()
                    
                    // Start monitoring progress
                    Task {
                        for await progress in progressStream {
                            await MainActor.run {
                                healthDataProgress = progress.progress
                                healthDataStatus = progress.message
                            }
                            
                            if let error = progress.error {
                                AppLogger.error("Health data loading error at stage \(progress.stage)", error: error, category: .health)
                            }
                            
                            // Check if we've completed
                            if progress.stage == .complete {
                                AppLogger.info("Health data loading completed with progress: \(progress.progress)", category: .health)
                            }
                        }
                    }
                    
                    // Load context with real progress reporting
                    let context = await contextAssembler.assembleContext(
                        forceRefresh: false,
                        progressReporter: progressReporter
                    )
                    
                    healthContext = context
                    updatePromptsFromHealth(context)
                    await generateSmartSuggestions(context)
                    
                    AppLogger.info("Health context loaded successfully", category: .health)
                    
                    // Ensure progress reaches 100%
                    await MainActor.run {
                        healthDataProgress = 1.0
                        healthDataStatus = "Complete!"
                        isLoadingHealthData = false
                    }
                }
            } else {
                healthDataStatus = "Permission denied"
                healthDataProgress = 0.0
                
                // Hide loading immediately - no artificial delay
                isLoadingHealthData = false
            }
        } catch {
            AppLogger.error("HealthKit authorization failed", error: error, category: .health)
            healthDataStatus = "Authorization failed"
            healthDataProgress = 0.0
            
            // Hide loading immediately on error
            isLoadingHealthData = false
        }
    }

    /// Store profile data from ProfileSetupView
    func addProfileData(birthDate: Date, biologicalSex: String) {
        // Store in conversation variables for later use
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        conversationVariables["birthDate"] = formatter.string(from: birthDate)
        conversationVariables["biologicalSex"] = biologicalSex

        // Add to conversation history for context
        conversationHistory.append("My biological sex is \(biologicalSex)")
        
        // Limit conversation history to prevent memory growth
        if conversationHistory.count > 20 {
            conversationHistory.removeFirst()
        }

        AppLogger.info("Profile data stored: sex=\(biologicalSex), age calculated from birthDate", category: .onboarding)
    }

    /// Get stored profile data
    func getProfileData() -> (birthDate: Date?, biologicalSex: String?) {
        var birthDate: Date?
        var biologicalSex: String?

        if let birthDateString = conversationVariables["birthDate"] {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            birthDate = formatter.date(from: birthDateString)
        }

        if let sex = conversationVariables["biologicalSex"] {
            biologicalSex = sex
        }

        return (birthDate, biologicalSex)
    }

    /// Analyze user input and determine next step
    func analyzeConversation(_ input: String) async {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isAnalyzing = true
        defer { isAnalyzing = false }

        // Add to conversation history
        conversationHistory.append(input)
        conversationTurnCount += 1
        
        // Limit conversation history to prevent memory growth
        if conversationHistory.count > 20 {
            conversationHistory.removeFirst()
        }

        // Analyze context quality
        await analyzeContextQuality(input)

        // Extract insights for confirmation
        extractInsightsFromConversation()

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
            // Create conversation data for persona synthesis
            let conversationData = ConversationData(
                messages: conversationHistory.map { message in
                    ConversationMessage(
                        role: .user,
                        content: message,
                        timestamp: Date()
                    )
                },
                variables: [
                    "primary_goal": extractGoal(from: conversationHistory),
                    "obstacles": extractObstacles(from: conversationHistory),
                    "userName": extractUserName(from: conversationHistory) ?? "there"
                ]
            )

            // Convert context quality to personality insights
            let insights = ConversationPersonalityInsights(
                dominantTraits: extractDominantTraits(),
                communicationStyle: detectCommunicationStyle(),
                motivationType: detectConversationMotivationType(),
                energyLevel: detectConversationEnergyLevel(),
                preferredComplexity: .moderate,
                emotionalTone: ["supportive", "encouraging"],
                stressResponse: .needsSupport,
                preferredTimes: detectPreferredTimes(),
                extractedAt: Date()
            )

            // Determine best model if not already selected
            if selectedModel == nil {
                selectedModel = await personaSynthesizer.getBestAvailableModel()
            }

            // Create progress stream
            let progressStream = await personaSynthesizer.createProgressStream()

            // Start monitoring progress in background
            Task {
                for await progress in progressStream {
                    // Update published property on main thread
                    await MainActor.run {
                        self.personaSynthesisProgress = progress
                    }
                }
            }

            // Generate high-quality persona
            let persona = try await personaSynthesizer.synthesizePersona(
                from: conversationData,
                insights: insights,
                preferredModel: selectedModel
            )

            // Create coaching plan with the generated persona
            self.coachingPlan = createCoachingPlan(with: persona, conversationData: conversationData)

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
        - currentState: Do we know their fitness baseline? (Consider both conversation AND richness of health data)
        - lifestyle: Understanding of schedule/commitments?
        - nutritionReadiness: Willingness to track food?
        - communicationStyle: How they prefer to be coached?
        - pastPatterns: What has worked/failed before?
        - energyPatterns: When they feel most energetic?
        - supportSystem: Who helps or hinders them?

        For currentState: If health data is "No health data" or minimal, rely more on conversation.
        Rich health data (steps, sleep, weight, etc.) provides higher confidence.
        """

        do {
            AppLogger.info("Sending context analysis request to AI service", category: .ai)
            let request = AIRequest(
                systemPrompt: "You are a JSON generator. Return ONLY valid JSON, no other text.",
                messages: [AIChatMessage(role: .user, content: prompt)],
                temperature: 0.1,  // Lower temperature for more consistent JSON
                maxTokens: 200,    // Don't need much for JSON response
                stream: false,
                user: "onboarding",
                timeout: 15.0  // 15 second timeout for analysis
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
                user: "onboarding",
                timeout: 10.0  // 10 second timeout for follow-up
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
                user: "onboarding",
                timeout: 10.0  // 10 second timeout for suggestions
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
        Create a unique fitness coach persona based on this conversation.

        Conversation:
        \(conversationHistory.joined(separator: "\n"))

        Health data: \(buildHealthSummary())

        Generate a JSON response with YOUR OWN values based on the conversation.
        Return ONLY valid JSON matching this exact structure (the values shown are examples):
        {
          "understandingSummary": "[YOUR 2-3 sentences showing understanding]",
          "coachingApproach": ["[YOUR point 1]", "[YOUR point 2]", "[YOUR point 3]", "[YOUR point 4]", "[YOUR point 5]"],
          "lifeContext": {
            "workStyle": "[CHOOSE: sedentary, moderate, active, very_active]",
            "fitnessLevel": "[CHOOSE: beginner, intermediate, advanced, athlete]",
            "workoutWindowPreference": "[CHOOSE: early_morning, morning, midday, afternoon, evening, night]"
          },
          "goal": {
            "family": "[CHOOSE: strength_tone, endurance, performance, health_wellbeing, recovery_rehab]",
            "rawText": "[INSERT their actual goal from conversation]"
          },
          "engagementPreferences": {
            "checkInFrequency": "[CHOOSE: multiple_daily, daily, few_times_weekly, weekly]",
            "preferredTimes": ["[CHOOSE from: morning, evening, afternoon, night]"]
          },
          "sleepWindow": {
            "bedtime": "[INFER from conversation or use 10:30 PM]",
            "waketime": "[INFER from conversation or use 6:30 AM]"
          },
          "motivationalStyle": {
            "styles": ["[CHOOSE 1-2 from: tough_love, encouraging, analytical, buddy]"]
          },
          "timezone": "\(TimeZone.current.identifier)",
          "generatedPersona": {
            "id": "[GENERATE any valid UUID]",
            "name": "[CREATE unique coach name like Maya, Marcus, etc]",
            "archetype": "[CREATE descriptive title like 'The Gentle Motivator']",
            "systemPrompt": "[WRITE 300+ word detailed prompt starting with 'You are...' that captures ALL conversation insights]",
            "coreValues": ["[3-5 values that align with user needs]"],
            "backgroundStory": "[CREATE 2-3 sentence backstory]",
            "voiceCharacteristics": {
              "energy": "[CHOOSE: high, moderate, calm based on user energy]",
              "pace": "[CHOOSE: brisk, measured, natural based on user preference]",
              "warmth": "[CHOOSE: warm, neutral, friendly based on conversation tone]",
              "vocabulary": "[CHOOSE: simple, moderate, advanced based on user language]",
              "sentenceStructure": "[CHOOSE: simple, moderate, complex based on user style]"
            },
            "interactionStyle": {
              "greetingStyle": "[CREATE greeting that matches persona]",
              "closingStyle": "[CREATE sign-off that matches persona]",
              "encouragementPhrases": ["[CREATE 2-3 phrases]"],
              "acknowledgmentStyle": "[CREATE acknowledgment style]",
              "correctionApproach": "[CHOOSE: very gentle, gentle, direct]",
              "humorLevel": "[CHOOSE: none, light, moderate, playful]",
              "formalityLevel": "[CHOOSE: casual, balanced, professional]",
              "responseLength": "[CHOOSE: concise, moderate, detailed]"
            },
            "adaptationRules": [],
            "metadata": {
              "createdAt": "2024-01-01T00:00:00Z",
              "version": "1.0",
              "sourceInsights": {
                "dominantTraits": ["supportive", "analytical"],
                "communicationStyle": "conversational",
                "motivationType": "balanced",
                "energyLevel": "moderate",
                "preferredComplexity": "moderate",
                "emotionalTone": ["encouraging"],
                "stressResponse": "needsSupport",
                "preferredTimes": ["morning"],
                "extractedAt": "2024-01-01T00:00:00Z"
              },
              "generationDuration": 0.5,
              "tokenCount": 1000,
              "previewReady": true
            }
          }
        }
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
        _ = input.lowercased()
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

        // Calculate health data quality score based on actual data available
        var healthDataQuality = 0.0
        if let health = healthContext {
            var dataPoints = 0
            if health.activity.steps != nil { dataPoints += 1 }
            if health.activity.activeEnergyBurned != nil { dataPoints += 1 }
            if health.activity.exerciseMinutes != nil { dataPoints += 1 }
            if health.sleep.lastNight != nil { dataPoints += 1 }
            if health.heartHealth.restingHeartRate != nil { dataPoints += 1 }
            if health.body.weight != nil { dataPoints += 1 }
            // Score from 0.2 (minimal data) to 0.8 (rich data)
            healthDataQuality = min(0.2 + (Double(dataPoints) * 0.1), 0.8)
        }

        // Update scores based on conversation content and health data
        contextQuality = ContextComponents(
            goalClarity: hasSpecificGoal && hasNumbers ? 0.7 : (hasSpecificGoal ? 0.4 : 0.2),
            obstacles: hasObstacles ? 0.6 : 0.2,
            exercisePreferences: hasExercisePrefs ? 0.6 : 0.2,
            currentState: healthDataQuality > 0 ? healthDataQuality : (hasExercisePrefs ? 0.4 : 0.2),
            lifestyle: hasSchedule ? 0.6 : (healthDataQuality > 0.4 ? 0.5 : 0.2),
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
        _ = conversation.contains("run") || conversation.contains("cardio") || conversation.contains("endurance")
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
                workStyle: isBusy ? .active : .moderate,
                fitnessLevel: isBeginner ? .beginner : .intermediate,
                workoutWindowPreference: detectWorkoutWindowPreference()
            ),
            goal: Goal(
                family: hasWeightGoal ? .strengthTone : (hasMuscleGoal ? .strengthTone : .healthWellbeing),
                rawText: conversationHistory.joined(separator: " ")
            ),
            engagementPreferences: EngagementPreferences(
                checkInFrequency: needsMotivation ? .daily : .fewTimes,
                preferredTimes: detectPreferredTimes()
            ),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(
                styles: needsMotivation ? [.tough, .encouraging] : (prefersSoft ? [.encouraging] : [.encouraging, .analytical])
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
                    pace: prefersSoft ? .measured : .natural,
                    warmth: .warm,
                    vocabulary: .moderate,
                    sentenceStructure: .moderate
                ),
                interactionStyle: InteractionStyle(
                    greetingStyle: needsMotivation ? "Hey there" : (prefersSoft ? "Hello" : "Hi"),
                    closingStyle: needsMotivation ? "Looking forward to our progress" : "See you next time",
                    encouragementPhrases: needsMotivation ?
                        ["You're making progress", "That's a great effort", "You're on the right track"] :
                        ["Nice work", "Good progress", "Well done"],
                    acknowledgmentStyle: prefersSoft ? "I understand" : "I hear you",
                    correctionApproach: prefersSoft ? "very gentle" : "gentle",
                    humorLevel: needsMotivation ? .moderate : .light,
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
                        motivationType: needsMotivation ? .achievement : .balanced,
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
                ),
                nutritionRecommendations: generateDefaultNutritionRecommendations()
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
        let insights: PersonalityInsights? = contextQuality.overall > 0.3 ? {
            var pi = PersonalityInsights()
            pi.traits = [
                .socialOrientation: 0.7,
                .dataOrientation: 0.5
            ]
            pi.motivationalDrivers = [.achievement]
            pi.lastUpdated = Date()
            return pi
        }() : nil

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

    // MARK: - Helper Methods for Persona Generation

    private func extractGoal(from history: [String]) -> String {
        let conversation = history.joined(separator: " ").lowercased()
        if conversation.contains("lose") && conversation.contains("weight") {
            return "weight loss"
        } else if conversation.contains("muscle") || conversation.contains("strength") {
            return "build muscle"
        } else if conversation.contains("run") || conversation.contains("marathon") {
            return "improve endurance"
        }
        return "improve fitness"
    }

    private func extractObstacles(from history: [String]) -> String {
        let conversation = history.joined(separator: " ").lowercased()
        var obstacles: [String] = []
        if conversation.contains("time") || conversation.contains("busy") {
            obstacles.append("limited time")
        }
        if conversation.contains("motivation") {
            obstacles.append("staying motivated")
        }
        if conversation.contains("injury") || conversation.contains("pain") {
            obstacles.append("past injuries")
        }
        return obstacles.isEmpty ? "none specified" : obstacles.joined(separator: ", ")
    }

    private func extractUserName(from history: [String]) -> String? {
        // Simple heuristic - look for "my name is" or "I'm [name]"
        let conversation = history.joined(separator: " ")
        if let range = conversation.range(of: "my name is ", options: .caseInsensitive) {
            let afterName = String(conversation[range.upperBound...])
            let name = afterName.split(separator: " ").first ?? ""
            return String(name).trimmingCharacters(in: .punctuationCharacters)
        }
        return nil
    }

    private func extractDominantTraits() -> [String] {
        var traits: [String] = []
        if contextQuality.goalClarity > 0.7 { traits.append("goal-oriented") }
        if contextQuality.obstacles > 0.6 { traits.append("self-aware") }
        if contextQuality.exercisePreferences > 0.6 { traits.append("activity-focused") }
        return traits.isEmpty ? ["balanced"] : traits
    }

    private func detectCommunicationStyle() -> ConversationCommunicationStyle {
        let avgMessageLength = conversationHistory.reduce(0) { $0 + $1.count } / max(conversationHistory.count, 1)
        if avgMessageLength > 100 { return .analytical }
        if avgMessageLength < 30 { return .energetic }
        return .conversational
    }

    private func detectConversationMotivationType() -> ConversationMotivationType {
        let conversation = conversationHistory.joined(separator: " ").lowercased()
        if conversation.contains("compete") || conversation.contains("win") || conversation.contains("best") {
            return .achievement
        }
        if conversation.contains("friend") || conversation.contains("group") || conversation.contains("together") {
            return .social
        }
        if conversation.contains("perform") || conversation.contains("race") {
            return .performance
        }
        return .health
    }

    private func detectMotivationType() -> MotivationType {
        let conversation = conversationHistory.joined(separator: " ").lowercased()
        if conversation.contains("compete") || conversation.contains("win") || conversation.contains("best") {
            return .achievement
        }
        if conversation.contains("friend") || conversation.contains("group") || conversation.contains("together") {
            return .social
        }
        return .health
    }

    private func detectConversationEnergyLevel() -> ConversationEnergyLevel {
        let conversation = conversationHistory.joined(separator: " ").lowercased()
        let highEnergyWords = ["excited", "pumped", "ready", "motivated", "can't wait"]
        let lowEnergyWords = ["tired", "slow", "gentle", "easy", "relaxed"]

        let highCount = highEnergyWords.filter { conversation.contains($0) }.count
        let lowCount = lowEnergyWords.filter { conversation.contains($0) }.count

        if highCount > lowCount { return .high }
        if lowCount > highCount { return .low }
        return .moderate
    }

    private func detectEnergyLevel() -> ConversationEnergyLevel {
        return detectConversationEnergyLevel()
    }

    private func detectWorkoutWindowPreference() -> LifeContext.WorkoutWindow {
        let conversation = conversationHistory.joined(separator: " ").lowercased()
        if conversation.contains("early") || conversation.contains("5am") || conversation.contains("6am") {
            return .earlyMorning
        }
        if conversation.contains("morning") || conversation.contains("7am") || conversation.contains("8am") {
            return .morning
        }
        if conversation.contains("lunch") || conversation.contains("noon") || conversation.contains("midday") {
            return .midday
        }
        if conversation.contains("evening") || conversation.contains("after work") {
            return .evening
        }
        return .morning  // Default
    }

    private func extractInsightsFromConversation() {
        let conversation = conversationHistory.joined(separator: " ")

        // Extract goal
        let primaryGoal = extractGoal(from: conversationHistory)

        // Extract obstacles
        var obstacles: [String] = []
        let lowerConvo = conversation.lowercased()
        if lowerConvo.contains("busy") || lowerConvo.contains("time") {
            obstacles.append("limited time")
        }
        if lowerConvo.contains("motivation") || lowerConvo.contains("lazy") {
            obstacles.append("staying motivated")
        }
        if lowerConvo.contains("injury") || lowerConvo.contains("pain") {
            obstacles.append("managing injuries")
        }

        // Extract exercise preferences
        var exercisePrefs: [String] = []
        if lowerConvo.contains("run") { exercisePrefs.append("running") }
        if lowerConvo.contains("walk") { exercisePrefs.append("walking") }
        if lowerConvo.contains("gym") { exercisePrefs.append("gym workouts") }
        if lowerConvo.contains("yoga") { exercisePrefs.append("yoga") }
        if lowerConvo.contains("swim") { exercisePrefs.append("swimming") }
        if lowerConvo.contains("bike") || lowerConvo.contains("cycling") { exercisePrefs.append("cycling") }

        // Determine fitness level
        let fitnessLevel: String
        if lowerConvo.contains("beginner") || lowerConvo.contains("new to") || lowerConvo.contains("just starting") {
            fitnessLevel = "beginner"
        } else if lowerConvo.contains("advanced") || lowerConvo.contains("experienced") {
            fitnessLevel = "advanced"
        } else {
            fitnessLevel = "intermediate"
        }

        // Extract schedule
        let schedule: String
        if lowerConvo.contains("busy") {
            schedule = "busy schedule with limited time"
        } else if lowerConvo.contains("flexible") {
            schedule = "flexible schedule"
        } else if lowerConvo.contains("work from home") || lowerConvo.contains("remote") {
            schedule = "work from home with flexible hours"
        } else {
            schedule = "standard work schedule"
        }

        // Extract motivational needs
        var motivationalNeeds: [String] = []
        if lowerConvo.contains("accountability") { motivationalNeeds.append("accountability") }
        if lowerConvo.contains("encouragement") || lowerConvo.contains("support") { motivationalNeeds.append("encouragement") }
        if lowerConvo.contains("track") || lowerConvo.contains("progress") { motivationalNeeds.append("progress tracking") }
        if lowerConvo.contains("celebrate") || lowerConvo.contains("wins") { motivationalNeeds.append("celebrating achievements") }

        // Determine communication style
        let communicationStyle: String
        if contextQuality.communicationStyle > 0.5 {
            communicationStyle = "detailed and analytical"
        } else if lowerConvo.contains("simple") || lowerConvo.contains("easy") {
            communicationStyle = "simple and straightforward"
        } else {
            communicationStyle = "balanced and supportive"
        }

        // Create insights object
        extractedInsights = ExtractedInsights(
            primaryGoal: primaryGoal,
            keyObstacles: obstacles,
            exercisePreferences: exercisePrefs,
            currentFitnessLevel: fitnessLevel,
            dailySchedule: schedule,
            motivationalNeeds: motivationalNeeds,
            communicationStyle: communicationStyle
        )
    }

    private func createCoachingPlan(with persona: PersonaProfile, conversationData: ConversationData) -> CoachingPlan {
        let conversation = conversationHistory.joined(separator: " ").lowercased()

        // Extract understanding from conversation
        let understandingSummary = "I understand you want to \(extractGoal(from: conversationHistory))"
            + (contextQuality.obstacles > 0.5 ? " while managing \(extractObstacles(from: conversationHistory))." : ".")
            + " Let's create a sustainable plan that fits your lifestyle."

        // Generate coaching approach based on persona
        let coachingApproach = [
            "I'll be your \(persona.archetype), focusing on \(persona.coreValues.first ?? "progress")",
            "We'll work at a \(persona.voiceCharacteristics.pace.rawValue) pace that feels right for you",
            "I'll adapt my coaching style based on your energy and progress",
            "Together, we'll build habits that last beyond any single goal"
        ]

        return CoachingPlan(
            understandingSummary: understandingSummary,
            coachingApproach: coachingApproach,
            lifeContext: LifeContext(
                workStyle: conversation.contains("active") ? .active : .moderate,
                fitnessLevel: conversation.contains("beginner") ? .beginner : .intermediate,
                workoutWindowPreference: detectWorkoutWindowPreference()
            ),
            goal: Goal(
                family: conversation.contains("strength") ? .strengthTone : .healthWellbeing,
                rawText: extractGoal(from: conversationHistory)
            ),
            engagementPreferences: EngagementPreferences(
                checkInFrequency: persona.voiceCharacteristics.energy == .high ? .daily : .fewTimes,
                preferredTimes: detectPreferredTimes()
            ),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(
                styles: persona.voiceCharacteristics.energy == .high ? [.tough, .encouraging] : [.encouraging]
            ),
            timezone: TimeZone.current.identifier,
            generatedPersona: persona
        )
    }

    private func generateDefaultNutritionRecommendations() -> NutritionRecommendations {
        // Analyze conversation for fitness goals
        let conversation = conversationHistory.joined(separator: " ").lowercased()

        if conversation.contains("muscle") || conversation.contains("strength") || conversation.contains("gain") {
            return NutritionRecommendations(
                approach: "Build and recover",
                proteinGramsPerPound: 1.2,
                fatPercentage: 0.25,
                carbStrategy: "Fuel your workouts with quality carbs",
                rationale: "Higher protein supports muscle growth. Moderate fat leaves room for performance carbs.",
                flexibilityNotes: "Hit your protein daily, let carbs and fat balance out over the week"
            )
        } else if conversation.contains("weight loss") || conversation.contains("lean") || conversation.contains("cut") {
            return NutritionRecommendations(
                approach: "Sustainable deficit",
                proteinGramsPerPound: 1.1,
                fatPercentage: 0.30,
                carbStrategy: "Moderate carbs for energy and satiety",
                rationale: "Higher protein preserves muscle during weight loss. Balanced fat helps with adherence.",
                flexibilityNotes: "Focus on weekly averages. One high day won't derail progress"
            )
        } else {
            return NutritionRecommendations(
                approach: "Balanced fitness",
                proteinGramsPerPound: 0.9,
                fatPercentage: 0.30,
                carbStrategy: "Fill remaining calories with quality carbs",
                rationale: "Balanced macros support general fitness and health goals.",
                flexibilityNotes: "Aim for consistency over perfection - 80/20 rule works well"
            )
        }
    }
}
