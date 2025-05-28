import SwiftUI
import Charts
import Observation

struct WorkoutDetailView: View {
    let workout: Workout
    @State var viewModel: WorkoutViewModel
    @State private var showingAIAnalysis = false
    @State private var selectedExercise: Exercise?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                // Workout header
                workoutHeaderSection

                // Summary stats grid
                summaryStatsSection

                // AI analysis
                aiAnalysisSection

                // Exercises breakdown
                exercisesSection

                // Action buttons
                actionsSection
            }
            .padding()
        }
        .navigationTitle("Workout Details")
        .sheet(isPresented: $showingAIAnalysis) {
            AIAnalysisView(analysis: viewModel.aiWorkoutSummary ?? "")
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise, workout: workout)
        }
    }
}

// MARK: - Sections
private extension WorkoutDetailView {
    var workoutHeaderSection: some View {
        Card {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Image(systemName: workout.workoutTypeEnum?.systemImage ?? "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundStyle(AppColors.accent)

                    VStack(alignment: .leading) {
                        Text(workout.workoutTypeEnum?.displayName ?? workout.workoutType)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text((workout.completedDate ?? workout.plannedDate ?? Date()).formatted(date: .complete, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                if let notes = workout.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, AppSpacing.xSmall)
                }
            }
        }
    }

    var summaryStatsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.medium) {
            SummaryStatCard(
                title: "Duration",
                value: workout.formattedDuration ?? "0m",
                icon: "timer",
                color: .blue
            )

            SummaryStatCard(
                title: "Exercises",
                value: "\(workout.exercises.count)",
                icon: "list.bullet",
                color: .green
            )

            SummaryStatCard(
                title: "Total Sets",
                value: "\(workout.totalSets)",
                icon: "square.stack.3d.up",
                color: .purple
            )

            SummaryStatCard(
                title: "Calories",
                value: "\(Int(workout.caloriesBurned ?? 0))",
                icon: "flame.fill",
                color: .orange
            )
        }
    }

    var aiAnalysisSection: some View {
        Card {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Label("AI Analysis", systemImage: "sparkles")
                        .font(.headline)

                    Spacer()

                    if viewModel.isGeneratingAnalysis {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if let analysis = viewModel.aiWorkoutSummary, !analysis.isEmpty {
                    Text(analysis.prefix(100) + "...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)

                    Button("Read Full Analysis") { showingAIAnalysis = true }
                        .font(.callout)
                        .foregroundStyle(AppColors.accent)
                } else {
                    Button("Generate Analysis") {
                        Task { await viewModel.generateAIAnalysis(for: workout) }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isGeneratingAnalysis)
                }
            }
        }
    }

    var exercisesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Exercises", icon: "figure.strengthtraining.traditional")

            VStack(spacing: AppSpacing.small) {
                ForEach(workout.exercises) { exercise in
                    WorkoutExerciseCard(exercise: exercise) {
                        selectedExercise = exercise
                    }
                }
            }
        }
    }

    var actionsSection: some View {
        VStack(spacing: AppSpacing.small) {
            Button(action: createTemplate) {
                Label("Save as Template", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(action: shareWorkout) {
                Label("Share Workout", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top)
    }

    func createTemplate() {
        // TODO: Show template creation flow
    }

    func shareWorkout() {
        // TODO: Share workout summary
    }
}

// MARK: - Supporting Views
private struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct WorkoutExerciseCard: View {
    let exercise: Exercise
    let action: () -> Void

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let index: Int
        let volume: Double
    }

    private var chartData: [ChartPoint] {
        exercise.sets.enumerated().compactMap { index, set in
            let reps = Double(set.completedReps ?? set.targetReps ?? 0)
            let weight = set.completedWeightKg ?? set.targetWeightKg ?? 0
            let volume = reps * weight
            return ChartPoint(index: index + 1, volume: volume)
        }
    }

    private var totalVolume: Double {
        chartData.reduce(0) { $0 + $1.volume }
    }

    var body: some View {
        Button(action: action) {
            Card {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    HStack {
                        Text(exercise.name)
                            .font(.headline)
                        Spacer()
                        Text("\(exercise.sets.count) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !chartData.isEmpty {
                        Chart(chartData) { point in
                            BarMark(
                                x: .value("Set", point.index),
                                y: .value("Volume", point.volume)
                            )
                            .foregroundStyle(AppColors.accent.gradient)
                        }
                        .chartXAxis(.hidden)
                        .frame(height: 80)
                    }

                    HStack {
                        Label("\(Int(totalVolume))kg total", systemImage: "scalemass")
                            .font(.caption)
                            .foregroundStyle(AppColors.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.quaternary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Views
private struct AIAnalysisView: View {
    let analysis: String
    var body: some View { ScrollView { Text(analysis).padding() } }
}

private struct ExerciseDetailView: View {
    let exercise: Exercise
    let workout: Workout
    var body: some View { Text(exercise.name).padding() }
}

