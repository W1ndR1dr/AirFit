import XCTest
import XCUIAutomation

/// Base class for all page objects providing common functionality.
@MainActor
class BasePage {
    let app: XCUIApplication
    let timeout: TimeInterval = 10.0

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Common Actions
    func tapElement(_ element: XCUIElement) async {
        let exists = await element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists)
        element.tap()
    }

    func typeText(in element: XCUIElement, text: String) async {
        let exists = await element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists)
        element.tap()
        element.typeText(text)
    }

    func verifyElement(exists element: XCUIElement, timeout: TimeInterval? = nil) async {
        let waitTime = timeout ?? self.timeout
        let exists = await element.waitForExistence(timeout: waitTime)
        XCTAssertTrue(exists)
    }

    func verifyElement(notExists element: XCUIElement) {
        XCTAssertFalse(element.exists)
    }

    func waitForElement(_ element: XCUIElement, timeout: TimeInterval? = nil) async -> Bool {
        let waitTime = timeout ?? self.timeout
        return await element.waitForExistence(timeout: waitTime)
    }

    func swipeUp() {
        app.swipeUp()
    }

    func swipeDown() {
        app.swipeDown()
    }

    func scrollToElement(_ element: XCUIElement) {
        while !element.exists {
            swipeUp()
        }
    }
}
