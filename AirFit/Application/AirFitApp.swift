import SwiftUI
import SwiftData

@main
struct AirFitApp: App {
    // MARK: - DI Container
    @State private var diContainer: DIContainer?
    @State private var isInitializing = true
    
    // MARK: - Model Container State
    @State private var modelContainer: ModelContainer?
    @State private var containerError: Error?
    @State private var isRetrying = false
    
    // MARK: - UI State
    @State private var gradientManager: GradientManager?
    
    // MARK: - Test Mode Detection
    private var isTestMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--test-mode") ||
        ProcessInfo.processInfo.environment["AIRFIT_TEST_MODE"] == "1"
    }
    
    // MARK: - Model Schema
    // Using migration plan for proper schema evolution
    private static let migrationPlan = AirFitMigrationPlan.self
    
    // MARK: - Model Container Creation
    private func createModelContainer(inMemory: Bool = false) -> ModelContainer? {
        do {
            if inMemory {
                // For in-memory containers, use latest schema directly
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(
                    for: User.self, OnboardingProfile.self, DailyLog.self,
                    FoodEntry.self, FoodItem.self, NutritionData.self,
                    Workout.self, Exercise.self, ExerciseSet.self,
                    TrackedGoal.self, CoachMessage.self, ChatSession.self,
                    ChatMessage.self, ChatAttachment.self, ConversationSession.self,
                    ConversationResponse.self, HealthKitSyncRecord.self,
                    configurations: config
                )
                AppLogger.warning("Using in-memory database - data will not persist", category: .data)
                return container
            } else {
                // For persistent containers, use migration plan
                let container = try ModelContainer(
                    for: User.self, // Need at least one model type
                    migrationPlan: Self.migrationPlan
                )
                return container
            }
        } catch {
            self.containerError = error
            AppLogger.error("Failed to create ModelContainer", error: error, category: .data)
            return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let containerError = containerError {
                // Model container error - show recovery options
                ModelContainerErrorView(
                    error: containerError,
                    isRetrying: isRetrying,
                    onRetry: retryContainerCreation,
                    onReset: resetDatabaseAndRetry,
                    onUseInMemory: useInMemoryDatabase
                )
            } else if modelContainer == nil {
                // Initial model container creation
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color.accentColor)
                    
                    Text("Loading database...")
                        .font(AppFonts.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.accentColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .task {
                    modelContainer = createModelContainer()
                }
            } else if isInitializing {
                // DI container initialization
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color.accentColor)
                    
                    Text("Initializing AirFit...")
                        .font(AppFonts.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.accentColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .task {
                    await initializeApp()
                }
            } else if let diContainer = diContainer, let modelContainer = modelContainer {
                ContentView()
                    .modelContainer(modelContainer)
                    .withDIContainer(diContainer)
                    .environmentObject(gradientManager ?? GradientManager())
                    .task {
                        // Resolve GradientManager from DI
                        if gradientManager == nil {
                            gradientManager = try? await diContainer.resolve(GradientManager.self)
                        }
                    }
            } else {
                // Unexpected error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text("Failed to initialize")
                        .font(AppFonts.headline)
                        .foregroundColor(.primary)
                    
                    Button("Retry") {
                        containerError = nil
                        modelContainer = nil
                        diContainer = nil
                        isInitializing = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.accentColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
    
    private func initializeApp() async {
        guard let modelContainer = modelContainer else {
            AppLogger.error("Cannot initialize DI without model container", category: .app)
            return
        }
        
        isInitializing = true
        
        // Create DI container with perfect lazy resolution
        // This is FAST - just registers factories, doesn't create services
        if isTestMode {
            AppLogger.info("Running in TEST MODE with mock services", category: .app)
            diContainer = DIBootstrapper.createMockContainer(
                modelContainer: modelContainer
            )
        } else {
            AppLogger.info("AirFitApp: Creating DI container", category: .app)
            diContainer = DIBootstrapper.createAppContainer(
                modelContainer: modelContainer
            )
            AppLogger.info("AirFitApp: DI container created instantly", category: .app)
        }
        
        // UI can render immediately - services will be created lazily as needed
        isInitializing = false
    }
    
    // MARK: - Error Recovery Methods
    private func retryContainerCreation() {
        isRetrying = true
        containerError = nil
        
        Task {
            // Small delay for UI feedback
            try? await Task.sleep(for: .seconds(0.5))
            
            await MainActor.run {
                modelContainer = createModelContainer()
                isRetrying = false
            }
        }
    }
    
    private func resetDatabaseAndRetry() {
        isRetrying = true
        
        Task {
            // Delete the database file
            let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                        in: .userDomainMask).first!
            let dbPath = documentsPath.appendingPathComponent("default.store")
            
            do {
                try FileManager.default.removeItem(at: dbPath)
                AppLogger.info("Deleted corrupted database", category: .data)
            } catch {
                AppLogger.error("Failed to delete database", error: error, category: .data)
            }
            
            await MainActor.run {
                containerError = nil
                modelContainer = createModelContainer()
                isRetrying = false
            }
        }
    }
    
    private func useInMemoryDatabase() {
        isRetrying = true
        containerError = nil
        
        Task {
            await MainActor.run {
                modelContainer = createModelContainer(inMemory: true)
                isRetrying = false
                
                if modelContainer != nil {
                    // Show warning to user about data not persisting
                    // This could be done via an alert or banner
                    AppLogger.warning("Using in-memory database - data will be lost on app restart", category: .data)
                }
            }
        }
    }
}
