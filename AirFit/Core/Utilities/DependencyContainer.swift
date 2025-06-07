import Foundation
import SwiftData

/// Legacy dependency container
/// - Warning: DEPRECATED - Use DIContainer instead. This class is only kept for Onboarding module compatibility.
/// - SeeAlso: DIContainer, DIBootstrapper, DIViewModelFactory
@available(*, deprecated, message: "Use DIContainer instead of DependencyContainer")
public final class DependencyContainer: @unchecked Sendable {
    static let shared = DependencyContainer()

    // MARK: - Properties
    private(set) var modelContainer: ModelContainer?
    private(set) var networkClient: NetworkClientProtocol
    private(set) var keychain: KeychainWrapper
    private(set) var logger: AppLogger.Type
    private(set) var aiService: AIServiceProtocol?
    private(set) var userService: UserServiceProtocol?
    private(set) var apiKeyManager: APIKeyManagementProtocol?
    private(set) var notificationManager: NotificationManager?

    // MARK: - Initialization
    init() {
        self.networkClient = NetworkClient.shared
        self.keychain = KeychainWrapper.shared
        self.logger = AppLogger.self
        
        // Initialize services that don't depend on ModelContext
        Task { @MainActor in
            self.apiKeyManager = APIKeyManager(keychain: keychain)
            self.notificationManager = NotificationManager.shared
        }
    }

    // MARK: - Configuration
    func configure(with modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        
        // Initialize services that depend on ModelContext
        let modelContext = ModelContext(modelContainer)
        
        // Set offline AI service immediately as fallback
        Task { @MainActor in
            if self.aiService == nil {
                self.aiService = await OfflineAIService()
            }
        }
        Task { @MainActor in
            self.userService = UserService(modelContext: modelContext)
        }
        
        // Configure AI service with AIService
        Task { @MainActor in
            if let keyManager = self.apiKeyManager {
                // Safe cast with fallback
                guard let apiKeyManagement = keyManager as? APIKeyManagementProtocol else {
                    AppLogger.error("API key manager doesn't conform to required protocol", category: .app)
                    self.aiService = await OfflineAIService()
                    return
                }
                
                // Create and configure the production AI service
                let orchestrator = await MainActor.run {
                    LLMOrchestrator(apiKeyManager: apiKeyManagement)
                }
                let productionService = await AIService(llmOrchestrator: orchestrator)
                
                // Try to configure the service
                do {
                    try await productionService.configure()
                    self.aiService = productionService
                    AppLogger.info("Production AI service configured successfully", category: .app)
                } catch {
                    AppLogger.warning("Failed to configure production AI service: \(error). Using offline service.", category: .app)
                    self.aiService = await OfflineAIService()
                }
            } else {
                AppLogger.warning("No API key manager available, using offline AI service", category: .app)
                self.aiService = await OfflineAIService()
            }
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
