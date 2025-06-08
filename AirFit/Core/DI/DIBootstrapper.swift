import Foundation
import SwiftData

// MARK: - Preview Helpers

/// Simple API key manager for SwiftUI previews
private final class PreviewAPIKeyManager: APIKeyManagementProtocol {
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        // No-op for previews
    }
    
    func getAPIKey(for provider: AIProvider) async throws -> String {
        // Throw for previews - offline mode will be used
        throw AppError.unauthorized
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        // No-op for previews
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        return false
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        return []
    }
}

/// Bootstraps the DI container with all required services
@MainActor
public final class DIBootstrapper {
    
    /// Create and configure the main app container
    public static func createAppContainer(modelContainer: ModelContainer) async throws -> DIContainer {
        let container = DIContainer()
        
        // MARK: - Core Services (Singletons)
        
        // Keychain - true singleton, stateless wrapper
        container.registerSingleton(KeychainWrapper.self, instance: KeychainWrapper.shared)
        
        // API Key Manager
        container.register(APIKeyManagementProtocol.self, lifetime: .singleton) { container in
            let keychain = try await container.resolve(KeychainWrapper.self)
            return APIKeyManager(keychain: keychain)
        }
        
        // Network Client
        container.register(NetworkClientProtocol.self, lifetime: .singleton) { _ in
            NetworkClient()
        }
        
        // Model Container - only register the container, not the context
        // Services will get mainContext directly from the container when needed
        AppLogger.info("DIBootstrapper: Registering ModelContainer", category: .app)
        container.registerSingleton(ModelContainer.self, instance: modelContainer)
        AppLogger.info("DIBootstrapper: ModelContainer registered successfully", category: .app)
        
        // MARK: - AI Services
        
        // LLM Orchestrator
        container.register(LLMOrchestrator.self, lifetime: .singleton) { container in
            let apiKeyManager = try await container.resolve(APIKeyManagementProtocol.self)
            return await LLMOrchestrator(apiKeyManager: apiKeyManager)
        }
        
        // AI Service - production only, no fallback
        container.register(AIServiceProtocol.self, lifetime: .singleton) { container in
            let llmOrchestrator = try await container.resolve(LLMOrchestrator.self)
            return AIService(llmOrchestrator: llmOrchestrator)
        }
        
        // MARK: - User Services
        
        // User Service
        container.register(UserServiceProtocol.self, lifetime: .singleton) { _ in
            await MainActor.run {
                UserService(modelContext: modelContainer.mainContext)
            }
        }
        
        // MARK: - Health Services
        
        // HealthKit Manager
        container.register(HealthKitManager.self, lifetime: .singleton) { _ in
            await MainActor.run {
                HealthKitManager.shared
            }
        }
        
        // Weather Service
        container.register(WeatherServiceProtocol.self, lifetime: .singleton) { _ in
            await MainActor.run {
                WeatherService()
            }
        }
        
        // MARK: - Module Services (Transient - created per-use)
        
        // Context Assembler - needed by HealthKitService
        container.register(ContextAssembler.self) { container in
            let healthKitManager = try await container.resolve(HealthKitManager.self)
            let goalService = try? await container.resolve(GoalServiceProtocol.self)
            return await MainActor.run {
                ContextAssembler(
                    healthKitManager: healthKitManager,
                    goalService: goalService
                )
            }
        }
        
        // Dashboard Module Services
        container.register(HealthKitService.self) { container in
            let healthKitManager = try await container.resolve(HealthKitManager.self)
            let contextAssembler = try await container.resolve(ContextAssembler.self)
            return HealthKitService(healthKitManager: healthKitManager, contextAssembler: contextAssembler)
        }
        
        // Also register the protocol interface to the same service
        container.register(HealthKitServiceProtocol.self) { container in
            try await container.resolve(HealthKitService.self)
        }
        
        container.register(DashboardNutritionService.self) { _ in
            await MainActor.run {
                DashboardNutritionService(modelContext: modelContainer.mainContext)
            }
        }
        
        // Also register the protocol interface to the same service
        container.register(DashboardNutritionServiceProtocol.self) { container in
            try await container.resolve(DashboardNutritionService.self)
        }
        
        // Note: AICoachService requires a user-specific CoachEngine
        // Register it as transient and create per-user in ViewModelFactory
        
        // Nutrition Service
        container.register(NutritionServiceProtocol.self) { _ in
            await MainActor.run {
                NutritionService(modelContext: modelContainer.mainContext)
            }
        }
        
        // Workout Service
        container.register(WorkoutServiceProtocol.self) { _ in
            await MainActor.run {
                WorkoutService(modelContext: modelContainer.mainContext)
            }
        }
        
        // Exercise Database
        container.register(ExerciseDatabase.self, lifetime: .singleton) { _ in
            await MainActor.run {
                ExerciseDatabase.shared
            }
        }
        
        // Workout Sync Service
        container.register(WorkoutSyncService.self, lifetime: .singleton) { _ in
            await MainActor.run {
                WorkoutSyncService.shared
            }
        }
        
        // Analytics Service
        container.register(AnalyticsServiceProtocol.self) { _ in
            await MainActor.run {
                AnalyticsService(modelContext: modelContainer.mainContext)
            }
        }
        
        // Goal Service  
        container.register(GoalServiceProtocol.self) { _ in
            await MainActor.run {
                GoalService(modelContext: modelContainer.mainContext)
            }
        }
        
        // Also register the concrete type
        container.register(GoalService.self) { _ in
            await MainActor.run {
                GoalService(modelContext: modelContainer.mainContext)
            }
        }
        
        // AI-specific service registrations for FunctionCallDispatcher
        container.register(AIGoalServiceProtocol.self) { container in
            let goalService = try await container.resolve(GoalServiceProtocol.self)
            return await MainActor.run {
                AIGoalService(goalService: goalService)
            }
        }
        
        container.register(AIWorkoutServiceProtocol.self) { container in
            let workoutService = try await container.resolve(WorkoutServiceProtocol.self)
            return await MainActor.run {
                AIWorkoutService(workoutService: workoutService)
            }
        }
        
        container.register(AIAnalyticsServiceProtocol.self) { container in
            let analyticsService = try await container.resolve(AnalyticsServiceProtocol.self)
            return await MainActor.run {
                AIAnalyticsService(analyticsService: analyticsService)
            }
        }
        
        // MARK: - FoodTracking Module Services
        
        // Food Voice Adapter
        container.register(FoodVoiceAdapterProtocol.self) { container in
            let voiceInputManager = try await container.resolve(VoiceInputManager.self)
            return await MainActor.run {
                FoodVoiceAdapter(voiceInputManager: voiceInputManager)
            }
        }
        
        // Food Tracking Coordinator
        container.register(FoodTrackingCoordinator.self) { _ in
            await MainActor.run {
                FoodTrackingCoordinator()
            }
        }
        
        // MARK: - Voice Services
        
        // Voice Input Manager
        container.register(VoiceInputManager.self, lifetime: .singleton) { _ in
            await MainActor.run {
                VoiceInputManager()
            }
        }
        
        // MARK: - Notification Services
        
        // Notification Manager
        container.register(NotificationManager.self, lifetime: .singleton) { _ in
            await MainActor.run {
                NotificationManager.shared
            }
        }
        
        return container
    }
    
