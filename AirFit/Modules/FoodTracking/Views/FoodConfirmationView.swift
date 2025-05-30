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
    @State private var showAlternatives = false
    @State private var selectedAlternatives: Set<UUID> = []
    
    init(items: [ParsedFoodItem], viewModel: FoodTrackingViewModel) {
        _items = State(initialValue: items)
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with confidence summary
                confidenceSummaryHeader
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Confidence-based grouping
                        if hasHighConfidenceItems {
                            confidenceSection(
                                title: "High Confidence",
                                items: highConfidenceItems,
                                color: .green,
                                icon: "checkmark.circle.fill"
                            )
                        }
                        
                        if hasLowConfidenceItems {
                            confidenceSection(
                                title: "Please Review",
                                items: lowConfidenceItems,
                                color: .orange,
                                icon: "exclamationmark.triangle.fill"
                            )
                        }
                        
                        // Alternative suggestions
                        if hasAlternativeSuggestions {
                            alternativesSection
                        }
                        
                        // Nutrition summary with confidence weighting
                        nutritionSummaryCard
                        
                        // Add more items button
                        addItemButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Confirm Food Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel food entry")
                    .accessibilityHint("Tap to discard this food entry")
                    .accessibilityIdentifier("cancel_button")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await confirmAndSave()
                        }
                    }
                    .disabled(isLoading || confirmedItems.isEmpty)
                    .accessibilityLabel("Confirm food entry")
                    .accessibilityHint("Tap to save this food to your log")
                    .accessibilityIdentifier("confirm_button")
                }
            }
            .sheet(isPresented: $showAddItem) {
                ManualFoodEntryView(viewModel: viewModel) { newItem in
                    items.append(newItem)
                    showAddItem = false
                }
            }
            .sheet(item: $editingItem) { item in
                FoodItemEditView(item: item) { updatedItem in
                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                        items[index] = updatedItem
                    }
                    editingItem = nil
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var highConfidenceItems: [ParsedFoodItem] {
        items.filter { $0.confidence >= 0.7 }
    }
    
    private var lowConfidenceItems: [ParsedFoodItem] {
        items.filter { $0.confidence < 0.7 && $0.confidence >= 0.5 }
    }
    
    private var alternativeSuggestions: [ParsedFoodItem] {
        items.filter { $0.confidence < 0.5 }
    }
    
    private var hasHighConfidenceItems: Bool {
        !highConfidenceItems.isEmpty
    }
    
    private var hasLowConfidenceItems: Bool {
        !lowConfidenceItems.isEmpty
    }
    
    private var hasAlternativeSuggestions: Bool {
        !alternativeSuggestions.isEmpty
    }
    
    private var confirmedItems: [ParsedFoodItem] {
        highConfidenceItems + lowConfidenceItems + alternativeSuggestions.filter { selectedAlternatives.contains($0.id) }
    }
    
    private var totalNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let confirmed = confirmedItems
        return (
            calories: confirmed.reduce(0) { $0 + $1.calories },
            protein: confirmed.reduce(0) { $0 + ($1.proteinGrams ?? 0) },
            carbs: confirmed.reduce(0) { $0 + ($1.carbGrams ?? 0) },
            fat: confirmed.reduce(0) { $0 + ($1.fatGrams ?? 0) }
        )
    }
    
    // MARK: - View Components
    
    private var confidenceSummaryHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.blue)
                Text("AI Analysis Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                // Overall confidence indicator
                confidenceBadge(for: overallConfidence)
            }
            
            if hasLowConfidenceItems || hasAlternativeSuggestions {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text("Some items need your review. Tap to edit or confirm.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .accessibilityLabel("Food confirmation")
        .accessibilityValue("Confirm food items with confidence indicators")
    }
    
    private var overallConfidence: Float {
        guard !items.isEmpty else { return 0 }
        return items.reduce(0) { $0 + $1.confidence } / Float(items.count)
    }
    
    private func confidenceSection(
        title: String,
        items: [ParsedFoodItem],
        color: Color,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(items) { item in
                foodItemCard(item, sectionColor: color)
            }
        }
        .padding()
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("\(title) section")
        .accessibilityValue("\(items.count) food items")
    }
    
    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.purple)
                Text("Alternative Suggestions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(showAlternatives ? "Hide" : "Show") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAlternatives.toggle()
                    }
                }
                .font(.caption)
            }
            
            if showAlternatives {
                Text("These are alternative interpretations. Select any that match what you actually ate.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ForEach(alternativeSuggestions) { item in
                    alternativeItemCard(item)
                }
            }
        }
        .padding()
        .background(.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("Alternative suggestions section")
        .accessibilityHint("Tap to view other possible food matches")
    }
    
    private func foodItemCard(_ item: ParsedFoodItem, sectionColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let brand = item.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Text("\(item.quantity.formatted(.number.precision(.fractionLength(0...1)))) \(item.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    confidenceBadge(for: item.confidence)
                    
                    Text("\(Int(item.calories)) cal")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            // Nutrition breakdown
            if let protein = item.proteinGrams,
               let carbs = item.carbGrams,
               let fat = item.fatGrams {
                HStack(spacing: 16) {
                    macroIndicator("P", value: protein, color: .blue)
                    macroIndicator("C", value: carbs, color: .green)
                    macroIndicator("F", value: fat, color: .orange)
                    Spacer()
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button("Edit Details") {
                editingItem = item
            }
            
            Button("Remove", role: .destructive) {
                withAnimation {
                    items.removeAll { $0.id == item.id }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name) food item")
    }
    
    private func alternativeItemCard(_ item: ParsedFoodItem) -> some View {
        HStack {
            Button {
                withAnimation {
                    if selectedAlternatives.contains(item.id) {
                        selectedAlternatives.remove(item.id)
                    } else {
                        selectedAlternatives.insert(item.id)
                    }
                }
            } label: {
                Image(systemName: selectedAlternatives.contains(item.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedAlternatives.contains(item.id) ? .blue : .secondary)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Alternative suggestion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if selectedAlternatives.contains(item.id) {
                Text("Selected")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func confidenceBadge(for confidence: Float) -> some View {
        let (color, text) = confidenceInfo(for: confidence)
        
        return Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
    }
    
    private func confidenceInfo(for confidence: Float) -> (Color, String) {
        switch confidence {
        case 0.8...:
            return (.green, "HIGH")
        case 0.6..<0.8:
            return (.orange, "MED")
        default:
            return (.red, "LOW")
        }
    }
    
    private func macroIndicator(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text("\(Int(value))g")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Actions
    private func confirmAndSave() {
        isLoading = true
        
        Task {
            await viewModel.confirmAndSaveFoodItems(confirmedItems)
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
    
    private var nutritionSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(.blue)
                Text("Nutrition Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(confirmedItems.count) item\(confirmedItems.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            let nutrition = totalNutrition
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(Int(nutrition.calories))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Calories")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                HStack(spacing: 16) {
                    macroIndicator("P", value: nutrition.protein, color: .blue)
                    macroIndicator("C", value: nutrition.carbs, color: .green)
                    macroIndicator("F", value: nutrition.fat, color: .orange)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var addItemButton: some View {
        Button {
            showAddItem = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Another Item")
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.bordered)
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
    @State private var item: ParsedFoodItem
    let onSave: (ParsedFoodItem) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(item: ParsedFoodItem, onSave: @escaping (ParsedFoodItem) -> Void) {
        _item = State(initialValue: item)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    TextField("Name", text: $item.name)
                    TextField("Brand", text: Binding(
                        get: { item.brand ?? "" },
                        set: { item.brand = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section("Portion") {
                    HStack {
                        TextField("Quantity", value: $item.quantity, format: .number)
                            .keyboardType(.decimalPad)
                        TextField("Unit", text: $item.unit)
                    }
                }
                
                Section("Nutrition") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", value: $item.calories, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("0", value: Binding(
                            get: { item.proteinGrams ?? 0 },
                            set: { item.proteinGrams = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("0", value: Binding(
                            get: { item.carbGrams ?? 0 },
                            set: { item.carbGrams = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("0", value: Binding(
                            get: { item.fatGrams ?? 0 },
                            set: { item.fatGrams = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Edit Food Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(item)
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
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Food Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
        Text("Advanced AI features with confidence indicators")
            .font(.caption)
            .foregroundStyle(.secondary)
        Spacer()
    }
    .padding()
}
#endif 