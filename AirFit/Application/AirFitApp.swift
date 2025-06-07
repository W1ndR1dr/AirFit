import SwiftUI
import SwiftData

@main
struct AirFitApp: App {
    // MARK: - DI Container
    @State private var diContainer: DIContainer?
    
    // MARK: - Test Mode Detection
    private var isTestMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--test-mode") ||
        ProcessInfo.processInfo.environment["AIRFIT_TEST_MODE"] == "1"
    }
    
    // MARK: - Shared Model Container
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            FoodEntry.self,
            Workout.self,
            DailyLog.self,
            CoachMessage.self,
            HealthKitSyncRecord.self,
            ChatSession.self,
            ChatMessage.self,
            ConversationSession.self,
            ConversationResponse.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(Self.sharedModelContainer)
                .withDIContainer(diContainer ?? DIContainer())
                .task {
                    if diContainer == nil {
                        do {
                            if isTestMode {
                                AppLogger.info("Running in TEST MODE with mock services", category: .app)
                                diContainer = try await DIBootstrapper.createMockContainer(
                                    modelContainer: Self.sharedModelContainer
                                )
                            } else {
                                diContainer = try await DIBootstrapper.createAppContainer(
                                    modelContainer: Self.sharedModelContainer
                                )
                            }
                        } catch {
                            AppLogger.error("Failed to create DI container", error: error, category: .app)
                            // Fallback to empty container
                            diContainer = DIContainer()
                        }
                    }
                }
        }
    }
}
