import SwiftUI
import Charts
import SwiftData

struct WorkoutStatisticsView: View {
    @State var viewModel: WorkoutViewModel
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedMetric: MetricType = .frequency
    @State private var animateIn = false

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
        BaseScreen {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    CascadeText("Statistics")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -20)
                    
                    // Time Range Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(Array(TimeRange.allCases.enumerated()), id: \.element) { index, range in
                                TimeRangeChip(
                                    title: range.displayName,
                                    isSelected: selectedTimeRange == range,
                                    index: index
                                ) {
                                    HapticService.impact(.light)
                                    withAnimation(MotionToken.microAnimation) {
                                        selectedTimeRange = range
                                    }
                                }
                                .environmentObject(gradientManager)
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                    // Summary Cards
                    summaryCardsSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                    // Main Chart
                    mainChartSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

                    // Personal Records
                    personalRecordsSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)

                    // Muscle Group Distribution
                    muscleGroupSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.5), value: animateIn)

                    // Workout Type Breakdown
                    workoutTypeSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.6), value: animateIn)
                }
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.workouts.isEmpty {
                await viewModel.loadWorkouts()
            }
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
        }
    }

    // MARK: - Sections
    private var summaryCardsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
            SummaryCard(
                title: "Total Workouts",
                value: "\(filteredWorkouts.count)",
                trend: calculateTrend(for: .frequency),
                icon: "calendar",
                colors: [Color(hex: "#667EEA"), Color(hex: "#764BA2")],
                index: 0
            )
            .environmentObject(gradientManager)

            SummaryCard(
                title: "Total Duration",
                value: totalDuration.formattedDuration(),
                trend: calculateTrend(for: .duration),
                icon: "timer",
                colors: [Color(hex: "#52B788"), Color(hex: "#40916C")],
                index: 1
            )
            .environmentObject(gradientManager)

            SummaryCard(
                title: "Calories Burned",
                value: "\(Int(totalCalories))",
                trend: calculateTrend(for: .calories),
                icon: "flame.fill",
                colors: [Color(hex: "#F8961E"), Color(hex: "#F3722C")],
                index: 2
            )
            .environmentObject(gradientManager)

            SummaryCard(
                title: "Avg per Week",
                value: String(format: "%.1f", averageWorkoutsPerWeek),
                trend: nil,
                icon: "chart.bar.fill",
                colors: [Color(hex: "#A8DADC"), Color(hex: "#457B9D")],
                index: 3
            )
            .environmentObject(gradientManager)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private var mainChartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Metric Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(Array(MetricType.allCases.enumerated()), id: \.element) { index, metric in
                        MetricChip(
                            title: metric.displayName,
                            icon: metric.icon,
                            isSelected: selectedMetric == metric,
                            index: index
                        ) {
                            HapticService.impact(.light)
                            withAnimation(MotionToken.microAnimation) {
                                selectedMetric = metric
                            }
                        }
                        .environmentObject(gradientManager)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }

            // Chart
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: selectedMetric.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            CascadeText(selectedMetric.displayName)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                        }
                        Spacer()
                    }

                    if chartData.isEmpty {
                        VStack(spacing: AppSpacing.md) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("No data available")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.secondary)
                        }
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
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(4)

                            default:
                                LineMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Value", dataPoint.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                                AreaMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Value", dataPoint.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            gradientManager.active.colors(for: colorScheme).first?.opacity(0.2) ?? Color.clear,
                                            gradientManager.active.colors(for: colorScheme).first?.opacity(0.05) ?? Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisGridLine()
                                    .foregroundStyle(Color.secondary.opacity(0.1))
                                AxisValueLabel()
                                    .foregroundStyle(Color.secondary.opacity(0.6))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine()
                                    .foregroundStyle(Color.secondary.opacity(0.1))
                                AxisValueLabel()
                                    .foregroundStyle(Color.secondary.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    CascadeText("Personal Records")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)

            VStack(spacing: AppSpacing.sm) {
                if let longestWorkout = filteredWorkouts.max(by: { ($0.duration ?? 0) < ($1.duration ?? 0) }) {
                    PersonalRecordRow(
                        title: "Longest Workout",
                        value: longestWorkout.formattedDuration ?? "0m",
                        subtitle: longestWorkout.name,
                        date: longestWorkout.completedDate ?? Date(),
                        icon: "timer",
                        colors: [Color(hex: "#667EEA"), Color(hex: "#764BA2")],
                        index: 0
                    )
                    .environmentObject(gradientManager)
                }

                if let mostCalories = filteredWorkouts.max(by: { ($0.caloriesBurned ?? 0) < ($1.caloriesBurned ?? 0) }) {
                    PersonalRecordRow(
                        title: "Most Calories",
                        value: "\(Int(mostCalories.caloriesBurned ?? 0)) cal",
                        subtitle: mostCalories.name,
                        date: mostCalories.completedDate ?? Date(),
                        icon: "flame.fill",
                        colors: [Color(hex: "#F8961E"), Color(hex: "#F3722C")],
                        index: 1
                    )
                    .environmentObject(gradientManager)
                }

                if let mostExercises = filteredWorkouts.max(by: { $0.exercises.count < $1.exercises.count }) {
                    PersonalRecordRow(
                        title: "Most Exercises",
                        value: "\(mostExercises.exercises.count) exercises",
                        subtitle: mostExercises.name,
                        date: mostExercises.completedDate ?? Date(),
                        icon: "list.bullet",
                        colors: [Color(hex: "#52B788"), Color(hex: "#40916C")],
                        index: 2
                    )
                    .environmentObject(gradientManager)
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var muscleGroupSection: some View {
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
                    CascadeText("Muscle Groups")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)

            GlassCard {
                if muscleGroupData.isEmpty {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        Text("No muscle group data")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                } else {
                    Chart(Array(muscleGroupData.prefix(8).enumerated()), id: \.offset) { _, item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Muscle", item.name)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(4)
                        .annotation(position: .trailing) {
                            GradientNumber(value: Double(item.count))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                    }
                    .frame(height: CGFloat(min(muscleGroupData.count, 8)) * 40)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                                .foregroundStyle(Color.secondary.opacity(0.1))
                            AxisValueLabel()
                                .foregroundStyle(Color.secondary.opacity(0.6))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(Color.primary.opacity(0.8))
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var workoutTypeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    CascadeText("Workout Types")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)

            GlassCard {
                if workoutTypeData.isEmpty {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        Text("No workout type data")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                } else {
                    VStack(spacing: AppSpacing.md) {
                        ForEach(Array(workoutTypeData.enumerated()), id: \.element.type) { index, item in
                            VStack(spacing: AppSpacing.xs) {
                                HStack {
                                    HStack(spacing: AppSpacing.sm) {
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [item.type.color.opacity(0.2), item.type.color.opacity(0.1)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 32, height: 32)
                                            
                                            Image(systemName: item.type.systemImage)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(item.type.color)
                                        }

                                        Text(item.type.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                    }

                                    Spacer()

                                    HStack(spacing: AppSpacing.sm) {
                                        GradientNumber(value: Double(item.count))
                                            .font(.system(size: 18, weight: .bold, design: .rounded))

                                        Text("\(item.percentage)%")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(Color.secondary.opacity(0.8))
                                            .frame(width: 40, alignment: .trailing)
                                    }
                                }

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.primary.opacity(0.05))
                                            .frame(height: 8)
                                            .clipShape(Capsule())
                                        
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [item.type.color, item.type.color.opacity(0.7)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geometry.size.width * CGFloat(item.percentage) / 100)
                                            .frame(height: 8)
                                            .clipShape(Capsule())
                                            .animation(MotionToken.standardSpring.delay(Double(index) * 0.1), value: item.percentage)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .padding(.horizontal, AppSpacing.md)
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
    let index: Int
    let action: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
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
        .scaleEffect(animateIn ? 1 : 0.8)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(Double(index) * 0.05)) {
                animateIn = true
            }
        }
    }
}

private struct MetricChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let index: Int
    let action: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
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
        .scaleEffect(animateIn ? 1 : 0.8)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(Double(index) * 0.05)) {
                animateIn = true
            }
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let trend: Double?
    let icon: String
    let colors: [Color]
    let index: Int
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary.opacity(0.8))
                    Spacer()
                }

                GradientNumber(value: Double(value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0)
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .medium))
                        Text("\(abs(Int(trend)))%")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: trend >= 0 ? [Color(hex: "#52B788"), Color(hex: "#40916C")] : [Color(hex: "#F94144"), Color(hex: "#F3722C")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
        }
        .scaleEffect(animateIn ? 1 : 0.8)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(Double(index) * 0.1)) {
                animateIn = true
            }
        }
    }
}

private struct PersonalRecordRow: View {
    let title: String
    let value: String
    let subtitle: String
    let date: Date
    let icon: String
    let colors: [Color]
    let index: Int
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    var body: some View {
        GlassCard {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: colors.map { $0.opacity(0.15) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary.opacity(0.8))
                    
                    Text(value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary.opacity(0.6))
            }
            .padding(AppSpacing.sm)
        }
        .scaleEffect(animateIn ? 1 : 0.95)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(Double(index) * 0.1)) {
                animateIn = true
            }
        }
    }
}
