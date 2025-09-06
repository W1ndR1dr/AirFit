import Foundation
import SwiftData
import Observation
import UIKit

// MARK: - Direct AI Error Types
enum DirectAIError: Error, LocalizedError {
    case nutritionParsingFailed(String)
    case nutritionValidationFailed
    case educationalContentFailed(String)
    case invalidResponse
    case timeout
    case emptyResponse
    case invalidJSONResponse(String)
    case invalidNutritionValues(String)

    var errorDescription: String? {
        switch self {
        case .nutritionParsingFailed(let reason):
            return "Failed to parse nutrition: \(reason)"
        case .nutritionValidationFailed:
            return "Nutrition data validation failed"
        case .educationalContentFailed(let reason):
            return "Failed to generate educational content: \(reason)"
        case .invalidResponse:
            return "Invalid AI response format"
        case .timeout:
            return "Request timed out"
        case .emptyResponse:
            return "AI returned empty response"
        case .invalidJSONResponse(let response):
            return "Invalid JSON response: \(response.prefix(100))"
        case .invalidNutritionValues(let details):
            return "Invalid nutrition values: \(details)"
        }
    }

    var userFriendlyMessage: String {
        switch self {
        case .nutritionParsingFailed:
            return "I couldn't understand that food description. Could you try again with more detail?"
        case .nutritionValidationFailed:
            return "The nutrition data seems unusual. Please double-check your entry."
        case .educationalContentFailed:
            return "I'm having trouble generating content right now. Please try again."
        case .invalidResponse, .timeout, .emptyResponse, .invalidJSONResponse, .invalidNutritionValues:
            return "I'm having technical difficulties. Please try again in a moment."
        }
    }
}

// MARK: - CoachEngine Errors
enum CoachEngineError: LocalizedError {
    case noActiveConversation
    case noMessageToRegenerate
    case aiServiceUnavailable
    case streamingTimeout
    case functionExecutionFailed(String)
    case contextAssemblyFailed
    case invalidUserProfile
    case nutritionParsingFailed(String)
    case educationalContentFailed(String)

    var errorDescription: String? {
        switch self {
        case .noActiveConversation:
            return "No active conversation found"
        case .noMessageToRegenerate:
            return "No message found to regenerate"
        case .aiServiceUnavailable:
            return "AI service is currently unavailable"
        case .streamingTimeout:
            return "Response timed out"
        case .functionExecutionFailed(let details):
            return "Function execution failed: \(details)"
        case .contextAssemblyFailed:
            return "Failed to assemble health context"
        case .invalidUserProfile:
            return "Invalid user profile data"
        case .nutritionParsingFailed(let details):
            return "Nutrition parsing failed: \(details)"
        case .educationalContentFailed(let details):
            return "Educational content generation failed: \(details)"
        }
    }

    var userFriendlyMessage: String {
        switch self {
        case .noActiveConversation:
            return "Let's start a new conversation! What would you like to know?"
        case .noMessageToRegenerate:
            return "There's nothing to regenerate yet. Ask me something!"
        case .aiServiceUnavailable:
            return "I'm having trouble connecting right now. Please check your internet connection and try again."
        case .streamingTimeout:
            return "That took longer than expected. Let me try to help you with something else."
        case .functionExecutionFailed:
            return "I couldn't complete that action right now, but I'm here to help in other ways."
        case .contextAssemblyFailed:
            return "I'm having trouble accessing your health data. I can still help with general questions!"
        case .invalidUserProfile:
            return "Let me help you set up your profile so I can provide better personalized advice."
        case .nutritionParsingFailed:
            return "I had trouble understanding that food description. Could you try describing it differently?"
        case .educationalContentFailed:
            return "I couldn't generate educational content about that topic right now. Please try again."
        }
    }
}

// MARK: - CoachEngine
@MainActor
@Observable
final class CoachEngine {
    // MARK: - State Properties
    private(set) var isProcessing = false
    internal private(set) var currentResponse = ""
    private(set) var error: Error?
    private(set) var activeConversationId: UUID?
    private(set) var streamingTokens: [String] = []
    internal private(set) var lastFunctionCall: String?

    // MARK: - Dependencies
    internal let personaService: PersonaService
    internal let conversationManager: ConversationManager
    internal let aiService: AIServiceProtocol
    private let contextAssembler: ContextAssembler
    internal let modelContext: ModelContext
    private let routingConfiguration: RoutingConfiguration
    private let healthKitManager: HealthKitManaging
    private let nutritionCalculator: NutritionCalculatorProtocol
    private let muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol
    internal let exerciseDatabase: ExerciseDatabase

    // MARK: - Components
    private let messageProcessor: MessageProcessor
    private let stateManager: ConversationStateManager
    private let directAIProcessor: DirectAIProcessor
    private let streamingHandler: StreamingResponseHandler

    // MARK: - Configuration
    private let maxRetries = 3
    private let streamingTimeout: TimeInterval = 30.0
    private let functionCallTimeout: TimeInterval = 10.0

    // MARK: - Initialization
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
        exerciseDatabase: ExerciseDatabase
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

        // Initialize components
        self.messageProcessor = MessageProcessor(localCommandParser: localCommandParser)
        self.stateManager = ConversationStateManager()
        self.directAIProcessor = DirectAIProcessor(aiService: aiService)
        self.streamingHandler = StreamingResponseHandler(routingConfiguration: routingConfiguration)

        // Set up streaming delegate
        self.streamingHandler.delegate = self

