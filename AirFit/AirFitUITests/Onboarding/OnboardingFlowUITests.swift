import XCTest

final class OnboardingFlowUITests: XCTestCase {
    var app: XCUIApplication!
    var onboardingPage: OnboardingPage!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-onboarding"]
        app.launch()
        onboardingPage = OnboardingPage(app: app)
    }

    override func tearDownWithError() throws {
        onboardingPage = nil
        app = nil
    }

    func test_completeOnboardingFlow_happyPath() throws {
        // Opening Screen
        onboardingPage.verifyOnOpeningScreen()
        onboardingPage.tapBegin()

        // Life Snapshot
        onboardingPage.verifyOnLifeSnapshot()
        onboardingPage.selectLifeOption("onboarding.life.desk_job")
        onboardingPage.selectWorkoutOption("onboarding.life.workout_early_bird")
        onboardingPage.tapNext()

        // Core Aspiration
        onboardingPage.verifyOnCoreAspiration()
        onboardingPage.selectPredefinedGoal("onboarding.goal.strength_tone")
        onboardingPage.enterGoalText("Gain strength")
        onboardingPage.tapNext()

        // Coaching Style
        onboardingPage.verifyOnCoachingStyle()
        onboardingPage.adjustSlider("onboarding.blend.analytical.slider", to: 0.8)
        onboardingPage.tapNext()

        // Engagement Preferences
        onboardingPage.verifyOnEngagementPreferences()
        onboardingPage.selectEngagementCard("onboarding.engagement.guidance")
        onboardingPage.tapNext()

        // Sleep & Boundaries
        onboardingPage.verifyOnSleepBoundaries()
        onboardingPage.adjustTimeSlider("onboarding.sleep.bedtime.slider", to: 0.5)
        onboardingPage.tapNext()

        // Motivational Accents
        onboardingPage.verifyOnMotivationalAccents()
        onboardingPage.selectMotivationOption("onboarding.motivation.celebration.subtle_affirming")
        onboardingPage.selectMotivationOption("onboarding.motivation.absence.respect_space")
        onboardingPage.tapNext()

        // Generating Coach
        onboardingPage.verifyOnGeneratingCoach()
        XCTAssertTrue(onboardingPage.coachReadyScreen.waitForExistence(timeout: 15))
        onboardingPage.verifyCoachProfileReady()
    }

    func test_cardSelection_interaction() throws {
        onboardingPage.tapBegin()
        onboardingPage.verifyOnLifeSnapshot()
        onboardingPage.tapNext()
        onboardingPage.verifyOnCoreAspiration()

        let cardId = "onboarding.goal.performance"
        onboardingPage.selectPredefinedGoal(cardId)
        XCTAssertTrue(app.buttons[cardId].isSelected || app.buttons[cardId].images["checkmark.circle.fill"].exists)
    }

    func test_sliderAdjustment_updatesValue() throws {
        onboardingPage.tapBegin()
        onboardingPage.tapNext()
        onboardingPage.verifyOnCoreAspiration()
        onboardingPage.tapNext()
        onboardingPage.verifyOnCoachingStyle()

        let sliderId = "onboarding.blend.authoritative.slider"
        let slider = app.sliders[sliderId]
        let initialValue = slider.value as? String
        onboardingPage.adjustSlider(sliderId, to: 0.7)
        let newValue = slider.value as? String
        XCTAssertNotEqual(initialValue, newValue)
    }

    func test_voiceInputButton_exists() throws {
        onboardingPage.tapBegin()
        onboardingPage.tapNext()
        onboardingPage.verifyOnCoreAspiration()

        XCTAssertTrue(onboardingPage.voiceButton.exists)
        onboardingPage.tapVoiceButton()
        XCTAssertTrue(onboardingPage.voiceButton.exists)
    }

    func test_profileGeneration_completes() throws {
        onboardingPage.tapBegin()
        onboardingPage.tapNext()
        onboardingPage.tapNext()
        onboardingPage.tapNext()
        onboardingPage.tapNext()
        onboardingPage.tapNext()
        onboardingPage.tapNext()

        onboardingPage.verifyOnGeneratingCoach()
        XCTAssertTrue(onboardingPage.coachReadyScreen.waitForExistence(timeout: 15))
        onboardingPage.verifyCoachProfileReady()
    }
}
