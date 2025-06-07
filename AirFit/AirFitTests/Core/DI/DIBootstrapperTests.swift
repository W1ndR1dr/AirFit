import XCTest
@testable import AirFit

@MainActor
final class DIBootstrapperTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    
    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
        container = DIContainer()
    }
    
    override func tearDown() {
        container = nil
        super.tearDown()
    }
    
    // MARK: - Registration Tests
    
    func test_registerCoreServices_registersAllRequiredServices() async throws {
        // Act
        try await DIBootstrapper.registerCoreServices(in: container)
        
        // Assert - Core services should be registered
        let networkManager = try await container.resolve(NetworkManagementProtocol.self)
        XCTAssertNotNil(networkManager)
        
        let apiKeyManager = try await container.resolve(APIKeyManagementProtocol.self)
        XCTAssertNotNil(apiKeyManager)
        
        let analyticsService = try await container.resolve(AnalyticsServiceProtocol.self)
        XCTAssertNotNil(analyticsService)
    }
    
    func test_registerDataServices_registersAllDataServices() async throws {
        // Arrange - Core services must be registered first
        try await DIBootstrapper.registerCoreServices(in: container)
        
        // Act
        try await DIBootstrapper.registerDataServices(in: container)
        
        // Assert
        let userService = try await container.resolve(UserServiceProtocol.self)
        XCTAssertNotNil(userService)
        
        let goalService = try await container.resolve(GoalServiceProtocol.self)
        XCTAssertNotNil(goalService)
        
        let nutritionService = try await container.resolve(NutritionServiceProtocol.self)
        XCTAssertNotNil(nutritionService)
        
        let workoutService = try await container.resolve(WorkoutServiceProtocol.self)
        XCTAssertNotNil(workoutService)
    }
    
    func test_registerAIServices_registersAllAIServices() async throws {
        // Arrange - Core services must be registered first
        try await DIBootstrapper.registerCoreServices(in: container)
        
        // Act
        try await DIBootstrapper.registerAIServices(in: container)
        
        // Assert
        let aiService = try await container.resolve(AIServiceProtocol.self)
        XCTAssertNotNil(aiService)
        
        let coachEngine = try await container.resolve(CoachEngineProtocol.self)
        XCTAssertNotNil(coachEngine)
        
        let foodCoachEngine = try await container.resolve(FoodCoachEngineProtocol.self)
        XCTAssertNotNil(foodCoachEngine)
    }
    
    func test_registerHealthServices_registersHealthKitManager() async throws {
        // Act
        try await DIBootstrapper.registerHealthServices(in: container)
        
        // Assert
        let healthKitManager = try await container.resolve(HealthKitManagerProtocol.self)
        XCTAssertNotNil(healthKitManager)
        XCTAssertTrue(healthKitManager is HealthKitManager)
    }
    
    func test_registerTestServices_overridesWithMocks() async throws {
        // Arrange - Register real services first
        try await DIBootstrapper.registerCoreServices(in: container)
        try await DIBootstrapper.registerDataServices(in: container)
        
        // Act - Override with test services
        try await DIBootstrapper.registerTestServices(in: container)
        
        // Assert - Should now resolve to mocks
        let userService = try await container.resolve(UserServiceProtocol.self)
        XCTAssertTrue(userService is MockUserService)
        
        let aiService = try await container.resolve(AIServiceProtocol.self)
        XCTAssertTrue(aiService is MockAIService)
        
        let healthKitManager = try await container.resolve(HealthKitManagerProtocol.self)
        XCTAssertTrue(healthKitManager is MockHealthKitManager)
    }
    
    // MARK: - Environment Tests
    
    func test_configure_forProduction_registersRealServices() async throws {
        // Act
        try await DIBootstrapper.configure(container: container, environment: .production)
        
        // Assert - Should have real services
        let networkManager = try await container.resolve(NetworkManagementProtocol.self)
        XCTAssertTrue(networkManager is NetworkManager)
        
        let userService = try await container.resolve(UserServiceProtocol.self)
        XCTAssertTrue(userService is UserService)
    }
    
    func test_configure_forDevelopment_registersRealServices() async throws {
        // Act
        try await DIBootstrapper.configure(container: container, environment: .development)
        
        // Assert - Should have real services (same as production)
        let networkManager = try await container.resolve(NetworkManagementProtocol.self)
        XCTAssertTrue(networkManager is NetworkManager)
    }
    
    func test_configure_forTesting_registersMockServices() async throws {
        // Act
        try await DIBootstrapper.configure(container: container, environment: .testing)
        
        // Assert - Should have mock services
        let networkManager = try await container.resolve(NetworkManagementProtocol.self)
        XCTAssertTrue(networkManager is MockNetworkManager)
        
        let userService = try await container.resolve(UserServiceProtocol.self)
        XCTAssertTrue(userService is MockUserService)
    }
    
    // MARK: - Dependency Order Tests
    
    func test_registerDataServices_withoutCoreServices_throwsError() async throws {
        // Act & Assert - Should fail because core services aren't registered
        do {
            try await DIBootstrapper.registerDataServices(in: container)
            XCTFail("Expected dependency resolution error")
        } catch {
            // Expected - data services depend on core services
            XCTAssertTrue(error is DIContainer.DIError)
        }
    }
    
    func test_registerAIServices_withoutCoreServices_throwsError() async throws {
        // Act & Assert - Should fail because core services aren't registered
        do {
            try await DIBootstrapper.registerAIServices(in: container)
            XCTFail("Expected dependency resolution error")
        } catch {
            // Expected - AI services depend on core services
            XCTAssertTrue(error is DIContainer.DIError)
        }
    }
    
    // MARK: - Service Integration Tests
    
    func test_allRegisteredServices_canBeResolved() async throws {
        // Act - Full registration
        try await DIBootstrapper.configure(container: container, environment: .production)
        
        // Assert - All services should be resolvable
        let services: [Any.Type] = [
            NetworkManagementProtocol.self,
            APIKeyManagementProtocol.self,
            AnalyticsServiceProtocol.self,
            UserServiceProtocol.self,
            GoalServiceProtocol.self,
            NutritionServiceProtocol.self,
            WorkoutServiceProtocol.self,
            HealthKitManagerProtocol.self,
            AIServiceProtocol.self,
            CoachEngineProtocol.self,
            FoodCoachEngineProtocol.self,
            NotificationManagerProtocol.self,
            WeatherServiceProtocol.self,
            FoodVoiceServiceProtocol.self,
            OnboardingServiceProtocol.self
        ]
        
        for serviceType in services {
            do {
                let service = try await container.resolve(serviceType)
                XCTAssertNotNil(service, "Failed to resolve \(serviceType)")
            } catch {
                XCTFail("Failed to resolve \(serviceType): \(error)")
            }
        }
    }
    
    // MARK: - Singleton Tests
    
    func test_singletonServices_returnSameInstance() async throws {
        // Arrange
        try await DIBootstrapper.configure(container: container, environment: .production)
        
        // Act - Resolve same service multiple times
        let apiKeyManager1 = try await container.resolve(APIKeyManagementProtocol.self)
        let apiKeyManager2 = try await container.resolve(APIKeyManagementProtocol.self)
        
        let analyticsService1 = try await container.resolve(AnalyticsServiceProtocol.self)
        let analyticsService2 = try await container.resolve(AnalyticsServiceProtocol.self)
        
        // Assert - Should be same instance for singletons
        XCTAssertTrue(apiKeyManager1 === apiKeyManager2)
        XCTAssertTrue(analyticsService1 === analyticsService2)
    }
    
    // MARK: - Test Helper Integration
    
    func test_testContainer_creation_usesTestEnvironment() async throws {
        // Act
        let testContainer = try await DITestHelper.createTestContainer()
        
        // Assert - Should have mock services
        let networkManager = try await testContainer.resolve(NetworkManagementProtocol.self)
        XCTAssertTrue(networkManager is MockNetworkManager)
        
        let healthKitManager = try await testContainer.resolve(HealthKitManagerProtocol.self)
        XCTAssertTrue(healthKitManager is MockHealthKitManager)
    }
    
    // MARK: - Error Handling Tests
    
    func test_multipleRegistration_ofSameProtocol_overridesPrevious() async throws {
        // Arrange
        try await container.register(NetworkManagementProtocol.self) { _ in
            NetworkManager()
        }
        
        // Act - Register again with mock
        try await container.register(NetworkManagementProtocol.self) { _ in
            MockNetworkManager()
        }
        
        // Assert - Should resolve to the latest registration
        let service = try await container.resolve(NetworkManagementProtocol.self)
        XCTAssertTrue(service is MockNetworkManager)
    }
}