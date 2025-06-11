import Foundation
import SwiftData
import SwiftUI

/// Factory for creating ViewModels with proper dependency injection
@MainActor
public final class DIViewModelFactory {
    private let container: DIContainer
    
    public init(container: DIContainer) {
        self.container = container
    }
    
    private func getModelContext() async throws -> ModelContext {
        // Since we're @MainActor, we can safely get the ModelContainer
        let modelContainer = try await container.resolve(ModelContainer.self)
        // mainContext is accessed on MainActor
        return modelContainer.mainContext
    }
    
    // MARK: - Dashboard
    
    func makeDashboardViewModel(user: User) async throws -> DashboardViewModel {
        let modelContext = try await getModelContext()
        let healthKitService = try await container.resolve(HealthKitServiceProtocol.self)
        let nutritionService = try await container.resolve(DashboardNutritionServiceProtocol.self)
        
        // Create user-specific CoachEngine and AICoachService
        let coachEngine = try await makeCoachEngine(for: user)
        let aiCoachService = AICoachService(coachEngine: coachEngine)
        
        return DashboardViewModel(
            user: user,
            modelContext: modelContext,
            healthKitService: healthKitService,
            aiCoachService: aiCoachService,
            nutritionService: nutritionService
        )
    }
    
    // MARK: - Settings
    
    func makeSettingsViewModel(user: User) async throws -> SettingsViewModel {
        let modelContext = try await getModelContext()
        let apiKeyManager = try await container.resolve(APIKeyManagementProtocol.self)
        let aiService = try await container.resolve(AIServiceProtocol.self)
        let notificationManager = try await container.resolve(NotificationManager.self)
        let coordinator = SettingsCoordinator()
        
        return SettingsViewModel(
            modelContext: modelContext,
            user: user,
            apiKeyManager: apiKeyManager,
            aiService: aiService,
            notificationManager: notificationManager,
            coordinator: coordinator
        )
    }
    
    // MARK: - Workouts
    
    func makeWorkoutViewModel(user: User) async throws -> WorkoutViewModel {
        let modelContext = try await getModelContext()
        let healthKitManager = try await container.resolve(HealthKitManager.self)
        let exerciseDatabase = try await container.resolve(ExerciseDatabase.self)
        let workoutSyncService = try await container.resolve(WorkoutSyncService.self)
        
        // Create user-specific CoachEngine
        let coachEngine = try await makeCoachEngine(for: user)
        
        return WorkoutViewModel(
            modelContext: modelContext,
            user: user,
            coachEngine: coachEngine,
            healthKitManager: healthKitManager,
            exerciseDatabase: exerciseDatabase,
            workoutSyncService: workoutSyncService
        )
    }
    
    // MARK: - Chat
    
    func makeChatViewModel(user: User) async throws -> ChatViewModel {
        let modelContext = try await getModelContext()
        let aiService = try await container.resolve(AIServiceProtocol.self, name: "adaptive")
        let voiceManager = try await container.resolve(VoiceInputManager.self)
        
        // Create user-specific CoachEngine
        let coachEngine = try await makeCoachEngine(for: user)
        
        return ChatViewModel(
            modelContext: modelContext,
            user: user,
            coachEngine: coachEngine,
            aiService: aiService,
            coordinator: ChatCoordinator(),
            voiceManager: voiceManager
        )
    }
    
    // MARK: - Food Tracking
    
    func makeFoodTrackingViewModel(user: User) async throws -> FoodTrackingViewModel {
        let modelContext = try await getModelContext()
        let voiceInputManager = try await container.resolve(VoiceInputManager.self)
        let nutritionService = try await container.resolve(NutritionServiceProtocol.self)
        let coordinator = FoodTrackingCoordinator()
        
        // Create food voice adapter
        let foodVoiceAdapter = FoodVoiceAdapter(voiceInputManager: voiceInputManager)
        
        // Create coach engine
        let coachEngine = try await makeCoachEngine(for: user)
        
        return FoodTrackingViewModel(
            modelContext: modelContext,
            user: user,
            foodVoiceAdapter: foodVoiceAdapter,
            nutritionService: nutritionService,
            coachEngine: coachEngine,
            coordinator: coordinator
        )
    }
    
    
    // MARK: - Onboarding
    
