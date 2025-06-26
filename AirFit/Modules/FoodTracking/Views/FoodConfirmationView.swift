import SwiftUI
import SwiftData

/// View allowing users to confirm AI-parsed food items, edit their nutrition values,
/// adjust portions and save the results.
struct FoodConfirmationView: View {
    @State private var items: [ParsedFoodItem]
    @State var viewModel: FoodTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var editingItem: ParsedFoodItem?
    @State private var showAddItem = false
    @State private var animateIn = false

    init(items: [ParsedFoodItem], viewModel: FoodTrackingViewModel) {
        _items = State(initialValue: items)
        self.viewModel = viewModel
    }

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Header with meal type
                mealTypeHeader
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : -20)

                // Items list
                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            FoodItemCard(
                                item: item,
                                index: index,
                                onEdit: { editingItem = item },
                                onDelete: { deleteItem(item) }
                            )
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(Double(index) * 0.1), value: animateIn)
                        }

                        // Add item button with gradient accent
                        Button {
                            HapticService.impact(.light)
                            showAddItem = true
                        } label: {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Add Item")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.primary.opacity(0.05),
                                        Color.primary.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient(
                                            colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, AppSpacing.sm)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(Double(items.count) * 0.1 + 0.2), value: animateIn)
                    }
                    .padding(AppSpacing.md)
                }

                // Nutrition summary
                nutritionSummary
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

                // Action buttons
                actionButtons
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticService.impact(.light)
                        dismiss()
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }

                ToolbarItem(placement: .principal) {
                    CascadeText("Confirm Food")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
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
                .environmentObject(gradientManager)
            }
            .onAppear {
                withAnimation(MotionToken.standardSpring.delay(0.1)) {
                    animateIn = true
                }
            }
        }
    }

    // MARK: - Header
    private var mealTypeHeader: some View {
        GlassCard {
            HStack {
                Label {
                    Text(viewModel.selectedMealType.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                } icon: {
                    Image(systemName: viewModel.selectedMealType.icon)
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Spacer()

                Text(viewModel.currentDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
            .padding(AppSpacing.sm)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Nutrition Summary
    private var nutritionSummary: some View {
        GlassCard {
            VStack(spacing: AppSpacing.xs) {
                HStack {
                    CascadeText("Total")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))

                    Spacer()
                }

                HStack(spacing: AppSpacing.lg) {
                    NutrientMetric(
                        value: totalCalories,
                        unit: "cal",
                        icon: "flame.fill",
                        color: Color(hex: "#FF9500")
                    )

                    NutrientMetric(
                        value: totalProtein,
                        unit: "g",
                        label: "P",
                        icon: "p.square.fill",
                        color: Color(hex: "#FF6B6B")
                    )

                    NutrientMetric(
                        value: totalCarbs,
                        unit: "g",
                        label: "C",
                        icon: "c.square.fill",
                        color: Color(hex: "#4ECDC4")
                    )

                    NutrientMetric(
                        value: totalFat,
                        unit: "g",
                        label: "F",
                        icon: "f.square.fill",
                        color: Color(hex: "#FFD93D")
                    )
                }
            }
            .padding(AppSpacing.sm)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: AppSpacing.sm) {
            Button {
                HapticService.impact(.light)
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(0.05),
                                Color.primary.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                HapticService.impact(.medium)
                saveItems()
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Save")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    LinearGradient(
                        colors: items.isEmpty ?
                            [Color.gray.opacity(0.4), Color.gray.opacity(0.3)] :
                            gradientManager.active.colors(for: colorScheme),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(
                    color: items.isEmpty ?
                        Color.clear :
                        gradientManager.active.colors(for: colorScheme)[0].opacity(0.2),
                    radius: 8,
                    y: 2
                )
            }
            .disabled(items.isEmpty)
        }
        .padding(AppSpacing.md)
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    gradientManager.active.colors(for: colorScheme).first?.opacity(0.05) ?? Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Computed Properties
    private var totalCalories: Double {
        Double(items.reduce(0) { $0 + $1.calories })
    }

    private var totalProtein: Double {
        items.reduce(0) { $0 + $1.proteinGrams }
    }

    private var totalCarbs: Double {
        items.reduce(0) { $0 + $1.carbGrams }
    }

    private var totalFat: Double {
        items.reduce(0) { $0 + $1.fatGrams }
    }

    // MARK: - Actions
    private func deleteItem(_ item: ParsedFoodItem) {
        withAnimation(MotionToken.standardSpring) {
            items.removeAll { $0.id == item.id }
        }
        HapticService.impact(.medium)
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
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        HStack(spacing: AppSpacing.xs) {
                            Text("\(item.quantity.formatted()) \(item.unit)")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)

                            if let brand = item.brand {
                                Text("• \(brand)")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary.opacity(0.8))
                            }

                            if item.confidence < 0.8 {
                                HStack(spacing: 2) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                    Text("\(Int(item.confidence * 100))%")
                                        .font(.caption2)
                                }
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            }
                        }
                    }

                    Spacer()

                    Menu {
                        Button(action: {
                            HapticService.impact(.light)
                            onEdit()
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: {
                            HapticService.impact(.rigid)
                            onDelete()
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.body)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.primary.opacity(0.05))
                            )
                    }
                }

                // Gradient divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                gradientManager.active.colors(for: colorScheme).first?.opacity(0.2) ?? Color.clear,
                                gradientManager.active.colors(for: colorScheme).last?.opacity(0.2) ?? Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.vertical, AppSpacing.xs)

                HStack(spacing: AppSpacing.md) {
                    NutrientCompact(
                        value: Double(item.calories),
                        unit: "cal",
                        color: Color(hex: "#FF9500")
                    )

                    NutrientCompact(
                        value: item.proteinGrams,
                        unit: "g",
                        label: "P",
                        color: Color(hex: "#FF6B6B")
                    )

                    NutrientCompact(
                        value: item.carbGrams,
                        unit: "g",
                        label: "C",
                        color: Color(hex: "#4ECDC4")
                    )

                    NutrientCompact(
                        value: item.fatGrams,
                        unit: "g",
                        label: "F",
                        color: Color(hex: "#FFD93D")
                    )
                }
            }
            .padding(AppSpacing.sm)
        }
    }
}

