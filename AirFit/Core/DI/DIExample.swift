import SwiftUI
import SwiftData

import Foundation

/// Example showing how to migrate from singleton-based to DI-based architecture
/// This is documentation only - not meant to compile
#if false
struct DIExample {

    // MARK: - Before (Current Approach with Singletons)

    struct OldDashboardView: View {
        @State private var viewModel: DashboardViewModel?
        let user: User

        var body: some View {
            Group {
                if let viewModel = viewModel {
                    DashboardContent(viewModel: viewModel)
                } else {
                    ProgressView()
                        .task {
                            // Manual dependency wiring with singletons
                            let modelContext = DataManager.shared.modelContext
                            let healthKitService = HealthKitService(
                                modelContext: modelContext,
                                healthKitManager: HealthKitManager() // Would need proper DI
                            )
                            let nutritionService = DashboardNutritionService(
                                modelContext: modelContext
                            )
                            let aiCoachService = AICoachService(
                                aiService: ServiceRegistry.shared.aiService,
                                modelContext: modelContext
                            )
                            let weatherService = WeatherService()
                            let coordinator = DashboardCoordinator()

                            self.viewModel = DashboardViewModel(
                                modelContext: modelContext,
                                user: user,
                                healthKitService: healthKitService,
                                nutritionService: nutritionService,
                                aiCoachService: aiCoachService,
                                weatherService: weatherService,
                                coordinator: coordinator
                            )
                        }
                }
            }
        }
    }

    // MARK: - After (New DI Approach)

    struct NewDashboardView: View {
        @Environment(\.diContainer)
        private var container
        @State private var viewModel: DashboardViewModel?
        let user: User

        var body: some View {
            Group {
                if let viewModel = viewModel {
                    DashboardContent(viewModel: viewModel)
                } else {
                    ProgressView()
                        .task {
                            do {
                                let factory = DIViewModelFactory(container: container)
                                self.viewModel = try await factory.makeDashboardViewModel(user: user)
                            } catch {
                                // Handle error
                                AppLogger.error("Failed to create DashboardViewModel", error: error)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Even Better (Using Helper)

    struct BestDashboardView: View {
        let user: User

        var body: some View {
            DashboardContent()
                .withViewModel { factory in
                    try await factory.makeDashboardViewModel(user: user)
                }
        }
    }

    // MARK: - App Setup Example

    @main
    struct AirFitAppWithDI: App {
        @State private var container: DIContainer?
        @State private var modelContainer: ModelContainer?

        var body: some Scene {
            WindowGroup {
                if let container = container, modelContainer != nil {
                    ContentView()
                        .withDIContainer(container)
                } else {
                    ProgressView("Loading...")
                        .task {
                            do {
                                // Setup model container
                                let schema = Schema([
                                    User.self,
                                    OnboardingProfile.self,
                                    FoodEntry.self,
                                    // ... other models
                                ])
                                let modelContainer = try ModelContainer(for: schema)
                                self.modelContainer = modelContainer

                                // Setup DI container
                                self.container = try await DIBootstrapper.createAppContainer(
                                    modelContainer: modelContainer
                                )
                            } catch {
                                // Handle initialization error
                                fatalError("Failed to initialize app: \(error)")
                            }
                        }
                }
            }
            .modelContainer(modelContainer ?? .init(for: Schema([User.self])))
        }
    }

    // MARK: - Testing Example

    final class DashboardViewModelTestsWithDI: XCTestCase {
        var container: DIContainer!

        override func setUp() {
            super.setUp()
            // Use test container with all mocks
            container = DIBootstrapper.createTestContainer()
        }

        func testDashboardLoading() async throws {
            // Create test user
            let user = User(name: "Test", email: "test@example.com")

            // Create view model with injected mocks
            let factory = DIViewModelFactory(container: container)
            let viewModel = try await factory.makeDashboardViewModel(user: user)

            // Test with mocked dependencies
            await viewModel.loadDashboardData()

            XCTAssertFalse(viewModel.isLoading)
            XCTAssertNil(viewModel.error)
            // ... more assertions
        }
    }

    // MARK: - Preview Example

    struct DashboardView_Previews: PreviewProvider {
        static var previews: some View {
            DashboardView(user: .preview)
                .task {
                    // Create preview container with appropriate services
                    let container = try? await DIBootstrapper.createPreviewContainer()
                    return container
                }
                .withDIContainer(DIBootstrapper.createPreviewContainer())
        }
    }
}

// MARK: - Migration Strategy Comments

/*
 Migration Strategy:

 1. Phase 1: Add DI alongside existing system
 - Create DIContainer, DIBootstrapper, DIViewModelFactory
 - Don't remove DependencyContainer or ServiceRegistry yet
 - Start with one module (e.g., Dashboard)

 2. Phase 2: Migrate ViewModels
 - Update ViewModel initializers to accept dependencies
 - Remove direct singleton access from ViewModels
 - Use factory methods for ViewModel creation

 3. Phase 3: Update Views
 - Replace manual ViewModel creation with factory
 - Use .withDIContainer() on root views
 - Update previews to use preview container

 4. Phase 4: Update Tests
 - Replace singleton setup/teardown with test containers
 - Use mock registrations for all dependencies
 - Remove global state pollution between tests

 5. Phase 5: Remove Old System
 - Delete DependencyContainer
 - Delete ServiceRegistry
 - Remove .shared from services that don't need it
 - Update documentation

 Benefits Realized:
 - Clear dependency graphs
 - Easy testing with mocks
 - No singleton pollution
 - Scoped dependencies for complex flows
 - Better compile-time safety
 */

// MARK: - Common Patterns

extension DIContainer {
    /// Register module-specific services
    func registerDashboardModule() {
        register(HealthKitService.self) { container in
            await HealthKitService(
                modelContext: try await container.resolve(ModelContext.self),
                healthKitManager: try await container.resolve(HealthKitManagerProtocol.self)
            )
        }

        register(DashboardNutritionService.self) { container in
            await DashboardNutritionService(
                modelContext: try await container.resolve(ModelContext.self)
            )
        }

        register(AICoachService.self) { container in
            // Similar to bootstrapper - would need user context
            fatalError("AICoachService needs user-specific CoachEngine - use factory method")
        }
    }
}

// MARK: - Async Resolution Helper

extension DIContainer {
    /// Helper for views that need synchronous resolution
    @MainActor
    func resolveSync<T: Sendable>(_ type: T.Type) -> T? {
        // This should be avoided in production code
        // Dependencies should be resolved asynchronously during view setup
        var result: T?
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            result = try? await resolve(type)
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }
}
#endif
