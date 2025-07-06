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
        // First check format
        let formatValid: Bool
        switch provider {
        case .anthropic:
            formatValid = key.hasPrefix("sk-ant-") && key.count > 40
        case .openAI:
            formatValid = key.hasPrefix("sk-") && key.count > 40
        case .gemini:
            formatValid = key.count > 30
        }

        guard formatValid else {
            throw AppError.validationError(message: "Invalid API key format for \(provider.displayName)")
        }

        // Now validate with actual API call
        let config = LLMProviderConfig(apiKey: key)

        switch provider {
        case .anthropic:
            let provider = AnthropicProvider(config: config)
            return try await provider.validateAPIKey(key)
        case .openAI:
            let provider = OpenAIProvider(config: config)
            return try await provider.validateAPIKey(key)
        case .gemini:
            let provider = GeminiProvider(config: config)
            return try await provider.validateAPIKey(key)
        }
    }

    func saveAPIKey(_ key: String, for provider: AIProvider, model: String) {
        // Save to keychain
        let keychainKey = "airfit_api_key_\(provider.rawValue)"
        let keychainModel = "airfit_model_\(provider.rawValue)"

        _ = keychain.save(key: keychainKey, value: key)
        _ = keychain.save(key: keychainModel, value: model)

        // Update API key manager
        Task {
            try? await apiKeyManager.saveAPIKey(key, for: provider)
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

    func saveAndContinue() {
        // Mark API setup as complete
        UserDefaults.standard.set(true, forKey: "api_setup_complete")

        // Use the selected provider, or fall back to first configured
        if let activeProvider = selectedActiveProvider {
            UserDefaults.standard.set(activeProvider.provider.rawValue, forKey: "default_ai_provider")
            UserDefaults.standard.set(activeProvider.model, forKey: "default_ai_model")
            AppLogger.info("Set active provider: \(activeProvider.provider.displayName) with model: \(activeProvider.model)", category: .app)
        } else if let firstConfig = configuredProviders.first {
            UserDefaults.standard.set(firstConfig.provider.rawValue, forKey: "default_ai_provider")
            UserDefaults.standard.set(firstConfig.model, forKey: "default_ai_model")
            AppLogger.info("No active provider selected, using first: \(firstConfig.provider.displayName)", category: .app)
        }
        
        // Force synchronization to ensure values are persisted before container recreation
        UserDefaults.standard.synchronize()
    }

    private func loadExistingConfigurations() {
        let providers: [AIProvider] = [.anthropic, .openAI, .gemini]

        for provider in providers {
            let keychainKey = "airfit_api_key_\(provider.rawValue)"
            let keychainModel = "airfit_model_\(provider.rawValue)"

            if let apiKey = keychain.get(key: keychainKey),
               let model = keychain.get(key: keychainModel) {
                // Load into API key manager
                Task {
                    try? await apiKeyManager.saveAPIKey(apiKey, for: provider)
                }

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
