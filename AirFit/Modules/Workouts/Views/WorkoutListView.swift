import SwiftUI
import SwiftData
import Observation

/// Main list view showing weekly workout summary, recent workouts, and quick actions.
struct WorkoutListView: View {
    // MARK: - State
    @State private var viewModel: WorkoutViewModel
    @State private var coordinator: WorkoutCoordinator
    @State private var searchText = ""
    @State private var hasLoaded = false

    // MARK: - Initializers
    init(viewModel: WorkoutViewModel, coordinator: WorkoutCoordinator = WorkoutCoordinator()) {
        _viewModel = State(initialValue: viewModel)
        _coordinator = State(initialValue: coordinator)
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    WeeklySummaryCard(stats: viewModel.weeklyStats)
                        .padding(.top)

                    quickActionsSection

                    if filteredWorkouts.isEmpty {
                        emptyStateView
                    } else {
                        recentWorkoutsSection
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Workouts")
            .searchable(text: $searchText)
            .refreshable { await viewModel.loadWorkouts() }
            .navigationDestination(for: WorkoutCoordinator.WorkoutDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(item: $coordinator.presentedSheet) { sheet in
                sheetView(for: sheet)
            }
        }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            await viewModel.loadWorkouts()
        }
    }

    // MARK: - Filtered Workouts
    private var filteredWorkouts: [Workout] {
        guard !searchText.isEmpty else { return viewModel.workouts }
        return viewModel.workouts.filter { workout in
            workout.name.localizedCaseInsensitiveContains(searchText) ||
                workout.workoutTypeEnum?.displayName.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    // MARK: - Sections
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Quick Actions", icon: "bolt.fill")
            HStack(spacing: AppSpacing.medium) {
                QuickActionCard(title: "Start Workout", icon: "play.fill", color: .green) {
                    coordinator.showSheet(.templatePicker)
                }
                QuickActionCard(title: "Exercise Library", icon: "books.vertical.fill", color: .blue) {
                    coordinator.navigateTo(.exerciseLibrary)
                }
            }
        }
    }

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(
                title: "Recent Workouts",
                icon: "clock.fill",
                action: { coordinator.navigateTo(.allWorkouts) }
            )
            ForEach(filteredWorkouts.prefix(5)) { workout in
                WorkoutRow(workout: workout) {
                    coordinator.navigateTo(.workoutDetail(workout))
                }
            }
        }
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "figure.strengthtraining.traditional",
            title: "No Workouts",
            message: "Start your first workout to see it here",
            action: { coordinator.showSheet(.templatePicker) },
            actionTitle: "Start Workout"
        )
    }

    // MARK: - Navigation Destinations
    @ViewBuilder
    private func destinationView(for destination: WorkoutCoordinator.WorkoutDestination) -> some View {
        switch destination {
        case .workoutDetail(let workout):
            WorkoutDetailView(workout: workout, viewModel: viewModel)
        case .exerciseLibrary:
            ExerciseLibraryView()
        case .allWorkouts:
            Text("All Workouts")
        case .statistics:
            Text("Statistics")
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: WorkoutCoordinator.WorkoutSheet) -> some View {
        switch sheet {
        case .templatePicker:
            Text("Template Picker")
        case .newTemplate:
            Text("New Template")
        case .exerciseDetail(let exercise):
            Text(exercise.name)
        }
    }
}

// MARK: - Supporting Views
private struct WeeklySummaryCard: View {
    let stats: WeeklyWorkoutStats

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack {
                    Text("This Week")
                        .font(.headline)
                    Spacer()
                    NavigationLink(value: WorkoutCoordinator.WorkoutDestination.statistics) {
                        Text("View Stats")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.accent)
                    }
                }

                HStack(spacing: AppSpacing.large) {
                    StatItem(value: "\(stats.totalWorkouts)", label: "Workouts", icon: "figure.strengthtraining.traditional", color: .blue)
                    StatItem(value: stats.totalDuration.formattedDuration(), label: "Duration", icon: "timer", color: .green)
                    StatItem(value: "\(Int(stats.totalCalories))", label: "Calories", icon: "flame.fill", color: .orange)
                }
            }
        }
    }
}

private struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            HStack(spacing: AppSpacing.xSmall) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.headline)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WorkoutRow: View {
    let workout: Workout
    let action: () -> Void

    private var dateText: String {
        (workout.completedDate ?? workout.plannedDate ?? Date())
            .formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        Button(action: action) {
            Card {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        HStack {
                            Image(systemName: workout.workoutTypeEnum?.systemImage ?? "figure.strengthtraining.traditional")
                                .foregroundStyle(AppColors.accent)
                            Text(workout.workoutTypeEnum?.displayName ?? workout.workoutType)
                                .font(.headline)
                        }
                        Text(dateText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: AppSpacing.medium) {
                            Label(workout.formattedDuration ?? "0m", systemImage: "timer")
                            Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                            if let calories = workout.caloriesBurned, calories > 0 {
                                Label("\(Int(calories)) cal", systemImage: "flame.fill")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xSmall) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.small))
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.small)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.medium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer.preview // swiftlint:disable:this force_try
    let context = container.mainContext
    let user = try! context.fetch(FetchDescriptor<User>()).first! // swiftlint:disable:this force_try
    let vm = WorkoutViewModel(
        modelContext: context,
        user: user,
        coachEngine: PreviewCoachEngine(),
        healthKitManager: PreviewHealthKitManager()
    )
    WorkoutListView(viewModel: vm)
        .modelContainer(container)
}

@MainActor
final class PreviewHealthKitManager: HealthKitManaging {
    var authorizationStatus: HealthKitManager.AuthorizationStatus = .authorized
    func refreshAuthorizationStatus() {}
    func requestAuthorization() async throws {}
    func fetchTodayActivityMetrics() async throws -> ActivityMetrics { ActivityMetrics() }
    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics { HeartHealthMetrics() }
    func fetchLatestBodyMetrics() async throws -> BodyMetrics { BodyMetrics() }
    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? { nil }
}
