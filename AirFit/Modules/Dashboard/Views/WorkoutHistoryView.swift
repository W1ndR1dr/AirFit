import SwiftUI
import SwiftData
import Charts

/// Detailed workout history view accessible from Today dashboard
struct WorkoutHistoryView: View {
    let user: User
    @State private var viewModel: WorkoutHistoryViewModel
    @State private var animateIn = false

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.dismiss) private var dismiss

    init(
        user: User,
        muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol,
        strengthProgressionService: StrengthProgressionServiceProtocol,
        modelContext: ModelContext
    ) {
        self.user = user
        self._viewModel = State(initialValue: WorkoutHistoryViewModel(
            user: user,
            modelContext: modelContext,
            muscleGroupVolumeService: muscleGroupVolumeService,
            strengthProgressionService: strengthProgressionService
        ))
    }

    var body: some View {
        BaseScreen {
            if viewModel.isLoading {
                VStack {
                    TextLoadingView(message: "Loading workouts")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.md)

                        // Filters
                        VStack(spacing: AppSpacing.md) {
                            timeframePicker
                            muscleGroupPicker
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, AppSpacing.lg)

                        // Content sections
                        DashboardContentView(delay: 0.1) {
                            volumeTrendsSection
                        }
                        .padding(.top, AppSpacing.xl)

                        DashboardContentView(delay: 0.2) {
                            workoutFrequencySection
                        }
                        .padding(.top, AppSpacing.xl)

                        DashboardContentView(delay: 0.3) {
                            recentWorkoutsSection
                        }
                        .padding(.top, AppSpacing.xl)

                        DashboardContentView(delay: 0.4) {
                            personalRecordsSection
                        }
                        .padding(.top, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.xl)
                    }
                }
            }
        }
        .navigationTitle("Workout History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            CascadeText("Workout History")
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.5)

            Text("Track your strength journey")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Timeframe Picker

    @ViewBuilder
    private var timeframePicker: some View {
        HStack(spacing: 0) {
            ForEach(WorkoutHistoryViewModel.TimeframeOption.allCases, id: \.self) { timeframe in
                Button {
                    withAnimation(.bouncy(duration: 0.3)) {
                        viewModel.selectedTimeframe = timeframe
                        HapticService.impact(.light)
                    }
                } label: {
                    Text(timeframe.rawValue)
                        .font(.system(size: 14, weight: viewModel.selectedTimeframe == timeframe ? .semibold : .medium))
                        .foregroundColor(viewModel.selectedTimeframe == timeframe ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedTimeframe == timeframe ?
                                AnyView(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                ) : AnyView(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.primary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var muscleGroupPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(WorkoutHistoryViewModel.MuscleGroup.allCases, id: \.self) { group in
                    muscleGroupButton(for: group)
                }
            }
        }
    }

    @ViewBuilder
    private func muscleGroupButton(for group: WorkoutHistoryViewModel.MuscleGroup) -> some View {
        let isSelected = viewModel.selectedMuscleGroup == group

        Button {
            withAnimation(.bouncy(duration: 0.3)) {
                viewModel.selectedMuscleGroup = group
                HapticService.impact(.light)
            }
        } label: {
            Text(group.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.primary.opacity(0.1)
                        }
                    }
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Volume Trends

    @ViewBuilder
    private var volumeTrendsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "Volume Trends")

            GlassCard {
                VStack(spacing: AppSpacing.lg) {
                    // Volume chart
                    if !viewModel.volumeData.isEmpty {
                        Chart(viewModel.volumeData) { data in
                            AreaMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Volume", data.volume)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            LineMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Volume", data.volume)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        }
                        .frame(height: 200)
                        .chartYAxisLabel("Volume (kg × reps)")
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            }
                        }
                    } else {
                        Text("No workout data available")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    }

                    // Stats
                    HStack(spacing: AppSpacing.xl) {
                        statItem(
                            title: "Total Volume",
                            value: formatVolume(viewModel.totalVolume),
                            subtitle: "kg this period"
                        )
                        statItem(
                            title: "Weekly Avg",
                            value: formatVolume(viewModel.weeklyAverage),
                            subtitle: "kg/week"
                        )
                        statItem(
                            title: "Progress",
                            value: String(format: "%+.1f%%", viewModel.volumeProgress),
                            subtitle: "vs last period",
                            isPositive: viewModel.volumeProgress > 0
                        )
                    }
                }
                .padding(AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    // MARK: - Workout Frequency

    @ViewBuilder
    private var workoutFrequencySection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "Workout Frequency")

            GlassCard {
                VStack(spacing: AppSpacing.lg) {
                    // Frequency bar chart
                    if !viewModel.frequencyData.isEmpty {
                        Chart(viewModel.frequencyData) { data in
                            BarMark(
                                x: .value("Day", data.weekday),
                                y: .value("Count", data.count)
                            )
                            .foregroundStyle(
                                data.isToday ?
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                            )
                            .cornerRadius(4)
                        }
                        .frame(height: 150)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                        .chartYAxisLabel("Workouts")
                    } else {
                        Text("No frequency data available")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                    }

                    // Summary
                    HStack(spacing: AppSpacing.xl) {
                        statItem(
                            title: "This Week",
                            value: "\(viewModel.currentWeekFrequency)",
                            subtitle: "workouts"
                        )

                        let totalWorkouts = viewModel.recentWorkouts.count
                        statItem(
                            title: "Total",
                            value: "\(totalWorkouts)",
                            subtitle: "this period"
                        )

                        let avgFrequency = Double(viewModel.frequencyData.reduce(0) { $0 + $1.count }) / max(Double(viewModel.selectedTimeframe.days) / 7.0, 1)
                        statItem(
                            title: "Avg/Week",
                            value: String(format: "%.1f", avgFrequency),
                            subtitle: "sessions"
                        )
                    }
                }
                .padding(AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    // MARK: - Recent Workouts

    @ViewBuilder
    private var recentWorkoutsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(
                title: "Recent Workouts",
                actionTitle: "See All",
                action: { dismiss() }
            )

            if viewModel.recentWorkouts.isEmpty {
                Text("No workouts recorded yet")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
            } else {
                VStack(spacing: AppSpacing.md) {
                    ForEach(viewModel.recentWorkouts.prefix(3)) { workout in
                        workoutRow(workout: workout)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    @ViewBuilder
    private func workoutRow(workout: Workout) -> some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(workout.name)
                        .font(.system(size: 16, weight: .semibold))

                    if let completedDate = workout.completedDate {
                        Text(completedDate, style: .date)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: AppSpacing.lg) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int((workout.durationSeconds ?? 0) / 60))m")
                            .font(.system(size: 14, weight: .medium))
                        Text("Duration")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(workout.exercises.count)")
                            .font(.system(size: 14, weight: .medium))
                        Text("Exercises")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatVolume(workout.totalVolume))
                            .font(.system(size: 14, weight: .medium))
                        Text("Volume")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Personal Records

    @ViewBuilder
    private var personalRecordsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "Recent PRs")

            if viewModel.recentPRs.isEmpty {
                Text("No personal records yet")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
            } else {
                VStack(spacing: AppSpacing.md) {
                    ForEach(viewModel.recentPRs) { pr in
                        prCard(pr: pr)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    @ViewBuilder
    private func prCard(pr: WorkoutHistoryViewModel.PersonalRecord) -> some View {
        GlassCard {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(pr.exercise)
                        .font(.system(size: 16, weight: .semibold))

                    Text(pr.date, style: .relative)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    Text("\(Int(pr.weight))kg")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    if pr.improvement > 0 {
                        Text(String(format: "+%.1f%%", pr.improvement))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    @ViewBuilder
    private func statItem(title: String, value: String, subtitle: String, isPositive: Bool = false) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(isPositive ? .green : .secondary)
        }
    }

    // MARK: - Helper Functions

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000 {
            return String(format: "%.1fk", volume / 1_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
}
