import SwiftUI
import SwiftData

struct AllWorkoutsView: View {
    @State var viewModel: WorkoutViewModel
    @State private var searchText = ""
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var sortOrder: SortOrder = .dateDescending

    enum WorkoutFilter: String, CaseIterable {
        case all = "All"
        case strength = "Strength"
        case cardio = "Cardio"
        case flexibility = "Flexibility"
        case sports = "Sports"

        var displayName: String { rawValue }
    }

    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case duration = "Duration"
        case exercises = "Exercise Count"

        var displayName: String { rawValue }
    }

    var filteredWorkouts: [Workout] {
        let filtered = viewModel.workouts.filter { workout in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                workout.name.localizedCaseInsensitiveContains(searchText) ||
                workout.exercises.contains { $0.name.localizedCaseInsensitiveContains(searchText) }

            // Type filter
            let matchesType = selectedFilter == .all ||
                workout.workoutType == selectedFilter.rawValue.lowercased()

            return matchesSearch && matchesType
        }

        // Sort
        return filtered.sorted(by: { lhs, rhs in
            switch sortOrder {
            case .dateDescending:
                return (lhs.completedDate ?? lhs.plannedDate ?? Date()) >
                    (rhs.completedDate ?? rhs.plannedDate ?? Date())
            case .dateAscending:
                return (lhs.completedDate ?? lhs.plannedDate ?? Date()) <
                    (rhs.completedDate ?? rhs.plannedDate ?? Date())
            case .duration:
                return (lhs.duration ?? 0) > (rhs.duration ?? 0)
            case .exercises:
                return lhs.exercises.count > rhs.exercises.count
            }
        })
    }

    var groupedWorkouts: [(String, [Workout])] {
        let grouped = Dictionary(grouping: filteredWorkouts) { workout in
            let date = workout.completedDate ?? workout.plannedDate ?? Date()
            return date.formatted(.dateTime.month(.wide).year())
        }

        return grouped.sorted { lhs, rhs in
            // Sort sections by date
            guard let lhsDate = lhs.value.first?.completedDate ?? lhs.value.first?.plannedDate,
                  let rhsDate = rhs.value.first?.completedDate ?? rhs.value.first?.plannedDate else {
                return false
            }
            return lhsDate > rhsDate
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Stats Summary
                if !filteredWorkouts.isEmpty {
                    WorkoutHistoryStats(workouts: filteredWorkouts)
                        .padding()
                }

                // Filters
                VStack(spacing: AppSpacing.medium) {
                    // Type Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.small) {
                            ForEach(WorkoutFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter.displayName,
                                    isSelected: selectedFilter == filter
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Sort Options
                    HStack {
                        Text("Sort by:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Menu {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Button(order.displayName) {
                                    sortOrder = order
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(sortOrder.displayName)
                                    .font(.caption)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundStyle(AppColors.accent)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                }

                // Workouts List
                if groupedWorkouts.isEmpty {
                    EmptyStateView(
                        icon: "figure.strengthtraining.traditional",
                        title: "No Workouts Found",
                        message: searchText.isEmpty ? "Start logging workouts to see them here" : "Try adjusting your search or filters"
                    )
                    .padding(.top, 50)
                } else {
                    VStack(spacing: AppSpacing.large) {
                        ForEach(groupedWorkouts, id: \.0) { section, workouts in
                            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                                Text(section)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)

                                VStack(spacing: AppSpacing.small) {
                                    ForEach(workouts) { workout in
                                        NavigationLink(value: WorkoutCoordinator.WorkoutDestination.workoutDetail(workout)) {
                                            WorkoutHistoryRow(workout: workout)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search workouts or exercises")
        .navigationTitle("Workout History")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if viewModel.workouts.isEmpty {
                await viewModel.loadWorkouts()
            }
        }
    }
}

// MARK: - History Stats
private struct WorkoutHistoryStats: View {
    let workouts: [Workout]

    var totalWorkouts: Int { workouts.count }
    var totalDuration: TimeInterval {
        workouts.compactMap(\.duration).reduce(0, +)
    }
    var totalCalories: Double {
        workouts.compactMap(\.caloriesBurned).reduce(0, +)
    }
    var averageDuration: TimeInterval {
        guard totalWorkouts > 0 else { return 0 }
        return totalDuration / Double(totalWorkouts)
    }

    var body: some View {
        Card {
            VStack(spacing: AppSpacing.medium) {
                Text("All Time Stats")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.medium) {
                    StatCard(value: "\(totalWorkouts)", label: "Workouts", icon: "number", color: .blue)
                    StatCard(value: totalDuration.formattedDuration(), label: "Total Time", icon: "timer", color: .green)
                    StatCard(value: "\(Int(totalCalories))", label: "Calories", icon: "flame.fill", color: .orange)
                    StatCard(value: averageDuration.formattedDuration(), label: "Avg Duration", icon: "chart.xyaxis.line", color: .purple)
                }
            }
        }
    }
}

// MARK: - Stat Card
private struct StatCard: View {
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

// MARK: - Filter Chip
private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.xSmall)
                .background(isSelected ? AppColors.accent : AppColors.cardBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - History Row
private struct WorkoutHistoryRow: View {
    let workout: Workout

    private var dateText: String {
        let date = workout.completedDate ?? workout.plannedDate ?? Date()
        return date.formatted(.dateTime.weekday(.wide).day().month())
    }

    private var timeText: String {
        let date = workout.completedDate ?? workout.plannedDate ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name)
                            .font(.headline)

                        HStack {
                            Image(systemName: workout.workoutTypeEnum?.systemImage ?? "figure.strengthtraining.traditional")
                                .foregroundStyle(AppColors.accent)
                                .font(.caption)

                            Text(dateText)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("•")
                                .foregroundStyle(.tertiary)

                            Text(timeText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if workout.aiAnalysis != nil {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AppColors.accent)
                            .font(.caption)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                }

                // Exercise preview
                if !workout.exercises.isEmpty {
                    Text(workout.exercises.prefix(3).map(\.name).joined(separator: ", ") +
                            (workout.exercises.count > 3 ? " +\(workout.exercises.count - 3) more" : ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Stats row
                HStack(spacing: AppSpacing.large) {
                    Label(workout.formattedDuration ?? "0m", systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label("\(workout.totalSets) sets", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let calories = workout.caloriesBurned, calories > 0 {
                        Label("\(Int(calories)) cal", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
