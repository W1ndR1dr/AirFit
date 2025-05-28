import SwiftUI

struct ExerciseLoggingView: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
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
                    Button(action: { showingSetLogger = true }) {
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
                Button(action: { showingExercisePicker = true }) {
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
                    .foregroundStyle(.accent)
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

