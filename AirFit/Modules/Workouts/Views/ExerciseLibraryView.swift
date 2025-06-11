import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.diContainer) private var container
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var exerciseDatabase: ExerciseDatabase?
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedEquipment: Equipment?
    @State private var selectedDifficulty: Difficulty?
    @State private var exercises: [ExerciseDefinition] = []
    @State private var selectedExercise: ExerciseDefinition?
    @State private var showingFilters = false
    @State private var hasLoaded = false
    @State private var animateIn = false

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]

    var filteredExercises: [ExerciseDefinition] {
        var result = exercises

        // Apply filters
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if let muscleGroup = selectedMuscleGroup {
            result = result.filter { $0.muscleGroups.contains(muscleGroup) }
        }

        if let equipment = selectedEquipment {
            result = result.filter { $0.equipment.contains(equipment) }
        }

        if let difficulty = selectedDifficulty {
            result = result.filter { $0.difficulty == difficulty }
        }

        // Apply search
        if !searchText.isEmpty {
            result = result.filter { exercise in
                exercise.name.localizedStandardContains(searchText) ||
                    exercise.instructions.contains { $0.localizedStandardContains(searchText) }
            }
        }

        return result.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            BaseScreen {
                VStack(spacing: 0) {
                    // Header
                    CascadeText("Exercise Library")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, AppSpacing.sm)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -20)
                    
                    // Search bar
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
                            
                            TextField("Search exercises...", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16, weight: .medium))
                                .onTapGesture {
                                    HapticService.impact(.light)
                                }
                            
                            if !searchText.isEmpty {
                                Button {
                                    HapticService.impact(.light)
                                    withAnimation(MotionToken.microAnimation) {
                                        searchText = ""
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
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)
                    
                    // Active filters indicator
                    if hasActiveFilters {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.xs) {
                                Text("Active filters:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                                
                                if let category = selectedCategory {
                                    FilterChip(text: category.displayName, type: .category)
                                }
                                if let muscle = selectedMuscleGroup {
                                    FilterChip(text: muscle.displayName, type: .muscle)
                                }
                                if let equipment = selectedEquipment {
                                    FilterChip(text: equipment.displayName, type: .equipment)
                                }
                                if let difficulty = selectedDifficulty {
                                    FilterChip(text: difficulty.displayName, type: .difficulty)
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                        }
                        .padding(.bottom, AppSpacing.sm)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Content
                    Group {
                        if exerciseDatabase?.isLoading ?? false {
                            loadingView
                        } else if exercises.isEmpty && !hasLoaded {
                            emptyStateView
                        } else {
                            exerciseGridView
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticService.impact(.light)
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(
                                hasActiveFilters ?
                                AnyShapeStyle(LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )) :
                                AnyShapeStyle(Color.secondary)
                            )
                    }
                }
            }
            .sheet(item: $selectedExercise, content: { exercise in
                ExerciseDetailSheet(exercise: exercise)
                    .environmentObject(gradientManager)
            })
            .sheet(isPresented: $showingFilters) {
                FilterSheet(
                    selectedCategory: $selectedCategory,
                    selectedMuscleGroup: $selectedMuscleGroup,
                    selectedEquipment: $selectedEquipment,
                    selectedDifficulty: $selectedDifficulty
                )
                .environmentObject(gradientManager)
            }
            .onAppear {
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
        .task {
            guard !hasLoaded else { return }
            do {
                exerciseDatabase = try await container.resolve(ExerciseDatabase.self)
                hasLoaded = true
                await loadExercises()
            } catch {
                AppLogger.error("Failed to resolve ExerciseDatabase", error: error, category: .ui)
            }
        }
    }

    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedMuscleGroup != nil ||
            selectedEquipment != nil || selectedDifficulty != nil
    }

    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            // Animated loading ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 6)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: exerciseDatabase?.loadingProgress ?? 0)
                    .stroke(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(MotionToken.standardSpring, value: exerciseDatabase?.loadingProgress)
                
                VStack(spacing: 2) {
                    GradientNumber(value: Double(Int((exerciseDatabase?.loadingProgress ?? 0) * 100)))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
            }

            CascadeText("Loading Exercise Library...")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "books.vertical",
            title: "No Exercises Found",
            message: "Try adjusting your search or filters to find exercises",
            action: clearFilters,
            actionTitle: "Clear Filters"
        )
    }

    private var exerciseGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                ForEach(Array(filteredExercises.enumerated()), id: \.element.id) { index, exercise in
                    ExerciseCard(exercise: exercise, index: index)
                        .environmentObject(gradientManager)
                        .onTapGesture {
                            HapticService.impact(.light)
                            selectedExercise = exercise
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.2 + Double(index % 10) * 0.05), value: animateIn)
                }
            }
            .padding(AppSpacing.md)
        }
        .refreshable {
            HapticService.impact(.medium)
            await loadExercises()
        }
    }

    private func loadExercises() async {
        guard let exerciseDatabase else { return }
        do {
            exercises = try await exerciseDatabase.getAllExercises()
        } catch {
            AppLogger.error("Failed to load exercises", error: error, category: .data)
        }
    }

    private func clearFilters() {
        selectedCategory = nil
        selectedMuscleGroup = nil
        selectedEquipment = nil
        selectedDifficulty = nil
    }
}

// MARK: - Supporting Views
private struct FilterChip: View {
    let text: String
    let type: FilterType
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    enum FilterType {
        case category, muscle, equipment, difficulty
        
        var icon: String {
            switch self {
            case .category: return "square.grid.2x2"
            case .muscle: return "figure.strengthtraining.traditional"
            case .equipment: return "dumbbell"
            case .difficulty: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.15) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
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
        .clipShape(Capsule())
    }
}

#Preview {
    ExerciseLibraryView()
}
