import XCTest
import XCUIAutomation

@MainActor
final class OnboardingFlowUITests: XCTestCase {
    var app: XCUIApplication!
    var onboardingPage: OnboardingPage!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-onboarding"]
        app.launch()
        onboardingPage = OnboardingPage(app: app)
    }

    override func tearDown() async throws {
        app = nil
        onboardingPage = nil
    }

    func test_completeOnboardingFlow_happyPath() async throws {
        // Start onboarding
        await onboardingPage.tapElement(onboardingPage.beginButton)

        // Life Snapshot Screen
        let lifeSnapshotExists = await onboardingPage.waitForElement(onboardingPage.lifeSnapshotScreen)
        XCTAssertTrue(lifeSnapshotExists)
        await onboardingPage.selectLifeSnapshotOptions()
        await onboardingPage.tapNextButton()

        // Core Aspiration Screen
        let goalScreenExists = await onboardingPage.waitForElement(onboardingPage.goalScreen)
        XCTAssertTrue(goalScreenExists)
        await onboardingPage.enterGoalText("I want to lose 20 pounds and build muscle")
        await onboardingPage.selectGoalFamily(.weightLoss)
        await onboardingPage.tapNextButton()

        // Coaching Style Screen
        let coachingStyleExists = await onboardingPage.waitForCoachingStyleScreen()
        XCTAssertTrue(coachingStyleExists)
        await onboardingPage.adjustSlider("onboarding.blend.authoritative", to: 0.3)
        await onboardingPage.adjustSlider("onboarding.blend.encouraging", to: 0.4)
        await onboardingPage.adjustSlider("onboarding.blend.analytical", to: 0.2)
        await onboardingPage.adjustSlider("onboarding.blend.playful", to: 0.1)
        await onboardingPage.tapNextButton()

        // Engagement Preferences Screen
        let engagementExists = await onboardingPage.waitForEngagementPreferencesScreen()
        XCTAssertTrue(engagementExists)
        await onboardingPage.selectEngagementCard("onboarding.engagement.detailed")
        await onboardingPage.selectRadioOption("onboarding.engagement.daily")
        await onboardingPage.toggleAutoRecovery(true)
        await onboardingPage.tapNextButton()

        // Sleep Boundaries Screen
        let sleepExists = await onboardingPage.waitForSleepBoundariesScreen()
        XCTAssertTrue(sleepExists)
        await onboardingPage.adjustTimeSlider("onboarding.sleep.bedtime", to: 0.8)
        await onboardingPage.adjustTimeSlider("onboarding.sleep.waketime", to: 0.3)
        await onboardingPage.tapNextButton()

        // Motivational Accents Screen
        let motivationExists = await onboardingPage.waitForMotivationalAccentsScreen()
        XCTAssertTrue(motivationExists)
        await onboardingPage.selectMotivationOption("onboarding.motivation.gentle")
        await onboardingPage.tapNextButton()

        // Generating Coach Screen
        let generatingExists = await onboardingPage.waitForGeneratingCoachScreen()
        XCTAssertTrue(generatingExists)

        // Coach Ready Screen
        let coachReadyExists = await onboardingPage.coachReadyScreen.waitForExistence(timeout: 15)
        XCTAssertTrue(coachReadyExists)
        await onboardingPage.tapBeginCoachButton()

        // Verify navigation to dashboard
        let dashboardExists = await onboardingPage.isOnDashboard()
        XCTAssertTrue(dashboardExists)
    }

    func test_cardSelection_updatesState() async throws {
        let cardId = "onboarding.engagement.detailed"
        await onboardingPage.selectEngagementCard(cardId)
        let isSelected = app.buttons[cardId].isSelected
        let hasCheckmark = app.buttons[cardId].images["checkmark.circle.fill"].exists
        XCTAssertTrue(isSelected || hasCheckmark)
    }

    func test_sliderAdjustment_updatesValue() async throws {
        let sliderId = "onboarding.blend.authoritative"
        let slider = app.sliders[sliderId]
        let initialValue = slider.value as? String
        await onboardingPage.adjustSlider(sliderId, to: 0.7)
        let newValue = slider.value as? String
        XCTAssertNotEqual(initialValue, newValue)
    }

    func test_voiceButton_isAccessible() async throws {
        XCTAssertTrue(onboardingPage.voiceButton.exists)
        await onboardingPage.tapElement(onboardingPage.voiceButton)
        XCTAssertTrue(onboardingPage.voiceButton.exists)
    }

    func test_backNavigation_worksCorrectly() async throws {
        await onboardingPage.tapElement(onboardingPage.beginButton)
        let lifeSnapshotExists = await onboardingPage.waitForElement(onboardingPage.lifeSnapshotScreen)
        XCTAssertTrue(lifeSnapshotExists)
        await onboardingPage.tapNextButton()

        let goalScreenExists = await onboardingPage.waitForElement(onboardingPage.goalScreen)
        XCTAssertTrue(goalScreenExists)
        await onboardingPage.tapBackButton()

        let backToLifeSnapshot = await onboardingPage.waitForElement(onboardingPage.lifeSnapshotScreen)
        XCTAssertTrue(backToLifeSnapshot)
    }

    func test_endToEndFlow_completesSuccessfully() async throws {
        await onboardingPage.tapElement(onboardingPage.beginButton)

        // Complete minimal flow
        let lifeSnapshotExists = await onboardingPage.waitForElement(onboardingPage.lifeSnapshotScreen)
        XCTAssertTrue(lifeSnapshotExists)
        await onboardingPage.tapNextButton()

        let goalScreenExists = await onboardingPage.waitForElement(onboardingPage.goalScreen)
        XCTAssertTrue(goalScreenExists)
        await onboardingPage.enterGoalText("Get fit")
        await onboardingPage.tapNextButton()

        // Skip through remaining screens quickly
        for _ in 0..<4 {
            await onboardingPage.tapNextButton()
        }

        let coachReadyExists = await onboardingPage.coachReadyScreen.waitForExistence(timeout: 15)
        XCTAssertTrue(coachReadyExists)
        await onboardingPage.tapBeginCoachButton()

        let dashboardExists = await onboardingPage.isOnDashboard()
        XCTAssertTrue(dashboardExists)
    }
}
