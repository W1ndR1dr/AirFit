import XCTest
@testable import AirFit

/// Placeholder tests for `HealthKitManager`.
///
/// These tests provide basic coverage to ensure the singleton and
/// authorization status enumeration compile under the test target.
/// Comprehensive tests require a refactor of `HealthKitManager` to
/// allow dependency injection of `HKHealthStore`.
final class HealthKitManagerTests: XCTestCase {

    @MainActor
    func test_sharedInstance_exists() {
        // The shared singleton should be accessible.
        let manager = HealthKitManager.shared
        XCTAssertNotNil(manager)
    }

    @MainActor
    func test_authorizationStatus_default_isNotDetermined() {
        let manager = HealthKitManager.shared
        // Expect default status to be `.notDetermined` on first launch.
        XCTAssertEqual(manager.authorizationStatus, .notDetermined)
    }
}
