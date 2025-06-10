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
    
    // MARK: - Test Mode Detection
    private var isTestMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--test-mode") ||
        ProcessInfo.processInfo.environment["AIRFIT_TEST_MODE"] == "1"
    }
    
    // MARK: - Model Schema
    private static let modelSchema = Schema([
        // Core models
        User.self,
        OnboardingProfile.self,
        
        // Food tracking
        FoodEntry.self,
        FoodItem.self,
        FoodItemTemplate.self,
        MealTemplate.self,
        NutritionData.self,
        
        // Workout tracking
        Workout.self,
        Exercise.self,
        ExerciseSet.self,
        ExerciseTemplate.self,
        WorkoutTemplate.self,
        SetTemplate.self,
        
        // Goals and logs
        DailyLog.self,
        TrackedGoal.self,
        
        // AI and chat
        CoachMessage.self,
        ChatSession.self,
        ChatMessage.self,
        ChatAttachment.self,
        ConversationSession.self,
        ConversationResponse.self,
        
        // Health sync
        HealthKitSyncRecord.self
    ])
    
    // MARK: - Model Container Creation
    private func createModelContainer(inMemory: Bool = false) -> ModelContainer? {
        let modelConfiguration = ModelConfiguration(
            schema: Self.modelSchema,
            isStoredInMemoryOnly: inMemory
        )
        
        do {
            // Use migration plan for future-proof schema evolution
            let container = try ModelContainer(
                for: Self.modelSchema,
                configurations: [modelConfiguration]
            )
            
            if inMemory {
                AppLogger.warning("Using in-memory database - data will not persist", category: .data)
            }
            
            return container
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
                        .tint(AppColors.accentColor)
                    
                    Text("Loading database...")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.backgroundPrimary)
                .task {
                    modelContainer = createModelContainer()
                }
            } else if isInitializing {
                // DI container initialization
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppColors.accentColor)
                    
                    Text("Initializing AirFit...")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.backgroundPrimary)
                .task {
                    await initializeApp()
                }
            } else if let diContainer = diContainer, let modelContainer = modelContainer {
                ContentView()
                    .modelContainer(modelContainer)
                    .withDIContainer(diContainer)
            } else {
                // Unexpected error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(AppColors.errorColor)
                    
                    Text("Failed to initialize")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Button("Retry") {
                        containerError = nil
                        modelContainer = nil
                        diContainer = nil
                        isInitializing = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.backgroundPrimary)
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
