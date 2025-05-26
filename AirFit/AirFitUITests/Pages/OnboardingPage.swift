import XCTest

/// Page object for interacting with the onboarding flow.
class OnboardingPage: BasePage {
    // MARK: - Opening Screen
    var beginButton: XCUIElement {
        app.buttons["onboarding.begin.button"]
    }

    var skipButton: XCUIElement {
        app.buttons["onboarding.skip.button"]
    }

    func verifyOnOpeningScreen() {
        verifyElement(exists: beginButton)
        verifyElement(exists: skipButton)
    }

    func tapBegin() {
        tapElement(beginButton)
    }

    // MARK: - Life Snapshot
    var lifeSnapshotScreen: XCUIElement {
        app.otherElements["onboarding.lifeSnapshot"]
    }

    func verifyOnLifeSnapshot() {
        verifyElement(exists: lifeSnapshotScreen)
    }

    func selectLifeOption(_ optionId: String) {
        let toggle = app.switches[optionId]
        tapElement(toggle)
    }

    func selectWorkoutOption(_ option: String) {
        let button = app.buttons[option]
        tapElement(button)
    }

    // MARK: - Core Aspiration
    var coreAspirationScreen: XCUIElement {
        app.otherElements["onboarding.coreAspiration"]
    }

    func verifyOnCoreAspiration() {
        verifyElement(exists: coreAspirationScreen)
    }

    func selectPredefinedGoal(_ goal: String) {
        let card = app.buttons[goal]
        tapElement(card)
    }

    var goalTextField: XCUIElement {
        app.textFields["onboarding.goal.text"]
    }

    var voiceButton: XCUIElement {
        app.buttons["onboarding.goal.voice"]
    }

    func enterGoalText(_ text: String) {
        typeText(in: goalTextField, text: text)
    }

    func tapVoiceButton() {
        tapElement(voiceButton)
    }

    // MARK: - Coaching Style
    var coachingStyleScreen: XCUIElement {
        app.otherElements["onboarding.coachingStyle"]
    }

    func verifyOnCoachingStyle() {
        verifyElement(exists: coachingStyleScreen)
    }

    func adjustSlider(_ identifier: String, to position: CGFloat) {
        let slider = app.sliders[identifier]
        XCTAssertTrue(slider.waitForExistence(timeout: timeout))
        slider.adjust(toNormalizedSliderPosition: position)
    }

    // MARK: - Engagement Preferences
    var engagementScreen: XCUIElement {
        app.otherElements["onboarding.engagementPreferences"]
    }

    func verifyOnEngagementPreferences() {
        verifyElement(exists: engagementScreen)
    }

    func selectEngagementCard(_ id: String) {
        let card = app.buttons[id]
        tapElement(card)
    }

    func selectRadioOption(_ id: String) {
        let button = app.buttons[id]
        tapElement(button)
    }

    func toggleAutoRecovery(_ on: Bool) {
        let toggle = app.switches["onboarding.engagement.autoRecovery"]
        if toggle.isOn != on {
            tapElement(toggle)
        }
    }

    // MARK: - Sleep & Boundaries
    var sleepScreen: XCUIElement {
        app.otherElements["onboarding.sleepBoundaries"]
    }

    func verifyOnSleepBoundaries() {
        verifyElement(exists: sleepScreen)
    }

    func adjustTimeSlider(_ id: String, to position: CGFloat) {
        let slider = app.sliders[id]
        XCTAssertTrue(slider.waitForExistence(timeout: timeout))
        slider.adjust(toNormalizedSliderPosition: position)
    }

    // MARK: - Motivational Accents
    var motivationScreen: XCUIElement {
        app.otherElements["onboarding.motivationalAccents"]
    }

    func verifyOnMotivationalAccents() {
        verifyElement(exists: motivationScreen)
    }

    func selectMotivationOption(_ id: String) {
        let button = app.buttons[id]
        tapElement(button)
    }

    // MARK: - Generating Coach
    var generatingScreen: XCUIElement {
        app.otherElements["onboarding.generatingCoach"]
    }

    func verifyOnGeneratingCoach() {
        verifyElement(exists: generatingScreen)
    }

    // MARK: - Coach Ready
    var coachReadyScreen: XCUIElement {
        app.otherElements["onboarding.coachProfileReady"]
    }

    func verifyCoachProfileReady() {
        verifyElement(exists: coachReadyScreen)
    }

    var beginCoachButton: XCUIElement {
        app.buttons["onboarding.beginCoach.button"]
    }

    // MARK: - Navigation
    var nextButton: XCUIElement {
        app.buttons["onboarding.next.button"]
    }

    var backButton: XCUIElement {
        app.buttons["onboarding.back.button"]
    }

    func tapNext() {
        tapElement(nextButton)
    }

    func tapBack() {
        tapElement(backButton)
    }

    // MARK: - Verification
    func isOnDashboard() -> Bool {
        app.tabBars["main.tabbar"].waitForExistence(timeout: 5)
    }
}

private extension XCUIElement {
    var isOn: Bool { (value as? String) == "1" }
}
