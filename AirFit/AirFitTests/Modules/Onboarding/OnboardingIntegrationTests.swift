import XCTest
import SwiftData
@testable import AirFit

// MARK: - App State Integration Tests
@MainActor
final class OnboardingAppStateIntegrationTests: XCTestCase {
    var container: ModelContainer!
    var modelContext: ModelContext!
    var appState: AppState!
    var onboardingService: OnboardingService!

    override func setUp() async throws {
        try super.setUp()
        
        container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        appState = AppState(modelContext: context)
        onboardingService = OnboardingService(modelContext: context)
    }

    override func tearDown() async throws {
        container = nil
        modelContext = nil
        appState = nil
        onboardingService = nil
        try super.tearDown()
    }

    func test_appState_withNoUser_shouldShowWelcome() async throws {
        // Arrange - Fresh app state with no users
        await appState.loadUserState()

        // Assert
        XCTAssertTrue(appState.shouldCreateUser)
        XCTAssertFalse(appState.shouldShowOnboarding)
        XCTAssertFalse(appState.shouldShowDashboard)
        XCTAssertFalse(appState.isLoading)
    }

    func test_appState_withUserButNoProfile_shouldShowOnboarding() async throws {
        // Arrange
        try await appState.createNewUser()
        await appState.loadUserState()

        // Assert
        XCTAssertFalse(appState.shouldCreateUser)
        XCTAssertTrue(appState.shouldShowOnboarding)
        XCTAssertFalse(appState.shouldShowDashboard)
        XCTAssertNotNil(appState.currentUser)
    }

    func test_appState_withCompletedOnboarding_shouldShowDashboard() async throws {
        // Arrange
        try await appState.createNewUser()

        // Create and save onboarding profile
        let profileBlob = UserProfileJsonBlob(
            lifeContext: LifeContext(),
            goal: Goal(family: .healthWellbeing, rawText: "Lose 10 pounds"),
            personaMode: .supportiveCoach,
            engagementPreferences: EngagementPreferences(),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(),
            timezone: "America/New_York",
            baselineModeEnabled: true
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(profileBlob)

        let profile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data
        )

        try await onboardingService.saveProfile(profile)
        await appState.loadUserState()

        // Assert
        XCTAssertFalse(appState.shouldCreateUser)
        XCTAssertFalse(appState.shouldShowOnboarding)
        XCTAssertTrue(appState.shouldShowDashboard)
        XCTAssertTrue(appState.hasCompletedOnboarding)
    }
}

// MARK: - Service Integration Tests
@MainActor
final class OnboardingServiceIntegrationTests: XCTestCase {
    var container: ModelContainer!
    var modelContext: ModelContext!
    var appState: AppState!
    var onboardingService: OnboardingService!

    override func setUp() async throws {
        try super.setUp()
        
        container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        appState = AppState(modelContext: context)
        onboardingService = OnboardingService(modelContext: context)
    }

    override func tearDown() async throws {
        container = nil
        modelContext = nil
        appState = nil
        onboardingService = nil
        try super.tearDown()
    }

    func test_onboardingService_saveProfile_shouldValidateRequiredFields() async throws {
        // Arrange
        try await appState.createNewUser()

        let incompleteBlob = ["incomplete": "data"]
        let data = try JSONSerialization.data(withJSONObject: incompleteBlob)

        let profile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data
        )

