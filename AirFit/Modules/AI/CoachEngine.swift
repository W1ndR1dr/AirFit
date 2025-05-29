import Foundation
import SwiftData
import Observation
import Combine

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
        modelContext: ModelContext
    ) {
        self.localCommandParser = localCommandParser
        self.functionDispatcher = functionDispatcher
        self.personaEngine = personaEngine
        self.conversationManager = conversationManager
        self.aiService = aiService
        self.contextAssembler = contextAssembler
        self.modelContext = modelContext

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

            // Save user message first
            _ = try await conversationManager.saveUserMessage(
                text,
                for: user,
                conversationId: conversationId
            )

            AppLogger.info("Processing user message: \(text.prefix(50))...", category: .ai)

            // Step 1: Check for local commands first (instant response)
            if let localResponse = await checkLocalCommand(text, for: user) {
                await handleLocalCommandResponse(localResponse, for: user, conversationId: conversationId)
                return
            }

            // Step 2: Process through AI pipeline
            await processAIResponse(text, for: user, conversationId: conversationId)

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

            await processAIResponse(lastUserMessage.content, for: user, conversationId: conversationId)

        } catch {
            await handleError(error)
        }
    }

    /// Generates AI-powered post-workout analysis
    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
        do {
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

        } catch {
            AppLogger.error("Failed to generate workout analysis", error: error, category: .ai)
            return "Great workout! Keep up the excellent work."
        }
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
        conversationId: UUID
    ) async {
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            // Step 1: Assemble health context
            let healthContext = await contextAssembler.assembleSnapshot(modelContext: modelContext)

            // Step 2: Get conversation history
            let conversationHistory = try await conversationManager.getRecentMessages(
                for: user,
                conversationId: conversationId,
                limit: 20
            )

            // Step 3: Build persona-aware system prompt
            let userProfile = try await getUserProfile(for: user)
            let adjustedProfile = personaEngine.adjustPersonaForContext(
                baseProfile: userProfile,
                healthContext: healthContext
            )

            let systemPrompt = try personaEngine.buildSystemPrompt(
                userProfile: adjustedProfile,
                healthContext: healthContext,
                conversationHistory: conversationHistory.map { aiMessage in
                    ChatMessage(
                        id: aiMessage.id,
                        role: (MessageRole(rawValue: aiMessage.role.rawValue) ?? .user).rawValue,
                        content: aiMessage.content,
                        session: nil
                    )
                },
                availableFunctions: FunctionRegistry.availableFunctions
            )

            // Step 4: Create AI request
            let aiMessages = conversationHistory.map { aiMessage in
                AIChatMessage(
                    id: aiMessage.id,
                    role: AIMessageRole(rawValue: aiMessage.role.rawValue) ?? .user,
                    content: aiMessage.content,
                    timestamp: aiMessage.timestamp
                )
            }

            // Add current user message
            let currentMessage = AIChatMessage(
                role: .user,
                content: text,
                timestamp: Date()
            )

            let aiRequest = AIRequest(
                systemPrompt: systemPrompt,
                messages: aiMessages + [currentMessage],
                functions: FunctionRegistry.availableFunctions,
                user: user.id.uuidString
            )

            // Step 5: Stream AI response
            await streamAIResponse(aiRequest, for: user, conversationId: conversationId, startTime: startTime)

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

        do {
            AppLogger.info("Executing function: \(functionCall.name)", category: .ai)

            // Execute function
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
            AppLogger.info("Function executed in \(Int(executionTime * 1_000))ms", category: .ai)

            // Create follow-up response about the function execution
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

            // Update current response to include function result
            currentResponse += "\n\n" + followUpResponse

        } catch {
            AppLogger.error("Function execution failed", error: error, category: .ai)

            // Save error response
            let errorResponse = "I encountered an issue while executing that action. Please try again or contact support if the problem persists."

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

    private func getUserProfile(for user: User) async throws -> PersonaProfile {
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

    private func createDefaultProfile() -> PersonaProfile {
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

// MARK: - Shared Instance
extension CoachEngine {
    /// Shared singleton used throughout the app. This uses simple placeholder
    /// services until full implementations are available.
    static let shared: CoachEngine = {
        let container = DependencyContainer.shared
        let context = container.makeModelContext() ?? {
            do {
                return try ModelContainer.createTestContainer().mainContext
            } catch {
                fatalError("Failed to create ModelContext: \(error)")
            }
        }()

        return CoachEngine(
            localCommandParser: LocalCommandParser(),
            functionDispatcher: FunctionCallDispatcher(),
            personaEngine: PersonaEngine(),
            conversationManager: ConversationManager(modelContext: context),
            aiService: PlaceholderAIAPIService(),
            contextAssembler: ContextAssembler(),
            modelContext: context
        )
    }()
}
