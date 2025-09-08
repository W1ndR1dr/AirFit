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
        // Resolve all dependencies in parallel - AICoachService is now pre-registered
        async let dashboardRepository = container.resolve(DashboardRepositoryProtocol.self)
        async let healthKitService = container.resolve(HealthKitServiceProtocol.self)
        async let nutritionService = container.resolve(NutritionServiceProtocol.self)
        async let aiCoachService = container.resolve(AICoachServiceProtocol.self)
        async let nutritionImportService = container.resolve(NutritionImportService.self)
        async let nutritionGoalService = container.resolve(NutritionGoalServiceProtocol.self)

        // Resolve import service now and bridge as a closure (avoid capturing async let)
        let importServiceResolved = try? await nutritionImportService
        let importSync: @MainActor (User) async -> Void = { user in
            if let svc = importServiceResolved {
                await svc.syncToday(for: user)
            }
        }

        return try await DashboardViewModel(
            user: user,
            dashboardRepository: dashboardRepository,
            healthKitService: healthKitService,
            aiCoachService: aiCoachService,
            nutritionService: nutritionService,
            nutritionImportSync: importSync,
            nutritionGoalService: try? await nutritionGoalService
        )
    }

    // MARK: - Settings

    func makeSettingsViewModel(user: User) async throws -> SettingsViewModel {
        // Resolve @MainActor services using resolveOnMain for iOS 26 compatibility
        let dataExporter = try await container.resolveOnMain(DataExporterProtocol.self)
        
        // Resolve other dependencies in parallel
        async let settingsRepository = container.resolve(SettingsRepositoryProtocol.self)
        async let userWriteRepository = container.resolve(UserWriteRepositoryProtocol.self)
        async let apiKeyManager = container.resolve(APIKeyManagementProtocol.self)
        async let aiService = container.resolve(AIServiceProtocol.self)
        async let notificationManager = container.resolve(NotificationManager.self)

        let coordinator = SettingsCoordinator()

        return try await SettingsViewModel(
            settingsRepository: settingsRepository,
            userWriteRepository: userWriteRepository,
            user: user,
            apiKeyManager: apiKeyManager,
            aiService: aiService,
            notificationManager: notificationManager,
            coordinator: coordinator,
            dataExporter: dataExporter
        )
    }

    // MARK: - Workouts (REMOVED - No longer tracking workouts)

    // MARK: - Chat

    func makeChatViewModel(user: User) async throws -> ChatViewModel {
        // Resolve dependencies in parallel - no longer need direct ModelContext access
        async let chatHistoryRepository = container.resolve(ChatHistoryRepositoryProtocol.self)
        async let aiService = container.resolve(AIServiceProtocol.self)
        async let voiceManager = container.resolve(VoiceInputManager.self)
        async let coachEngine = makeCoachEngine(for: user)
        async let streamStore = container.resolve(ChatStreamingStore.self)

        // Await all at once and create ViewModel
        return try await ChatViewModel(
            chatHistoryRepository: chatHistoryRepository,
            user: user,
            coachEngine: coachEngine,
            aiService: aiService,
            coordinator: ChatCoordinator(),
            voiceManager: voiceManager,
            streamStore: streamStore
        )
    }

    // MARK: - Food Tracking

    func makeFoodTrackingViewModel(user: User) async throws -> FoodTrackingViewModel {
        // Resolve dependencies in parallel
        async let voiceInputManager = container.resolve(VoiceInputManager.self)
        async let nutritionService = container.resolve(NutritionServiceProtocol.self)
        async let coachEngine = makeCoachEngine(for: user)
        async let healthKitManager = container.resolve(HealthKitManager.self)
        async let nutritionCalculator = container.resolve(NutritionCalculatorProtocol.self)
        async let foodRepository = container.resolve(FoodTrackingRepositoryProtocol.self)

        // Create adapter with resolved voice manager
        let foodVoiceAdapter = FoodVoiceAdapter(voiceInputManager: try await voiceInputManager)

        return try await FoodTrackingViewModel(
            foodRepository: foodRepository,
            user: user,
            foodVoiceAdapter: foodVoiceAdapter,
            nutritionService: nutritionService,
            coachEngine: coachEngine,
            coordinator: FoodTrackingCoordinator(),
            healthKitManager: healthKitManager,
            nutritionCalculator: nutritionCalculator
        )
    }


    // MARK: - Body

    func makeBodyViewModel(user: User) async throws -> BodyViewModel {
        // Resolve dependencies
        async let userReadRepository = container.resolve(UserReadRepositoryProtocol.self)
        async let healthKitManager = container.resolve(HealthKitManaging.self)

        return try await BodyViewModel(
            userReadRepository: userReadRepository,
            user: user,
            healthKitManager: healthKitManager
        )
    }

    // MARK: - Onboarding

    func makeOnboardingIntelligence() async throws -> OnboardingIntelligence {
        // OnboardingIntelligence is now a simple, self-contained component
        return try await container.resolve(OnboardingIntelligence.self)
    }

    // Removed duplicate - use makeFoodTrackingViewModel(user:) instead

    // MARK: - Private Helpers

    private func makeCoachEngine(for user: User) async throws -> CoachEngine {
        // Get ModelContext first (not Sendable)
        let modelContext = try await getModelContext()

        // Resolve all other dependencies in parallel for faster initialization
        async let aiService = container.resolve(AIServiceProtocol.self)
        async let personaService = container.resolve(PersonaService.self)
        async let contextAssembler = container.resolve(ContextAssembler.self)
        async let healthKitManager = container.resolve(HealthKitManaging.self)
        async let routingConfiguration = container.resolve(RoutingConfiguration.self)
        async let nutritionCalculator = container.resolve(NutritionCalculatorProtocol.self)
        async let muscleGroupVolumeService = container.resolve(MuscleGroupVolumeServiceProtocol.self)
        async let streamStore = container.resolve(ChatStreamingStore.self)

        // Create components that don't need async resolution
        let localCommandParser = LocalCommandParser()
        let conversationManager = ConversationManager(modelContext: modelContext)

        // Create the orchestrator
        let orchestrator = try await CoachOrchestrator(
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
            streamStore: streamStore
        )

        return try await CoachEngine(
            localCommandParser: localCommandParser,
            personaService: personaService,
            conversationManager: conversationManager,
            aiService: aiService,
            contextAssembler: contextAssembler,
            modelContext: modelContext,
            routingConfiguration: routingConfiguration,
            healthKitManager: healthKitManager,
            nutritionCalculator: nutritionCalculator,
            orchestrator: orchestrator
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
