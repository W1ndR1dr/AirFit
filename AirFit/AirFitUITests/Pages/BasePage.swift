import XCTest

class BasePage {
    let app: XCUIApplication
    let timeout: TimeInterval = 10

    required init(app: XCUIApplication) {
        self.app = app
    }

    func waitForElement(_ element: XCUIElement, timeout: TimeInterval? = nil) -> Bool {
        element.waitForExistence(timeout: timeout ?? self.timeout)
    }

    func tapElement(_ element: XCUIElement) {
        XCTAssertTrue(waitForElement(element), "\(element) not found")
        element.tap()
    }

    func typeText(in element: XCUIElement, text: String) {
        XCTAssertTrue(waitForElement(element), "\(element) not found")
        element.tap()
        element.typeText(text)
    }

    func verifyElement(exists element: XCUIElement) {
        XCTAssertTrue(waitForElement(element), "\(element) should exist")
    }

    func verifyElement(notExists element: XCUIElement) {
        XCTAssertFalse(element.exists, "\(element) should not exist")
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
