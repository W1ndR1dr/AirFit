import XCTest
@testable import AirFit

final class DIContainerTests: XCTestCase {
    
    // MARK: - Basic Registration & Resolution
    
    func test_register_and_resolve_singleton() async throws {
        // Arrange
        let container = DIContainer()
        let counter = Counter()
        
        container.register(TestService.self, lifetime: .singleton) { _ in
            let id = await counter.increment()
            return TestService(id: id)
        }
        
        // Act
        let instance1 = try await container.resolve(TestService.self)
        let instance2 = try await container.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(instance1.id, instance2.id, "Singleton should return same instance")
        let count = await counter.current()
        XCTAssertEqual(count, 1, "Singleton should only create one instance")
    }
    
    func test_register_and_resolve_transient() async throws {
        // Arrange
        let container = DIContainer()
        let counter = Counter()
        
        container.register(TestService.self, lifetime: .transient) { _ in
            let id = await counter.increment()
            return TestService(id: id)
        }
        
        // Act
        let instance1 = try await container.resolve(TestService.self)
        let instance2 = try await container.resolve(TestService.self)
        
        // Assert
        XCTAssertNotEqual(instance1.id, instance2.id, "Transient should create new instances")
        let count = await counter.current()
        XCTAssertEqual(count, 2, "Transient should create instance each time")
    }
    
    func test_registerSingleton_instance() async throws {
        // Arrange
        let container = DIContainer()
        let testService = TestService(id: 42)
        
        // Act
        container.registerSingleton(TestService.self, instance: testService)
        let resolved = try await container.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(resolved.id, 42)
        XCTAssertTrue(resolved === testService, "Should return exact same instance")
    }
    
    // MARK: - Named Registration
    
    func test_named_registration() async throws {
        // Arrange
        let container = DIContainer()
        
        container.register(TestService.self, name: "primary", lifetime: .singleton) { _ in
            TestService(id: 1)
        }
        
        container.register(TestService.self, name: "secondary", lifetime: .singleton) { _ in
            TestService(id: 2)
        }
        
        // Act
        let primary = try await container.resolve(TestService.self, name: "primary")
        let secondary = try await container.resolve(TestService.self, name: "secondary")
        
        // Assert
        XCTAssertEqual(primary.id, 1)
        XCTAssertEqual(secondary.id, 2)
    }
    
    // MARK: - Dependency Chain
    
    func test_dependency_chain_resolution() async throws {
        // Arrange
        let container = DIContainer()
        
        container.register(TestService.self, lifetime: .singleton) { _ in
            TestService(id: 100)
        }
        
        container.register(ComplexService.self, lifetime: .transient) { container in
            let dependency = try await container.resolve(TestService.self)
            return ComplexService(dependency: dependency)
        }
        
        // Act
        let complexService = try await container.resolve(ComplexService.self)
        
        // Assert
        XCTAssertEqual(complexService.dependency.id, 100)
    }
    
    // MARK: - Error Handling
    
    func test_resolve_unregistered_throws_error() async {
        // Arrange
        let container = DIContainer()
        
        // Act & Assert
        do {
            _ = try await container.resolve(TestService.self)
            XCTFail("Should throw error for unregistered type")
        } catch DIError.notRegistered {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Scoped Dependencies
    
    func test_scoped_dependencies() async throws {
        // Arrange
        let container = DIContainer()
        let counter = Counter()
        
        container.register(TestService.self, lifetime: .scoped) { _ in
            let id = await counter.increment()
            return TestService(id: id)
        }
        
        // Act - Same scope
        let scope1 = container.createScope()
        let instance1 = try await scope1.resolve(TestService.self)
        let instance2 = try await scope1.resolve(TestService.self)
        
        // Act - Different scope
        let scope2 = container.createScope()
        let instance3 = try await scope2.resolve(TestService.self)
        let instance4 = try await scope2.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(instance1.id, instance2.id, "Same scope should return same instance")
        XCTAssertEqual(instance3.id, instance4.id, "Same scope should return same instance")
        XCTAssertNotEqual(instance1.id, instance3.id, "Different scopes should have different instances")
        let count = await counter.current()
        XCTAssertEqual(count, 2, "Should create one instance per scope")
    }
    
    // MARK: - Parent Container
    
    func test_child_container_inherits_registrations() async throws {
        // Arrange
        let parent = DIContainer()
        parent.register(TestService.self, lifetime: .singleton) { _ in
            TestService(id: 999)
        }
        
        let child = parent.createScope()
        
        // Act
        let fromChild = try await child.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(fromChild.id, 999, "Child should resolve from parent")
    }
    
    func test_child_can_override_parent_registration() async throws {
        // Arrange
        let parent = DIContainer()
        parent.register(TestService.self, lifetime: .singleton) { _ in
            TestService(id: 1)
        }
        
        let child = parent.createScope()
        child.register(TestService.self, lifetime: .singleton) { _ in
            TestService(id: 2)
        }
        
        // Act
        let fromParent = try await parent.resolve(TestService.self)
        let fromChild = try await child.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(fromParent.id, 1)
        XCTAssertEqual(fromChild.id, 2)
    }
    
    // MARK: - Real World Example
    
    func test_real_world_service_registration() async throws {
        // Arrange
        let container = DIContainer()
        
        // Register mock services
        container.register(HealthKitManaging.self, lifetime: .singleton) { _ in
            MockHealthKitManager()
        }
        
        container.register(WeatherServiceProtocol.self, lifetime: .singleton) { _ in
            MockWeatherService()
        }
        
        container.register(AIServiceProtocol.self, lifetime: .singleton) { _ in
            MockAIService()
        }
        
        // Act - Resolve services
        let healthKit = try await container.resolve(HealthKitManaging.self)
        let weather = try await container.resolve(WeatherServiceProtocol.self)
        let ai = try await container.resolve(AIServiceProtocol.self)
        
        // Assert
        XCTAssertTrue(healthKit is MockHealthKitManager)
        XCTAssertTrue(weather is MockWeatherService)
        XCTAssertTrue(ai is MockAIService)
    }
    
    // MARK: - Thread Safety
    
    func test_concurrent_resolution_is_thread_safe() async throws {
        // Arrange
        let container = DIContainer()
        let counter = Counter()
        
        container.register(TestService.self, lifetime: .singleton) { _ in
            let id = await counter.increment()
            return TestService(id: id)
        }
        
        // Act - Concurrent resolution
        async let task1 = container.resolve(TestService.self)
        async let task2 = container.resolve(TestService.self)
        async let task3 = container.resolve(TestService.self)
        
        let results = try await [task1, task2, task3]
        
        // Assert
        let count = await counter.current()
        XCTAssertEqual(count, 1, "Singleton should only be created once even with concurrent access")
        XCTAssertEqual(results[0].id, results[1].id)
        XCTAssertEqual(results[1].id, results[2].id)
    }
}

// MARK: - Test Helpers

private actor Counter {
    private var value = 0
    
    func increment() -> Int {
        value += 1
        return value
    }
    
    func current() -> Int {
        return value
    }
}

private final class TestService: Sendable {
    let id: Int
    init(id: Int) {
        self.id = id
    }
}

private struct AnotherService: Sendable {
    let name: String
}

private final class ComplexService: Sendable {
    let dependency: TestService
    init(dependency: TestService) {
        self.dependency = dependency
    }
}
