import SwiftUI
import SwiftData

struct WorkoutBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: WorkoutViewModel
    
    @State private var workoutName = ""
    @State private var workoutType: WorkoutType = .strength
    @State private var selectedExercises: [BuilderExercise] = []
    @State private var showingExercisePicker = false
    @State private var notes = ""
    @State private var saveAsTemplate = true
    
    var isValid: Bool {
        !workoutName.isEmpty && !selectedExercises.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Workout Name", text: $workoutName)
                    
                    Picker("Type", selection: $workoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    ForEach($selectedExercises) { $exercise in
                        ExerciseBuilderRow(exercise: $exercise) {
                            removeExercise(exercise)
                        }
                    }
                    
                    Button(action: { showingExercisePicker = true }) {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Exercises")
                }
                
                Section {
                    Toggle("Save as Template", isOn: $saveAsTemplate)
                        .tint(AppColors.accent)
                }
            }
            .navigationTitle("Build Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { startWorkout() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exercise in
                    addExercise(from: exercise)
                }
            }
        }
    }
    
    private func addExercise(from definition: ExerciseDefinition) {
        let builderExercise = BuilderExercise(
            name: definition.name,
            muscleGroups: definition.muscleGroups.map(\.rawValue),
            sets: [BuilderSet()]
        )
        selectedExercises.append(builderExercise)
    }
    
    private func removeExercise(_ exercise: BuilderExercise) {
        selectedExercises.removeAll { $0.id == exercise.id }
    }
    
    private func startWorkout() {
        // Create workout
        let workout = Workout(
            name: workoutName,
            workoutType: workoutType,
            plannedDate: Date()
        )
        workout.notes = notes.isEmpty ? nil : notes
        
        // Add exercises
        for builderExercise in selectedExercises {
            let exercise = Exercise(
                name: builderExercise.name,
                muscleGroups: builderExercise.muscleGroups
            )
            exercise.notes = builderExercise.notes
            
            // Add sets
            for (index, builderSet) in builderExercise.sets.enumerated() {
                let set = ExerciseSet(
                    setNumber: index + 1,
                    targetReps: builderSet.targetReps,
                    targetWeightKg: builderSet.targetWeight
                )
                exercise.sets.append(set)
            }
            
            workout.exercises.append(exercise)
        }
        
        modelContext.insert(workout)
        
        // Save as template if requested
        if saveAsTemplate {
            let template = UserWorkoutTemplate(
                name: workoutName,
                workoutType: workoutType.rawValue,
                exercises: selectedExercises.map { exercise in
                    TemplateExercise(
                        name: exercise.name,
                        muscleGroups: exercise.muscleGroups,
                        notes: exercise.notes,
                        sets: exercise.sets.enumerated().map { index, set in
                            TemplateSetData(
                                order: index + 1,
                                targetReps: set.targetReps,
                                targetWeight: set.targetWeight
                            )
                        }
                    )
                },
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(template)
        }
        
        do {
            try modelContext.save()
            viewModel.activeWorkout = workout
            dismiss()
            
            // Navigate to active workout
            NotificationCenter.default.post(
                name: .startActiveWorkout,
                object: workout
            )
        } catch {
            AppLogger.error("Failed to create workout", error: error, category: .data)
        }
    }
}

// MARK: - Builder Models
struct BuilderExercise: Identifiable {
    let id = UUID()
    var name: String
    var muscleGroups: [String]
    var notes: String?
    var sets: [BuilderSet]
}

struct BuilderSet: Identifiable {
    let id = UUID()
    var targetReps: Int?
    var targetWeight: Double?
}

// MARK: - Exercise Builder Row
struct ExerciseBuilderRow: View {
    @Binding var exercise: BuilderExercise
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                VStack(alignment: .leading) {
                    Text(exercise.name)
                        .font(.headline)
                    
                    if !exercise.muscleGroups.isEmpty {
                        Text(exercise.muscleGroups.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            
            // Sets
            ForEach($exercise.sets) { $set in
                HStack {
                    Text("Set \(exercise.sets.firstIndex(where: { $0.id == set.id })! + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 50)
                    
                    HStack {
                        TextField("Reps", value: $set.targetReps, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        
                        Text("×")
                            .foregroundStyle(.secondary)
                        
                        TextField("Weight", value: $set.targetWeight, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                        
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if exercise.sets.count > 1 {
                        Button(action: { exercise.sets.removeAll { $0.id == set.id } }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Button(action: { exercise.sets.append(BuilderSet()) }) {
                Label("Add Set", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, AppSpacing.xSmall)
    }
}

// MARK: - Exercise Picker
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var exercises: [ExerciseDefinition] = []
    @State private var isLoading = true
    
    let onSelect: (ExerciseDefinition) -> Void
    
    var filteredExercises: [ExerciseDefinition] {
        guard !searchText.isEmpty else { return exercises }
        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredExercises) { exercise in
                Button(action: {
                    onSelect(exercise)
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            Text(exercise.category.displayName)
                                .font(.caption)
                                .padding(.horizontal, AppSpacing.xSmall)
                                .padding(.vertical, 2)
                                .background(exercise.category.color.opacity(0.2))
                                .clipShape(Capsule())
                            
                            Text(exercise.muscleGroups.map(\.displayName).joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                do {
                    exercises = try await ExerciseDatabase.shared.getAllExercises()
                    isLoading = false
                } catch {
                    AppLogger.error("Failed to load exercises", error: error, category: .data)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
} 