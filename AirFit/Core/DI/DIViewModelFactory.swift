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
    
    // MARK: - Dashboard
    
    func makeDashboardViewModel(user: User) async throws -> DashboardViewModel {
        let modelContainer = try await container.resolve(ModelContainer.self)
        let healthKitService = try await container.resolve(HealthKitServiceProtocol.self)
        let nutritionService = try await container.resolve(DashboardNutritionServiceProtocol.self)
        
        // Create user-specific CoachEngine and AICoachService
        let coachEngine = try await makeCoachEngine(for: user)
        let aiCoachService = AICoachService(coachEngine: coachEngine)
        
        return DashboardViewModel(
            user: user,
            modelContext: modelContainer.mainContext,
            healthKitService: healthKitService,
            aiCoachService: aiCoachService,
            nutritionService: nutritionService
        )
    }
    
    // MARK: - Settings
    
    func makeSettingsViewModel(user: User) async throws -> SettingsViewModel {
        let modelContainer = try await container.resolve(ModelContainer.self)
        let apiKeyManager = try await container.resolve(APIKeyManagementProtocol.self)
        let aiService = try await container.resolve(AIServiceProtocol.self)
        let notificationManager = try await container.resolve(NotificationManager.self)
        let coordinator = SettingsCoordinator()
        
        return SettingsViewModel(
            modelContext: modelContainer.mainContext,
            user: user,
            apiKeyManager: apiKeyManager,
            aiService: aiService,
            notificationManager: notificationManager,
            coordinator: coordinator
        )
    }
    
    // MARK: - Workouts
    
    func makeWorkoutViewModel(user: User) async throws -> WorkoutViewModel {
        let modelContainer = try await container.resolve(ModelContainer.self)
        let healthKitManager = try await container.resolve(HealthKitManager.self)
        let exerciseDatabase = try await container.resolve(ExerciseDatabase.self)
        let workoutSyncService = try await container.resolve(WorkoutSyncService.self)
        
        // Create user-specific CoachEngine
        let coachEngine = try await makeCoachEngine(for: user)
        
        return WorkoutViewModel(
            modelContext: modelContainer.mainContext,
            user: user,
            coachEngine: coachEngine,
            healthKitManager: healthKitManager,
            exerciseDatabase: exerciseDatabase,
            workoutSyncService: workoutSyncService
        )
    }
    
    // MARK: - Chat
    
    func makeChatViewModel(user: User) async throws -> ChatViewModel {
        let modelContainer = try await container.resolve(ModelContainer.self)
        let aiService = try await container.resolve(AIServiceProtocol.self, name: "adaptive")
        
        // Create user-specific CoachEngine
        let coachEngine = try await makeCoachEngine(for: user)
        
        return ChatViewModel(
            modelContext: modelContainer.mainContext,
            user: user,
            coachEngine: coachEngine,
            aiService: aiService,
            coordinator: ChatCoordinator()
        )
    }
    
    // MARK: - Food Tracking
    
    func makeFoodTrackingViewModel(user: User) async throws -> FoodTrackingViewModel {
        let modelContainer = try await container.resolve(ModelContainer.self)
        let voiceInputManager = try await container.resolve(VoiceInputManager.self)
        let nutritionService = try await container.resolve(NutritionServiceProtocol.self)
        let coordinator = FoodTrackingCoordinator()
        
        // Create food voice adapter
        let foodVoiceAdapter = FoodVoiceAdapter(voiceInputManager: voiceInputManager)
        
        // Create coach engine
        let coachEngine = try await makeCoachEngine(for: user)
        
        return FoodTrackingViewModel(
            modelContext: modelContainer.mainContext,
            user: user,
            foodVoiceAdapter: foodVoiceAdapter,
            nutritionService: nutritionService,
            coachEngine: coachEngine,
            coordinator: coordinator
        )
    }
    
    
    // MARK: - Onboarding
    
    func makeOnboardingViewModel() async throws -> OnboardingViewModel {
        let modelContainer = try await container.resolve(ModelContainer.self)
        let userService = try await container.resolve(UserServiceProtocol.self)
        let apiKeyManager = try await container.resolve(APIKeyManagementProtocol.self)
        let aiService = try await container.resolve(AIServiceProtocol.self)
        
        // Create onboarding service
        let onboardingService = OnboardingService(
            modelContext: modelContainer.mainContext
        )
        
        // Create HealthKit auth manager
        let healthKitAuthManager = HealthKitAuthManager()
        
        return OnboardingViewModel(
            aiService: aiService,
            onboardingService: onboardingService,
            modelContext: modelContainer.mainContext,
            apiKeyManager: apiKeyManager,
            userService: userService,
            healthKitAuthManager: healthKitAuthManager
        )
    }
    
    func makeOnboardingFlowCoordinator() async throws -> OnboardingFlowCoordinator {
        let modelContainer = try await container.resolve(ModelContainer.self)
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
            modelContext: modelContainer.mainContext,
            cache: cache
        )
        
        // Create conversation flow definition
        let flowDefinition = ConversationFlowData.defaultFlow()
        
        // Create conversation manager
        let conversationManager = ConversationFlowManager(
            flowDefinition: flowDefinition,
            modelContext: modelContainer.mainContext
        )
        
        return OnboardingFlowCoordinator(
            conversationManager: conversationManager,
            personaService: personaService,
            userService: userService,
            modelContext: modelContainer.mainContext
        )
    }
    
    // Removed duplicate - use makeFoodTrackingViewModel(user:) instead
    
    // MARK: - Private Helpers
    
    private func makeCoachEngine(for user: User) async throws -> CoachEngine {
        let modelContainer = try await container.resolve(ModelContainer.self)
        let aiService = try await container.resolve(AIServiceProtocol.self)
        let modelContext = modelContainer.mainContext
        
        // Create required components
        let localCommandParser = LocalCommandParser()
        let personaEngine = PersonaEngine()
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
        
        return CoachEngine(
            localCommandParser: localCommandParser,
            functionDispatcher: functionDispatcher,
            personaEngine: personaEngine,
            conversationManager: conversationManager,
            aiService: aiService,
            contextAssembler: contextAssembler,
            modelContext: modelContext
        )
    }
    
    private func makeConversationManager(for user: User) async throws -> ConversationManager {
        let modelContainer = try await container.resolve(ModelContainer.self)
        return ConversationManager(modelContext: modelContainer.mainContext)
    }
}

// MARK: - SwiftUI View Extension

// Note: The withViewModel helper was removed because @Observable types 
// don't conform to ObservableObject. Views should manually create their
// ViewModels using the DIViewModelFactory from the environment container.