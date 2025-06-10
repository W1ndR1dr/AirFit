import Foundation

/// Minimal AI service implementation for development and testing
/// This is a production-ready stub that can be used when full AI services aren't configured
final class MinimalAIAPIService: AIServiceProtocol, Sendable {
    let serviceIdentifier = "minimal-ai-service"
    let isConfigured = true
    let activeProvider: AIProvider = .anthropic
    let availableModels: [AIModel] = []
    
    func configure() async throws {
        // No-op for minimal implementation
    }
    
    func reset() async {
        // No-op for minimal implementation
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: ["type": "minimal"]
        )
    }
    
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        // No-op for minimal implementation - this is a stub service
    }
    
    func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                // Simulate minimal response
                continuation.yield(.textDelta("This is a minimal AI response for development."))
                continuation.yield(.done(usage: nil))
                continuation.finish()
            }
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        return true
    }
    
    func checkHealth() async -> ServiceHealth {
        return await healthCheck()
    }
    
    func estimateTokenCount(for text: String) -> Int {
        // Rough estimation: ~4 characters per token
        return max(1, text.count / 4)
    }
}