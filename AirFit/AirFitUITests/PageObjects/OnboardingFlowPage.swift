import XCTest
import XCUIAutomation

@MainActor
final class OnboardingFlowPage: BasePage {

    var nextButton: XCUIElement {
        app.buttons["onboarding.next.button"]
    }

    func tapNext() async {
        nextButton.tap()
    }
}
