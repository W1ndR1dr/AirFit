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
        // Get ModelContext first (not Sendable)
        let modelContext = try await getModelContext()

        // Resolve all dependencies in parallel - AICoachService is now pre-registered
        async let healthKitService = container.resolve(HealthKitServiceProtocol.self)
        async let nutritionService = container.resolve(DashboardNutritionServiceProtocol.self)
        async let aiCoachService = container.resolve(AICoachServiceProtocol.self)

        return try await DashboardViewModel(
            user: user,
            modelContext: modelContext,
            healthKitService: healthKitService,
            aiCoachService: aiCoachService,
            nutritionService: nutritionService
        )
    }

    // MARK: - Settings

    func makeSettingsViewModel(user: User) async throws -> SettingsViewModel {
        // Get ModelContext first (not Sendable)
        let modelContext = try await getModelContext()

        // Resolve other dependencies in parallel
        async let apiKeyManager = container.resolve(APIKeyManagementProtocol.self)
        async let aiService = container.resolve(AIServiceProtocol.self)
        async let notificationManager = container.resolve(NotificationManager.self)

        let coordinator = SettingsCoordinator()

        return try await SettingsViewModel(
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
        // Get ModelContext first (not Sendable)
        let modelContext = try await getModelContext()

        // Resolve other dependencies in parallel
        async let healthKitManager = container.resolve(HealthKitManager.self)
        async let exerciseDatabase = container.resolve(ExerciseDatabase.self)
        async let workoutSyncService = container.resolve(WorkoutSyncService.self)
        async let coachEngine = makeCoachEngine(for: user)

        return try await WorkoutViewModel(
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
        // Get ModelContext first (not Sendable)
        let modelContext = try await getModelContext()

        // Resolve other dependencies in parallel
        async let aiService = container.resolve(AIServiceProtocol.self, name: "adaptive")
        async let voiceManager = container.resolve(VoiceInputManager.self)
        async let coachEngine = makeCoachEngine(for: user)

        // Await all at once and create ViewModel
        return try await ChatViewModel(
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
        // Get ModelContext first (not Sendable)
        let modelContext = try await getModelContext()

        // Resolve other dependencies in parallel
        async let voiceInputManager = container.resolve(VoiceInputManager.self)
        async let nutritionService = container.resolve(NutritionServiceProtocol.self)
        async let coachEngine = makeCoachEngine(for: user)
        async let healthKitManager = container.resolve(HealthKitManager.self)
        async let nutritionCalculator = container.resolve(NutritionCalculatorProtocol.self)

        // Create adapter with resolved voice manager
        let foodVoiceAdapter = FoodVoiceAdapter(voiceInputManager: try await voiceInputManager)

        return try await FoodTrackingViewModel(
            modelContext: modelContext,
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
        // Get ModelContext first (not Sendable)
        let modelContext = try await getModelContext()

        // Resolve other dependencies
        async let healthKitManager = container.resolve(HealthKitManaging.self)

        return try await BodyViewModel(
            modelContext: modelContext,
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
        async let exerciseDatabase = container.resolve(ExerciseDatabase.self)

        // Create components that don't need async resolution
        let localCommandParser = LocalCommandParser()
        let conversationManager = ConversationManager(modelContext: modelContext)

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
            muscleGroupVolumeService: muscleGroupVolumeService,
            exerciseDatabase: exerciseDatabase
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
