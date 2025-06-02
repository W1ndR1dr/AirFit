import Foundation
import Security

/// Helper class for enhanced Keychain operations with error handling and batch operations
final class KeychainHelper: @unchecked Sendable {
    static let shared = KeychainHelper()
    
    private let serviceName: String
    private let accessGroup: String?
    private let lock = NSLock()
    
    init(serviceName: String = Bundle.main.bundleIdentifier ?? "com.airfit",
         accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }
    
    // MARK: - Save Operations
    
    func save(_ data: Data, for key: String, accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly) throws {
        lock.lock()
        defer { lock.unlock() }
        
        // Delete any existing item first
        try? delete(for: key)
        
        var query = baseQuery(for: key)
        query[kSecValueData] = data
        query[kSecAttrAccessible] = accessibility.rawValue
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func save(_ string: String, for key: String, accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.encodingError
        }
        try save(data, for: key, accessibility: accessibility)
    }
    
    // MARK: - Retrieve Operations
    
    func getData(for key: String) throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        
        var query = baseQuery(for: key)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.unexpectedItemData
        }
        
        return data
    }
    
    func getString(for key: String) throws -> String {
        let data = try getData(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingError
        }
        return string
    }
    
    // MARK: - Delete Operations
    
    func delete(for key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func deleteAll() throws {
        lock.lock()
        defer { lock.unlock() }
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Batch Operations
    
    func getAllKeys() throws -> [String] {
        lock.lock()
        defer { lock.unlock() }
        
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecReturnAttributes: true,
            kSecMatchLimit: kSecMatchLimitAll
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return []
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let items = result as? [[CFString: Any]] else {
            return []
        }
        
        return items.compactMap { $0[kSecAttrAccount] as? String }
    }
    
    // MARK: - Existence Check
    
    func exists(for key: String) -> Bool {
        do {
            _ = try getData(for: key)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func baseQuery(for key: String) -> [CFString: Any] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup] = accessGroup
        }
        
        return query
    }
}

// MARK: - Keychain Accessibility Options
enum KeychainAccessibility: RawRepresentable {
    case whenUnlocked
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlock
    case afterFirstUnlockThisDeviceOnly
    case whenPasscodeSetThisDeviceOnly
    
    var rawValue: CFString {
        switch self {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        }
    }
    
    init?(rawValue: CFString) {
        switch rawValue {
        case kSecAttrAccessibleWhenUnlocked:
            self = .whenUnlocked
        case kSecAttrAccessibleWhenUnlockedThisDeviceOnly:
            self = .whenUnlockedThisDeviceOnly
        case kSecAttrAccessibleAfterFirstUnlock:
            self = .afterFirstUnlock
        case kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly:
            self = .afterFirstUnlockThisDeviceOnly
        case kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly:
            self = .whenPasscodeSetThisDeviceOnly
        default:
            return nil
        }
    }
}

// MARK: - Keychain Errors
enum KeychainError: LocalizedError {
    case itemNotFound
    case duplicateItem
    case invalidItemFormat
    case unexpectedItemData
    case encodingError
    case decodingError
    case unhandledError(status: OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found in keychain"
        case .duplicateItem:
            return "Item already exists in keychain"
        case .invalidItemFormat:
            return "Invalid item format"
        case .unexpectedItemData:
            return "Unexpected item data returned from keychain"
        case .encodingError:
            return "Failed to encode data for keychain"
        case .decodingError:
            return "Failed to decode data from keychain"
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        }
    }
}