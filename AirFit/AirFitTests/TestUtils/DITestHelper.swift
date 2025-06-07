import Foundation
import SwiftData
@testable import AirFit

/// Helper for setting up DI containers in tests with proper mock registrations
@MainActor
enum DITestHelper {
    
    /// Create a fully configured test container with all mocks registered
    static func createTestContainer() async throws -> DIContainer {
        let container = DIContainer()
        
        // Create in-memory model container for tests
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
            DailyLog.self,
            CoachMessage.self,
            FoodItemTemplate.self,
            MealTemplate.self,
            WorkoutTemplate.self,
            ExerciseTemplate.self,
            SetTemplate.self,
            ExerciseSet.self,
            HealthKitSyncRecord.self,
            ChatAttachment.self,
            NutritionData.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        
        // Register core services
        container.registerSingleton(ModelContainer.self, instance: modelContainer)
        container.registerSingleton(KeychainWrapper.self, instance: KeychainWrapper.shared)
        
        // Register all mock services
        container.register(APIKeyManagementProtocol.self, lifetime: .singleton) { _ in
            MockAPIKeyManager()
        }
        
        container.register(AIServiceProtocol.self, lifetime: .singleton) { _ in
            MockAIService()
        }
        
        container.register(UserServiceProtocol.self, lifetime: .singleton) { _ in
            MockUserService()
        }
        
        container.register(HealthKitManagerProtocol.self, lifetime: .singleton) { _ in
            MockHealthKitManager()
        }
        
        container.register(HealthKitManager.self, lifetime: .singleton) { _ in
            MockHealthKitManager()
        }
        
        container.register(WeatherServiceProtocol.self, lifetime: .singleton) { _ in
            MockWeatherService()
        }
        
        container.register(NetworkClientProtocol.self, lifetime: .singleton) { _ in
            MockNetworkClient()
        }
        
        // Module services
        container.register(NutritionServiceProtocol.self) { _ in
            MockNutritionService()
        }
        
        container.register(WorkoutServiceProtocol.self) { _ in
            MockWorkoutService()
        }
        
        container.register(AnalyticsServiceProtocol.self) { _ in
            MockAnalyticsService()
        }
        
        container.register(GoalServiceProtocol.self) { _ in
            MockGoalService()
        }
        
        container.register(NotificationManager.self, lifetime: .singleton) { _ in
            MockNotificationManager()
        }
        
        container.register(NotificationManagerProtocol.self, lifetime: .singleton) { _ in
            MockNotificationManager()
        }
        
        container.register(VoiceInputManager.self, lifetime: .singleton) { _ in
            MockVoiceInputManager()
        }
        
        // LLM and AI-related mocks
        container.register(LLMOrchestrator.self, lifetime: .singleton) { container in
            let apiKeyManager = try await container.resolve(APIKeyManagementProtocol.self)
            return await LLMOrchestrator(apiKeyManager: apiKeyManager)
        }
        
        // Context Assembler for health services
        container.register(ContextAssembler.self) { container in
            let healthKitManager = try await container.resolve(HealthKitManager.self) as! MockHealthKitManager
            return ContextAssembler(healthKitManager: healthKitManager)
        }
        
        // Dashboard services - only register protocols since mocks can't be concrete actor types
        container.register(HealthKitServiceProtocol.self) { _ in
            MockHealthKitService()
        }
        
        container.register(AICoachServiceProtocol.self) { _ in
            MockAICoachService()
        }
        
        container.register(DashboardNutritionServiceProtocol.self) { _ in
            MockDashboardNutritionService()
        }
        
        // Onboarding services (concrete classes, not protocols)
        container.register(ConversationFlowManager.self) { @MainActor container in
            let modelContainer = try await container.resolve(ModelContainer.self)
            let flowDefinition: [String: ConversationNode] = [:] // Empty for tests
            return MockConversationFlowManager()
        }
        
        container.register(ConversationPersistence.self) { @MainActor container in
            let modelContainer = try await container.resolve(ModelContainer.self)
            return MockConversationPersistence()
        }
        
        container.register(PersonaService.self) { @MainActor container in
            return MockPersonaService()
        }
        
        // Food tracking services
        container.register(FoodVoiceAdapterProtocol.self) { _ in
            MockFoodVoiceAdapter()
        }
        
        container.register(FoodTrackingCoordinatorProtocol.self) { _ in
            MockFoodTrackingCoordinator()
        }
        
        // Voice/Speech services
        container.register(WhisperServiceWrapperProtocol.self) { _ in
            MockWhisperServiceWrapper()
        }
        
        // Onboarding services
        container.register(OnboardingServiceProtocol.self) { _ in
            MockOnboardingService()
        }
        
        // Additional AI services
        container.register(CoachEngine.self) { @MainActor container in
            MockCoachEngine()
        }
        
        return container
    }
    
    /// Create a minimal test container for unit tests that don't need full setup
    static func createMinimalTestContainer() -> DIContainer {
        let container = DIContainer()
        
        // Just the essentials
        container.register(AIServiceProtocol.self, lifetime: .singleton) { _ in
            OfflineAIService()
        }
        
        container.register(APIKeyManagementProtocol.self, lifetime: .singleton) { _ in
            MockAPIKeyManager()
        }
        
        return container
    }
}

// MARK: - Test Extensions

extension DIContainer {
    /// Configure a specific mock in the test container
    func configureMock<T>(_ type: T.Type, configuration: (T) -> Void) async throws {
        let mock = try await resolve(type)
        configuration(mock)
    }
}

// MARK: - Common Test Data

extension User {
    static var mock: User {
        User(
            email: "test@example.com",
            name: "Test User"
        )
    }
}

extension OnboardingProfile {
    static var mock: OnboardingProfile {
        OnboardingProfile(
            personaPromptData: Data(),
            communicationPreferencesData: Data(),
            rawFullProfileData: Data()
        )
    }
}