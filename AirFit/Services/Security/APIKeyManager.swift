import Foundation

/// Implementation of APIKeyManagementProtocol using Keychain
actor APIKeyManager: APIKeyManagementProtocol, ServiceProtocol {
    private let keychain: KeychainWrapper
    private let keychainPrefix = "com.airfit.apikey."
    
    // MARK: - ServiceProtocol
    nonisolated var isConfigured: Bool { 
        // For APIKeyManager, we're always configured if we can access keychain
        true 
    }
    nonisolated let serviceIdentifier = "api-key-manager"
    
    init(keychain: KeychainWrapper = .shared) {
        self.keychain = keychain
    }
    
    // MARK: - ServiceProtocol
    
    func configure() async throws {
        // Nothing specific to configure for keychain access
        AppLogger.info("APIKeyManager configured", category: .security)
    }
    
    func reset() async {
        // Do not clear API keys on reset
        AppLogger.info("APIKeyManager reset", category: .security)
    }
    
    func healthCheck() async -> ServiceHealth {
        // Check if we can access keychain
        let testKey = "com.airfit.health.check"
        let canAccessKeychain: Bool
        do {
            try keychain.save("test".data(using: .utf8)!, forKey: testKey)
            _ = try keychain.load(key: testKey)
            try keychain.delete(key: testKey)
            canAccessKeychain = true
        } catch {
            canAccessKeychain = false
        }
        
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
    
    // MARK: - APIKeyManagementProtocol
    
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        let keychainKey = self.keychainKey(for: provider.rawValue)
        let data = key.data(using: .utf8) ?? Data()
        try keychain.save(data, forKey: keychainKey)
        
        AppLogger.info("Saved API key for provider: \(provider.rawValue)", category: .security)
    }
    
    func getAPIKey(for provider: AIProvider) async throws -> String {
        let keychainKey = self.keychainKey(for: provider.rawValue)
        
        do {
            let data = try keychain.load(key: keychainKey)
            guard let apiKey = String(data: data, encoding: .utf8) else {
                throw ServiceError.invalidResponse("Invalid API key data")
            }
            return apiKey
        } catch {
            AppLogger.error("Failed to get API key for provider: \(provider.rawValue)", error: error, category: .security)
            throw ServiceError.authenticationFailed("No API key found for \(provider.rawValue)")
        }
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        let keychainKey = self.keychainKey(for: provider.rawValue)
        try keychain.delete(key: keychainKey)
        
        AppLogger.info("Deleted API key for provider: \(provider.rawValue)", category: .security)
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        let keychainKey = self.keychainKey(for: provider.rawValue)
        
        do {
            _ = try keychain.load(key: keychainKey)
            return true
        } catch {
            return false
        }
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
    
    // MARK: - Private Methods
    
    private func keychainKey(for provider: String) -> String {
        "\(keychainPrefix)\(provider)"
    }
}