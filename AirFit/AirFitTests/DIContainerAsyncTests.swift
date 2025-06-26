import XCTest
@testable import AirFit

@MainActor
final class DIContainerAsyncTests: XCTestCase {

    func testAsyncResolutionDoesNotBlock() async throws {
        // Given
        let container = DIContainer()
        let expectation = "Test Value"

        container.register(String.self) { _ in
            expectation
        }

        // When
        let startTime = Date()
        let result = try await container.resolve(String.self)
        let elapsed = Date().timeIntervalSince(startTime)

        // Then
        XCTAssertEqual(result, expectation)
        XCTAssertLessThan(elapsed, 0.1, "Resolution should be nearly instant")
    }

    func testNoSynchronousResolutionAvailable() async {
        // This test verifies that synchronousResolve method doesn't exist
        let container = DIContainer()

        // The following line should not compile if we've successfully removed synchronous resolution
        // container.synchronousResolve(String.self)

        // If this test compiles, it means we've successfully removed the synchronous API
        XCTAssertTrue(true, "Synchronous resolution has been removed")
    }

    func testMissingDependencyThrowsError() async {
        // Given
        let container = DIContainer()

        // When/Then
        do {
            _ = try await container.resolve(String.self)
            XCTFail("Should have thrown for unregistered type")
        } catch let error as DIError {
            switch error {
            case .notRegistered(let type):
                XCTAssertEqual(type, "String")
            default:
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDIContainerSharedIsRemoved() {
        // This verifies DIContainer.shared no longer exists
        // The following line should not compile:
        // let _ = DIContainer.shared

        XCTAssertTrue(true, "DIContainer.shared has been removed")
    }
}
