import XCTest
@testable import AirFit

@MainActor
final class ChatCoordinatorTests: XCTestCase {
    var coordinator: ChatCoordinator!

    override func setUp() async throws {
        coordinator = ChatCoordinator()
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
