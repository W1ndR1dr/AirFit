import SwiftUI
import SwiftData

@main
struct AirFitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: NutritionEntry.self)
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label("Coach", systemImage: "message.fill")
                }
                .tag(0)

            NutritionView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
                .tag(1)

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "sparkles")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "brain.head.profile")
                }
                .tag(3)
        }
    }
}
