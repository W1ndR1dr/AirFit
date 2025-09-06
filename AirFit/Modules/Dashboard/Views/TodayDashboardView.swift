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
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Main content with text hierarchy
                        VStack(alignment: .leading, spacing: AppSpacing.xl) {
                            // Dynamic header with CascadeText
                            minimalistHeader()
                            
                            // Nutrition section with text hierarchy
                            nutritionTextSection()
                            
                            // Today's insights in text format
                            if let viewModel = viewModel {
                                if viewModel.isLoading {
                                    loadingView
                                } else if let error = viewModel.error {
                                    errorView(error, viewModel)
                                } else {
                                    insightsTextSection(viewModel)
                                }
                            }
                            
                            // Quick actions in text format
                            if let viewModel = viewModel {
                                actionsTextSection()
                            }
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, AppSpacing.md)
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationBarHidden(true)
                .toolbar(.hidden, for: .navigationBar)
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
        .onReceive(NotificationCenter.default.publisher(for: .foodEntrySaved)) { _ in
            viewModel?.refreshDashboard()
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(user: user)
            }
        }
        .accessibilityIdentifier("today.dashboard")
    }

    // MARK: - Minimalist Header
    
    @ViewBuilder
    private func minimalistHeader() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Time-based greeting with CascadeText
            CascadeText(timeBasedGreeting(), alignment: .leading)
                .font(.system(size: 34, weight: .thin, design: .rounded))
                .foregroundStyle(.primary)

            // Subtitle with AI content when available
            if let viewModel = viewModel,
               let content = viewModel.aiDashboardContent {
                Text(content.primaryInsight)
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(MotionToken.standardSpring, value: content.primaryInsight)
            } else if isInitializing {
                Text(getLoadingSubtitle())
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundStyle(.secondary.opacity(0.7))
                    .redacted(reason: .placeholder)
                    .shimmering()
            }
        }
    }
    
    // MARK: - Nutrition Text Section
    @ViewBuilder
    private func nutritionTextSection() -> some View {
        let summary = makeFoodNutritionSummary()
        
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Section header
            GradientText("Today's Nutrition", style: .primary)
                .font(.title2)
                .fontWeight(.medium)
                .cascadeIn(delay: 0.1)
            
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Calories - primary metric
                VStack(alignment: .leading, spacing: 4) {
                    Text("Energy")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("\(Int(summary.calories)) calories")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("of \(Int(summary.calorieGoal)) goal • \(Int((summary.calories / summary.calorieGoal) * 100))%")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .cascadeIn(delay: 0.2)
                
                // Macronutrients in text format
                HStack(spacing: AppSpacing.lg) {
                    // Protein
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Protein")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("\(Int(summary.protein))g")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(Int((summary.protein / summary.proteinGoal) * 100))%")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Carbs  
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Carbs")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("\(Int(summary.carbs))g")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(Int((summary.carbs / summary.carbGoal) * 100))%")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Fat
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fat")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("\(Int(summary.fat))g")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(Int((summary.fat / summary.fatGoal) * 100))%")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .cascadeIn(delay: 0.3)
                
                // Adjustment note
                if let vm = viewModel, let pct = vm.nutritionAdjustmentPercent, abs(pct) > 0.001 {
                    Text(String(format: "Adjusted %+.0f%% based on activity/intake", pct * 100))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .cascadeIn(delay: 0.4)
                }
            }
        }
    }
    
    // MARK: - Skeleton Content
    
    @ViewBuilder
    private func skeletonContent() -> some View {
        VStack(spacing: AppSpacing.xl) {
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


    // MARK: - Insights Text Section

    @ViewBuilder
    private func insightsTextSection(_ viewModel: DashboardViewModel) -> some View {
        // AI Guidance in text format
        if let content = viewModel.aiDashboardContent {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if let guidance = content.guidance {
                    VStack(alignment: .leading, spacing: 4) {
                        GradientText("Today's Focus", style: .subtle)
                            .font(.caption)
                        Text(guidance)
                            .font(.title3)
                            .fontWeight(.medium)
                            .lineSpacing(2)
                            .foregroundStyle(.primary)
                    }
                    .cascadeIn(delay: 0.5)
                }

                if let celebration = content.celebration {
                    VStack(alignment: .leading, spacing: 4) {
                        GradientText("Achievement", style: .success)
                            .font(.caption)
                        Text(celebration)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                    .cascadeIn(delay: 0.6)
                }
            }
        }
    }


    private func makeFoodNutritionSummary() -> FoodNutritionSummary {
        if let vm = viewModel {
            let s = vm.nutritionSummary
            let t = vm.nutritionTargets
            return FoodNutritionSummary(
                calories: s.calories,
                protein: s.protein,
                carbs: s.carbs,
                fat: s.fat,
                fiber: s.fiber,
                sugar: 0,
                sodium: 0,
                calorieGoal: t.calories,
                proteinGoal: t.protein,
                carbGoal: t.carbs,
                fatGoal: t.fat
            )
        } else {
            let t = NutritionTargets.default
            return FoodNutritionSummary(
                calories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                fiber: 0,
                sugar: 0,
                sodium: 0,
                calorieGoal: t.calories,
                proteinGoal: t.protein,
                carbGoal: t.carbs,
                fatGoal: t.fat
            )
        }
    }

    // MARK: - Actions Text Section

    @ViewBuilder
    private func actionsTextSection() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section header
            GradientText("Right Now", style: .accent)
                .font(.title2)
                .fontWeight(.medium)
                .cascadeIn(delay: 0.7)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Dynamic quick actions in text format
                ForEach(Array(getQuickActions().enumerated()), id: \.offset) { index, action in
                    Button {
                        HapticService.impact(.light)
                        handleQuickAction(action.action)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(action.subtitle)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, AppSpacing.xs)
                    }
                    .buttonStyle(.plain)
                    .cascadeIn(delay: 0.8 + Double(index) * 0.1)
                }
            }
        }
    }

    // MARK: - Loading & Error Views

    private var loadingView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Loading")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text("Preparing your day...")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppSpacing.lg)
        .accessibilityIdentifier("today.loading")
    }

    private func errorView(_ error: Error, _ viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Error")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("Something went wrong")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                HapticService.impact(.light)
                viewModel.refreshDashboard()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Retry")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("Tap to try again")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, AppSpacing.xs)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppSpacing.lg)
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

        // Time-based meal suggestions with photo options
        switch hour {
        case 6..<10:
            actions.append(QuickAction(
                title: "Log Breakfast",
                subtitle: "Start your day right",
                systemImage: "sunrise.fill",
                color: "orange",
                action: .logMeal(type: .breakfast)
            ))
            // Add photo option for breakfast
            actions.append(QuickAction(
                title: "Photo Breakfast",
                subtitle: "New! Snap a photo to log",
                systemImage: "camera.fill",
                color: "orange",
                action: .logMealWithPhoto(type: .breakfast)
            ))
        case 11..<14:
            actions.append(QuickAction(
                title: "Log Lunch",
                subtitle: "Fuel your afternoon",
                systemImage: "sun.max.fill",
                color: "yellow",
                action: .logMeal(type: .lunch)
            ))
            // Add photo option for lunch
            actions.append(QuickAction(
                title: "Photo Lunch",
                subtitle: "New! Snap a photo to log",
                systemImage: "camera.fill",
                color: "yellow",
                action: .logMealWithPhoto(type: .lunch)
            ))
        case 17..<20:
            actions.append(QuickAction(
                title: "Log Dinner",
                subtitle: "End well",
                systemImage: "moon.fill",
                color: "purple",
                action: .logMeal(type: .dinner)
            ))
            // Add photo option for dinner
            actions.append(QuickAction(
                title: "Photo Dinner",
                subtitle: "New! Snap a photo to log",
                systemImage: "camera.fill",
                color: "purple",
                action: .logMealWithPhoto(type: .dinner)
            ))
        default:
            // Show general photo logging option during off-meal times
            actions.append(QuickAction(
                title: "Log with Photo",
                subtitle: "New! Capture your meal instantly",
                systemImage: "camera.fill",
                color: "orange",
                action: .logMealWithPhoto(type: .snack)
            ))
        }

        return actions
    }

    private func handleQuickAction(_ action: QuickAction.QuickActionType) {
        switch action {
        case .logMeal:
            coordinator.navigate(to: .nutritionDetail)
        case .logMealWithPhoto:
            // Navigate directly to the photo capture interface
            coordinator.navigate(to: .nutritionDetail) // This will be handled by the navigation system to show photo capture
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
                    .animation(.bouncy(duration: 0.5), value: progress)

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
    let container = try! ModelContainer(for: User.self) // swiftlint:disable:this force_try
    let user = User(name: "Preview")
    container.mainContext.insert(user)

    return TodayDashboardView(user: user)
        .withDIContainer(DIContainer())
        .modelContainer(container)
}
