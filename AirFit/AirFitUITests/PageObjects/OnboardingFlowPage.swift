import XCTest

/// Page object representing the onboarding flow.
struct OnboardingFlowPage {
    let app: XCUIApplication

    var nextButton: XCUIElement { app.buttons["onboarding_next_button"] }

    func tapNext() {
        nextButton.tap()
    }
}
