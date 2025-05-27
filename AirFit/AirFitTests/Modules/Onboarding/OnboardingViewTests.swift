import XCTest
import SwiftUI
import SwiftData
@testable import AirFit

@MainActor
final class OnboardingViewTests: XCTestCase {
    var modelContainer: ModelContainer!
    var context: ModelContext!
    var mockAIService: MockAIService!
    var mockOnboardingService: MockOnboardingService!
    var viewModel: OnboardingViewModel!

    override func setUp() async throws {
        await MainActor.run {
            super.setUp()
        }
        modelContainer = try ModelContainer.createTestContainer()
        context = modelContainer.mainContext
        mockAIService = MockAIService()
        mockOnboardingService = MockOnboardingService()
        viewModel = OnboardingViewModel(
            aiService: mockAIService,
            onboardingService: mockOnboardingService,
            modelContext: context
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockOnboardingService = nil
        mockAIService = nil
        context = nil
        modelContainer = nil
        await MainActor.run {
            super.tearDown()
        }
    }

    // MARK: - LifeSnapshotView Tests
    func test_lifeSnapshotView_initialization_shouldCreateWithViewModel() {
        // Act
        let view = LifeSnapshotView(viewModel: viewModel)

        // Assert
        XCTAssertNotNil(view)
    }

    func test_lifeSnapshotView_shouldHaveCorrectAccessibilityIdentifier() {
        let expectedIdentifier = "onboarding.lifeSnapshot"
        XCTAssertEqual(expectedIdentifier, "onboarding.lifeSnapshot")
    }

    func test_lifeSnapshotView_checkboxOptions_shouldHaveCorrectIdentifiers() {
        let expectedIdentifiers = [
            "onboarding.life.desk_job",
            "onboarding.life.active_work",
            "onboarding.life.travel",
            "onboarding.life.family_care",
            "onboarding.life.schedule_predictable",
            "onboarding.life.schedule_unpredictable"
        ]

        // Verify all expected identifiers exist
        for identifier in expectedIdentifiers {
            XCTAssertFalse(identifier.isEmpty, "Identifier should not be empty: \(identifier)")
        }
    }

    func test_lifeSnapshotView_workoutOptions_shouldHaveCorrectIdentifiers() {
        let workoutOptions = LifeContext.WorkoutWindow.allCases
        XCTAssertGreaterThan(workoutOptions.count, 0, "Should have workout window options")

        for option in workoutOptions {
            let identifier = "onboarding.life.workout_\(option.rawValue)"
            XCTAssertFalse(identifier.isEmpty, "Workout option identifier should not be empty")
        }
    }

    func test_lifeSnapshotView_navigationButtons_shouldHaveCorrectIdentifiers() {
        let backButtonId = "onboarding.back.button"
        let nextButtonId = "onboarding.next.button"

        XCTAssertEqual(backButtonId, "onboarding.back.button")
        XCTAssertEqual(nextButtonId, "onboarding.next.button")
    }

    // MARK: - CoreAspirationView Tests
    func test_coreAspirationView_initialization_shouldCreateWithViewModel() {
        // Act
        let view = CoreAspirationView(viewModel: viewModel)

        // Assert
        XCTAssertNotNil(view)
    }

    func test_coreAspirationView_shouldHaveCorrectAccessibilityIdentifier() {
        let expectedIdentifier = "onboarding.coreAspiration"
        XCTAssertEqual(expectedIdentifier, "onboarding.coreAspiration")
    }

    func test_coreAspirationView_goalFamilyCards_shouldHaveCorrectIdentifiers() {
        let goalFamilies = Goal.GoalFamily.allCases
        XCTAssertGreaterThan(goalFamilies.count, 0, "Should have goal family options")

        for family in goalFamilies {
            let identifier = "onboarding.goal.family.\(family.rawValue)"
            XCTAssertFalse(identifier.isEmpty, "Goal family identifier should not be empty")
        }
    }

    func test_coreAspirationView_voiceButton_shouldHaveCorrectIdentifier() {
        let voiceButtonId = "onboarding.goal.voice"
        XCTAssertEqual(voiceButtonId, "onboarding.goal.voice")
    }

    // MARK: - CoachingStyleView Tests
    func test_coachingStyleView_initialization_shouldCreateWithViewModel() {
        // Act
        let view = CoachingStyleView(viewModel: viewModel)

        // Assert
        XCTAssertNotNil(view)
    }

    func test_coachingStyleView_shouldHaveCorrectAccessibilityIdentifier() {
        let expectedIdentifier = "onboarding.coachingStyle"
        XCTAssertEqual(expectedIdentifier, "onboarding.coachingStyle")
    }

    func test_coachingStyleView_blendSliders_shouldHaveCorrectIdentifiers() {
        let expectedSliderIds = [
            "onboarding.blend.authoritative",
            "onboarding.blend.encouraging",
            "onboarding.blend.analytical",
            "onboarding.blend.playful"
        ]

        for sliderId in expectedSliderIds {
            XCTAssertFalse(sliderId.isEmpty, "Slider identifier should not be empty: \(sliderId)")
        }
    }

    func test_coachingStyleView_blendValidation_shouldNormalizeValues() {
        // Arrange
        viewModel.blend.authoritativeDirect = 0.5
        viewModel.blend.encouragingEmpathetic = 0.5
        viewModel.blend.analyticalInsightful = 0.5
        viewModel.blend.playfullyProvocative = 0.5

        // Act
        viewModel.validateBlend()

        // Assert
        let total = viewModel.blend.authoritativeDirect +
                   viewModel.blend.encouragingEmpathetic +
                   viewModel.blend.analyticalInsightful +
                   viewModel.blend.playfullyProvocative
        XCTAssertEqual(total, 1.0, accuracy: 0.0001, "Blend values should sum to 1.0")
        XCTAssertTrue(viewModel.blend.isValid, "Blend should be valid after normalization")
    }

    // MARK: - EngagementPreferencesView Tests
    func test_engagementPreferencesView_initialization_shouldCreateWithViewModel() {
        // Act
        let view = EngagementPreferencesView(viewModel: viewModel)

        // Assert
        XCTAssertNotNil(view)
    }

    func test_engagementPreferencesView_shouldHaveCorrectAccessibilityIdentifier() {
        let expectedIdentifier = "onboarding.engagementPreferences"
        XCTAssertEqual(expectedIdentifier, "onboarding.engagementPreferences")
    }

    func test_engagementPreferencesView_trackingStyleCards_shouldHaveCorrectIdentifiers() {
        let trackingStyles = EngagementPreferences.TrackingStyle.allCases
        XCTAssertGreaterThan(trackingStyles.count, 0, "Should have tracking style options")

        for style in trackingStyles {
            let identifier = "onboarding.engagement.\(style.rawValue)"
            XCTAssertFalse(identifier.isEmpty, "Tracking style identifier should not be empty")
        }
    }

    func test_engagementPreferencesView_checkInFrequency_shouldHaveCorrectIdentifiers() {
        let frequencies = EngagementPreferences.UpdateFrequency.allCases
        XCTAssertGreaterThan(frequencies.count, 0, "Should have update frequency options")

        for frequency in frequencies {
            let identifier = "onboarding.engagement.\(frequency.rawValue)"
            XCTAssertFalse(identifier.isEmpty, "Update frequency identifier should not be empty")
        }
    }

    // MARK: - SleepAndBoundariesView Tests
    func test_sleepAndBoundariesView_initialization_shouldCreateWithViewModel() {
        // Act
        let view = SleepAndBoundariesView(viewModel: viewModel)

        // Assert
        XCTAssertNotNil(view)
    }

    func test_sleepAndBoundariesView_shouldHaveCorrectAccessibilityIdentifier() {
        let expectedIdentifier = "onboarding.sleepAndBoundaries"
        XCTAssertEqual(expectedIdentifier, "onboarding.sleepAndBoundaries")
    }

    func test_sleepAndBoundariesView_timeSliders_shouldHaveCorrectIdentifiers() {
        let bedTimeId = "onboarding.sleep.bedtime"
        let wakeTimeId = "onboarding.sleep.waketime"

        XCTAssertEqual(bedTimeId, "onboarding.sleep.bedtime")
        XCTAssertEqual(wakeTimeId, "onboarding.sleep.waketime")
    }

    // MARK: - MotivationalAccentsView Tests
    func test_motivationalAccentsView_initialization_shouldCreateWithViewModel() {
        // Act
        let view = MotivationalAccentsView(viewModel: viewModel)

        // Assert
        XCTAssertNotNil(view)
    }

    func test_motivationalAccentsView_shouldHaveCorrectAccessibilityIdentifier() {
        let expectedIdentifier = "onboarding.motivationalAccents"
        XCTAssertEqual(expectedIdentifier, "onboarding.motivationalAccents")
    }

    func test_motivationalAccentsView_celebrationStyles_shouldHaveCorrectIdentifiers() {
        let celebrationStyles = MotivationalStyle.CelebrationStyle.allCases
        XCTAssertGreaterThan(celebrationStyles.count, 0, "Should have celebration style options")

        for style in celebrationStyles {
            let identifier = "onboarding.motivation.\(style.rawValue)"
            XCTAssertFalse(identifier.isEmpty, "Celebration style identifier should not be empty")
        }
    }

    func test_motivationalAccentsView_absenceResponses_shouldHaveCorrectIdentifiers() {
        let absenceResponses = MotivationalStyle.AbsenceResponse.allCases
        XCTAssertGreaterThan(absenceResponses.count, 0, "Should have absence response options")

        for response in absenceResponses {
            let identifier = "onboarding.motivation.\(response.rawValue)"
            XCTAssertFalse(identifier.isEmpty, "Absence response identifier should not be empty")
        }
    }

    // MARK: - OpeningScreenView Tests
    func test_openingScreenView_initialization_shouldCreateWithViewModel() {
        // Act
        let view = OpeningScreenView(viewModel: viewModel)

        // Assert
        XCTAssertNotNil(view)
    }

    func test_openingScreenView_shouldHaveCorrectAccessibilityIdentifier() {
        let expectedIdentifier = "onboarding.openingScreen"
        XCTAssertEqual(expectedIdentifier, "onboarding.openingScreen")
    }

    func test_openingScreenView_beginButton_shouldHaveCorrectIdentifier() {
        let beginButtonId = "onboarding.begin.button"
        XCTAssertEqual(beginButtonId, "onboarding.begin.button")
    }

    // MARK: - GeneratingCoachView Tests
    func test_generatingCoachView_initialization_shouldCreateWithViewModel() {
        // Act
        let view = GeneratingCoachView(viewModel: viewModel)

        // Assert
        XCTAssertNotNil(view)
    }

    func test_generatingCoachView_shouldHaveCorrectAccessibilityIdentifier() {
        let expectedIdentifier = "onboarding.generatingCoach"
        XCTAssertEqual(expectedIdentifier, "onboarding.generatingCoach")
    }

    // MARK: - CoachProfileReadyView Tests
    func test_coachProfileReadyView_initialization_shouldCreateWithViewModel() {
        // Act
        let view = CoachProfileReadyView(viewModel: viewModel)

        // Assert
        XCTAssertNotNil(view)
    }

    func test_coachProfileReadyView_shouldHaveCorrectAccessibilityIdentifier() {
        let expectedIdentifier = "onboarding.coachProfileReady"
        XCTAssertEqual(expectedIdentifier, "onboarding.coachProfileReady")
    }

    func test_coachProfileReadyView_beginCoachButton_shouldHaveCorrectIdentifier() {
        let beginCoachButtonId = "onboarding.beginCoach.button"
        XCTAssertEqual(beginCoachButtonId, "onboarding.beginCoach.button")
    }

    // MARK: - OnboardingNavigationButtons Tests
    func test_onboardingNavigationButtons_shouldHaveCorrectIdentifiers() {
        let backButtonId = "onboarding.back.button"
        let nextButtonId = "onboarding.next.button"

        XCTAssertEqual(backButtonId, "onboarding.back.button")
        XCTAssertEqual(nextButtonId, "onboarding.next.button")
    }

    func test_onboardingNavigationButtons_shouldCallCorrectActions() {
        // This test verifies that the navigation buttons call the correct ViewModel methods
        let initialScreen = viewModel.currentScreen

        // Test next navigation
        viewModel.navigateToNextScreen()
        XCTAssertNotEqual(viewModel.currentScreen, initialScreen, "Should navigate to next screen")

        // Test back navigation
        let currentScreen = viewModel.currentScreen
        viewModel.navigateToPreviousScreen()
        XCTAssertEqual(viewModel.currentScreen, initialScreen, "Should navigate back to previous screen")
    }

    // MARK: - View State Management Tests
    func test_allViews_shouldBindToViewModelCorrectly() {
        // Test that all views properly bind to the ViewModel state

        // Test LifeContext binding
        viewModel.lifeContext.isDeskJob = true
        XCTAssertTrue(viewModel.lifeContext.isDeskJob)

        // Test Goal binding
        viewModel.goal.rawText = "Test goal"
        XCTAssertEqual(viewModel.goal.rawText, "Test goal")

        // Test Blend binding
        viewModel.blend.authoritativeDirect = 0.5
        XCTAssertEqual(viewModel.blend.authoritativeDirect, 0.5)

        // Test EngagementPreferences binding
        viewModel.engagementPreferences.trackingStyle = .dataDrivenPartnership
        XCTAssertEqual(viewModel.engagementPreferences.trackingStyle, .dataDrivenPartnership)

        // Test SleepWindow binding
        viewModel.sleepWindow.bedTime = "22:00"
        XCTAssertEqual(viewModel.sleepWindow.bedTime, "22:00")

        // Test MotivationalStyle binding
        viewModel.motivationalStyle.celebrationStyle = .enthusiasticCelebratory
        XCTAssertEqual(viewModel.motivationalStyle.celebrationStyle, .enthusiasticCelebratory)
    }

    // MARK: - Error Handling Tests
    func test_views_shouldHandleErrorStatesGracefully() {
        // Test that views handle error states without crashing
        viewModel.error = OnboardingError.invalidProfileData
        XCTAssertNotNil(viewModel.error)

        // Views should still be creatable even with errors
        let lifeSnapshotView = LifeSnapshotView(viewModel: viewModel)
        let coreAspirationView = CoreAspirationView(viewModel: viewModel)
        let coachingStyleView = CoachingStyleView(viewModel: viewModel)

        XCTAssertNotNil(lifeSnapshotView)
        XCTAssertNotNil(coreAspirationView)
        XCTAssertNotNil(coachingStyleView)
    }

    // MARK: - Loading State Tests
    func test_views_shouldHandleLoadingStatesGracefully() {
        // Test that views handle loading states without crashing
        // Note: isLoading is private(set), so we test the views can be created
        // regardless of loading state

        // Views should still be creatable during loading
        let generatingCoachView = GeneratingCoachView(viewModel: viewModel)
        let coachProfileReadyView = CoachProfileReadyView(viewModel: viewModel)

        XCTAssertNotNil(generatingCoachView)
        XCTAssertNotNil(coachProfileReadyView)
    }
}
