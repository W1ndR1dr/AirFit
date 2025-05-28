import XCTest
@testable import AirFit

final class WorkoutSyncServiceTests: XCTestCase {

    func test_sharedInstance_exists() {
        let service = WorkoutSyncService.shared
        XCTAssertNotNil(service)
    }
}
