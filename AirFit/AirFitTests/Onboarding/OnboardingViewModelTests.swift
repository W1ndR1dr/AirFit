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

    override func setUp() async throws {
        try await super.setUp()
        modelContainer = try ModelContainer.createTestContainer()
        context = modelContainer.mainContext
        mockAIService = MockAIService()
        mockOnboardingService = MockOnboardingService()
        mockHealthProvider = MockHealthKitPrefillProvider()
        sut = OnboardingViewModel(
            aiService: mockAIService,
            onboardingService: mockOnboardingService,
            modelContext: context,
            speechService: nil,
            healthPrefillProvider: mockHealthProvider
        )
        // Allow prefill task to complete
        try await Task.sleep(nanoseconds: 100_000_000)
    }

    override func tearDown() async throws {
        sut = nil
        mockHealthProvider = nil
        mockOnboardingService = nil
        mockAIService = nil
        context = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Navigation
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
    func test_analyzeGoalText_givenValidText_shouldStoreStructuredGoal() async {
        // Arrange
        sut.goal.rawText = "run a marathon"
        mockAIService.analyzeGoalResult = .success(.mock)

        // Act
        await sut.analyzeGoalText()

        // Assert
        XCTAssertTrue(mockAIService.analyzeGoalCalled)
        XCTAssertEqual(sut.structuredGoal?.goalType, StructuredGoal.mock.goalType)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func test_analyzeGoalText_givenEmptyText_shouldNotCallService() async {
        // Arrange
        sut.goal.rawText = "  "

        // Act
        await sut.analyzeGoalText()

        // Assert
        XCTAssertFalse(mockAIService.analyzeGoalCalled)
        XCTAssertNil(sut.structuredGoal)
    }

    // MARK: - HealthKit Prefill
    func test_prefillFromHealthKit_givenWindow_shouldUpdateSleepTimes() async {
        // Arrange
        let bed = Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: Date())!
        let wake = Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!
        mockHealthProvider.result = .success((bed: bed, wake: wake))
        sut = OnboardingViewModel(
            aiService: mockAIService,
            onboardingService: mockOnboardingService,
            modelContext: context,
            speechService: nil,
            healthPrefillProvider: mockHealthProvider
        )
        try await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        XCTAssertEqual(sut.sleepWindow.bedTime, formatter.string(from: bed))
        XCTAssertEqual(sut.sleepWindow.wakeTime, formatter.string(from: wake))
    }

    // MARK: - Blend Validation
    func test_validateBlend_shouldNormalizeValues() {
        // Arrange
        sut.blend.authoritativeDirect = 0.5
        sut.blend.encouragingEmpathetic = 0.5
        sut.blend.analyticalInsightful = 0.5
        sut.blend.playfullyProvocative = 0.5

        // Act
        sut.validateBlend()

        // Assert
        let total = sut.blend.authoritativeDirect + sut.blend.encouragingEmpathetic +
                   sut.blend.analyticalInsightful + sut.blend.playfullyProvocative
        XCTAssertEqual(total, 1.0, accuracy: 0.0001)
        XCTAssertTrue(sut.blend.isValid)
    }

    // MARK: - Complete Onboarding
    func test_completeOnboarding_shouldSaveProfileWithCorrectJSON() async throws {
        // Arrange
        sut.lifeContext.isDeskJob = true
        sut.goal.family = .performance
        sut.goal.rawText = "Run a marathon"
        sut.blend = Blend(
            authoritativeDirect: 0.4,
            encouragingEmpathetic: 0.3,
            analyticalInsightful: 0.2,
            playfullyProvocative: 0.1
        )
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
        XCTAssertEqual(blob.blend.playfullyProvocative, 0.1, accuracy: 0.001)
        XCTAssertEqual(blob.timezone, "UTC")
        XCTAssertFalse(blob.baselineModeEnabled)
    }
}