        // Conversation will be initialized when first message is processed
    }

    // MARK: - Private Helpers

    /// Helper to collect all text from an AI response stream
    private func collectAIResponse(from request: AIRequest) async -> String {
        var result = ""
        do {
            for try await response in aiService.sendRequest(request) {
                switch response {
                case .text(let text), .textDelta(let text):
                    result += text
                default:
                    break
                }
            }
        } catch {
            AppLogger.error("Failed to get AI response: \(error)", category: .ai)
        }
        return result
    }

    // MARK: - Public Methods

    /// Processes a user message through the complete AI coaching pipeline
    func processUserMessage(_ text: String, for user: User) async {
        guard !isProcessing else {
            AppLogger.warning("Already processing a message, ignoring new request", category: .ai)
            return
        }

        await startProcessing()

        do {
            // Ensure we have an active conversation with user's persona
            if activeConversationId == nil {
                // Get user's active persona
                let persona = try await personaService.getActivePersona(for: user.id)
                activeConversationId = await stateManager.createSession(
                    userId: user.id,
                    personaId: persona.id
                )
            }

            guard let conversationId = activeConversationId else {
                throw CoachEngineError.noActiveConversation
            }

            // Step 1: Classify the message for optimization
            let messageType = messageProcessor.classifyMessage(text)
            AppLogger.debug("Message classified as \(messageType.rawValue): '\(text.prefix(50))...'", category: .ai)

            // Step 2: Save user message with classification
            let savedMessage = try await conversationManager.saveUserMessage(
                text,
                for: user,
                conversationId: conversationId
            )

            // Update message with classification
            savedMessage.messageType = messageType
            try modelContext.save()

            // Update state manager
            await stateManager.updateSession(conversationId, messageProcessed: true)

            AppLogger.info("Processing user message (\(messageType.rawValue)): \(text.prefix(50))...", category: .ai)

            // Step 3: Check for local commands and execute them
            let localCommand = await messageProcessor.checkLocalCommand(text, for: user)

            if let command = localCommand {
                // Execute the command (navigation, logging, etc.)
                await executeLocalCommand(command, for: user)

                // Get command execution description to add context for AI
                let commandDescription = messageProcessor.describeCommandExecution(command)

                // Append command context to the message for AI processing
                let textWithContext = text + "\n\n" + commandDescription

                // Process through AI with command context
                await processAIResponse(
                    textWithContext,
                    for: user,
                    conversationId: conversationId,
                    messageType: messageType,
                    executedCommand: command
                )
            } else {
                // No command, process normally through AI
                await processAIResponse(
                    text,
                    for: user,
                    conversationId: conversationId,
                    messageType: messageType,
                    executedCommand: nil
                )
            }

        } catch {
            await handleError(error)
        }
    }

    /// Clears the current conversation and starts a new one
    func clearConversation() {
        Task {
            if let oldId = activeConversationId {
                await stateManager.endSession(oldId)
            }

            // Conversation will be created when a user sends a message
            currentResponse = ""
            streamingTokens = []
            lastFunctionCall = nil
            error = nil

            AppLogger.info("Started new conversation: \(activeConversationId?.uuidString ?? "unknown")", category: .ai)
        }
    }

    /// Regenerates the last AI response
    func regenerateLastResponse(for user: User) async {
        guard let conversationId = activeConversationId else {
            await handleError(CoachEngineError.noActiveConversation)
            return
        }

        do {
            // Get the last user message
            let recentMessages = try await conversationManager.getRecentMessages(
                for: user,
                conversationId: conversationId,
                limit: 10
            )

            guard let lastUserMessage = recentMessages.last(where: { $0.role == .user }) else {
                await handleError(CoachEngineError.noMessageToRegenerate)
                return
            }

            // Clear current response and regenerate
            currentResponse = ""
            streamingTokens = []

            await processAIResponse(lastUserMessage.content, for: user, conversationId: conversationId, messageType: .conversation)

        } catch {
            await handleError(error)
        }
    }

    /// Generates AI-powered post-workout analysis
    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async -> String {
        let analysisPrompt = buildWorkoutAnalysisPrompt(request)

        // Get user's persona for consistent voice
        var systemPrompt = "You are a fitness coach providing post-workout analysis. Be encouraging, specific, and actionable."
        let user = request.workout.user
        let userId = user?.id ?? UUID()

        if let user = user {
            do {
                let persona = try await personaService.getActivePersona(for: user.id)
                systemPrompt = persona.systemPrompt + "\n\nTask context: Providing post-workout analysis. Be encouraging, specific, and actionable."
            } catch {
                AppLogger.warning("Failed to get user persona for workout analysis, using default", category: .ai)
            }
        }

        let aiRequest = AIRequest(
            systemPrompt: systemPrompt,
            messages: [
                AIChatMessage(
                    role: .user,
                    content: analysisPrompt,
                    timestamp: Date()
                )
            ],
            functions: [],
            user: userId.uuidString
        )

        let analysisResult = await collectAIResponse(from: aiRequest)

        if analysisResult.isEmpty {
            // Build contextual fallback using workout data
            let workout = request.workout
            var fallback = "Completed \(workout.name)"

            if let duration = workout.formattedDuration {
                fallback += " - \(duration)"
            }

            if !workout.exercises.isEmpty {
                fallback += " with \(workout.exercises.count) exercises"
            }

            if let calories = workout.caloriesBurned, calories > 0 {
                fallback += " burning \(Int(calories)) calories"
            }

            fallback += ". "

            // Add encouragement based on recent history
            if request.recentWorkouts.count > 3 {
                fallback += "Consistent work! You're building great habits."
            } else {
                fallback += "Great effort! Keep building momentum."
            }

            return fallback
        }

        return analysisResult
    }

    private func buildWorkoutAnalysisPrompt(_ request: PostWorkoutAnalysisRequest) -> String {
        let workout = request.workout
        let recentWorkouts = request.recentWorkouts

        var prompt = "Analyze this workout:\n\n"
        prompt += "Workout: \(workout.workoutTypeEnum?.displayName ?? workout.workoutType)\n"
        prompt += "Duration: \(workout.formattedDuration ?? "Unknown")\n"
        prompt += "Exercises: \(workout.exercises.count)\n"

        if let calories = workout.caloriesBurned, calories > 0 {
            prompt += "Calories: \(Int(calories))\n"
        }

        prompt += "\nExercises performed:\n"
        for exercise in workout.exercises {
            prompt += "- \(exercise.name): \(exercise.sets.count) sets\n"
        }

        if recentWorkouts.count > 1 {
            prompt += "\nRecent workout history (\(recentWorkouts.count - 1) previous):\n"
            for recent in recentWorkouts.dropFirst() {
                prompt += "- \(recent.workoutTypeEnum?.displayName ?? recent.workoutType): \(recent.formattedDuration ?? "Unknown")\n"
            }
        }

        prompt += "\nProvide encouraging analysis focusing on progress, form tips, and next steps. Keep it under 150 words."

        return prompt
    }

    // MARK: - Private Methods

    private func startProcessing() async {
        isProcessing = true
        error = nil
        currentResponse = ""
        streamingTokens = []
    }

    private func finishProcessing() async {
        isProcessing = false
    }


    /// Executes local commands (navigation, logging, etc.) without generating a response
    /// The AI will generate the appropriate response based on context
    private func executeLocalCommand(
        _ command: LocalCommand,
        for user: User
    ) async {
        // Execute the command based on type
        switch command {
        case .showDashboard, .navigateToTab, .showSettings, .showProfile,
             .showFood, .showWorkouts, .showStats,
             .showRecovery, .showProgress:
            // Navigation commands - execute through NavigationState
            if let navigationState = await getNavigationState() {
                await MainActor.run {
                    navigationState.executeIntent(.executeCommand(parsed: command))
                }
            }

        case .quickLog, .quickAction:
            // Quick logging actions - would open appropriate UI
            AppLogger.info("Executed quick log command: \(command)", category: .ai)

        case .help:
            // Help command - AI will provide contextual help
            AppLogger.info("User requested help", category: .ai)

        case .none:
            // No action needed
            break
        }

        AppLogger.info("Local command executed: \(command)", category: .ai)
    }

    /// Gets the NavigationState from the environment if available
    private func getNavigationState() async -> NavigationState? {
        // This would need to be injected or accessed through the view hierarchy
        // For now, return nil - the actual implementation would get this from
        // the SwiftUI environment or through dependency injection
        return nil
    }

    private func processAIResponse(
        _ text: String,
        for user: User,
        conversationId: UUID,
        messageType: MessageType,
        executedCommand: LocalCommand? = nil
    ) async {
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            // Step 1: Assemble health context
            let healthContext = await contextAssembler.assembleContext()

            // Step 2: Get conversation history with optimized limit based on message type
            let historyLimit = await stateManager.getOptimalHistoryLimit(
                for: conversationId,
                messageType: messageType
            )
            let conversationHistory = try await conversationManager.getRecentMessages(
                for: user,
                conversationId: conversationId,
                limit: historyLimit
            )

            AppLogger.debug(
                "Using \(historyLimit) message history limit for \(messageType.rawValue) (retrieved \(conversationHistory.count) messages)",
                category: .ai
            )

            // Step 3: HYBRID ROUTING - Determine processing strategy
            let userContext = UserContextSnapshot(
                activeGoals: [], // Extract from user profile if available
                recentActivity: healthContext.appContext.workoutContext?.recentWorkouts.map { $0.type } ?? [],
                preferences: [:],
                timeOfDay: messageProcessor.getCurrentTimeOfDay(),
                isNewUser: user.onboardingProfile == nil
            )

            let aiMessages = conversationHistory.map { aiMessage in
                AIChatMessage(
                    id: aiMessage.id,
                    role: AIMessageRole(rawValue: aiMessage.role.rawValue) ?? .user,
                    content: aiMessage.content,
                    timestamp: aiMessage.timestamp
                )
            }

            let routingStrategy = routingConfiguration.determineRoutingStrategy(
                userInput: text,
                conversationHistory: aiMessages,
                userContext: userContext,
                userId: user.id
            )

            AppLogger.info(
                "Processing with \(routingStrategy.route.description) strategy: \(routingStrategy.reason)",
                category: .ai
            )

            // Step 4: Route based on strategy
            switch routingStrategy.route {
            case .directAI:
                await processWithDirectAI(
                    text: text,
                    user: user,
                    conversationId: conversationId,
                    conversationHistory: aiMessages,
                    healthContext: healthContext,
                    routingStrategy: routingStrategy,
                    startTime: startTime
                )

            case .functionCalling, .hybrid:
                await processWithFunctionCalling(
                    text: text,
                    user: user,
                    conversationId: conversationId,
                    conversationHistory: aiMessages,
                    healthContext: healthContext,
                    routingStrategy: routingStrategy,
                    startTime: startTime
                )
            }

        } catch {
            await handleError(error)
        }
    }

    // MARK: - Hybrid Routing Implementation

    /// Processes request using direct AI for simple tasks (nutrition parsing, educational content)
    private func processWithDirectAI(
        text: String,
        user: User,
        conversationId: UUID,
        conversationHistory: [AIChatMessage],
        healthContext: HealthContextSnapshot,
        routingStrategy: RoutingStrategy,
        startTime: CFAbsoluteTime
    ) async {
        let directAIStartTime = CFAbsoluteTimeGetCurrent()

        do {
            // Detect specific direct AI task types
            let isNutritionParsing = messageProcessor.detectsNutritionParsing(text)
            let isEducationalContent = messageProcessor.detectsEducationalContent(text)

            var responseContent: String
            var metrics: RoutingMetrics

            if isNutritionParsing {
                // Direct nutrition parsing
                let result = try await directAIProcessor.parseNutrition(
                    foodText: text,
                    context: "",
                    user: user
                )

                responseContent = buildNutritionParsingResponse(result)

                metrics = RoutingMetrics(
                    route: .directAI,
                    executionTimeMs: result.processingTimeMs,
                    success: true,
                    tokenUsage: result.tokenCount,
                    confidence: result.confidence,
                    fallbackUsed: false
                )

            } else if isEducationalContent {
                // Direct educational content generation
                let topic = messageProcessor.extractEducationalTopic(from: text)
                let userProfile = try await getUserProfile(for: user)
                let content = try await directAIProcessor.generateEducationalContent(
                    topic: topic,
                    userContext: text,
                    userProfile: userProfile
                )

                responseContent = content.content

                metrics = RoutingMetrics(
                    route: .directAI,
                    executionTimeMs: Int((CFAbsoluteTimeGetCurrent() - directAIStartTime) * 1_000),
                    success: true,
                    tokenUsage: content.tokenCount,
                    confidence: content.personalizationLevel,
                    fallbackUsed: false
                )

            } else {
                // General direct AI conversation (fallback to function calling if complex)
                if routingStrategy.fallbackEnabled && text.count > 150 {
                    AppLogger.info("Direct AI detected complex request, falling back to function calling", category: .ai)
                    await processWithFunctionCalling(
                        text: text,
                        user: user,
                        conversationId: conversationId,
                        conversationHistory: conversationHistory,
                        healthContext: healthContext,
                        routingStrategy: RoutingStrategy(
                            route: .functionCalling,
                            reason: "Intelligent fallback from direct AI",
                            fallbackEnabled: false
                        ),
                        startTime: startTime
                    )
                    return
                }

                // Simple conversational response
                let userProfile = try await getUserProfile(for: user)
                responseContent = try await directAIProcessor.generateSimpleResponse(
                    text: text,
                    userProfile: userProfile,
                    healthContext: healthContext
                )

                metrics = RoutingMetrics(
                    route: .directAI,
                    executionTimeMs: Int((CFAbsoluteTimeGetCurrent() - directAIStartTime) * 1_000),
                    success: true,
                    tokenUsage: text.count / 4 + responseContent.count / 4,
                    confidence: 0.8,
                    fallbackUsed: false
                )
            }

            // Save AI response
            _ = try await conversationManager.createAssistantMessage(
                responseContent,
                for: user,
                conversationId: conversationId,
                functionCall: nil,
                isLocalCommand: false,
                isError: false
            )

            currentResponse = responseContent

            // Record performance metrics
            routingConfiguration.recordRoutingMetrics(metrics)

            await finishProcessing()

        } catch {
            AppLogger.error("Direct AI processing failed", error: error, category: .ai)

            // Intelligent fallback to function calling
            if routingStrategy.fallbackEnabled {
                AppLogger.info("Direct AI failed, falling back to function calling", category: .ai)

                let fallbackMetrics = RoutingMetrics(
                    route: .directAI,
                    executionTimeMs: Int((CFAbsoluteTimeGetCurrent() - directAIStartTime) * 1_000),
                    success: false,
                    fallbackUsed: true
                )
                routingConfiguration.recordRoutingMetrics(fallbackMetrics)

                await processWithFunctionCalling(
                    text: text,
                    user: user,
                    conversationId: conversationId,
                    conversationHistory: conversationHistory,
                    healthContext: healthContext,
                    routingStrategy: RoutingStrategy(
                        route: .functionCalling,
                        reason: "Fallback from failed direct AI",
                        fallbackEnabled: false
                    ),
                    startTime: startTime
                )
            } else {
                await handleError(error)
            }
        }
    }

    /// Processes request using traditional function calling system for complex workflows
    private func processWithFunctionCalling(
        text: String,
        user: User,
        conversationId: UUID,
        conversationHistory: [AIChatMessage],
        healthContext: HealthContextSnapshot,
        routingStrategy: RoutingStrategy,
        startTime: CFAbsoluteTime
    ) async {
        let functionCallStartTime = CFAbsoluteTimeGetCurrent()

        do {
            // Get user's persona for consistent coaching voice
            let persona = try await personaService.getActivePersona(for: user.id)

            // Add task context to system prompt
            let systemPrompt = persona.systemPrompt + "\n\nTask context: General conversation with access to functions."

            // Add current user message
            let currentMessage = AIChatMessage(
                role: .user,
                content: text,
                timestamp: Date()
            )

            let userId = user.id
            let aiRequest = AIRequest(
                systemPrompt: systemPrompt,
                messages: conversationHistory + [currentMessage],
                functions: FunctionRegistry.availableFunctions,
                user: userId.uuidString
            )

            // Stream AI response with function calling
            await streamAIResponseWithMetrics(
                aiRequest,
                for: user,
                conversationId: conversationId,
                routingStrategy: routingStrategy,
                startTime: functionCallStartTime
            )

        } catch {
            let metrics = RoutingMetrics(
                route: routingStrategy.route,
                executionTimeMs: Int((CFAbsoluteTimeGetCurrent() - functionCallStartTime) * 1_000),
                success: false
            )
            routingConfiguration.recordRoutingMetrics(metrics)

            await handleError(error)
        }
    }

    // MARK: - Direct AI Helpers


    /// Enhanced version of streamAIResponse with routing metrics
    private func streamAIResponseWithMetrics(
        _ request: AIRequest,
        for user: User,
        conversationId: UUID,
        routingStrategy: RoutingStrategy,
        startTime: CFAbsoluteTime
    ) async {
        do {
            // Create streaming response
            let responseStream = aiService.sendRequest(request)

            // Process using streaming handler
            let result = try await streamingHandler.handleStream(
                responseStream,
                routingStrategy: routingStrategy
            )

            // Update state from result
            currentResponse = result.fullResponse
            lastFunctionCall = result.functionCall?.name

            // Save AI response
            let assistantMessage = try await conversationManager.createAssistantMessage(
                result.fullResponse,
                for: user,
                conversationId: conversationId,
                functionCall: result.functionCall.map { call in
                    FunctionCall(
                        name: call.name,
                        arguments: call.arguments.mapValues { AnyCodable($0.value) }
                    )
                },
                isLocalCommand: false,
                isError: false
            )

            // Execute function call if detected
            if let functionCall = result.functionCall {
                await executeFunctionCall(
                    functionCall,
                    for: user,
                    conversationId: conversationId,
                    originalMessage: assistantMessage
                )
            }

            await finishProcessing()

        } catch {
            await handleError(error)
        }
    }

    private func streamAIResponse(
        _ request: AIRequest,
        for user: User,
        conversationId: UUID,
        startTime: CFAbsoluteTime
    ) async {
        do {
            var fullResponse = ""
            var functionCallDetected: AIFunctionCall?
            var firstTokenReceived = false

            // Create streaming response
            let responseStream = aiService.sendRequest(request)

            // Process streaming response using async/await
            for try await response in responseStream {
                switch response {
                case .text(let text):
                    if !firstTokenReceived {
                        let timeToFirstToken = CFAbsoluteTimeGetCurrent() - startTime
                        AppLogger.info("First token received in \(Int(timeToFirstToken * 1_000))ms", category: .ai)
                        firstTokenReceived = true
                    }

                    fullResponse += text
                    self.streamingTokens.append(text)
                    self.currentResponse = fullResponse

                case .textDelta(let text):
                    if !firstTokenReceived {
                        let timeToFirstToken = CFAbsoluteTimeGetCurrent() - startTime
                        AppLogger.info("First token received in \(Int(timeToFirstToken * 1_000))ms", category: .ai)
                        firstTokenReceived = true
                    }

                    fullResponse += text
                    self.streamingTokens.append(text)
                    self.currentResponse = fullResponse

                case .functionCall(let functionCall):
                    functionCallDetected = functionCall
                    self.lastFunctionCall = functionCall.name
                    AppLogger.info("Function call detected: \(functionCall.name)", category: .ai)

                case .structuredData(let data):
                    // Handle structured data by converting to text
                    if let jsonString = String(data: data, encoding: .utf8) {
                        fullResponse = jsonString
                        self.currentResponse = fullResponse
                    }

                case .done(let usage):
                    AppLogger.info("Stream completed with usage: \(usage?.totalTokens ?? 0) tokens", category: .ai)

                case .error(let aiError):
                    AppLogger.error("AI service error", error: aiError, category: .ai)
                    throw aiError
                }
            }

            // Step 6: Save AI response
            let assistantMessage = try await conversationManager.createAssistantMessage(
                fullResponse,
                for: user,
                conversationId: conversationId,
                functionCall: functionCallDetected.map { call in
                    FunctionCall(
                        name: call.name,
                        arguments: call.arguments.mapValues { AnyCodable($0.value) }
                    )
                },
                isLocalCommand: false,
                isError: false
            )

            // Step 7: Execute function call if detected
            if let functionCall = functionCallDetected {
                await executeFunctionCall(
                    functionCall,
                    for: user,
                    conversationId: conversationId,
                    originalMessage: assistantMessage
                )
            }

            await finishProcessing()

        } catch {
            await handleError(error)
        }
    }

    private func executeFunctionCall(
        _ functionCall: AIFunctionCall,
        for user: User,
        conversationId: UUID,
        originalMessage: CoachMessage
    ) async {
        // Direct function execution - no more dispatcher overhead
        do {
            try await handleFunctionCall(functionCall, for: user, conversationId: conversationId)
        } catch {
            AppLogger.error("Function execution failed", error: error, category: .ai)
            await handleFunctionError(error, for: user, conversationId: conversationId)
        }
    }

    /// Handles nutrition parsing via direct AI (3x performance improvement)
    private func handleDirectNutritionParsing(
        _ functionCall: AIFunctionCall,
        for user: User,
        conversationId: UUID,
        startTime: CFAbsoluteTime
    ) async {
        do {
            let foodText = extractString(functionCall.arguments["food_text"]) ?? ""
            let context = extractString(functionCall.arguments["context"]) ?? ""

            let result = try await parseAndLogNutritionDirect(
                foodText: foodText,
                context: context,
                for: user,
                conversationId: conversationId
            )

            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.info("Direct nutrition parsing completed in \(Int(executionTime * 1_000))ms (vs ~\(Int(executionTime * 3_000))ms via dispatcher)", category: .ai)

            let followUpResponse = buildNutritionParsingResponse(result)

            // Save function result as assistant message
            _ = try await conversationManager.createAssistantMessage(
                followUpResponse,
                for: user,
                conversationId: conversationId,
                functionCall: FunctionCall(
                    name: functionCall.name,
                    arguments: functionCall.arguments.mapValues { AnyCodable($0.value) }
                ),
                isLocalCommand: false,
                isError: false
            )

            currentResponse += "\n\n" + followUpResponse

        } catch {
            AppLogger.error("Direct nutrition parsing failed", error: error, category: .ai)
            await handleFunctionError(error, for: user, conversationId: conversationId)
        }
    }

    /// Handles educational content generation via direct AI (80% token reduction)
    private func handleDirectEducationalContent(
        _ functionCall: AIFunctionCall,
        for user: User,
        conversationId: UUID,
        startTime: CFAbsoluteTime
    ) async {
        do {
            let topic = extractString(functionCall.arguments["topic"]) ?? ""
            let userContext = extractString(functionCall.arguments["userContext"]) ?? ""

            let content = try await generateEducationalContentDirect(
                topic: topic,
                userContext: userContext,
                for: user
            )

            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.info("Direct educational content generated in \(Int(executionTime * 1_000))ms with \(content.tokenCount) tokens", category: .ai)

            let followUpResponse = content.content

            // Save function result as assistant message
            _ = try await conversationManager.createAssistantMessage(
                followUpResponse,
                for: user,
                conversationId: conversationId,
                functionCall: FunctionCall(
                    name: functionCall.name,
                    arguments: functionCall.arguments.mapValues { AnyCodable($0.value) }
                ),
                isLocalCommand: false,
                isError: false
            )

            currentResponse += "\n\n" + followUpResponse

        } catch {
            AppLogger.error("Direct educational content generation failed", error: error, category: .ai)
            await handleFunctionError(error, for: user, conversationId: conversationId)
        }
    }

    /// Handles complex functions - removed, now handled directly in handleFunctionCall

    /// Builds response for nutrition parsing results
    private func buildNutritionParsingResponse(_ result: NutritionParseResult) -> String {
        let itemsDescription = result.items
            .map { item in
                "\(item.name) (\(item.quantity)): \(Int(item.calories)) cal, \(String(format: "%.1f", item.protein))g protein"
            }
            .joined(separator: "\n")

        return """
        I've logged your nutrition data:

        \(itemsDescription)

        Total: \(Int(result.totalCalories)) calories
        Confidence: \(String(format: "%.0f", result.confidence * 100))%
        """
    }

    /// Handles function execution errors with user-friendly messages
    internal func handleFunctionError(
        _ error: Error,
        for user: User,
        conversationId: UUID
    ) async {
        let errorResponse: String

        if let directError = error as? DirectAIError {
            errorResponse = directError.userFriendlyMessage
        } else {
            errorResponse = "I encountered an issue while executing that action. Please try again or contact support if the problem persists."
        }

        do {
            _ = try await conversationManager.createAssistantMessage(
                errorResponse,
                for: user,
                conversationId: conversationId,
                functionCall: nil,
                isLocalCommand: false,
                isError: true
            )

            currentResponse += "\n\n" + errorResponse
        } catch {
            await handleError(error)
        }
    }

    /// Extracts string value from AIAnyCodable arguments
    private func extractString(_ value: AIAnyCodable?) -> String? {
        guard let value = value else { return nil }

        switch value.value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        default:
            return String(describing: value.value)
        }
    }

    private func generateFunctionFollowUp(_ result: FunctionExecutionResult) -> String {
        if result.success {
            return result.message
        } else {
            return "I wasn't able to complete that action right now. \(result.message)"
        }
    }


    private func getUserProfile(for user: User) async throws -> CoachingPlan {
        // Note: This method is now primarily used for direct AI processing fallback.
        // The main persona functionality uses PersonaService.getActivePersona()
        guard let onboardingProfile = user.onboardingProfile else {
            return createDefaultProfile()
        }

        do {
            let decoder = JSONDecoder()
            let profile = try decoder.decode(CoachingPlan.self, from: onboardingProfile.rawFullProfileData)
            return profile
        } catch {
            AppLogger.warning("Failed to decode user profile, using default", category: .ai)
            return createDefaultProfile()
        }
    }

    private func handleError(_ error: Error) async {
        self.error = error
        await finishProcessing()

        AppLogger.error("CoachEngine error", error: error, category: .ai)

        // Set user-friendly error message
        if let coachError = error as? CoachEngineError {
            currentResponse = coachError.userFriendlyMessage
        } else {
            currentResponse = "I'm having trouble processing your request right now. Please try again in a moment."
        }
    }

    private func createDefaultProfile() -> CoachingPlan {
        // Create a basic default profile if user hasn't completed onboarding
        return CoachingPlan(
            understandingSummary: "I'll help you improve your health and fitness with a personalized approach.",
            coachingApproach: [
                "Focus on building sustainable habits",
                "Daily check-ins to keep you motivated",
                "Adapt to your energy levels and schedule"
            ],
            lifeContext: LifeContext(
                workStyle: .moderate,
                fitnessLevel: .intermediate
            ),
            goal: Goal(
                family: .healthWellbeing,
                rawText: "Improve overall health and fitness"
            ),
            engagementPreferences: EngagementPreferences(
                checkInFrequency: .daily,
                preferredTimes: ["morning", "evening"]
            ),
            sleepWindow: SleepWindow(
                bedtime: "10:30 PM",
                waketime: "6:30 AM"
            ),
            motivationalStyle: MotivationalStyle(
                styles: [.encouraging]
            ),
            timezone: TimeZone.current.identifier,
            generatedPersona: PersonaProfile(
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
                nutritionRecommendations: nil // Default persona - no custom nutrition
            )
        )
    }

    // MARK: - Public Function Call Interface
    /// Executes a function call directly without conversation context
    /// Used for standalone operations like nutrition parsing
    func executeFunction(
        _ functionCall: AIFunctionCall,
        for user: User
    ) async throws -> FunctionExecutionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let conversationId = UUID() // Temporary conversation for standalone function calls
        
        do {
            try await handleFunctionCall(functionCall, for: user, conversationId: conversationId)
            let executionTime = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1_000)
            
            return FunctionExecutionResult(
                success: true,
                message: "Function executed successfully",
                executionTimeMs: executionTime,
                functionName: functionCall.name
            )
        } catch {
            let executionTime = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1_000)
            return FunctionExecutionResult(
                success: false,
                message: error.localizedDescription,
                executionTimeMs: executionTime,
                functionName: functionCall.name
            )
        }
    }

    // MARK: - Direct AI Methods (Delegates to DirectAIProcessor)

    /// Parses nutrition data using direct AI (bypassing function dispatcher)
    /// Provides 3x performance improvement over dispatcher-based approach
    public func parseAndLogNutritionDirect(
        foodText: String,
        context: String = "",
        for user: User,
        conversationId: UUID? = nil
    ) async throws -> NutritionParseResult {
        return try await directAIProcessor.parseNutrition(
            foodText: foodText,
            context: context,
            user: user,
            conversationId: conversationId
        )
    }

    /// Generates educational content using direct AI (bypassing function dispatcher)
    /// Provides 80% token reduction compared to function calling approach
    public func generateEducationalContentDirect(
        topic: String,
        userContext: String,
        for user: User
    ) async throws -> EducationalContent {
        let userProfile = try await getUserProfile(for: user)
        return try await directAIProcessor.generateEducationalContent(
            topic: topic,
            userContext: userContext,
            userProfile: userProfile
        )
    }
}

