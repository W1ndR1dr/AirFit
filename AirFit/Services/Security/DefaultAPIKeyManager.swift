import Foundation

/// Default implementation of APIKeyManagerProtocol using Keychain
final class DefaultAPIKeyManager: APIKeyManagerProtocol, APIKeyManagementProtocol {
    private let keychain: KeychainWrapper
    private let keychainPrefix = "com.airfit.apikey."
    
    init(keychain: KeychainWrapper = .shared) {
        self.keychain = keychain
    }
    
    // MARK: - Legacy Synchronous Methods
    
    func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws {
        let key = keychainKey(for: provider.rawValue)
        try keychain.set(apiKey, forKey: key)
        
        AppLogger.info("Saved API key for provider: \(provider.rawValue)", category: .security)
    }
    
    func getAPIKey(forProvider provider: AIProvider) -> String? {
        let key = keychainKey(for: provider.rawValue)
        
        do {
            let apiKey = try keychain.get(forKey: key)
            return apiKey
        } catch {
            AppLogger.error("Failed to get API key for provider: \(provider.rawValue)", error: error, category: .security)
            return nil
        }
    }
    
    func deleteAPIKey(forProvider provider: AIProvider) throws {
        let key = keychainKey(for: provider.rawValue)
        try keychain.delete(forKey: key)
        
        AppLogger.info("Deleted API key for provider: \(provider.rawValue)", category: .security)
    }
    
    // MARK: - Modern Async Methods
    
    func getAPIKey(for provider: String) async -> String? {
        let key = keychainKey(for: provider)
        
        do {
            let apiKey = try keychain.get(forKey: key)
            return apiKey
        } catch {
            AppLogger.error("Failed to get API key for provider: \(provider)", error: error, category: .security)
            return nil
        }
    }
    
    func saveAPIKey(_ apiKey: String, for provider: String) async throws {
        let key = keychainKey(for: provider)
        try keychain.set(apiKey, forKey: key)
        
        AppLogger.info("Saved API key for provider: \(provider)", category: .security)
    }
    
    func deleteAPIKey(for provider: String) async throws {
        let key = keychainKey(for: provider)
        try keychain.delete(forKey: key)
        
        AppLogger.info("Deleted API key for provider: \(provider)", category: .security)
    }
    
    // MARK: - APIKeyManagementProtocol Methods
    
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        try saveAPIKey(key, forProvider: provider)
    }
    
    func getAPIKey(for provider: AIProvider) async throws -> String {
        guard let apiKey = getAPIKey(forProvider: provider) else {
            throw ServiceError.authenticationFailed("No API key found for \(provider.rawValue)")
        }
        return apiKey
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        try deleteAPIKey(forProvider: provider)
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        getAPIKey(forProvider: provider) != nil
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        return AIProvider.allCases.filter { provider in
            await hasAPIKey(for: provider)
        }
    }
    
    // MARK: - Private Methods
    
    private func keychainKey(for provider: String) -> String {
        "\(keychainPrefix)\(provider)"
    }
}