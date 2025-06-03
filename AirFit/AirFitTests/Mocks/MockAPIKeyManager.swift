import Foundation
@testable import AirFit

// MARK: - MockAPIKeyManagementProtocol
final class MockAPIKeyManagement: APIKeyManagementProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // Stubbed responses
    var stubbedSaveAPIKeyError: Error?
    var stubbedGetAPIKeyResult: String = "test-api-key"
    var stubbedGetAPIKeyError: Error?
    var stubbedDeleteAPIKeyError: Error?
    var stubbedHasAPIKeyResult: Bool = true
    var stubbedGetAllConfiguredProvidersResult: [AIProvider] = []
    
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        recordInvocation("saveAPIKey", arguments: key, provider)
        if let error = stubbedSaveAPIKeyError {
            throw error
        }
    }
    
    func getAPIKey(for provider: AIProvider) async throws -> String {
        recordInvocation("getAPIKey", arguments: provider)
        if let error = stubbedGetAPIKeyError {
            throw error
        }
        return stubbedGetAPIKeyResult
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        recordInvocation("deleteAPIKey", arguments: provider)
        if let error = stubbedDeleteAPIKeyError {
            throw error
        }
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        recordInvocation("hasAPIKey", arguments: provider)
        return stubbedHasAPIKeyResult
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        recordInvocation("getAllConfiguredProviders", arguments: nil)
        return stubbedGetAllConfiguredProvidersResult
    }
}

// MARK: - MockAPIKeyManagerProtocol (Legacy)
final class MockAPIKeyManager: APIKeyManagerProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // Stubbed responses
    var stubbedSetAPIKeyError: Error?
    var stubbedGetAPIKeyResult: String? = "test-api-key"
    var stubbedGetAPIKeyError: Error?
    var stubbedRemoveAPIKeyError: Error?
    var stubbedHasAPIKeyResult: Bool = true
    var stubbedGetAllConfiguredProvidersResult: [AIProvider] = []
    
    // Legacy sync methods
    var stubbedSaveAPIKeyError: Error?
    var stubbedDeleteAPIKeyError: Error?
    
    func setAPIKey(_ key: String, for provider: AIProvider) async throws {
        recordInvocation("setAPIKey", arguments: key, provider)
        if let error = stubbedSetAPIKeyError {
            throw error
        }
    }
    
    func getAPIKey(for provider: AIProvider) async throws -> String? {
        recordInvocation("getAPIKey", arguments: provider)
        if let error = stubbedGetAPIKeyError {
            throw error
        }
        return stubbedGetAPIKeyResult
    }
    
    func removeAPIKey(for provider: AIProvider) async throws {
        recordInvocation("removeAPIKey", arguments: provider)
        if let error = stubbedRemoveAPIKeyError {
            throw error
        }
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        recordInvocation("hasAPIKey", arguments: provider)
        return stubbedHasAPIKeyResult
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        recordInvocation("getAllConfiguredProviders", arguments: nil)
        return stubbedGetAllConfiguredProvidersResult
    }
    
    // Legacy synchronous methods from APIKeyManagerProtocol in APIKeyManagerProtocol.swift
    func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws {
        recordInvocation("saveAPIKey_sync", arguments: apiKey, provider)
        if let error = stubbedSaveAPIKeyError {
            throw error
        }
    }
    
    func getAPIKey(forProvider provider: AIProvider) -> String? {
        recordInvocation("getAPIKey_sync", arguments: provider)
        return stubbedGetAPIKeyResult
    }
    
    func deleteAPIKey(forProvider provider: AIProvider) throws {
        recordInvocation("deleteAPIKey_sync", arguments: provider)
        if let error = stubbedDeleteAPIKeyError {
            throw error
        }
    }
    
    // Modern async methods using string-based provider identification
    func getAPIKey(for provider: String) async -> String? {
        recordInvocation("getAPIKey_string", arguments: provider)
        return stubbedGetAPIKeyResult
    }
    
    func saveAPIKey(_ apiKey: String, for provider: String) async throws {
        recordInvocation("saveAPIKey_string", arguments: apiKey, provider)
        if let error = stubbedSaveAPIKeyError {
            throw error
        }
    }
    
    func deleteAPIKey(for provider: String) async throws {
        recordInvocation("deleteAPIKey_string", arguments: provider)
        if let error = stubbedDeleteAPIKeyError {
            throw error
        }
    }
}