import SwiftUI
import Charts

// MARK: - Food Tracking View with DI
struct FoodTrackingView: View {
    let user: User
    @State private var viewModel: FoodTrackingViewModel?
    @Environment(\.diContainer) private var container

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

/// Main food logging interface with voice-first workflow and macro visualization.
struct FoodLoggingView: View {
    @State private var viewModel: FoodTrackingViewModel
    @State private var coordinator: FoodTrackingCoordinator
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    init(viewModel: FoodTrackingViewModel, coordinator: FoodTrackingCoordinator = FoodTrackingCoordinator()) {
        _viewModel = State(initialValue: viewModel)
        _coordinator = State(initialValue: coordinator)
    }


    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            BaseScreen {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with title
                        if animateIn {
                            CascadeText("Food Tracking")
                                .font(.system(size: 34, weight: .light, design: .rounded))
                                .padding(.horizontal, AppSpacing.screenPadding)
                                .padding(.top, AppSpacing.md)
                        }

                        datePicker
                            .padding(.top, AppSpacing.sm)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)
                            .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                        macroSummaryCard
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

                        quickActionsSection
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.lg)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)

                        mealsSection
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.lg)

                        if !viewModel.suggestedFoods.isEmpty {
                            suggestionsSection
                                .padding(.top, AppSpacing.lg)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button("Done") {
                    HapticService.impact(.light)
                    dismiss()
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                .padding(AppSpacing.screenPadding)
                .opacity(animateIn ? 1 : 0)
            }
            .navigationDestination(for: FoodTrackingDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(item: $coordinator.activeSheet) { sheet in
                sheetView(for: sheet)
            }
            .fullScreenCover(item: $coordinator.activeFullScreenCover) { cover in
                fullScreenView(for: cover)
            }
            .task {
                await viewModel.loadTodaysData()
            }
            .refreshable {
                await viewModel.loadTodaysData()
            }
            .errorAlert(
                error: $viewModel.error,
                isPresented: $viewModel.isShowingError
            )
            .onAppear {
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
    }

    // MARK: - Date Picker
    private var datePicker: some View {
        HStack {
            Button(action: {
                HapticService.selection()
                previousDay()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
            }

            Spacer()

            Text(viewModel.currentDate.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.primary)

            Spacer()
            Button(action: {
                HapticService.selection()
                nextDay()
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(
                        Calendar.current.isDateInToday(viewModel.currentDate) ?
                            AnyShapeStyle(Color.secondary.opacity(0.3)) :
                            AnyShapeStyle(gradientManager.currentGradient(for: colorScheme))
                    )
            }
            .disabled(Calendar.current.isDateInToday(viewModel.currentDate))
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Macro Summary
    private var macroSummaryCard: some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    Text("Today's Nutrition")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)

                    Spacer()

                    NavigationLink(value: FoodTrackingDestination.insights) {
                        HStack(spacing: 4) {
                            Text("Details")
                                .font(.system(size: 15, weight: .light))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .light))
                        }
                        .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    }
                }

                // Macro rings visualization
                HStack(spacing: AppSpacing.lg) {
                    MacroMetric(
                        title: "Calories",
                        value: Int(viewModel.todaysNutrition.calories),
                        unit: "",
                        color: gradientManager.active == .peachRose ? Color.orange : Color.blue,
                        icon: "flame.fill"
                    )

                    MacroMetric(
                        title: "Protein",
                        value: Int(viewModel.todaysNutrition.protein),
                        unit: "g",
                        color: .purple,
                        icon: "p.square.fill"
                    )

                    MacroMetric(
                        title: "Carbs",
                        value: Int(viewModel.todaysNutrition.carbs),
                        unit: "g",
                        color: .green,
                        icon: "c.square.fill"
                    )

                    MacroMetric(
                        title: "Fat",
                        value: Int(viewModel.todaysNutrition.fat),
                        unit: "g",
                        color: .yellow,
                        icon: "f.square.fill"
                    )
                }

                // Bottom stats bar
                HStack {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                        Text("\(Int(viewModel.todaysNutrition.calories)) / \(Int(viewModel.todaysNutrition.calorieGoal)) cal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    Spacer()
                }
                .padding(.top, AppSpacing.xs)
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Quick Add")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    QuickActionCard(title: "Voice", icon: "mic.fill", gradientColors: [.blue, .purple]) {
                        HapticService.impact(.light)
                        Task { await viewModel.startVoiceInput() }
                    }

                    QuickActionCard(title: "Photo", icon: "camera.fill", gradientColors: [.orange, .pink]) {
                        HapticService.impact(.light)
                        coordinator.showSheet(.photoCapture)
                    }

                    QuickActionCard(title: "Search", icon: "magnifyingglass", gradientColors: [.green, .teal]) {
                        HapticService.impact(.light)
                        coordinator.showSheet(.foodSearch)
                    }

                    QuickActionCard(title: "Manual", icon: "square.and.pencil", gradientColors: [.purple, .indigo]) {
                        HapticService.impact(.light)
                        coordinator.showSheet(.manualEntry)
                    }
                }
            }
        }
    }

    // MARK: - Meals
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Today's Meals")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.primary)

            VStack(spacing: AppSpacing.sm) {
                ForEach(Array(MealType.allCases.enumerated()), id: \.element) { index, mealType in
                    MealCard(
                        mealType: mealType,
                        entries: viewModel.todaysFoodEntries.filter { $0.mealType == mealType.rawValue },
                        onAdd: {
                            HapticService.impact(.light)
                            viewModel.setSelectedMealType(mealType)
                            Task { await viewModel.startVoiceInput() }
                        },
                        onTapEntry: { entry in
                            HapticService.selection()
                            coordinator.showSheet(.mealDetails(entry))
                        }
                    )
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(
                        MotionToken.standardSpring.delay(0.5 + Double(index) * 0.1),
                        value: animateIn
                    )
                }
            }
        }
    }

    // MARK: - Suggestions
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Quick Add Favorites")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal, AppSpacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.suggestedFoods) { food in
                        SuggestionCard(food: food) {
                            HapticService.impact(.light)
                            selectSuggestedFood(food)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    // MARK: - Actions
    private func previousDay() {
        withAnimation {
            viewModel.currentDate = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.currentDate) ?? viewModel.currentDate
        }
        Task { await viewModel.loadTodaysData() }
    }

    private func nextDay() {
        withAnimation {
            viewModel.currentDate = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.currentDate) ?? viewModel.currentDate
        }
        Task { await viewModel.loadTodaysData() }
    }

    private func selectSuggestedFood(_ food: FoodItem) {
        let parsedItem = ParsedFoodItem(
            name: food.name,
            brand: food.brand,
            quantity: food.quantity ?? 1,
            unit: food.unit ?? "serving",
            calories: Int(food.calories ?? 0),
            proteinGrams: food.proteinGrams ?? 0,
            carbGrams: food.carbGrams ?? 0,
            fatGrams: food.fatGrams ?? 0,
            fiberGrams: food.fiberGrams,
            sugarGrams: food.sugarGrams,
            sodiumMilligrams: food.sodiumMg,
            databaseId: nil,
            confidence: 1.0
        )
        viewModel.setParsedItems([parsedItem])
        coordinator.showFullScreenCover(.confirmation([parsedItem]))
    }

    // MARK: - Navigation Helpers
    @ViewBuilder
    private func destinationView(for destination: FoodTrackingDestination) -> some View {
        switch destination {
        case .history:
            PlaceholderView(title: "Food History", subtitle: "Coming in Phase 3")
        case .insights:
            PlaceholderView(title: "Nutrition Insights", subtitle: "Coming in Phase 3")
        case .favorites:
            PlaceholderView(title: "Favorite Foods", subtitle: "Coming in Phase 3")
        case .recipes:
            PlaceholderView(title: "Recipes", subtitle: "Coming in Phase 3")
        case .mealPlan:
            PlaceholderView(title: "Meal Plan", subtitle: "Coming in Phase 3")
        case .voiceInput:
            FoodVoiceInputView(viewModel: viewModel)
        case .photoInput:
            PlaceholderView(title: "Photo Input", subtitle: "Camera-based food recognition")
        case .foodDetail(let entry):
            PlaceholderView(title: "Food Detail", subtitle: "Entry details for \(entry.id)")
        case .foodSearch:
            PlaceholderView(title: "Food Search", subtitle: "Search food database")
        case .quickLog(let food):
            PlaceholderView(title: "Quick Log", subtitle: "Add \(food.name)")
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: FoodTrackingSheet) -> some View {
        switch sheet {
        case .voiceInput:
            FoodVoiceInputView(viewModel: viewModel)
        case .photoCapture:
            PhotoInputView(viewModel: viewModel)
        case .foodSearch:
            PlaceholderView(title: "Food Search", subtitle: "Coming in Phase 3")
        case .manualEntry:
            PlaceholderView(title: "Manual Entry", subtitle: "Coming in Phase 3")
        case .mealDetails(let entry):
            PlaceholderView(title: "Meal Details", subtitle: "Entry: \(entry.mealDisplayName)")
        }
    }

    @ViewBuilder
    private func fullScreenView(for cover: FoodTrackingCoordinator.FoodTrackingFullScreenCover) -> some View {
        switch cover {
        case .camera:
            PlaceholderView(title: "Camera Food Scan", subtitle: "Coming in Phase 4")
        case .confirmation(let items):
            PlaceholderView(title: "Food Confirmation", subtitle: "\(items.count) items to confirm")
        }
    }
}

