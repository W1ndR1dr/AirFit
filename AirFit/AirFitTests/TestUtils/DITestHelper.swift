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
        
        container.register(HealthKitManaging.self, lifetime: .singleton) { _ in
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
        
        container.register(NotificationManager.self, lifetime: .singleton) { _ in
            MockNotificationManager()
        }
        
        container.register(VoiceInputManager.self, lifetime: .singleton) { _ in
            MockVoiceInputManager()
        }
        
        // LLM and AI-related mocks
        container.register(LLMOrchestrator.self, lifetime: .singleton) { _ in
            MockLLMOrchestrator()
        }
        
        // Context Assembler for health services
        container.register(ContextAssembler.self) { container in
            let modelContainer = try await container.resolve(ModelContainer.self)
            let healthKitManager = try await container.resolve(HealthKitManager.self)
            let weatherService = try await container.resolve(WeatherServiceProtocol.self)
            return ContextAssembler(
                healthKitManager: healthKitManager,
                weatherService: weatherService,
                modelContext: modelContainer.mainContext
            )
        }
        
        // Dashboard services
        container.register(HealthKitService.self) { container in
            MockHealthKitService()
        }
        
        container.register(DashboardNutritionService.self) { container in
            MockDashboardNutritionService()
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
            name: "Test User",
            age: 30,
            heightCM: 175,
            weightKG: 70,
            biologicalSex: .male,
            activityLevel: .moderate,
            primaryGoal: .maintainWeight,
            preferredUnits: .metric
        )
    }
}

extension OnboardingProfile {
    static var mock: OnboardingProfile {
        OnboardingProfile(
            preferredUnits: "metric",
            weight: 70,
            height: 175,
            biologicalSex: "male",
            lifeSnapshot: "Active professional",
            coreAspiration: "Stay healthy and fit",
            coachingStyle: .balanced,
            motivationalAccents: .encouraging,
            sleepSchedule: "11pm-7am",
            workLifeBoundaries: .moderate,
            communicationPreferences: nil,
            personaPromptData: nil
        )
    }
}