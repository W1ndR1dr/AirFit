import SwiftUI

// MARK: - Exercise Card
struct ExerciseCard: View {
    let exercise: ExerciseDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            // Exercise Image
            exerciseImage

            // Exercise Info
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    DifficultyPill(difficulty: exercise.difficulty)
                    Spacer()
                    CategoryBadge(category: exercise.category)
                }

                MuscleGroupTags(muscleGroups: Array(exercise.muscleGroups.prefix(2)))
            }
            .padding(AppSpacing.small)
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    private var exerciseImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.backgroundSecondary)
                .frame(height: 120)

            // Placeholder for now - could load actual images later
            Image(systemName: exercise.category.systemImage)
                .font(.system(size: 40))
                .foregroundStyle(exercise.category.color)
        }
        .clipped()
    }
}

// MARK: - Exercise Detail Sheet
struct ExerciseDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: ExerciseDefinition
    @State private var selectedImageIndex = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    // Header
                    exerciseHeader

                    // Instructions
                    instructionsSection

                    // Tips and Mistakes (if available)
                    if !exercise.tips.isEmpty {
                        tipsSection
                    }

                    if !exercise.commonMistakes.isEmpty {
                        mistakesSection
                    }

                    // Action Button
                    actionButton
                }
                .padding()
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.backgroundSecondary)
                .frame(height: 200)
                .overlay {
                    Image(systemName: exercise.category.systemImage)
                        .font(.system(size: 60))
                        .foregroundStyle(exercise.category.color)
                }

            // Exercise metadata
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    DifficultyPill(difficulty: exercise.difficulty)
                    CategoryBadge(category: exercise.category)
                    Spacer()
                    if exercise.isCompound {
                        CompoundBadge()
                    }
                }

                MuscleGroupWrap(muscleGroups: exercise.muscleGroups)
                EquipmentTags(equipment: exercise.equipment)
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Instructions")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                ForEach(
                    Array(exercise.instructions.enumerated()),
                    id: \.offset
                ) { index, instruction in
                    HStack(alignment: .top, spacing: AppSpacing.small) {
                        Text("\(index + 1).")
                            .font(.headline)
                            .foregroundStyle(AppColors.accent)
                            .frame(width: 24, alignment: .leading)

                        Text(instruction)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Pro Tips")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                ForEach(exercise.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: AppSpacing.small) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(tip)
                            .font(.body)
                    }
                }
            }
        }
    }

    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Common Mistakes")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                ForEach(exercise.commonMistakes, id: \.self) { mistake in
                    HStack(alignment: .top, spacing: AppSpacing.small) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(mistake)
                            .font(.body)
                    }
                }
            }
        }
    }

    private var actionButton: some View {
        Button(action: addToWorkout) {
            Label("Add to Workout", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func addToWorkout() {
        // TODO: Integrate with workout planning
        dismiss()
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: ExerciseCategory?
    @Binding var selectedMuscleGroup: MuscleGroup?
    @Binding var selectedEquipment: Equipment?
    @Binding var selectedDifficulty: Difficulty?

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag(nil as ExerciseCategory?)
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category as ExerciseCategory?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Muscle Group") {
                    Picker("Muscle Group", selection: $selectedMuscleGroup) {
                        Text("All Muscle Groups").tag(nil as MuscleGroup?)
                        ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                            Text(muscle.displayName).tag(muscle as MuscleGroup?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Equipment") {
                    Picker("Equipment", selection: $selectedEquipment) {
                        Text("All Equipment").tag(nil as Equipment?)
                        ForEach(Equipment.allCases, id: \.self) { equipment in
                            Text(equipment.displayName).tag(equipment as Equipment?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Difficulty") {
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        Text("All Levels").tag(nil as Difficulty?)
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.displayName).tag(difficulty as Difficulty?)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button("Clear All Filters") {
                        selectedCategory = nil
                        selectedMuscleGroup = nil
                        selectedEquipment = nil
                        selectedDifficulty = nil
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct DifficultyPill: View {
    let difficulty: Difficulty

    var body: some View {
        Text(difficulty.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(difficulty.color.opacity(0.2))
            .foregroundStyle(difficulty.color)
            .clipShape(Capsule())
    }
}

struct CategoryBadge: View {
    let category: ExerciseCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.systemImage)
            Text(category.displayName)
        }
        .font(.caption)
        .foregroundStyle(category.color)
    }
}

struct CompoundBadge: View {
    var body: some View {
        Text("Compound")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppColors.accent.opacity(0.2))
            .foregroundStyle(AppColors.accent)
            .clipShape(Capsule())
    }
}

struct MuscleGroupTags: View {
    let muscleGroups: [MuscleGroup]

    var body: some View {
        HStack {
            ForEach(muscleGroups, id: \.self) { muscle in
                Text(muscle.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.2))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())
            }
        }
    }
}

struct MuscleGroupWrap: View {
    let muscleGroups: [MuscleGroup]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80))],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(muscleGroups, id: \.self) { muscle in
                Text(muscle.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.2))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())
            }
        }
    }
}

struct EquipmentTags: View {
    let equipment: [Equipment]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80))],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(equipment, id: \.self) { item in
                HStack(spacing: 4) {
                    Image(systemName: item.systemImage)
                    Text(item.displayName)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColors.backgroundSecondary)
                .foregroundStyle(.primary)
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Extensions for UI
extension ExerciseCategory {
    var systemImage: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .flexibility: return "figure.flexibility"
        case .plyometrics: return "figure.jumprope"
        case .balance: return "figure.mind.and.body"
        case .sports: return "sportscourt.fill"
        }
    }

    var color: Color {
        switch self {
        case .strength: return .blue
        case .cardio: return .red
        case .flexibility: return .green
        case .plyometrics: return .orange
        case .balance: return .purple
        case .sports: return .cyan
        }
    }
}

extension Difficulty {
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

extension Equipment {
    var systemImage: String {
        switch self {
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .dumbbells: return "dumbbell"
        case .barbell: return "dumbbell.fill"
        case .kettlebells: return "dumbbell"
        case .cables: return "cable.connector"
        case .machine: return "gear"
        case .resistanceBands: return "oval"
        case .foamRoller: return "cylinder"
        case .medicineBall: return "circle.fill"
        case .stabilityBall: return "circle"
        case .other: return "questionmark.circle"
        }
    }
} 