import Foundation

// MARK: - API Key Management Protocol
/// Unified protocol for secure API key storage and retrieval
protocol APIKeyManagementProtocol: AnyObject, Sendable {
    /// Save an API key for a provider
    func saveAPIKey(
        _ key: String,
        for provider: AIProvider
    ) async throws

    /// Get an API key for a provider (throws if not found)
    func getAPIKey(
        for provider: AIProvider
    ) async throws -> String

    /// Delete an API key for a provider
    func deleteAPIKey(
        for provider: AIProvider
    ) async throws

    /// Check if an API key exists for a provider
    func hasAPIKey(
        for provider: AIProvider
    ) async -> Bool

    /// Get all providers that have API keys configured
    func getAllConfiguredProviders() async -> [AIProvider]
}
