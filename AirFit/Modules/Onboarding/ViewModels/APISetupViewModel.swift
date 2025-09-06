import SwiftUI
import Combine

struct APIConfiguration {
    let provider: AIProvider
    let model: String
    let isValid: Bool
}

@MainActor
final class APISetupViewModel: ObservableObject {
    @Published var configuredProviders: [APIConfiguration] = []
    @Published var isValidating = false
    @Published var error: String?
    @Published var selectedActiveProvider: APIConfiguration?

    private let keychain = KeychainManager()
    private let apiKeyManager: APIKeyManagementProtocol

    init(apiKeyManager: APIKeyManagementProtocol) {
        self.apiKeyManager = apiKeyManager

        // Load any existing configurations
        loadExistingConfigurations()
    }

    func validateAPIKey(_ key: String, for provider: AIProvider, model: String) async throws -> Bool {
        // Validate with provider API (source of truth). Formats change; avoid strict client-side rejection.
        let config = LLMProviderConfig(apiKey: key)
        switch provider {
        case .anthropic:
            let p = AnthropicProvider(config: config)
            return try await p.validateAPIKey(key)
        case .openAI:
            let p = OpenAIProvider(config: config)
            return try await p.validateAPIKey(key)
        case .gemini:
            let p = GeminiProvider(config: config)
            return try await p.validateAPIKey(key)
        }
    }

    func saveAPIKey(_ key: String, for provider: AIProvider, model: String) async throws {
        // Save to keychain with error handling
        let keychainKey = "airfit_api_key_\(provider.rawValue)"
        let keychainModel = "airfit_model_\(provider.rawValue)"

        guard keychain.save(key: keychainKey, value: key) else {
            throw AppError.keychain("Failed to save API key to keychain")
        }
        
        guard keychain.save(key: keychainModel, value: model) else {
            // Rollback key save if model save fails
            _ = keychain.delete(key: keychainKey)
            throw AppError.keychain("Failed to save model to keychain")
        }

        // Update API key manager and await completion
        do {
            try await apiKeyManager.saveAPIKey(key, for: provider)
        } catch {
            // Rollback keychain saves on API manager failure
            _ = keychain.delete(key: keychainKey)
            _ = keychain.delete(key: keychainModel)
            throw AppError.apiConfiguration("Failed to configure API key manager: \(error.localizedDescription)")
        }

        // Update configured providers
        if let index = configuredProviders.firstIndex(where: { $0.provider == provider }) {
            configuredProviders[index] = APIConfiguration(
                provider: provider,
                model: model,
                isValid: true
            )
        } else {
            configuredProviders.append(
                APIConfiguration(
                    provider: provider,
                    model: model,
                    isValid: true
                )
            )
        }

        // Auto-select active provider if none selected
        if selectedActiveProvider == nil,
           let first = configuredProviders.first(where: { $0.provider == provider }) {
            selectedActiveProvider = first
        }

        // Save to UserDefaults for quick access
        UserDefaults.standard.set(model, forKey: "selected_model_\(provider.rawValue)")
    }

    func removeConfiguration(for provider: AIProvider) {
        // Remove from keychain
        let keychainKey = "airfit_api_key_\(provider.rawValue)"
        let keychainModel = "airfit_model_\(provider.rawValue)"

        _ = keychain.delete(key: keychainKey)
        _ = keychain.delete(key: keychainModel)

        // Remove from API key manager
        Task {
            try? await apiKeyManager.deleteAPIKey(for: provider)
        }

        // Update configured providers
        configuredProviders.removeAll { $0.provider == provider }

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "selected_model_\(provider.rawValue)")
    }

    func saveAndContinue() async throws {
        // Ensure we have at least one configured provider
        guard !configuredProviders.isEmpty else {
            throw AppError.configuration("No API providers configured")
        }
        
        // Ensure we have an active provider selected
        guard let activeProvider = selectedActiveProvider ?? configuredProviders.first else {
            throw AppError.configuration("No active provider selected")
        }
        
        // Sanity-check that the selected provider's key actually works
        do {
            let keychainKey = "airfit_api_key_\(activeProvider.provider.rawValue)"
            if let apiKey = keychain.get(key: keychainKey) {
                let config = LLMProviderConfig(apiKey: apiKey)
                let isValid: Bool
                switch activeProvider.provider {
                case .anthropic:
                    isValid = try await AnthropicProvider(config: config).validateAPIKey(apiKey)
                case .openAI:
                    isValid = try await OpenAIProvider(config: config).validateAPIKey(apiKey)
                case .gemini:
                    isValid = try await GeminiProvider(config: config).validateAPIKey(apiKey)
                }
                if !isValid {
                    throw AppError.validationError(message: "API key failed validation for \(activeProvider.provider.displayName)")
                }
            } else {
                throw AppError.configuration("Missing API key for selected provider")
            }
        } catch {
            throw AppError.apiConfiguration("\(activeProvider.provider.displayName) key check failed: \(error.localizedDescription)")
        }

        // Save active provider configuration
        UserDefaults.standard.set(activeProvider.provider.rawValue, forKey: DefaultsKeys.defaultAIProvider)
        UserDefaults.standard.set(activeProvider.model, forKey: DefaultsKeys.defaultAIModel)
        
        // Verify API key manager has the keys loaded
        for config in configuredProviders {
            let hasKey = await apiKeyManager.hasAPIKey(for: config.provider)
            if !hasKey {
                // Try to reload from keychain
                let keychainKey = "airfit_api_key_\(config.provider.rawValue)"
                if let apiKey = keychain.get(key: keychainKey) {
                    try await apiKeyManager.saveAPIKey(apiKey, for: config.provider)
                } else {
                    throw AppError.configuration("Missing API key for \(config.provider.displayName)")
                }
            }
        }
        
        // Mark API setup as complete only after verification
        UserDefaults.standard.set(true, forKey: DefaultsKeys.apiSetupComplete)
        
        AppLogger.info("API setup completed with provider: \(activeProvider.provider.displayName) model: \(activeProvider.model)", category: .app)
    }

    private func loadExistingConfigurations() {
        let providers: [AIProvider] = [.anthropic, .openAI, .gemini]

        for provider in providers {
            let keychainKey = "airfit_api_key_\(provider.rawValue)"
            let keychainModel = "airfit_model_\(provider.rawValue)"

            if let _ = keychain.get(key: keychainKey),
               let model = keychain.get(key: keychainModel) {
                // Load into API key manager - will be done on demand in saveAndContinue
                // This avoids race conditions during initialization

                // Add to configured providers
                configuredProviders.append(
                    APIConfiguration(
                        provider: provider,
                        model: model,
                        isValid: true
                    )
                )
            }
        }
    }
}

// MARK: - Keychain Manager
struct KeychainManager {
    func save(key: String, value: String) -> Bool {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.airfit.api",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.airfit.api",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        return nil
    }

    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.airfit.api"
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
