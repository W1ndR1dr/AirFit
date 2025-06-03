import Foundation

// MARK: - API Key Management Protocol
protocol APIKeyManagementProtocol: AnyObject, Sendable {
    func saveAPIKey(
        _ key: String,
        for provider: AIProvider
    ) async throws
    
    func getAPIKey(
        for provider: AIProvider
    ) async throws -> String
    
    func deleteAPIKey(
        for provider: AIProvider
    ) async throws
    
    func hasAPIKey(
        for provider: AIProvider
    ) async -> Bool
    
    func getAllConfiguredProviders() async -> [AIProvider]
}