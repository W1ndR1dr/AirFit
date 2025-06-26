import SwiftUI
import SwiftData

/// Search interface for finding and selecting foods to log
struct NutritionSearchView: View {
    @State var viewModel: FoodTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory?
    @State private var debounceTimer: Timer?
    @State private var animateIn = false

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
            BaseScreen {
                VStack(spacing: 0) {
                    // Header with animated title
                    CascadeText("Add Food")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, AppSpacing.sm)
                        .opacity(animateIn ? 1 : 0)

                    searchBar
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
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
            }
            .onAppear {
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        GlassCard {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(size: 18))

                TextField("Search foods...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium))
                    .onSubmit {
                        HapticService.impact(.light)
                        Task { await performSearch() }
                    }
                    .onChange(of: searchText) { _, newValue in
                        triggerSearch()
                    }

                if !searchText.isEmpty {
                    Button {
                        HapticService.impact(.light)
                        withAnimation(MotionToken.microAnimation) {
                            searchText = ""
                            selectedCategory = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.secondary.opacity(0.6))
                            .font(.system(size: 16))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(AppSpacing.sm)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }

    // MARK: - Initial Content
    @ViewBuilder
    private var initialContent: some View {
        CategoriesSection(categories: foodCategories, selectedCategory: $selectedCategory)
            .padding(.horizontal)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
            .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

        HStack {
            CascadeText("Recent Foods")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
        .opacity(animateIn ? 1 : 0)
        .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)

        if viewModel.recentFoods.isEmpty {
            EmptyStateView(
                icon: "clock.arrow.circlepath",
                title: "No Recent Foods",
                message: "Foods you log will appear here for quick re-adding."
            )
        } else {
            ForEach(Array(viewModel.recentFoods.prefix(5).enumerated()), id: \.element.id) { index, food in
                FoodItemRow(food: food) {
                    HapticService.impact(.light)
                    selectRecentFood(food)
                }
                .padding(.horizontal, AppSpacing.md)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.5 + Double(index) * 0.1), value: animateIn)
            }
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
            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: gradientManager.active.colors(for: colorScheme).first ?? Color.accentColor))
                    .scaleEffect(1.2)

                Text("Loading...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, AppSpacing.xl)
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
            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: gradientManager.active.colors(for: colorScheme).first ?? Color.accentColor))
                    .scaleEffect(1.2)

                CascadeText("Searching...")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, AppSpacing.xl)
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
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                CascadeText("Categories")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        CategoryChip(category: category, isSelected: selectedCategory == category) {
                            HapticService.impact(.light)
                            withAnimation(MotionToken.microAnimation) {
                                if selectedCategory == category {
                                    selectedCategory = nil // Deselect
                                } else {
                                    selectedCategory = category
                                }
                            }
                        }
                        .scaleEffect(selectedCategory == category ? 1.05 : 1.0)
                        .animation(MotionToken.microAnimation, value: selectedCategory)
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
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            GlassCard {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    // Icon with gradient
                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(food.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)
                            .lineLimit(2)

                        if let brand = food.brand, !brand.isEmpty {
                            Text(brand)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.secondary.opacity(0.8))
                                .lineLimit(1)
                        }

                        Text("\(food.quantity?.formatted() ?? "1") \(food.unit ?? "serving")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary.opacity(0.6))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        GradientNumber(value: Double(food.calories ?? 0))
                            .font(.system(size: 20, weight: .bold, design: .rounded))

                        Text("cal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.orange.opacity(0.8))
                    }
                }
                .padding(AppSpacing.sm)
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(MotionToken.microAnimation, value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MotionToken.microAnimation) {
                isPressed = pressing
            }
        }, perform: {})
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
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                Text(category.name)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .foregroundStyle(
                isSelected ?
                    AnyShapeStyle(Color.white) :
                    AnyShapeStyle(LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .background {
                if isSelected {
                    LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.primary.opacity(0.08)
                }
            }
            .clipShape(Capsule())
            .overlay {
                if !isSelected {
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
            .shadow(color: isSelected ? gradientManager.active.colors(for: colorScheme).first?.opacity(0.3) ?? .clear : .clear, radius: 8, y: 4)
        }
    }
}

// MARK: - Empty State View - Using CommonComponents.EmptyStateView


// MARK: - Previews
// TODO: Fix preview to handle async CoachEngine.createDefault
