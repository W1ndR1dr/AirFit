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
    
    // iOS 26 Liquid Glass morphing namespace
    @Namespace private var tabMorphing

    var body: some View {
        ZStack {
            // Main tab content - Custom implementation
            ZStack {
                // Chat - Primary interaction
                if navigationState.selectedTab == .chat {
                    NavigationStack {
                        ChatViewWrapper(user: user)
                            .navigationBarHidden(true)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                    .transition(.opacity)
                }
                
                // Today - Daily overview
                if navigationState.selectedTab == .today {
                    NavigationStack {
                        TodayDashboardView(user: user)
                            .navigationBarHidden(true)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                    .transition(.opacity)
                }
                
                // Nutrition - Enhanced nutrition dashboard
                if navigationState.selectedTab == .nutrition {
                    NavigationStack {
                        NutritionDashboardView(user: user)
                            .navigationBarHidden(true)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                    .transition(.opacity)
                }
                
                // Workouts - Enhanced workout dashboard
                if navigationState.selectedTab == .workouts {
                    NavigationStack {
                        WorkoutDashboardView(user: user)
                            .navigationBarHidden(true)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                    .transition(.opacity)
                }
                
                // Body - Metrics & progress
                if navigationState.selectedTab == .body {
                    NavigationStack {
                        BodyDashboardView(user: user)
                            .navigationBarHidden(true)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                    .transition(.opacity)
                }
            }
            .animation(SoftMotion.standard, value: navigationState.selectedTab)

            // Custom Glass Morphism Tab Bar
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $navigationState.selectedTab, tabMorphing: tabMorphing)
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, AppSpacing.md)
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
        .onCameraCaptureEvent { phase in
            // Global Camera Control support for quick photo capture
            if phase == .ended && navigationState.selectedTab != .nutrition {
                // Only handle Camera Control if not already on nutrition tab
                // (PhotoInputView will handle it when on nutrition)
                navigationState.showPhotoCapture()
            }
        }
    }

    // MARK: - Helper Methods

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
                                    .smooth(duration: 2)
                                        .repeatForever(autoreverses: true),
                                    value: pulseAnimation
                                )

                            // Icon
                            Image(systemName: navigationState.fabIsExpanded ? "xmark" : "message.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(navigationState.fabIsExpanded ? 90 : 0))
                                .animation(.bouncy(duration: 0.3), value: navigationState.fabIsExpanded)
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
                                .glassEffect(.thin, in: .capsule)
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
            .glassEffect(.thin, in: .capsule)
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
                TextLoadingView(message: "Loading coach")
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
                TextLoadingView(message: "Loading nutrition tracker")
                    .task {
                        let factory = DIViewModelFactory(container: container)
                        viewModel = try? await factory.makeFoodTrackingViewModel(user: user)
                    }
            }
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    let tabMorphing: Namespace.ID
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    tabMorphing: tabMorphing,
                    action: {
                        withAnimation(.bouncy) {
                            selectedTab = tab
                        }
                        // Haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 60)
        .background {
            // Glass morphism background
            ZStack {
                // Base material
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .glassEffect(in: .rect(cornerRadius: 30))
                
                // Gradient overlay at 5% opacity
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme)
                                .map { $0.opacity(0.05) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border subtle highlight
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            }
        }
        .shadow(
            color: .black.opacity(0.1),
            radius: 20,
            x: 0,
            y: 8
        )
        .padding(.horizontal, AppSpacing.xs)
    }
}

struct TabBarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let tabMorphing: Namespace.ID
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon
                Image(systemName: tab.systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        isSelected ? 
                        AnyShapeStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) :
                        AnyShapeStyle(.secondary)
                    )
                    .opacity(isSelected ? 1.0 : 0.6)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(SoftMotion.emphasize, value: isSelected)
                
                // Gradient dot indicator for selected tab
                if isSelected {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 4, height: 4)
                        .transition(.scale.combined(with: .opacity))
                        .animation(SoftMotion.emphasize, value: isSelected)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .glassEffect(
            isSelected ? .regular : .thin,
            in: .rect(cornerRadius: 20)
        )
        .glassEffectID("tab-\(tab.rawValue)", in: tabMorphing)
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