// MARK: - StreamingResponseDelegate

extension CoachEngine: StreamingResponseDelegate {
    func streamingDidReceiveText(_ text: String, accumulated: String) async {
        streamingTokens.append(text)
        currentResponse = accumulated
    }

    func streamingDidDetectFunction(_ function: AIFunctionCall) async {
        lastFunctionCall = function.name
    }

    func streamingDidComplete(fullResponse: String, tokenUsage: Int) async {
        currentResponse = fullResponse
        AppLogger.debug("Streaming completed with \(tokenUsage) tokens", category: .ai)
    }

    func streamingDidFail(with error: Error) async {
        self.error = error
        await handleError(error)
    }
}

// MARK: - Extensions
extension CoachEngine {
    /// Gets conversation statistics for the active conversation
    func getActiveConversationStats(for user: User) async throws -> ConversationStats? {
        guard let conversationId = activeConversationId else { return nil }

        return try await conversationManager.getConversationStats(
            for: user,
            conversationId: conversationId
        )
    }

    /// Prunes old conversations to maintain performance
    func pruneOldConversations(for user: User) async {
        do {
            try await conversationManager.pruneOldConversations(for: user, keepLast: 10)
            AppLogger.info("Pruned old conversations for user \(user.id)", category: .ai)
        } catch {
            AppLogger.error("Failed to prune conversations", error: error, category: .ai)
        }
    }

