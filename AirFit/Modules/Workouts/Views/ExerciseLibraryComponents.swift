import SwiftUI

// MARK: - Exercise Card
struct ExerciseCard: View {
    let exercise: ExerciseDefinition
    let index: Int
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    private var categoryColors: [Color] {
        switch exercise.category {
        case .strength: return [Color(hex: "#667EEA"), Color(hex: "#764BA2")]
        case .cardio: return [Color(hex: "#F8961E"), Color(hex: "#F3722C")]
        case .flexibility: return [Color(hex: "#52B788"), Color(hex: "#40916C")]
        case .plyometrics: return [Color(hex: "#00B4D8"), Color(hex: "#0077B6")]
        case .balance: return [Color(hex: "#E63946"), Color(hex: "#F1FAEE")]
        case .sports: return [Color(hex: "#A8DADC"), Color(hex: "#457B9D")]
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Exercise Image
                exerciseImage

                // Exercise Info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack {
                        DifficultyPill(difficulty: exercise.difficulty)
                            .environmentObject(gradientManager)
                        Spacer()
                        CategoryBadge(category: exercise.category)
                            .environmentObject(gradientManager)
                    }

                    MuscleGroupTags(muscleGroups: Array(exercise.muscleGroups.prefix(2)))
                        .environmentObject(gradientManager)
                }
                .padding(AppSpacing.sm)
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(MotionToken.microAnimation, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MotionToken.microAnimation) {
                isPressed = pressing
            }
        }, perform: {})
    }

    private var exerciseImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: categoryColors.map { $0.opacity(0.1) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)

            // Gradient glow behind icon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            categoryColors.first?.opacity(0.3) ?? Color.clear,
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 20)

            // Icon
            Image(systemName: exercise.category.systemImage)
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: categoryColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .clipped()
    }
}

// MARK: - Exercise Detail Sheet
struct ExerciseDetailSheet: View {
    @Environment(\.dismiss)
    private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    let exercise: ExerciseDefinition
    @State private var selectedImageIndex = 0
    @State private var animateIn = false

    private var categoryColors: [Color] {
        switch exercise.category {
        case .strength: return [Color(hex: "#667EEA"), Color(hex: "#764BA2")]
        case .cardio: return [Color(hex: "#F8961E"), Color(hex: "#F3722C")]
        case .flexibility: return [Color(hex: "#52B788"), Color(hex: "#40916C")]
        case .plyometrics: return [Color(hex: "#00B4D8"), Color(hex: "#0077B6")]
        case .balance: return [Color(hex: "#E63946"), Color(hex: "#F1FAEE")]
        case .sports: return [Color(hex: "#A8DADC"), Color(hex: "#457B9D")]
        }
    }

    var body: some View {
        NavigationStack {
            BaseScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Title
                        CascadeText(exercise.name)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)

                        // Header
                        exerciseHeader
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                        // Instructions
                        instructionsSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                        // Tips and Mistakes (if available)
                        if !exercise.tips.isEmpty {
                            tipsSection
                                .opacity(animateIn ? 1 : 0)
                                .offset(y: animateIn ? 0 : 20)
                                .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
                        }

                        if !exercise.commonMistakes.isEmpty {
                            mistakesSection
                                .opacity(animateIn ? 1 : 0)
                                .offset(y: animateIn ? 0 : 20)
                                .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)
                        }

