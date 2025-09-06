import SwiftUI
import SwiftData

struct WorkoutBuilderView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.modelContext)
    private var modelContext
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State var viewModel: WorkoutViewModel

    @State private var workoutName = ""
    @State private var workoutType: WorkoutType = .strength
    @State private var selectedExercises: [BuilderExercise] = []
    @State private var showingExercisePicker = false
    @State private var notes = ""
    @State private var saveAsTemplate = true
    @State private var animateIn = false

    var isValid: Bool {
        !workoutName.isEmpty && !selectedExercises.isEmpty
    }

    var body: some View {
        NavigationStack {
            BaseScreen {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Header
                        CascadeText("Build Workout")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)

                        // Workout Details
                        GlassCard {
                            VStack(spacing: AppSpacing.md) {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text("Workout Name")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.secondary)

                                    HStack {
                                        TextField("Enter name", text: $workoutName)
                                            .font(.system(size: 18, weight: .medium, design: .rounded))
                                        WhisperVoiceButton(text: $workoutName)
                                    }
                                    .padding(AppSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.primary.opacity(0.05))
                                    )
                                    .onTapGesture {
                                        HapticService.impact(.light)
                                    }
                                }

                                // Workout type selector
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text("Workout Type")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.secondary)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: AppSpacing.sm) {
                                            ForEach(WorkoutType.allCases, id: \.self) { type in
                                                WorkoutTypeChip(type: type, isSelected: workoutType == type) {
                                                    HapticService.impact(.light)
                                                    withAnimation(MotionToken.microAnimation) {
                                                        workoutType = type
                                                    }
                                                }
                                                .environmentObject(gradientManager)
                                            }
                                        }
                                    }
                                }

                                // Notes
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text("Notes (optional)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.secondary)

                                    TextField("Add any notes...", text: $notes, axis: .vertical)
                                        .font(.system(size: 16, weight: .medium))
                                        .lineLimit(3...6)
                                        .padding(AppSpacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.primary.opacity(0.05))
                                        )
                                        .overlay(alignment: .bottomTrailing) {
                                            WhisperVoiceButton(text: $notes)
                                                .padding(8)
                                        }
                                }
                            }
                            .padding(AppSpacing.md)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                        // Exercises section
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
                            .padding(.horizontal, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                            if selectedExercises.isEmpty {
                                EmptyStateView(
                                    icon: "figure.strengthtraining.traditional",
                                    title: "No Exercises Yet",
                                    message: "Add exercises to build your workout"
                                )
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.xl)
                                .opacity(animateIn ? 1 : 0)
                                .animation(MotionToken.standardSpring.delay(0.25), value: animateIn)
                            } else {
                                ForEach(Array($selectedExercises.enumerated()), id: \.element.id) { index, $exercise in
                                    ExerciseBuilderRow(exercise: $exercise, index: index) {
                                        HapticService.impact(.light)
                                        withAnimation(MotionToken.standardSpring) {
                                            removeExercise(exercise)
                                        }
                                    }
                                    .environmentObject(gradientManager)
                                    .padding(.horizontal, AppSpacing.md)
                                }
                            }

                            Button {
                                HapticService.impact(.medium)
                                showingExercisePicker = true
                            } label: {
                                HStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Add Exercise")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.2), radius: 8, y: 2)
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
                        }

                        // Save as template option
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text("Save as Template")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Reuse this workout structure later")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color.secondary.opacity(0.8))
                                }

                                Spacer()

                                Toggle("", isOn: $saveAsTemplate)
                                    .labelsHidden()
                                    .tint(
                                        LinearGradient(
                                            colors: gradientManager.active.colors(for: colorScheme),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            .padding(AppSpacing.md)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xl)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)
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

                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        HapticService.impact(.medium)
                        startWorkout()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                    .foregroundStyle(
                        !isValid ?
                            AnyShapeStyle(Color.secondary.opacity(0.5)) :
                            AnyShapeStyle(LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(
                    exerciseDatabase: viewModel.exerciseDatabase
                ) { exercise in
                    HapticService.impact(.medium)
                    addExercise(from: exercise)
                }
                .environmentObject(gradientManager)
            }
            .onAppear {
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
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

        // Template saving removed - AI generates personalized workouts on-demand

        do {
            try modelContext.save()
            viewModel.activeWorkout = workout
            dismiss()

            // Navigation to active workout handled by viewModel state change
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
    let index: Int
    let onDelete: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(exercise.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        if !exercise.muscleGroups.isEmpty {
                            HStack(spacing: AppSpacing.xs) {
                                ForEach(exercise.muscleGroups, id: \.self) { muscle in
                                    Text(muscle)
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, AppSpacing.xs)
                                        .padding(.vertical, 4)
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

                    Spacer()

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#F94144"), Color(hex: "#F3722C")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }

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

                // Sets
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array($exercise.sets.enumerated()), id: \.element.id) { setIndex, $set in
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
                                    .frame(width: 6, height: 6)

                                Text("Set \(setIndex + 1)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                                    .frame(width: 50, alignment: .leading)
                            }

                            HStack(spacing: AppSpacing.sm) {
                                TextField("0", value: $set.targetReps, format: .number)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .frame(width: 50)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.primary.opacity(0.05))
                                    )
                                    .onTapGesture {
                                        HapticService.impact(.light)
                                    }

                                Text("reps")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.secondary.opacity(0.8))

                                Text("×")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.secondary.opacity(0.6))

                                TextField("0", value: $set.targetWeight, format: .number)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 60)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.primary.opacity(0.05))
                                    )
                                    .onTapGesture {
                                        HapticService.impact(.light)
                                    }

                                Text("kg")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.secondary.opacity(0.8))
                            }

                            Spacer()

                            if exercise.sets.count > 1 {
                                Button {
                                    HapticService.impact(.light)
                                    withAnimation(MotionToken.standardSpring) {
                                        exercise.sets.removeAll { $0.id == set.id }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(hex: "#F94144").opacity(0.8), Color(hex: "#F3722C").opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Button {
                    HapticService.impact(.light)
                    withAnimation(MotionToken.standardSpring) {
                        exercise.sets.append(BuilderSet())
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                        Text("Add Set")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(AppSpacing.md)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.25 + Double(index) * 0.1)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Exercise Picker
struct ExercisePickerView: View {
    @Environment(\.dismiss)
    private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var exercises: [ExerciseDefinition] = []
    @State private var isLoading = true
    @State private var animateIn = false

    let exerciseDatabase: ExerciseDatabase
    let onSelect: (ExerciseDefinition) -> Void

    var filteredExercises: [ExerciseDefinition] {
        guard !searchText.isEmpty else { return exercises }
        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            BaseScreen {
                VStack(spacing: 0) {
                    // Header
                    CascadeText("Select Exercise")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.top, AppSpacing.md)
                        .padding(.horizontal, AppSpacing.md)
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

                            WhisperVoiceButton(text: $searchText)

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
                    .padding(.vertical, AppSpacing.sm)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                    if isLoading {
                        Spacer()
                        TextLoadingView(message: "Building workout")
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: AppSpacing.sm) {
                                ForEach(Array(filteredExercises.enumerated()), id: \.element.id) { index, exercise in
                                    ExerciseRow(exercise: exercise, index: index) {
                                        HapticService.impact(.medium)
                                        onSelect(exercise)
                                        dismiss()
                                    }
                                    .environmentObject(gradientManager)
                                    .padding(.horizontal, AppSpacing.md)
                                }
                            }
                            .padding(.vertical, AppSpacing.sm)
                        }
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
            .task {
                do {
                    exercises = try await exerciseDatabase.getAllExercises()
                    isLoading = false
                    withAnimation(MotionToken.standardSpring) {
                        animateIn = true
                    }
                } catch {
                    AppLogger.error("Failed to load exercises", error: error, category: .data)
                }
            }
        }
    }
}

// MARK: - Workout Type Chip
private struct WorkoutTypeChip: View {
    let type: WorkoutType
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 14, weight: .medium))
                Text(type.displayName)
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

// MARK: - Exercise Row
private struct ExerciseRow: View {
    let exercise: ExerciseDefinition
    let index: Int
    let action: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var animateIn = false

    private var categoryColors: [Color] {
        // Use gradient colors for all categories
        return gradientManager.active.colors(for: colorScheme)
    }

    private func getCategoryIcon(for category: ExerciseCategory) -> String {
        switch category {
        case .strength: return "figure.strengthtraining.traditional"
        case .cardio: return "figure.run"
        case .flexibility: return "figure.flexibility"
        case .plyometrics: return "figure.jumprope"
        case .balance: return "figure.yoga"
        case .sports: return "sportscourt"
        }
    }

    var body: some View {
        Button(action: action) {
            GlassCard {
                HStack(spacing: AppSpacing.md) {
                    // Category icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: categoryColors.map { $0.opacity(0.15) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Image(systemName: getCategoryIcon(for: exercise.category))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: categoryColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(exercise.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        HStack(spacing: AppSpacing.sm) {
                            Text(exercise.category.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, AppSpacing.xs)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: categoryColors.map { $0.opacity(0.2) },
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Capsule())

                            Text(exercise.muscleGroups.map(\.displayName).joined(separator: ", "))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.secondary.opacity(0.8))
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary.opacity(0.3))
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
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.2 + Double(index) * 0.05)) {
                animateIn = true
            }
        }
    }
}