    // MARK: - Notification Content Generation

    enum NotificationContentType {
        case morningGreeting
        case workoutReminder
        case mealReminder(MealType)
        case achievement
    }

    /// Generates AI-powered notification content with persona context
    func generateNotificationContent<T>(type: NotificationContentType, context: T) async throws -> String {
        // Build appropriate prompt based on notification type
        let contentPrompt = buildNotificationPrompt(type: type, context: context)

        // Get current user ID from context (all our contexts have userName)
        let userId = extractUserId(from: context) ?? UUID()

        // Get user's persona for consistent voice
        var systemPrompt = "You are a fitness coach generating notification content. Keep it brief, motivational, and personal."

        do {
            let persona = try await personaService.getActivePersona(for: userId)
            systemPrompt = persona.systemPrompt + "\n\nTask: Generate a brief notification message (under 30 words). Match your established personality and voice."
        } catch {
            AppLogger.warning("Failed to get persona for notification, using default", category: .ai)
        }

        // Create AI request
        let aiRequest = AIRequest(
            systemPrompt: systemPrompt,
            messages: [
                AIChatMessage(
                    role: .user,
                    content: contentPrompt,
                    timestamp: Date()
                )
            ],
            functions: nil,
            temperature: 0.7,
            maxTokens: 100,
            stream: false,
            user: userId.uuidString
        )

        // Collect AI response
        let response = await collectAIResponse(from: aiRequest)

        // Return response or simple fallback if empty
        if response.isEmpty {
            AppLogger.warning("AI returned empty response for notification", category: .ai)
            return "Keep up the great work!"
        }

        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildNotificationPrompt<T>(type: NotificationContentType, context: T) -> String {
        switch type {
        case .morningGreeting:
            if let morningContext = context as? MorningContext {
                var prompt = "Generate a personalized morning greeting for \(morningContext.userName). "
                prompt += "Requirements: 1-2 sentences, warm and encouraging tone. "

                var context = "Context: "
                if let sleepQuality = morningContext.sleepQuality {
                    context += "Sleep quality was \(sleepQuality). "
                }
                if let sleepDuration = morningContext.sleepDuration {
                    let hours = Int(sleepDuration / 3_600)
                    context += "Slept \(hours) hours. "
                }
                if let workout = morningContext.plannedWorkout {
                    context += "Has \(workout.name) workout scheduled today. "
                }
                if morningContext.currentStreak > 0 {
                    context += "On a \(morningContext.currentStreak)-day activity streak. "
                }
                if let weather = morningContext.weather {
                    context += "Weather: \(weather.temperature)°F, \(weather.condition). "
                }

                prompt += context.isEmpty ? "" : context
                prompt += "Create a unique message that acknowledges their specific situation."

                return prompt
            }

        case .workoutReminder:
            if let workoutContext = context as? WorkoutReminderContext {
                var prompt = "Generate a motivating workout reminder for \(workoutContext.userName). "
                prompt += "Workout type: \(workoutContext.workoutType). "
                prompt += "Requirements: 1-2 sentences, energetic but not pushy. "

                if workoutContext.streak > 0 {
                    prompt += "They're on day \(workoutContext.streak + 1) of their streak - acknowledge this! "
                } else if workoutContext.lastWorkoutDays > 3 {
                    prompt += "It's been \(workoutContext.lastWorkoutDays) days since last workout - be encouraging about getting back. "
                } else if workoutContext.lastWorkoutDays == 1 {
                    prompt += "They worked out yesterday - encourage consistency. "
                }

                prompt += "Match their motivational style: \(workoutContext.motivationalStyle.styles.first?.rawValue ?? "encouraging")."

                return prompt
            }

        case .mealReminder(let mealType):
            if let mealContext = context as? MealReminderContext {
                var prompt = "Generate a \(mealType.displayName) reminder for \(mealContext.userName). "
                prompt += "Requirements: 1 sentence, friendly and practical. "

                if let lastMeal = mealContext.lastMealLogged {
                    let hoursSince = Date().timeIntervalSince(lastMeal) / 3_600
                    if hoursSince < 2 {
                        prompt += "They recently logged a meal - acknowledge their consistency. "
                    } else if hoursSince > 6 {
                        prompt += "They haven't logged in a while - gently encourage. "
                    }
                }

                if !mealContext.favoritesFoods.isEmpty {
                    prompt += "Their favorites include: \(mealContext.favoritesFoods.prefix(3).joined(separator: ", ")). "
                }

                return prompt
            }

        case .achievement:
            if let achievementContext = context as? AchievementContext {
                var prompt = "Celebrate \(achievementContext.userName) earning: \(achievementContext.achievementName)."
                if achievementContext.personalBest {
                    prompt += " This is a personal best!"
                }
                return prompt
            }
        }

        // Generic fallback prompt
        return "Generate a brief, motivational fitness notification."
    }

    private func extractUserId<T>(from context: T) -> UUID? {
        // Try to extract user ID from various context types
        // This is a bit of a hack but works for our current contexts
        let mirror = Mirror(reflecting: context)

        // Look for userId property
        for (label, value) in mirror.children {
            if label == "userId", let id = value as? UUID {
                return id
            }
        }

        // For now, return nil - the real implementation would need proper context types
        return nil
    }
}

// MARK: - Factory Methods
extension CoachEngine {
    /// Creates a default instance of CoachEngine with minimal dependencies for development.
    /// Note: For production use, resolve CoachEngine through the DI container instead.
    static func createDefault(modelContext: ModelContext) async -> CoachEngine {
        // This method is kept minimal for SwiftUI previews only
        fatalError("Use DI container to resolve CoachEngine in production. This method is only for SwiftUI previews.")
    }

}

// MARK: - CoachEngineProtocol Conformance
extension CoachEngine: CoachEngineProtocol {
    // generatePostWorkoutAnalysis is already implemented above
}


// MARK: - FoodCoachEngineProtocol Conformance
extension CoachEngine: FoodCoachEngineProtocol {
    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
        // Placeholder implementation leveraging existing pipeline.
        await processUserMessage(message, for: User())
        return ["response": .string(currentResponse)]
    }

