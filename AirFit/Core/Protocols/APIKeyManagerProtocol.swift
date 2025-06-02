import Foundation

/// Abstraction for secure API key storage.
protocol APIKeyManagerProtocol {
    // Legacy synchronous methods
    func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws
    func getAPIKey(forProvider provider: AIProvider) -> String?
    func deleteAPIKey(forProvider provider: AIProvider) throws
    
    // Modern async methods using string-based provider identification
    func getAPIKey(for provider: String) async -> String?
    func saveAPIKey(_ apiKey: String, for provider: String) async throws
    func deleteAPIKey(for provider: String) async throws
}
