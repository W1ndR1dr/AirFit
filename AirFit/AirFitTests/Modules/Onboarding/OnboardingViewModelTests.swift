import XCTest
import SwiftData
@testable import AirFit

@MainActor

final class OnboardingViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var context: ModelContext!
    var mockAIService: MockAIService!
    var mockOnboardingService: MockOnboardingService!
    var mockHealthProvider: MockHealthKitPrefillProvider!
    var sut: OnboardingViewModel!
    var mockAPIKeyManager: MockAPIKeyManager!
    var mockUserService: MockUserService!

    override func setUp() async throws {
        try await super.setUp()
        
        modelContainer = try ModelContainer.createTestContainer()
        context = modelContainer.mainContext
        mockAIService = MockAIService()
        mockOnboardingService = MockOnboardingService(modelContext: context)
        mockHealthProvider = MockHealthKitPrefillProvider()
        mockAPIKeyManager = MockAPIKeyManager()
        mockUserService = MockUserService()
        sut = OnboardingViewModel(
            aiService: mockAIService,
            onboardingService: mockOnboardingService,
            modelContext: context,
            apiKeyManager: mockAPIKeyManager,
            userService: mockUserService,
            speechService: nil,
            healthPrefillProvider: mockHealthProvider,
            mode: .legacy  // Test legacy mode to test the blend functionality
        )
        // Allow prefill task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    override func tearDown() async throws {
        sut = nil
        mockUserService = nil
        mockAPIKeyManager = nil
        mockHealthProvider = nil
        mockOnboardingService = nil
        mockAIService = nil
        context = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Navigation
        @MainActor
        func test_navigationFlow_shouldTraverseAllScreens() {
        // Arrange
        var visited: [OnboardingScreen] = [sut.currentScreen]

        // Act
        for _ in 0..<8 { // total 9 screens
            sut.navigateToNextScreen()
            visited.append(sut.currentScreen)
        }
        sut.navigateToNextScreen() // Should not go past last

        // Assert
        XCTAssertEqual(visited.first, .openingScreen)
        XCTAssertEqual(visited.last, .coachProfileReady)
        XCTAssertEqual(sut.currentScreen, .coachProfileReady)
        XCTAssertEqual(visited.count, 9)
    }

    // MARK: - Goal Analysis
        @MainActor
        func test_analyzeGoalText_givenValidText_shouldLogGoalText() async {
        // Arrange
        sut.goal.rawText = "run a marathon"

        // Act
        await sut.analyzeGoalText()

        // Assert
        // The current implementation just logs the goal text
        // Goal analysis is handled by the AI coach after onboarding completion
        XCTAssertEqual(sut.goal.rawText, "run a marathon")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

        @MainActor

        func test_analyzeGoalText_givenEmptyText_shouldStillWork() async {
        // Arrange
        sut.goal.rawText = "  "

        // Act
        await sut.analyzeGoalText()

        // Assert
        // The method should work even with empty text
        XCTAssertEqual(sut.goal.rawText, "  ")
        XCTAssertNil(sut.error)
    }

    // MARK: - HealthKit Prefill
        @MainActor
        func test_prefillFromHealthKit_givenWindow_shouldUpdateSleepTimes() async {
        // Arrange
        let bed = Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: Date())!
        let wake = Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!
        mockHealthProvider.result = .success((bed: bed, wake: wake))
        sut = OnboardingViewModel(
            aiService: mockAIService,
            onboardingService: mockOnboardingService,
            modelContext: context,
            apiKeyManager: mockAPIKeyManager,
            userService: mockUserService,
            speechService: nil,
            healthPrefillProvider: mockHealthProvider,
            mode: .legacy
        )
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        XCTAssertEqual(sut.sleepWindow.bedTime, formatter.string(from: bed))
        XCTAssertEqual(sut.sleepWindow.wakeTime, formatter.string(from: wake))
    }

    // MARK: - Persona Mode Selection
        @MainActor
        func test_personaModeSelection_shouldUpdateCorrectly() {
        // Arrange & Act
        sut.selectedPersonaMode = .directTrainer

        // Assert
        XCTAssertEqual(sut.selectedPersonaMode, .directTrainer)

        // Change mode
        sut.selectedPersonaMode = .analyticalAdvisor
        XCTAssertEqual(sut.selectedPersonaMode, .analyticalAdvisor)
    }

    // MARK: - Complete Onboarding
        @MainActor
        func test_completeOnboarding_shouldSaveProfileWithCorrectJSON() async throws {
        // Arrange
        sut.lifeContext.isDeskJob = true
        sut.goal.family = .performance
        sut.goal.rawText = "Run a marathon"
        sut.selectedPersonaMode = .directTrainer
        sut.engagementPreferences.trackingStyle = .guidanceOnDemand
        sut.sleepWindow.bedTime = "23:00"
        sut.sleepWindow.wakeTime = "07:00"
        sut.motivationalStyle.celebrationStyle = .enthusiasticCelebratory
        sut.motivationalStyle.absenceResponse = .respectSpace
        sut.timezone = "UTC"
        sut.baselineModeEnabled = false

        // Act
        try await sut.completeOnboarding()

        // Assert
        XCTAssertTrue(mockOnboardingService.saveProfileCalled)
        let profiles = try context.fetch(FetchDescriptor<OnboardingProfile>())
        XCTAssertEqual(profiles.count, 1)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let blob = try decoder.decode(UserProfileJsonBlob.self, from: profiles.first!.personaPromptData)
        XCTAssertEqual(blob.lifeContext.isDeskJob, true)
        XCTAssertEqual(blob.goal.family, .performance)
        XCTAssertEqual(blob.personaMode, .directTrainer)
        XCTAssertEqual(blob.timezone, "UTC")
        XCTAssertFalse(blob.baselineModeEnabled)
    }
}
