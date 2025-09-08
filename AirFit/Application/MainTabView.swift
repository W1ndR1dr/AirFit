import SwiftUI
import SwiftData

/// Main tab-based navigation view for the app
///
/// This is the primary navigation structure, making chat the default and most prominent feature
/// while providing easy access to dashboard, food tracking, workouts, and profile.
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.diContainer) private var diContainer
    @EnvironmentObject private var gradientManager: GradientManager

    @State private var navigationState = NavigationState()

    let user: User

    // For tab bar gradient animation
    @State
    private var tabBarGradientPhase: CGFloat = 0

    var body: some View {
        ZStack {
            // Main tab content
            TabView(selection: $navigationState.selectedTab) {
                // Chat - Primary interaction
                NavigationStack {
                    ChatViewWrapper(user: user)
                }
                .tag(AppTab.chat)
                .tabItem {
                    Label(AppTab.chat.displayName, systemImage: AppTab.chat.systemImage)
                }

                // Today - Daily overview
                NavigationStack {
                    TodayDashboardView(user: user)
                }
                .tag(AppTab.today)
                .tabItem {
                    Label(AppTab.today.displayName, systemImage: AppTab.today.systemImage)
                }

                // Nutrition - Enhanced nutrition dashboard
                NavigationStack {
                    NutritionDashboardView(user: user)
                }
                .tag(AppTab.nutrition)
                .tabItem {
                    Label(AppTab.nutrition.displayName, systemImage: AppTab.nutrition.systemImage)
                }


                // Body - Metrics & progress
                NavigationStack {
                    BodyDashboardView(user: user)
                }
                .tag(AppTab.body)
                .tabItem {
                    Label(AppTab.body.displayName, systemImage: AppTab.body.systemImage)
                }
            }
            .tint(gradientManager.active.colors(for: colorScheme)[0])
            .onAppear {
                customizeTabBar()
            }

            // Floating AI Assistant overlay
            if navigationState.selectedTab != .chat {
                FloatingAIAssistant(navigationState: navigationState)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .task {
            // Update quick actions periodically
            await updateQuickActions()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await updateQuickActions()
            }
        }
    }

    // MARK: - Helper Methods

    private func customizeTabBar() {
        SurfaceSystem.configureTabBarAppearance(for: colorScheme)
    }

    private func updateQuickActions() async {
        // Fetch today's food entries to determine logged meals
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { entry in
                entry.loggedAt >= startOfDay && entry.loggedAt < endOfDay
            }
        )

        let todaysEntries = (try? modelContext.fetch(descriptor)) ?? []

        // Check which meals have been logged
        let hasLoggedBreakfast = todaysEntries.contains { $0.mealType == MealType.breakfast.rawValue }
        let hasLoggedLunch = todaysEntries.contains { $0.mealType == MealType.lunch.rawValue }
        let hasLoggedDinner = todaysEntries.contains { $0.mealType == MealType.dinner.rawValue }

        let context = AppContext(
            hasLoggedBreakfast: hasLoggedBreakfast,
            hasLoggedLunch: hasLoggedLunch,
            hasLoggedDinner: hasLoggedDinner,
            lastWorkoutDate: nil,
            currentTab: navigationState.selectedTab,
            timeOfDay: getCurrentTimeOfDay()
        )

        navigationState.updateQuickActions(for: context)
    }

    private func getCurrentTimeOfDay() -> AppContext.TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
}

// MARK: - Floating AI Assistant

struct FloatingAIAssistant: View {
    let navigationState: NavigationState
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    @State private var pulseAnimation = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    // FAB Button
                    Button {
                        navigationState.toggleFAB()
                    } label: {
                        ZStack {
                            // Gradient background with pulse
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                .opacity(pulseAnimation ? 0.8 : 1.0)
                                .animation(
                                    .easeInOut(duration: 2)
                                        .repeatForever(autoreverses: true),
                                    value: pulseAnimation
                                )

                            // Icon
                            Image(systemName: navigationState.fabIsExpanded ? "xmark" : "message.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(navigationState.fabIsExpanded ? 90 : 0))
                                .animation(.spring(duration: 0.3), value: navigationState.fabIsExpanded)
                        }
                        .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.3), radius: 12, y: 4)
                    }
                    .scaleEffect(navigationState.fabScale)
                    .position(
                        x: navigationState.fabPosition.x + navigationState.fabDragOffset.width,
                        y: navigationState.fabPosition.y + navigationState.fabDragOffset.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                navigationState.fabDragOffset = value.translation
                            }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    // Update position and reset offset
                                    navigationState.fabPosition.x += value.translation.width
                                    navigationState.fabPosition.y += value.translation.height
                                    navigationState.fabDragOffset = .zero

                                    // Keep within bounds
                                    navigationState.fabPosition.x = min(max(40, navigationState.fabPosition.x), geometry.size.width - 40)
                                    navigationState.fabPosition.y = min(max(100, navigationState.fabPosition.y), geometry.size.height - 100)
                                }
                            }
                    )

                    // Expanded quick actions
                    if navigationState.fabIsExpanded {
                        VStack(alignment: .trailing, spacing: 12) {
                            ForEach(navigationState.suggestedQuickActions) { action in
                                FloatingQuickActionButton(action: action) {
                                    navigationState.executeIntent(.logQuickAction(type: action.action))
                                    navigationState.toggleFAB()
                                }
                            }

                            // Voice input button
                            Button {
                                navigationState.voiceInputActive = true
                                navigationState.toggleFAB()
                            } label: {
                                HStack {
                                    Text("Voice command")
                                        .font(.system(size: 14, weight: .medium))
                                    Image(systemName: "mic.fill")
                                }
                                .foregroundColor(.primary)
                                .surfaceCapsule(.thin)
                            }
                        }
                        .padding(.trailing, 80)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
        }
        .onAppear {
            pulseAnimation = navigationState.hasUnreadMessages
        }
    }
}

// MARK: - Quick Action Button

struct FloatingQuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(action.title)
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: action.systemImage)
            }
            .foregroundColor(.primary)
            .surfaceCapsule(.thin)
        }
    }
}

// MARK: - Dashboard Views

// NutritionDashboardView is now implemented in its own file
// BodyDashboardView is now implemented in its own file

// MARK: - View Wrappers

struct ChatViewWrapper: View {
    let user: User
    @State
    private var viewModel: ChatViewModel?
    @Environment(\.diContainer)
    private var container

    var body: some View {
        Group {
            if let viewModel = viewModel {
                ChatView(viewModel: viewModel, user: user)
            } else {
                ProgressView()
                    .task {
                        let factory = DIViewModelFactory(container: container)
                        viewModel = try? await factory.makeChatViewModel(user: user)
                    }
            }
        }
    }
}

struct FoodLoggingViewWrapper: View {
    let user: User
    @State
    private var viewModel: FoodTrackingViewModel?
    @Environment(\.diContainer)
    private var container

    var body: some View {
        Group {
            if let viewModel = viewModel {
                FoodLoggingView(viewModel: viewModel)
            } else {
                ProgressView()
                    .task {
                        let factory = DIViewModelFactory(container: container)
                        viewModel = try? await factory.makeFoodTrackingViewModel(user: user)
                    }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let container = ModelContainer.preview
    let user = User(name: "Preview User")
    container.mainContext.insert(user)

    return MainTabView(user: user)
        .modelContainer(container)
        .withDIContainer(DIContainer())
}
