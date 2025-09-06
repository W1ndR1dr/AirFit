import XCTest
import SwiftData
@testable import AirFit

// Minimal helpers to make writing reliable, fast tests easier
enum TestSupport {
    // In-memory SwiftData container with a small schema used in previews
    static func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            FoodEntry.self,
            Workout.self,
            TrackedGoal.self,
            ChatSession.self
        ])
        return try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
    }

    // Full app DI container backed by in-memory SwiftData
    static func makeAppDIContainer() throws -> DIContainer {
        let model = try makeInMemoryModelContainer()
        return DIBootstrapper.createAppContainer(modelContainer: model)
    }

    // Mock DI container used for tests (demo/test AI, etc.)
    static func makeMockDIContainer() throws -> DIContainer {
        let model = try makeInMemoryModelContainer()
        return DIBootstrapper.createMockContainer(modelContainer: model)
    }
}