    /// Create and configure a demo container (no API keys required)
    public static func createDemoContainer(modelContainer: ModelContainer) async throws -> DIContainer {
        // Set demo mode flag
        UserDefaults.standard.set(true, forKey: "isUsingDemoMode")
        
        // Create regular container - it will use DemoAIService based on the flag
        return try await createAppContainer(modelContainer: modelContainer)
    }
    
    /// Create a test container with mock services
    /// Note: This method should only be called from test targets where mock types are available
    public static func createTestContainer() -> DIContainer {
        let container = DIContainer()
        
        // In production code, we can't directly reference test mocks
        // Tests should extend this method or create their own container setup
        // This provides a basic structure that tests can build upon
        
        // Register placeholder services for testing
        // Tests will override these with actual mocks
        
        container.register(APIKeyManagementProtocol.self, lifetime: .singleton) { _ in
            // Will be overridden by test setup
            fatalError("Test container not properly configured - override in test setup")
        }
        
        container.register(AIServiceProtocol.self, lifetime: .singleton) { _ in
            // Use offline service as a safe fallback for tests
            OfflineAIService()
        }
        
        // Add other service registrations that tests can override
        
        return container
    }
    
    /// Create a preview container for SwiftUI previews
    public static func createPreviewContainer() async throws -> DIContainer {
        // Create in-memory model container
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            FoodEntry.self,
            FoodItem.self,
            Workout.self,
            Exercise.self,
            ChatSession.self,
            ChatMessage.self,
            ConversationSession.self,
            ConversationResponse.self,
            TrackedGoal.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        
        // Create container with offline services for previews
        let container = DIContainer()
        
        // Use offline/mock services for previews
        container.registerSingleton(ModelContainer.self, instance: modelContainer)
        container.registerSingleton(KeychainWrapper.self, instance: KeychainWrapper.shared)
        
        container.register(APIKeyManagementProtocol.self, lifetime: .singleton) { _ in
            // For previews, create a simple implementation that returns empty keys
            PreviewAPIKeyManager()
        }
        
        container.register(AIServiceProtocol.self, lifetime: .singleton) { _ in
            OfflineAIService()
        }
        
        // ... register other preview-appropriate services
        
        return container
    }
}