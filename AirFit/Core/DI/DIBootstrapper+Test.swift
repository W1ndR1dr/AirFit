import Foundation
import SwiftData

// MARK: - Test Mode Support
extension DIBootstrapper {
    /// Create a container with test mode AI service for UI testing
    @MainActor
    public static func createMockContainer(modelContainer: ModelContainer) async throws -> DIContainer {
        // Start with the real container
        let container = try await createAppContainer(modelContainer: modelContainer)
        
        // Override just the AI service to use test mode
        container.register(AIServiceProtocol.self, lifetime: .singleton) { _ in
            TestModeAIService()
        }
        
        // Override API Key Manager to always return true for hasAPIKey
        container.register(APIKeyManagementProtocol.self, lifetime: .singleton) { _ in
            TestModeAPIKeyManager()
        }
        
        AppLogger.info("Mock DI container created for testing", category: .app)
        
        return container
    }
}

// MARK: - Test Mode API Key Manager
@MainActor
private final class TestModeAPIKeyManager: APIKeyManagementProtocol {
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {}
    
    func getAPIKey(for provider: AIProvider) async throws -> String {
        return "test-api-key-\(provider.rawValue)"
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {}
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        return true
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        return AIProvider.allCases
    }
}