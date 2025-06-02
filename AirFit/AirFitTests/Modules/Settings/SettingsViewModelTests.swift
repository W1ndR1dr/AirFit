import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class SettingsViewModelTests: XCTestCase {
    var sut: SettingsViewModel!
    var mockAPIKeyManager: MockAPIKeyManager!
    var mockAIService: MockAIService!
    var mockNotificationManager: MockNotificationManager!
    var modelContext: ModelContext!
    var testUser: User!
    var coordinator: SettingsCoordinator!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup test context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: User.self, configurations: config)
        modelContext = ModelContext(container)
        
        // Create test user
        testUser = User(name: "Test User")
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Setup mocks
        mockAPIKeyManager = MockAPIKeyManager()
        mockAIService = MockAIService()
        mockNotificationManager = MockNotificationManager.shared
        coordinator = SettingsCoordinator()
        
        // Create SUT
        sut = SettingsViewModel(
            modelContext: modelContext,
            user: testUser,
            apiKeyManager: mockAPIKeyManager,
            aiService: mockAIService,
            notificationManager: NotificationManager.shared,
            coordinator: coordinator
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockAPIKeyManager = nil
        mockAIService = nil
        mockNotificationManager = nil
        modelContext = nil
        testUser = nil
        coordinator = nil
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
        mockAPIKeyManager.setHasKey(true, for: .openAI)
        mockAPIKeyManager.setHasKey(false, for: .anthropic)
        
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
        mockAPIKeyManager.testKeys[.openAI] = true
        mockAIService.testConnectionResult = true
        
        // Act
        try await sut.saveAPIKey(testKey, for: .openAI)
        
        // Assert
        XCTAssertTrue(mockAPIKeyManager.savedKeys.contains { $0.provider == "openAI" })
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
        mockAPIKeyManager.setHasKey(true, for: .anthropic)
        
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
        CoachPersona(
            id: UUID(),
            identity: PersonaIdentity(
                name: "Test Coach",
                archetype: "Motivator",
                coreValues: ["Excellence", "Growth"],
                backgroundStory: "Test story"
            ),
            communication: VoiceCharacteristics(
                energy: .high,
                pace: .brisk,
                warmth: .warm,
                vocabulary: .moderate,
                sentenceStructure: .simple
            ),
            philosophy: CoachingPhilosophy(
                approach: "Test approach",
                principles: ["Test principle"],
                motivationalStyle: "Encouraging"
            ),
            behaviors: CoachingBehaviors(
                greetingStyle: "Enthusiastic",
                feedbackStyle: "Constructive",
                encouragementStyle: "Positive",
                adaptations: []
            ),
            quirks: [],
            profile: PersonalityInsights(
                traits: [.intensityPreference: 0.8],
                communicationStyle: CommunicationProfile(
                    preferredTone: .energetic,
                    detailLevel: .moderate,
                    encouragementStyle: .cheerleader,
                    feedbackTiming: .immediate
                ),
                motivationalDrivers: [.achievement],
                stressResponses: [:],
                confidenceScores: [:],
                lastUpdated: Date()
            ),
            systemPrompt: "Test prompt",
            generatedAt: Date()
        )
    }
}