import SwiftUI

/// Modern dependency injection container for AirFit
/// Provides a clean, testable alternative to singletons
public final class DIContainer: @unchecked Sendable {
    /// Lifetime of a registered dependency
    public enum Lifetime {
        case singleton  // Created once, shared across app
        case transient  // New instance each time
        case scoped     // Shared within a scope (e.g., per-screen)
    }

    // MARK: - Private Properties

    private var registrations: [String: Registration] = [:]
    private var singletonInstances: [String: Any] = [:]
    private var scopedInstances: [String: Any] = [:]
    private let parent: DIContainer?

    // MARK: - Initialization

    public init(parent: DIContainer? = nil) {
        self.parent = parent
    }

    // MARK: - Registration

    /// Register a factory for a service type (must be Sendable for concurrent creation)
    public func register<T: Sendable>(
        _ type: T.Type,
        name: String? = nil,
        lifetime: Lifetime = .transient,
        factory: @escaping @Sendable (DIContainer) async throws -> T
    ) {
        let key = makeKey(type: type, name: name)
        let erasedFactory: @Sendable (DIContainer) async throws -> any Sendable = { container in
            try await factory(container)
        }
        registrations[key] = Registration(
            lifetime: lifetime,
            factory: .concurrent(erasedFactory)
        )
    }
    
    /// Register a @MainActor factory for UI-bound types
    public func registerMainActor<T>(
        _ type: T.Type,
        name: String? = nil,
        lifetime: Lifetime = .transient,
        factory: @escaping @MainActor @Sendable (DIContainer) async throws -> T
    ) {
        let key = makeKey(type: type, name: name)
        registrations[key] = Registration(
            lifetime: lifetime,
            factory: .mainActor({ container in try await factory(container) })
        )
    }

    /// Register a singleton instance directly
    public func registerSingleton<T: Sendable>(
        _ type: T.Type,
        name: String? = nil,
        instance: T
    ) {
        let key = makeKey(type: type, name: name)
        let erasedFactory: @Sendable (DIContainer) async throws -> any Sendable = { _ in instance }
        registrations[key] = Registration(lifetime: .singleton, factory: .concurrent(erasedFactory))
        singletonInstances[key] = instance

        // Debug logging
        AppLogger.info("DI: Registered \(String(describing: type)) with key: \(key)", category: .app)
    }

    // MARK: - Resolution

    /// Resolve a dependency
    public func resolve<T>(_ type: T.Type, name: String? = nil) async throws -> T {
        let key = makeKey(type: type, name: name)

        // Debug logging
        AppLogger.info("DI: Resolving \(String(describing: type)) with key: \(key)", category: .app)

        // Check if we have a registration
        guard let registration = findRegistration(for: key) else {
            throw DIError.notRegistered(String(describing: type))
        }

        // Return existing instance if available
        switch registration.lifetime {
        case .singleton:
            if let instance = singletonInstances[key] as? T {
                return instance
            }
        case .scoped:
            if let instance = scopedInstances[key] as? T {
                return instance
            }
        case .transient:
            break
        }

        // Create new instance based on factory type
        let instance: Any
        switch registration.factory {
        case .concurrent(let factory):
            let sendable = try await factory(self)
            instance = sendable  // Convert any Sendable to Any
        case .mainActor:
            // Cannot call @MainActor factory from non-MainActor context
            throw DIError.resolutionFailed("Cannot resolve @MainActor service from non-MainActor context. Use resolveOnMain() instead.")
        }
        guard let typedInstance = instance as? T else {
            throw DIError.invalidType(String(describing: type))
        }

        // Store if needed
        switch registration.lifetime {
        case .singleton:
            singletonInstances[key] = typedInstance
        case .scoped:
            scopedInstances[key] = typedInstance
        case .transient:
            break
        }

        return typedInstance
    }
    
