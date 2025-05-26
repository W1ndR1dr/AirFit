import Foundation
import SwiftData

@MainActor
public final class DependencyContainer {
    static let shared = DependencyContainer()

    // MARK: - Properties
    private(set) var modelContainer: ModelContainer?
    private(set) var networkClient: NetworkClientProtocol
    private(set) var keychain: KeychainWrapper
    private(set) var logger: AppLogger.Type

    // MARK: - Initialization
    private init() {
        self.networkClient = NetworkClient.shared
        self.keychain = KeychainWrapper.shared
        self.logger = AppLogger.self
    }

    // MARK: - Configuration
    func configure(with modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        AppLogger.info("Dependency container configured", category: .app)
    }

    // MARK: - Factory Methods
    func makeModelContext() -> ModelContext? {
        guard let container = modelContainer else {
            AppLogger.error("ModelContainer not configured", category: .app)
            return nil
        }
        return ModelContext(container)
    }

    // MARK: - Service Registration (for testing)
    func register<T>(service: T, for type: T.Type) {
        // This would be expanded for full DI
        // For now, it's a placeholder for test injection
        AppLogger.debug("Registered service: \(type)", category: .app)
    }
}

// MARK: - Environment Values
import SwiftUI

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    func withDependencies(_ container: DependencyContainer = .shared) -> some View {
        environment(\.dependencies, container)
    }
}
