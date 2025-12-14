import SwiftUI
import SwiftData
import UserNotifications

@main
struct AirFitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: NutritionEntry.self)
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

        switch actionId {
        case "LOG_FOOD":
            // Post notification to open nutrition tab
            await MainActor.run {
                NotificationCenter.default.post(name: .openNutritionTab, object: nil)
            }
        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openNutritionTab = Notification.Name("openNutritionTab")
    static let profileReset = Notification.Name("profileReset")
}

// MARK: - Content View with Ethereal Background

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedTab = 0

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

            // Main tab content
            TabView(selection: $selectedTab) {
                NavigationStack {
                    ChatView()
                }
                .tabItem {
                    Label("Coach", systemImage: "message.fill")
                }
                .tag(0)

                NavigationStack {
                    NutritionView()
                }
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
                .tag(1)

                NavigationStack {
                    InsightsView()
                }
                .tabItem {
                    Label("Insights", systemImage: "sparkles")
                }
                .tag(2)

                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Label("Profile", systemImage: "brain.head.profile")
                }
                .tag(3)

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
            }
            .tint(Theme.accent)
        }
        .animation(.airfitMorph, value: selectedTab)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .task {
            await AutoSyncManager.shared.performLaunchSync(modelContext: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openNutritionTab)) { _ in
            withAnimation(.airfit) {
                selectedTab = 1
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: NutritionEntry.self, inMemory: true)
}
