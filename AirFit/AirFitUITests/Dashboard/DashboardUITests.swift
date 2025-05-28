import XCTest
import XCUIAutomation

@MainActor
final class DashboardUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-onboarding"]
        app.launch()

        // Complete minimal onboarding flow to reach the dashboard
        let onboarding = OnboardingPage(app: app)
        await onboarding.tapElement(onboarding.beginButton)
        _ = await onboarding.waitForElement(onboarding.lifeSnapshotScreen)
        await onboarding.tapNextButton()
        _ = await onboarding.waitForElement(onboarding.goalScreen)
        await onboarding.enterGoalText("Get fit")
        await onboarding.tapNextButton()
        for _ in 0..<4 { await onboarding.tapNextButton() }
        _ = await onboarding.coachReadyScreen.waitForExistence(timeout: 15)
        await onboarding.tapBeginCoachButton()

        // Wait for dashboard to appear
        _ = await app.otherElements["dashboard.main"].waitForExistence(timeout: 5)
    }

    override func tearDown() async throws {
        app = nil
    }

    func test_dashboardLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["--uitesting", "--reset-onboarding"]
            app.launch()
        }
    }

    func test_loadingState_displaysAndDismisses() async throws {
        let loading = app.otherElements["dashboard.loading"]
        XCTAssertTrue(await loading.waitForExistence(timeout: 2))
        let dashboard = app.otherElements["dashboard.main"]
        XCTAssertTrue(await dashboard.waitForExistence(timeout: 5))
        XCTAssertFalse(loading.exists)
    }

    func test_errorState_showsAndHandlesRetry() async throws {
        app.terminate()
        app.launchArguments = ["--uitesting", "--reset-onboarding", "--dashboard-error"]
        app.launch()

        let errorView = app.otherElements["dashboard.error"]
        XCTAssertTrue(await errorView.waitForExistence(timeout: 2))
        app.buttons["Retry"].tap()
        let dashboard = app.otherElements["dashboard.main"]
        XCTAssertTrue(await dashboard.waitForExistence(timeout: 5))
    }

    func test_morningGreeting_logEnergy() async throws {
        let logButton = app.buttons["Log Energy"]
        XCTAssertTrue(await logButton.waitForExistence(timeout: 2))
        logButton.tap()

        let levelButton = app.buttons["4"]
        XCTAssertTrue(await levelButton.waitForExistence(timeout: 2))
        levelButton.tap()

        XCTAssertTrue(app.buttons["Update"].exists)
    }

    func test_nutritionCard_navigation() async throws {
        let nutrition = app.staticTexts["Nutrition"]
        XCTAssertTrue(await nutrition.waitForExistence(timeout: 2))
        nutrition.tap()
        XCTAssertTrue(app.staticTexts["Destination"].waitForExistence(timeout: 2))
    }

    func test_quickAction_tapNavigates() async throws {
        let quickActions = app.staticTexts["Quick Actions"]
        XCTAssertTrue(await quickActions.waitForExistence(timeout: 2))

        let firstAction = app.buttons.matching(identifier: "Quick Actions").firstMatch
        if firstAction.exists { firstAction.tap() }

        XCTAssertTrue(app.staticTexts["Destination"].waitForExistence(timeout: 2))
    }

    func test_backNavigation_returnsToDashboard() async throws {
        let nutrition = app.staticTexts["Nutrition"]
        XCTAssertTrue(await nutrition.waitForExistence(timeout: 2))
        nutrition.tap()
        XCTAssertTrue(app.staticTexts["Destination"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.otherElements["dashboard.main"].exists)
    }

    func test_deepLink_nutrition() async throws {
        app.terminate()
        app.launchArguments = ["--uitesting", "--reset-onboarding", "-deeplink", "airfit://dashboard/nutrition"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Nutrition"].waitForExistence(timeout: 5))
    }

    func test_accessibility_labels_exist() {
        XCTAssertTrue(app.otherElements["dashboard.main"].exists)
        XCTAssertTrue(app.buttons["Log Energy"].exists)
        XCTAssertTrue(app.staticTexts["Quick Actions"].exists)
    }

    func test_dynamicType_supportsAccessibility() async throws {
        app.terminate()
        app.launchArguments = ["--uitesting", "--reset-onboarding", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        app.launch()
        _ = await app.otherElements["dashboard.main"].waitForExistence(timeout: 5)
        XCTAssertTrue(app.otherElements["dashboard.main"].exists)
    }
}
