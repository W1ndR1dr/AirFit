import XCTest
import XCUIAutomation

enum GoalFamily: String {
    case weightLoss = "weight_loss"
    case strengthTone = "strength_tone"
    case performance = "performance"
    case wellness = "wellness"
}

/// Page object for interacting with the onboarding flow.
@MainActor
final class OnboardingPage: BasePage {
    // MARK: - Opening Screen
    var beginButton: XCUIElement {
        app.buttons["onboarding.begin.button"]
    }

    var skipButton: XCUIElement {
        app.buttons["onboarding.skip.button"]
    }

    func verifyOnOpeningScreen() async {
        await verifyElement(exists: beginButton)
        await verifyElement(exists: skipButton)
    }

    func tapBegin() async {
        await tapElement(beginButton)
    }

    // MARK: - Life Snapshot
    var lifeSnapshotScreen: XCUIElement {
        app.scrollViews["onboarding.lifeSnapshot"]
    }

    func verifyOnLifeSnapshot() async {
        await verifyElement(exists: lifeSnapshotScreen)
    }

    func selectLifeOption(_ optionId: String) async {
        let toggle = app.switches[optionId]
        await tapElement(toggle)
    }

    func selectWorkoutOption(_ option: String) async {
        let button = app.buttons[option]
        await tapElement(button)
    }

    // MARK: - Core Aspiration
    var coreAspirationScreen: XCUIElement {
        app.descendants(matching: .any)["onboarding.coreAspiration"]
    }

    var goalScreen: XCUIElement {
        app.scrollViews["onboarding.coreAspiration"]
    }

    func verifyOnCoreAspiration() async {
        await verifyElement(exists: coreAspirationScreen)
    }

    func selectPredefinedGoal(_ goal: String) async {
        let card = app.buttons[goal]
        await tapElement(card)
    }

    func selectGoalFamily(_ family: GoalFamily) async {
        let familyButton = app.buttons["onboarding.goal.family.\(family.rawValue)"]
        familyButton.tap()
    }

    func selectLifeSnapshotOptions() async {
        // Select some default life snapshot options
        app.buttons["onboarding.life.desk_job"].tap()
        app.buttons["onboarding.life.workout_early_bird"].tap()
    }

    var goalTextInput: XCUIElement {
        app.textFields["onboarding.goal.text"]
    }

    var voiceButton: XCUIElement {
        app.buttons["onboarding.goal.voice"]
    }

    func enterGoalText(_ text: String) async {
        await typeText(in: goalTextInput, text: text)
    }

    func tapVoiceButton() async {
        await tapElement(voiceButton)
    }

    // MARK: - Coaching Style
    var coachingStyleScreen: XCUIElement {
        app.descendants(matching: .any)["onboarding.coachingStyle"]
    }

    func verifyOnCoachingStyle() async {
        await verifyElement(exists: coachingStyleScreen)
    }

    func waitForCoachingStyleScreen() async -> Bool {
        await app.descendants(matching: .any)["onboarding.coachingStyle"].waitForExistence(timeout: timeout)
    }

    func adjustSlider(_ identifier: String, to position: CGFloat) async {
        let slider = app.sliders[identifier]
        let exists = await slider.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists)
        slider.adjust(toNormalizedSliderPosition: position)
    }

    // MARK: - Engagement Preferences
    var engagementScreen: XCUIElement {
        app.descendants(matching: .any)["onboarding.engagementPreferences"]
    }

    func verifyOnEngagementPreferences() async {
        await verifyElement(exists: engagementScreen)
    }

    func waitForEngagementPreferencesScreen() async -> Bool {
        await app.descendants(matching: .any)["onboarding.engagementPreferences"].waitForExistence(timeout: timeout)
    }

    func selectEngagementCard(_ id: String) async {
        let card = app.buttons[id]
        card.tap()
    }

    func selectRadioOption(_ id: String) async {
        let button = app.buttons[id]
        button.tap()
    }

    func toggleAutoRecovery(_ on: Bool) async {
        let toggle = app.switches["onboarding.engagement.autoRecovery"]
        if await toggle.isOn != on {
            toggle.tap()
        }
    }

    // MARK: - Sleep & Boundaries
    var sleepScreen: XCUIElement {
        app.descendants(matching: .any)["onboarding.sleepBoundaries"]
    }

    func verifyOnSleepBoundaries() async {
        await verifyElement(exists: sleepScreen)
    }

    func waitForSleepBoundariesScreen() async -> Bool {
        await app.descendants(matching: .any)["onboarding.sleepBoundaries"].waitForExistence(timeout: timeout)
    }

    func adjustTimeSlider(_ id: String, to position: CGFloat) async {
        let slider = app.sliders[id]
        let exists = await slider.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists)
        slider.adjust(toNormalizedSliderPosition: position)
    }

    // MARK: - Motivational Accents
    var motivationScreen: XCUIElement {
        app.descendants(matching: .any)["onboarding.motivationalAccents"]
    }

    func verifyOnMotivationalAccents() async {
        await verifyElement(exists: motivationScreen)
    }

    func waitForMotivationalAccentsScreen() async -> Bool {
        await app.descendants(matching: .any)["onboarding.motivationalAccents"].waitForExistence(timeout: timeout)
    }

    func selectMotivationOption(_ id: String) async {
        let button = app.buttons[id]
        button.tap()
    }

    // MARK: - Generating Coach
    var generatingScreen: XCUIElement {
        app.descendants(matching: .any)["onboarding.generatingCoach"]
    }

    func verifyOnGeneratingCoach() async {
        await verifyElement(exists: generatingScreen)
    }

    func waitForGeneratingCoachScreen() async -> Bool {
        await app.descendants(matching: .any)["onboarding.generatingCoach"].waitForExistence(timeout: timeout)
    }

    // MARK: - Coach Ready
    var coachReadyScreen: XCUIElement {
        app.descendants(matching: .any)["onboarding.coachProfileReady"]
    }

    func verifyCoachProfileReady() async {
        await verifyElement(exists: coachReadyScreen)
    }

    var beginCoachButton: XCUIElement {
        app.buttons["onboarding.beginCoach.button"]
    }

    func tapBeginCoachButton() async {
        app.buttons["onboarding.beginCoach.button"].tap()
    }

    // MARK: - Navigation
    var nextButton: XCUIElement {
        app.buttons["onboarding.next.button"]
    }

    var backButton: XCUIElement {
        app.buttons["onboarding.back.button"]
    }

    func tapNextButton() async {
        app.buttons["onboarding.next.button"].tap()
    }

    func tapBackButton() async {
        app.buttons["onboarding.back.button"].tap()
    }

    // MARK: - Verification
    func isOnDashboard() async -> Bool {
        await app.tabBars["main.tabbar"].waitForExistence(timeout: 5)
    }
}

private extension XCUIElement {
    var isOn: Bool {
        get async {
            (await value as? String) == "1"
        }
    }
}
