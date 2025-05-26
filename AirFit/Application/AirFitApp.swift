import SwiftData
import SwiftUI

@main
struct AirFitApp: App {
    // MARK: - Properties
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()

    // MARK: - Model Container
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            DailyLog.self,
            FoodEntry.self,
            FoodItem.self,
            Workout.self,
            Exercise.self,
            ExerciseSet.self,
            CoachMessage.self,
            ChatSession.self,
            ChatMessage.self,
            ChatAttachment.self,
            NutritionData.self,
            HealthKitSyncRecord.self,
            WorkoutTemplate.self,
            ExerciseTemplate.self,
            SetTemplate.self,
            MealTemplate.self,
            FoodItemTemplate.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .automatic
        )

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: AirFitMigrationPlan.self,
                configurations: [modelConfiguration]
            )

            container.mainContext.autosaveEnabled = true
            container.mainContext.undoManager = nil

            AppLogger.info("ModelContainer initialized successfully", category: .data)
            return container
        } catch {
            AppLogger.fault("Failed to create ModelContainer", error: error, category: .data)
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Initialization
    init() {
        setupAppearance()
        AppLogger.info("AirFit launched", category: .general)
    }

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(Self.sharedModelContainer)
                .onAppear {
                    setupInitialData()
                    AppLogger.info("Main view appeared", category: .ui)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    // MARK: - Private Methods
    private func setupAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(AppColors.backgroundPrimary)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(AppColors.backgroundPrimary)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            AppLogger.info("App became active", category: .general)
        case .inactive:
            AppLogger.info("App became inactive", category: .general)
        case .background:
            AppLogger.info("App entered background", category: .general)
            try? Self.sharedModelContainer.mainContext.save()
        @unknown default:
            break
        }
    }

    private func setupInitialData() {
        Task {
            await DataManager.shared.performInitialSetup()
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false
    @Published var selectedTab: AppTab = .dashboard

    init() {
        loadUserState()
    }

    private func loadUserState() {
        // Load from UserDefaults or Keychain
    }
}


