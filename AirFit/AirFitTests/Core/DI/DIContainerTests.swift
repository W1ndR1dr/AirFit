import XCTest
@testable import AirFit

@MainActor
final class DIContainerTests: XCTestCase {
    
    // MARK: - Basic Registration & Resolution
    
    func test_register_and_resolve_singleton() async throws {
        // Arrange
        let container = DIContainer()
        var instanceCount = 0
        
        container.register(TestService.self, scope: .singleton) {
            instanceCount += 1
            return TestService(id: instanceCount)
        }
        
        // Act
        let instance1 = try await container.resolve(TestService.self)
        let instance2 = try await container.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(instance1.id, instance2.id, "Singleton should return same instance")
        XCTAssertEqual(instanceCount, 1, "Singleton should only create one instance")
    }
    
    func test_register_and_resolve_transient() async throws {
        // Arrange
        let container = DIContainer()
        var instanceCount = 0
        
        container.register(TestService.self, scope: .transient) {
            instanceCount += 1
            return TestService(id: instanceCount)
        }
        
        // Act
        let instance1 = try await container.resolve(TestService.self)
        let instance2 = try await container.resolve(TestService.self)
        
        // Assert
        XCTAssertNotEqual(instance1.id, instance2.id, "Transient should create new instances")
        XCTAssertEqual(instanceCount, 2, "Transient should create instance per resolution")
    }
    
    func test_register_instance() async throws {
        // Arrange
        let container = DIContainer()
        let service = TestService(id: 42)
        
        // Act
        container.registerInstance(service, for: TestService.self)
        let resolved = try await container.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(resolved.id, 42)
        XCTAssertTrue(resolved === service, "Should return exact same instance")
    }
    
    // MARK: - Named Registration
    
    func test_named_registration() async throws {
        // Arrange
        let container = DIContainer()
        
        container.register(TestService.self, name: "primary") {
            TestService(id: 1)
        }
        
        container.register(TestService.self, name: "secondary") {
            TestService(id: 2)
        }
        
        // Act
        let primary = try await container.resolve(TestService.self, name: "primary")
        let secondary = try await container.resolve(TestService.self, name: "secondary")
        
        // Assert
        XCTAssertEqual(primary.id, 1)
        XCTAssertEqual(secondary.id, 2)
    }
    
    // MARK: - Hierarchical Resolution
    
    func test_parent_container_resolution() async throws {
        // Arrange
        let parent = DIContainer()
        parent.register(TestService.self) {
            TestService(id: 1)
        }
        
        let child = DIContainer(parent: parent)
        child.register(AnotherService.self) {
            AnotherService(name: "child")
        }
        
        // Act & Assert
        // Child can resolve from parent
        let serviceFromParent = try await child.resolve(TestService.self)
        XCTAssertEqual(serviceFromParent.id, 1)
        
        // Parent cannot resolve from child
        let anotherService = await parent.resolveOptional(AnotherService.self)
        XCTAssertNil(anotherService)
    }
    
    func test_child_overrides_parent() async throws {
        // Arrange
        let parent = DIContainer()
        parent.register(TestService.self) {
            TestService(id: 1)
        }
        
        let child = DIContainer(parent: parent)
        child.register(TestService.self) {
            TestService(id: 2)
        }
        
        // Act
        let parentService = try await parent.resolve(TestService.self)
        let childService = try await child.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(parentService.id, 1)
        XCTAssertEqual(childService.id, 2, "Child should override parent registration")
    }
    
    // MARK: - Provider Pattern
    
    func test_provider_with_dependencies() async throws {
        // Arrange
        let container = DIContainer()
        
        container.register(TestService.self) {
            TestService(id: 100)
        }
        
        container.registerProvider(ComplexService.self) { container in
            let testService = try await container.resolve(TestService.self)
            return ComplexService(dependency: testService)
        }
        
        // Act
        let complex = try await container.resolve(ComplexService.self)
        
        // Assert
        XCTAssertEqual(complex.dependency.id, 100)
    }
    