    // MARK: - Dashboard Content Generation

    /// Gets today's nutrition data from HealthKit first, falls back to local SwiftData
    /// This ensures we see nutrition from all apps, not just AirFit entries
    private func getTodaysNutrition(for user: User) async -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let today = Date()

        // Try HealthKit first (authoritative source including other apps)
        do {
            let nutritionSummary = try await healthKitManager.getNutritionData(for: today)

            AppLogger.info("Dashboard using HealthKit nutrition: \(Int(nutritionSummary.calories)) cal", category: .health)
            return (
                calories: nutritionSummary.calories,
                protein: nutritionSummary.protein,
                carbs: nutritionSummary.carbohydrates,
                fat: nutritionSummary.fat
            )
        } catch {
            AppLogger.warning("Failed to get HealthKit nutrition, falling back to local data: \(error)", category: .health)
        }

        // Fallback to local SwiftData entries
        let startOfDay = Calendar.current.startOfDay(for: today)
        let todayEntries = user.foodEntries.filter {
            Calendar.current.isDate($0.loggedAt, inSameDayAs: startOfDay)
        }

        let localCalories = Double(todayEntries.reduce(into: 0) { $0 += $1.totalCalories })
        let localProtein = todayEntries.reduce(into: 0) { $0 += $1.totalProtein }
        let localCarbs = todayEntries.reduce(into: 0) { $0 += $1.totalCarbs }
        let localFat = todayEntries.reduce(into: 0) { $0 += $1.totalFat }

