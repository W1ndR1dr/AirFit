import SwiftUI

/// A view for searching food items from a database, displaying recent foods, and browsing categories.
struct NutritionSearchView: View {
    @ObservedObject var viewModel: FoodTrackingViewModel
    @Environment(\\.dismiss) private var dismiss

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Debounce for search
    @State private var debounceTimer: Timer?

    // Categories - can be dynamic later
    private let foodCategories: [FoodCategory] = [
        FoodCategory(name: "Fruits", icon: "apple.logo"),
        FoodCategory(name: "Vegetables", icon: "leaf.fill"),
        FoodCategory(name: "Proteins", icon: "fish.fill"),
        FoodCategory(name: "Grains", icon: "wheat"),
        FoodCategory(name: "Dairy", icon: "milk.jug.fill"),
        FoodCategory(name: "Snacks", icon: "bolt.heart.fill")
    ]
    @State private var selectedCategory: FoodCategory? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.bottom, AppSpacing.small)

                Divider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                        if searchText.isEmpty && selectedCategory == nil {
                            initialContent // Shows categories, recents, favorites
                        } else if selectedCategory != nil && searchText.isEmpty {
                            categoryResultsContent // Shows results for a selected category
                        }
                        else {
                            searchResultsContent // Shows live search results
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle("Search Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                isSearchFocused = true
                if viewModel.recentFoods.isEmpty { // Load recents if not already loaded
                    Task {
                        await viewModel.loadTodaysData() // This loads recent foods
                    }
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)

            TextField("Search foods, brands...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    triggerSearch(immediately: true)
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.clearSearchResults() // Assuming a method to clear results in VM
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppConstants.Layout.defaultCornerRadius.medium)
        .padding(.horizontal)
        .onChange(of: searchText) { _, newValue in
            if selectedCategory != nil && !newValue.isEmpty {
                // If a category was selected, and user starts typing, clear category selection
                // to switch to general search.
                selectedCategory = nil
            }
            triggerSearch()
        }
    }

    // MARK: - Initial Content (No Search Text, No Category Selected)
    @ViewBuilder
    private var initialContent: some View {
        CategoriesSection(categories: foodCategories, selectedCategory: $selectedCategory)
            .padding(.horizontal)
        
        RecentFoodsSection(
            recentFoods: viewModel.recentFoods,
            onSelect: selectRecentFood
        )
        .padding(.horizontal)

        // Placeholder for Favorites
        // FavoriteFoodsSection().padding(.horizontal)
        
        // Placeholder for Popular Searches
        // PopularSearchesSection().padding(.horizontal)
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
            .font(AppFonts.footnote)
            .foregroundColor(AppColors.textSecondary)
        }
        
        // Simulate loading for category selection
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, AppSpacing.xLarge)
        } else if viewModel.searchResults.isEmpty { // Assuming searchResults is populated by category search
            EmptyStateView(
                icon: "tray.fill",
                title: "No Items in \(selectedCategory?.name ?? "Category")",
                message: "Try a different category or use the search bar."
            )
            .padding()
        } else {
            FoodItemsList(
                items: viewModel.searchResults.map { FoodListItem.databaseItem($0) },
                onSelectDatabaseItem: { item in
                    viewModel.selectSearchResult(item) // This should trigger coordinator
                    dismiss()
                }
            )
            .padding(.horizontal)
        }
    }


    // MARK: - Search Results Content
    @ViewBuilder
    private var searchResultsContent: some View {
        if viewModel.isLoading && !searchText.isEmpty {
            ProgressView("Searching...")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, AppSpacing.xLarge)
        } else if viewModel.searchResults.isEmpty && !searchText.isEmpty {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No Results Found",
                message: "Try a different search term or check for typos."
            )
            .padding()
        } else if !viewModel.searchResults.isEmpty {
            Text("Search Results (\(viewModel.searchResults.count))")
                .font(AppFonts.headline)
                .padding(.horizontal)
            
            FoodItemsList(
                items: viewModel.searchResults.map { FoodListItem.databaseItem($0) },
                onSelectDatabaseItem: { item in
                    viewModel.selectSearchResult(item) // This should trigger coordinator
                    dismiss()
                }
            )
            .padding(.horizontal)
        } else if !searchText.isEmpty {
             // Suggestion to type more if search text is short and no results yet
            Text("Keep typing to see more results...")
                .font(AppFonts.callout)
                .foregroundColor(AppColors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
    
    // MARK: - Helper Functions
    private func triggerSearch(immediately: Bool = false) {
        debounceTimer?.invalidate()
        
        guard !searchText.isEmpty || selectedCategory != nil else {
            viewModel.clearSearchResults() // Clear results if search text is empty and no category
            return
        }
        
        if immediately || searchText.count > 2 || selectedCategory != nil { // Start search immediately or after 2 chars
            performSearch()
        } else {
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                performSearch()
            }
        }
    }

    private func performSearch() {
        Task {
            if let category = selectedCategory, searchText.isEmpty {
                // Perform category-specific search
                // Assuming viewModel.searchFoods can handle a category parameter or a specific method exists
                // For now, we'll just use the searchText as if it was the category name for demo
                await viewModel.searchFoods(category.name)
            } else if !searchText.isEmpty {
                await viewModel.searchFoods(searchText)
            }
        }
    }

    private func selectRecentFood(_ food: FoodItem) {
        // Convert FoodItem to ParsedFoodItem and pass to confirmation
        let parsedItem = ParsedFoodItem(
            name: food.name,
            brand: food.brand,
            quantity: food.quantity,
            unit: food.unit,
            calories: food.calories,
            proteinGrams: food.proteinGrams,
            carbGrams: food.carbGrams,
            fatGrams: food.fatGrams,
            fiber: food.fiberGrams,
            sugar: food.sugarGrams,
            sodium: food.sodiumMg,
            barcode: food.barcode,
            databaseId: nil, // FoodItem is from local log, not necessarily a DB ID
            confidence: 1.0 // High confidence for user's own logged food
        )
        viewModel.setParsedItems([parsedItem]) // Update ViewModel
        viewModel.coordinator.showFullScreenCover(.confirmation([parsedItem]))
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

private struct RecentFoodsSection: View {
    let recentFoods: [FoodItem]
    let onSelect: (FoodItem) -> Void

    var body: some View {
        if !recentFoods.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Recent Foods")
                    .font(AppFonts.title3)
                    .fontWeight(.semibold)
                
                FoodItemsList(
                    items: recentFoods.map { FoodListItem.recentItem($0) },
                    onSelectRecentItem: onSelect
                )
            }
        } else {
            EmptyStateView(icon: "clock.arrow.circlepath", title: "No Recent Foods", message: "Foods you log will appear here for quick re-adding.")
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
        case .recentItem(let item): return item.calories
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
            return "\(item.quantity.formatted(.number.precision(.fractionLength(0...1)))) \(item.unit)"
        case .databaseItem(let item):
            return "\(item.defaultQuantity.formatted(.number.precision(.fractionLength(0...1)))) \(item.defaultUnit)"
        }
    }
}

