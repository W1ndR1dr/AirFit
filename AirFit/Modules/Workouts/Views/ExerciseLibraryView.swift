import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.diContainer) private var container
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
            Group {
                if exerciseDatabase?.isLoading ?? false {
                    loadingView
                } else if exercises.isEmpty && !hasLoaded {
                    emptyStateView
                } else {
                    exerciseGridView
                }
            }
            .navigationTitle("Exercise Library")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(hasActiveFilters ? AppColors.accent : .secondary)
                    }
                }
            }
            .sheet(item: $selectedExercise, content: { exercise in
                ExerciseDetailSheet(exercise: exercise)
            })
            .sheet(isPresented: $showingFilters) {
                FilterSheet(
                    selectedCategory: $selectedCategory,
                    selectedMuscleGroup: $selectedMuscleGroup,
                    selectedEquipment: $selectedEquipment,
                    selectedDifficulty: $selectedDifficulty
                )
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
        VStack(spacing: AppSpacing.large) {
            ProgressView(value: exerciseDatabase?.loadingProgress ?? 0)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(maxWidth: 200)

            Text("Loading Exercise Library...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("\(Int((exerciseDatabase?.loadingProgress ?? 0) * 100))% Complete")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
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
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredExercises) { exercise in
                    ExerciseCard(exercise: exercise)
                        .onTapGesture {
                            selectedExercise = exercise
                        }
                }
            }
            .padding()
        }
        .refreshable {
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

#Preview {
    ExerciseLibraryView()
}
