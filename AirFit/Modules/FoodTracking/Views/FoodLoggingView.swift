import SwiftUI
import Charts
import SwiftData

/// Main food logging interface with voice-first workflow and macro visualization.
struct FoodLoggingView: View {
    @StateObject private var viewModel: FoodTrackingViewModel
    @StateObject private var coordinator: FoodTrackingCoordinator
    @Environment(\.dismiss) private var dismiss

    init(user: User, modelContext: ModelContext) {
        let coordinator = FoodTrackingCoordinator()
        let adapter = FoodVoiceAdapter()
        let vm = FoodTrackingViewModel(
            modelContext: modelContext,
            user: user,
            foodVoiceAdapter: adapter,
            nutritionService: NutritionService(modelContext: modelContext),
            foodDatabaseService: FoodDatabaseService(),
            coachEngine: CoachEngine.shared,
            coordinator: coordinator
        )
        _viewModel = StateObject(wrappedValue: vm)
        _coordinator = StateObject(wrappedValue: coordinator)
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    datePicker
                    macroSummaryCard
                        .padding(.horizontal)
                        .padding(.top, AppSpacing.medium)
                    quickActionsSection
                        .padding(.horizontal)
                        .padding(.top, AppSpacing.large)
                    mealsSection
                        .padding(.horizontal)
                        .padding(.top, AppSpacing.large)
                    if !viewModel.suggestedFoods.isEmpty {
                        suggestionsSection
                            .padding(.top, AppSpacing.large)
                    }
                }
                .padding(.bottom, AppSpacing.xLarge)
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle("Food Tracking")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
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
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Date Picker
    private var datePicker: some View {
        HStack {
            Button(action: previousDay) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(viewModel.currentDate.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
            Spacer()
            Button(action: nextDay) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .disabled(Calendar.current.isDateInToday(viewModel.currentDate))
        }
        .padding(.horizontal)
        .padding(.vertical, AppSpacing.small)
        .background(AppColors.cardBackground)
    }

    // MARK: - Macro Summary
    private var macroSummaryCard: some View {
        Card {
            VStack(spacing: AppSpacing.medium) {
                HStack {
                    Text("Today's Nutrition")
                        .font(.headline)
                    Spacer()
                    NavigationLink(value: FoodTrackingDestination.insights) {
                        Text("Details")
                            .font(.subheadline)
                            .foregroundStyle(.accent)
                    }
                }
                MacroRingsView(
                    nutrition: viewModel.todaysNutrition,
                    style: .compact
                )
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(Int(viewModel.todaysNutrition.calories)) / \(Int(viewModel.todaysNutrition.calorieGoal)) cal")
                        .font(.callout)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.blue)
                    Text("\(Int(viewModel.waterIntakeML)) ml")
                        .font(.callout)
                        .fontWeight(.medium)
                }
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Quick Add", icon: "plus.circle.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.medium) {
                    QuickActionButton(title: "Voice", icon: "mic.fill", color: .accent) {
                        Task { await viewModel.startVoiceInput() }
                    }
                    QuickActionButton(title: "Barcode", icon: "barcode.viewfinder", color: .orange) {
                        viewModel.startBarcodeScanning()
                    }
                    QuickActionButton(title: "Search", icon: "magnifyingglass", color: .green) {
                        coordinator.showSheet(.foodSearch)
                    }
                    QuickActionButton(title: "Water", icon: "drop.fill", color: .blue) {
                        coordinator.showSheet(.waterTracking)
                    }
                    QuickActionButton(title: "Manual", icon: "square.and.pencil", color: .purple) {
                        coordinator.showSheet(.manualEntry)
                    }
                }
            }
        }
    }

    // MARK: - Meals
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Today's Meals", icon: "fork.knife")
            VStack(spacing: AppSpacing.medium) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    MealCard(
                        mealType: mealType,
                        entries: viewModel.todaysFoodEntries.filter { $0.mealType == mealType.rawValue },
                        onAdd: {
                            viewModel.selectedMealType = mealType
                            Task { await viewModel.startVoiceInput() }
                        },
                        onTapEntry: { entry in
                            coordinator.showSheet(.mealDetails(entry))
                        }
                    )
                }
            }
        }
    }

    // MARK: - Suggestions
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Quick Add Favorites", icon: "star.fill")
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.medium) {
                    ForEach(viewModel.suggestedFoods) { food in
                        SuggestionCard(food: food) {
                            selectSuggestedFood(food)
                        }
                    }
                }
                .padding(.horizontal)
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
        let parsed = ParsedFoodItem(
            name: food.name,
            brand: food.brand,
            quantity: food.quantity ?? 1,
            unit: food.unit ?? "serving",
            calories: food.calories ?? 0,
            proteinGrams: food.proteinGrams,
            carbGrams: food.carbGrams,
            fatGrams: food.fatGrams,
            confidence: 1.0
        )
        viewModel.parsedItems = [parsed]
        coordinator.showFullScreenCover(.confirmation([parsed]))
    }

    // MARK: - Navigation Helpers
    @ViewBuilder
    private func destinationView(for destination: FoodTrackingDestination) -> some View {
        switch destination {
        case .history:
            FoodHistoryView(viewModel: viewModel)
        case .insights:
            NutritionInsightsView(viewModel: viewModel)
        case .favorites:
            FavoriteFoodsView(viewModel: viewModel)
        case .recipes:
            RecipesView(viewModel: viewModel)
        case .mealPlan:
            MealPlanView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: FoodTrackingCoordinator.FoodTrackingSheet) -> some View {
        switch sheet {
        case .voiceInput:
            VoiceInputView(viewModel: viewModel)
        case .barcodeScanner:
            BarcodeScannerView(viewModel: viewModel)
        case .foodSearch:
            NutritionSearchView(viewModel: viewModel)
        case .manualEntry:
            ManualFoodEntryView(viewModel: viewModel)
        case .waterTracking:
            WaterTrackingView(viewModel: viewModel)
        case .mealDetails(let entry):
            MealDetailsView(entry: entry, viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func fullScreenView(for cover: FoodTrackingCoordinator.FoodTrackingFullScreenCover) -> some View {
        switch cover {
        case .camera:
            CameraFoodScanView(viewModel: viewModel)
        case .confirmation(let items):
            FoodConfirmationView(items: items, viewModel: viewModel)
        }
    }
}

// MARK: - Supporting Views
private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xSmall) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(AppSpacing.xSmall)
                    .background(color)
                    .clipShape(Circle())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
    }
}

private struct MealCard: View {
    let mealType: MealType
    let entries: [FoodEntry]
    let onAdd: () -> Void
    let onTapEntry: (FoodEntry) -> Void

    private var totalCalories: Int {
        entries.flatMap { $0.items }.reduce(0) { $0 + Int($1.calories ?? 0) }
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Label(mealType.displayName, systemImage: mealType.icon)
                        .font(.headline)
                    Spacer()
                    if !entries.isEmpty {
                        Text("\(totalCalories) cal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.accent)
                    }
                }
                if !entries.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        ForEach(entries) { entry in
                            Button(action: { onTapEntry(entry) }) {
                                HStack {
                                    Text(entry.displayName)
                                        .font(.callout)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text("\(entry.totalCalories) cal")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct SuggestionCard: View {
    let food: FoodItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(food.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: AppSpacing.xSmall) {
                    Text("\(Int(food.calories ?? 0)) cal")
                    Text("•")
                    Text(food.displayQuantity)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 140)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.medium))
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

#if DEBUG
#Preview {
    let container = try! ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    let user = User(name: "Preview")
    context.insert(user)
    return FoodLoggingView(user: user, modelContext: context)
        .modelContainer(container)
}
#endif
