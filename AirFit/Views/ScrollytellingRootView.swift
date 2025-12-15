import SwiftUI
import SwiftData

// MARK: - Scrollytelling Root View

/// Main container view that replaces TabView with horizontal scrollytelling navigation.
/// Features:
/// - Breathing MeshGradient background with parallax
/// - Horizontal paging ScrollView for tab content
/// - Custom floating tab bar
/// - Smooth color interpolation between tabs
struct ScrollytellingRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: Int = 0
    @State private var scrollPosition: Int? = 0
    @State private var scrollOffset: CGFloat = 0

    /// Normalized scroll progress from 0.0 to 4.0
    private var scrollProgress: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        guard screenWidth > 0 else { return 0 }
        return max(0, scrollOffset / screenWidth)
    }

    var body: some View {
        ZStack {
            // Breathing background
            BreathingMeshBackground(scrollProgress: scrollProgress)
                .ignoresSafeArea()

            // Horizontal paging content
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        TabPageContainer(index: index)
                            .containerRelativeFrame(.horizontal)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .scrollPosition(id: $scrollPosition)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.x
            } action: { _, newValue in
                scrollOffset = newValue
            }
            .onChange(of: scrollPosition) { _, newPosition in
                if let newPosition {
                    selectedTab = newPosition
                }
            }

            // Floating tab bar
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab, onTap: scrollToTab)
            }
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
        .task {
            await AutoSyncManager.shared.performLaunchSync(modelContext: modelContext)
        }
        // Notification handlers for deep linking
        .onReceive(NotificationCenter.default.publisher(for: .openDashboardTab)) { _ in
            scrollToTab(0)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openNutritionTab)) { _ in
            scrollToTab(1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCoachTab)) { _ in
            scrollToTab(2)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openInsightsTab)) { _ in
            scrollToTab(3)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openProfileTab)) { _ in
            scrollToTab(4)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Sync when app comes to foreground
                Task {
                    await AutoSyncManager.shared.performLaunchSync(modelContext: modelContext)
                }
            }
        }
    }

    /// Programmatically scroll to a specific tab
    private func scrollToTab(_ index: Int) {
        withAnimation(.storytelling) {
            scrollPosition = index
            selectedTab = index
        }
    }
}

// MARK: - Tab Page Container

/// Wrapper for each tab's content - no NavigationStack to avoid opaque backgrounds
private struct TabPageContainer: View {
    let index: Int

    var body: some View {
        Group {
            switch index {
            case 0:
                DashboardView()
            case 1:
                NutritionView()
            case 2:
                ChatView()
            case 3:
                InsightsView()
            case 4:
                ProfileView()
            default:
                DashboardView()
            }
        }
        .scrollContentBackground(.hidden)
        .background(.clear)
    }
}

// MARK: - Preview

#Preview("Scrollytelling Root") {
    ScrollytellingRootView()
        .modelContainer(for: NutritionEntry.self, inMemory: true)
}

#Preview("Scrollytelling Root - Dark") {
    ScrollytellingRootView()
        .modelContainer(for: NutritionEntry.self, inMemory: true)
        .preferredColorScheme(.dark)
}
