import SwiftUI
import Charts
import Observation
import SwiftData

struct WorkoutDetailView: View {
    let workout: Workout
    @State var viewModel: WorkoutViewModel
    @State private var showingAIAnalysis = false
    @State private var selectedExercise: Exercise?
    @State private var showingTemplateSheet = false
    @State private var showingShareSheet = false
    @State private var shareItem: ShareItem?
    @Environment(\.modelContext)
    private var modelContext

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
            AIAnalysisView(analysis: viewModel.aiWorkoutSummary ?? workout.aiAnalysis ?? "")
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise, workout: workout)
        }
        .sheet(isPresented: $showingTemplateSheet) {
            SaveAsTemplateView(workout: workout, modelContext: modelContext)
        }
        .sheet(item: $shareItem) { item in
            WorkoutShareSheet(activityItems: [item.text])
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

                if let analysis = workout.aiAnalysis ?? viewModel.aiWorkoutSummary, !analysis.isEmpty {
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
            Button {
                showingTemplateSheet = true
            } label: {
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

    func shareWorkout() {
        let shareText = generateShareText()
        shareItem = ShareItem(text: shareText)
    }

    func generateShareText() -> String {
        var text = "🏋️ \(workout.name)\n"
        text += "\(workout.workoutTypeEnum?.displayName ?? "Workout") • \(workout.formattedDuration ?? "0m")\n\n"

        if let calories = workout.caloriesBurned, calories > 0 {
            text += "🔥 \(Int(calories)) calories burned\n"
        }

        text += "💪 \(workout.exercises.count) exercises • \(workout.totalSets) sets\n\n"

        // Exercise summary
        text += "Exercises:\n"
        for exercise in workout.exercises {
            let totalVolume = exercise.sets.reduce(0) { total, set in
                let reps = Double(set.completedReps ?? set.targetReps ?? 0)
                let weight = set.completedWeightKg ?? set.targetWeightKg ?? 0
                return total + (reps * weight)
            }
            text += "• \(exercise.name): \(exercise.sets.count) sets"
            if totalVolume > 0 {
                text += " • \(Int(totalVolume))kg total"
            }
            text += "\n"
        }

        if let analysis = workout.aiAnalysis {
            text += "\n✨ AI Coach: \(analysis.prefix(100))..."
        }

        text += "\n\n—\nTracked with AirFit"

        return text
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

// MARK: - Share Item
private struct ShareItem: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - Share Sheet
private struct WorkoutShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Save as Template View
private struct SaveAsTemplateView: View {
    let workout: Workout
    let modelContext: ModelContext
    @Environment(\.dismiss)
    private var dismiss
    @State private var templateName: String = ""
    @State private var includeNotes = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Template Name", text: $templateName)
                    Toggle("Include Notes", isOn: $includeNotes)
                }

                Section("Exercises") {
                    ForEach(workout.exercises) { exercise in
                        Label(exercise.name, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Save as Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTemplate() }
                        .fontWeight(.semibold)
                        .disabled(templateName.isEmpty)
                }
            }
        }
        .onAppear {
            templateName = workout.name
        }
    }

    private func saveTemplate() {
        let template = UserWorkoutTemplate(
            name: templateName,
            workoutType: workout.workoutType,
            exercises: workout.exercises.map { exercise in
                TemplateExercise(
                    name: exercise.name,
                    muscleGroups: exercise.muscleGroups,
                    notes: includeNotes ? exercise.notes : nil,
                    sets: exercise.sets.enumerated().map { index, set in
                        TemplateSetData(
                            order: index + 1,
                            targetReps: set.targetReps ?? set.completedReps,
                            targetWeight: set.targetWeightKg ?? set.completedWeightKg
                        )
                    }
                )
            },
            notes: includeNotes ? workout.notes : nil
        )

        modelContext.insert(template)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            AppLogger.error("Failed to save template", error: error, category: .data)
        }
    }
}

// MARK: - AI Analysis View
private struct AIAnalysisView: View {
    let analysis: String
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(analysis)
                    .padding()
                    .textSelection(.enabled)
            }
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Exercise Detail View
private struct ExerciseDetailView: View {
    let exercise: Exercise
    let workout: Workout
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Exercise Info") {
                    LabeledContent("Name", value: exercise.name)
                    if !exercise.muscleGroups.isEmpty {
                        LabeledContent("Muscle Groups", value: exercise.muscleGroups.joined(separator: ", "))
                    }
                    if let notes = exercise.notes {
                        LabeledContent("Notes", value: notes)
                    }
                }

                Section("Sets") {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .fontWeight(.medium)

                            Spacer()

                            if let reps = set.completedReps ?? set.targetReps {
                                Text("\(reps) reps")
                            }

                            if let weight = set.completedWeightKg ?? set.targetWeightKg, weight > 0 {
                                Text("× \(weight, specifier: "%.1f")kg")
                            }

                            if let rpe = set.rpe {
                                Text("RPE \(Int(rpe))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Summary") {
                    let totalVolume = exercise.sets.reduce(0) { total, set in
                        let reps = Double(set.completedReps ?? set.targetReps ?? 0)
                        let weight = set.completedWeightKg ?? set.targetWeightKg ?? 0
                        return total + (reps * weight)
                    }

                    LabeledContent("Total Sets", value: "\(exercise.sets.count)")
                    LabeledContent("Total Volume", value: "\(Int(totalVolume))kg")
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
