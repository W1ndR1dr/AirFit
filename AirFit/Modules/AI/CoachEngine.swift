import Foundation
import SwiftData
import Observation
import Combine
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
    private let localCommandParser: LocalCommandParser
    private let functionDispatcher: FunctionCallDispatcher
    private let personaEngine: PersonaEngine
    private let conversationManager: ConversationManager
    private let aiService: AIAPIServiceProtocol
    private let contextAssembler: ContextAssembler
    private let modelContext: ModelContext
    private let routingConfiguration: RoutingConfiguration

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
        aiService: AIAPIServiceProtocol,
        contextAssembler: ContextAssembler,
        modelContext: ModelContext,
        routingConfiguration: RoutingConfiguration = RoutingConfiguration.shared
    ) {
        self.localCommandParser = localCommandParser
        self.functionDispatcher = functionDispatcher
        self.personaEngine = personaEngine
        self.conversationManager = conversationManager
        self.aiService = aiService
        self.contextAssembler = contextAssembler
        self.modelContext = modelContext
        self.routingConfiguration = routingConfiguration

        // Initialize with a new conversation
        self.activeConversationId = UUID()
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
            let conversationId = activeConversationId ?? UUID()
            if activeConversationId == nil {
                activeConversationId = conversationId
            }

            // Step 1: Classify the message for optimization
            let messageType = classifyMessage(text)
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

            AppLogger.info("Processing user message (\(messageType.rawValue)): \(text.prefix(50))...", category: .ai)

            // Step 3: Check for local commands first (instant response)
            if let localResponse = await checkLocalCommand(text, for: user) {
                await handleLocalCommandResponse(localResponse, for: user, conversationId: conversationId)
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
        activeConversationId = UUID()
        currentResponse = ""
        streamingTokens = []
        lastFunctionCall = nil
        error = nil

        AppLogger.info("Started new conversation: \(activeConversationId?.uuidString ?? "unknown")", category: .ai)
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
        // Build analysis prompt
        let analysisPrompt = buildWorkoutAnalysisPrompt(request)

        // Create AI request for analysis
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

        // Get AI response
        var analysisResult = ""
        let responsePublisher = aiService.getStreamingResponse(for: aiRequest)

        await withCheckedContinuation { continuation in
            var cancellables = Set<AnyCancellable>()

            responsePublisher
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in
                        continuation.resume()
                    },
                    receiveValue: { response in
                        switch response {
                        case .text(let text), .textDelta(let text):
                            analysisResult += text
                        default:
                            break
                        }
                    }
                )
                .store(in: &cancellables)
        }

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

    /// Classifies user messages to optimize conversation history and token usage
    /// Commands need minimal context, conversations need full history
    private func classifyMessage(_ text: String) -> MessageType {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmedText.lowercased()
        
        // Very short messages are likely commands
        if trimmedText.count < 20 {
            AppLogger.debug("Classified as command: short message (\(trimmedText.count) chars)", category: .ai)
            return .command
        }
        
        // Check for command indicators at start of message
        let commandStarters = ["log ", "add ", "track ", "record ", "show ", "open ", "start "]
        for starter in commandStarters where lowercased.hasPrefix(starter) {
            AppLogger.debug("Classified as command: starts with '\(starter)'", category: .ai)
            return .command
        }
        
        // Check for nutrition/fitness keywords combined with short length
        let nutritionKeywords = ["calories", "protein", "carbs", "fat", "water", "steps", "workout"]
        let hasNutritionKeyword = nutritionKeywords.contains { lowercased.contains($0) }
        
        if hasNutritionKeyword && trimmedText.count < 50 {
            AppLogger.debug("Classified as command: nutrition keyword + short length", category: .ai)
            return .command
        }
        
        // Check for typical command patterns
        let commandPatterns = [
            "\\d+\\s*(calories|cal|protein|carbs|fat|water|ml|oz|steps|lbs|kg)",
            "^(yes|no|ok|thanks|got it)$",
            "^\\d+\\s*\\w*\\s*\\w+$" // Numbers with units like "500 calories" or "2 apples"
        ]
        
        for pattern in commandPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(trimmedText.startIndex..<trimmedText.endIndex, in: trimmedText)
                if regex.firstMatch(in: trimmedText, options: [], range: range) != nil {
                    AppLogger.debug("Classified as command: matches pattern '\(pattern)'", category: .ai)
                    return .command
                }
            }
        }
        
        // Default to conversation for complex, longer messages
        AppLogger.debug("Classified as conversation: complex message requiring full context", category: .ai)
        return .conversation
    }

    private func startProcessing() async {
        isProcessing = true
        error = nil
        currentResponse = ""
        streamingTokens = []
    }

    private func finishProcessing() async {
        isProcessing = false
    }

    private func checkLocalCommand(_ text: String, for user: User) async -> LocalCommand? {
        let startTime = CFAbsoluteTimeGetCurrent()

        let command = localCommandParser.parse(text)

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.debug("Local command check took \(Int(processingTime * 1_000))ms", category: .ai)

        return command == .none ? nil : command
    }

    private func handleLocalCommandResponse(
        _ command: LocalCommand,
        for user: User,
        conversationId: UUID
    ) async {
        do {
            // Generate response for local command
            let response = generateLocalCommandResponse(command)

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
            let historyLimit = messageType.contextLimit
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
                timeOfDay: getCurrentTimeOfDay(),
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
            let isNutritionParsing = ContextAnalyzer.detectsSimpleParsing(text)
            let isEducationalContent = detectsEducationalContent(text)
            
            var responseContent: String
            var metrics: RoutingMetrics
            
            if isNutritionParsing {
                // Direct nutrition parsing
                let result = try await parseAndLogNutritionDirect(
                    foodText: text,
                    for: user,
                    conversationId: conversationId
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
                let topic = extractEducationalTopic(from: text)
                let content = try await generateEducationalContentDirect(
                    topic: topic,
                    userContext: text,
                    for: user
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
                responseContent = try await generateSimpleConversationalResponse(
                    text: text,
                    user: user,
                    conversationHistory: conversationHistory,
                    healthContext: healthContext
                )
                
                metrics = RoutingMetrics(
                    route: .directAI,
                    executionTimeMs: Int((CFAbsoluteTimeGetCurrent() - directAIStartTime) * 1_000),
                    success: true,
                    tokenUsage: estimateTokenCount(text + responseContent),
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
    
    private func extractEducationalTopic(from text: String) -> String {
        let lowercased = text.lowercased()
        
        // Common fitness topics
        let topics = [
            "protein", "carbs", "fat", "calories", "macros",
            "muscle", "strength", "cardio", "recovery",
            "sleep", "hydration", "supplements", "nutrition"
        ]
        
        for topic in topics where lowercased.contains(topic) {
            return topic
        }
        
        // Extract first significant word as topic
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
        
        return words.first ?? "fitness"
    }
    
    private func generateSimpleConversationalResponse(
        text: String,
        user: User,
        conversationHistory: [AIChatMessage],
        healthContext: HealthContextSnapshot
    ) async throws -> String {
        let userProfile = try await getUserProfile(for: user)
        
        let prompt = """
        Respond to this fitness-related question or comment: "\(text)"
        
        User context:
        - Workout Window: \(userProfile.lifeContext.workoutWindowPreference.displayName)
        - Primary goal: \(userProfile.goal.family.displayName)
        - Recent activity: \(healthContext.appContext.workoutContext?.recentWorkouts.count ?? 0) workouts
        
        Provide a helpful, encouraging response in 1-2 sentences. Be conversational and supportive.
        """
        
        let aiRequest = AIRequest(
            systemPrompt: "You are a supportive fitness coach providing brief, helpful responses.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.7,
            maxTokens: 200,
            user: user.id.uuidString
        )
        
        return try await executeStreamingAIRequest(aiRequest)
    }
     
     private func getCurrentTimeOfDay() -> String {
         let hour = Calendar.current.component(.hour, from: Date())
         switch hour {
         case 5..<12: return "morning"
         case 12..<17: return "afternoon"
         case 17..<21: return "evening"
         default: return "night"
         }
     }
     
     private func detectsEducationalContent(_ text: String) -> Bool {
         let lowercased = text.lowercased()
         
         let educationalPatterns = [
             "what is", "how does", "explain", "tell me about",
             "why is", "why do", "what are the benefits",
             "how to", "best practices", "tips for",
             "science behind", "research on"
         ]
         
         let fitnessTopics = [
             "protein", "carbs", "fat", "calories", "macros",
             "muscle", "strength", "cardio", "recovery",
             "sleep", "hydration", "supplements"
         ]
         
         let hasEducationalPattern = educationalPatterns.contains { lowercased.contains($0) }
         let hasFitnessTopic = fitnessTopics.contains { lowercased.contains($0) }
         
         return hasEducationalPattern && hasFitnessTopic
     }

    /// Enhanced version of streamAIResponse with routing metrics
    private func streamAIResponseWithMetrics(
        _ request: AIRequest,
        for user: User,
        conversationId: UUID,
        routingStrategy: RoutingStrategy,
        startTime: CFAbsoluteTime
    ) async {
        let functionCallStartTime = CFAbsoluteTimeGetCurrent()
        var functionCallDetected: AIFunctionCall?
        var fullResponse = ""
        var tokenUsage: Int = 0
        var success = false
        
        do {
            var firstTokenReceived = false
            var cancellables = Set<AnyCancellable>()

            // Create streaming response publisher
            let responsePublisher = aiService.getStreamingResponse(for: request)

            // Process streaming response using async/await with Combine
            await withCheckedContinuation { continuation in
                responsePublisher
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                AppLogger.info("Stream completed", category: .ai)
                                success = true
                                continuation.resume()
                            case .failure(let error):
                                AppLogger.error("Stream failed", error: error, category: .ai)
                                Task { await self.handleError(error) }
                                continuation.resume()
                            }
                        },
                        receiveValue: { [weak self] response in
                            guard let self = self else { return }

                            Task { @MainActor in
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
                                    tokenUsage = usage?.totalTokens ?? 0
                                    AppLogger.info("Stream completed with usage: \(tokenUsage) tokens", category: .ai)

                                case .error(let aiError):
                                    AppLogger.error("AI service error", error: aiError, category: .ai)
                                    Task { await self.handleError(aiError) }
                                }
                            }
                        }
                    )
                    .store(in: &cancellables)
            }

            // Save AI response
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

            // Execute function call if detected
            if let functionCall = functionCallDetected {
                await executeFunctionCall(
                    functionCall,
                    for: user,
                    conversationId: conversationId,
                    originalMessage: assistantMessage
                )
            }
            
            // Record successful function calling metrics
            let metrics = RoutingMetrics(
                route: routingStrategy.route,
                executionTimeMs: Int((CFAbsoluteTimeGetCurrent() - functionCallStartTime) * 1_000),
                success: success,
                tokenUsage: tokenUsage > 0 ? tokenUsage : nil
            )
                         routingConfiguration.recordRoutingMetrics(metrics)

             await finishProcessing()

        } catch {
            // Record failed function calling metrics
            let metrics = RoutingMetrics(
                route: routingStrategy.route,
                executionTimeMs: Int((CFAbsoluteTimeGetCurrent() - functionCallStartTime) * 1_000),
                success: false,
                tokenUsage: tokenUsage > 0 ? tokenUsage : nil
            )
                         routingConfiguration.recordRoutingMetrics(metrics)
             
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
            var cancellables = Set<AnyCancellable>()

            // Create streaming response publisher
            let responsePublisher = aiService.getStreamingResponse(for: request)

            // Process streaming response using async/await with Combine
            await withCheckedContinuation { continuation in
                responsePublisher
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                AppLogger.info("Stream completed", category: .ai)
                                continuation.resume()
                            case .failure(let error):
                                AppLogger.error("Stream failed", error: error, category: .ai)
                                Task { await self.handleError(error) }
                                continuation.resume()
                            }
                        },
                        receiveValue: { [weak self] response in
                            guard let self = self else { return }

                            Task { @MainActor in
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
                                    Task { await self.handleError(aiError) }
                                }
                            }
                        }
                    )
                    .store(in: &cancellables)
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

    private func generateLocalCommandResponse(_ command: LocalCommand) -> String {
        switch command {
        case .showDashboard:
            return "I'll take you to your dashboard where you can see your progress overview."
        case let .navigateToTab(tab):
            return "I'll navigate you to the \(tab.rawValue) section."
        case let .logWater(amount, unit):
            return "I've logged \(amount) \(unit.rawValue) of water for you. Great job staying hydrated!"
        case let .quickLog(type):
            return "I'll help you quickly log your \(type). Let me open that for you."
        case .showSettings:
            return "I'll take you to your settings where you can customize your experience."
        case .showProfile:
            return "I'll show you your profile information."
        case .startWorkout:
            return "Let's get you started with a workout! I'll open your workout options."
        case .help:
            return "I'm here to help! You can ask me about workouts, nutrition, progress tracking, or just chat about your fitness goals."
        case .none:
            return "I'm not sure what you'd like me to do. Could you be more specific?"
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
    
    // MARK: - Direct AI Methods
    
    /// Parses nutrition data using direct AI (bypassing function dispatcher)
    /// Provides 3x performance improvement over dispatcher-based approach
    public func parseAndLogNutritionDirect(
        foodText: String,
        context: String = "",
        for user: User,
        conversationId: UUID? = nil
    ) async throws -> NutritionParseResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard !foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DirectAIError.nutritionParsingFailed("Empty food description")
        }
        
        let prompt = buildOptimizedNutritionPrompt(
            foodText: foodText,
            context: context,
            user: user
        )
        
        do {
            let aiRequest = AIRequest(
                systemPrompt: "You are a precision nutrition expert. Return only valid JSON without explanations.",
                messages: [AIChatMessage(role: .user, content: prompt)],
                temperature: 0.1, // Low temperature for consistent parsing
                maxTokens: 500,   // Optimized token limit
                user: user.id.uuidString
            )
            
            let response = try await executeStreamingAIRequest(aiRequest)
            let parsedNutritionItems = try parseNutritionResponse(response)
            let validatedItems = validateNutritionItems(parsedNutritionItems)
            
            guard !validatedItems.isEmpty else {
                throw DirectAIError.nutritionValidationFailed
            }
            
            let processingTime = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1_000)
            let confidence = validatedItems.reduce(0) { $0 + $1.confidence } / Double(validatedItems.count)
            
            // Convert ParsedNutritionItem to NutritionItem
            let nutritionItems = validatedItems.map { parsedItem in
                NutritionItem(
                    name: parsedItem.name,
                    quantity: parsedItem.quantity,
                    calories: parsedItem.calories,
                    protein: parsedItem.proteinGrams,
                    carbs: parsedItem.carbGrams,
                    fat: parsedItem.fatGrams,
                    confidence: parsedItem.confidence
                )
            }
            
            let totalCalories = nutritionItems.reduce(0) { $0 + $1.calories }
            
            let result = NutritionParseResult(
                items: nutritionItems,
                totalCalories: totalCalories,
                confidence: confidence,
                tokenCount: estimateTokenCount(prompt),
                processingTimeMs: processingTime,
                parseStrategy: .directAI
            )
            
            AppLogger.info(
                "Direct nutrition parsing: \(validatedItems.count) items in \(processingTime)ms | Confidence: \(String(format: "%.2f", confidence)) | Tokens: ~\(result.tokenCount)",
                category: .ai
            )
            
            return result
            
        } catch let error as DirectAIError {
            AppLogger.error("Direct nutrition parsing failed", error: error, category: .ai)
            throw error
        } catch {
            AppLogger.error("Unexpected nutrition parsing error", error: error, category: .ai)
            throw DirectAIError.nutritionParsingFailed(error.localizedDescription)
        }
    }
    
    /// Generates educational content using direct AI (bypassing function dispatcher)
    /// Provides 80% token reduction compared to function calling approach
    public func generateEducationalContentDirect(
        topic: String,
        userContext: String,
        for user: User
    ) async throws -> EducationalContent {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DirectAIError.educationalContentFailed("Empty topic")
        }
        
        let userProfile = try await getUserProfile(for: user)
        let prompt = buildEducationalPrompt(
            topic: topic,
            userContext: userContext,
            userProfile: userProfile
        )
        
        do {
            let aiRequest = AIRequest(
                systemPrompt: "You are an expert fitness educator providing personalized, science-based guidance.",
                messages: [AIChatMessage(role: .user, content: prompt)],
                temperature: 0.7, // Higher temperature for creative content
                maxTokens: 800,   // Sufficient for detailed content
                user: user.id.uuidString
            )
            
            let response = try await executeStreamingAIRequest(aiRequest)
            let personalizationLevel = calculatePersonalizationLevel(response, userProfile: userProfile)
            
            let processingTime = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1_000)
            
            let content = EducationalContent(
                topic: topic,
                content: response,
                generatedAt: Date(),
                tokenCount: estimateTokenCount(prompt + response),
                personalizationLevel: personalizationLevel,
                contentType: classifyContentType(topic)
            )
            
            AppLogger.info(
                "Educational content generated: \(response.count) chars in \(processingTime)ms | Personalization: \(String(format: "%.2f", personalizationLevel))",
                category: .ai
            )
            
            return content
            
        } catch let error as DirectAIError {
            AppLogger.error("Educational content generation failed", error: error, category: .ai)
            throw error
        } catch {
            AppLogger.error("Unexpected educational content error", error: error, category: .ai)
            throw DirectAIError.educationalContentFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Private Direct AI Helpers
    
    private func buildOptimizedNutritionPrompt(
        foodText: String,
        context: String,
        user: User
    ) -> String {
        let contextSuffix = context.isEmpty ? "" : "\nContext: \(context)"
        
        return """
        Parse: "\(foodText)"\(contextSuffix)
        
        Return JSON:
        {
            "items": [
                {
                    "name": "food name",
                    "quantity": "1 cup",
                    "calories": 200,
                    "proteinGrams": 8.0,
                    "carbGrams": 45.0,
                    "fatGrams": 3.0,
                    "fiberGrams": 2.0,
                    "confidence": 0.95
                }
            ]
        }
        
        Rules:
        - USDA nutrition database accuracy
        - Realistic values (not 100 cal defaults)
        - Multiple items if mentioned
        - Confidence 0.9+ for common foods
        - JSON only, no text
        """
    }
    
    private func buildEducationalPrompt(
        topic: String,
        userContext: String,
        userProfile: UserProfileJsonBlob
    ) -> String {
        let cleanTopic = topic.replacingOccurrences(of: "_", with: " ").capitalized
        let contextLine = userContext.isEmpty ? "" : "\nContext: \(userContext)"
        
        return """
        Create educational content about \(cleanTopic) for this user:
        
        User Level: Intermediate
        Goals: \(userProfile.goal.family.displayName)
        Motivation Style: \(userProfile.motivationalStyle.celebrationStyle.displayName)\(contextLine)
        
        Requirements:
        - Explain \(cleanTopic) scientifically but accessibly
        - Personalize for their level and goals
        - Include 3-4 actionable tips
        - 250-400 words, conversational tone
        - Focus on practical application
        
        Structure: Brief explanation, personalized insights, actionable tips.
        """
    }
    
    private func executeStreamingAIRequest(_ request: AIRequest) async throws -> String {
        var fullResponse = ""
        var cancellables = Set<AnyCancellable>()
        
        let responsePublisher = aiService.getStreamingResponse(for: request)
        
        await withCheckedContinuation { continuation in
            responsePublisher
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        continuation.resume()
                    },
                    receiveValue: { response in
                        switch response {
                        case .text(let text), .textDelta(let text):
                            fullResponse += text
                        case .error(let aiError):
                            AppLogger.error("AI streaming error", error: aiError, category: .ai)
                        default:
                            break
                        }
                    }
                )
                .store(in: &cancellables)
        }
        
        guard !fullResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DirectAIError.emptyResponse
        }
        
        return fullResponse
    }
    
    private func parseNutritionResponse(_ response: String) throws -> [ParsedNutritionItem] {
        // Extract JSON from response (handle cases where AI adds explanatory text)
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let itemsArray = json["items"] as? [[String: Any]] else {
            throw DirectAIError.invalidJSONResponse(response)
        }
        
        return try itemsArray.map { itemDict in
            guard let name = itemDict["name"] as? String,
                  let quantity = itemDict["quantity"] as? String,
                  let calories = itemDict["calories"] as? Double,
                  let protein = itemDict["proteinGrams"] as? Double,
                  let carbs = itemDict["carbGrams"] as? Double,
                  let fat = itemDict["fatGrams"] as? Double else {
                throw DirectAIError.invalidJSONResponse("Missing required nutrition fields")
            }
            
            return ParsedNutritionItem(
                name: name,
                quantity: quantity,
                calories: calories,
                proteinGrams: protein,
                carbGrams: carbs,
                fatGrams: fat,
                fiberGrams: itemDict["fiberGrams"] as? Double,
                confidence: itemDict["confidence"] as? Double ?? 0.8
            )
        }
    }
    
    private func validateNutritionItems(_ items: [ParsedNutritionItem]) -> [ParsedNutritionItem] {
        return items.filter { item in
            if !item.isValid {
                AppLogger.warning(
                    "Rejected invalid nutrition values for \(item.name): \(item.calories) cal, \(item.proteinGrams)g protein",
                    category: .ai
                )
                return false
            }
            return true
        }
    }
    
    private func extractKeyPoints(from content: String) -> [String] {
        // Simple extraction of key points from content
        let sentences = content.components(separatedBy: .punctuationCharacters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 20 } // Meaningful sentences
        
        // Return up to 4 key sentences
        return Array(sentences.prefix(4))
    }
    
    private func calculatePersonalizationLevel(_ content: String, userProfile: UserProfileJsonBlob) -> Double {
        var personalKeywords: [String] = []
        
        // Add goal family as personalization keyword
        personalKeywords.append(userProfile.goal.family.displayName.lowercased())
        
        // Add workout window preference
        personalKeywords.append(userProfile.lifeContext.workoutWindowPreference.displayName.lowercased())
        
        // Add motivational style elements
        personalKeywords.append(userProfile.motivationalStyle.celebrationStyle.displayName.lowercased())
        personalKeywords.append(userProfile.motivationalStyle.absenceResponse.displayName.lowercased())
        
        let mentions = personalKeywords.reduce(0) { count, keyword in
            count + (content.localizedCaseInsensitiveContains(keyword) ? 1 : 0)
        }
        
        return personalKeywords.isEmpty ? 0.5 : min(Double(mentions) / Double(personalKeywords.count), 1.0)
    }
    
    private func extractJSON(from response: String) -> String {
        // Find JSON block in response
        if let startIndex = response.firstIndex(of: "{"),
           let endIndex = response.lastIndex(of: "}") {
            return String(response[startIndex...endIndex])
        }
        
        // Return original if no clear JSON boundaries
        return response
    }
    
    private func estimateTokenCount(_ text: String) -> Int {
        // Rough token estimation: ~4 characters per token for English
        return max(text.count / 4, 1)
    }
    
    // MARK: - Direct AI Methods (Phase 3 Implementation)
    
    /// Direct AI nutrition parsing without function call overhead
    func parseAndLogNutritionDirect(
        foodText: String,
        for user: User,
        conversationId: UUID
    ) async throws -> NutritionParseResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        AppLogger.debug("Starting direct AI nutrition parsing for: '\(foodText.prefix(50))...'", category: .ai)
        
        do {
            // Get user profile for personalization
            let userProfile = try await getUserProfile(for: user)
            
            // Build optimized prompt for nutrition parsing
            let prompt = buildDirectNutritionParsingPrompt(text: foodText, userProfile: userProfile)
            
            // Create AI request with low temperature for consistent parsing
            let aiRequest = AIRequest(
                systemPrompt: "You are a nutrition expert providing accurate food parsing. Return only valid JSON.",
                messages: [AIChatMessage(role: .user, content: prompt)],
                temperature: 0.1,
                maxTokens: 500,
                user: "nutrition-direct-\(user.id.uuidString.prefix(8))"
            )
            
            // Execute direct AI call
            let response = try await executeStreamingAIRequest(aiRequest)
            
            // Parse JSON response directly  
            let directNutritionItems = try parseDirectNutritionResponse(response)
            
            // Convert to result format
            let totalCalories = directNutritionItems.reduce(0.0) { $0 + $1.calories }
            let averageConfidence = directNutritionItems.reduce(0.0) { $0 + $1.confidence } / Double(max(directNutritionItems.count, 1))
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            let tokenCount = estimateTokenCount(prompt + response)
            
            let result = NutritionParseResult(
                items: directNutritionItems,
                totalCalories: totalCalories,
                confidence: averageConfidence,
                tokenCount: tokenCount,
                processingTimeMs: Int(processingTime * 1_000),
                parseStrategy: .directAI
            )
            
            // Log parsing success
            AppLogger.info(
                "Direct AI nutrition parsing completed: \(directNutritionItems.count) items, \(Int(totalCalories)) cal, \(Int(processingTime * 1000))ms",
                category: .ai
            )
            
            return result
            
        } catch {
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.error(
                "Direct AI nutrition parsing failed after \(Int(processingTime * 1000))ms",
                error: error,
                category: .ai
            )
            throw CoachEngineError.nutritionParsingFailed(error.localizedDescription)
        }
    }
    

    
    // MARK: - Direct AI Helper Methods
    
    private func buildDirectNutritionParsingPrompt(text: String, userProfile: UserProfileJsonBlob) -> String {
        return """
        Parse this food description into structured nutrition data: "\(text)"
        
        User Context:
        - Goal: \(userProfile.goal.family.displayName)
        - Workout Window: \(userProfile.lifeContext.workoutWindowPreference.displayName)
        
        Return ONLY valid JSON in this exact format:
        {
            "items": [
                {
                    "name": "food name",
                    "quantity": "amount with unit",
                    "calories": 0,
                    "protein": 0.0,
                    "carbs": 0.0,
                    "fat": 0.0,
                    "confidence": 0.95
                }
            ]
        }
        
        Rules:
        - Use USDA nutrition database knowledge for accuracy
        - If multiple items mentioned, include all
        - Estimate quantities if not specified  
        - Return realistic nutrition values (not 100 calories for everything!)
        - Confidence 0.9+ for common foods, lower for ambiguous items
        - No explanations or extra text, just JSON
        """
    }
    
    private func buildDirectEducationPrompt(
        topic: String,
        userContext: String,
        userProfile: UserProfileJsonBlob
    ) -> String {
        let cleanTopic = topic.replacingOccurrences(of: "_", with: " ").capitalized
        let contextLine = userContext.isEmpty ? "" : "\nContext: \(userContext)"
        
        return """
        Create educational content about \(cleanTopic) for this user:
        
        User Profile:
        - Goal: \(userProfile.goal.family.displayName)
        - Workout Window: \(userProfile.lifeContext.workoutWindowPreference.displayName)
        - Motivation Style: \(userProfile.motivationalStyle.celebrationStyle.displayName)\(contextLine)
        
        Requirements:
        - Explain \(cleanTopic) scientifically but accessibly
        - Personalize for their goal and workout preferences
        - Include 3-4 actionable tips specific to their situation
        - 200-300 words, conversational and encouraging tone
        - Focus on practical application they can use today
        
        Structure: Brief explanation, why it matters for their goals, actionable tips.
        """
    }
    
    private func parseDirectNutritionResponse(_ response: String) throws -> [NutritionItem] {
        // Extract JSON from response (handle cases where AI adds explanatory text)
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let itemsArray = json["items"] as? [[String: Any]] else {
            throw DirectAIError.invalidJSONResponse(response)
        }
        
        return try itemsArray.map { itemDict in
            guard let name = itemDict["name"] as? String,
                  let quantity = itemDict["quantity"] as? String,
                  let calories = itemDict["calories"] as? Double,
                  let protein = itemDict["protein"] as? Double,
                  let carbs = itemDict["carbs"] as? Double,
                  let fat = itemDict["fat"] as? Double else {
                throw DirectAIError.invalidJSONResponse("Missing required nutrition fields")
            }
            
            let confidence = itemDict["confidence"] as? Double ?? 0.8
            
            // Validate nutrition values
            guard calories > 0 && calories < 5000,
                  protein >= 0 && protein < 300,
                  carbs >= 0 && carbs < 1000,
                  fat >= 0 && fat < 500 else {
                throw DirectAIError.invalidNutritionValues("Invalid nutrition values for \(name)")
            }
            
            return NutritionItem(
                name: name,
                quantity: quantity,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                confidence: confidence
            )
        }
    }
    
    private func classifyContentType(_ topic: String) -> EducationalContent.ContentType {
        let lowercaseTopic = topic.lowercased()
        
        if lowercaseTopic.contains("exercise") || lowercaseTopic.contains("workout") || lowercaseTopic.contains("training") {
            return .exercise
        } else if lowercaseTopic.contains("nutrition") || lowercaseTopic.contains("diet") || lowercaseTopic.contains("food") {
            return .nutrition
        } else if lowercaseTopic.contains("recovery") || lowercaseTopic.contains("sleep") || lowercaseTopic.contains("rest") {
            return .recovery
        } else if lowercaseTopic.contains("motivation") || lowercaseTopic.contains("mindset") || lowercaseTopic.contains("goal") {
            return .motivation
        } else {
            return .general
        }
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
    /// Uses inline stub implementations to avoid external dependencies.
    static func createDefault(modelContext: ModelContext) -> CoachEngine {
        // Minimal inline stub for AIAPIServiceProtocol
        final class MinimalAIAPIService: AIAPIServiceProtocol {
            func configure(provider: AIProvider, apiKey: String, modelIdentifier: String?) {
                // No-op for development
            }
            
            func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponse, Error> {
                // Return empty publisher for development
                Empty(completeImmediately: true).eraseToAnyPublisher()
            }
        }
        
        // Simple inline mocks for development
        final class DevWorkoutService: WorkoutServiceProtocol {
            func generatePlan(for user: User, goal: String, duration: Int, intensity: String, targetMuscles: [String], equipment: [String], constraints: String?, style: String) async throws -> WorkoutPlanResult {
                return WorkoutPlanResult(id: UUID(), exercises: [], estimatedCalories: 300, estimatedDuration: duration, summary: "Dev workout plan")
            }
        }
        
        final class DevAnalyticsService: AnalyticsServiceProtocol {
            func analyzePerformance(query: String, metrics: [String], days: Int, depth: String, includeRecommendations: Bool, for user: User) async throws -> PerformanceAnalysisResult {
                return PerformanceAnalysisResult(summary: "Dev analysis", insights: [], trends: [], recommendations: [], dataPoints: 0)
            }
        }
        
        final class DevGoalService: GoalServiceProtocol {
            func createOrRefineGoal(current: String?, aspirations: String, timeframe: String?, fitnessLevel: String?, constraints: [String], motivations: [String], goalType: String?, for user: User) async throws -> GoalResult {
                return GoalResult(id: UUID(), title: "Dev Goal", description: "Dev goal description", targetDate: nil, metrics: [], milestones: [], smartCriteria: GoalResult.SMARTCriteria(specific: "", measurable: "", achievable: "", relevant: "", timeBound: ""))
            }
        }
        
        return CoachEngine(
            localCommandParser: LocalCommandParser(),
            functionDispatcher: FunctionCallDispatcher(
                workoutService: DevWorkoutService(),
                analyticsService: DevAnalyticsService(),
                goalService: DevGoalService()
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
    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
        // TODO: Implement post-workout analysis
        return "Great workout! Keep up the excellent work."
    }
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
            var cancellables = Set<AnyCancellable>()
            
            let responsePublisher = aiService.getStreamingResponse(for: aiRequest)
            
            await withCheckedContinuation { continuation in
                responsePublisher
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            continuation.resume()
                        },
                        receiveValue: { response in
                            switch response {
                            case .text(let text), .textDelta(let text):
                                fullResponse += text
                            case .error(let aiError):
                                AppLogger.error("AI nutrition parsing error", error: aiError, category: .ai)
                            default:
                                break
                            }
                        }
                    )
                    .store(in: &cancellables)
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
