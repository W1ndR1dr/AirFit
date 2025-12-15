import SwiftUI

struct DashboardView: View {
    @State private var selectedSegment: DashboardSegment = .body
    @State private var weekContext: APIClient.ContextSummary?
    @State private var expandedMetric: MetricType?
    @State private var scrollTarget: String?
    @State private var showWorkoutSheet = false
    @State private var recentWorkouts: [APIClient.WorkoutSummary] = []

    // Weekly history data for sparklines
    @State private var weeklyWeightData: [Double] = []
    @State private var weeklyProteinData: [Double] = []
    @State private var weeklyCaloriesData: [Double] = []
    @State private var weeklySleepData: [Double] = []
    @State private var weeklyWorkoutData: [Double] = []  // 1 = workout day, 0 = rest

    private let apiClient = APIClient()
    private let healthKit = HealthKitManager()

    enum DashboardSegment: String, CaseIterable {
        case body = "Body"
        case training = "Training"
    }

    var body: some View {
        ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // This Week summary
                        if let ctx = weekContext {
                            thisWeekCard(ctx)
                                .padding(.horizontal, 20)
                        }

                        // Segmented picker
                        Picker("", selection: $selectedSegment) {
                            ForEach(DashboardSegment.allCases, id: \.self) { segment in
                                Text(segment.rawValue).tag(segment)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)

                        // Content based on selection
                        Group {
                            switch selectedSegment {
                            case .body:
                                BodyContentView()
                                    .id("bodySection")
                            case .training:
                                TrainingContentView()
                                    .id("trainingSection")
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
                .onChange(of: scrollTarget) { _, target in
                    guard let target else { return }
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        proxy.scrollTo(target, anchor: .top)
                    }
                    scrollTarget = nil
                }
            }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .animation(.airfit, value: selectedSegment)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: expandedMetric)
        .task {
            await loadWeekContext()
            await loadWeeklyHistory()
            await loadRecentWorkouts()
        }
        .sheet(isPresented: $showWorkoutSheet) {
            WorkoutDetailSheet(workouts: recentWorkouts)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func loadWeekContext() async {
        do {
            weekContext = try await apiClient.getInsightsContext(range: "week")
        } catch {
            print("Failed to load week context: \(error)")
        }
    }

    private func loadWeeklyHistory() async {
        // Load weight history from HealthKit
        let weights = await healthKit.getWeightHistory(days: 7)
        await MainActor.run {
            weeklyWeightData = aggregateToDailyValues(weights.map { ($0.date, $0.weightLbs) })
        }

        // Load sleep history from HealthKit
        let sleepValues = await loadSleepHistory()
        await MainActor.run {
            weeklySleepData = sleepValues
        }

        // Nutrition: show flat average for now (no fake variance)
        // TODO: Load actual daily nutrition from SwiftData when available
        if let ctx = weekContext {
            await MainActor.run {
                // Show flat average - no fake variance data
                let proteinAvg = Double(ctx.avg_protein)
                let caloriesAvg = Double(ctx.avg_calories)
                weeklyProteinData = Array(repeating: proteinAvg, count: 7)
                weeklyCaloriesData = Array(repeating: caloriesAvg, count: 7)

                // Workouts: show flat count for now
                // TODO: Get actual workout days from Hevy data
                let workoutCount = Double(ctx.total_workouts)
                weeklyWorkoutData = Array(repeating: workoutCount / 7.0, count: 7)
            }
        }
    }

    /// Load 7 days of sleep data from HealthKit
    private func loadSleepHistory() async -> [Double] {
        var sleepValues: [Double] = []
        let calendar = Calendar.current

        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let snapshot = await healthKit.getDailySnapshot(for: date)
                sleepValues.append(snapshot.sleepHours ?? 0)
            }
        }
        return sleepValues
    }

