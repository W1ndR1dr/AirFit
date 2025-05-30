import SwiftUI
import Charts
import SwiftData

/// AI-parsed food confirmation interface with editable nutrition data and portion adjustments.
struct FoodConfirmationView: View {
    @State private var items: [ParsedFoodItem]
    @State private var viewModel: FoodTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editingItem: ParsedFoodItem?
    @State private var showAddItem = false
    @State private var isLoading = false
    
    init(items: [ParsedFoodItem], viewModel: FoodTrackingViewModel) {
        _items = State(initialValue: items)
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mealTypeHeader
                
                ScrollView {
                    VStack(spacing: AppSpacing.medium) {
                        ForEach($items) { $item in
                            FoodItemCard(
                                item: item,
                                onEdit: { editingItem = item },
                                onDelete: { deleteItem(item) }
                            )
                        }
                        
                        Button(action: { showAddItem = true }) {
                            Label("Add Item", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top)
                    }
                    .padding()
                }
                
                nutritionSummary
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
            .disabled(isLoading)
        }
    }
    
    private var mealTypeHeader: some View {
        HStack {
            Label(viewModel.selectedMealType.displayName, systemImage: mealTypeIcon)
                .font(.headline)
            
            Spacer()
            
            Text(viewModel.currentDate.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(AppColors.cardBackground)
    }
    
    private var mealTypeIcon: String {
        switch viewModel.selectedMealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "takeoutbag.and.cup.and.straw.fill"
        case .preWorkout: return "bolt.fill"
        case .postWorkout: return "bolt.circle.fill"
        }
    }
    
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
            
            if !items.isEmpty {
                nutritionChart
                    .frame(height: 120)
                    .padding(.horizontal)
            }
        }
        .background(AppColors.cardBackground)
    }
    
    private var nutritionChart: some View {
        Chart {
            SectorMark(
                angle: .value("Protein", totalProtein * 4),
                innerRadius: .ratio(0.6),
                angularInset: 1
            )
            .foregroundStyle(AppColors.proteinColor)
            .opacity(0.8)
            
            SectorMark(
                angle: .value("Carbs", totalCarbs * 4),
                innerRadius: .ratio(0.6),
                angularInset: 1
            )
            .foregroundStyle(AppColors.carbsColor)
            .opacity(0.8)
            
            SectorMark(
                angle: .value("Fat", totalFat * 9),
                innerRadius: .ratio(0.6),
                angularInset: 1
            )
            .foregroundStyle(AppColors.fatColor)
            .opacity(0.8)
        }
        .chartLegend(.hidden)
        .chartBackground { _ in
            VStack {
                Text("\(Int(totalCalories))")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("calories")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: AppSpacing.medium) {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: saveItems) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Label("Save", systemImage: "checkmark.circle.fill")
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            .disabled(items.isEmpty || isLoading)
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
        withAnimation(.easeInOut(duration: 0.3)) {
            items.removeAll { $0.id == item.id }
        }
        HapticManager.impact(.light)
    }
    
    private func saveItems() {
        isLoading = true
        
        Task {
            await viewModel.confirmAndSaveFoodItems(items)
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views
struct FoodItemCard: View {
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
                            .lineLimit(2)
                        
                        HStack {
                            Text(quantityText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if let brand = item.brand {
                                Text("• \(brand)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if item.confidence < 0.8 {
                                HStack(spacing: 2) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                    Text("Low confidence")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
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
                    Spacer()
                }
                .font(.caption)
            }
        }
    }
    
    private var quantityText: String {
        let qty = item.quantity.truncatingRemainder(dividingBy: 1) == 0 
            ? String(Int(item.quantity)) 
            : String(format: "%.1f", item.quantity)
        return "\(qty) \(item.unit)"
    }
}

struct NutrientLabel: View {
    let value: Double
    let unit: String
    var label: String? = nil
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            if let label = label {
                Text(label)
                    .foregroundStyle(color)
                    .fontWeight(.medium)
            }
            Text(formattedValue)
                .fontWeight(.medium)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
    
    private var formattedValue: String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Placeholder Views for Future Implementation
struct FoodItemEditView: View {
    let item: ParsedFoodItem
    let onSave: (ParsedFoodItem) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                
                Text("Food Item Editor")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Coming in Phase 3")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Edit \(item.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(item)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ManualFoodEntryView: View {
    @State private var viewModel: FoodTrackingViewModel
    let onAdd: (ParsedFoodItem) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: FoodTrackingViewModel, onAdd: @escaping (ParsedFoodItem) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onAdd = onAdd
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                
                Text("Manual Food Entry")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Coming in Phase 3")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    let mockItems = [
        ParsedFoodItem(
            name: "Grilled Chicken Breast",
            brand: "Organic Valley",
            quantity: 1,
            unit: "serving",
            calories: 165,
            proteinGrams: 31,
            carbGrams: 0,
            fatGrams: 3.6,
            confidence: 0.95
        ),
        ParsedFoodItem(
            name: "Brown Rice",
            brand: nil,
            quantity: 0.5,
            unit: "cup",
            calories: 112,
            proteinGrams: 2.6,
            carbGrams: 23,
            fatGrams: 0.9,
            confidence: 0.75
        )
    ]
    
    // Simplified preview without complex dependencies
    VStack {
        Text("FoodConfirmationView Preview")
            .font(.title)
        Text("Items: \(mockItems.count)")
        Text("Total Calories: \(Int(mockItems.reduce(0) { $0 + $1.calories }))")
    }
    .padding()
}
#endif 