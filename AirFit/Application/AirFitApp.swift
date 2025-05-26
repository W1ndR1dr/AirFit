import SwiftData
import SwiftUI

@main
struct AirFitApp: App {
    // MARK: - Properties
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

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
                .modelContainer(for: [
                    // Add SwiftData models here
                ])
                .onAppear {
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
        @unknown default:
            break
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