    /// Aggregate readings to single daily values (most recent per day)
    private func aggregateToDailyValues(_ readings: [(Date, Double)]) -> [Double] {
        let calendar = Calendar.current
        var dailyValues: [Double] = Array(repeating: 0, count: 7)

        for (date, value) in readings {
            let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            if daysAgo >= 0 && daysAgo < 7 {
                let index = 6 - daysAgo  // 0 = 6 days ago, 6 = today
                dailyValues[index] = value
            }
        }

        return dailyValues
    }

    private func loadRecentWorkouts() async {
        do {
            recentWorkouts = try await apiClient.getRecentWorkouts(limit: 10)
        } catch {
            print("Failed to load recent workouts: \(error)")
        }
    }

    private func scrollToSection(_ id: String) {
        if id == "bodySection" {
            selectedSegment = .body
        } else if id == "trainingSection" {
            selectedSegment = .training
        }
        scrollTarget = id
    }

    private func toggleExpanded(_ metric: MetricType) {
        if expandedMetric == metric {
            expandedMetric = nil
        } else {
            expandedMetric = metric
        }
    }

    // MARK: - This Week Card

    private func thisWeekCard(_ ctx: APIClient.ContextSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("THIS WEEK")
                .font(.labelHero)
                .tracking(2)
                .foregroundStyle(Theme.textMuted)
                .padding(.bottom, 8)

            // Protein row - expands inline (target: 175g)
            MetricRow(
                label: "Protein",
                value: "\(ctx.avg_protein)",
                unit: "g avg",
                sparklineData: weeklyProteinData,
                color: Theme.protein,
                sparklineStyle: .goalBars(target: 175),
                isExpanded: expandedMetric == .protein
            ) {
                toggleExpanded(.protein)
            }

            if expandedMetric == .protein {
                NutritionDetailView(
                    label: "Protein",
                    dailyValues: weeklyProteinData,
                    target: 175,
                    unit: "g",
                    color: Theme.protein
                )
                .padding(.leading, 4)
                .padding(.trailing, 4)
                .padding(.bottom, 8)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                ))
            }

            Divider().padding(.leading, 70)

            // Calories row - expands inline (target: 2600 training / 2200 rest)
            MetricRow(
                label: "Calories",
                value: "\(ctx.avg_calories)",
                unit: "avg",
                sparklineData: weeklyCaloriesData,
                color: Theme.calories,
                sparklineStyle: .goalBars(target: 2600),
                isExpanded: expandedMetric == .calories
            ) {
                toggleExpanded(.calories)
            }

            if expandedMetric == .calories {
                NutritionDetailView(
                    label: "Calories",
                    dailyValues: weeklyCaloriesData,
                    target: 2600,
                    unit: "",
                    color: Theme.calories
                )
                .padding(.leading, 4)
                .padding(.trailing, 4)
                .padding(.bottom, 8)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                ))
            }

            Divider().padding(.leading, 70)

            // Sleep row - expands inline (target: 7.5 hours)
            if let sleep = ctx.avg_sleep {
                MetricRow(
                    label: "Sleep",
                    value: String(format: "%.1f", sleep),
                    unit: "hrs",
                    sparklineData: weeklySleepData,
                    color: Color.indigo,
                    sparklineStyle: .goalBars(target: 7.5),
                    isExpanded: expandedMetric == .sleep
                ) {
                    toggleExpanded(.sleep)
                }

                if expandedMetric == .sleep {
                    SleepDetailView(dailyValues: weeklySleepData)
                        .padding(.leading, 4)
                        .padding(.trailing, 4)
                        .padding(.bottom, 8)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                        ))
                }

                Divider().padding(.leading, 70)
            }

            // Workouts row - taps to show workout detail sheet
            if ctx.total_workouts > 0 {
                MetricRow(
                    label: "Workouts",
                    value: "\(ctx.total_workouts)",
                    unit: "",
                    sparklineData: weeklyWorkoutData,
                    color: Theme.secondary,
                    sparklineStyle: .bars,
                    isExpanded: false
                ) {
                    showWorkoutSheet = true
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    private func trendBadge(change: Double, label: String, inverted: Bool) -> some View {
        let isPositive = inverted ? change < 0 : change > 0
        let color = isPositive ? Theme.success : Theme.warning

        return HStack(spacing: 4) {
            Image(systemName: change < 0 ? "arrow.down" : "arrow.up")
                .font(.caption2)
            Text(String(format: "%.1f lbs %@", abs(change), label))
                .font(.labelMicro)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }
}

// MARK: - Body Content (fetches directly from HealthKit)

struct BodyContentView: View {
    @State private var timeRange: ChartTimeRange = .year
    @State private var weightData: [ChartDataPoint] = []
    @State private var bodyFatData: [ChartDataPoint] = []
    @State private var leanMassData: [ChartDataPoint] = []
    @State private var isLoading = true

    private let healthKit = HealthKitManager()

    // Current values (most recent)
    private var currentWeight: Double? { weightData.last?.value }
    private var currentBodyFat: Double? { bodyFatData.last?.value }
    private var currentLeanMass: Double? {
        if let lm = leanMassData.last?.value { return lm }
        // Calculate from weight and body fat if lean mass not directly available
        if let w = currentWeight, let bf = currentBodyFat {
            return w * (1 - bf / 100)
        }
        return nil
    }

    // Trends (change over visible range)
    private var weightTrend: Double? {
        guard weightData.count >= 2 else { return nil }
        return weightData.last!.value - weightData.first!.value
    }

    private var bodyFatTrend: Double? {
        guard bodyFatData.count >= 2 else { return nil }
        return bodyFatData.last!.value - bodyFatData.first!.value
    }

    private var leanMassTrend: Double? {
        guard leanMassData.count >= 2 else { return nil }
        return leanMassData.last!.value - leanMassData.first!.value
    }

    var body: some View {
        Group {
            if isLoading && weightData.isEmpty {
                loadingView
            } else if weightData.isEmpty && bodyFatData.isEmpty {
                emptyState
            } else {
                bodyContent
            }
        }
        .task {
            await loadData()
        }
        .onChange(of: timeRange) { _, _ in
            Task { await loadData() }
        }
    }

    private var bodyContent: some View {
        VStack(spacing: 20) {
            // Time range picker
            ChartTimeRangePicker(selection: $timeRange)
                .padding(.horizontal, 20)

            // Current metrics hero
            currentMetricsCard

            // Weight chart
            if !weightData.isEmpty {
                chartCard(
                    title: "WEIGHT",
                    icon: "scalemass.fill",
                    color: Theme.accent,
                    data: weightData,
                    unit: "lbs",
                    trend: weightTrend,
                    trendInverted: true
                )
            }

            // Body fat chart
            if !bodyFatData.isEmpty {
                chartCard(
                    title: "BODY FAT",
                    icon: "percent",
                    color: Theme.warning,
                    data: bodyFatData,
                    unit: "%",
                    trend: bodyFatTrend,
                    trendInverted: true,
                    formatValue: { String(format: "%.1f%%", $0) }
                )
            }

            // Lean mass chart
            if !leanMassData.isEmpty {
                chartCard(
                    title: "LEAN MASS",
                    icon: "figure.strengthtraining.traditional",
                    color: Theme.success,
                    data: leanMassData,
                    unit: "lbs",
                    trend: leanMassTrend,
                    trendInverted: false
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .animation(.airfit, value: timeRange)
    }

    // MARK: - Current Metrics Card

    private var currentMetricsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "figure.stand")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                Text("CURRENT")
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(Theme.textMuted)

                Spacer()

                Text(timeRange.label.uppercased())
                    .font(.labelMicro)
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Theme.accent.opacity(0.12))
                    )
            }

            HStack(spacing: 0) {
                metricTile(
                    value: currentWeight.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "lbs",
                    label: "Weight",
                    color: Theme.accent
                )
                metricTile(
                    value: currentBodyFat.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "%",
                    label: "Body Fat",
                    color: Theme.warning
                )
                metricTile(
                    value: currentLeanMass.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "lbs",
                    label: "Lean",
                    color: Theme.success
                )
            }

            // Trend summary
            if let wt = weightTrend {
                HStack(spacing: 12) {
                    trendBadge(value: wt, label: "weight", inverted: true)

                    if let bf = bodyFatTrend {
                        trendBadge(value: bf, label: "body fat", inverted: true, suffix: "%")
                    }

                    if let lm = leanMassTrend {
                        trendBadge(value: lm, label: "lean", inverted: false)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    private func metricTile(value: String, unit: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.metricMedium)  // 32pt - fits 3 columns
                    .foregroundStyle(color)
                Text(unit)
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }
            Text(label)
                .font(.labelMicro)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func trendBadge(value: Double, label: String, inverted: Bool, suffix: String = " lbs") -> some View {
        let isPositive = inverted ? value < 0 : value > 0
        let color = isPositive ? Theme.success : Theme.error

        return HStack(spacing: 4) {
            Image(systemName: value < 0 ? "arrow.down" : "arrow.up")
                .font(.caption2)
            Text(String(format: "%.1f%@", abs(value), suffix))
                .font(.labelMicro)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }

    // MARK: - Chart Card

    private func chartCard(
        title: String,
        icon: String,
        color: Color,
        data: [ChartDataPoint],
        unit: String,
        trend: Double?,
        trendInverted: Bool,
        formatValue: @escaping (Double) -> String = { String(format: "%.1f", $0) }
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)
                    Text(title)
                        .font(.labelHero)
                        .tracking(2)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                // Data point count
                Text("\(data.count) readings")
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            // Interactive chart
            InteractiveChartView(
                data: data,
                color: color,
                unit: unit,
                formatValue: formatValue
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Theme.accent)
            Text("Loading body metrics...")
                .font(.labelMedium)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                    .opacity(0.5)

                Image(systemName: "figure.stand")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: 8) {
                Text("No body data yet")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)

                Text("Log your weight in the Health app to see trends here.")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true

        // Request authorization if needed
        _ = await healthKit.requestAuthorization()

        // Fetch data based on time range
        async let weightTask = fetchWeight()
        async let bodyFatTask = fetchBodyFat()
        async let leanMassTask = fetchLeanMass()

        let (weight, bodyFat, leanMass) = await (weightTask, bodyFatTask, leanMassTask)

        await MainActor.run {
            withAnimation(.airfit) {
                weightData = weight
                bodyFatData = bodyFat
                leanMassData = leanMass
                isLoading = false
            }
        }
    }

    private func fetchWeight() async -> [ChartDataPoint] {
        let readings: [WeightReading]

        if let days = timeRange.days {
            readings = await healthKit.getWeightHistory(days: days)
        } else {
            readings = await healthKit.getAllWeightHistory()
        }

        return readings.map { ChartDataPoint(date: $0.date, value: $0.weightLbs) }
    }

    private func fetchBodyFat() async -> [ChartDataPoint] {
        let readings: [BodyFatReading]

        if let days = timeRange.days {
            readings = await healthKit.getBodyFatHistory(days: days)
        } else {
            readings = await healthKit.getAllBodyFatHistory()
        }

        return readings.map { ChartDataPoint(date: $0.date, value: $0.bodyFatPct) }
    }

    private func fetchLeanMass() async -> [ChartDataPoint] {
        let readings: [LeanMassReading]

        if let days = timeRange.days {
            readings = await healthKit.getLeanMassHistory(days: days)
        } else {
            readings = await healthKit.getAllLeanMassHistory()
        }

        return readings.map { ChartDataPoint(date: $0.date, value: $0.leanMassLbs) }
    }
}

// MARK: - Training Content (extracted from TrainingView)

struct TrainingContentView: View {
    @State private var setTracker: APIClient.SetTrackerResponse?
    @State private var liftProgress: [APIClient.LiftData] = []
    @State private var recentWorkouts: [APIClient.WorkoutSummary] = []
    @State private var isLoading = true
    @State private var isSyncing = false

    private let apiClient = APIClient()

    var body: some View {
        Group {
            if isLoading && setTracker == nil {
                loadingView
            } else {
                trainingContent
            }
        }
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
    }

    private var trainingContent: some View {
        VStack(spacing: 24) {
            // Set Tracker Section (Hero)
            if let tracker = setTracker, !tracker.muscle_groups.isEmpty {
                setTrackerSection(tracker)
            }

            // Lift Progress Section
            if !liftProgress.isEmpty {
                liftProgressSection
            }

            // Recent Workouts Section
            if !recentWorkouts.isEmpty {
                recentWorkoutsSection
            }

            // Empty state
            if setTracker?.muscle_groups.isEmpty ?? true && liftProgress.isEmpty && !isLoading {
                emptyStateView
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    private func setTrackerSection(_ tracker: APIClient.SetTrackerResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                    Text("ROLLING 7-DAY SETS")
                        .font(.labelHero)
                        .tracking(2)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                if let lastSync = tracker.last_sync {
                    Text(formatSyncTime(lastSync))
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            let sortedMuscles = sortMuscleGroups(tracker.muscle_groups)

            ForEach(sortedMuscles, id: \.0) { name, data in
                MuscleProgressBar(
                    name: name.capitalized,
                    current: data.current,
                    minSets: data.min,
                    maxSets: data.max,
                    status: data.status
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    private func sortMuscleGroups(_ groups: [String: APIClient.MuscleGroupData]) -> [(String, APIClient.MuscleGroupData)] {
        let priority = ["chest", "back", "quads", "glutes", "hamstrings", "delts", "biceps", "triceps", "calves", "core"]
        return groups.sorted { a, b in
            let aIndex = priority.firstIndex(of: a.key) ?? priority.count
            let bIndex = priority.firstIndex(of: b.key) ?? priority.count
            return aIndex < bIndex
        }
    }

    private var liftProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(Theme.protein)
                Text("LIFT PROGRESS")
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(Theme.textMuted)
            }

            ForEach(liftProgress) { lift in
                LiftProgressCard(lift: lift)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundStyle(Theme.tertiary)
                Text("RECENT WORKOUTS")
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(Theme.textMuted)
            }

            ForEach(recentWorkouts) { workout in
                WorkoutCard(workout: workout)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Theme.accent)
            Text("Loading training data...")
                .font(.labelMedium)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                    .opacity(0.5)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent)
            }

            Text("No workout data")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)

            Text("Connect Hevy to see your training progress here.")
                .font(.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }

    private func loadData() async {
        isLoading = true

        async let setTrackerTask: () = loadSetTracker()
        async let liftProgressTask: () = loadLiftProgress()
        async let workoutsTask: () = loadRecentWorkouts()

        await setTrackerTask
        await liftProgressTask
        await workoutsTask

        isLoading = false
    }

    private func loadSetTracker() async {
        do {
            setTracker = try await apiClient.getSetTracker()
        } catch {
            print("Failed to load set tracker: \(error)")
        }
    }

    private func loadLiftProgress() async {
        do {
            let response = try await apiClient.getLiftProgress()
            liftProgress = response.lifts
        } catch {
            print("Failed to load lift progress: \(error)")
        }
    }

    private func loadRecentWorkouts() async {
        do {
            recentWorkouts = try await apiClient.getRecentWorkouts()
        } catch {
            print("Failed to load recent workouts: \(error)")
        }
    }

    private func formatSyncTime(_ isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: isoDate) {
            let relative = RelativeDateTimeFormatter()
            relative.unitsStyle = .abbreviated
            return relative.localizedString(for: date, relativeTo: Date())
        }
        return ""
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
