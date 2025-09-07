import SwiftUI
import SwiftData
import Charts

/// Enhanced Workout Dashboard - Comprehensive workout tracking with AI insights
struct WorkoutDashboardView: View {
    let user: User
    @State private var viewModel: WorkoutViewModel?
    @Environment(\.diContainer) private var container
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    @State private var coordinator = WorkoutCoordinator()
    @State private var hasAppeared = false
    @State private var selectedTimeframe: WorkoutTimeframe = .week
    @State private var animateIn = false
    @State private var isInitializing = true

    enum WorkoutTimeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"

        var displayName: String { rawValue }
    }

    var body: some View {
        BaseScreen {
            NavigationStack(path: $coordinator.navigationPath) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header is always visible
                        workoutHeaderImmediate()
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)
                            .animation(MotionToken.standardSpring, value: animateIn)

                        // Quick actions - always visible
                        quickWorkoutActions
                            .padding(.top, AppSpacing.lg)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)
                            .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                        if let viewModel = viewModel {
                            // Real content when loaded
                            VStack(spacing: AppSpacing.xl) {
                                todaysWorkoutSection(viewModel)
                                    .padding(.top, AppSpacing.xl)
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                                weeklyMuscleVolumeSection(viewModel)
                                    .padding(.top, AppSpacing.xl)
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

                                achievementsSection(viewModel)
                                    .padding(.top, AppSpacing.xl)
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)

                                weeklyStatsCard(viewModel)
                                    .padding(.horizontal, AppSpacing.screenPadding)
                                    .padding(.top, AppSpacing.xl)
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(MotionToken.standardSpring.delay(0.5), value: animateIn)

                                recentWorkoutsSection(viewModel)
                                    .padding(.top, AppSpacing.xl)
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(MotionToken.standardSpring.delay(0.6), value: animateIn)
                            }
                        } else if isInitializing {
                            // Skeleton content while loading
                            workoutSkeletonContent()
                        }
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
                .scrollContentBackground(.hidden)
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    if let viewModel = viewModel {
                        await viewModel.loadWorkouts()
                    }
                }
                .navigationDestination(for: WorkoutCoordinator.WorkoutDestination.self) { destination in
                    if let viewModel = viewModel {
                        destinationView(for: destination, viewModel: viewModel)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            HapticService.impact(.light)
                            coordinator.showSheet(.voiceWorkoutInput)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                        }
                        .accessibilityLabel("Create Workout Plan")
                        .disabled(viewModel == nil)
                        .opacity(viewModel == nil ? 0.5 : 1)
                    }
                }
            }
        }
        .task {
            guard viewModel == nil else { return }
            isInitializing = true
            let factory = DIViewModelFactory(container: container)
            viewModel = try? await factory.makeWorkoutViewModel(user: user)
            isInitializing = false
            
            if !hasAppeared {
                hasAppeared = true
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
        .onAppear {
            // Tab update logic would go here if needed
        }
        .accessibilityIdentifier("workout.dashboard")
    }


    // MARK: - Header

    @ViewBuilder
    private func workoutHeaderImmediate() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            CascadeText("Workouts")
                .font(.system(size: 34, weight: .thin, design: .rounded))

            Text(workoutLoadingMessage())
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func workoutLoadingMessage() -> String {
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        switch dayOfWeek {
        case 1: // Sunday
            return "Loading your rest day overview..."
        case 2: // Monday
            return "Loading your week's training plan..."
        case 6: // Friday
            return "Loading your week's progress..."
        case 7: // Saturday
            return "Loading your weekend workout..."
        default:
            return "Loading your training data..."
        }
    }

    @ViewBuilder
    private func workoutHeader(_ viewModel: WorkoutViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            CascadeText("Workouts")
                .font(.system(size: 34, weight: .thin, design: .rounded))

            // AI-powered workout insight
            if let aiInsight = generateWorkoutInsight(from: viewModel) {
                Text(aiInsight)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickWorkoutActions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Quick Start")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, AppSpacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    QuickWorkoutCard(
                        title: "AI Workout",
                        subtitle: "Personalized plan",
                        systemImage: "brain",
                        color: .purple,
                        index: 0
                    ) {
                        coordinator.showSheet(.voiceWorkoutInput)
                    }

                    QuickWorkoutCard(
                        title: "Strength",
                        subtitle: "Build muscle",
                        systemImage: "dumbbell.fill",
                        color: .blue,
                        index: 1
                    ) {
                        startQuickWorkout(.strength)
                    }

                    QuickWorkoutCard(
                        title: "Cardio",
                        subtitle: "Boost endurance",
                        systemImage: "figure.run",
                        color: .orange,
                        index: 2
                    ) {
                        startQuickWorkout(.cardio)
                    }

                    QuickWorkoutCard(
                        title: "HIIT",
                        subtitle: "High intensity",
                        systemImage: "flame.fill",
                        color: .red,
                        index: 3
                    ) {
                        startQuickWorkout(.hiit)
                    }

                    QuickWorkoutCard(
                        title: "Yoga",
                        subtitle: "Flexibility",
                        systemImage: "figure.yoga",
                        color: .indigo,
                        index: 4
                    ) {
                        startQuickWorkout(.yoga)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    // MARK: - Today's Workout

    @ViewBuilder
    private func todaysWorkoutSection(_ viewModel: WorkoutViewModel) -> some View {
        let todaysWorkout = viewModel.workouts.first { workout in
            Calendar.current.isDateInToday(workout.plannedDate ?? workout.completedDate ?? .distantPast)
        }

        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Today's Plan")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, AppSpacing.screenPadding)

            if let workout = todaysWorkout {
                TodaysWorkoutCard(workout: workout) {
                    coordinator.navigateTo(.workoutDetail(workout))
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            } else {
                emptyTodayState
                    .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    private var emptyTodayState: some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))

                Text("No workout scheduled")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)

                Text("Let's create your perfect workout for today")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticService.impact(.light)
                    coordinator.showSheet(.voiceWorkoutInput)
                } label: {
                    Text("Create Workout")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(gradientManager.currentGradient(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, AppSpacing.sm)
            }
            .padding(AppSpacing.lg)
        }
    }

    // MARK: - Weekly Muscle Volume

    @ViewBuilder
    private func weeklyMuscleVolumeSection(_ viewModel: WorkoutViewModel) -> some View {
        let muscleVolumes = calculateMuscleVolumes(from: viewModel)

        if !muscleVolumes.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Text("Weekly Volume")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("by muscle group")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, AppSpacing.screenPadding)

                GlassCard {
                    MuscleVolumeView(volumes: muscleVolumes)
                        .padding(AppSpacing.md)
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    // MARK: - Achievements

    @ViewBuilder
    private func achievementsSection(_ viewModel: WorkoutViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Recent Achievements")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, AppSpacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    // Placeholder achievements - would be calculated from workout data
                    AchievementCard(
                        icon: "trophy.fill",
                        title: "Consistency",
                        subtitle: "5 workouts this week",
                        color: .yellow,
                        index: 0
                    )

                    AchievementCard(
                        icon: "flame.fill",
                        title: "Calorie Crusher",
                        subtitle: "2,500 cal burned",
                        color: .orange,
                        index: 1
                    )

                    AchievementCard(
                        icon: "bolt.fill",
                        title: "PR Week",
                        subtitle: "3 new records",
                        color: .blue,
                        index: 2
                    )
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    // MARK: - Weekly Stats

    @ViewBuilder
    private func weeklyStatsCard(_ viewModel: WorkoutViewModel) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Text("This Week's Stats")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    NavigationLink(value: WorkoutCoordinator.WorkoutDestination.statistics) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    }
                }

                HStack(spacing: AppSpacing.lg) {
                    WeeklyStatItem(
                        value: "\(viewModel.weeklyStats.totalWorkouts)",
                        label: "Workouts",
                        icon: "figure.strengthtraining.traditional",
                        color: .blue
                    )

                    WeeklyStatItem(
                        value: viewModel.weeklyStats.totalDuration.formattedDuration(),
                        label: "Duration",
                        icon: "timer",
                        color: .green
                    )

                    WeeklyStatItem(
                        value: "\(Int(viewModel.weeklyStats.totalCalories))",
                        label: "Calories",
                        icon: "flame.fill",
                        color: .orange
                    )

                    WeeklyStatItem(
                        value: "\(viewModel.weeklyStats.muscleGroupDistribution.count)",
                        label: "Muscle Groups",
                        icon: "figure.arms.open",
                        color: .purple
                    )
                }
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Recent Workouts

    @ViewBuilder
    private func recentWorkoutsSection(_ viewModel: WorkoutViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Recent Workouts")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                NavigationLink(value: WorkoutCoordinator.WorkoutDestination.allWorkouts) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)

            if viewModel.workouts.isEmpty {
                emptyWorkoutsState
                    .padding(.horizontal, AppSpacing.screenPadding)
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(Array(viewModel.workouts.prefix(5).enumerated()), id: \.element.id) { index, workout in
                        WorkoutDashboardRow(workout: workout, index: index) {
                            coordinator.navigateTo(.workoutDetail(workout))
                        }
                        .environmentObject(gradientManager)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    private var emptyWorkoutsState: some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("Start your fitness journey")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.lg)
        }
    }

    // MARK: - Skeleton Content

    @ViewBuilder
    private func workoutSkeletonContent() -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Today's workout skeleton
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 150, height: 20)
                    .shimmering()
                
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 200, height: 24)
                            .shimmering()
                        
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 80, height: 16)
                                    .shimmering()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.top, AppSpacing.xl)
            
            // Muscle volume skeleton
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 180, height: 20)
                    .shimmering()
                
                // Muscle group bars
                VStack(spacing: AppSpacing.sm) {
                    ForEach(0..<5, id: \.self) { _ in
                        HStack(spacing: AppSpacing.md) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 60, height: 16)
                                .shimmering()
                            
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: geometry.size.width * Double.random(in: 0.3...0.8), height: 8)
                                    .shimmering()
                            }
                            .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 40, height: 16)
                                .shimmering()
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            // Stats card skeleton
            GlassCard {
                VStack(spacing: AppSpacing.lg) {
                    HStack(spacing: AppSpacing.xl) {
                        ForEach(0..<3, id: \.self) { _ in
                            VStack(spacing: AppSpacing.xs) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 50, height: 30)
                                    .shimmering()
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 70, height: 12)
                                    .shimmering()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            // Recent workouts skeleton
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 140, height: 20)
                    .shimmering()
                
                VStack(spacing: AppSpacing.sm) {
                    ForEach(0..<2, id: \.self) { _ in
                        GlassCard {
                            HStack(spacing: AppSpacing.md) {
                                Circle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .shimmering()
                                
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 120, height: 16)
                                        .shimmering()
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 80, height: 12)
                                        .shimmering()
                                }
                                
                                Spacer()
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 50, height: 16)
                                    .shimmering()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)
    }
    
    // MARK: - Helper Methods

    private func generateWorkoutInsight(from viewModel: WorkoutViewModel) -> String? {
        let hour = Calendar.current.component(.hour, from: Date())
        let stats = viewModel.weeklyStats

        switch hour {
        case 6..<12:
            if stats.totalWorkouts == 0 {
                return "Ready to start strong this week? Morning workouts boost energy all day."
            }
            return "Morning warrior. Keep that consistency going."

        case 12..<17:
            if stats.totalWorkouts < 3 {
                return "Perfect time for a quick workout. Even 20 minutes makes a difference."
            }
            return "You're crushing it this week with \(stats.totalWorkouts) workouts."

        case 17..<22:
            if let lastWorkout = viewModel.workouts.first {
                let daysSince = Calendar.current.dateComponents([.day], from: lastWorkout.completedDate ?? Date(), to: Date()).day ?? 0
                if daysSince >= 3 {
                    return "It's been \(daysSince) days since your last workout. Ready to get back?"
                }
            }
            return "Evening sessions help you unwind. What's on tap tonight?"

        default:
            return "Rest and recovery build strength. Tomorrow's another opportunity."
        }
    }

    private func calculateMuscleVolumes(from viewModel: WorkoutViewModel) -> [MuscleGroupVolume] {
        let distribution = viewModel.weeklyStats.muscleGroupDistribution

        // Define target sets per muscle group per week
        let targets: [String: Int] = [
            "Chest": 16,
            "Back": 16,
            "Shoulders": 12,
            "Arms": 12,
            "Legs": 16,
            "Core": 8
        ]

        return targets.compactMap { muscle, target in
            let sets = distribution[muscle] ?? 0
            return MuscleGroupVolume(
                name: muscle,
                sets: sets,
                target: target,
                color: muscleGroupColor(muscle)
            )
        }.sorted { $0.sets > $1.sets }
    }

    private func muscleGroupColor(_ muscle: String) -> String {
        switch muscle {
        case "Chest": return "blue"
        case "Back": return "green"
        case "Shoulders": return "orange"
        case "Arms": return "purple"
        case "Legs": return "red"
        case "Core": return "indigo"
        default: return "gray"
        }
    }

    private func startQuickWorkout(_ type: WorkoutType) {
        // Deprecated: in-app workout logging removed
    }

    @ViewBuilder
    private func destinationView(for destination: WorkoutCoordinator.WorkoutDestination, viewModel: WorkoutViewModel) -> some View {
        switch destination {
        case .workoutDetail(let workout):
            WorkoutDetailView(workout: workout, viewModel: viewModel)
        case .allWorkouts:
            Text("All Workouts")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .statistics:
            Text("Workout Statistics")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: WorkoutCoordinator.WorkoutSheet) -> some View {
        switch sheet {
        case .voiceWorkoutInput:
            VoiceWorkoutInputPlaceholder(coordinator: coordinator)
                .environmentObject(gradientManager)
        }
    }
}

