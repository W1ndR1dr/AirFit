import Foundation

/// Mock implementation of APIKeyManagementProtocol for testing
final class MockAPIKeyManager: APIKeyManagementProtocol {
    
    // MARK: - Properties
    private var apiKeys: [String: String] = [:]
    
    // Test control properties
    var shouldFail = false
    var failureError: Error = ServiceError.authenticationFailed("Mock failure")
    var saveCallCount = 0
    var getCallCount = 0
    var deleteCallCount = 0
    
    // MARK: - APIKeyManagementProtocol
    
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        saveCallCount += 1
        
        if shouldFail {
            throw failureError
        }
        
        apiKeys[provider.rawValue] = key
    }
    
    func getAPIKey(for provider: AIProvider) async throws -> String {
        getCallCount += 1
        
        if shouldFail {
            throw failureError
        }
        
        guard let key = apiKeys[provider.rawValue] else {
            throw ServiceError.authenticationFailed("No API key found for \(provider.rawValue)")
        }
        
        return key
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        deleteCallCount += 1
        
        if shouldFail {
            throw failureError
        }
        
        apiKeys.removeValue(forKey: provider.rawValue)
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        apiKeys[provider.rawValue] != nil
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        AIProvider.allCases.filter { provider in
            apiKeys[provider.rawValue] != nil
        }
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        apiKeys.removeAll()
        shouldFail = false
        saveCallCount = 0
        getCallCount = 0
        deleteCallCount = 0
    }
    
    func setMockAPIKey(_ key: String, for provider: AIProvider) {
        apiKeys[provider.rawValue] = key
    }
    
    func getAllKeys() -> [String: String] {
        apiKeys
    }
}

/// Mock implementation that also conforms to legacy APIKeyManagerProtocol
final class MockFullAPIKeyManager: APIKeyManagerProtocol, APIKeyManagementProtocol {
    
    private let mockManager = MockAPIKeyManager()
    
    // MARK: - Legacy APIKeyManagerProtocol
    
    func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws {
        Task { @MainActor in
            try await mockManager.saveAPIKey(apiKey, for: provider)
        }
    }
    
    func getAPIKey(forProvider provider: AIProvider) -> String? {
        var result: String?
        Task { @MainActor in
            result = try? await mockManager.getAPIKey(for: provider)
        }
        return result
    }
    
    func deleteAPIKey(forProvider provider: AIProvider) throws {
        Task { @MainActor in
            try await mockManager.deleteAPIKey(for: provider)
        }
    }
    
    func getAPIKey(for provider: String) async -> String? {
        guard let aiProvider = AIProvider(rawValue: provider) else { return nil }
        return try? await mockManager.getAPIKey(for: aiProvider)
    }
    
    func saveAPIKey(_ apiKey: String, for provider: String) async throws {
        guard let aiProvider = AIProvider(rawValue: provider) else {
            throw ServiceError.invalidConfiguration("Unknown provider: \(provider)")
        }
        try await mockManager.saveAPIKey(apiKey, for: aiProvider)
    }
    
    func deleteAPIKey(for provider: String) async throws {
        guard let aiProvider = AIProvider(rawValue: provider) else {
            throw ServiceError.invalidConfiguration("Unknown provider: \(provider)")
        }
        try await mockManager.deleteAPIKey(for: aiProvider)
    }
    
    // MARK: - APIKeyManagementProtocol
    
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        try await mockManager.saveAPIKey(key, for: provider)
    }
    
    func getAPIKey(for provider: AIProvider) async throws -> String {
        try await mockManager.getAPIKey(for: provider)
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        try await mockManager.deleteAPIKey(for: provider)
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        await mockManager.hasAPIKey(for: provider)
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        await mockManager.getAllConfiguredProviders()
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        mockManager.reset()
    }
    
    func setMockAPIKey(_ key: String, for provider: AIProvider) {
        mockManager.setMockAPIKey(key, for: provider)
    }
}