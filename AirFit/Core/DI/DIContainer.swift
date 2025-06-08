import Foundation
import SwiftUI

/// Modern dependency injection container for AirFit
/// Provides a clean, testable alternative to singletons
public final class DIContainer: @unchecked Sendable {
    /// Shared instance for app initialization
    /// Note: This is only used during app startup to avoid SwiftUI environment timing issues
    nonisolated(unsafe) public static var shared: DIContainer?
    /// Lifetime of a registered dependency
    public enum Lifetime {
        case singleton  // Created once, shared across app
        case transient  // New instance each time
        case scoped     // Shared within a scope (e.g., per-screen)
    }
    
    // MARK: - Private Properties
    
    private var registrations: [ObjectIdentifier: Registration] = [:]
    private var singletonInstances: [ObjectIdentifier: Any] = [:]
    private var scopedInstances: [ObjectIdentifier: Any] = [:]
    private let parent: DIContainer?
    
    // MARK: - Initialization
    
    public init(parent: DIContainer? = nil) {
        self.parent = parent
    }
    
    // MARK: - Registration
    
    /// Register a factory for a service type
    public func register<T>(
        _ type: T.Type,
        name: String? = nil,
        lifetime: Lifetime = .transient,
        factory: @escaping @Sendable (DIContainer) async throws -> T
    ) {
        let key = makeKey(type: type, name: name)
        registrations[key] = Registration(
            lifetime: lifetime,
            factory: { container in try await factory(container) }
        )
    }
    
    /// Register a singleton instance directly
    public func registerSingleton<T: Sendable>(
        _ type: T.Type,
        name: String? = nil,
        instance: T
    ) {
        let key = makeKey(type: type, name: name)
        registrations[key] = Registration(lifetime: .singleton, factory: { _ in instance })
        singletonInstances[key] = instance
        
        // Debug logging for ModelContainer
        if String(describing: type).contains("ModelContainer") {
            AppLogger.info("DI: Registered \(type) with key: \(key)", category: .app)
        }
    }
    
    // MARK: - Resolution
    
    /// Resolve a dependency
    public func resolve<T>(_ type: T.Type, name: String? = nil) async throws -> T {
        let key = makeKey(type: type, name: name)
        
        // Debug logging for ModelContainer
        if String(describing: type).contains("ModelContainer") {
            AppLogger.info("DI: Resolving ModelContainer", category: .app)
            AppLogger.info("DI: Key: \(key)", category: .app)
            AppLogger.info("DI: Registrations count: \(registrations.count)", category: .app)
            AppLogger.info("DI: Has registration: \(registrations[key] != nil)", category: .app)
        }
        
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
        
        // Create new instance
        let instance = try await registration.factory(self)
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
    
    /// Create a child container for scoped dependencies
    public func createScope() -> DIContainer {
        return DIContainer(parent: self)
    }
    
    // MARK: - Private Methods
    
    private func makeKey(type: Any.Type, name: String?) -> ObjectIdentifier {
        if let name = name {
            // Combine type and name for unique key
            return ObjectIdentifier(type: type, name: name)
        }
        return ObjectIdentifier(type)
    }
    
    private func findRegistration(for key: ObjectIdentifier) -> Registration? {
        registrations[key] ?? parent?.findRegistration(for: key)
    }
}

// MARK: - Supporting Types

private struct Registration {
    let lifetime: DIContainer.Lifetime
    let factory: @Sendable (DIContainer) async throws -> Any
}

private extension ObjectIdentifier {
    init(type: Any.Type, name: String) {
        // Create a unique identifier combining type and name
        let combined = "\(type)-\(name)"
        self.init(combined as AnyObject)
    }
}

// MARK: - Errors

public enum DIError: LocalizedError {
    case notRegistered(String)
    case invalidType(String)
    case resolutionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .notRegistered(let type):
            return "No registration found for type: \(type)"
        case .invalidType(let type):
            return "Could not cast resolved instance to type: \(type)"
        case .resolutionFailed(let reason):
            return "Failed to resolve dependency: \(reason)"
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

// MARK: - Property Wrapper for SwiftUI

@propertyWrapper
@MainActor
public struct DIInjected<T: Sendable> {
    @Environment(\.diContainer) private var container
    private let type: T.Type
    private let name: String?
    
    public init(_ type: T.Type, name: String? = nil) {
        self.type = type
        self.name = name
    }
    
    public var wrappedValue: T {
        get {
            // This is a synchronous wrapper
            // In practice, dependencies should be pre-resolved at view creation
            synchronousResolve {
                try await container.resolve(type, name: name)
            }
        }
    }
}

// Helper for synchronous resolution (use sparingly)
@MainActor
fileprivate func synchronousResolve<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) -> T {
    let semaphore = DispatchSemaphore(value: 0)
    var result: Result<T, Error>!
    
    Task.detached {
        do {
            let value = try await operation()
            result = .success(value)
        } catch {
            result = .failure(error)
        }
        semaphore.signal()
    }
    
    semaphore.wait()
    
    switch result! {
    case .success(let value):
        return value
    case .failure(let error):
        fatalError("Synchronous resolution failed: \(error)")
    }
}