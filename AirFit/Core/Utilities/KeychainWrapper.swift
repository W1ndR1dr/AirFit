import Foundation
import Security

final class KeychainWrapper {
    static let shared = KeychainWrapper()
    
    private let serviceName = AppConstants.Storage.keychainServiceName
    
    private init() {}
    
    // MARK: - Save
    @discardableResult
    func save(_ data: Data, for key: String) -> Bool {
        delete(key: key) // Delete any existing item first
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            AppLogger.error("Keychain save failed", 
                          error: KeychainError.saveFailed(status),
                          category: .storage)
        }
        
        return status == errSecSuccess
    }
    
    @discardableResult
    func saveString(_ string: String, for key: String) -> Bool {
        guard let data = string.data(using: .utf8) else {
            AppLogger.error("Failed to encode string for keychain", category: .storage)
            return false
        }
        return save(data, for: key)
    }
    
    @discardableResult
    func saveCodable<T: Codable>(_ object: T, for key: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(object)
            return save(data, for: key)
        } catch {
            AppLogger.error("Failed to encode object for keychain", 
                          error: error,
                          category: .storage)
            return false
        }
    }
    
    // MARK: - Retrieve
    func getData(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            if status != errSecItemNotFound {
                AppLogger.error("Keychain retrieval failed", 
                              error: KeychainError.retrievalFailed(status),
                              category: .storage)
            }
            return nil
        }
        
        return data
    }
    
    func getString(for key: String) -> String? {
        guard let data = getData(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func getCodable<T: Codable>(_ type: T.Type, for key: String) -> T? {
        guard let data = getData(for: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            AppLogger.error("Failed to decode object from keychain", 
                          error: error,
                          category: .storage)
            return nil
        }
    }
    
    // MARK: - Delete
    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            AppLogger.error("Keychain deletion failed", 
                          error: KeychainError.deletionFailed(status),
                          category: .storage)
        }
        
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Clear All
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            AppLogger.error("Failed to clear keychain", 
                          error: KeychainError.clearFailed(status),
                          category: .storage)
        }
    }
}

// MARK: - Error
enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case retrievalFailed(OSStatus)
    case deletionFailed(OSStatus)
    case clearFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .retrievalFailed(let status):
            return "Failed to retrieve from keychain: \(status)"
        case .deletionFailed(let status):
            return "Failed to delete from keychain: \(status)"
        case .clearFailed(let status):
            return "Failed to clear keychain: \(status)"
        }
    }
} 