// MARK: - Supporting Views

struct TodaysWorkoutCard: View {
    let workout: Workout
    let onTap: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.diContainer) private var container
    @State private var showingSendOptions = false

    var body: some View {
        Button(action: onTap) {
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(workout.name)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.primary)

                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: workout.workoutTypeEnum?.systemImage ?? "figure.strengthtraining.traditional")
                                    .font(.system(size: 14))
                                Text(workout.workoutTypeEnum?.displayName ?? "Workout")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if workout.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.green)
                        } else if workout.workoutTypeEnum == .strength {
                            HStack(spacing: AppSpacing.sm) {
                                Button {
                                    HapticService.impact(.light)
                                    showingSendOptions = true
                                } label: {
                                    Image(systemName: "applewatch.radiowaves.left.and.right")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(AppSpacing.xs)
                                        .background(gradientManager.currentGradient(for: colorScheme))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                
                                Text("Start")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(gradientManager.currentGradient(for: colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        } else {
                            Text("Start")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.xs)
                                .background(gradientManager.currentGradient(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    if !workout.isCompleted {
                        HStack(spacing: AppSpacing.lg) {
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 12))
                                Text("\(workout.exercises.count) exercises")
                                    .font(.system(size: 14, weight: .medium))
                            }

                            if let duration = workout.formattedDuration {
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.system(size: 12))
                                    Text(duration)
                                        .font(.system(size: 14, weight: .medium))
                                }
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(AppSpacing.md)
            }
        }
        .buttonStyle(.plain)
    }
}

