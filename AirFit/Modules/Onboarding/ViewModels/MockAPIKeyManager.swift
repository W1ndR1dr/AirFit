import Foundation

/// Mock API Key Manager for previews and testing
actor MockAPIKeyManager: APIKeyManagementProtocol {
    private var keys: [AIProvider: String] = [:]
    
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        keys[provider] = key
    }
    
    func getAPIKey(for provider: AIProvider) async throws -> String {
        guard let key = keys[provider] else {
            throw AppError.authentication("API key not found for \(provider.rawValue)")
        }
        return key
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        keys.removeValue(forKey: provider)
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        return keys[provider] != nil
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        return Array(keys.keys)
    }
}
