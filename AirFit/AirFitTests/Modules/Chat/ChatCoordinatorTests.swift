import XCTest
@testable import AirFit

@MainActor
final class ChatCoordinatorTests: XCTestCase {
    // MARK: - Properties
    private var coordinator: ChatCoordinator!

    // MARK: - Setup
    override func setUp() {
        super.setUp()
        coordinator = ChatCoordinator()
    }
    
    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }

    func test_navigateToPushesDestination() {
        coordinator.navigateTo(.searchResults)
        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }

    func test_showSheetSetsActiveSheet() {
        coordinator.showSheet(.voiceSettings)
        XCTAssertEqual(coordinator.activeSheet, .voiceSettings)
    }

    func test_scrollToStoresMessageId() {
        coordinator.scrollTo(messageId: "123")
        XCTAssertEqual(coordinator.scrollToMessageId, "123")
    }

    func test_dismissClearsPresentation() {
        coordinator.showSheet(.exportChat)
        coordinator.showPopover(.quickActions)
        coordinator.dismiss()
        XCTAssertNil(coordinator.activeSheet)
        XCTAssertNil(coordinator.activePopover)
    }
}
