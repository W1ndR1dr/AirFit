import Foundation

/// Fallback AI service that returns errors when no providers are configured
/// Prevents crashes and provides clear error feedback to users
actor OfflineAIService: AIServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated var isConfigured: Bool { false }
    nonisolated var serviceIdentifier: String { "offline_ai_service" }
    
    func configure() async throws {
        throw AIError.unauthorized
    }
    
    func reset() async {
        // No-op for offline service
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: "No AI provider configured",
            metadata: [:]
        )
    }
    
    // MARK: - AIServiceProtocol
    nonisolated var activeProvider: AIProvider { .openAI }  // Default, not actually used
    nonisolated var availableModels: [AIModel] { [] }
    
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        throw AIError.unauthorized
    }
    
    nonisolated func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.error(AIError.unauthorized))
            continuation.finish()
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        false
    }
    
    func checkHealth() async -> ServiceHealth {
        await healthCheck()
    }
    
    nonisolated func estimateTokenCount(for text: String) -> Int {
        // Rough estimate: ~4 characters per token
        text.count / 4
    }
    
    // MARK: - Additional convenience methods
    func sendMessage(_ message: String, withContext context: [String: Any]?) async throws -> String {
        throw AIError.unauthorized
    }
    
    func streamMessage(_ message: String, withContext context: [String: Any]?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: AIError.unauthorized)
        }
    }
    
    func generateStructuredResponse<T: Decodable>(_ prompt: String, responseType: T.Type, withContext context: [String: Any]?) async throws -> T {
        throw AIError.unauthorized
    }
}