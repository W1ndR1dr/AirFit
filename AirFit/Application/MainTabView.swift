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
                
                // Dashboard - Daily insights
                NavigationStack {
                    DashboardView(user: user)
                }
                .tag(AppTab.dashboard)
                .tabItem {
                    Label(AppTab.dashboard.displayName, systemImage: AppTab.dashboard.systemImage)
                }
                
                // Food - Nutrition tracking
                NavigationStack {
                    FoodLoggingViewWrapper(user: user)
                }
                .tag(AppTab.food)
                .tabItem {
                    Label(AppTab.food.displayName, systemImage: AppTab.food.systemImage)
                }
                
                // Workouts - Activity tracking
                NavigationStack {
                    WorkoutView(user: user)
                }
                .tag(AppTab.workouts)
                .tabItem {
                    Label(AppTab.workouts.displayName, systemImage: AppTab.workouts.systemImage)
                }
                
                // Profile - Settings & stats
                NavigationStack {
                    ProfileView(user: user)
                }
                .tag(AppTab.profile)
                .tabItem {
                    Label(AppTab.profile.displayName, systemImage: AppTab.profile.systemImage)
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
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Glass morphism effect
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        
        // Apply to tab bar
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func updateQuickActions() async {
        // For now, use simple context based on time
        let context = AppContext(
            hasLoggedBreakfast: false, // TODO: Fetch from nutrition service
            hasLoggedLunch: false,
            hasLoggedDinner: false,
            lastWorkoutDate: nil,
            waterIntakeML: 0,
            waterGoalML: 2_000,
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
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.thinMaterial)
                                .clipShape(Capsule())
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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Placeholder Views (temporary until real views are connected)

struct ProfileView: View {
    let user: User
    
    var body: some View {
        // For now, show settings view as profile
        SettingsView(user: user)
    }
}

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