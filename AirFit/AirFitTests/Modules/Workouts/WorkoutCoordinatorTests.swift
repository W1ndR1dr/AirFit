import XCTest
@testable import AirFit

final class WorkoutCoordinatorTests: XCTestCase {
    var coordinator: WorkoutCoordinator!

    override func setUp() {
        // WorkoutCoordinator is @MainActor, will be created in test methods
    }

    @MainActor

    func test_navigateToPushesDestination()  {

        let coordinator = WorkoutCoordinator()
        coordinator.navigateTo(.exerciseLibrary)
        XCTAssertEqual(coordinator.path.count, 1)
    }

    @MainActor

    func test_showAndDismissSheet()  {

        let coordinator = WorkoutCoordinator()
        coordinator.showSheet(.templatePicker)
        XCTAssertEqual(coordinator.presentedSheet, .templatePicker)
        coordinator.dismissSheet()
        XCTAssertNil(coordinator.presentedSheet)
    }

    @MainActor

    func test_handleDeepLinkResetsPath()  {

        let coordinator = WorkoutCoordinator()
        coordinator.navigateTo(.exerciseLibrary)
        coordinator.navigateTo(.allWorkouts)
        coordinator.handleDeepLink(.statistics)
        XCTAssertEqual(coordinator.path.count, 1)
    }
}
