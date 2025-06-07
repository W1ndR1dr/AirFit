import XCTest
@testable import AirFit

@MainActor
final class WorkoutCoordinatorTests: XCTestCase {
    // MARK: - Properties
    private var coordinator: WorkoutCoordinator!

    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
        coordinator = WorkoutCoordinator()
    }
    
    override func tearDown() async throws {
        coordinator = nil
        try await super.tearDown()
    }

    func test_navigateToPushesDestination() {
        // Act
        coordinator.navigateTo(.exerciseLibrary)
        
        // Assert
        XCTAssertEqual(coordinator.path.count, 1)
    }

    func test_showAndDismissSheet() {
        // Act & Assert - Show sheet
        coordinator.showSheet(.templatePicker)
        XCTAssertEqual(coordinator.presentedSheet, .templatePicker)
        
        // Act & Assert - Dismiss sheet
        coordinator.dismissSheet()
        XCTAssertNil(coordinator.presentedSheet)
    }

    func test_handleDeepLinkResetsPath() {
        // Arrange
        coordinator.navigateTo(.exerciseLibrary)
        coordinator.navigateTo(.allWorkouts)
        
        // Act
        coordinator.handleDeepLink(.statistics)
        
        // Assert
        XCTAssertEqual(coordinator.path.count, 1)
    }
}
