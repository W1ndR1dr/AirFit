import SwiftUI
import SwiftData

@MainActor
final class AppInitializer: ObservableObject {
    @Published var isInitialized = false
    @Published var diContainer: DIContainer?
    @Published var initializationError: Error?
    
    private let isTestMode: Bool
    private let modelContainer: ModelContainer
    
    init() {
        self.isTestMode = ProcessInfo.processInfo.arguments.contains("--test-mode") ||
                         ProcessInfo.processInfo.environment["AIRFIT_TEST_MODE"] == "1"
        self.modelContainer = AirFitApp.sharedModelContainer
        
        AppLogger.info("AppInitializer: Created, starting initialization", category: .app)
        
        // Start initialization immediately
        Task {
            await initialize()
        }
    }
    
    func initialize() async {
        AppLogger.info("AppInitializer: Starting initialization", category: .app)
        
        // Create DI container based on mode - FAST, no blocking!
        if isTestMode {
            AppLogger.info("AppInitializer: Creating mock container for test mode", category: .app)
            diContainer = DIBootstrapper.createMockContainer(
                modelContainer: modelContainer
            )
        } else {
            AppLogger.info("AppInitializer: Creating production container", category: .app)
            diContainer = DIBootstrapper.createAppContainer(
                modelContainer: modelContainer
            )
        }
        
        AppLogger.info("AppInitializer: Container created instantly", category: .app)
        isInitialized = true
    }
}