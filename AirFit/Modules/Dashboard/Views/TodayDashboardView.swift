import SwiftUI
import SwiftData

/// Today Dashboard - Overview of the user's day with AI insights and quick actions
struct TodayDashboardView: View {
    let user: User
    @State private var viewModel: DashboardViewModel?
    @Environment(\.diContainer) private var container
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    @State private var coordinator = DashboardCoordinator()
    @State private var hasAppeared = false
    @State private var showSettings = false
    
    // Lightweight UI state available immediately
    @State private var isInitializing = true

    var body: some View {
        BaseScreen {
            NavigationStack(path: $coordinator.path) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Dynamic header - always visible
                        dynamicHeaderImmediate()
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.md)
                            .padding(.bottom, AppSpacing.lg)

                        if let viewModel = viewModel {
                            // Full content when ViewModel is ready
                            if viewModel.isLoading {
                                loadingView
                            } else if let error = viewModel.error {
                                errorView(error, viewModel)
                            } else {
                                todayInsights(viewModel)
                            }
                        } else if isInitializing {
                            // Skeleton UI while ViewModel initializes
                            skeletonContent()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationBarTitleDisplayMode(.inline)
                .refreshable { 
                    viewModel?.refreshDashboard() 
                }
                .navigationDestination(for: DashboardDestination.self) { destination in
                    destinationView(for: destination)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            HapticService.impact(.light)
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .accessibilityLabel("Settings")
                    }
                }
            }
        }
        .task {
            guard viewModel == nil else { return }
            isInitializing = true
            let factory = DIViewModelFactory(container: container)
            viewModel = try? await factory.makeDashboardViewModel(user: user)
            isInitializing = false
            
            if let viewModel = viewModel, !hasAppeared {
                hasAppeared = true
                viewModel.onAppear()
            }
        }
        .onDisappear { 
            viewModel?.onDisappear() 
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(user: user)
            }
        }
        .accessibilityIdentifier("today.dashboard")
    }

    // MARK: - Immediate Header (No ViewModel Required)
    
    @ViewBuilder
    private func dynamicHeaderImmediate() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Time-based greeting - available immediately
            CascadeText(timeBasedGreeting())
                .font(.system(size: 34, weight: .thin, design: .rounded))
            
            // Show AI subtitle when available, placeholder when loading
            if let viewModel = viewModel,
               let content = viewModel.aiDashboardContent {
                Text(content.primaryInsight)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(MotionToken.standardSpring, value: content.primaryInsight)
            } else if isInitializing {
                Text(getLoadingSubtitle())
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.secondary.opacity(0.6))
                    .redacted(reason: .placeholder)
                    .shimmering()
            }
        }
    }
    
    // MARK: - Skeleton Content
    
    @ViewBuilder
    private func skeletonContent() -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Progress Rings Skeleton
            HStack(spacing: AppSpacing.lg) {
                ForEach(0..<3) { _ in
                    VStack(spacing: 8) {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                            .frame(width: 90, height: 90)
                            .overlay(
                                VStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 40, height: 20)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.15))
                                        .frame(width: 30, height: 12)
                                }
                            )
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 60, height: 14)
                    }
                    .shimmering()
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            // Quick Actions Skeleton
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 100, height: 20)
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .shimmering()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(0..<2) { _ in
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 140, height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                                .shimmering()
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                }
            }
            
            // AI Guidance Skeleton
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 100, height: 16)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 18)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 250, height: 18)
                    }
                }
                .shimmering()
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
        .padding(.bottom, AppSpacing.xl)
    }

    // MARK: - Dynamic Header

    @ViewBuilder
    private func dynamicHeader(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Time-based greeting
            CascadeText(timeBasedGreeting())
                .font(.system(size: 34, weight: .thin, design: .rounded))

            // AI personalized subtitle
            if let content = viewModel.aiDashboardContent {
                Text(content.primaryInsight)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(MotionToken.standardSpring, value: content.primaryInsight)
            }
        }
    }

    // MARK: - Today's Insights

    @ViewBuilder
    private func todayInsights(_ viewModel: DashboardViewModel) -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Progress Rings
            if let content = viewModel.aiDashboardContent,
               let nutrition = content.nutritionData {
                HStack(spacing: AppSpacing.lg) {
                    // Calories ring
                    ProgressRingView(
                        progress: nutrition.calorieProgress,
                        title: "Calories",
                        value: "\(Int(nutrition.calories))",
                        target: "\(Int(nutrition.calorieTarget))",
                        color: gradientManager.active.colors(for: colorScheme)[0]
                    )

                    // Protein ring
                    ProgressRingView(
                        progress: nutrition.proteinProgress,
                        title: "Protein",
                        value: "\(Int(nutrition.protein))g",
                        target: "\(Int(nutrition.proteinTarget))g",
                        color: .green
                    )

                    // Activity ring (placeholder for now)
                    ProgressRingView(
                        progress: 0.6,
                        title: "Activity",
                        value: "45",
                        target: "60 min",
                        color: .orange
                    )
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }

            // Quick Actions
            quickActionsSection(viewModel)

            // AI Guidance
            if let content = viewModel.aiDashboardContent {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    if let guidance = content.guidance {
                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Today's Focus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.secondary)

                                Text(guidance)
                                    .font(.system(size: 18, weight: .light))
                                    .lineSpacing(2)
                            }
                        }
                    }

                    if let celebration = content.celebration {
                        GlassCard {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20))
                                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))

                                Text(celebration)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
        .padding(.bottom, AppSpacing.xl)
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private func quickActionsSection(_ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Right Now")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    // Dynamic quick actions based on time and context
                    ForEach(getQuickActions(), id: \.title) { action in
                        Button {
                            HapticService.impact(.light)
                            handleQuickAction(action.action)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: action.systemImage)
                                    .font(.system(size: 24))
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(action.title)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.primary)

                                    Text(action.subtitle)
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .frame(width: 140, height: 100)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    // MARK: - Loading & Error Views

    private var loadingView: some View {
        VStack(spacing: AppSpacing.large) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 48, height: 48)

                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: gradientManager.active.colors(for: colorScheme)[0]))
            }

            Text("Loading your day...")
                .font(AppFonts.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .accessibilityIdentifier("today.loading")
    }

    private func errorView(_ error: Error, _ viewModel: DashboardViewModel) -> some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(error.localizedDescription)
                .font(AppFonts.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                HapticService.impact(.light)
                viewModel.refreshDashboard()
            } label: {
                Text("Retry")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.3), radius: 12, y: 4)
            }
            .padding(.horizontal, AppSpacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .accessibilityIdentifier("today.error")
    }

    // MARK: - Helper Methods

    private func timeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = user.name ?? "there"

        switch hour {
        case 5..<12:
            return "Good morning, \(name)"
        case 12..<17:
            return "Good afternoon, \(name)"
        case 17..<22:
            return "Good evening, \(name)"
        default:
            return "Hello, \(name)"
        }
    }

    private func getLoadingSubtitle() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Preparing your morning insights..."
        case 12..<17:
            return "Loading your afternoon summary..."
        case 17..<22:
            return "Getting your evening update..."
        default:
            return "Loading your personalized insights..."
        }
    }
    
    private func getQuickActions() -> [QuickAction] {
        let hour = Calendar.current.component(.hour, from: Date())
        var actions: [QuickAction] = []

        // Time-based meal suggestions
        switch hour {
        case 6..<10:
            actions.append(QuickAction(
                title: "Log Breakfast",
                subtitle: "Start your day right",
                systemImage: "sunrise.fill",
                color: "orange",
                action: .logMeal(type: .breakfast)
            ))
        case 11..<14:
            actions.append(QuickAction(
                title: "Log Lunch",
                subtitle: "Fuel your afternoon",
                systemImage: "sun.max.fill",
                color: "yellow",
                action: .logMeal(type: .lunch)
            ))
        case 17..<20:
            actions.append(QuickAction(
                title: "Log Dinner",
                subtitle: "End well",
                systemImage: "moon.fill",
                color: "purple",
                action: .logMeal(type: .dinner)
            ))
        default:
            break
        }

        // Always show workout

        actions.append(QuickAction(
            title: "Start Workout",
            subtitle: "Let's move",
            systemImage: "figure.run",
            color: "green",
            action: .startWorkout
        ))

        return actions
    }

    private func handleQuickAction(_ action: QuickAction.QuickActionType) {
        switch action {
        case .logMeal:
            coordinator.navigate(to: .nutritionDetail)
        case .startWorkout:
            coordinator.navigate(to: .workoutHistory)
        case .checkIn:
            coordinator.navigate(to: .recoveryDetail)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: DashboardDestination) -> some View {
        switch destination {
        case .nutritionDetail:
            Text("Navigate to Nutrition tab")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .workoutHistory:
            Text("Navigate to Workout tab")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .recoveryDetail:
            Text("Recovery Detail")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .settings:
            SettingsView(user: user)
        }
    }
}

// MARK: - Progress Ring View

struct ProgressRingView: View {
    let progress: Double
    let title: String
    let value: String
    let target: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.5), value: progress)

                VStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text(target)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 90, height: 90)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}


// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: User.self)
    let user = User(name: "Preview")
    container.mainContext.insert(user)

    return TodayDashboardView(user: user)
        .withDIContainer(DIContainer())
        .modelContainer(container)
}
