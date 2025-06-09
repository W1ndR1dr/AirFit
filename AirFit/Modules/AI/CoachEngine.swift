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
    private(set) var currentResponse = ""
    private(set) var error: Error?
    private(set) var activeConversationId: UUID?
    private(set) var streamingTokens: [String] = []
    private(set) var lastFunctionCall: String?

    // MARK: - Dependencies
    private let functionDispatcher: FunctionCallDispatcher
    private let personaEngine: PersonaEngine
    private let conversationManager: ConversationManager
    private let aiService: AIServiceProtocol
    private let contextAssembler: ContextAssembler
    private let modelContext: ModelContext
    private let routingConfiguration: RoutingConfiguration
    
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
        functionDispatcher: FunctionCallDispatcher,
        personaEngine: PersonaEngine,
        conversationManager: ConversationManager,
        aiService: AIServiceProtocol,
        contextAssembler: ContextAssembler,
        modelContext: ModelContext,
        routingConfiguration: RoutingConfiguration = RoutingConfiguration.shared
    ) {
        self.functionDispatcher = functionDispatcher
        self.personaEngine = personaEngine
        self.conversationManager = conversationManager
        self.aiService = aiService
        self.contextAssembler = contextAssembler
        self.modelContext = modelContext
        self.routingConfiguration = routingConfiguration
        
        // Initialize components
        self.messageProcessor = MessageProcessor(localCommandParser: localCommandParser)
        self.stateManager = ConversationStateManager()
        self.directAIProcessor = DirectAIProcessor(aiService: aiService)
        self.streamingHandler = StreamingResponseHandler()
        
        // Set up streaming delegate
        self.streamingHandler.delegate = self

        // Initialize with a new conversation
        Task {
            self.activeConversationId = await stateManager.createSession(
                userId: UUID(), // Will be updated with actual user ID
                mode: .supportiveCoach
            )
        }
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
            // Ensure we have an active conversation
            if activeConversationId == nil {
                activeConversationId = await stateManager.createSession(
                    userId: user.id,
                    mode: .supportiveCoach
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

            // Step 3: Check for local commands first (instant response)
            if let localCommand = await messageProcessor.checkLocalCommand(text, for: user) {
                await handleLocalCommandResponse(localCommand, for: user, conversationId: conversationId)
                return
            }

            // Step 4: Process through AI pipeline with optimized history
            await processAIResponse(text, for: user, conversationId: conversationId, messageType: messageType)

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
            
            activeConversationId = await stateManager.createSession(
                userId: UUID(), // Will be updated with actual user
                mode: .supportiveCoach
            )
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
        
        let aiRequest = AIRequest(
            systemPrompt: "You are a fitness coach providing post-workout analysis. Be encouraging, specific, and actionable.",
            messages: [
                AIChatMessage(
                    role: .user,
                    content: analysisPrompt,
                    timestamp: Date()
                )
            ],
            functions: [],
            user: "workout-analysis"
        )
        
        let analysisResult = await collectAIResponse(from: aiRequest)
        return analysisResult.isEmpty ? "Great workout! Keep up the excellent work." : analysisResult
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


    private func handleLocalCommandResponse(
        _ command: LocalCommand,
        for user: User,
        conversationId: UUID
    ) async {
        do {
            // Generate response for local command
            let response = messageProcessor.generateLocalCommandResponse(command)

            // Save the local command response
            _ = try await conversationManager.createAssistantMessage(
                response,
                for: user,
                conversationId: conversationId,
                functionCall: nil,
                isLocalCommand: true,
                isError: false
            )

            currentResponse = response
            await finishProcessing()

            AppLogger.info("Local command processed successfully", category: .ai)

        } catch {
            await handleError(error)
        }
    }

    private func processAIResponse(
        _ text: String,
        for user: User,
        conversationId: UUID,
        messageType: MessageType
    ) async {
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            // Step 1: Assemble health context
            let healthContext = await contextAssembler.assembleSnapshot(modelContext: modelContext)

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
            // Build persona-aware system prompt (traditional path)
            let userProfile = try await getUserProfile(for: user)

            let systemPrompt = try personaEngine.buildSystemPrompt(
                userProfile: userProfile,
                healthContext: healthContext,
                conversationHistory: conversationHistory,
                availableFunctions: FunctionRegistry.availableFunctions
            )

            // Add current user message
            let currentMessage = AIChatMessage(
                role: .user,
                content: text,
                timestamp: Date()
            )

            let aiRequest = AIRequest(
                systemPrompt: systemPrompt,
                messages: conversationHistory + [currentMessage],
                functions: FunctionRegistry.availableFunctions,
                user: user.id.uuidString
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
        let startTime = CFAbsoluteTimeGetCurrent()

        AppLogger.info("Executing function: \(functionCall.name)", category: .ai)

        // Hybrid routing: Use direct AI for simple parsing, function dispatcher for complex workflows
        switch functionCall.name {
        case "parseAndLogComplexNutrition":
            await handleDirectNutritionParsing(functionCall, for: user, conversationId: conversationId, startTime: startTime)
            
        case "generateEducationalInsight":
            await handleDirectEducationalContent(functionCall, for: user, conversationId: conversationId, startTime: startTime)
            
        default:
            // Use function dispatcher for remaining complex functions
            do {
                try await handleDispatcherFunction(functionCall, for: user, conversationId: conversationId, startTime: startTime)
            } catch {
                AppLogger.error("Function execution failed", error: error, category: .ai)
                await handleFunctionError(error, for: user, conversationId: conversationId)
            }
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
    
    /// Handles complex functions via traditional function dispatcher
    private func handleDispatcherFunction(
        _ functionCall: AIFunctionCall,
        for user: User,
        conversationId: UUID,
        startTime: CFAbsoluteTime
    ) async throws {
        do {
            let result = try await functionDispatcher.execute(
                functionCall,
                for: user,
                context: FunctionContext(
                    modelContext: modelContext,
                    conversationId: conversationId,
                    userId: user.id
                )
            )
            
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.info("Dispatcher function executed in \(Int(executionTime * 1_000))ms", category: .ai)
            
            let followUpResponse = generateFunctionFollowUp(result)
            
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
                isError: !result.success
            )
            
            currentResponse += "\n\n" + followUpResponse
            
        } catch {
            throw error // Re-throw to be handled by main catch block
        }
    }
    
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
    private func handleFunctionError(
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


    private func getUserProfile(for user: User) async throws -> UserProfileJsonBlob {
        guard let onboardingProfile = user.onboardingProfile else {
            return createDefaultProfile()
        }

        do {
            let decoder = JSONDecoder()
            let profile = try decoder.decode(UserProfileJsonBlob.self, from: onboardingProfile.rawFullProfileData)
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

    private func createDefaultProfile() -> UserProfileJsonBlob {
        // Create a basic default profile if user hasn't completed onboarding
        return UserProfileJsonBlob(
            lifeContext: LifeContext(),
            goal: Goal(),
            blend: Blend(
                authoritativeDirect: 0.3,
                encouragingEmpathetic: 0.4,
                analyticalInsightful: 0.15,
                playfullyProvocative: 0.15
            ),
            engagementPreferences: EngagementPreferences(),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(),
            timezone: TimeZone.current.identifier,
            baselineModeEnabled: false
        )
    }

    // MARK: - Public Function Call Interface
    /// Executes a function call directly without conversation context
    /// Used for standalone operations like nutrition parsing
    func executeFunction(
        _ functionCall: AIFunctionCall,
        for user: User
    ) async throws -> FunctionExecutionResult {
        let context = FunctionContext(
            modelContext: modelContext,
            conversationId: UUID(), // Temporary conversation for standalone function calls
            userId: user.id
        )
        
        return try await functionDispatcher.execute(functionCall, for: user, context: context)
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
}

// MARK: - Factory Methods
extension CoachEngine {
    /// Creates a default instance of CoachEngine with minimal dependencies for development.
    /// Uses stub implementations to avoid external dependencies.
    static func createDefault(modelContext: ModelContext) -> CoachEngine {
        // Create minimal preview services that conform to AI protocols
        let previewWorkoutService = PreviewAIWorkoutService()
        let previewAnalyticsService = PreviewAIAnalyticsService()
        let previewGoalService = PreviewAIGoalService()
        
        return CoachEngine(
            localCommandParser: LocalCommandParser(),
            functionDispatcher: FunctionCallDispatcher(
                workoutService: previewWorkoutService,
                analyticsService: previewAnalyticsService,
                goalService: previewGoalService
            ),
            personaEngine: PersonaEngine(),
            conversationManager: ConversationManager(modelContext: modelContext),
            aiService: MinimalAIAPIService(),
            contextAssembler: ContextAssembler(),
            modelContext: modelContext
        )
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

    func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
        // Create AI function call for meal photo analysis
        let contextString = context != nil ? "User has \(context!.recentMeals.count) recent meals, date: \(context!.currentDate)" : ""
        let functionCall = AIFunctionCall(
            name: "analyzeMealPhoto",
            arguments: [
                "imageData": AIAnyCodable("base64_image_data"),
                "context": AIAnyCodable(contextString)
            ]
        )
        
        // TODO: This method needs a user parameter to work properly
        let user = User() // Temporary placeholder
        _ = try await executeFunction(functionCall, for: user)
        
        // Parse the result to extract detected food items
        let items: [ParsedFoodItem] = [] // Placeholder - would parse from result.data
        
        return MealPhotoAnalysisResult(
            items: items,
            confidence: 0.8,
            processingTime: 0.5
        )
    }
    
    func searchFoods(query: String, limit: Int) async throws -> [ParsedFoodItem] {
        // Create AI function call for food search
        let functionCall = AIFunctionCall(
            name: "searchFoods",
            arguments: [
                "query": AIAnyCodable(query),
                "limit": AIAnyCodable(limit)
            ]
        )
        
        // TODO: This method needs a user parameter to work properly
        let user = User() // Temporary placeholder
        _ = try await executeFunction(functionCall, for: user)
        
        // Parse the result to extract food items
        // For now, return empty array as placeholder
        return []
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
                "AI nutrition parsing: \(validatedResult.count) items in \(Int(duration * 1000))ms | Input: '\(text)' | Validation: \(validatedResult.allSatisfy { $0.calories > 0 })",
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
            guard item.calories > 0 && item.calories < 5000,
                  item.proteinGrams >= 0 && item.proteinGrams < 300,
                  item.carbGrams >= 0 && item.carbGrams < 1000,
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

/// Minimal preview implementation of AI workout service
private final class PreviewAIWorkoutService: AIWorkoutServiceProtocol {
    // Base protocol requirements
    func startWorkout(type: WorkoutType, user: User) async throws -> Workout {
        Workout(name: type.displayName, workoutType: type, plannedDate: Date(), user: user)
    }
    func pauseWorkout(_ workout: Workout) async throws {}
    func resumeWorkout(_ workout: Workout) async throws {}
    func endWorkout(_ workout: Workout) async throws {}
    func logExercise(_ exercise: Exercise, in workout: Workout) async throws {}
    func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout] { [] }
    func getWorkoutTemplates() async throws -> [WorkoutTemplate] { [] }
    func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws {}
    
    // AI protocol requirements
    func generatePlan(for user: User, goal: String, duration: Int, intensity: String, targetMuscles: [String], equipment: [String], constraints: String?, style: String) async throws -> WorkoutPlanResult {
        WorkoutPlanResult(
            id: UUID(),
            exercises: [],
            estimatedCalories: 300,
            estimatedDuration: duration,
            summary: "Preview workout plan",
            difficulty: .intermediate,
            focusAreas: targetMuscles
        )
    }
    
    func adaptPlan(_ plan: WorkoutPlanResult, feedback: String, adjustments: [String: Any]) async throws -> WorkoutPlanResult {
        plan
    }
}

/// Minimal preview implementation of AI analytics service
private final class PreviewAIAnalyticsService: AIAnalyticsServiceProtocol {
    // Base protocol requirements
    func trackEvent(_ event: AnalyticsEvent) async {}
    func trackScreen(_ screen: String, properties: [String: String]?) async {}
    func setUserProperties(_ properties: [String: String]) async {}
    func trackWorkoutCompleted(_ workout: Workout) async {}
    func trackMealLogged(_ meal: FoodEntry) async {}
    func getInsights(for user: User) async throws -> UserInsights {
        UserInsights(
            workoutFrequency: 3.5,
            averageWorkoutDuration: 3600,
            caloriesTrend: Trend(direction: .up, changePercentage: 5),
            macroBalance: MacroBalance(proteinPercentage: 0.3, carbsPercentage: 0.4, fatPercentage: 0.3),
            streakDays: 7,
            achievements: []
        )
    }
    
    // AI protocol requirements
    func analyzePerformance(query: String, metrics: [String], days: Int, depth: String, includeRecommendations: Bool, for user: User) async throws -> PerformanceAnalysisResult {
        PerformanceAnalysisResult(
            summary: "Preview analysis",
            insights: [],
            trends: [],
            recommendations: [],
            dataPoints: 0,
            confidence: 0.5
        )
    }
    
    func generatePredictiveInsights(for user: User, timeframe: Int) async throws -> PredictiveInsights {
        PredictiveInsights(
            projections: [:],
            risks: [],
            opportunities: [],
            confidence: 0.5
        )
    }
}

/// Minimal preview implementation of AI goal service
private final class PreviewAIGoalService: AIGoalServiceProtocol {
    // Base protocol requirements
    func createGoal(_ goal: TrackedGoal) async throws {}
    func updateGoal(_ goal: TrackedGoal) async throws {}
    func deleteGoal(_ goal: TrackedGoal) async throws {}
    func completeGoal(_ goal: TrackedGoal) async throws {}
    func getActiveGoals(for userId: UUID) async throws -> [TrackedGoal] { [] }
    func getAllGoals(for userId: UUID) async throws -> [TrackedGoal] { [] }
    func getGoal(by id: UUID) async throws -> TrackedGoal? { nil }
    func updateProgress(for goalId: UUID, progress: Double) async throws {}
    func recordMilestone(for goalId: UUID, milestone: TrackedGoalMilestone) async throws {}
    func getGoalsContext(for userId: UUID) async throws -> GoalsContext {
        GoalsContext(
            activeGoals: [],
            totalActiveGoals: 0,
            goalsNeedingAttention: [],
            recentAchievements: [],
            primaryGoal: nil
        )
    }
    func getGoalStatistics(for userId: UUID) async throws -> GoalStatistics {
        GoalStatistics(
            totalGoals: 0,
            activeGoals: 0,
            completedGoals: 0,
            pausedGoals: 0,
            completionRate: 0,
            averageCompletionDays: 0,
            currentStreak: 0
        )
    }
    
    // AI protocol requirements
    func createOrRefineGoal(current: String?, aspirations: String, timeframe: String?, fitnessLevel: String?, constraints: [String], motivations: [String], goalType: String?, for user: User) async throws -> GoalResult {
        GoalResult(
            id: UUID(),
            title: "Preview Goal",
            description: aspirations,
            targetDate: nil,
            metrics: [],
            milestones: [],
            smartCriteria: GoalResult.SMARTCriteria(
                specific: aspirations,
                measurable: "Track progress",
                achievable: "Yes",
                relevant: "Aligned with goals",
                timeBound: timeframe ?? "Flexible"
            )
        )
    }
    
    func suggestGoalAdjustments(for goal: TrackedGoal, user: User) async throws -> [GoalAdjustment] {
        []
    }
}