// MARK: - Nutrient Components
private struct NutrientMetric: View {
    let value: Double
    let unit: String
    var label: String?
    let icon: String
    let color: Color

    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color.gradient)

            VStack(spacing: 0) {
                GradientNumber(value: value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

private struct NutrientCompact: View {
    let value: Double
    let unit: String
    var label: String?
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            if let label = label {
                Text(label)
                    .foregroundStyle(color)
                    .font(.system(size: 12, weight: .semibold))
            }

            Text("\(Int(value))")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(color.opacity(0.8))
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

// MARK: - Food Edit View
private struct FoodItemEditView: View {
    @State var item: ParsedFoodItem
    var onSave: (ParsedFoodItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    var body: some View {
        BaseScreen {
            VStack(spacing: AppSpacing.md) {
                CascadeText("Edit Food")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, AppSpacing.lg)

                GlassCard {
                    VStack(spacing: AppSpacing.sm) {
                        Text("Editing functionality")
                        Text("Coming soon")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(AppSpacing.md)
                }
                .padding(.horizontal, AppSpacing.md)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)

                Spacer()

                HStack(spacing: AppSpacing.sm) {
                    Button {
                        HapticService.impact(.light)
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.primary.opacity(0.05),
                                        Color.primary.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient(
                                            colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        HapticService.impact(.medium)
                        onSave(item)
                        dismiss()
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.2), radius: 8, y: 2)
                    }
                }
                .padding(AppSpacing.md)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
            }
            .onAppear {
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
    }
}

private struct ManualFoodEntryView: View {
    @State var viewModel: FoodTrackingViewModel
    var onAdd: (ParsedFoodItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var name = ""
    @State private var calories: Double = 0
    @State private var animateIn = false

    var body: some View {
        BaseScreen {
            VStack(spacing: AppSpacing.md) {
                // Header
                CascadeText("Add Food Item")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, AppSpacing.lg)
                    .opacity(animateIn ? 1 : 0)

                GlassCard {
                    VStack(spacing: AppSpacing.md) {
                        // Food name field
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Food Name")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)

                            TextField("e.g., Apple", text: $name)
                                .textFieldStyle(.plain)
                                .padding(AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.primary.opacity(0.05))
                                )
                        }

                        // Calories field
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Calories")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)

                            TextField("0", value: $calories, formatter: NumberFormatter())
                                .textFieldStyle(.plain)
                                .padding(AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.primary.opacity(0.05))
                                )
                                .keyboardType(.decimalPad)
                        }
                    }
                    .padding(AppSpacing.md)
                }
                .padding(.horizontal, AppSpacing.md)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                Spacer()

                // Action buttons
                HStack(spacing: AppSpacing.sm) {
                    Button {
                        HapticService.impact(.light)
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.primary.opacity(0.05),
                                        Color.primary.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient(
                                            colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        HapticService.impact(.medium)
                        let item = ParsedFoodItem(
                            name: name,
                            brand: nil,
                            quantity: 1.0,
                            unit: "serving",
                            calories: Int(calories),
                            proteinGrams: 0,
                            carbGrams: 0,
                            fatGrams: 0,
                            fiberGrams: nil,
                            sugarGrams: nil,
                            sodiumMilligrams: nil,
                            databaseId: nil,
                            confidence: 1.0
                        )
                        onAdd(item)
                        dismiss()
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            LinearGradient(
                                colors: (name.isEmpty || calories <= 0) ?
                                    [Color.gray.opacity(0.4), Color.gray.opacity(0.3)] :
                                    gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(
                            color: (name.isEmpty || calories <= 0) ?
                                Color.clear :
                                gradientManager.active.colors(for: colorScheme)[0].opacity(0.2),
                            radius: 8,
                            y: 2
                        )
                    }
                    .disabled(name.isEmpty || calories <= 0)
                }
                .padding(AppSpacing.md)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
            }
            .onAppear {
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
    }
}

#if DEBUG
/*
 #Preview {
 let container = ModelContainer.preview
 let context = container.mainContext
 let user = try! context.fetch(FetchDescriptor<User>()).first!
 let parsed = ParsedFoodItem(
 name: "Apple",
 brand: nil,
 quantity: 1,
 unit: "item",
 calories: 95,
 proteinGrams: 0.5,
 carbGrams: 25,
 fatGrams: 0.3,
 fiberGrams: nil,
 sugarGrams: nil,
 sodiumMilligrams: nil,
 databaseId: nil,
 confidence: 1.0
 )
 let vm = FoodTrackingViewModel(
 modelContext: context,
 user: user,
 foodVoiceAdapter: FoodVoiceAdapter(),
 nutritionService: MockNutritionService(),
 coachEngine: MockCoachEngine(),
 coordinator: FoodTrackingCoordinator()
 )
 FoodConfirmationView(items: [parsed], viewModel: vm)
 .modelContainer(container)
 }
 */

@MainActor
final class MockNutritionService: NutritionServiceProtocol {
    func saveFoodEntry(_ entry: FoodEntry) async throws {}
    func getFoodEntries(for date: Date) async throws -> [FoodEntry] { [] }
    func deleteFoodEntry(_ entry: FoodEntry) async throws {}
    func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] { [] }
    nonisolated func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary { FoodNutritionSummary() }
    func getWaterIntake(for user: User, date: Date) async throws -> Double { 0 }
    func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] { [] }
    func logWaterIntake(for user: User, amountML: Double, date: Date) async throws {}
    func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] { [] }
    nonisolated func getTargets(from profile: OnboardingProfile?) -> NutritionTargets { .default }
    func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary { FoodNutritionSummary() }
}

@MainActor
final class MockCoachEngine: FoodCoachEngineProtocol {
    func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
        ["response": .string("Mock response")]
    }

    func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
        FunctionExecutionResult(success: true, message: "Mock execution", executionTimeMs: 1, functionName: functionCall.name)
    }

    func analyzeMealPhoto(image: UIImage, context: NutritionContext?, for user: User) async throws -> MealPhotoAnalysisResult {
        MealPhotoAnalysisResult(items: [], confidence: 0.9, processingTime: 0.1)
    }

    func searchFoods(query: String, limit: Int, for user: User) async throws -> [ParsedFoodItem] {
        []
    }

    func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
        [ParsedFoodItem(
            name: text.components(separatedBy: .whitespacesAndNewlines).first ?? "Mock Food",
            brand: nil,
            quantity: 1.0,
            unit: "serving",
            calories: 150,
            proteinGrams: 10.0,
            carbGrams: 20.0,
            fatGrams: 5.0,
            fiberGrams: 3.0,
            sugarGrams: 8.0,
            sodiumMilligrams: 200.0,
            databaseId: nil,
            confidence: 0.8
        )]
    }
}
#endif
