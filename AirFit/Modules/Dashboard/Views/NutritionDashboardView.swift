import SwiftUI
// SwiftData removed - using repository pattern
import Charts

/// Enhanced Nutrition Dashboard - Comprehensive nutrition tracking with AI insights
struct NutritionDashboardView: View {
    let user: User
    @State private var viewModel: FoodTrackingViewModel?
    @Environment(\.diContainer) private var container
    // @Environment(\.modelContext) - removed, using repository pattern
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    @State private var coordinator = FoodTrackingCoordinator()
    @State private var hasAppeared = false
    @State private var selectedTimeframe: NutritionTimeframe = .today
    @State private var animateIn = false
    @State private var isInitializing = true

    enum NutritionTimeframe: String, CaseIterable {
        case today = "Today"
        case week = "Week"
        case month = "Month"

        var displayName: String { rawValue }
    }

    var body: some View {
        BaseScreen {
            NavigationStack(path: $coordinator.navigationPath) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header is always visible
                        nutritionHeaderImmediate()
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)
                            .animation(MotionToken.standardSpring, value: animateIn)

                        // Timeframe selector - always visible
                        timeframePicker
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.lg)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)
                            .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                        // Content or skeleton
                        if let viewModel = viewModel {
                            // Main content based on timeframe
                            switch selectedTimeframe {
                            case .today:
                                todayNutritionView(viewModel)
                            case .week:
                                weekNutritionView(viewModel)
                            case .month:
                                monthNutritionView(viewModel)
                            }
                        } else if isInitializing {
                            // Skeleton content while loading
                            nutritionSkeletonContent()
                        }
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
                .scrollContentBackground(.hidden)
                .navigationBarHidden(true)
                .toolbar(.hidden, for: .navigationBar)
                .refreshable {
                    if let viewModel = viewModel {
                        await viewModel.loadTodaysData()
                    }
                }
                .navigationDestination(for: FoodTrackingDestination.self) { destination in
                    destinationView(for: destination)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            HapticService.impact(.light)
                            coordinator.presentVoiceInput()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                        }
                        .accessibilityLabel("Add Food")
                        .disabled(viewModel == nil)
                        .opacity(viewModel == nil ? 0.5 : 1)
                    }
                }
            }
        }
        .task {
            guard viewModel == nil else { return }
            isInitializing = true
            let factory = DIViewModelFactory(container: container)
            viewModel = try? await factory.makeFoodTrackingViewModel(user: user)
            isInitializing = false
            
            if let viewModel = viewModel, !hasAppeared {
                hasAppeared = true
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
                await viewModel.loadTodaysData()
            }
        }
        .accessibilityIdentifier("nutrition.dashboard")
    }


    // MARK: - Header

    @ViewBuilder
    private func nutritionHeaderImmediate() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            CascadeText("Nutrition")
                .font(.system(size: 34, weight: .thin, design: .rounded))

            // Show contextual message while loading
            Text(nutritionLoadingMessage())
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func nutritionLoadingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10:
            return "Loading your breakfast tracking..."
        case 10..<12:
            return "Checking your morning nutrition..."
        case 12..<14:
            return "Loading lunch data..."
        case 14..<17:
            return "Reviewing your afternoon intake..."
        case 17..<20:
            return "Loading dinner tracking..."
        default:
            return "Analyzing your daily nutrition..."
        }
    }

    @ViewBuilder
    private func nutritionHeader(_ viewModel: FoodTrackingViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            CascadeText("Nutrition")
                .font(.system(size: 34, weight: .thin, design: .rounded))

            // AI-powered nutrition insight
            if let aiInsight = generateNutritionInsight(from: viewModel) {
                Text(aiInsight)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Timeframe Picker

    private var timeframePicker: some View {
        HStack(spacing: 0) {
            ForEach(NutritionTimeframe.allCases, id: \.self) { timeframe in
                timeframeButton(timeframe)
            }
        }
        .padding(4)
        .glassEffect(.thick, in: .rect(cornerRadius: 16))
    }

    @ViewBuilder
    private func timeframeButton(_ timeframe: NutritionTimeframe) -> some View {
        Button {
            HapticService.impact(.light)
            withAnimation(MotionToken.standardSpring) {
                selectedTimeframe = timeframe
            }
        } label: {
            Text(timeframe.displayName)
                .font(.system(size: 16, weight: selectedTimeframe == timeframe ? .semibold : .medium))
                .foregroundStyle(selectedTimeframe == timeframe ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedTimeframe == timeframe ? Color.primary.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Today View

    @ViewBuilder
    private func todayNutritionView(_ viewModel: FoodTrackingViewModel) -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Enhanced macro rings with dynamic targets
            MacroRingsView(
                nutrition: viewModel.todaysNutrition,
                style: .full,
                animateOnAppear: true
            )
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.top, AppSpacing.lg)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
            .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

            // Today's meal timeline
            todaysMealTimeline(viewModel)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

            // Quick actions for adding food
            quickFoodActions
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)

            // Recent foods for quick logging
            if !viewModel.recentFoods.isEmpty {
                recentFoodsSection(viewModel)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(MotionToken.standardSpring.delay(0.5), value: animateIn)
            }
        }
    }

    // MARK: - Week View

    @ViewBuilder
    private func weekNutritionView(_ viewModel: FoodTrackingViewModel) -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Weekly nutrition trends chart
            weeklyTrendsChart
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, AppSpacing.lg)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

            // Weekly averages summary
            weeklyAveragesCard
                .padding(.horizontal, AppSpacing.screenPadding)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
        }
    }

    // MARK: - Month View

    @ViewBuilder
    private func monthNutritionView(_ viewModel: FoodTrackingViewModel) -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Monthly patterns and insights
            monthlyInsightsCard
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, AppSpacing.lg)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

            // Compliance tracking
            complianceTrackingCard
                .padding(.horizontal, AppSpacing.screenPadding)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
        }
    }

    // MARK: - Today's Meal Timeline

    @ViewBuilder
    private func todaysMealTimeline(_ viewModel: FoodTrackingViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Today's Meals")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(viewModel.todaysFoodEntries.count) logged")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.screenPadding)

            if viewModel.todaysFoodEntries.isEmpty {
                emptyMealsState
            } else {
                mealTimelineList(viewModel)
            }
        }
    }

    private var emptyMealsState: some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))

                Text("No meals logged today")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)

                Text("Start tracking your nutrition to see insights and progress")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticService.impact(.light)
                    coordinator.presentVoiceInput()
                } label: {
                    Text("Add First Meal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(gradientManager.currentGradient(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, AppSpacing.sm)
            }
            .padding(AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.screenPadding)
    }

    @ViewBuilder
    private func mealTimelineList(_ viewModel: FoodTrackingViewModel) -> some View {
        LazyVStack(spacing: AppSpacing.sm) {
            ForEach(viewModel.todaysFoodEntries) { entry in
                MealTimelineCard(entry: entry) {
                    // Navigate to food detail or edit
                    coordinator.navigateToFoodDetail(entry)
                }
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
    }

    // MARK: - Quick Actions

    private var quickFoodActions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Quick Add")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, AppSpacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    QuickFoodActionCard(
                        title: "Voice Input",
                        subtitle: "Say what you ate",
                        systemImage: "mic.fill",
                        color: .blue
                    ) {
                        coordinator.presentVoiceInput()
                    }

                    QuickFoodActionCard(
                        title: "Photo",
                        subtitle: "Snap your meal",
                        systemImage: "camera.fill",
                        color: .green
                    ) {
                        coordinator.presentPhotoInput()
                    }

                    QuickFoodActionCard(
                        title: "Search",
                        subtitle: "Find foods",
                        systemImage: "magnifyingglass",
                        color: .orange
                    ) {
                        coordinator.presentFoodSearch()
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    // MARK: - Recent Foods

    @ViewBuilder
    private func recentFoodsSection(_ viewModel: FoodTrackingViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Recent Foods")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, AppSpacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.recentFoods.prefix(8), id: \.id) { food in
                        RecentFoodCard(food: food) {
                            coordinator.presentQuickLog(food)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    // MARK: - Weekly Charts

    private var weeklyTrendsChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Weekly Trends")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                // Placeholder for weekly nutrition chart
                Chart {
                    ForEach(0..<7, id: \.self) { day in
                        BarMark(
                            x: .value("Day", Calendar.current.shortWeekdaySymbols[day]),
                            y: .value("Calories", Double.random(in: 1_500...2_500))
                        )
                        .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private var weeklyAveragesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Weekly Averages")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: AppSpacing.lg) {
                    WeeklyAverageItem(
                        title: "Calories",
                        value: "2,180",
                        target: "2,200",
                        color: gradientManager.active.colors(for: colorScheme)[0]
                    )

                    WeeklyAverageItem(
                        title: "Protein",
                        value: "145g",
                        target: "150g",
                        color: .red
                    )

                    WeeklyAverageItem(
                        title: "Carbs",
                        value: "275g",
                        target: "280g",
                        color: .green
                    )

                    WeeklyAverageItem(
                        title: "Fat",
                        value: "85g",
                        target: "75g",
                        color: .yellow
                    )
                }
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Monthly Views

    private var monthlyInsightsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Monthly Insights")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    NutritionInsightRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Consistency Improving",
                        subtitle: "You've hit your protein goal 85% of the time this month"
                    )

                    NutritionInsightRow(
                        icon: "clock.fill",
                        title: "Meal Timing",
                        subtitle: "Your best energy comes from meals spaced 4-5 hours apart"
                    )

                    NutritionInsightRow(
                        icon: "brain.head.profile",
                        title: "Pattern Recognition",
                        subtitle: "Higher carbs on workout days improved your session quality"
                    )
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private var complianceTrackingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Compliance Tracking")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                ComplianceGrid()
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Helper Methods

    private func generateNutritionInsight(from viewModel: FoodTrackingViewModel) -> String? {
        let hour = Calendar.current.component(.hour, from: Date())
        let summary = viewModel.todaysNutrition
        let remainingCalories = summary.calorieGoal - summary.calories

        switch hour {
        case 6..<12:
            if summary.calories < summary.calorieGoal * 0.2 {
                return "Good morning. Start strong with a protein-rich breakfast to fuel your day."
            }
            return "Morning nutrition is on track. Keep the momentum going."

        case 12..<17:
            if remainingCalories > summary.calorieGoal * 0.6 {
                return "Afternoon energy dip? Time for a balanced meal to power through."
            }
            return "Solid progress on your nutrition goals today."

        case 17..<22:
            if remainingCalories > 500 {
                return "Evening wind-down. \(Int(remainingCalories)) calories left to meet your goals."
            }
            return "Excellent nutrition day. Your consistency is paying off."

        default:
            return "Rest and recovery mode. Your nutrition foundation is strong."
        }
    }

    @ViewBuilder
    private func destinationView(for destination: FoodTrackingDestination) -> some View {
        switch destination {
        case .voiceInput:
            Text("Voice Input")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .photoInput:
            Text("Photo Input")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .foodSearch:
            Text("Food Search")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .quickLog:
            Text("Quick Log")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .history:
            Text("History")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .insights:
            Text("Insights")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .favorites:
            Text("Favorites")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .recipes:
            Text("Recipes")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .mealPlan:
            Text("Meal Plan")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .foodDetail:
            Text("Food Detail")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Skeleton Content
    
    @ViewBuilder
    private func nutritionSkeletonContent() -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Nutrition rings skeleton
            HStack(spacing: AppSpacing.lg) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(spacing: AppSpacing.xs) {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                            .frame(width: 70, height: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 40, height: 20)
                                    .shimmering()
                            )
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 50, height: 12)
                            .shimmering()
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.top, AppSpacing.lg)
            
            // Recent meals skeleton
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 120, height: 20)
                    .shimmering()
                
                VStack(spacing: AppSpacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        GlassCard {
                            HStack(spacing: AppSpacing.md) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .shimmering()
                                
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 150, height: 16)
                                        .shimmering()
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 100, height: 12)
                                        .shimmering()
                                }
                                
                                Spacer()
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 60, height: 20)
                                    .shimmering()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            // Chart skeleton
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 100, height: 16)
                        .shimmering()
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 200)
                        .shimmering()
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)
    }
}