private struct FoodItemsList: View {
    let items: [FoodListItem]
    var onSelectRecentItem: ((FoodItem) -> Void)? = nil
    var onSelectDatabaseItem: ((FoodDatabaseItem) -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            ForEach(items) { item in
                FoodItemRow(item: item) {
                    switch item {
                    case .recentItem(let recent):
                        onSelectRecentItem?(recent)
                    case .databaseItem(let dbItem):
                        onSelectDatabaseItem?(dbItem)
                    }
                }
                Divider().padding(.leading, AppSpacing.medium)
            }
        }
    }
}


private struct FoodItemRow: View {
    let item: FoodListItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                // Icon (optional, could be category-based or a generic food icon)
                Image(systemName: "takeoutbag.and.cup.and.straw.fill") // Placeholder icon
                    .font(.title2)
                    .foregroundColor(AppColors.accentColor)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(item.name)
                        .font(AppFonts.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)

                    if let brand = item.brand, !brand.isEmpty {
                        Text(brand)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Text(item.servingDescription)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppSpacing.xxSmall) {
                    Text("\(Int(item.calories)) cal")
                        .font(AppFonts.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.caloriesColor)
                    
                    HStack(spacing: AppSpacing.small) {
                        if let protein = item.protein {
                            MacroPill(label: "P", value: protein, color: AppColors.proteinColor)
                        }
                        if let carbs = item.carbs {
                            MacroPill(label: "C", value: carbs, color: AppColors.carbsColor)
                        }
                        if let fat = item.fat {
                            MacroPill(label: "F", value: fat, color: AppColors.fatColor)
                        }
                    }
                }
            }
            .padding(.vertical, AppSpacing.small)
        }
        .buttonStyle(.plain)
    }
}

