import SwiftUI

struct ExerciseLoggingView: View {
    let workoutManager: WatchWorkoutManager
    @State private var showingExercisePicker = false
    @State private var showingSetLogger = false

    var currentExercise: ExerciseBuilderData? {
        workoutManager.currentWorkoutData.exercises.last
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Current exercise
                if let exercise = currentExercise {
                    CurrentExerciseCard(exercise: exercise)

                    // Log set button
                    Button {
                        showingSetLogger = true
                    } label: {
                        Label("Log Set", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    // Recent sets
                    if !exercise.sets.isEmpty {
                        RecentSetsView(sets: exercise.sets)
                    }
                } else {
                    // No exercise started
                    Text("Start an exercise to begin logging")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                // New exercise button
                Button {
                    showingExercisePicker = true
                } label: {
                    Label("New Exercise", systemImage: "figure.strengthtraining.traditional")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                workoutManager.startNewExercise(
                    name: exercise.name,
                    muscleGroups: exercise.muscleGroups
                )
                showingExercisePicker = false
            }
        }
        .sheet(isPresented: $showingSetLogger) {
            SetLoggerView { reps, weight, duration, rpe in
                workoutManager.logSet(
                    reps: reps,
                    weight: weight,
                    duration: duration,
                    rpe: rpe
                )
                showingSetLogger = false
            }
        }
    }
}

struct CurrentExerciseCard: View {
    let exercise: ExerciseBuilderData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exercise.name)
                .font(.headline)

            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption)
                Text(exercise.muscleGroups.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !exercise.sets.isEmpty {
                Text("\(exercise.sets.count) sets completed")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct RecentSetsView: View {
    let sets: [SetBuilderData]

    var recentSets: [SetBuilderData] {
        Array(sets.suffix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent Sets")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(recentSets.enumerated()), id: \.offset) { index, set in
                HStack {
                    Text("Set \(sets.count - (recentSets.count - index - 1))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let reps = set.reps, let weight = set.weightKg {
                        Text("\(reps) × \(weight.formatted())kg")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Exercise Picker
struct ExercisePickerView: View {
    let onExerciseSelected: (ExerciseTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let exercises: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Push-ups", muscleGroups: ["Chest", "Triceps"]),
        ExerciseTemplate(name: "Squats", muscleGroups: ["Legs", "Glutes"]),
        ExerciseTemplate(name: "Pull-ups", muscleGroups: ["Back", "Biceps"]),
        ExerciseTemplate(name: "Bench Press", muscleGroups: ["Chest", "Triceps"]),
        ExerciseTemplate(name: "Deadlift", muscleGroups: ["Back", "Legs"]),
        ExerciseTemplate(name: "Overhead Press", muscleGroups: ["Shoulders", "Triceps"])
    ]
    
    var body: some View {
        NavigationStack {
            List(exercises, id: \.name) { exercise in
                Button {
                    onExerciseSelected(exercise)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.headline)
                        Text(exercise.muscleGroups.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Set Logger
struct SetLoggerView: View {
    let onSetLogged: (Int?, Double?, TimeInterval?, Double?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var reps: Int = 10
    @State private var weight: Double = 20.0
    @State private var duration: TimeInterval = 0
    @State private var rpe: Double = 7.0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reps") {
                    Stepper("\(reps) reps", value: $reps, in: 1...50)
                }
                
                Section("Weight") {
                    HStack {
                        Text("\(weight.formatted())kg")
                        Spacer()
                        Stepper("", value: $weight, in: 0...200, step: 2.5)
                            .labelsHidden()
                    }
                }
                
                Section("RPE") {
                    HStack {
                        Text("RPE \(rpe.formatted())")
                        Spacer()
                        Stepper("", value: $rpe, in: 1...10, step: 0.5)
                            .labelsHidden()
                    }
                }
            }
            .navigationTitle("Log Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSetLogged(reps, weight, duration, rpe)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types
struct ExerciseTemplate {
    let name: String
    let muscleGroups: [String]
}
