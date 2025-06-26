import XCTest
@testable import AirFit

@MainActor
final class APIKeyManagerTests: XCTestCase {
    // MARK: - Properties
    private var sut: APIKeyManager!
    private var mockKeychain: MockKeychainWrapper!

    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()

        // Create mock keychain
        mockKeychain = MockKeychainWrapper()

        // Create SUT with mock
        sut = APIKeyManager(keychain: mockKeychain)
    }

    override func tearDown() {
        sut = nil
        mockKeychain = nil
        super.tearDown()
    }

    // MARK: - Save API Key Tests

    func test_saveAPIKey_withValidKey_savesToKeychain() async throws {
        // Arrange
        let apiKey = "sk-test1234567890"
        let provider = AIProvider.openAI

        // Act
        try await sut.saveAPIKey(apiKey, for: provider)

        // Assert
        let savedValue = mockKeychain.storage["com.airfit.apikey.\(provider.rawValue)"]
        XCTAssertEqual(savedValue, apiKey)
        XCTAssertTrue(mockKeychain.setCallCount > 0)
    }

    func test_saveAPIKey_withEmptyKey_throwsError() async throws {
        // Arrange
        let apiKey = ""
        let provider = AIProvider.anthropic

        // Act & Assert
        do {
            try await sut.saveAPIKey(apiKey, for: provider)
            XCTFail("Expected error for empty API key")
        } catch {
            XCTAssertTrue(error is APIKeyManager.APIKeyError)
        }
    }

    func test_saveAPIKey_overwritesExistingKey() async throws {
        // Arrange
        let oldKey = "sk-old1234567890"
        let newKey = "sk-new0987654321"
        let provider = AIProvider.openAI

        // Save old key first
        try await sut.saveAPIKey(oldKey, for: provider)

        // Act - Save new key
        try await sut.saveAPIKey(newKey, for: provider)

        // Assert
        let savedValue = mockKeychain.storage["com.airfit.apikey.\(provider.rawValue)"]
        XCTAssertEqual(savedValue, newKey)
        XCTAssertEqual(mockKeychain.setCallCount, 2)
    }

    // MARK: - Get API Key Tests

    func test_getAPIKey_withExistingKey_returnsKey() async throws {
        // Arrange
        let apiKey = "sk-test1234567890"
        let provider = AIProvider.anthropic
        mockKeychain.storage["com.airfit.apikey.\(provider.rawValue)"] = apiKey

        // Act
        let retrievedKey = try await sut.getAPIKey(for: provider)

        // Assert
        XCTAssertEqual(retrievedKey, apiKey)
        XCTAssertTrue(mockKeychain.getCallCount > 0)
    }

    func test_getAPIKey_withNoKey_throwsError() async throws {
        // Arrange
        let provider = AIProvider.gemini
        // No key in storage

        // Act & Assert
        do {
            _ = try await sut.getAPIKey(for: provider)
            XCTFail("Expected error when key doesn't exist")
        } catch APIKeyManager.APIKeyError.keyNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_getAPIKey_withKeychainError_throwsWrappedError() async throws {
        // Arrange
        let provider = AIProvider.openAI
        mockKeychain.shouldThrowError = true
        mockKeychain.errorToThrow = NSError(domain: "TestError", code: -1)

        // Act & Assert
        do {
            _ = try await sut.getAPIKey(for: provider)
            XCTFail("Expected error from keychain")
        } catch APIKeyManager.APIKeyError.keychainError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Delete API Key Tests

    func test_deleteAPIKey_withExistingKey_removesFromKeychain() async throws {
        // Arrange
        let apiKey = "sk-test1234567890"
        let provider = AIProvider.openAI
        mockKeychain.storage["com.airfit.apikey.\(provider.rawValue)"] = apiKey

        // Act
        try await sut.deleteAPIKey(for: provider)

        // Assert
        XCTAssertNil(mockKeychain.storage["com.airfit.apikey.\(provider.rawValue)"])
        XCTAssertTrue(mockKeychain.deleteCallCount > 0)
    }

    func test_deleteAPIKey_withNoKey_doesNotThrow() async throws {
        // Arrange
        let provider = AIProvider.anthropic
        // No key in storage

        // Act & Assert - Should not throw
        try await sut.deleteAPIKey(for: provider)
        XCTAssertTrue(mockKeychain.deleteCallCount > 0)
    }

    // MARK: - Has API Key Tests

    func test_hasAPIKey_withExistingKey_returnsTrue() async throws {
        // Arrange
        let apiKey = "sk-test1234567890"
        let provider = AIProvider.gemini
        mockKeychain.storage["com.airfit.apikey.\(provider.rawValue)"] = apiKey

        // Act
        let hasKey = await sut.hasAPIKey(for: provider)

        // Assert
        XCTAssertTrue(hasKey)
    }

    func test_hasAPIKey_withNoKey_returnsFalse() async throws {
        // Arrange
        let provider = AIProvider.openAI
        // No key in storage

        // Act
        let hasKey = await sut.hasAPIKey(for: provider)

        // Assert
        XCTAssertFalse(hasKey)
    }

    func test_hasAPIKey_withKeychainError_returnsFalse() async throws {
        // Arrange
        let provider = AIProvider.anthropic
        mockKeychain.shouldThrowError = true

        // Act
        let hasKey = await sut.hasAPIKey(for: provider)

        // Assert
        XCTAssertFalse(hasKey)
    }

    // MARK: - Get All Configured Providers Tests

    func test_getAllConfiguredProviders_returnsProvidersWithKeys() async throws {
        // Arrange
        mockKeychain.storage["com.airfit.apikey.openAI"] = "sk-openai"
        mockKeychain.storage["com.airfit.apikey.anthropic"] = "sk-anthropic"
        // No Gemini key

        // Act
        let providers = await sut.getAllConfiguredProviders()

        // Assert
        XCTAssertEqual(providers.count, 2)
        XCTAssertTrue(providers.contains(.openAI))
        XCTAssertTrue(providers.contains(.anthropic))
        XCTAssertFalse(providers.contains(.gemini))
    }

    func test_getAllConfiguredProviders_withNoKeys_returnsEmptyArray() async throws {
        // Arrange - No keys in storage

        // Act
        let providers = await sut.getAllConfiguredProviders()

        // Assert
        XCTAssertTrue(providers.isEmpty)
    }

    // MARK: - Key Format Validation Tests

    func test_saveAPIKey_withInvalidFormat_throwsError() async throws {
        // Arrange
        let testCases: [(String, AIProvider)] = [
            ("", .openAI),                    // Empty
            ("   ", .anthropic),              // Whitespace only
            ("short", .gemini),               // Too short
            ("no-prefix", .openAI),           // Wrong prefix for OpenAI
            ("claude-wrong", .anthropic)      // Wrong prefix for Anthropic
        ]

        // Act & Assert
        for (invalidKey, provider) in testCases {
            do {
                try await sut.saveAPIKey(invalidKey, for: provider)
                XCTFail("Expected error for invalid key '\(invalidKey)' with provider \(provider)")
            } catch APIKeyManager.APIKeyError.invalidKeyFormat {
                // Expected
            } catch {
                XCTFail("Unexpected error for key '\(invalidKey)': \(error)")
            }
        }
    }

    func test_saveAPIKey_withValidFormat_succeeds() async throws {
        // Arrange
        let testCases: [(String, AIProvider)] = [
            ("sk-proj-test1234567890abcdef", .openAI),
            ("sk-ant-test1234567890abcdef", .anthropic),
            ("AIzaSyAtest1234567890abcdef", .gemini)
        ]

        // Act & Assert
        for (validKey, provider) in testCases {
            try await sut.saveAPIKey(validKey, for: provider)
            let savedKey = try await sut.getAPIKey(for: provider)
            XCTAssertEqual(savedKey, validKey)
        }
    }

    // MARK: - Concurrent Access Tests

    func test_concurrentOperations_maintainDataIntegrity() async throws {
        // Arrange
        let providers: [AIProvider] = [.openAI, .anthropic, .gemini]
        let keys = [
            "sk-proj-concurrent1",
            "sk-ant-concurrent2",
            "AIzaSyconcurrent3"
        ]

        // Act - Perform concurrent operations
        await withTaskGroup(of: Void.self) { group in
            // Save keys concurrently
            for (index, provider) in providers.enumerated() {
                group.addTask {
                    try? await self.sut.saveAPIKey(keys[index], for: provider)
                }
            }

            // Check keys concurrently
            for provider in providers {
                group.addTask {
                    _ = await self.sut.hasAPIKey(for: provider)
                }
            }

            // Get all providers concurrently
            group.addTask {
                _ = await self.sut.getAllConfiguredProviders()
            }
        }

        // Assert - Verify all operations completed successfully
        let configuredProviders = await sut.getAllConfiguredProviders()
        XCTAssertEqual(configuredProviders.count, 3)

        for (index, provider) in providers.enumerated() {
            let key = try await sut.getAPIKey(for: provider)
            XCTAssertEqual(key, keys[index])
        }
    }
}

// MARK: - Mock Keychain Wrapper

private class MockKeychainWrapper {
    var storage: [String: String] = [:]
    var setCallCount = 0
    var getCallCount = 0
    var deleteCallCount = 0
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockError", code: -1)

    func set(_ value: String, forKey key: String) throws {
        setCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        storage[key] = value
    }

    func string(forKey key: String) throws -> String? {
        getCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        return storage[key]
    }

    func removeObject(forKey key: String) throws {
        deleteCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        storage.removeValue(forKey: key)
    }
}
