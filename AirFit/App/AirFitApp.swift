import SwiftUI
import SwiftData
import UserNotifications

@main
struct AirFitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("appearanceMode") private var appearanceMode: String = "System"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }

    init() {
        // Make TabView and NavigationBar transparent
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = .clear
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .clear
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    ScrollytellingRootView()
                        .preferredColorScheme(colorScheme)
                } else {
                    OnboardingCoordinator()
                        .preferredColorScheme(colorScheme)
                }

                // Only show app-level splash for returning users
                // New users get the onboarding splash (with wordmark) instead
                if showSplash && hasCompletedOnboarding {
                    AirFitSplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // Returning users: brief splash as loading mask (0.8s total)
                // New users: onboarding handles its own splash timing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            }
            .onOpenURL { url in
                DeepLinkHandler.shared.handle(url)
            }
        }
        .modelContainer(for: [
            NutritionEntry.self,
            WaterEntry.self,
            Conversation.self,
            // Hevy cache models (for offline access to training data)
            CachedWorkout.self,
            CachedSetTracker.self,
            CachedLiftProgress.self,
            HevyCacheMetadata.self,
            // Gemini Direct mode insight storage
            LocalInsight.self
        ])
    }
}

// MARK: - App Delegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Initialize notifications
        Task {
            await NotificationManager.shared.registerCategories()
            _ = await NotificationManager.shared.requestAuthorization()
        }

        // Register background tasks for periodic sync
        AutoSyncManager.registerBackgroundTasks()

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Schedule background sync when app goes to background
        AutoSyncManager.scheduleBackgroundSync()
    }

    // Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show banner even when app is open
        return [.banner, .sound]
    }

    // Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionId = response.actionIdentifier
        let categoryId = response.notification.request.content.categoryIdentifier

        switch actionId {
        case "LOG_FOOD":
            // Post notification to open nutrition tab
            await MainActor.run {
                NotificationCenter.default.post(name: .openNutritionTab, object: nil)
            }
        case "VIEW_INSIGHT" where categoryId == "INSIGHT_ALERT",
             UNNotificationDefaultActionIdentifier where categoryId == "INSIGHT_ALERT":
            // Open insights tab when tapping insight notification
            await MainActor.run {
 
                NotificationCenter.default.post(name: .openInsightsTab, object: nil)
            }
        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openNutritionTab = Notification.Name("openNutritionTab")
    static let openDashboardTab = Notification.Name("openDashboardTab")
    static let openCoachTab = Notification.Name("openCoachTab")
    static let openInsightsTab = Notification.Name("openInsightsTab")
    static let openProfileTab = Notification.Name("openProfileTab")
    static let profileReset = Notification.Name("profileReset")
}

// MARK: - Content View with Ethereal Background

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0

    // Watch connectivity handler (singleton, initialized on first access)
    private let watchHandler = WatchConnectivityHandler.shared

    var body: some View {
        ZStack {
            // Ethereal animated background (respects reduce motion)
            if reduceMotion {
                Theme.background
                    .ignoresSafeArea()
            } else {
                EtherealBackground(currentTab: selectedTab)
                    .ignoresSafeArea()
            }

            // Main tab content - transparent to show ethereal background
            // Tab order: Dashboard(0), Nutrition(1), Coach(2-center), Insights(3), Profile(4)
            TabView(selection: $selectedTab) {
                NavigationStack {
                    DashboardView()
                        .background(.clear)
                }
                .background(.clear)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
                .tag(0)

                NavigationStack {
                    NutritionView()
                        .background(.clear)
                }
                .background(.clear)
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
                .tag(1)

                NavigationStack {
                    ChatView()
                        .background(.clear)
                }
                .background(.clear)
                .tabItem {
                    Label("Coach", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(2)

                NavigationStack {
                    InsightsView()
                        .background(.clear)
                }
                .background(.clear)
                .tabItem {
                    Label("Insights", systemImage: "sparkles")
                }
                .tag(3)

                NavigationStack {
                    ProfileView()
                        .background(.clear)
                }
                .background(.clear)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(4)
            }
            .background(.clear)
            .tint(Theme.accent)
        }
        .animation(.airfitMorph, value: selectedTab)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .task {
            // Configure Watch connectivity with SwiftData context
            watchHandler.configure(modelContext: modelContext)
            await AutoSyncManager.shared.performLaunchSync(modelContext: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDashboardTab)) { _ in
            withAnimation(.airfit) { selectedTab = 0 }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openNutritionTab)) { _ in
            withAnimation(.airfit) { selectedTab = 1 }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCoachTab)) { _ in
            withAnimation(.airfit) { selectedTab = 2 }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openInsightsTab)) { _ in
            withAnimation(.airfit) { selectedTab = 3 }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openProfileTab)) { _ in
            withAnimation(.airfit) { selectedTab = 4 }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // Smart sync: detects if user was away for a "workout-length" duration
                // If so, aggressively syncs Hevy since they may have just logged a workout
                Task {
                    await AutoSyncManager.shared.appDidBecomeActive(modelContext: modelContext)
                }
            case .background:
                // Track when app went to background for workout duration detection
                AutoSyncManager.shared.appDidEnterBackground()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            NutritionEntry.self,
            Conversation.self,
            CachedWorkout.self,
            CachedSetTracker.self,
            CachedLiftProgress.self,
            HevyCacheMetadata.self,
            LocalInsight.self
        ], inMemory: true)
}
