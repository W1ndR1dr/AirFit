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
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        BaseScreen {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    CascadeText("Workout Details")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -20)

                    // Workout header
                    workoutHeaderSection
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                    // Summary stats grid
                    summaryStatsSection
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                    // AI analysis
                    aiAnalysisSection
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

                    // Exercises breakdown
                    exercisesSection
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)

                    // Action buttons
                    actionsSection
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xl)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.5), value: animateIn)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
        }
        .sheet(isPresented: $showingAIAnalysis) {
            AIAnalysisView(analysis: viewModel.aiWorkoutSummary ?? workout.aiAnalysis ?? "")
                .environmentObject(gradientManager)
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise, workout: workout)
                .environmentObject(gradientManager)
        }
        .sheet(isPresented: $showingTemplateSheet) {
            SaveAsTemplateView(workout: workout, modelContext: modelContext)
                .environmentObject(gradientManager)
        }
        .sheet(item: $shareItem) { item in
            WorkoutShareSheet(activityItems: [item.text])
        }
    }
}

// MARK: - Sections
private extension WorkoutDetailView {
    var workoutHeaderSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.15) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .blur(radius: 8)

                        Image(systemName: workout.workoutTypeEnum?.systemImage ?? "figure.strengthtraining.traditional")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.workoutTypeEnum?.displayName ?? workout.workoutType)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        Text((workout.completedDate ?? workout.plannedDate ?? Date()).formatted(date: .complete, time: .shortened))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.secondary.opacity(0.8))
                    }

                    Spacer()
                }

                if let notes = workout.notes, !notes.isEmpty {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    gradientManager.active.colors(for: colorScheme).first?.opacity(0.2) ?? Color.clear,
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.vertical, AppSpacing.xs)

                    Text(notes)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(AppSpacing.md)
        }
    }

    var summaryStatsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
            SummaryStatCard(
                title: "Duration",
                value: workout.formattedDuration ?? "0m",
                icon: "timer",
                index: 0
            )
            .environmentObject(gradientManager)

            SummaryStatCard(
                title: "Exercises",
                value: "\(workout.exercises.count)",
                icon: "list.bullet",
                index: 1
            )
            .environmentObject(gradientManager)

            SummaryStatCard(
                title: "Total Sets",
                value: "\(workout.totalSets)",
                icon: "square.stack.3d.up",
                index: 2
            )
            .environmentObject(gradientManager)

            SummaryStatCard(
                title: "Calories",
                value: "\(Int(workout.caloriesBurned ?? 0))",
                icon: "flame.fill",
                index: 3
            )
            .environmentObject(gradientManager)
        }
    }

    var aiAnalysisSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        CascadeText("AI Analysis")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }

                    Spacer()

                    if viewModel.isGeneratingAnalysis {
                        ProgressView()
                            .controlSize(.small)
                            .progressViewStyle(CircularProgressViewStyle(tint: gradientManager.active.colors(for: colorScheme).first ?? .accentColor))
                    }
                }

                if let analysis = workout.aiAnalysis ?? viewModel.aiWorkoutSummary, !analysis.isEmpty {
                    Text(analysis.prefix(150) + "...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(3)
                        .padding(.vertical, AppSpacing.xs)

                    Button(action: {
                        HapticService.impact(.light)
                        showingAIAnalysis = true
                    }, label: {
                        HStack {
                            Text("Read Full Analysis")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    })
                } else {
                    Button {
                        HapticService.impact(.medium)
                        Task { await viewModel.generateAIAnalysis(for: workout) }
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Generate Analysis")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            LinearGradient(
                                colors: viewModel.isGeneratingAnalysis ?
                                    [Color.gray.opacity(0.6), Color.gray.opacity(0.4)] :
                                    gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(
                            color: viewModel.isGeneratingAnalysis ?
                                Color.clear :
                                gradientManager.active.colors(for: colorScheme)[0].opacity(0.2),
                            radius: 8,
                            y: 2
                        )
                    }
                    .disabled(viewModel.isGeneratingAnalysis)
                }
            }
            .padding(AppSpacing.md)
        }
    }

    var exercisesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    CascadeText("Exercises")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                Spacer()
            }

            VStack(spacing: AppSpacing.sm) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                    WorkoutExerciseCard(exercise: exercise, index: index) {
                        HapticService.impact(.light)
                        selectedExercise = exercise
                    }
                    .environmentObject(gradientManager)
                }
            }
        }
    }

    var actionsSection: some View {
        VStack(spacing: AppSpacing.small) {
            Button {
                HapticService.impact(.light)
                showingTemplateSheet = true
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Save as Template")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(0.05),
                            Color.primary.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                HapticService.impact(.light)
                shareWorkout()
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Share Workout")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(0.05),
                            Color.primary.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
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
    let index: Int
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    private var gradientColors: [Color] {
        switch icon {
        case "timer": return [Color(hex: "#667EEA"), Color(hex: "#764BA2")]
        case "list.bullet": return [Color(hex: "#52B788"), Color(hex: "#40916C")]
        case "square.stack.3d.up": return [Color(hex: "#00B4D8"), Color(hex: "#0077B6")]
        case "flame.fill": return [Color(hex: "#F8961E"), Color(hex: "#F3722C")]
        default: return gradientManager.active.colors(for: colorScheme)
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary.opacity(0.8))
                }

                GradientNumber(value: Double(value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.sm)
        }
        .scaleEffect(animateIn ? 1 : 0.9)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(Double(index) * 0.05)) {
                animateIn = true
            }
        }
    }
}