    // MARK: - Error Handling
    
    func test_resolve_unregistered_throws() async {
        // Arrange
        let container = DIContainer()
        
        // Act & Assert
        do {
            _ = try await container.resolve(TestService.self)
            XCTFail("Should throw for unregistered service")
        } catch {
            XCTAssertTrue(error is DIError)
        }
    }
    
    func test_resolve_optional_returns_nil() async {
        // Arrange
        let container = DIContainer()
        
        // Act
        let service = await container.resolveOptional(TestService.self)
        
        // Assert
        XCTAssertNil(service)
    }
    
    func test_resolve_with_default() async {
        // Arrange
        let container = DIContainer()
        let defaultService = TestService(id: 999)
        
        // Act
        let service = await container.resolve(TestService.self, default: defaultService)
        
        // Assert
        XCTAssertEqual(service.id, 999)
    }
    
    // MARK: - Scope Management
    
    func test_scoped_lifetime() async throws {
        // Arrange
        let container = DIContainer()
        var instanceCount = 0
        
        container.register(TestService.self, scope: .scoped) {
            instanceCount += 1
            return TestService(id: instanceCount)
        }
        
        // Act - First scope
        let scope1 = container.createScope()
        let instance1a = try await scope1.resolve(TestService.self)
        let instance1b = try await scope1.resolve(TestService.self)
        
        // Act - Second scope
        let scope2 = container.createScope()
        let instance2a = try await scope2.resolve(TestService.self)
        let instance2b = try await scope2.resolve(TestService.self)
        
        // Assert
        XCTAssertEqual(instance1a.id, instance1b.id, "Same instance within scope")
        XCTAssertEqual(instance2a.id, instance2b.id, "Same instance within scope")
        XCTAssertNotEqual(instance1a.id, instance2a.id, "Different instances across scopes")
    }
    
    func test_clear_scoped() async throws {
        // Arrange
        let container = DIContainer()
        var instanceCount = 0
        
        container.register(TestService.self, scope: .scoped) {
            instanceCount += 1
            return TestService(id: instanceCount)
        }
        
        // Act
        let instance1 = try await container.resolve(TestService.self)
        container.clearScoped()
        let instance2 = try await container.resolve(TestService.self)
        
        // Assert
        XCTAssertNotEqual(instance1.id, instance2.id, "Should create new instance after clear")
    }
    
    // MARK: - Real World Example
    
    func test_real_world_dashboard_creation() async throws {
        // Arrange
        let container = await DIBootstrapper.createTestContainer()
        
        // Override specific service for this test
        container.register(HealthKitManagerProtocol.self) {
            let mock = MockHealthKitManager()
            mock.mockSteps = 12345
            mock.mockCalories = 500
            return mock
        }
        
        // Act
        let factory = DIViewModelFactory(container: container)
        let user = User()
        
        // This would normally crash with singletons, but works fine with DI
        let viewModel = try await factory.makeDashboardViewModel(user: user)
        
        // Assert
        XCTAssertNotNil(viewModel)
        // In a real test, we'd verify the ViewModel uses our mock data
    }
    
    // MARK: - Performance
    
    func test_performance_singleton_resolution() async throws {
        // Arrange
        let container = DIContainer()
        container.register(TestService.self) {
            TestService(id: 1)
        }
        
        // Warm up
        _ = try await container.resolve(TestService.self)
        
        // Act & Assert
        measure {
            Task { @MainActor in
                for _ in 0..<1000 {
                    _ = try? await container.resolve(TestService.self)
                }
            }
        }
    }
}

// MARK: - Test Helpers

private class TestService {
    let id: Int
    init(id: Int) {
        self.id = id
    }
}

private struct AnotherService {
    let name: String
}

private class ComplexService {
    let dependency: TestService
    init(dependency: TestService) {
        self.dependency = dependency
    }
}