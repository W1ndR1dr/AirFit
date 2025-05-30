import SwiftUI

/// View allowing users to confirm AI-parsed food items, edit their nutrition values,
/// adjust portions and save the results.
struct FoodConfirmationView: View {
    @State private var items: [ParsedFoodItem]
    @ObservedObject var viewModel: FoodTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editingItem: ParsedFoodItem?
    @State private var showAddItem = false

    init(items: [ParsedFoodItem], viewModel: FoodTrackingViewModel) {
        _items = State(initialValue: items)
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with meal type
                mealTypeHeader

                // Items list
                ScrollView {
                    VStack(spacing: AppSpacing.medium) {
                        ForEach($items) { $item in
                            FoodItemCard(
                                item: item,
                                onEdit: { editingItem = item },
                                onDelete: { deleteItem(item) }
                            )
                        }

                        // Add item button
                        Button(action: { showAddItem = true }) {
                            Label("Add Item", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .padding(.top)
                    }
                    .padding()
                }

                // Nutrition summary
                nutritionSummary

                // Action buttons
                actionButtons
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle("Confirm Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $editingItem) { item in
                FoodItemEditView(item: item) { updatedItem in
                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                        items[index] = updatedItem
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                ManualFoodEntryView(viewModel: viewModel) { newItem in
                    items.append(newItem)
                }
            }
        }
    }

    // MARK: - Header
    private var mealTypeHeader: some View {
        HStack {
            Label(viewModel.selectedMealType.displayName, systemImage: viewModel.selectedMealType.icon)
                .font(.headline)

            Spacer()

            Text(viewModel.currentDate.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(AppColors.cardBackground)
    }

    // MARK: - Nutrition Summary
    private var nutritionSummary: some View {
        VStack(spacing: AppSpacing.small) {
            Divider()

            HStack {
                Text("Total")
                    .font(.headline)

                Spacer()

                HStack(spacing: AppSpacing.large) {
                    NutrientLabel(value: totalCalories, unit: "cal", color: .orange)
                    NutrientLabel(value: totalProtein, unit: "g", label: "P", color: AppColors.proteinColor)
                    NutrientLabel(value: totalCarbs, unit: "g", label: "C", color: AppColors.carbsColor)
                    NutrientLabel(value: totalFat, unit: "g", label: "F", color: AppColors.fatColor)
                }
                .font(.callout)
            }
            .padding()
        }
        .background(AppColors.cardBackground)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: AppSpacing.medium) {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(action: saveItems) {
                Label("Save", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(items.isEmpty)
        }
        .padding()
        .background(AppColors.cardBackground)
    }

    // MARK: - Computed Properties
    private var totalCalories: Double {
        items.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        items.reduce(0) { $0 + ($1.proteinGrams ?? 0) }
    }

    private var totalCarbs: Double {
        items.reduce(0) { $0 + ($1.carbGrams ?? 0) }
    }

    private var totalFat: Double {
        items.reduce(0) { $0 + ($1.fatGrams ?? 0) }
    }

    // MARK: - Actions
    private func deleteItem(_ item: ParsedFoodItem) {
        withAnimation {
            items.removeAll { $0.id == item.id }
        }
        HapticManager.impact(.light)
    }

    private func saveItems() {
        Task {
            await viewModel.confirmAndSaveFoodItems(items)
            dismiss()
        }
    }
}

// MARK: - Supporting Views
private struct FoodItemCard: View {
    let item: ParsedFoodItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text(item.name)
                            .font(.headline)

                        HStack {
                            Text("\(item.quantity.formatted()) \(item.unit)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let brand = item.brand {
                                Text("• \(brand)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if item.confidence < 0.8 {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }

                    Spacer()

                    Menu {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                    }
                }

                Divider()

                HStack(spacing: AppSpacing.large) {
                    NutrientLabel(value: item.calories, unit: "cal", color: .orange)
                    if let protein = item.proteinGrams {
                        NutrientLabel(value: protein, unit: "g", label: "Protein", color: AppColors.proteinColor)
                    }
                    if let carbs = item.carbGrams {
                        NutrientLabel(value: carbs, unit: "g", label: "Carbs", color: AppColors.carbsColor)
                    }
                    if let fat = item.fatGrams {
                        NutrientLabel(value: fat, unit: "g", label: "Fat", color: AppColors.fatColor)
                    }
                }
                .font(.caption)
            }
        }
    }
}

private struct NutrientLabel: View {
    let value: Double
    let unit: String
    var label: String? = nil
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            if let label = label {
                Text(label)
                    .foregroundStyle(color)
            }
            Text("\(value.formatted()) \(unit)")
                .fontWeight(.medium)
        }
    }
}

// MARK: - MealType Icon
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

// MARK: - Placeholder Views for Future Tasks
private struct FoodItemEditView: View {
    @State var item: ParsedFoodItem
    var onSave: (ParsedFoodItem) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Text("Food item editing not implemented")
            Button("Save") {
                onSave(item)
                dismiss()
            }
        }
        .padding()
    }
}

private struct ManualFoodEntryView: View {
    @ObservedObject var viewModel: FoodTrackingViewModel
    var onAdd: (ParsedFoodItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var calories: Double = 0

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            TextField("Food name", text: $name)
                .textFieldStyle(.roundedBorder)
            TextField("Calories", value: $calories, formatter: NumberFormatter())
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
            Button("Add") {
                let item = ParsedFoodItem(
                    name: name,
                    brand: nil,
                    quantity: 1,
                    unit: "serving",
                    calories: calories,
                    proteinGrams: nil,
                    carbGrams: nil,
                    fatGrams: nil,
                    confidence: 1.0
                )
                onAdd(item)
                dismiss()
            }
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    // Simple preview with placeholder data
    let container = try! ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    let user = User.example
    context.insert(user)
    let parsed = ParsedFoodItem(name: "Apple", brand: nil, quantity: 1, unit: "item", calories: 95, proteinGrams: 0.5, carbGrams: 25, fatGrams: 0.3, confidence: 1.0)
    let vm = FoodTrackingViewModel(
        modelContext: context,
        user: user,
        foodVoiceAdapter: FoodVoiceAdapter(),
        nutritionService: NutritionService(modelContext: context),
        foodDatabaseService: FoodDatabaseService(),
        coachEngine: CoachEngine.createDefault(modelContext: context),
        coordinator: FoodTrackingCoordinator()
    )
    return FoodConfirmationView(items: [parsed], viewModel: vm)
        .modelContainer(container)
}
#endif
