import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class DIBootstrapperTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var modelContainer: ModelContainer!
    
    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()
        
        // Create test model container
        modelContainer = try ModelContainer.createTestContainer()
    }
    
    override func tearDown() async throws {
        container = nil
        modelContainer = nil
        try super.tearDown()
    }
    
    // MARK: - App Container Tests
    
    func test_createAppContainer_registersAllRequiredServices() async throws {
        // Act
        container = try await DIBootstrapper.createAppContainer(modelContainer: modelContainer)
        
        // Assert - Core services should be registered
        let networkManager = try await container.resolve(NetworkManagementProtocol.self)
        XCTAssertNotNil(networkManager)
        XCTAssertTrue(networkManager is NetworkManager)
        
        let apiKeyManager = try await container.resolve(APIKeyManagementProtocol.self)
        XCTAssertNotNil(apiKeyManager)
        XCTAssertTrue(apiKeyManager is APIKeyManager)
        
        let userService = try await container.resolve(UserServiceProtocol.self)
        XCTAssertNotNil(userService)
        XCTAssertTrue(userService is UserService)
    }
    
    func test_createAppContainer_registersAIServices() async throws {
        // Act
        container = try await DIBootstrapper.createAppContainer(modelContainer: modelContainer)
        
        // Assert
        let aiService = try await container.resolve(AIServiceProtocol.self)
        XCTAssertNotNil(aiService)
        XCTAssertTrue(aiService is AIService)
        
        let coachEngine = try await container.resolve(CoachEngineProtocol.self)
        XCTAssertNotNil(coachEngine)
        XCTAssertTrue(coachEngine is CoachEngine)
    }
    
    func test_createAppContainer_registersHealthServices() async throws {
        // Act
        container = try await DIBootstrapper.createAppContainer(modelContainer: modelContainer)
        
        // Assert
        let healthKitManager = try await container.resolve(HealthKitManaging.self)
        XCTAssertNotNil(healthKitManager)
        XCTAssertTrue(healthKitManager is HealthKitManager)
        
        let healthKitService = try await container.resolve(HealthKitService.self)
        XCTAssertNotNil(healthKitService)
    }
    
    func test_createAppContainer_registersSingletonServices() async throws {
        // Act
        container = try await DIBootstrapper.createAppContainer(modelContainer: modelContainer)
        
        // Assert - Verify singletons return same instance
        let healthKit1 = try await container.resolve(HealthKitManager.self)
        let healthKit2 = try await container.resolve(HealthKitManager.self)
        XCTAssertTrue(healthKit1 === healthKit2, "HealthKitManager should be singleton")
        
        let notificationManager1 = try await container.resolve(NotificationManager.self)
        let notificationManager2 = try await container.resolve(NotificationManager.self)
        XCTAssertTrue(notificationManager1 === notificationManager2, "NotificationManager should be singleton")
    }
    
    // MARK: - Test Container Tests
    
    func test_createTestContainer_createsValidContainer() throws {
        // Act
        container = DIBootstrapper.createTestContainer()
        
        // Assert
        XCTAssertNotNil(container)
        
        // Should have basic registrations that tests can override
        // Note: We can't test specific mocks here since they're in test target
    }
    
    // MARK: - Preview Container Tests
    
    func test_createPreviewContainer_createsContainerWithOfflineServices() async throws {
        // Act
        container = try await DIBootstrapper.createPreviewContainer()
        
        // Assert
        let aiService = try await container.resolve(AIServiceProtocol.self)
        XCTAssertNotNil(aiService)
        XCTAssertTrue(aiService is OfflineAIService, "Preview should use offline AI")
        
        let apiKeyManager = try await container.resolve(APIKeyManagementProtocol.self)
        XCTAssertNotNil(apiKeyManager)
        // Should be preview API key manager that returns false for hasAPIKey
        let hasKey = await apiKeyManager.hasAPIKey(for: .openAI)
        XCTAssertFalse(hasKey, "Preview API key manager should return false")
    }
    
    func test_createPreviewContainer_includesPreviewData() async throws {
        // Act
        container = try await DIBootstrapper.createPreviewContainer()
        
        // Assert - Should have preview model container with data
        let userService = try await container.resolve(UserServiceProtocol.self)
        XCTAssertNotNil(userService)
        
        // Get current user to verify preview data exists
        let currentUser = await userService.currentUser
        XCTAssertNotNil(currentUser, "Preview container should include sample user")
    }
    
    // MARK: - Service Resolution Tests
    
    func test_appContainer_allServicesResolvable() async throws {
        // Arrange
        container = try await DIBootstrapper.createAppContainer(modelContainer: modelContainer)
        
        // Define all service types that should be resolvable
        let serviceTypes: [Any.Type] = [
            UserServiceProtocol.self,
            GoalServiceProtocol.self,
            NutritionServiceProtocol.self,
            WorkoutServiceProtocol.self,
            HealthKitManaging.self,
            AIServiceProtocol.self,
            CoachEngineProtocol.self,
            FoodCoachEngineProtocol.self,
            NotificationManager.self,
            WeatherServiceProtocol.self,
            FoodVoiceServiceProtocol.self,
            OnboardingServiceProtocol.self
        ]
        
        // Act & Assert - All services should resolve without throwing
        for serviceType in serviceTypes {
            do {
                let service = try await container.resolve(serviceType)
                XCTAssertNotNil(service, "\(serviceType) should resolve")
            } catch {
                XCTFail("Failed to resolve \(serviceType): \(error)")
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func test_createAppContainer_servicesCanInteract() async throws {
        // Arrange
        container = try await DIBootstrapper.createAppContainer(modelContainer: modelContainer)
        
        // Act - Get services that depend on each other
        let userService = try await container.resolve(UserServiceProtocol.self)
        let goalService = try await container.resolve(GoalServiceProtocol.self)
        
        // Assert - Services should be able to work together
        // This verifies the dependency graph is correctly wired
        XCTAssertNotNil(userService)
        XCTAssertNotNil(goalService)
        
        // Goal service depends on user service internally
        // If this doesn't crash, dependencies are wired correctly
    }
    
    // MARK: - Error Handling Tests
    
    func test_container_throwsForUnregisteredService() async throws {
        // Arrange
        container = DIContainer()
        
        // Act & Assert
        do {
            _ = try await container.resolve(String.self)
            XCTFail("Should throw for unregistered type")
        } catch {
            // Expected - should throw DIError
            XCTAssertTrue(error.localizedDescription.contains("not registered"))
        }
    }
}