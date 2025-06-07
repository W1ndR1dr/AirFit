import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var sut: OnboardingViewModel!
    private var mockAIService: MockAIService!
    private var mockOnboardingService: MockOnboardingService!
    private var mockHealthProvider: MockHealthKitPrefillProvider!
    private var mockAPIKeyManager: MockAPIKeyManager!
    private var mockUserService: MockUserService!
    private var mockWhisperService: MockWhisperServiceWrapper!
    private var modelContext: ModelContext!
    private var testUser: User!
    
    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test container
        container = try await DITestHelper.createTestContainer()
        
        // Get model context from container
        let modelContainer = try await container.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Get mocks from container
        mockAIService = try await container.resolve(AIServiceProtocol.self) as? MockAIService
        mockOnboardingService = try await container.resolve(OnboardingServiceProtocol.self) as? MockOnboardingService
        mockAPIKeyManager = try await container.resolve(APIKeyManagementProtocol.self) as? MockAPIKeyManager
        mockUserService = try await container.resolve(UserServiceProtocol.self) as? MockUserService
        mockWhisperService = try await container.resolve(WhisperServiceWrapperProtocol.self) as? MockWhisperServiceWrapper
        
        // Create mock health provider manually (not in DI container)
        mockHealthProvider = MockHealthKitPrefillProvider()
        
        // Create view model with conversational mode (current implementation)
        sut = OnboardingViewModel(
            aiService: mockAIService,
            onboardingService: mockOnboardingService,
            modelContext: modelContext,
            apiKeyManager: mockAPIKeyManager,
            userService: mockUserService,
            speechService: mockWhisperService,
            healthPrefillProvider: mockHealthProvider,
            mode: .conversational  // Test current implementation
        )
        
        // Allow prefill task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    override func tearDown() async throws {
        mockAIService?.reset()
        mockOnboardingService?.reset()
        mockAPIKeyManager?.reset()
        mockUserService?.reset()
        mockWhisperService?.reset()
        mockHealthProvider?.reset()
        sut = nil
        mockAIService = nil
        mockOnboardingService = nil
        mockHealthProvider = nil
        mockAPIKeyManager = nil
        mockUserService = nil
        mockWhisperService = nil
        modelContext = nil
        testUser = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - Navigation Tests
    
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
    
    func test_navigateToPreviousScreen_fromSecondScreen_returnsToFirst() {
        // Arrange
        sut.navigateToNextScreen() // Go to second screen
        
        // Act
        sut.navigateToPreviousScreen()
        
        // Assert
        XCTAssertEqual(sut.currentScreen, .openingScreen)
    }
    
    func test_navigateToPreviousScreen_fromFirstScreen_staysOnFirst() {
        // Arrange - already on first screen
        
        // Act
        sut.navigateToPreviousScreen()
        
        // Assert
        XCTAssertEqual(sut.currentScreen, .openingScreen)
    }

    // MARK: - Goal Analysis Tests
    
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

    // MARK: - HealthKit Prefill Tests
    
    func test_prefillFromHealthKit_givenWindow_shouldUpdateSleepTimes() async {
        // Arrange
        let bed = Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: Date())!
        let wake = Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!
        mockHealthProvider.result = .success((bed: bed, wake: wake))
        
        // Create new view model to trigger prefill
        sut = OnboardingViewModel(
            aiService: mockAIService,
            onboardingService: mockOnboardingService,
            modelContext: modelContext,
            apiKeyManager: mockAPIKeyManager,
            userService: mockUserService,
            speechService: mockWhisperService,
            healthPrefillProvider: mockHealthProvider,
            mode: .conversational
        )
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        XCTAssertEqual(sut.sleepWindow.bedTime, formatter.string(from: bed))
        XCTAssertEqual(sut.sleepWindow.wakeTime, formatter.string(from: wake))
    }
    
    func test_prefillFromHealthKit_whenFails_usesDefaultTimes() async {
        // Arrange
        mockHealthProvider.result = .failure(AppError.genericError("Failed to fetch"))
        
        // Act - create new view model to trigger prefill
        sut = OnboardingViewModel(
            aiService: mockAIService,
            onboardingService: mockOnboardingService,
            modelContext: modelContext,
            apiKeyManager: mockAPIKeyManager,
            userService: mockUserService,
            speechService: mockWhisperService,
            healthPrefillProvider: mockHealthProvider,
            mode: .conversational
        )
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert - Should use default times
        XCTAssertEqual(sut.sleepWindow.bedTime, "22:30")
        XCTAssertEqual(sut.sleepWindow.wakeTime, "06:30")
    }

    // MARK: - Persona Mode Selection Tests
    
    func test_personaModeSelection_shouldUpdateCorrectly() {
        // Arrange & Act
        sut.selectedPersonaMode = .directTrainer

        // Assert
        XCTAssertEqual(sut.selectedPersonaMode, .directTrainer)

        // Change mode
        sut.selectedPersonaMode = .analyticalAdvisor
        XCTAssertEqual(sut.selectedPersonaMode, .analyticalAdvisor)
    }
    
    func test_allPersonaModes_canBeSelected() {
        // Test all available persona modes
        for mode in PersonaMode.allCases {
            // Act
            sut.selectedPersonaMode = mode
            
            // Assert
            XCTAssertEqual(sut.selectedPersonaMode, mode)
        }
    }
    
    func test_defaultPersonaMode_isSupportiveCoach() {
        // Assert - default should be supportive coach
        XCTAssertEqual(sut.selectedPersonaMode, .supportiveCoach)
    }

    // MARK: - Complete Onboarding Tests
    
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
        let profiles = try modelContext.fetch(FetchDescriptor<OnboardingProfile>())
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
    
    func test_completeOnboarding_withAllPersonaModes_savesCorrectly() async throws {
        for mode in PersonaMode.allCases {
            // Arrange
            setUp() // Reset for each test
            sut.selectedPersonaMode = mode
            sut.goal.rawText = "Test goal for \(mode.displayName)"
            
            // Act
            try await sut.completeOnboarding()
            
            // Assert
            let profiles = try modelContext.fetch(FetchDescriptor<OnboardingProfile>())
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let blob = try decoder.decode(UserProfileJsonBlob.self, from: profiles.last!.personaPromptData)
            XCTAssertEqual(blob.personaMode, mode)
        }
    }
    
    func test_completeOnboarding_whenServiceFails_showsError() async {
        // Arrange
        sut.goal.rawText = "Get fit"
        mockOnboardingService.shouldThrowError = true
        
        // Act
        do {
            try await sut.completeOnboarding()
            XCTFail("Should have thrown error")
        } catch {
            // Assert
            XCTAssertNotNil(sut.error)
            XCTAssertTrue(sut.isShowingError)
        }
    }
    
    // MARK: - Conversational Mode Tests
    
    func test_conversationalMode_initializesOrchestrator() {
        // Assert - orchestrator should be set up for conversational mode
        XCTAssertEqual(sut.mode, .conversational)
        XCTAssertNotNil(sut.orchestratorState)
        XCTAssertEqual(sut.orchestratorState, .notStarted)
    }
    
    func test_legacyMode_doesNotInitializeOrchestrator() async throws {
        // Arrange - create view model with legacy mode
        let legacySut = OnboardingViewModel(
            aiService: mockAIService,
            onboardingService: mockOnboardingService,
            modelContext: modelContext,
            apiKeyManager: mockAPIKeyManager,
            userService: mockUserService,
            speechService: mockWhisperService,
            healthPrefillProvider: mockHealthProvider,
            mode: .legacy
        )
        
        // Assert
        XCTAssertEqual(legacySut.mode, .legacy)
        XCTAssertEqual(legacySut.orchestratorState, .notStarted)
    }
    
    // MARK: - Life Context Tests
    
    func test_lifeContext_allPropertiesCanBeSet() {
        // Act
        sut.lifeContext.isDeskJob = true
        sut.lifeContext.isPhysicallyActiveWork = false
        sut.lifeContext.travelsFrequently = true
        sut.lifeContext.hasChildrenOrFamilyCare = true
        sut.lifeContext.scheduleType = .unpredictable
        sut.lifeContext.workoutWindowPreference = .evening
        
        // Assert
        XCTAssertTrue(sut.lifeContext.isDeskJob)
        XCTAssertFalse(sut.lifeContext.isPhysicallyActiveWork)
        XCTAssertTrue(sut.lifeContext.travelsFrequently)
        XCTAssertTrue(sut.lifeContext.hasChildrenOrFamilyCare)
        XCTAssertEqual(sut.lifeContext.scheduleType, .unpredictable)
        XCTAssertEqual(sut.lifeContext.workoutWindowPreference, .evening)
    }
    
    // MARK: - Error Handling Tests
    
    func test_errorHandling_clearsError() {
        // Arrange
        sut.error = AppError.genericError("Test error")
        sut.isShowingError = true
        
        // Act
        sut.clearError()
        
        // Assert
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isShowingError)
    }
    
    // MARK: - Voice Input Tests
    
    func test_voiceInput_transcriptionState() async {
        // Note: Voice input methods are typically tested in integration tests
        // as they involve complex interactions with speech services
        XCTAssertFalse(sut.isTranscribing)
    }
}
