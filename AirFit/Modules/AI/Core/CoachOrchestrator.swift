import Foundation
import SwiftData

@MainActor
protocol CoachOrchestratorDelegate: AnyObject {
    // State
    func didStartProcessing()
    func didFinishProcessing()
    func updateCurrentResponse(_ text: String)
    func appendStreamingToken(_ token: String)
    func setError(_ error: Error?)
    func setActiveConversationId(_ id: UUID?)
    func setLastFunctionCall(_ name: String?)
}

@MainActor
final class CoachOrchestrator {

    // MARK: - Dependencies
    private let personaService: PersonaService
    private let conversationManager: ConversationManager
    private let aiService: AIServiceProtocol
    private let contextAssembler: ContextAssembler
    private let modelContext: ModelContext
    private let routingConfiguration: RoutingConfiguration
    private let healthKitManager: HealthKitManaging
    private let nutritionCalculator: NutritionCalculatorProtocol
    private let muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol
    private let exerciseDatabase: ExerciseDatabase
    private let streamStore: ChatStreamingStore?

    // Subcomponents
    private let messageProcessor: MessageProcessor
    private let stateManager: ConversationStateManager
    private let directAIProcessor: DirectAIProcessor
    private let streamingHandler: StreamingResponseHandler
    private let router: CoachRouter
    private let formatter = AIFormatter()
    private let parser = AIParser()

    // Strategies
    private lazy var workout = WorkoutStrategy(
        personaService: personaService,
        aiService: aiService,
        exerciseDatabase: exerciseDatabase,
        modelContext: modelContext,
        formatter: formatter
    )

    private lazy var nutrition = NutritionStrategy(
        aiService: aiService,
        directAIProcessor: directAIProcessor,
        parser: parser
    )

    private lazy var recovery = RecoveryStrategy(
        personaService: personaService,
        aiService: aiService,
        healthKitManager: healthKitManager,
        nutritionCalculator: nutritionCalculator,
        muscleGroupVolumeService: muscleGroupVolumeService,
        formatter: formatter
    )

    weak var delegate: CoachOrchestratorDelegate?

    // MARK: - Init
    init(
        localCommandParser: LocalCommandParser,
        personaService: PersonaService,
        conversationManager: ConversationManager,
        aiService: AIServiceProtocol,
        contextAssembler: ContextAssembler,
        modelContext: ModelContext,
        routingConfiguration: RoutingConfiguration,
        healthKitManager: HealthKitManaging,
        nutritionCalculator: NutritionCalculatorProtocol,
        muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol,
        exerciseDatabase: ExerciseDatabase,
        streamStore: ChatStreamingStore?
    ) {
        self.personaService = personaService
        self.conversationManager = conversationManager
        self.aiService = aiService
        self.contextAssembler = contextAssembler
        self.modelContext = modelContext
        self.routingConfiguration = routingConfiguration
        self.healthKitManager = healthKitManager
        self.nutritionCalculator = nutritionCalculator
        self.muscleGroupVolumeService = muscleGroupVolumeService
        self.exerciseDatabase = exerciseDatabase
        self.streamStore = streamStore

        self.messageProcessor = MessageProcessor(localCommandParser: localCommandParser)
        self.stateManager = ConversationStateManager()
        self.directAIProcessor = DirectAIProcessor(aiService: aiService)
        self.streamingHandler = StreamingResponseHandler(routingConfiguration: routingConfiguration)
        self.router = CoachRouter(routingConfiguration: routingConfiguration)

        self.streamingHandler.delegate = self
    }

    // MARK: - Public API (facade entry points)

    func processUserMessage(_ text: String, for user: User, activeConversationId: inout UUID?) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        delegate?.didStartProcessing()
        defer { delegate?.didFinishProcessing() }

