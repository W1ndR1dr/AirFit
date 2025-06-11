import XCTest
@testable import AirFit

@MainActor
final class WorkoutSyncServiceTests: XCTestCase {

    func test_service_can_be_created() {
        let service = WorkoutSyncService()
        XCTAssertNotNil(service)
    }
    
    func test_service_conforms_to_protocol() {
        let service = WorkoutSyncService()
        XCTAssertEqual(service.serviceIdentifier, "workout-sync-service")
        XCTAssertFalse(service.isConfigured)
    }
    
    func test_service_can_configure() async throws {
        let service = WorkoutSyncService()
        XCTAssertFalse(service.isConfigured)
        
        try await service.configure()
        XCTAssertTrue(service.isConfigured)
    }
    
    func test_service_health_check() async {
        let service = WorkoutSyncService()
        let health = await service.healthCheck()
        
        XCTAssertNotNil(health)
        // WatchConnectivity may not be supported in simulator
        XCTAssertTrue(health.status == .healthy || health.status == .unhealthy)
    }
}