        // Act & Assert
        do {
            try await onboardingService.saveProfile(profile)
            XCTFail("Should have thrown validation error")
        } catch let error as OnboardingError {
            switch error {
            case .missingRequiredField(let field):
                let requiredFields = [
                    "life_context", "goal", "blend", "engagement_preferences",
                    "sleep_window", "motivational_style", "timezone"
                ]
                XCTAssertTrue(requiredFields.contains(field))
            case .invalidProfileData:
                // This is also acceptable since the validation catches missing fields
                // and re-throws as invalidProfileData
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    func test_onboardingService_saveProfile_shouldLinkToUser() async throws {
        // Arrange
        try await appState.createNewUser()
        guard let user = appState.currentUser else {
            XCTFail("User should exist")
            return
        }

        let profileBlob = UserProfileJsonBlob(
            lifeContext: LifeContext(),
            goal: Goal(family: .healthWellbeing, rawText: "Test goal"),
            personaMode: .supportiveCoach,
            engagementPreferences: EngagementPreferences(),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(),
            timezone: "UTC",
            baselineModeEnabled: true
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(profileBlob)

        let profile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data
        )

        // Act
        try await onboardingService.saveProfile(profile)

        // Assert
        XCTAssertNotNil(user.onboardingProfile)
        XCTAssertEqual(user.onboardingProfile?.id, profile.id)
        XCTAssertEqual(profile.user?.id, user.id)
    }
}

// MARK: - JSON Structure Tests
@MainActor
final class OnboardingJSONStructureTests: XCTestCase {

    func test_userProfileJsonBlob_shouldMatchSystemPromptRequirements() throws {
        // Arrange
        let profileBlob = createTestProfileBlob()

        // Act
        let jsonObject = try encodeProfileToJSON(profileBlob)

        // Assert
        verifyRequiredFields(in: jsonObject)
        verifyNestedStructure(in: jsonObject)
    }

    // MARK: - Helper Methods
    private func createTestProfileBlob() -> UserProfileJsonBlob {
        UserProfileJsonBlob(
            lifeContext: LifeContext(
                isDeskJob: true,
                isPhysicallyActiveWork: false,
                travelsFrequently: false,
                hasChildrenOrFamilyCare: true,
                scheduleType: .predictable,
                workoutWindowPreference: .earlyBird
            ),
            goal: Goal(
                family: .healthWellbeing,
                rawText: "I want to lose 15 pounds for my wedding"
            ),
            personaMode: .analyticalAdvisor,
            engagementPreferences: EngagementPreferences(
                trackingStyle: .dataDrivenPartnership,
                informationDepth: .detailed,
                updateFrequency: .daily
            ),
            sleepWindow: SleepWindow(
                bedTime: "22:30",
                wakeTime: "06:30",
                consistency: .consistent
            ),
            motivationalStyle: MotivationalStyle(
                celebrationStyle: .enthusiasticCelebratory,
                absenceResponse: .gentleNudge
            ),
            timezone: "America/New_York",
            baselineModeEnabled: true
        )
    }

    private func encodeProfileToJSON(_ profileBlob: UserProfileJsonBlob) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(profileBlob)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    private func verifyRequiredFields(in jsonObject: [String: Any]) {
        XCTAssertNotNil(jsonObject["life_context"])
        XCTAssertNotNil(jsonObject["goal"])
        XCTAssertNotNil(jsonObject["persona_mode"])
        XCTAssertNotNil(jsonObject["engagement_preferences"])
        XCTAssertNotNil(jsonObject["sleep_window"])
        XCTAssertNotNil(jsonObject["motivational_style"])
        XCTAssertNotNil(jsonObject["timezone"])
    }

    private func verifyNestedStructure(in jsonObject: [String: Any]) {
        let lifeContext = jsonObject["life_context"] as? [String: Any]
        XCTAssertNotNil(lifeContext?["is_desk_job"])
        XCTAssertNotNil(lifeContext?["workout_window_preference"])

        let goal = jsonObject["goal"] as? [String: Any]
        XCTAssertNotNil(goal?["family"])
        XCTAssertNotNil(goal?["raw_text"])

        let blend = jsonObject["blend"] as? [String: Any]
        XCTAssertNotNil(blend?["authoritative_direct"])
        XCTAssertNotNil(blend?["encouraging_empathetic"])
        XCTAssertNotNil(blend?["analytical_insightful"])
        XCTAssertNotNil(blend?["playfully_provocative"])
    }
}

// MARK: - Flow Integration Tests
@MainActor
final class OnboardingFlowIntegrationTests: XCTestCase {
    var container: ModelContainer!
    var modelContext: ModelContext!
    var appState: AppState!
    var onboardingService: OnboardingService!

    override func setUp() async throws {
        try super.setUp()
        
        container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        appState = AppState(modelContext: context)
        onboardingService = OnboardingService(modelContext: context)
    }

    override func tearDown() async throws {
        container = nil
        modelContext = nil
        appState = nil
        onboardingService = nil
        try super.tearDown()
    }

    func test_completeOnboardingFlow_shouldTransitionToDashboard() async throws {
        // Arrange
        try await appState.createNewUser()

        let mockAPIKeyManager = MockAPIKeyManager()
        let mockUserService = MockUserService()
        
        let viewModel = OnboardingViewModel(
            aiService: MockAIService(),
            onboardingService: onboardingService,
            modelContext: context,
            apiKeyManager: mockAPIKeyManager,
            userService: mockUserService
        )

        // Set up complete profile data
        viewModel.lifeContext = LifeContext(
            isDeskJob: true,
            isPhysicallyActiveWork: false,
            travelsFrequently: false,
            hasChildrenOrFamilyCare: false,
            scheduleType: .predictable,
            workoutWindowPreference: .earlyBird
        )
        viewModel.goal = Goal(family: .healthWellbeing, rawText: "Lose weight for health")
        viewModel.selectedPersonaMode = .supportiveCoach
        viewModel.engagementPreferences = EngagementPreferences(
            trackingStyle: .dataDrivenPartnership,
            informationDepth: .detailed,
            updateFrequency: .daily
        )
        viewModel.sleepWindow = SleepWindow(
            bedTime: "22:00",
            wakeTime: "06:00",
            consistency: .consistent
        )
        viewModel.motivationalStyle = MotivationalStyle(
            celebrationStyle: .enthusiasticCelebratory,
            absenceResponse: .gentleNudge
        )

        var completionCalled = false
        viewModel.onCompletionCallback = {
            completionCalled = true
        }

        // Act
        try await viewModel.completeOnboarding()
        await appState.loadUserState()

        // Assert
        XCTAssertTrue(completionCalled)
        XCTAssertTrue(appState.shouldShowDashboard)
        XCTAssertFalse(appState.shouldShowOnboarding)
        XCTAssertNotNil(appState.currentUser?.onboardingProfile)
    }
}
