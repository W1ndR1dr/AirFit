import Foundation
import SwiftData

public final class DependencyContainer: @unchecked Sendable {
    static let shared = DependencyContainer()

    // MARK: - Properties
    private(set) var modelContainer: ModelContainer?
    private(set) var networkClient: NetworkClientProtocol
    private(set) var keychain: KeychainWrapper
    private(set) var logger: AppLogger.Type
    private(set) var aiService: AIServiceProtocol?
    private(set) var userService: UserServiceProtocol?
    private(set) var apiKeyManager: APIKeyManagerProtocol?
    private(set) var notificationManager: NotificationManagerProtocol?

    // MARK: - Initialization
    init() {
        self.networkClient = NetworkClient.shared
        self.keychain = KeychainWrapper.shared
        self.logger = AppLogger.self
        
        // Initialize services that don't depend on ModelContext
        self.apiKeyManager = DefaultAPIKeyManager(keychain: keychain)
        self.notificationManager = DefaultNotificationManager()
    }

    // MARK: - Configuration
    func configure(with modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        
        // Initialize services that depend on ModelContext
        let modelContext = ModelContext(modelContainer)
        self.userService = DefaultUserService(modelContext: modelContext)
        
        // Configure AI service (using MockAIService until Module 10 provides real implementation)
        Task {
            self.aiService = await MockAIService()
        }
        
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

private struct DependencyContainerKey: EnvironmentKey, Sendable {
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
