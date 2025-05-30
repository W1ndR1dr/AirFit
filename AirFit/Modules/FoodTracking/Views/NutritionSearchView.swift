import SwiftUI
import SwiftData

/// Search interface for finding and selecting foods to log
struct NutritionSearchView: View {
    @State var viewModel: FoodTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory?
    @State private var debounceTimer: Timer?
    
    private let foodCategories: [FoodCategory] = [
        FoodCategory(name: "Fruits", icon: "apple"),
        FoodCategory(name: "Vegetables", icon: "carrot"),
        FoodCategory(name: "Proteins", icon: "fish"),
        FoodCategory(name: "Grains", icon: "leaf"),
        FoodCategory(name: "Dairy", icon: "drop"),
        FoodCategory(name: "Snacks", icon: "takeoutbag.and.cup.and.straw")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                
                ScrollView {
                    LazyVStack(spacing: AppSpacing.medium) {
                        if searchText.isEmpty && selectedCategory == nil {
                            initialContent
                        } else if selectedCategory != nil {
                            categoryResultsContent
                        } else {
                            searchResultsContent
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField("Search foods...", text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task { await performSearch() }
                }
                .onChange(of: searchText) { _, newValue in
                    triggerSearch()
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    selectedCategory = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.medium))
        .padding(.horizontal)
    }

    // MARK: - Initial Content
    @ViewBuilder
    private var initialContent: some View {
        CategoriesSection(categories: foodCategories, selectedCategory: $selectedCategory)
            .padding(.horizontal)
        
        Text("Recent Foods")
            .font(.headline)
            .padding(.horizontal)
        
        if viewModel.recentFoods.isEmpty {
            EmptyStateView(
                icon: "clock.arrow.circlepath",
                title: "No Recent Foods",
                message: "Foods you log will appear here for quick re-adding."
            )
        } else {
            ForEach(viewModel.recentFoods.prefix(5), id: \.id) { food in
                FoodItemRow(food: food) {
                    selectRecentFood(food)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Category Results Content
    @ViewBuilder
    private var categoryResultsContent: some View {
        if let category = selectedCategory {
            HStack {
                Text("Showing results for ") + Text(category.name).bold()
                Spacer()
                Button {
                    selectedCategory = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
            .padding(.horizontal)
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, AppSpacing.xLarge)
        } else {
            EmptyStateView(
                icon: "tray.fill",
                title: "No Items in Category",
                message: "Try a different category or use the search bar."
            )
            .padding()
        }
    }

    // MARK: - Search Results Content
    @ViewBuilder
    private var searchResultsContent: some View {
        if viewModel.isLoading && !searchText.isEmpty {
            ProgressView("Searching...")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, AppSpacing.xLarge)
        } else if !searchText.isEmpty {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No Results Found",
                message: "Try a different search term or check for typos."
            )
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    private func triggerSearch() {
        debounceTimer?.invalidate()
        
        guard !searchText.isEmpty || selectedCategory != nil else {
            return
        }
        
        if searchText.count > 2 || selectedCategory != nil {
            Task { await performSearch() }
        } else {
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                Task { await performSearch() }
            }
        }
    }

    private func performSearch() async {
        if let category = selectedCategory, searchText.isEmpty {
            await viewModel.searchFoods(category.name)
        } else if !searchText.isEmpty {
            await viewModel.searchFoods(searchText)
        }
    }

    private func selectRecentFood(_ food: FoodItem) {
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
        dismiss()
    }
}

// MARK: - Sections
private struct CategoriesSection: View {
    let categories: [FoodCategory]
    @Binding var selectedCategory: FoodCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Categories")
                .font(AppFonts.title3)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.small) {
                    ForEach(categories) { category in
                        CategoryChip(category: category, isSelected: selectedCategory == category) {
                            if selectedCategory == category {
                                selectedCategory = nil // Deselect
                            } else {
                                selectedCategory = category
                            }
                            // Trigger search for this category in parent view
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Reusable Components
/// Represents an item in the food list, can be either a recent log or a database search result.
enum FoodListItem: Identifiable {
    case recentItem(FoodItem)
    case databaseItem(FoodDatabaseItem)

    var id: String {
        switch self {
        case .recentItem(let item): return item.id.uuidString // FoodItem is Identifiable via its SwiftData nature
        case .databaseItem(let item): return item.id // FoodDatabaseItem has String ID
        }
    }

    var name: String {
        switch self {
        case .recentItem(let item): return item.name
        case .databaseItem(let item): return item.name
        }
    }
    
    var brand: String? {
        switch self {
        case .recentItem(let item): return item.brand
        case .databaseItem(let item): return item.brand
        }
    }

    var calories: Double {
        switch self {
        case .recentItem(let item): return item.calories ?? 0
        case .databaseItem(let item): return item.caloriesPerServing
        }
    }
    
    var protein: Double? {
        switch self {
        case .recentItem(let item): return item.proteinGrams
        case .databaseItem(let item): return item.proteinPerServing
        }
    }
    
    var carbs: Double? {
        switch self {
        case .recentItem(let item): return item.carbGrams
        case .databaseItem(let item): return item.carbsPerServing
        }
    }
    
    var fat: Double? {
        switch self {
        case .recentItem(let item): return item.fatGrams
        case .databaseItem(let item): return item.fatPerServing
        }
    }

    var servingDescription: String {
        switch self {
        case .recentItem(let item):
            let qty = item.quantity?.formatted(.number.precision(.fractionLength(0...1))) ?? "1"
            let unit = item.unit ?? "serving"
            return "\(qty) \(unit)"
        case .databaseItem(let item):
            return "\(item.defaultQuantity.formatted(.number.precision(.fractionLength(0...1)))) \(item.defaultUnit)"
        }
    }
}

private struct FoodItemRow: View {
    let food: FoodItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.accent)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(food.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)

                    if let brand = food.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Text("\(food.quantity?.formatted() ?? "1") \(food.unit ?? "serving")")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppSpacing.xSmall) {
                    Text("\(Int(food.calories ?? 0)) cal")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.caloriesColor)
                }
            }
            .padding(.vertical, AppSpacing.small)
        }
        .buttonStyle(.plain)
    }
}

struct FoodCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
}

private struct CategoryChip: View {
    let category: FoodCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xSmall) {
                Image(systemName: category.icon)
                Text(category.name)
            }
            .font(.footnote)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.xSmall)
            .foregroundColor(isSelected ? AppColors.textOnAccent : AppColors.accent)
            .background(isSelected ? AppColors.accent : AppColors.accent.opacity(0.15))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Empty State View - Using CommonComponents.EmptyStateView


// MARK: - Previews
#if DEBUG
#Preview("Default State") {
    @MainActor func makePreview() -> some View {
        let container = try! ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        
        let user = User(
            id: UUID(),
            createdAt: Date(),
            lastActiveAt: Date(),
            email: "test@example.com",
            name: "Test User",
            preferredUnits: "metric"
        )
        context.insert(user)
        
        let coordinator = FoodTrackingCoordinator()
        let viewModel = FoodTrackingViewModel(
            modelContext: context,
            user: user,
            foodVoiceAdapter: FoodVoiceAdapter(),
            nutritionService: MockNutritionService(),
            coachEngine: CoachEngine.createDefault(modelContext: context),
            coordinator: coordinator
        )
        
        return NavigationStack {
            NutritionSearchView(viewModel: viewModel)
        }
        .modelContainer(container)
    }
    
    return makePreview()
}
#endif