private struct WorkoutExerciseCard: View {
    let exercise: Exercise
    let index: Int
    let action: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var animateIn = false

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
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text(exercise.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("\(exercise.sets.count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("sets")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.secondary.opacity(0.8))
                        }
                    }

                    if !chartData.isEmpty {
                        Chart(chartData) { point in
                            BarMark(
                                x: .value("Set", point.index),
                                y: .value("Volume", point.volume)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .cornerRadius(4)
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .frame(height: 60)
                        .padding(.vertical, AppSpacing.xs)
                    }

                    HStack {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "scalemass")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "#00B4D8"),
                                            Color(hex: "#0077B6")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            GradientNumber(value: totalVolume)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            Text("kg total")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.secondary.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                    }
                }
                .padding(AppSpacing.md)
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
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(Double(index) * 0.1)) {
                animateIn = true
            }
        }
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
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var templateName: String = ""
    @State private var includeNotes = true
    @State private var animateIn = false

    var body: some View {
        NavigationStack {
            BaseScreen {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Title
                        CascadeText("Save Template")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)

                        // Template details
                        GlassCard {
                            VStack(spacing: AppSpacing.md) {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text("Template Name")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.secondary)

                                    TextField("Enter name", text: $templateName)
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .padding(AppSpacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.primary.opacity(0.05))
                                        )
                                }

                                HStack {
                                    Text("Include Notes")
                                        .font(.system(size: 16, weight: .medium))
                                    Spacer()
                                    Toggle("", isOn: $includeNotes)
                                        .labelsHidden()
                                        .tint(
                                            LinearGradient(
                                                colors: gradientManager.active.colors(for: colorScheme),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                                .padding(.top, AppSpacing.xs)
                            }
                            .padding(AppSpacing.md)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                        // Exercises preview
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack {
                                CascadeText("Exercises (\(workout.exercises.count))")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                Spacer()
                            }
                            .padding(.horizontal, AppSpacing.md)

                            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "#52B788"),
                                                    Color(hex: "#40916C")
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    Text(exercise.name)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.primary)

                                    Spacer()

                                    Text("\(exercise.sets.count) sets")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.secondary.opacity(0.8))
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .opacity(animateIn ? 1 : 0)
                                .offset(x: animateIn ? 0 : -20)
                                .animation(MotionToken.standardSpring.delay(0.2 + Double(index) * 0.05), value: animateIn)
                            }
                        }
                        .padding(.top, AppSpacing.sm)
                    }
                    .padding(.bottom, AppSpacing.xl)
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

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticService.impact(.medium)
                        saveTemplate()
                    }
                    .fontWeight(.semibold)
                    .disabled(templateName.isEmpty)
                    .foregroundStyle(
                        templateName.isEmpty ?
                            AnyShapeStyle(Color.secondary.opacity(0.5)) :
                            AnyShapeStyle(LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                }
            }
            .onAppear {
                templateName = workout.name
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
    }

    private func saveTemplate() {
        // Template saving removed - AI generates personalized workouts on-demand
    }
}

