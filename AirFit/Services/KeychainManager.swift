import Foundation
import Security

/// Thread-safe Keychain wrapper for storing sensitive data like API keys.
///
/// Uses the iOS Keychain Services API for secure, encrypted storage.
/// All operations are synchronous but safe to call from any thread.
actor KeychainManager {
    static let shared = KeychainManager()

    // MARK: - Keychain Keys

    private enum KeychainKey: String {
        case geminiAPIKey = "com.airfit.gemini-api-key"
        case hevyAPIKey = "com.airfit.hevy-api-key"
    }

    // MARK: - Gemini API Key

    /// Store the Gemini API key securely in the Keychain.
    func setGeminiAPIKey(_ key: String) throws {
        try set(key, for: .geminiAPIKey)
    }

    /// Retrieve the stored Gemini API key, or nil if not set.
    func getGeminiAPIKey() -> String? {
        return get(for: .geminiAPIKey)
    }

    /// Remove the Gemini API key from the Keychain.
    func deleteGeminiAPIKey() throws {
        try delete(for: .geminiAPIKey)
    }

    /// Check if a Gemini API key is stored.
    func hasGeminiAPIKey() -> Bool {
        return getGeminiAPIKey() != nil
    }

    // MARK: - Hevy API Key

    /// Store the Hevy API key securely in the Keychain.
    func setHevyAPIKey(_ key: String) throws {
        try set(key, for: .hevyAPIKey)
    }

    /// Retrieve the stored Hevy API key, or nil if not set.
    func getHevyAPIKey() -> String? {
        return get(for: .hevyAPIKey)
    }

    /// Remove the Hevy API key from the Keychain.
    func deleteHevyAPIKey() throws {
        try delete(for: .hevyAPIKey)
    }

    /// Check if a Hevy API key is stored.
    func hasHevyAPIKey() -> Bool {
        return getHevyAPIKey() != nil
    }

    // MARK: - Generic Keychain Operations

    private func set(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // First, try to delete any existing item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Now add the new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func get(for key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func delete(for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)

        // errSecItemNotFound is acceptable - means nothing to delete
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Errors

enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode value for Keychain storage"
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        }
    }
}
