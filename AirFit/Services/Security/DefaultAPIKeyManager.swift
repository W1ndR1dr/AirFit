import Foundation

/// Default implementation of APIKeyManagerProtocol using Keychain
@MainActor
final class DefaultAPIKeyManager: APIKeyManagerProtocol, APIKeyManagementProtocol, ServiceProtocol, @unchecked Sendable {
    private let keychain: KeychainWrapper
    private let keychainPrefix = "com.airfit.apikey."
    
    // MARK: - ServiceProtocol
    private(set) var isConfigured: Bool = false
    let serviceIdentifier = "api-key-manager"
    
    init(keychain: KeychainWrapper = .shared) {
        self.keychain = keychain
    }
    
    // MARK: - ServiceProtocol
    
    func configure() async throws {
        // Nothing specific to configure for keychain access
        isConfigured = true
        AppLogger.info("APIKeyManager configured", category: .security)
    }
    
    func reset() async {
        // Do not clear API keys on reset
        AppLogger.info("APIKeyManager reset", category: .security)
    }
    
    func healthCheck() async -> ServiceHealth {
        // Check if we can access keychain
        let canAccessKeychain = await Task { () -> Bool in
            do {
                // Try to access a dummy key to verify keychain access
                _ = try keychain.load(key: "health_check_dummy")
                return true
            } catch {
                // Expected error for non-existent key, but confirms keychain is accessible
                return true
            }
        }.value
        
        return ServiceHealth(
            status: canAccessKeychain ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: canAccessKeychain ? nil : "Cannot access keychain",
            metadata: [
                "configuredProviders": "\(await getAllConfiguredProviders().count)"
            ]
        )
    }
    
    // MARK: - Legacy Synchronous Methods
    
    func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws {
        let key = keychainKey(for: provider.rawValue)
        let data = apiKey.data(using: .utf8) ?? Data()
        try keychain.save(data, forKey: key)
        
        AppLogger.info("Saved API key for provider: \(provider.rawValue)", category: .security)
    }
    
    func getAPIKey(forProvider provider: AIProvider) -> String? {
        let key = keychainKey(for: provider.rawValue)
        
        do {
            let data = try keychain.load(key: key)
            let apiKey = String(data: data, encoding: .utf8)
            return apiKey
        } catch {
            AppLogger.error("Failed to get API key for provider: \(provider.rawValue)", error: error, category: .security)
            return nil
        }
    }
    
    func deleteAPIKey(forProvider provider: AIProvider) throws {
        let key = keychainKey(for: provider.rawValue)
        try keychain.delete(key: key)
        
        AppLogger.info("Deleted API key for provider: \(provider.rawValue)", category: .security)
    }
    
    // MARK: - Modern Async Methods
    
    func getAPIKey(for provider: String) async -> String? {
        let key = keychainKey(for: provider)
        
        do {
            let data = try keychain.load(key: key)
            let apiKey = String(data: data, encoding: .utf8)
            return apiKey
        } catch {
            AppLogger.error("Failed to get API key for provider: \(provider)", error: error, category: .security)
            return nil
        }
    }
    
    func saveAPIKey(_ apiKey: String, for provider: String) async throws {
        let key = keychainKey(for: provider)
        let data = apiKey.data(using: .utf8) ?? Data()
        try keychain.save(data, forKey: key)
        
        AppLogger.info("Saved API key for provider: \(provider)", category: .security)
    }
    
    func deleteAPIKey(for provider: String) async throws {
        let key = keychainKey(for: provider)
        try keychain.delete(key: key)
        
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
        var configuredProviders: [AIProvider] = []
        for provider in AIProvider.allCases {
            if await hasAPIKey(for: provider) {
                configuredProviders.append(provider)
            }
        }
        return configuredProviders
    }
    
    // MARK: - APIKeyManagerProtocol Methods
    
    func setAPIKey(_ key: String, for provider: AIProvider) async throws {
        try saveAPIKey(key, forProvider: provider)
    }
    
    func getAPIKey(for provider: AIProvider) async throws -> String? {
        return getAPIKey(forProvider: provider)
    }
    
    func removeAPIKey(for provider: AIProvider) async throws {
        try deleteAPIKey(forProvider: provider)
    }
    
    // MARK: - Private Methods
    
    private func keychainKey(for provider: String) -> String {
        "\(keychainPrefix)\(provider)"
    }
}