    func makeOnboardingViewModel(modelContext: ModelContext? = nil) async throws -> OnboardingViewModel {
        AppLogger.info("DIViewModelFactory: Creating OnboardingViewModel", category: .app)
        AppLogger.info("DIViewModelFactory: Container ID: \(ObjectIdentifier(container))", category: .app)
        
        // Use provided context or get from container
        let context: ModelContext
        if let modelContext = modelContext {
            context = modelContext
        } else {
            context = try await getModelContext()
        }
        
        let userService = try await container.resolve(UserServiceProtocol.self)
        let apiKeyManager = try await container.resolve(APIKeyManagementProtocol.self)
        let aiService = try await container.resolve(AIServiceProtocol.self)
        
        // Create onboarding service
        let onboardingService = OnboardingService(modelContext: context)
        
        // Get HealthKit auth manager from container
        let healthKitAuthManager = try await container.resolve(HealthKitAuthManager.self)
        
        return OnboardingViewModel(
            aiService: aiService,
            onboardingService: onboardingService,
            modelContext: context,
            apiKeyManager: apiKeyManager,
            userService: userService,
            healthKitAuthManager: healthKitAuthManager
        )
    }
    
    func makeOnboardingFlowCoordinator() async throws -> OnboardingFlowCoordinator {
        let modelContext = try await getModelContext()
        let userService = try await container.resolve(UserServiceProtocol.self)
        let apiKeyManager = try await container.resolve(APIKeyManagementProtocol.self)
        let llmOrchestrator = try await container.resolve(LLMOrchestrator.self)
        
        let cache = AIResponseCache()
        
        // Create optimized persona synthesizer
        let personaSynthesizer = OptimizedPersonaSynthesizer(
            llmOrchestrator: llmOrchestrator,
            cache: cache
        )
        
        // Create persona service
        let personaService = PersonaService(
            personaSynthesizer: personaSynthesizer,
            llmOrchestrator: llmOrchestrator,
            modelContext: modelContext,
            cache: cache
        )
        
        // Create conversation flow definition
        let flowDefinition = ConversationFlowData.defaultFlow()
        
        // Create conversation manager
        let conversationManager = ConversationFlowManager(
            flowDefinition: flowDefinition,
            modelContext: modelContext
        )
        
        return OnboardingFlowCoordinator(
            conversationManager: conversationManager,
            personaService: personaService,
            userService: userService,
            modelContext: modelContext
        )
    }
    
    // Removed duplicate - use makeFoodTrackingViewModel(user:) instead
    
    // MARK: - Private Helpers
    
    private func makeCoachEngine(for user: User) async throws -> CoachEngine {
        let modelContext = try await getModelContext()
        let aiService = try await container.resolve(AIServiceProtocol.self)
        
        // Create required components
        let localCommandParser = LocalCommandParser()
        let personaService = try await container.resolve(PersonaService.self)
        let conversationManager = ConversationManager(modelContext: modelContext)
        let contextAssembler = try await container.resolve(ContextAssembler.self)
        
        // Create AI services for FunctionCallDispatcher
        let goalService = try await container.resolve(AIGoalServiceProtocol.self)
        let workoutService = try await container.resolve(AIWorkoutServiceProtocol.self)
        let analyticsService = try await container.resolve(AIAnalyticsServiceProtocol.self)
        
        let functionDispatcher = FunctionCallDispatcher(
            workoutService: workoutService,
            analyticsService: analyticsService,
            goalService: goalService
        )
        
        // Get routing configuration
        let routingConfiguration = try await container.resolve(RoutingConfiguration.self)
        
        return CoachEngine(
            localCommandParser: localCommandParser,
            functionDispatcher: functionDispatcher,
            personaService: personaService,
            conversationManager: conversationManager,
            aiService: aiService,
            contextAssembler: contextAssembler,
            modelContext: modelContext,
            routingConfiguration: routingConfiguration
        )
    }
    
    private func makeConversationManager(for user: User) async throws -> ConversationManager {
        let modelContext = try await getModelContext()
        return ConversationManager(modelContext: modelContext)
    }
}

// MARK: - SwiftUI View Extension

// Note: The withViewModel helper was removed because @Observable types 
// don't conform to ObservableObject. Views should manually create their
// ViewModels using the DIViewModelFactory from the environment container.