struct QuickWorkoutCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let index: Int
    let action: () -> Void
    @State private var animateIn = false

    var body: some View {
        Button(action: {
            HapticService.impact(.medium)
            action()
        }) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 28))
                    .foregroundStyle(color)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .opacity(animateIn ? 1 : 0)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(.secondary)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 10)
            }
            .frame(width: 100, height: 100)
            .glassEffect(in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(Double(index) * 0.05)) {
                animateIn = true
            }
        }
    }
}

struct WeeklyStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
            }

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let index: Int
    @State private var animateIn = false

    var body: some View {
        GlassCard {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .opacity(animateIn ? 1 : 0)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(.secondary)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 10)
            }
            .padding(AppSpacing.md)
            .frame(width: 140)
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(Double(index) * 0.1)) {
                animateIn = true
            }
        }
    }
}

struct WorkoutDashboardRow: View {
    let workout: Workout
    let index: Int
    let action: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.diContainer) private var container
    @State private var animateIn = false
    @State private var showingSendToWatch = false

    private var dateText: String {
        let date = workout.completedDate ?? workout.plannedDate ?? Date()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    var body: some View {
        Button(action: action) {
            GlassCard {
                HStack {
                    // Workout type indicator
                    Circle()
                        .fill(workout.workoutTypeEnum?.color ?? .gray)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: workout.workoutTypeEnum?.systemImage ?? "figure.strengthtraining.traditional")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(workout.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(spacing: AppSpacing.md) {
                            Text(dateText)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)

                            if let duration = workout.formattedDuration {
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.system(size: 11))
                                    Text(duration)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(.secondary.opacity(0.8))
                            }

                            if let calories = workout.caloriesBurned, calories > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 11))
                                    Text("\(Int(calories)) cal")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(Color.orange.opacity(0.8))
                            }
                        }
                    }

                    Spacer()
                    
                    // Send to Watch button for strength workouts that aren't completed
                    if workout.workoutTypeEnum == .strength && !workout.isCompleted {
                        Button {
                            HapticService.impact(.light)
                            showingSendToWatch = true
                        } label: {
                            Image(systemName: "applewatch.radiowaves.left.and.right")
                                .font(.system(size: 18))
                                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, AppSpacing.xs)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .padding(AppSpacing.md)
            }
        }
        .buttonStyle(.plain)
        .opacity(animateIn ? 1 : 0)
        .offset(x: animateIn ? 0 : -20)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(Double(index) * 0.05)) {
                animateIn = true
            }
        }
        .alert("Send to Apple Watch", isPresented: $showingSendToWatch) {
            Button("Send") {
                Task {
                    await sendWorkoutToWatch()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Send \"\(workout.name)\" to your Apple Watch?")
        }
    }
    
    private func sendWorkoutToWatch() async {
        do {
            let transferService = try? await container.resolve(WorkoutPlanTransferProtocol.self)
            
            guard let transferService = transferService else {
                AppLogger.warning("Watch transfer service not available", category: .services)
                return
            }
            
            // Convert workout to planned workout data
            let plannedWorkout = PlannedWorkoutData.from(
                workout: workout,
                userId: workout.user?.id ?? UUID()
            )
            
            // Send to watch
            try await transferService.sendWorkoutPlan(plannedWorkout)
            
            HapticService.notification(.success)
        } catch {
            AppLogger.error("Failed to send workout to watch", error: error, category: .services)
            HapticService.notification(.error)
        }
    }
}

// MARK: - Extensions

extension TimeInterval {
    func formattedDuration() -> String {
        let hours = Int(self) / 3_600
        let minutes = (Int(self) % 3_600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

#Preview {
    let container = ModelContainer.preview
    let user = User(name: "Preview")
    
    WorkoutDashboardView(user: user)
        .withDIContainer(DIContainer())
        .modelContainer(container)
}
