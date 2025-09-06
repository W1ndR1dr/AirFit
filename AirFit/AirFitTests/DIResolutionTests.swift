import XCTest
@testable import AirFit

final class DIResolutionTests: XCTestCase {
    func testResolvesCoreRegistrations() async throws {
        let container = try TestSupport.makeMockDIContainer()

        // Core systems
        _ = try await container.resolve(ModelContainer.self)
        _ = try await container.resolve(APIKeyManagementProtocol.self)

        // AI core
        _ = try await container.resolve(AIServiceProtocol.self)
        _ = try await container.resolve(DirectAIProcessor.self)

        // UI services
        _ = try await container.resolve(GradientManager.self)
        _ = try await container.resolve(ChatStreamingStore.self)

        // Domain
        _ = try await container.resolve(ContextAssembler.self)
        _ = try await container.resolve(HealthKitManaging.self)
    }
}