                        // Action Button
                        actionButton
                            .padding(.bottom, AppSpacing.xl)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.5), value: animateIn)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
        .presentationDetents([.large])
    }

    private var exerciseHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // Image placeholder
            GlassCard {
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: categoryColors.map { $0.opacity(0.1) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Gradient glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    categoryColors.first?.opacity(0.4) ?? Color.clear,
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)

                    Image(systemName: exercise.category.systemImage)
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: categoryColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(height: 200)
            }
            .padding(.horizontal, AppSpacing.md)

            // Exercise metadata
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    DifficultyPill(difficulty: exercise.difficulty)
                        .environmentObject(gradientManager)
                    CategoryBadge(category: exercise.category)
                        .environmentObject(gradientManager)
                    Spacer()
                    if exercise.isCompound {
                        CompoundBadge()
                            .environmentObject(gradientManager)
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                MuscleGroupWrap(muscleGroups: exercise.muscleGroups)
                    .environmentObject(gradientManager)
                    .padding(.horizontal, AppSpacing.md)

                EquipmentTags(equipment: exercise.equipment)
                    .environmentObject(gradientManager)
                    .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "list.number")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    CascadeText("Instructions")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(
                    Array(exercise.instructions.enumerated()),
                    id: \.offset
                ) { index, instruction in
                    GlassCard {
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Text("\(index + 1)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }

                            Text(instruction)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(AppSpacing.sm)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#F8961E"), Color(hex: "#F3722C")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    CascadeText("Pro Tips")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(Array(exercise.tips.enumerated()), id: \.element) { index, tip in
                    GlassCard {
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "#F8961E"), Color(hex: "#F3722C")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text(tip)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.primary)
                        }
                        .padding(AppSpacing.sm)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }

    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#F94144"), Color(hex: "#F3722C")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    CascadeText("Common Mistakes")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(Array(exercise.commonMistakes.enumerated()), id: \.element) { index, mistake in
                    GlassCard {
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "#F94144"), Color(hex: "#F3722C")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text(mistake)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.primary)
                        }
                        .padding(AppSpacing.sm)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }

    private var actionButton: some View {
        Button {
            HapticService.impact(.medium)
            addToWorkout()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Add to Workout")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                LinearGradient(
                    colors: gradientManager.active.colors(for: colorScheme),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.3), radius: 12, y: 4)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private func addToWorkout() {
        // TODO: Integrate with workout planning
        dismiss()
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    @Environment(\.dismiss)
    private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedCategory: ExerciseCategory?
    @Binding var selectedMuscleGroup: MuscleGroup?
    @Binding var selectedEquipment: Equipment?
    @Binding var selectedDifficulty: Difficulty?
    @State private var animateIn = false

    var body: some View {
        NavigationStack {
            BaseScreen {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        CascadeText("Filters")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)

                        // Category
                        FilterSection(
                            title: "Category",
                            icon: "square.grid.2x2",
                            selection: $selectedCategory,
                            options: ExerciseCategory.allCases,
                            allLabel: "All Categories",
                            index: 0
                        )
                        .environmentObject(gradientManager)

                        // Muscle Group
                        FilterSection(
                            title: "Muscle Group",
                            icon: "figure.strengthtraining.traditional",
                            selection: $selectedMuscleGroup,
                            options: MuscleGroup.allCases,
                            allLabel: "All Muscle Groups",
                            index: 1
                        )
                        .environmentObject(gradientManager)

                        // Equipment
                        FilterSection(
                            title: "Equipment",
                            icon: "dumbbell",
                            selection: $selectedEquipment,
                            options: Equipment.allCases,
                            allLabel: "All Equipment",
                            index: 2
                        )
                        .environmentObject(gradientManager)

                        // Difficulty
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack {
                                HStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: gradientManager.active.colors(for: colorScheme),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("Difficulty")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                                Spacer()
                            }

                            HStack(spacing: AppSpacing.sm) {
                                FilterPill(
                                    text: "All",
                                    isSelected: selectedDifficulty == nil,
                                    color: Color.secondary
                                ) {
                                    HapticService.impact(.light)
                                    selectedDifficulty = nil
                                }

                                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                    FilterPill(
                                        text: difficulty.displayName,
                                        isSelected: selectedDifficulty == difficulty,
                                        color: difficulty.color
                                    ) {
                                        HapticService.impact(.light)
                                        selectedDifficulty = difficulty
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)

                        // Clear button
                        Button {
                            HapticService.impact(.medium)
                            selectedCategory = nil
                            selectedMuscleGroup = nil
                            selectedEquipment = nil
                            selectedDifficulty = nil
                        } label: {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Clear All Filters")
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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

// MARK: - Filter Section
private struct FilterSection<T: Hashable & CaseIterable>: View where T.AllCases: RandomAccessCollection, T: RawRepresentable, T.RawValue == String {
    let title: String
    let icon: String
    @Binding var selection: T?
    let options: T.AllCases
    let allLabel: String
    let index: Int
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text(title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    Spacer()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        FilterPill(
                            text: "All",
                            isSelected: selection == nil,
                            color: Color.secondary
                        ) {
                            HapticService.impact(.light)
                            selection = nil
                        }

                        ForEach(Array(options), id: \.self) { option in
                            if let displayable = option as? any DisplayNameProviding {
                                FilterPill(
                                    text: displayable.displayName,
                                    isSelected: selection == option,
                                    color: gradientManager.active.colors(for: colorScheme).first ?? Color.blue
                                ) {
                                    HapticService.impact(.light)
                                    selection = option
                                }
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .padding(.horizontal, AppSpacing.md)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.1 + Double(index) * 0.1)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Filter Pill
private struct FilterPill: View {
    let text: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .foregroundStyle(isSelected ? Color.white : color)
                .background {
                    if isSelected {
                        color
                    } else {
                        Color.primary.opacity(0.08)
                    }
                }
                .clipShape(Capsule())
                .overlay {
                    if !isSelected {
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    }
                }
        }
    }
}

// Protocol for display name
protocol DisplayNameProviding {
    var displayName: String { get }
}

extension ExerciseCategory: DisplayNameProviding {}
extension MuscleGroup: DisplayNameProviding {}
extension Equipment: DisplayNameProviding {}
extension Difficulty: DisplayNameProviding {}

// MARK: - Supporting Views
struct DifficultyPill: View {
    let difficulty: Difficulty
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(difficulty.displayName)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 4)
            .foregroundStyle(difficulty.color)
            .background {
                Capsule()
                    .fill(difficulty.color.opacity(0.15))
                    .overlay {
                        Capsule()
                            .stroke(difficulty.color.opacity(0.3), lineWidth: 1)
                    }
            }
    }
}

struct CategoryBadge: View {
    let category: ExerciseCategory
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    private var categoryColors: [Color] {
        switch category {
        case .strength: return [Color(hex: "#667EEA"), Color(hex: "#764BA2")]
        case .cardio: return [Color(hex: "#F8961E"), Color(hex: "#F3722C")]
        case .flexibility: return [Color(hex: "#52B788"), Color(hex: "#40916C")]
        case .plyometrics: return [Color(hex: "#00B4D8"), Color(hex: "#0077B6")]
        case .balance: return [Color(hex: "#E63946"), Color(hex: "#F1FAEE")]
        case .sports: return [Color(hex: "#A8DADC"), Color(hex: "#457B9D")]
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.systemImage)
                .font(.system(size: 11, weight: .medium))
            Text(category.displayName)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(
            LinearGradient(
                colors: categoryColors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

struct CompoundBadge: View {
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("Compound")
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 3)
            .foregroundStyle(.white)
            .background {
                LinearGradient(
                    colors: gradientManager.active.colors(for: colorScheme),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .clipShape(Capsule())
            .shadow(color: gradientManager.active.colors(for: colorScheme).first?.opacity(0.3) ?? .clear, radius: 4, y: 2)
    }
}

struct MuscleGroupTags: View {
    let muscleGroups: [MuscleGroup]
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(muscleGroups, id: \.self) { muscle in
                Text(muscle.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, 3)
                    .background(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.1) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(Color.secondary)
                    .clipShape(Capsule())
            }
        }
    }
}

struct MuscleGroupWrap: View {
    let muscleGroups: [MuscleGroup]
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80))],
            alignment: .leading,
            spacing: AppSpacing.xs
        ) {
            ForEach(muscleGroups, id: \.self) { muscle in
                Text(muscle.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.1) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.2) },
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .foregroundStyle(Color.primary.opacity(0.8))
            }
        }
    }
}

struct EquipmentTags: View {
    let equipment: [Equipment]
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 100))],
            alignment: .leading,
            spacing: AppSpacing.xs
        ) {
            ForEach(equipment, id: \.self) { item in
                HStack(spacing: 4) {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(item.displayName)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background {
                    Capsule()
                        .fill(Color.primary.opacity(0.05))
                        .overlay {
                            Capsule()
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        }
                }
                .foregroundStyle(Color.primary)
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