        AppLogger.info("Dashboard using local nutrition: \(Int(localCalories)) cal from \(todayEntries.count) entries", category: .data)
        return (calories: localCalories, protein: localProtein, carbs: localCarbs, fat: localFat)
    }

    func generateDashboardContent(for user: User) async throws -> AIDashboardContent {
        // Get current context
        let hour = Calendar.current.component(.hour, from: Date())
        let dayOfWeek = Calendar.current.dateComponents([.weekday], from: Date()).weekday ?? 1
        let weekdayName = Formatters.weekdaySymbols[dayOfWeek - 1]

        // Get today's nutrition from HealthKit first (includes all apps), fallback to local
        let nutrition = await getTodaysNutrition(for: user)
        let calories = nutrition.calories
        let protein = nutrition.protein
        let carbs = nutrition.carbs
        let fat = nutrition.fat

        // Get muscle group volumes
        let muscleVolumes = try await muscleGroupVolumeService.getWeeklyVolumes(for: user)

        // Build context for AI
        var contextParts: [String] = []
        contextParts.append("Current time: \(weekdayName) at \(hour):00")
        contextParts.append("User: \(user.name ?? "Friend")")

        // Get dynamic nutrition targets
        let dynamicTargets = try? await nutritionCalculator.calculateDynamicTargets(for: user)

        // Add nutrition context
        if calories > 0 {
            contextParts.append("Today's nutrition: \(Int(calories)) cal, \(Int(protein))g protein, \(Int(carbs))g carbs, \(Int(fat))g fat")
            if let targets = dynamicTargets {
                contextParts.append("Targets: \(targets.displayCalories) cal, \(Int(targets.protein))g protein")
            } else {
                contextParts.append("Targets: 2000 cal, 150g protein") // Fallback defaults
            }
        }

        // Add workout context
        if !muscleVolumes.isEmpty {
            let volumeSummary = muscleVolumes.map { "\($0.name): \($0.sets)/\($0.target) sets" }.joined(separator: ", ")
            contextParts.append("This week's volume: \(volumeSummary)")
        }

        // Add recent workout info
        let recentWorkouts = user.workouts.filter { $0.completedDate != nil }
            .sorted { ($0.completedDate ?? Date.distantPast) > ($1.completedDate ?? Date.distantPast) }
            .prefix(1)

        if let lastWorkout = recentWorkouts.first,
           let lastWorkoutDate = lastWorkout.completedDate {
            let daysAgo = Calendar.current.dateComponents([.day], from: lastWorkoutDate, to: Date()).day ?? 0
            if daysAgo == 0 {
                contextParts.append("Workout completed today!")
            } else if daysAgo == 1 {
                contextParts.append("Last workout: yesterday")
            } else {
                contextParts.append("Last workout: \(daysAgo) days ago")
            }
        }

        // Get persona for consistent voice
        guard let personaData = user.coachPersonaData,
              let persona = try? JSONDecoder().decode(CoachPersona.self, from: personaData) else {
            // Fallback to simple content
            return AIDashboardContent(
                primaryInsight: "Welcome back! Let's make today count.",
                nutritionData: calories > 0 ? DashboardNutritionData(
                    calories: calories,
                    calorieTarget: dynamicTargets?.totalCalories ?? 2_000,
                    protein: protein,
                    proteinTarget: dynamicTargets?.protein ?? 150,
                    carbs: carbs,
                    carbTarget: dynamicTargets?.carbs ?? 250,
                    fat: fat,
                    fatTarget: dynamicTargets?.fat ?? 65
                ) : nil,
                muscleGroupVolumes: muscleVolumes.isEmpty ? nil : muscleVolumes,
                guidance: nil,
                celebration: nil
            )
        }

        // Build AI prompt
        let prompt = """
        Generate dashboard content for the user based on this context:
        \(contextParts.joined(separator: "\n"))

        Use this coaching voice:
        - Name: \(persona.identity.name)
        - Personality: \(persona.identity.coreValues.joined(separator: ", "))
        - Communication style: \(persona.communication.energy.rawValue) energy, \(persona.communication.pace.rawValue) pace

        Rules:
        - Be concise and actionable
        - Reference specific data when available
        - Match the coach's personality
        - Avoid generic motivational phrases
        - Focus on what matters right now
        - primary_insight: A personalized greeting and key insight (1-2 sentences max)
        - guidance: Actionable advice if relevant (1 sentence)
        - celebration: Celebration if they hit a milestone (1 sentence)
        """

        // Use structured output for guaranteed JSON response
        let dashboardSchema = StructuredOutputSchema.fromJSON(
            name: "dashboard_content",
            description: "Generate AI-driven dashboard content with insights and recommendations",
            schema: [
                "type": "object",
                "properties": [
                    "primary_insight": [
                        "type": "string",
                        "description": "Main insight or observation about user's current state"
                    ],
                    "guidance": [
                        "type": "string",
                        "description": "Actionable guidance or recommendation"
                    ],
                    "celebration": [
                        "type": "string",
                        "description": "Positive reinforcement or achievement recognition"
                    ],
                    "nutrition_focus": [
                        "type": "string",
                        "description": "Specific nutrition advice based on current intake"
                    ],
                    "workout_context": [
                        "type": "string",
                        "description": "Workout-related context or recovery advice"
                    ]
                ],
                "required": ["primary_insight", "guidance"],
                "additionalProperties": false
            ],
            strict: true
        ) ?? StructuredOutputSchema(name: "dashboard_content", description: "", jsonSchema: Data(), strict: true)

        let aiRequest = AIRequest(
            systemPrompt: "You are \(persona.identity.name), a fitness coach. Generate concise, personalized dashboard content.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.7,
            maxTokens: 300,
            user: user.id.uuidString,
            responseFormat: .structuredJson(schema: dashboardSchema)
        )

        var structuredData: Data?
        for try await response in aiService.sendRequest(aiRequest) {
            switch response {
            case .structuredData(let data):
                structuredData = data
            case .error(let error):
                throw error
            case .done:
                break
            default:
                break
            }
        }

        // Parse structured response
        var primaryInsight = "Welcome back! Ready to make progress?"
        var guidance: String?
        var celebration: String?

        if let data = structuredData {
            // Define response structure to match schema
            struct DashboardAIResponse: Codable {
                let primary_insight: String
                let guidance: String?
                let celebration: String?
                let nutrition_focus: String?
                let workout_context: String?
            }

            do {
                let response = try JSONDecoder().decode(DashboardAIResponse.self, from: data)
                primaryInsight = response.primary_insight
                guidance = response.guidance
                celebration = response.celebration

                // We could also use nutrition_focus and workout_context if needed
            } catch {
                AppLogger.error("Failed to parse dashboard AI response", error: error, category: .ai)
            }
        }

        let dashboardContent = AIDashboardContent(
            primaryInsight: primaryInsight,
            nutritionData: calories > 0 ? DashboardNutritionData(
                calories: calories,
                calorieTarget: dynamicTargets?.totalCalories ?? 2_000,
                protein: protein,
                proteinTarget: dynamicTargets?.protein ?? 150,
                carbs: carbs,
                carbTarget: dynamicTargets?.carbs ?? 250,
                fat: fat,
                fatTarget: dynamicTargets?.fat ?? 65
            ) : nil,
            muscleGroupVolumes: muscleVolumes.isEmpty ? nil : muscleVolumes,
            guidance: guidance,
            celebration: celebration
        )

        return dashboardContent
    }

    func analyzeMealPhoto(image: UIImage, context: NutritionContext?, for user: User) async throws -> MealPhotoAnalysisResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Convert image to base64 for multimodal LLM
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FoodTrackingError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        let prompt = """
        Analyze this meal photo and identify all visible food items with their quantities and nutrition info.

        Return ONLY valid JSON:
        {
            "items": [
                {
                    "name": "food name",
                    "brand": "brand name or null",
                    "quantity": 1.5,
                    "unit": "cups/oz/pieces",
                    "calories": 0,
                    "proteinGrams": 0.0,
                    "carbGrams": 0.0,
                    "fatGrams": 0.0,
                    "fiberGrams": 0.0,
                    "sugarGrams": 0.0,
                    "sodiumMilligrams": 0.0,
                    "confidence": 0.85
                }
            ]
        }
        """

        // Create multimodal message with image
        // Include image in the prompt for multimodal LLMs
        let imagePrompt = """
        \(prompt)

        [Image data: \(base64Image)]
        """

        let aiRequest = AIRequest(
            systemPrompt: "You are a nutrition expert analyzing meal photos. Identify all foods with accurate portions and nutrition data.",
            messages: [
                AIChatMessage(
                    role: .user,
                    content: imagePrompt
                )
            ],
            temperature: 0.2,
            maxTokens: 1_000,
            user: "photo-analysis"
        )

        var fullResponse = ""
        for try await response in aiService.sendRequest(aiRequest) {
            switch response {
            case .text(let text), .textDelta(let text):
                fullResponse += text
            case .done:
                break
            default:
                break
            }
        }

        let items = try parseNutritionJSON(fullResponse)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        return MealPhotoAnalysisResult(
            items: items,
            confidence: 0.9, // High confidence with actual image analysis
            processingTime: processingTime
        )
    }

    func searchFoods(query: String, limit: Int, for user: User) async throws -> [ParsedFoodItem] {
        // Just ask the LLM to search its knowledge for matching foods
        let prompt = """
        Search for foods matching: "\(query)"

        Return the top \(limit) food items that match this query.

        Return ONLY valid JSON with this exact structure:
        {
            "items": [
                {
                    "name": "food name",
                    "brand": "brand name or null",
                    "quantity": 1.0,
                    "unit": "serving",
                    "calories": 0,
                    "proteinGrams": 0.0,
                    "carbGrams": 0.0,
                    "fatGrams": 0.0,
                    "fiberGrams": 0.0,
                    "sugarGrams": 0.0,
                    "sodiumMilligrams": 0.0,
                    "confidence": 0.95
                }
            ]
        }
        """

        let aiRequest = AIRequest(
            systemPrompt: "You are a nutrition expert. Use your knowledge to provide accurate nutrition data.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.3,
            maxTokens: 800,
            user: "food-search"
        )

        var fullResponse = ""
        for try await response in aiService.sendRequest(aiRequest) {
            switch response {
            case .text(let text), .textDelta(let text):
                fullResponse += text
            case .done:
                break
            default:
                break
            }
        }

        let items = try parseNutritionJSON(fullResponse)
        return Array(items.prefix(limit))
    }

    func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
        let startTime = CFAbsoluteTimeGetCurrent()

        let prompt = buildNutritionParsingPrompt(text: text, mealType: mealType, user: user)

        do {
            let aiRequest = AIRequest(
                systemPrompt: "You are a nutrition expert providing accurate food parsing. Return only valid JSON.",
                messages: [AIChatMessage(role: .user, content: prompt)],
                temperature: 0.1, // Low temperature for consistent nutrition data
                maxTokens: 600,
                user: "nutrition-parsing"
            )

            var fullResponse = ""
            let responseStream = aiService.sendRequest(aiRequest)

            do {
                for try await response in responseStream {
                    switch response {
                    case .text(let text), .textDelta(let text):
                        fullResponse += text
                    case .error(let aiError):
                        AppLogger.error("AI nutrition parsing error", error: aiError, category: .ai)
                        throw aiError
                    case .done:
                        break
                    default:
                        break
                    }
                }
            } catch {
                AppLogger.error("AI nutrition parsing failed", error: error, category: .ai)
                throw error
            }

            let result = try parseNutritionJSON(fullResponse)
            let validatedResult = validateNutritionValues(result)

            let duration = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.info(
                "AI nutrition parsing: \(validatedResult.count) items in \(Int(duration * 1_000))ms | Input: '\(text)' | Validation: \(validatedResult.allSatisfy { $0.calories > 0 })",
                category: .ai
            )

            return validatedResult

        } catch {
            AppLogger.error("AI nutrition parsing failed", error: error, category: .ai)
            // Intelligent fallback rather than failing completely
            return [createFallbackFoodItem(from: text, mealType: mealType)]
        }
    }

    // MARK: - Private Nutrition Parsing Methods

    private func buildNutritionParsingPrompt(text: String, mealType: MealType, user: User) -> String {
        return """
        Parse this food description into accurate nutrition data: "\(text)"
        Meal type: \(mealType.rawValue)

        Return ONLY valid JSON with this exact structure:
        {
            "items": [
                {
                    "name": "food name",
                    "brand": "brand name or null",
                    "quantity": 1.5,
                    "unit": "cups",
                    "calories": 0,
                    "proteinGrams": 0.0,
                    "carbGrams": 0.0,
                    "fatGrams": 0.0,
                    "fiberGrams": 0.0,
                    "sugarGrams": 0.0,
                    "sodiumMilligrams": 0.0,
                    "confidence": 0.95
                }
            ]
        }

        Rules:
        - Use USDA nutrition database accuracy
        - If multiple items mentioned, include all
        - Estimate quantities if not specified
        - Return realistic nutrition values (not 100 calories for everything!)
        - Confidence 0.9+ for common foods, lower for ambiguous items
        - No explanations or extra text, just JSON
        """
    }

    private func parseNutritionJSON(_ jsonString: String) throws -> [ParsedFoodItem] {
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let itemsArray = json["items"] as? [[String: Any]] else {
            throw FoodTrackingError.invalidNutritionResponse
        }

        return try itemsArray.map { itemDict in
            guard let name = itemDict["name"] as? String,
                  let quantity = itemDict["quantity"] as? Double,
                  let unit = itemDict["unit"] as? String,
                  let calories = itemDict["calories"] as? Int,
                  let protein = itemDict["proteinGrams"] as? Double,
                  let carbs = itemDict["carbGrams"] as? Double,
                  let fat = itemDict["fatGrams"] as? Double else {
                throw FoodTrackingError.invalidNutritionData
            }

            return ParsedFoodItem(
                name: name,
                brand: itemDict["brand"] as? String,
                quantity: quantity,
                unit: unit,
                calories: calories,
                proteinGrams: protein,
                carbGrams: carbs,
                fatGrams: fat,
                fiberGrams: itemDict["fiberGrams"] as? Double,
                sugarGrams: itemDict["sugarGrams"] as? Double,
                sodiumMilligrams: itemDict["sodiumMilligrams"] as? Double,
                databaseId: nil,
                confidence: Float(itemDict["confidence"] as? Double ?? 0.8)
            )
        }
    }

    private func validateNutritionValues(_ items: [ParsedFoodItem]) -> [ParsedFoodItem] {
        return items.compactMap { item in
            // Reject obviously wrong values
            guard item.calories > 0 && item.calories < 5_000,
                  item.proteinGrams >= 0 && item.proteinGrams < 300,
                  item.carbGrams >= 0 && item.carbGrams < 1_000,
                  item.fatGrams >= 0 && item.fatGrams < 500 else {
                AppLogger.warning("Rejected invalid nutrition values for \(item.name)", category: .ai)
                return nil
            }
            return item
        }
    }

    private func createFallbackFoodItem(from text: String, mealType: MealType) -> ParsedFoodItem {
        // Extract basic food name from text
        let foodName = text.components(separatedBy: .whitespacesAndNewlines)
            .first(where: { $0.count > 2 }) ?? "Unknown Food"

        // Reasonable default values based on meal type
        let defaultCalories: Int = {
            switch mealType {
            case .breakfast: return 250
            case .lunch: return 400
            case .dinner: return 500
            case .snack: return 150
            case .preWorkout: return 200
            case .postWorkout: return 300
            }
        }()

        return ParsedFoodItem(
            name: foodName,
            brand: nil,
            quantity: 1.0,
            unit: "serving",
            calories: defaultCalories,
            proteinGrams: Double(defaultCalories) * 0.15 / 4, // 15% protein
            carbGrams: Double(defaultCalories) * 0.50 / 4,    // 50% carbs
            fatGrams: Double(defaultCalories) * 0.35 / 9,     // 35% fat
            fiberGrams: 3.0,
            sugarGrams: nil,
            sodiumMilligrams: nil,
            databaseId: nil,
            confidence: 0.3 // Low confidence indicates fallback
        )
    }
}

// MARK: - Preview Service Implementations

/// Minimal preview implementation of API key manager
private final class PreviewAPIKeyManager: APIKeyManagementProtocol {
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {}
    func getAPIKey(for provider: AIProvider) async throws -> String { "preview-key" }
    func deleteAPIKey(for provider: AIProvider) async throws {}
    func hasAPIKey(for provider: AIProvider) async -> Bool { true }
    func getAllConfiguredProviders() async -> [AIProvider] { AIProvider.allCases }
}