// MARK: - AI Analysis View
private struct AIAnalysisView: View {
    let analysis: String
    @Environment(\.dismiss)
    private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    var body: some View {
        NavigationStack {
            BaseScreen {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Header
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(animateIn ? 1 : 0.8)
                                .opacity(animateIn ? 1 : 0)

                            CascadeText("AI Analysis")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                        }
                        .padding(.top, AppSpacing.md)

                        // Analysis content
                        GlassCard {
                            Text(analysis)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.primary)
                                .textSelection(.enabled)
                                .padding(AppSpacing.md)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                        // AI disclaimer
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                            Text("Analysis generated by AI coach")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
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
}

// MARK: - Exercise Detail View
private struct ExerciseDetailView: View {
    let exercise: Exercise
    let workout: Workout
    @Environment(\.dismiss)
    private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    var body: some View {
        NavigationStack {
            BaseScreen {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Exercise name header
                        CascadeText(exercise.name)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)

                        // Exercise info
                        if !exercise.muscleGroups.isEmpty || exercise.notes != nil {
                            GlassCard {
                                VStack(alignment: .leading, spacing: AppSpacing.md) {
                                    if !exercise.muscleGroups.isEmpty {
                                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                            Text("Muscle Groups")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(Color.secondary)

                                            HStack(spacing: AppSpacing.xs) {
                                                ForEach(exercise.muscleGroups, id: \.self) { muscle in
                                                    Text(muscle)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .padding(.horizontal, AppSpacing.sm)
                                                        .padding(.vertical, 6)
                                                        .background(
                                                            LinearGradient(
                                                                colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.15) },
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }

                                    if let notes = exercise.notes {
                                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                            Text("Notes")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(Color.secondary)
                                            Text(notes)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(Color.primary)
                                        }
                                    }
                                }
                                .padding(AppSpacing.md)
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)
                        }

                        // Sets breakdown
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack {
                                CascadeText("Sets")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                Spacer()
                            }
                            .padding(.horizontal, AppSpacing.md)

                            VStack(spacing: AppSpacing.sm) {
                                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                                    GlassCard {
                                        HStack {
                                            HStack(spacing: AppSpacing.xs) {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: gradientManager.active.colors(for: colorScheme),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 8, height: 8)

                                                Text("Set \(index + 1)")
                                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            }

                                            Spacer()

                                            HStack(spacing: AppSpacing.sm) {
                                                if let reps = set.completedReps ?? set.targetReps {
                                                    GradientNumber(value: Double(reps))
                                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                                    Text("reps")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundStyle(Color.secondary)
                                                }

                                                if let weight = set.completedWeightKg ?? set.targetWeightKg, weight > 0 {
                                                    Text("×")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundStyle(Color.secondary.opacity(0.6))

                                                    GradientNumber(value: weight)
                                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                                    Text("kg")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundStyle(Color.secondary)
                                                }

                                                if let rpe = set.rpe {
                                                    Text("RPE \(Int(rpe))")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundStyle(Color.secondary.opacity(0.6))
                                                        .padding(.horizontal, AppSpacing.xs)
                                                        .padding(.vertical, 4)
                                                        .background(Color.primary.opacity(0.08))
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                        .padding(AppSpacing.sm)
                                    }
                                    .padding(.horizontal, AppSpacing.md)
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(MotionToken.standardSpring.delay(0.2 + Double(index) * 0.05), value: animateIn)
                                }
                            }
                        }

                        // Summary
                        GlassCard {
                            VStack(spacing: AppSpacing.md) {
                                let totalVolume = exercise.sets.reduce(0) { total, set in
                                    let reps = Double(set.completedReps ?? set.targetReps ?? 0)
                                    let weight = set.completedWeightKg ?? set.targetWeightKg ?? 0
                                    return total + (reps * weight)
                                }

                                HStack {
                                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                        Text("Total Sets")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(Color.secondary)
                                        GradientNumber(value: Double(exercise.sets.count))
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                    }

                                    Spacer()

                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.clear,
                                                    gradientManager.active.colors(for: colorScheme).first?.opacity(0.2) ?? Color.clear,
                                                    Color.clear
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 1, height: 40)

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                                        Text("Total Volume")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(Color.secondary)
                                        HStack(spacing: 4) {
                                            GradientNumber(value: totalVolume)
                                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                            Text("kg")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(Color.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(AppSpacing.md)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
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
}
