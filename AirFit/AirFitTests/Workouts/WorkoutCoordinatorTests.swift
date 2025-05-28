import XCTest
@testable import AirFit

@MainActor
final class WorkoutCoordinatorTests: XCTestCase {
    var coordinator: WorkoutCoordinator!

    override func setUp() async throws {
        coordinator = WorkoutCoordinator()
    }

    func test_navigateToPushesDestination() {
        coordinator.navigateTo(.exerciseLibrary)
        XCTAssertEqual(coordinator.path.count, 1)
    }

    func test_showAndDismissSheet() {
        coordinator.showSheet(.templatePicker)
        XCTAssertEqual(coordinator.presentedSheet, .templatePicker)
        coordinator.dismissSheet()
        XCTAssertNil(coordinator.presentedSheet)
    }

    func test_handleDeepLinkResetsPath() {
        coordinator.navigateTo(.exerciseLibrary)
        coordinator.navigateTo(.allWorkouts)
        coordinator.handleDeepLink(.statistics)
        XCTAssertEqual(coordinator.path.count, 1)
    }
}
