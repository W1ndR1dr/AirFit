import Foundation
import SwiftData
import Observation
import UIKit

@MainActor
@Observable
final class CoachEngine {
    // MARK: - State (kept for public API)
    private(set) var isProcessing = false
    internal private(set) var currentResponse = ""
    private(set) var error: Error?
    private(set) var activeConversationId: UUID?
    private(set) var streamingTokens: [String] = []
    internal private(set) var lastFunctionCall: String?

    // MARK: - Dependencies (exposed for compatibility where referenced)
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
    private let streamStore: ChatStreamingStore?

    // MARK: - New
    private let orchestrator: CoachOrchestrator

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
        streamStore: ChatStreamingStore? = nil
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

        self.orchestrator = CoachOrchestrator(
            localCommandParser: localCommandParser,
            personaService: personaService,
            conversationManager: conversationManager,
            aiService: aiService,
            contextAssembler: contextAssembler,
            modelContext: modelContext,
            routingConfiguration: routingConfiguration,
            healthKitManager: healthKitManager,
            nutritionCalculator: nutritionCalculator,
            muscleGroupVolumeService: muscleGroupVolumeService,
            exerciseDatabase: exerciseDatabase,
            streamStore: streamStore
        )
        self.orchestrator.delegate = self
    }

    // MARK: - Public API (unchanged signatures)

    func processUserMessage(_ text: String, for user: User) async {
        await orchestrator.processUserMessage(text, for: user, activeConversationId: &activeConversationId)
    }

    func clearConversation() {
        orchestrator.clearConversation(activeConversationId: &activeConversationId)
    }

    func regenerateLastResponse(for user: User) async {
        await orchestrator.regenerateLastResponse(for: user, activeConversationId: activeConversationId)
    }

    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async -> String {
        await orchestrator.postWorkoutAnalysis(request)
    }

    // Function tool entry for stand-alone calls
    func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
        let t0 = CFAbsoluteTimeGetCurrent()
        let result = await orchestrator.functionCall(functionCall, user: user, conversationId: UUID())
        let ms = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)
        return FunctionExecutionResult(success: true, message: "Function executed successfully", data: ["result": .string(result)], executionTimeMs: ms, functionName: functionCall.name)
    }

    // Direct AI wrappers (kept for compatibility)
    public func parseAndLogNutritionDirect(foodText: String, context: String = "", for user: User, conversationId: UUID? = nil) async throws -> NutritionParseResult {
        try await orchestrator.parseAndLogNutritionDirect(foodText: foodText, context: context, user: user, conversationId: conversationId)
    }

    public func generateEducationalContentDirect(topic: String, userContext: String, for user: User) async throws -> EducationalContent {
        let profile = try await getUserProfile(for: user)
        return try await DirectAIProcessor(aiService: aiService).generateEducationalContent(topic: topic, userContext: userContext, userProfile: profile)
    }

    // MARK: - Dashboard & Notifications passthrough

    enum NotificationContentType {
        case morningGreeting
        case workoutReminder
        case mealReminder(MealType)
        case achievement
    }

    func generateNotificationContent<T>(type: NotificationContentType, context: T) async throws -> String {
        // Map local enum to formatter enum
        let mapped: AIFormatter.NotificationContentType = {
            switch type {
            case .morningGreeting: return .morningGreeting
            case .workoutReminder: return .workoutReminder
            case .mealReminder(let m): return .mealReminder(m)
            case .achievement: return .achievement
            }
        }()
        return try await orchestrator.generateNotificationContent(type: mapped, context: context)
    }

    func generateDashboardContent(for user: User) async throws -> AIDashboardContent {
        try await orchestrator.generateDashboardContent(for: user)
    }

    // MARK: - FoodCoachEngineProtocol passthrough (kept)

    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
        await processUserMessage(message, for: User())
        return ["response": .string(currentResponse)]
    }

    // NOTE: private decode helper kept for generateEducationalContentDirect
    private func getUserProfile(for user: User) async throws -> CoachingPlan {
        guard let onboardingProfile = user.onboardingProfile else { return CoachingPlan.defaultProfile() }
        do { return try JSONDecoder().decode(CoachingPlan.self, from: onboardingProfile.rawFullProfileData) }
        catch {
            AppLogger.warning("Failed to decode user profile, using default", category: .ai)
            return CoachingPlan.defaultProfile()
        }
    }
}

// MARK: - Orchestrator delegate
extension CoachEngine: CoachOrchestratorDelegate {
    func didStartProcessing() { isProcessing = true; error = nil; streamingTokens.removeAll() }
    func didFinishProcessing() { isProcessing = false }
    func updateCurrentResponse(_ text: String) { currentResponse = text }
    func appendStreamingToken(_ token: String) { streamingTokens.append(token) }
    func setError(_ error: Error?) { self.error = error }
    func setActiveConversationId(_ id: UUID?) { self.activeConversationId = id }
    func setLastFunctionCall(_ name: String?) { self.lastFunctionCall = name }
}