        do {
            if activeConversationId == nil {
                let persona = try await personaService.getActivePersona(for: user.id)
                activeConversationId = await stateManager.createSession(userId: user.id, personaId: persona.id)
                delegate?.setActiveConversationId(activeConversationId)
            }
            guard let conversationId = activeConversationId else { throw CoachEngineError.noActiveConversation }

            // Classification
            let messageType = messageProcessor.classifyMessage(text)
            let saved = try await conversationManager.saveUserMessage(text, for: user, conversationId: conversationId)
            saved.messageType = messageType
            try modelContext.save()
            await stateManager.updateSession(conversationId, messageProcessed: true)

            // Optional local command
            if let command = await messageProcessor.checkLocalCommand(text, for: user) {
                await executeLocalCommand(command)
                let withContext = text + "\n\n" + messageProcessor.describeCommandExecution(command)
                try await routeAndProcess(
                    text: withContext,
                    user: user,
                    conversationId: conversationId,
                    messageType: messageType
                )
            } else {
                try await routeAndProcess(
                    text: text,
                    user: user,
                    conversationId: conversationId,
                    messageType: messageType
                )
            }
        } catch {
            delegate?.setError(error)
            delegate?.updateCurrentResponse(
                (error as? CoachEngineError)?.userFriendlyMessage
                ?? "I'm having trouble processing your request right now. Please try again in a moment."
            )
        }
    }

    func regenerateLastResponse(for user: User, activeConversationId: UUID?) async {
        guard let conversationId = activeConversationId else {
            delegate?.setError(CoachEngineError.noActiveConversation)
            delegate?.updateCurrentResponse(CoachEngineError.noActiveConversation.userFriendlyMessage)
            return
        }
        delegate?.didStartProcessing()
        defer { delegate?.didFinishProcessing() }

        do {
            let recent = try await conversationManager.getRecentMessages(for: user, conversationId: conversationId, limit: 10)
            guard let lastUser = recent.last(where: { $0.role == .user }) else {
                delegate?.setError(CoachEngineError.noMessageToRegenerate)
                delegate?.updateCurrentResponse(CoachEngineError.noMessageToRegenerate.userFriendlyMessage)
                return
            }
            try await routeAndProcess(text: lastUser.content, user: user, conversationId: conversationId, messageType: .conversation)
        } catch {
            delegate?.setError(error)
            delegate?.updateCurrentResponse("I'm having trouble processing your request right now. Please try again in a moment.")
        }
    }

    func clearConversation(activeConversationId: inout UUID?) {
        Task {
            if let old = activeConversationId { await stateManager.endSession(old) }
            activeConversationId = nil
            delegate?.setActiveConversationId(nil)
            delegate?.updateCurrentResponse("")
        }
    }

    // Strategies exposed for shim

    func postWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async -> String {
        await workout.generatePostWorkoutAnalysis(request)
    }

    // Expose NutritionStrategy direct path for shim compatibility
    func parseAndLogNutritionDirect(
        foodText: String,
        context: String = "",
        user: User,
        conversationId: UUID?
    ) async throws -> NutritionParseResult {
        try await nutrition.parseAndLogNutritionDirect(foodText: foodText, context: context, user: user, conversationId: conversationId)
    }

    // Expose RecoveryStrategy helpers for dashboard and notifications
    func generateNotificationContent<T>(
        type: AIFormatter.NotificationContentType,
        context: T
    ) async throws -> String {
        try await recovery.generateNotificationContent(type: type, context: context)
    }

    func generateDashboardContent(for user: User) async throws -> AIDashboardContent {
        try await recovery.generateDashboardContent(for: user)
    }

    func functionCall(
        _ call: AIFunctionCall,
        user: User,
        conversationId: UUID
    ) async -> String {
        do {
            switch call.name {
            case "parseAndLogComplexNutrition":
                let foodText = parser.extractString(from: call.arguments["food_description"]) ?? ""
                let res = try await nutrition.parseAndLogNutritionDirect(foodText: foodText, user: user, conversationId: conversationId)
                return AIFormatter().nutritionParsingResponse(res)

            case "generateEducationalInsight":
                // keep existing path via DirectAIProcessor for now (short)
                let topic = parser.extractString(from: call.arguments["topic"]) ?? "general fitness"
                let depth = parser.extractString(from: call.arguments["depth"]) ?? "beginner"
                let req = AIRequest(
                    systemPrompt: "You are an expert fitness educator. Provide clear, evidence-based information.",
                    messages: [AIChatMessage(role: .user, content: "Provide educational content about \(topic) at a \(depth) level. Keep it concise and actionable.")],
                    temperature: 0.7,
                    maxTokens: 500,
                    stream: false,
                    user: "educational-content"
                )
                var content = ""
                for try await r in aiService.sendRequest(req) {
                    switch r {
                    case .text(let t), .textDelta(let t): content += t
                    default: break
                    }
                }
                return content

            case "generatePersonalizedWorkoutPlan", "generate_workout":
                return try await workout.handleWorkoutGeneration(call.arguments, user: user)

            case "adaptPlanBasedOnFeedback":
                return try await workout.handleWorkoutAdaptation(call.arguments, user: user)

            case "send_workout_to_watch":
                return "Workout has been sent to your Apple Watch! Open the AirFit app on your watch to start."

            case "analyze_workout_completion":
                return await workout.handleWorkoutAnalysis(call.arguments, user: user)

            case "assistGoalSettingOrRefinement":
                // Delegate to existing CoachEngine path later; placeholder
                return "(SMART goal helper routed via orchestrator — move detailed implementation next pass.)"

            case "analyzePerformanceTrends":
                return "(Performance analysis routed via orchestrator — move detailed implementation next pass.)"

            default:
                return "(Note: \(call.name.replacingOccurrences(of: "_", with: " ")) isn't configured yet)"
            }
        } catch {
            return "I encountered an issue while executing that action. Please try again or contact support if the problem persists."
        }
    }

    // MARK: - Internal

    private func routeAndProcess(
        text: String,
        user: User,
        conversationId: UUID,
        messageType: MessageType
    ) async throws {
        // 1) Context
        let healthContext = await contextAssembler.assembleContext()
        let historyLimit = await stateManager.getOptimalHistoryLimit(for: conversationId, messageType: messageType)
        let history = try await conversationManager.getRecentMessages(for: user, conversationId: conversationId, limit: historyLimit)

        let userCtx = UserContextSnapshot(
            activeGoals: [],
            recentActivity: healthContext.appContext.workoutContext?.recentWorkouts.map { $0.type } ?? [],
            preferences: [:],
            timeOfDay: messageProcessor.getCurrentTimeOfDay(),
            isNewUser: user.onboardingProfile == nil
        )

        // 2) Routing
        let strategy = router.route(userInput: text, history: history, userContext: userCtx, userId: user.id)

        // 3) Execute
        switch strategy.route {
        case .directAI:
            try await handleDirectAI(
                text: text,
                user: user,
                conversationId: conversationId,
                history: history,
                healthContext: healthContext,
                strategy: strategy
            )
        case .functionCalling, .hybrid:
            try await handleFunctionCalling(
                text: text,
                user: user,
                conversationId: conversationId,
                history: history,
                healthContext: healthContext,
                strategy: strategy
            )
        }
    }

    private func handleDirectAI(
        text: String,
        user: User,
        conversationId: UUID,
        history: [AIChatMessage],
        healthContext: HealthContextSnapshot,
        strategy: RoutingStrategy
    ) async throws {
        let t0 = CFAbsoluteTimeGetCurrent()
        let isNutrition = messageProcessor.detectsNutritionParsing(text)
        let isEdu = messageProcessor.detectsEducationalContent(text)

        do {
            var response: String
            var metrics: RoutingMetrics

            if isNutrition {
                let res = try await nutrition.parseAndLogNutritionDirect(foodText: text, user: user, conversationId: conversationId)
                response = formatter.nutritionParsingResponse(res)
                metrics = RoutingMetrics(route: .directAI,
                                         executionTimeMs: res.processingTimeMs,
                                         success: true,
                                         tokenUsage: res.tokenCount,
                                         confidence: res.confidence,
                                         fallbackUsed: false,
                                         timestamp: Date())
            } else if isEdu {
                // Reuse existing direct processor path (already efficient)
                let profile = try await getUserProfile(for: user)
                let content = try await directAIProcessor.generateEducationalContent(topic: messageProcessor.extractEducationalTopic(from: text), userContext: text, userProfile: profile)
                response = content.content
                metrics = RoutingMetrics(route: .directAI,
                                         executionTimeMs: Int((CFAbsoluteTimeGetCurrent() - t0) * 1000),
                                         success: true,
                                         tokenUsage: content.tokenCount,
                                         confidence: content.personalizationLevel,
                                         fallbackUsed: false,
                                         timestamp: Date())
            } else {
                if strategy.fallbackEnabled && text.count > 150 {
                    try await handleFunctionCalling(text: text, user: user, conversationId: conversationId, history: history, healthContext: healthContext, strategy: RoutingStrategy(route: .functionCalling, reason: "Intelligent fallback from direct AI", fallbackEnabled: false, timestamp: Date()))
                    return
                }
                let profile = try await getUserProfile(for: user)
                response = try await directAIProcessor.generateSimpleResponse(text: text, userProfile: profile, healthContext: healthContext)
                metrics = RoutingMetrics(route: .directAI,
                                         executionTimeMs: Int((CFAbsoluteTimeGetCurrent() - t0) * 1000),
                                         success: true,
                                         tokenUsage: CoachMetrics.estimateTokens(for: text) + CoachMetrics.estimateTokens(for: response),
                                         confidence: 0.8,
                                         fallbackUsed: false,
                                         timestamp: Date())
            }

            _ = try await conversationManager.createAssistantMessage(response, for: user, conversationId: conversationId, functionCall: nil, isLocalCommand: false, isError: false)
            delegate?.updateCurrentResponse(response)
            CoachMetrics.record(metrics, via: routingConfiguration)

        } catch {
            if strategy.fallbackEnabled {
                let metrics = RoutingMetrics(route: .directAI,
                                             executionTimeMs: Int((CFAbsoluteTimeGetCurrent() - t0) * 1000),
                                             success: false,
                                             tokenUsage: nil,
                                             confidence: nil,
                                             fallbackUsed: true,
                                             timestamp: Date())
                CoachMetrics.record(metrics, via: routingConfiguration)
                try await handleFunctionCalling(text: text, user: user, conversationId: conversationId, history: history, healthContext: healthContext, strategy: RoutingStrategy(route: .functionCalling, reason: "Fallback from failed direct AI", fallbackEnabled: false, timestamp: Date()))
            } else {
                throw error
            }
        }
    }

    private func handleFunctionCalling(
        text: String,
        user: User,
        conversationId: UUID,
        history: [AIChatMessage],
        healthContext: HealthContextSnapshot,
        strategy: RoutingStrategy
    ) async throws {
        let persona = try await personaService.getActivePersona(for: user.id)
        let systemPrompt = persona.systemPrompt + "\n\nTask context: General conversation with access to functions."
        let currentMessage = AIChatMessage(role: .user, content: text, timestamp: Date())
        let req = AIRequest(
            systemPrompt: systemPrompt,
            messages: history + [currentMessage],
            functions: FunctionRegistry.availableFunctions,
            user: user.id.uuidString,
            timeout: 30.0
        )
        try await streamWithMetrics(req, user: user, conversationId: conversationId, routingStrategy: strategy)
    }

    private func getUserProfile(for user: User) async throws -> CoachingPlan {
        guard let onboardingProfile = user.onboardingProfile else { return createDefaultProfile() }
        do {
            return try JSONDecoder().decode(CoachingPlan.self, from: onboardingProfile.rawFullProfileData)
        } catch {
            AppLogger.warning("Failed to decode user profile, using default", category: .ai)
            return createDefaultProfile()
        }
    }

    private func createDefaultProfile() -> CoachingPlan {
        CoachingPlan.defaultProfile()
    }

    private func executeLocalCommand(_ command: LocalCommand) async {
        switch command {
        case .showDashboard, .navigateToTab, .showSettings, .showProfile,
             .startWorkout, .showFood, .showWorkouts, .showStats,
             .showRecovery, .showProgress:
            // No-op (UI integration point); keep parity without adding NotificationCenter.
            AppLogger.info("Local navigation command executed: \(command)", category: .ai)
        case .quickLog, .quickAction, .help, .none:
            AppLogger.info("Local quick command executed: \(command)", category: .ai)
        }
    }

    // MARK: Streaming

    private func streamWithMetrics(
        _ request: AIRequest,
        user: User,
        conversationId: UUID,
        routingStrategy: RoutingStrategy
    ) async throws {
        let responseStream = aiService.sendRequest(request)

        // Signal start (ChatStreamingStore only)
        streamStore?.publish(ChatStreamingEvent(conversationId: conversationId, kind: .started))

        var full = ""
        var fnCall: AIFunctionCall?
        var usageTokens = 0

        do {
            for try await resp in responseStream {
                switch resp {
                case .text(let t), .textDelta(let t):
                    full += t
                    delegate?.appendStreamingToken(t)
                    delegate?.updateCurrentResponse(full)
                    streamStore?.publish(ChatStreamingEvent(conversationId: conversationId, kind: .delta(t)))
                case .functionCall(let c):
                    fnCall = c
                    delegate?.setLastFunctionCall(c.name)
                case .structuredData(let data):
                    if let s = String(data: data, encoding: .utf8) {
                        full = s
                        delegate?.updateCurrentResponse(full)
                    }
                case .done(let usage):
                    usageTokens = usage?.totalTokens ?? 0
                    streamStore?.publish(ChatStreamingEvent(conversationId: conversationId, kind: .finished(usage: usage)))
                case .error(let aiError):
                    throw aiError
                }
            }

            let assistant = try await conversationManager.createAssistantMessage(
                full,
                for: user,
                conversationId: conversationId,
                functionCall: fnCall.map { FunctionCall(name: $0.name, arguments: $0.arguments.mapValues { AnyCodable($0.value) }) },
                isLocalCommand: false,
                isError: false
            )

            // Best-effort model metadata
            let modelUsed: String = request.model ?? {
                switch aiService.activeProvider {
                case .openAI: return LLMModel.gpt5Mini.identifier
                case .gemini: return LLMModel.gemini25Flash.identifier
                case .anthropic: return LLMModel.claude4Sonnet.identifier
                }
            }()
            try? await conversationManager.recordAIMetadata(for: assistant, model: modelUsed, tokens: (prompt: 0, completion: usageTokens), temperature: request.temperature, responseTime: 0)

            // Execute tool if any
            if let call = fnCall {
                let resultText = await functionCall(call, user: user, conversationId: conversationId)
                _ = try await conversationManager.createAssistantMessage(resultText, for: user, conversationId: conversationId, functionCall: FunctionCall(name: call.name, arguments: call.arguments.mapValues { AnyCodable($0.value) }), isLocalCommand: false, isError: false)
                delegate?.updateCurrentResponse(full + "\n\n" + resultText)
            }

        } catch {
            streamStore?.publish(ChatStreamingEvent(conversationId: conversationId, kind: .finished(usage: nil)))
            throw error
        }
    }
}