// MARK: - Supporting Views

struct MealTimelineCard: View {
    let entry: FoodEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Meal type indicator
                VStack {
                    Circle()
                        .fill(mealTypeColor)
                        .frame(width: 12, height: 12)

                    Rectangle()
                        .fill(mealTypeColor.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(entry.mealType.capitalized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    if let foodName = entry.items.first?.name {
                        Text(foodName)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text("\(Int(entry.items.reduce(0) { $0 + ($1.calories ?? 0) })) cal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(AppSpacing.md)
            .glassEffect(in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var mealTypeColor: Color {
        switch entry.mealType.lowercased() {
        case "breakfast": return .orange
        case "lunch": return .green
        case "dinner": return .purple
        case "snack": return .blue
        default: return .gray
        }
    }
}

struct QuickFoodActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundStyle(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 100)
            .padding(AppSpacing.sm)
            .glassEffect(in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct RecentFoodCard: View {
    let food: FoodItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.xs) {
                Text(food.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("\(Int(food.calories ?? 0)) cal")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, height: 60)
            .padding(AppSpacing.xs)
            .glassEffect(in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct WeeklyAverageItem: View {
    let title: String
    let value: String
    let target: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)

            Text("/ \(target)")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(.tertiary)
        }
    }
}

struct NutritionInsightRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}

struct ComplianceGrid: View {
    @State private var complianceData: [[Double]] = Array(repeating: Array(repeating: 0.0, count: 7), count: 5)

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { week in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { day in
                        ComplianceCell(compliance: complianceData[week][day])
                    }
                }
            }
        }
        .onAppear {
            // Generate sample compliance data
            complianceData = (0..<5).map { _ in
                (0..<7).map { _ in Double.random(in: 0...1) }
            }
        }
    }
}

struct ComplianceCell: View {
    let compliance: Double

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 24, height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var color: Color {
        switch compliance {
        case 0.8...:
            return .green.opacity(0.8)
        case 0.6..<0.8:
            return .yellow.opacity(0.8)
        case 0.3..<0.6:
            return .orange.opacity(0.8)
        default:
            return .red.opacity(0.3)
        }
    }
}

// MARK: - Preview

#Preview {
    // let container = ModelContainer.preview // REMOVED - Using DI
    let user = User(name: "Preview")
    
    NutritionDashboardView(user: user)
        .withDIContainer(DIContainer())
        // .modelContainer(container) // REMOVED - Using DI
}
