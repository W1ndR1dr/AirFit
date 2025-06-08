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
        do {
            AppLogger.info("AppInitializer: Starting initialization", category: .app)
            
            // Create DI container based on mode
            if isTestMode {
                AppLogger.info("AppInitializer: Creating mock container for test mode", category: .app)
                diContainer = try await DIBootstrapper.createMockContainer(
                    modelContainer: modelContainer
                )
            } else {
                AppLogger.info("AppInitializer: Creating production container", category: .app)
                diContainer = try await DIBootstrapper.createAppContainer(
                    modelContainer: modelContainer
                )
            }
            
            // Set as shared for initialization phase
            DIContainer.shared = diContainer
            
            AppLogger.info("AppInitializer: Container created successfully", category: .app)
            isInitialized = true
            
            // Clear shared after a delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            DIContainer.shared = nil
            
        } catch {
            AppLogger.error("AppInitializer: Failed to initialize", error: error, category: .app)
            initializationError = error
            
            // Create minimal fallback container
            let fallback = DIContainer()
            fallback.registerSingleton(ModelContainer.self, instance: modelContainer)
            diContainer = fallback
            isInitialized = true
        }
    }
}