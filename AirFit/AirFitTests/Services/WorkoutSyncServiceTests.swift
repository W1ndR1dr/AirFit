import XCTest
@testable import AirFit

@MainActor
final class WorkoutSyncServiceTests: XCTestCase {

    func test_sharedInstance_exists() {
        let service = WorkoutSyncService.shared
        XCTAssertNotNil(service)
    }
}