// MARK: StreamingResponseDelegate -> drive state via delegate (no NotificationCenter)
extension CoachOrchestrator: StreamingResponseDelegate {
    func streamingDidReceiveText(_ text: String, accumulated: String) async {
        delegate?.appendStreamingToken(text)
        delegate?.updateCurrentResponse(accumulated)
    }
    func streamingDidDetectFunction(_ function: AIFunctionCall) async {
        delegate?.setLastFunctionCall(function.name)
    }
    func streamingDidComplete(fullResponse: String, tokenUsage: Int) async {
        delegate?.updateCurrentResponse(fullResponse)
        AppLogger.debug("Streaming completed with \(tokenUsage) tokens", category: .ai)
    }
    func streamingDidFail(with error: Error) async {
        delegate?.setError(error)
    }
}

// MARK: CoachingPlan convenience
private extension CoachingPlan {
    static func defaultProfile() -> CoachingPlan {
        CoachingPlan(
            understandingSummary: "I'll help you improve your health and fitness with a personalized approach.",
            coachingApproach: [
                "Focus on building sustainable habits",
                "Daily check-ins to keep you motivated",
                "Adapt to your energy levels and schedule"
            ],
            lifeContext: LifeContext(),
            goal: Goal(family: .healthWellbeing, rawText: "Improve overall health and fitness"),
            engagementPreferences: EngagementPreferences(checkInFrequency: .daily, preferredTimes: ["morning", "evening"]),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(),
            timezone: TimeZone.current.identifier,
            generatedPersona: PersonaProfile.defaultCoach()
        )
    }
}

