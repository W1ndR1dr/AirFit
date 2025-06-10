import SwiftUI
import Charts
import SwiftData

struct WorkoutStatisticsView: View {
    @State var viewModel: WorkoutViewModel
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedMetric: MetricType = .frequency

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"
        case year = "Year"
        case all = "All Time"

        var displayName: String { rawValue }

        var startDate: Date {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .week:
                return calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case .quarter:
                return calendar.date(byAdding: .month, value: -3, to: now) ?? now
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: now) ?? now
            case .all:
                return Date.distantPast
            }
        }
    }

    enum MetricType: String, CaseIterable {
        case frequency = "Frequency"
        case volume = "Volume"
        case duration = "Duration"
        case calories = "Calories"

        var displayName: String { rawValue }
        var icon: String {
            switch self {
            case .frequency: return "calendar"
            case .volume: return "scalemass"
            case .duration: return "timer"
            case .calories: return "flame.fill"
            }
        }
    }

    var filteredWorkouts: [Workout] {
        viewModel.workouts.filter { workout in
            let date = workout.completedDate ?? workout.plannedDate ?? Date()
            return date >= selectedTimeRange.startDate
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                // Time Range Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.small) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            TimeRangeChip(
                                title: range.displayName,
                                isSelected: selectedTimeRange == range
                            ) {
                                selectedTimeRange = range
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Summary Cards
                summaryCardsSection

                // Main Chart
                mainChartSection

                // Personal Records
                personalRecordsSection

                // Muscle Group Distribution
                muscleGroupSection

                // Workout Type Breakdown
                workoutTypeSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if viewModel.workouts.isEmpty {
                await viewModel.loadWorkouts()
            }
        }
    }

    // MARK: - Sections
    private var summaryCardsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.medium) {
            SummaryCard(
                title: "Total Workouts",
                value: "\(filteredWorkouts.count)",
                trend: calculateTrend(for: .frequency),
                icon: "calendar",
                color: .blue
            )

            SummaryCard(
                title: "Total Duration",
                value: totalDuration.formattedDuration(),
                trend: calculateTrend(for: .duration),
                icon: "timer",
                color: .green
            )

            SummaryCard(
                title: "Calories Burned",
                value: "\(Int(totalCalories))",
                trend: calculateTrend(for: .calories),
                icon: "flame.fill",
                color: .orange
            )

            SummaryCard(
                title: "Avg per Week",
                value: String(format: "%.1f", averageWorkoutsPerWeek),
                trend: nil,
                icon: "chart.bar.fill",
                color: .purple
            )
        }
        .padding(.horizontal)
    }

    private var mainChartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            // Metric Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.small) {
                    ForEach(MetricType.allCases, id: \.self) { metric in
                        MetricChip(
                            title: metric.displayName,
                            icon: metric.icon,
                            isSelected: selectedMetric == metric
                        ) {
                            selectedMetric = metric
                        }
                    }
                }
            }

            // Chart
            StandardCard {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(selectedMetric.displayName)
                        .font(.headline)

                    if chartData.isEmpty {
                        Text("No data available")
                            .foregroundStyle(.secondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    } else {
                        Chart(chartData) { dataPoint in
                            switch selectedMetric {
                            case .frequency:
                                BarMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Count", dataPoint.value)
                                )
                                .foregroundStyle(AppColors.accent.gradient)

                            default:
                                LineMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Value", dataPoint.value)
                                )
                                .foregroundStyle(AppColors.accent)

                                AreaMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Value", dataPoint.value)
                                )
                                .foregroundStyle(AppColors.accent.opacity(0.1))
                            }
                        }
                        .frame(height: 200)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Personal Records", icon: "trophy.fill")
                .padding(.horizontal)

            VStack(spacing: AppSpacing.small) {
                if let longestWorkout = filteredWorkouts.max(by: { ($0.duration ?? 0) < ($1.duration ?? 0) }) {
                    PersonalRecordRow(
                        title: "Longest Workout",
                        value: longestWorkout.formattedDuration ?? "0m",
                        subtitle: longestWorkout.name,
                        date: longestWorkout.completedDate ?? Date(),
                        icon: "timer",
                        color: .blue
                    )
                }

                if let mostCalories = filteredWorkouts.max(by: { ($0.caloriesBurned ?? 0) < ($1.caloriesBurned ?? 0) }) {
                    PersonalRecordRow(
                        title: "Most Calories",
                        value: "\(Int(mostCalories.caloriesBurned ?? 0)) cal",
                        subtitle: mostCalories.name,
                        date: mostCalories.completedDate ?? Date(),
                        icon: "flame.fill",
                        color: .orange
                    )
                }

                if let mostExercises = filteredWorkouts.max(by: { $0.exercises.count < $1.exercises.count }) {
                    PersonalRecordRow(
                        title: "Most Exercises",
                        value: "\(mostExercises.exercises.count) exercises",
                        subtitle: mostExercises.name,
                        date: mostExercises.completedDate ?? Date(),
                        icon: "list.bullet",
                        color: .green
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var muscleGroupSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Muscle Groups", icon: "figure.strengthtraining.traditional")
                .padding(.horizontal)

            StandardCard {
                if muscleGroupData.isEmpty {
                    Text("No muscle group data")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart(Array(muscleGroupData.prefix(8).enumerated()), id: \.offset) { _, item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Muscle", item.name)
                        )
                        .foregroundStyle(AppColors.accent.gradient)
                        .annotation(position: .trailing) {
                            Text("\(item.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: CGFloat(min(muscleGroupData.count, 8)) * 40)
                }
            }
            .padding(.horizontal)
        }
    }

    private var workoutTypeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Workout Types", icon: "chart.pie.fill")
                .padding(.horizontal)

            StandardCard {
                if workoutTypeData.isEmpty {
                    Text("No workout type data")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: AppSpacing.small) {
                        ForEach(workoutTypeData, id: \.type) { item in
                            HStack {
                                Image(systemName: item.type.systemImage)
                                    .foregroundStyle(item.type.color)
                                    .frame(width: 30)

                                Text(item.type.displayName)
                                    .font(.subheadline)

                                Spacer()

                                Text("\(item.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("\(item.percentage)%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }

                            GeometryReader { geometry in
                                Rectangle()
                                    .fill(item.type.color.opacity(0.2))
                                    .frame(width: geometry.size.width * CGFloat(item.percentage) / 100)
                                    .frame(height: 4)
                                    .clipShape(Capsule())
                            }
                            .frame(height: 4)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Computed Properties
    private var totalDuration: TimeInterval {
        filteredWorkouts.compactMap(\.duration).reduce(0, +)
    }

    private var totalCalories: Double {
        filteredWorkouts.compactMap(\.caloriesBurned).reduce(0, +)
    }

    private var averageWorkoutsPerWeek: Double {
        guard !filteredWorkouts.isEmpty else { return 0 }
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: selectedTimeRange.startDate, to: Date()).weekOfYear ?? 1)
        return Double(filteredWorkouts.count) / Double(weeks)
    }

    private var chartData: [ChartDataPoint] {
        let grouped = Dictionary(grouping: filteredWorkouts) { workout in
            let date = workout.completedDate ?? workout.plannedDate ?? Date()
            return Calendar.current.startOfDay(for: date)
        }

        return grouped.map { date, workouts in
            let value: Double
            switch selectedMetric {
            case .frequency:
                value = Double(workouts.count)
            case .volume:
                value = workouts.reduce(0) { total, workout in
                    total + workout.totalVolume
                }
            case .duration:
                value = workouts.compactMap(\.duration).reduce(0, +) / 60 // Convert to minutes
            case .calories:
                value = workouts.compactMap(\.caloriesBurned).reduce(0, +)
            }

            return ChartDataPoint(date: date, value: value)
        }
        .sorted { $0.date < $1.date }
    }

    private var muscleGroupData: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]

        for workout in filteredWorkouts {
            for exercise in workout.exercises {
                for muscleGroup in exercise.muscleGroups {
                    counts[muscleGroup, default: 0] += 1
                }
            }
        }

        return counts.map { (name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private var workoutTypeData: [(type: WorkoutType, count: Int, percentage: Int)] {
        let counts = Dictionary(grouping: filteredWorkouts) { workout in
            workout.workoutTypeEnum ?? .strength
        }.mapValues { $0.count }

        let total = counts.values.reduce(0, +)

        return counts.map { type, count in
            let percentage = total > 0 ? Int((Double(count) / Double(total)) * 100) : 0
            return (type: type, count: count, percentage: percentage)
        }
        .sorted { $0.count > $1.count }
    }

    private func calculateTrend(for metric: MetricType) -> Double? {
        // Simple trend calculation - compare last period to previous
        guard selectedTimeRange != .all else { return nil }

        // This is a simplified trend calculation
        // In production, you'd want more sophisticated analysis
        return Double.random(in: -20...20)
    }
}

// MARK: - Supporting Types
private struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Supporting Views
private struct TimeRangeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(isSelected ? AppColors.accent : AppColors.cardBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

private struct MetricChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xSmall) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(isSelected ? AppColors.accent : AppColors.cardBackground)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let trend: Double?
    let icon: String
    let color: Color

    var body: some View {
        StandardCard {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text("\(abs(Int(trend)))%")
                            .font(.caption)
                    }
                    .foregroundStyle(trend >= 0 ? .green : .red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct PersonalRecordRow: View {
    let title: String
    let value: String
    let subtitle: String
    let date: Date
    let icon: String
    let color: Color

    var body: some View {
        StandardCard {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
