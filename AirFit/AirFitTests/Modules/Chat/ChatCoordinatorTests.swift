import XCTest
@testable import AirFit

final class ChatCoordinatorTests: XCTestCase {
    var coordinator: ChatCoordinator!

    override func setUp() {
        coordinator = ChatCoordinator()
    }

    @MainActor

    func test_navigateToPushesDestination() {
        coordinator.navigateTo(.searchResults)
        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }

    @MainActor

    func test_showSheetSetsActiveSheet() {
        coordinator.showSheet(.voiceSettings)
        XCTAssertEqual(coordinator.activeSheet, .voiceSettings)
    }

    @MainActor

    func test_scrollToStoresMessageId() {
        coordinator.scrollTo(messageId: "123")
        XCTAssertEqual(coordinator.scrollToMessageId, "123")
    }

    @MainActor

    func test_dismissClearsPresentation() {
        coordinator.showSheet(.exportChat)
        coordinator.showPopover(.quickActions)
        coordinator.dismiss()
        XCTAssertNil(coordinator.activeSheet)
        XCTAssertNil(coordinator.activePopover)
    }
}