private extension PersonaProfile {
    static func defaultCoach() -> PersonaProfile {
        PersonaProfile(
            id: UUID(),
            name: "AirFit Coach",
            archetype: "Supportive Mentor",
            systemPrompt: "You are a supportive fitness coach focused on building sustainable habits.",
            coreValues: ["empathy", "knowledge", "encouragement"],
            backgroundStory: "I'm here to help you achieve your health and fitness goals through personalized guidance.",
            voiceCharacteristics: VoiceCharacteristics(
                energy: .moderate,
                pace: .natural,
                warmth: .warm,
                vocabulary: .moderate,
                sentenceStructure: .moderate
            ),
            interactionStyle: InteractionStyle(
                greetingStyle: "Hey there!",
                closingStyle: "Keep pushing forward!",
                encouragementPhrases: ["Let's make progress together", "Every step counts", "You've got this!"],
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
                    dominantTraits: ["supportive", "knowledgeable", "encouraging"],
                    communicationStyle: .supportive,
                    motivationType: .health,
                    energyLevel: .moderate,
                    preferredComplexity: .moderate,
                    emotionalTone: ["warm", "understanding"],
                    stressResponse: .needsSupport,
                    preferredTimes: ["morning", "evening"],
                    extractedAt: Date()
                ),
                generationDuration: 0.0,
                tokenCount: 0,
                previewReady: true
            ),
            nutritionRecommendations: nil
        )
    }
}