    /// Resolve a @MainActor dependency - must be called from @MainActor context
    @MainActor
    public func resolveOnMain<T>(_ type: T.Type, name: String? = nil) async throws -> T {
        let key = makeKey(type: type, name: name)
        
        // Debug logging
        AppLogger.info("DI: Resolving \(String(describing: type)) with key: \(key) on MainActor", category: .app)
        
        // Check if we have a registration
        guard let registration = findRegistration(for: key) else {
            throw DIError.notRegistered(String(describing: type))
        }
        
        // Return existing instance if available
        switch registration.lifetime {
        case .singleton:
            if let instance = singletonInstances[key] as? T {
                return instance
            }
        case .scoped:
            if let instance = scopedInstances[key] as? T {
                return instance
            }
        case .transient:
            break
        }
        
        // Create new instance based on factory type
        let instance: Any
        switch registration.factory {
        case .concurrent(let factory):
            let sendable = try await factory(self)
            instance = sendable  // Convert any Sendable to Any
        case .mainActor(let factory):
            // Safe to call from @MainActor context
            instance = try await factory(self)
        }
        guard let typedInstance = instance as? T else {
            throw DIError.invalidType(String(describing: type))
        }
        
        // Store if needed
        switch registration.lifetime {
        case .singleton:
            singletonInstances[key] = typedInstance
        case .scoped:
            scopedInstances[key] = typedInstance
        case .transient:
            break
        }
        
        return typedInstance
    }
    
    /// Synchronously resolve a dependency - only works for already-created singletons
    /// This is useful for UI components that need immediate access to services
    public func resolveSync<T>(_ type: T.Type, name: String? = nil) throws -> T {
        let key = makeKey(type: type, name: name)
        
        // Check if we have a registration
        guard let registration = findRegistration(for: key) else {
            throw DIError.notRegistered(String(describing: type))
        }
        
        // Only return existing singleton instances
        switch registration.lifetime {
        case .singleton:
            if let instance = singletonInstances[key] as? T {
                return instance
            }
            throw DIError.resolutionFailed("Singleton not yet created for \(String(describing: type))")
        case .scoped:
            if let instance = scopedInstances[key] as? T {
                return instance
            }
            throw DIError.resolutionFailed("Scoped instance not yet created for \(String(describing: type))")
        case .transient:
            throw DIError.resolutionFailed("Cannot synchronously resolve transient dependencies for \(String(describing: type))")
        }
    }

    /// Create a child container for scoped dependencies
    public func createScope() -> DIContainer {
        return DIContainer(parent: self)
    }

    // MARK: - Private Methods

    private func makeKey(type: Any.Type, name: String?) -> String {
        let typeKey = String(describing: type)
        if let name = name {
            // Combine type and name for unique key
            return "\(typeKey)-\(name)"
        }
        return typeKey
    }

    private func findRegistration(for key: String) -> Registration? {
        registrations[key] ?? parent?.findRegistration(for: key)
    }
}

// MARK: - Supporting Types

private enum Factory {
    case concurrent(@Sendable (DIContainer) async throws -> any Sendable)
    case mainActor(@MainActor @Sendable (DIContainer) async throws -> Any)
}

private struct Registration {
    let lifetime: DIContainer.Lifetime
    let factory: Factory
}

// MARK: - Errors

public enum DIError: LocalizedError {
    case notRegistered(String)
    case invalidType(String)
    case resolutionFailed(String)
    case registrationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notRegistered(let type):
            return "No registration found for type: \(type)"
        case .invalidType(let type):
            return "Could not cast resolved instance to type: \(type)"
        case .resolutionFailed(let reason):
            return "Failed to resolve dependency: \(reason)"
        case .registrationFailed(let reason):
            return "Failed to register service: \(reason)"
        }
    }
}

// MARK: - SwiftUI Environment Integration

private struct DIContainerEnvironmentKey: EnvironmentKey {
    static let defaultValue = DIContainer()
}

public extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerEnvironmentKey.self] }
        set { self[DIContainerEnvironmentKey.self] = newValue }
    }
}

public extension View {
    /// Inject the DI container into the SwiftUI environment
    func withDIContainer(_ container: DIContainer) -> some View {
        environment(\.diContainer, container)
    }
}