private struct MacroPill: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(AppFonts.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text("\(Int(value))g")
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.xSmall)
        .padding(.vertical, AppSpacing.xxSmall)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
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
            .font(AppFonts.footnote)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.xSmall)
            .foregroundColor(isSelected ? AppColors.textOnAccent : AppColors.accentColor)
            .background(isSelected ? AppColors.accentColor : AppColors.accentColor.opacity(0.15))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Empty State View
private struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(AppColors.textTertiary)
            Text(title)
                .font(AppFonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.large)
    }
}


// MARK: - Previews
#Preview("Nutrition Search View - Initial") {
    let (user, modelContainer) = User.preview
    let context = modelContainer.mainContext
    
    let coordinator = FoodTrackingCoordinator()
    let foodVoiceAdapter = FoodVoiceAdapter(voiceInputManager: VoiceInputManager.shared)
    let nutritionService = NutritionService(modelContext: context) // Real service for previews
    let foodDBService = FoodDatabaseService() // Mock or actual
    let coachEngine = CoachEngine.createDefault(modelContext: context)

    let viewModel = FoodTrackingViewModel(
        modelContext: context,
        user: user,
        foodVoiceAdapter: foodVoiceAdapter,
        nutritionService: nutritionService,
        foodDatabaseService: foodDBService,
        coachEngine: coachEngine,
        coordinator: coordinator
    )
    Task { await viewModel.loadTodaysData() } // Load recent foods

    return NutritionSearchView(viewModel: viewModel)
        .modelContainer(modelContainer)
}

#Preview("Nutrition Search View - With Results") {
    let (user, modelContainer) = User.preview
    let context = modelContainer.mainContext
    
    let coordinator = FoodTrackingCoordinator()
    let foodVoiceAdapter = FoodVoiceAdapter(voiceInputManager: VoiceInputManager.shared)
    let nutritionService = NutritionService(modelContext: context)
    let foodDBService = FoodDatabaseService()
    let coachEngine = CoachEngine.createDefault(modelContext: context)

    let viewModel = FoodTrackingViewModel(
        modelContext: context,
        user: user,
        foodVoiceAdapter: foodVoiceAdapter,
        nutritionService: nutritionService,
        foodDatabaseService: foodDBService,
        coachEngine: coachEngine,
        coordinator: coordinator
    )
    
    // Simulate search results
    viewModel.setSearchResults([
        FoodDatabaseItem(id: "1", name: "Grilled Salmon", brand: "Wild Caught", defaultQuantity: 150, defaultUnit: "g", servingUnit: "g", caloriesPerServing: 300, proteinPerServing: 30, carbsPerServing: 0, fatPerServing: 20, calories: 300, protein: 30, carbs: 0, fat: 20),
        FoodDatabaseItem(id: "2", name: "Quinoa Salad", brand: "Organic", defaultQuantity: 1, defaultUnit: "cup", servingUnit: "cup", caloriesPerServing: 220, proteinPerServing: 8, carbsPerServing: 39, fatPerServing: 3.5, calories: 220, protein: 8, carbs: 39, fat: 3.5)
    ])

    return NutritionSearchView(viewModel: viewModel)
        .modelContainer(modelContainer)
}

#Preview("Nutrition Search View - No Results") {
    let (user, modelContainer) = User.preview
    let context = modelContainer.mainContext
    
    let coordinator = FoodTrackingCoordinator()
    let foodVoiceAdapter = FoodVoiceAdapter(voiceInputManager: VoiceInputManager.shared)
    let nutritionService = NutritionService(modelContext: context)
    let foodDBService = FoodDatabaseService()
    let coachEngine = CoachEngine.createDefault(modelContext: context)

    let viewModel = FoodTrackingViewModel(
        modelContext: context,
        user: user,
        foodVoiceAdapter: foodVoiceAdapter,
        nutritionService: nutritionService,
        foodDatabaseService: foodDBService,
        coachEngine: coachEngine,
        coordinator: coordinator
    )
    // Simulate empty search results after a search
    viewModel.setSearchResults([])


    return NutritionSearchView(viewModel: viewModel)
        .modelContainer(modelContainer)
        .onAppear {
            // To show "No Results Found" we need searchText to be non-empty
            // This is a bit of a hack for previewing this specific state.
            // In a real scenario, this would be after a search.
            // We can't directly set @State searchText from here.
        }
}
