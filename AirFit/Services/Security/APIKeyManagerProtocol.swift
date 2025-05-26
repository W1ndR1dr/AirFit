import Foundation

/// Abstraction for secure API key storage.
protocol APIKeyManagerProtocol {
    func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws
    func getAPIKey(forProvider provider: AIProvider) -> String?
    func deleteAPIKey(forProvider provider: AIProvider) throws
}