// MARK: - Supporting Views
private struct MacroMetric: View {
    let title: String
    let value: Int
    let unit: String
    let color: Color
    let icon: String
    @State private var animateIn = false

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(color)
                .scaleEffect(animateIn ? 1 : 0.5)
                .opacity(animateIn ? 1 : 0)

            GradientNumber(value: Double(value))
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text(title)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.secondary)

            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color.secondary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.1)) {
                animateIn = true
            }
        }
    }
}

private struct QuickActionCard: View {
    let title: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.primary)
            }
            .frame(width: 80)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MotionToken.standardSpring) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

private struct MealCard: View {
    let mealType: MealType
    let entries: [FoodEntry]
    let onAdd: () -> Void
    let onTapEntry: (FoodEntry) -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    private var totalCalories: Int {
        entries.flatMap { $0.items }.reduce(0) { $0 + Int($1.calories ?? 0) }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: mealType.icon)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(gradientForMealType(mealType))

                        Text(mealType.displayName)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    if !entries.isEmpty {
                        Text("\(totalCalories) cal")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.secondary)
                    }

                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    }
                }

                if !entries.isEmpty {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        ForEach(entries, id: \.id) { entry in
                            Button(action: { onTapEntry(entry) }) {
                                HStack {
                                    Text(entry.mealDisplayName)
                                        .font(.system(size: 15, weight: .light))
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Text("\(entry.totalCalories) cal")
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundStyle(.secondary)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func gradientForMealType(_ type: MealType) -> LinearGradient {
        switch type {
        case .breakfast:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .lunch:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dinner:
            return LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .snack:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .preWorkout:
            return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .postWorkout:
            return LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

private struct SuggestionCard: View {
    let food: FoodItem
    let action: () -> Void
    @State private var isPressed = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(food.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.xs) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(Int(food.calories ?? 0))")
                    }

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(food.displayQuantity)
                }
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.secondary)
            }
            .frame(width: 140)
            .padding(AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isPressed ? gradientManager.currentGradient(for: colorScheme) : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MotionToken.standardSpring) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Placeholder View
private struct PlaceholderView: View {
    let title: String
    let subtitle: String
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        BaseScreen {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(gradientManager.currentGradient(for: colorScheme))
                        .frame(width: 120, height: 120)
                        .opacity(0.2)
                        .blur(radius: 20)
                        .scaleEffect(animateIn ? 1.2 : 0.8)

                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                        .scaleEffect(animateIn ? 1 : 0.5)
                }

                VStack(spacing: AppSpacing.sm) {
                    if animateIn {
                        CascadeText(title)
                            .font(.system(size: 28, weight: .light, design: .rounded))
                    }

                    Text(subtitle)
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                }
                .padding(.horizontal, AppSpacing.screenPadding)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
        }
    }
}

// MARK: - Helper Extensions
private extension MealType {
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "takeoutbag.and.cup.and.straw.fill"
        case .preWorkout: return "bolt.fill"
        case .postWorkout: return "bolt.circle.fill"
        }
    }
}

private extension FoodItem {
    var displayQuantity: String {
        if let quantity, let unit {
            let qty = quantity.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(quantity)) : String(format: "%.1f", quantity)
            return "\(qty) \(unit)"
        }
        return "1 serving"
    }
}

#if DEBUG && false
#Preview {
    @Previewable @State var vm: FoodTrackingViewModel = {
        let container = ModelContainer.preview
        let context = container.mainContext
        let user = try! context.fetch(FetchDescriptor<User>()).first!
        return FoodTrackingViewModel(
            modelContext: context,
            user: user,
            foodVoiceAdapter: FoodVoiceAdapter(),
            nutritionService: NutritionService(modelContext: context),
            coachEngine: CoachEngine.createDefault(modelContext: context),
            coordinator: FoodTrackingCoordinator()
        )
    }()

    FoodLoggingView(viewModel: vm)
        .modelContainer(ModelContainer.preview)
}
#endif
