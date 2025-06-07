import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class SettingsViewModelTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var sut: SettingsViewModel!
    private var mockAPIKeyManager: MockAPIKeyManager!
    private var mockAIService: MockAIService!
    private var mockNotificationManager: MockNotificationManager!
    private var modelContext: ModelContext!
    private var testUser: User!
    private var coordinator: SettingsCoordinator!

    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test container
        container = try await DITestHelper.createTestContainer()
        
        // Get model context from container
        let modelContainer = try await container.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
        
        // Create test user
        testUser = User(name: "Test User")
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Get mocks from container
        mockAPIKeyManager = try await container.resolve(APIKeyManagementProtocol.self) as? MockAPIKeyManager
        mockAIService = try await container.resolve(AIServiceProtocol.self) as? MockAIService
        mockNotificationManager = try await container.resolve(NotificationManager.self) as? MockNotificationManager
        
        // Create coordinator manually (not in DI container yet)
        coordinator = SettingsCoordinator()
        
        // Create SUT
        sut = SettingsViewModel(
            modelContext: modelContext,
            user: testUser,
            apiKeyManager: mockAPIKeyManager,
            aiService: mockAIService,
            notificationManager: mockNotificationManager,
            coordinator: coordinator
        )
    }

    override func tearDown() async throws {
        mockAPIKeyManager?.reset()
        mockAIService?.reset()
        mockNotificationManager?.reset()
        sut = nil
        mockAPIKeyManager = nil
        mockAIService = nil
        mockNotificationManager = nil
        modelContext = nil
        testUser = nil
        coordinator = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - Loading Tests

    func test_loadSettings_shouldPopulateAvailableProviders() async {
        // Act
        await sut.loadSettings()

        // Assert
        XCTAssertEqual(sut.availableProviders.count, AIProvider.allCases.count)
        XCTAssertTrue(sut.availableProviders.contains(.openAI))
        XCTAssertTrue(sut.availableProviders.contains(.anthropic))
    }

    func test_loadSettings_shouldCheckInstalledAPIKeys() async {
        // Arrange
        mockAPIKeyManager.stubbedGetAllConfiguredProvidersResult = [.openAI]

        // Act
        await sut.loadSettings()

        // Assert
        XCTAssertTrue(sut.installedAPIKeys.contains(.openAI))
        XCTAssertFalse(sut.installedAPIKeys.contains(.anthropic))
    }

    // MARK: - API Key Management Tests

    func test_saveAPIKey_withValidKey_shouldStoreAndConfigureService() async throws {
        // Arrange
        let testKey = "sk-test1234567890"
        mockAIService.isConfigured = true

        // Act
        try await sut.saveAPIKey(testKey, for: .openAI)

        // Assert
        XCTAssertTrue((mockAPIKeyManager.invocations["saveAPIKey"]?.count ?? 0) > 0)
        XCTAssertTrue(sut.installedAPIKeys.contains(.openAI))
        XCTAssertTrue(mockAIService.isConfigured)
    }

    func test_saveAPIKey_withInvalidFormat_shouldThrowError() async {
        // Arrange
        let invalidKey = "invalid"

        // Act & Assert
        do {
            try await sut.saveAPIKey(invalidKey, for: .openAI)
            XCTFail("Should throw invalidAPIKey error")
        } catch SettingsError.invalidAPIKey {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_deleteAPIKey_forActiveProvider_shouldSwitchToAlternative() async throws {
        // Arrange
        sut.selectedProvider = .openAI
        sut.installedAPIKeys = [.openAI, .anthropic]
        mockAPIKeyManager.stubbedGetAllConfiguredProvidersResult = [.anthropic]

        // Act
        try await sut.deleteAPIKey(for: .openAI)

        // Assert
        XCTAssertFalse(sut.installedAPIKeys.contains(.openAI))
        XCTAssertEqual(sut.selectedProvider, .anthropic)
    }

    // MARK: - Preference Update Tests

    func test_updateUnits_shouldSaveAndPostNotification() async throws {
        // Arrange
        let expectation = expectation(forNotification: .unitsChanged, object: nil)

        // Act
        try await sut.updateUnits(.metric)

        // Assert
        XCTAssertEqual(sut.preferredUnits, .metric)
        XCTAssertEqual(testUser.preferredUnitsEnum, .metric)
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func test_updateAppearance_shouldSavePreference() async throws {
        // Act
        try await sut.updateAppearance(.dark)

        // Assert
        XCTAssertEqual(sut.appearanceMode, .dark)
        XCTAssertEqual(testUser.appearanceMode, .dark)
    }

    func test_updateHaptics_shouldSavePreference() async throws {
        // Act
        try await sut.updateHaptics(false)

        // Assert
        XCTAssertFalse(sut.hapticFeedback)
        XCTAssertFalse(testUser.hapticFeedbackEnabled)
    }

    // MARK: - Biometric Lock Tests

    func test_updateBiometricLock_whenNotAvailable_shouldThrowError() async {
        // Arrange
        // BiometricAuthManager will return false for canUseBiometrics in tests

        // Act & Assert
        do {
            try await sut.updateBiometricLock(true)
            XCTFail("Should throw biometricsNotAvailable error")
        } catch SettingsError.biometricsNotAvailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Persona Tests

    func test_loadCoachPersona_withValidData_shouldLoadPersona() async throws {
        // Arrange
        let testPersona = createTestPersona()
        let personaData = try JSONEncoder().encode(testPersona)
        testUser.coachPersonaData = personaData

        // Act
        try await sut.loadCoachPersona()

        // Assert
        XCTAssertNotNil(sut.coachPersona)
        XCTAssertEqual(sut.coachPersona?.identity.name, testPersona.identity.name)
    }

    func test_generatePersonaPreview_withNoPersona_shouldThrowError() async {
        // Arrange
        sut.coachPersona = nil

        // Act & Assert
        do {
            _ = try await sut.generatePersonaPreview(scenario: .morningGreeting)
            XCTFail("Should throw personaNotConfigured error")
        } catch SettingsError.personaNotConfigured {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func createTestPersona() -> CoachPersona {
        let profile = PersonalityInsights()

        // Create a persona profile first
        let personaProfile = PersonaProfile(
            id: UUID(),
            name: "Test Coach",
            archetype: "Motivator",
            systemPrompt: "Test prompt",
            coreValues: ["Excellence", "Growth"],
            backgroundStory: "Test story",
            voiceCharacteristics: VoiceCharacteristics(
                energy: .high,
                pace: .brisk,
                warmth: .warm,
                vocabulary: .moderate,
                sentenceStructure: .simple
            ),
            interactionStyle: InteractionStyle(
                greetingStyle: "Enthusiastic",
                closingStyle: "Motivational",
                encouragementPhrases: ["Great job!", "Keep going!"],
                acknowledgmentStyle: "Constructive",
                correctionApproach: "Gentle",
                humorLevel: .light,
                formalityLevel: .casual,
                responseLength: .moderate
            ),
            adaptationRules: [],
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "1.0",
                sourceInsights: ConversationPersonalityInsights(
                    dominantTraits: ["Motivated"],
                    communicationStyle: .energetic,
                    motivationType: .achievement,
                    energyLevel: .high,
                    preferredComplexity: .moderate,
                    emotionalTone: ["supportive"],
                    stressResponse: .needsSupport,
                    preferredTimes: ["morning"],
                    extractedAt: Date()
                ),
                generationDuration: 1.0,
                tokenCount: 100,
                previewReady: true
            )
        )

        return CoachPersona(from: personaProfile)
    }
}
