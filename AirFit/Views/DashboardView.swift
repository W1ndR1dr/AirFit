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
    @State private var weeklySleepBreakdowns: [SleepBreakdown] = []  // Detailed sleep stages
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
            // Run context and workouts in parallel (both are network calls)
            async let contextTask: () = loadWeekContext()
            async let workoutsTask: () = loadRecentWorkouts()

            _ = await (contextTask, workoutsTask)

            // Then load HealthKit history (deferred slightly for UI responsiveness)
            await loadWeeklyHistory()
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

        // Load sleep history from HealthKit (both simple hours and detailed breakdowns)
        let sleepValues = await loadSleepHistory()
        let sleepBreakdowns = await healthKit.getRecentSleepBreakdowns(nights: 7)
        await MainActor.run {
            weeklySleepData = sleepValues
            weeklySleepBreakdowns = sleepBreakdowns
        }

        // Use actual daily data from server (no longer repeating averages!)
        // ARCHITECTURE NOTE: Server stores daily aggregates synced from iOS.
        // This gives us real day-to-day variance for sparklines.
        if let ctx = weekContext {
            await MainActor.run {
                if let dailyNutrition = ctx.daily_nutrition, !dailyNutrition.isEmpty {
                    // Use actual daily values from server
                    weeklyProteinData = dailyNutrition.map { Double($0.protein) }
                    weeklyCaloriesData = dailyNutrition.map { Double($0.calories) }
                } else {
                    // Fallback: repeat average (legacy behavior when no daily data)
                    weeklyProteinData = Array(repeating: Double(ctx.avg_protein), count: 7)
                    weeklyCaloriesData = Array(repeating: Double(ctx.avg_calories), count: 7)
                }

                // Workouts: show flat count for now
                // TODO: Get actual workout days from Hevy data
                let workoutCount = Double(ctx.total_workouts)
                weeklyWorkoutData = Array(repeating: workoutCount / 7.0, count: 7)
            }
        }
    }

    /// Load 7 days of sleep data from HealthKit (parallel queries for speed)
    private func loadSleepHistory() async -> [Double] {
        let calendar = Calendar.current

        // Run all 7 days in parallel instead of serial
        return await withTaskGroup(of: (Int, Double).self) { group in
            for dayOffset in 0..<7 {
                group.addTask {
                    if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                        let snapshot = await self.healthKit.getDailySnapshot(for: date)
                        return (dayOffset, snapshot.sleepHours ?? 0)
                    }
                    return (dayOffset, 0)
                }
            }

            // Collect results and sort by dayOffset (most recent last)
            var results: [(Int, Double)] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 > $1.0 }.map { $0.1 }
        }
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

            // Readiness assessment (Phase 2: HealthKit Dashboard Expansion)
            ReadinessCard()
                .padding(.bottom, 8)

            Divider().padding(.leading, 70)

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
                    SleepBreakdownView(
                        breakdowns: weeklySleepBreakdowns,
                        dailyValues: weeklySleepData
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
    @State private var pRatioData: [ChartDataPoint] = []  // Rolling P-ratio quality scores
    @State private var restingHRData: [ChartDataPoint] = []  // Long-term cardio fitness
    @State private var walkingSpeedData: [ChartDataPoint] = []  // Walking pace (mph)
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

    // P-Ratio: Quality of body composition changes
    // Normalized so higher = better regardless of bulk/cut/maintain
    private var currentPRatio: Double? { pRatioData.last?.value }

    private var pRatioTrend: Double? {
        guard pRatioData.count >= 2 else { return nil }
        return pRatioData.last!.value - pRatioData.first!.value
    }

    // Resting HR: Lower is generally better (improved cardio fitness)
    private var currentRestingHR: Double? { restingHRData.last?.value }

    private var restingHRTrend: Double? {
        guard restingHRData.count >= 2 else { return nil }
        return restingHRData.last!.value - restingHRData.first!.value
    }

    // Walking Speed: Higher is better (improved mobility/fitness)
    private var currentWalkingSpeed: Double? { walkingSpeedData.last?.value }

    private var walkingSpeedTrend: Double? {
        guard walkingSpeedData.count >= 2 else { return nil }
        return walkingSpeedData.last!.value - walkingSpeedData.first!.value
    }

    /// Convert P-ratio quality score (0-100) to label
    private func pRatioLabel(for quality: Double) -> String {
        switch quality {
        case ..<20: return "Poor"           // Gaining fat or losing muscle
        case 20..<40: return "Fair"         // Suboptimal partitioning
        case 40..<60: return "Good"         // Decent quality changes
        case 60..<80: return "Great"        // High quality gains/losses
        default: return "Optimal"           // Elite partitioning
        }
    }

    /// Color for P-ratio quality level - intuitive scale: red → orange → light green → green → blue
    private func pRatioColor(for quality: Double) -> Color {
        switch quality {
        case ..<20: return Color(hex: "EF4444")   // Red - Poor
        case 20..<40: return Color(hex: "F97316") // Orange - Fair
        case 40..<60: return Color(hex: "84CC16") // Lime/Light Green - Good
        case 60..<80: return Color(hex: "22C55E") // Green - Great
        default: return Color(hex: "3B82F6")      // Blue - Optimal (exceptional)
        }
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
                    trendInverted: true,
                    tooltip: "A scalar value masquerading as moral judgment. Descartes never said 'I weigh, therefore I am'—and yet here we are. The trend is signal; any single reading is noise with emotional baggage. Think longitudinally or don't bother thinking at all."
                )
            }

            // P-Ratio - quality of body composition changes
            if !pRatioData.isEmpty {
                pRatioCard
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
                    tooltip: "Adipose tissue: evolution's answer to the question 'what if we needed to survive winter without DoorDash?' A Pareto-optimal storage solution—calorically dense, thermally insulating, hormonally active. The goal isn't zero; it's equilibrium.",
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
                    trendInverted: false,
                    tooltip: "Metabolically active tissue—the body's standing army, expensive to maintain but existentially necessary. Muscle is the organ of longevity; everything else is just along for the ride. Sisyphus should have lifted the boulder instead."
                )
            }

            // Resting heart rate chart - cardio fitness indicator
            if !restingHRData.isEmpty {
                chartCard(
                    title: "RESTING HR",
                    icon: "heart.fill",
                    color: Theme.error,
                    data: restingHRData,
                    unit: "bpm",
                    trend: restingHRTrend,
                    trendInverted: true,
                    tooltip: "The metronome of metabolic efficiency—your heart's idle speed. Lower resting rates signal cardiovascular adaptation: more stroke volume per beat, less work for the same output. Elite endurance athletes hover in the 40s; mortals should celebrate the 50s. Improvement here is measured in months, not days.",
                    formatValue: { String(format: "%.0f", $0) }
                )
            }

            // Walking speed temporarily disabled - motion metrics hang on fresh HealthKit auth
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
        tooltip: String? = nil,
        formatValue: @escaping (Double) -> String = { String(format: "%.1f", $0) }
    ) -> some View {
        ChartCardView(
            title: title,
            icon: icon,
            color: color,
            data: data,
            unit: unit,
            tooltip: tooltip,
            formatValue: formatValue
        )
    }

    // MARK: - P-Ratio Card (quality of composition changes)

    private var pRatioCard: some View {
        PRatioCardView(
            data: pRatioData,
            currentValue: currentPRatio,
            trend: pRatioTrend,
            timeRange: timeRange,
            qualityLabel: pRatioLabel,
            qualityColor: pRatioColor
        )
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        ShimmerLoadingView(text: "Loading body data...")
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

        // Defer heavy HealthKit queries to let UI render first
        try? await Task.sleep(for: .milliseconds(150))

        // Request authorization if needed
        _ = await healthKit.requestAuthorization()

        // Fetch body composition and heart data
        // NOTE: Motion metrics (walking speed, gait) are skipped - they hang on fresh HealthKit auth
        let weight = await fetchWeight()
        let bodyFat = await fetchBodyFat()
        let leanMass = await fetchLeanMass()
        let restingHR = await fetchRestingHR()

        // Calculate rolling P-ratio quality scores
        let pRatio = calculatePRatioQuality(weight: weight, bodyFat: bodyFat)

        await MainActor.run {
            withAnimation(.airfit) {
                weightData = weight
                bodyFatData = bodyFat
                leanMassData = leanMass
                pRatioData = pRatio
                restingHRData = restingHR
                walkingSpeedData = []
                isLoading = false
            }
        }
    }

    /// Calculate P-ratio quality scores over rolling windows
    /// P-ratio = ΔLean / ΔWeight, normalized so higher = better regardless of phase
    /// Uses a 14-day rolling window to smooth out daily fluctuations
    private func calculatePRatioQuality(weight: [ChartDataPoint], bodyFat: [ChartDataPoint]) -> [ChartDataPoint] {
        guard weight.count >= 2 && bodyFat.count >= 2 else { return [] }

        let calendar = Calendar.current
        let windowDays = 14  // Rolling window size

        // Build lookup of body fat by day
        var bodyFatByDay: [Date: Double] = [:]
        for bf in bodyFat {
            let dayStart = calendar.startOfDay(for: bf.date)
            bodyFatByDay[dayStart] = bf.value
        }

        // Calculate lean mass for each weight reading
        struct CompositionPoint {
            let date: Date
            let weight: Double
            let lean: Double
            let fat: Double
        }

        var compositionData: [CompositionPoint] = []
        for w in weight {
            let dayStart = calendar.startOfDay(for: w.date)
            if let bf = bodyFatByDay[dayStart], bf > 0 && bf < 100 {
                let fatMass = w.value * (bf / 100.0)
                let leanMass = w.value - fatMass
                compositionData.append(CompositionPoint(date: w.date, weight: w.value, lean: leanMass, fat: fatMass))
            }
        }

        compositionData.sort { $0.date < $1.date }
        guard compositionData.count >= 2 else { return [] }

        var results: [ChartDataPoint] = []

        // For each point, compare to point ~windowDays ago
        for i in 1..<compositionData.count {
            let current = compositionData[i]

            // Find comparison point (windowDays ago, or earliest available)
            let targetDate = calendar.date(byAdding: .day, value: -windowDays, to: current.date)!
            var compareIndex = 0
            for j in 0..<i {
                if compositionData[j].date <= targetDate {
                    compareIndex = j
                } else {
                    break
                }
            }

            let previous = compositionData[compareIndex]
            let deltaWeight = current.weight - previous.weight
            let deltaLean = current.lean - previous.lean
            let deltaFat = current.fat - previous.fat

            // Skip if no meaningful change
            guard abs(deltaWeight) > 0.5 else { continue }

            // Calculate quality score (0-100, higher = better)
            let quality: Double
            if deltaWeight > 0 {
                // Bulking: P-ratio = what % of gain was lean
                quality = max(0, min(100, (deltaLean / deltaWeight) * 100))
            } else {
                // Cutting: inverse P-ratio = what % of loss was fat
                quality = max(0, min(100, (deltaFat / deltaWeight) * 100))
            }

            results.append(ChartDataPoint(date: current.date, value: quality))
        }

        return results
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

    private func fetchRestingHR() async -> [ChartDataPoint] {
        let readings: [RestingHRReading]

        if let days = timeRange.days {
            readings = await healthKit.getRestingHRHistoryAsReadings(days: days)
        } else {
            readings = await healthKit.getAllRestingHRHistory()
        }

        return readings.map { ChartDataPoint(date: $0.date, value: $0.bpm) }
    }

    private func fetchWalkingSpeed() async -> [ChartDataPoint] {
        let readings: [WalkingSpeedReading]

        if let days = timeRange.days {
            readings = await healthKit.getWalkingSpeedHistory(days: days)
        } else {
            readings = await healthKit.getAllWalkingSpeedHistory()
        }

        // Convert to mph for display
        return readings.map { ChartDataPoint(date: $0.date, value: $0.mph) }
    }
}

// MARK: - Training Content (extracted from TrainingView)

struct TrainingContentView: View {
    @Environment(\.modelContext) private var modelContext

    // Cached data (from SwiftData via HevyCacheManager)
    @State private var cachedSetTracker: [CachedSetTracker] = []
    @State private var cachedLiftProgress: [CachedLiftProgress] = []
    @State private var cachedWorkouts: [CachedWorkout] = []

    // Tracked exercises (still from server - for strength detail view)
    @State private var trackedExercises: [APIClient.TrackedExercise] = []

    // UI state
    @State private var isLoading = true
    @State private var isCacheStale = false
    @State private var cacheAge: String = ""
    @State private var showHealthKitFallback = false
    @State private var healthKitWorkouts: [HealthKitWorkout] = []

    private let apiClient = APIClient()
    private let hevyCacheManager = HevyCacheManager()
    private let healthKit = HealthKitManager()

    var body: some View {
        Group {
            if isLoading && cachedSetTracker.isEmpty && cachedWorkouts.isEmpty {
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
            // Staleness indicator if cache is old
            if isCacheStale {
                stalenessIndicator
            }

            // Set Tracker Section (Hero) - from cache
            if !cachedSetTracker.isEmpty {
                setTrackerSection
            }

            // Strength Progress Section (drill-down to StrengthDetailView)
            if !trackedExercises.isEmpty {
                StrengthSummaryCard(exercises: trackedExercises)
            }

            // Lift Progress Section - from cache
            if !cachedLiftProgress.isEmpty {
                liftProgressSection
            }

            // Recent Workouts Section - from cache
            if !cachedWorkouts.isEmpty {
                recentWorkoutsSection
            }

            // HealthKit fallback when no Hevy cache
            if showHealthKitFallback && !healthKitWorkouts.isEmpty {
                healthKitFallbackSection
            }

            // Empty state
            if cachedSetTracker.isEmpty && cachedLiftProgress.isEmpty && cachedWorkouts.isEmpty && healthKitWorkouts.isEmpty && !isLoading {
                emptyStateView
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Staleness Indicator

    private var stalenessIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.caption)
            Text("Workout data from \(cacheAge)")
                .font(.caption)

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .foregroundStyle(Theme.textMuted)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
    }

    // MARK: - HealthKit Fallback Section

    private var healthKitFallbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Text("APPLE HEALTH WORKOUTS")
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(Theme.textMuted)
            }

            Text("Connect Hevy via server for detailed lift tracking")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)

            ForEach(healthKitWorkouts, id: \.id) { workout in
                HealthKitWorkoutRow(workout: workout)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    private var setTrackerSection: some View {
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

                if !cacheAge.isEmpty {
                    Text(cacheAge)
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            let sortedMuscles = sortMuscleGroups(cachedSetTracker)

            ForEach(sortedMuscles, id: \.muscleGroup) { cached in
                MuscleProgressBar(
                    name: cached.muscleGroup.capitalized,
                    current: cached.currentSets,
                    minSets: cached.optimalMin,
                    maxSets: cached.optimalMax,
                    status: cached.status
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

    private func sortMuscleGroups(_ groups: [CachedSetTracker]) -> [CachedSetTracker] {
        let priority = ["chest", "back", "quads", "glutes", "hamstrings", "delts", "biceps", "triceps", "calves", "core"]
        return groups.sorted { a, b in
            let aIndex = priority.firstIndex(of: a.muscleGroup) ?? priority.count
            let bIndex = priority.firstIndex(of: b.muscleGroup) ?? priority.count
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

            ForEach(cachedLiftProgress, id: \.exerciseName) { lift in
                CachedLiftProgressCard(lift: lift)
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

            ForEach(cachedWorkouts, id: \.id) { workout in
                CachedWorkoutCard(workout: workout)
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
        ShimmerLoadingView(text: "Loading workouts...")
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

        // Small defer to let UI render first
        try? await Task.sleep(for: .milliseconds(50))

        // Try to refresh cache from server first
        let serverAvailable = await apiClient.checkHealth()

        if serverAvailable {
            // Refresh cache from server
            do {
                try await hevyCacheManager.refreshFromServer(modelContext: modelContext)
                isCacheStale = false
            } catch {
                print("[TrainingContent] Cache refresh failed: \(error)")
            }
        }

        // Load from cache (fresh or stale)
        await loadFromCache()

        // Check if cache is stale
        isCacheStale = await hevyCacheManager.isCacheStale(modelContext: modelContext)
        cacheAge = await hevyCacheManager.cacheAgeDescription(modelContext: modelContext)

        // Load tracked exercises from server (for strength detail view)
        if serverAvailable {
            await loadTrackedExercises()
        }

        // Fallback to HealthKit if no Hevy cache
        if cachedWorkouts.isEmpty {
            await loadHealthKitFallback()
        }

        isLoading = false
    }

    private func loadFromCache() async {
        cachedSetTracker = await hevyCacheManager.getSetTracker(modelContext: modelContext)
        cachedLiftProgress = await hevyCacheManager.getLiftProgress(modelContext: modelContext)
        cachedWorkouts = await hevyCacheManager.getRecentWorkouts(modelContext: modelContext)
    }

    private func loadTrackedExercises() async {
        do {
            let response = try await apiClient.getTrackedExercises()
            trackedExercises = response.exercises
        } catch {
            print("Failed to load tracked exercises: \(error)")
        }
    }

    private func loadHealthKitFallback() async {
        let workouts = await healthKit.getRecentWorkouts(days: 7)
        if !workouts.isEmpty {
            showHealthKitFallback = true
            healthKitWorkouts = workouts
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}

// MARK: - Chart Card View with Tooltip

struct ChartCardView: View {
    let title: String
    let icon: String
    let color: Color
    let data: [ChartDataPoint]
    let unit: String
    let tooltip: String?
    let formatValue: (Double) -> String

    @State private var showTooltip = false

    var body: some View {
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

                    // Info button for tooltip
                    if tooltip != nil {
                        Button {
                            showTooltip = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
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
        .sheet(isPresented: $showTooltip) {
            if let tooltip = tooltip {
                MetricTooltipSheet(title: title, explanation: tooltip, color: color)
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Theme.surface)
            }
        }
    }
}

// MARK: - Change Quality Card View with Synchronized Gauge + Chart

struct PRatioCardView: View {
    let data: [ChartDataPoint]
    let currentValue: Double?
    let trend: Double?
    let timeRange: ChartTimeRange  // Use dashboard's time range
    let qualityLabel: (Double) -> String
    let qualityColor: (Double) -> Color

    @State private var showTooltip = false
    @State private var selectedValue: Double?

    private let tooltip = """
    Based on P-Score (partitioning ratio)—the scientific measure of how much weight change comes from lean mass versus fat. A score of 100 means pure muscle; 0 means pure fat storage.

    Nutrient partitioning efficiency—a measure of whether your body is building the cathedral or just piling stones. Not all mass is created equal, and this metric knows the difference.

    High scores mean your inputs are becoming outputs you actually wanted. Low scores suggest your metabolism is still preparing for a famine that isn't coming. The good news: this one bends to your will.
    """

    // Shared height for perfect gauge/chart alignment
    private let sharedHeight: CGFloat = 140

    // Zone thresholds
    private let zones: [(threshold: Double, label: String)] = [
        (0, "Poor"),
        (20, "Fair"),
        (40, "Good"),
        (60, "Great"),
        (80, "Optimal")
    ]

    // Display value - selected or current
    private var displayValue: Double {
        selectedValue ?? currentValue ?? 50.0
    }

    // Filter data by time range
    private var filteredData: [ChartDataPoint] {
        guard let days = timeRange.days else { return data }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return data.filter { $0.date >= cutoff }
    }

    var body: some View {
        let color = qualityColor(displayValue)

        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.caption)
                    .foregroundStyle(color)
                Text("CHANGE QUALITY")
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(Theme.textMuted)

                Button {
                    showTooltip = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted.opacity(0.6))
                }
                .buttonStyle(.plain)

                Spacer()
            }

            // Main content: Gauge + Chart synchronized
            QualityGaugeChartView(
                data: filteredData,
                displayValue: displayValue,
                color: color,
                zones: zones,
                qualityColor: qualityColor,
                chartHeight: sharedHeight,
                onSelectionChange: { value in
                    selectedValue = value
                },
                onSelectionEnd: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.airfit) {
                            selectedValue = nil
                        }
                    }
                }
            )

            // X-axis labels
            if let first = filteredData.first?.date, let last = filteredData.last?.date {
                HStack {
                    Text(formatAxisDate(first))
                    Spacer()
                    Text(formatAxisDate(last))
                }
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)
                .padding(.leading, 50)  // Align with chart area
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
        .sheet(isPresented: $showTooltip) {
            MetricTooltipSheet(title: "Change Quality", explanation: tooltip, color: color)
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.surface)
        }
        .sensoryFeedback(.selection, trigger: selectedValue != nil ? Int(displayValue / 20) : nil)
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Combined Gauge + Chart View (for proper alignment)

struct QualityGaugeChartView: View {
    let data: [ChartDataPoint]
    let displayValue: Double
    let color: Color
    let zones: [(threshold: Double, label: String)]
    let qualityColor: (Double) -> Color
    let chartHeight: CGFloat
    let onSelectionChange: (Double?) -> Void
    let onSelectionEnd: () -> Void

    @State private var selectedPoint: ChartDataPoint?
    @State private var showingDetail = false

    private var smoothedData: [ChartDataPoint] {
        guard data.count > 3 else { return data }
        // P-ratio is inherently volatile (small weight changes → big % swings)
        // Use aggressive smoothing (35% bandwidth) to tame the noise while
        // preserving the overall trend shape
        return ChartSmoothing.applyLOESS(to: data, bandwidth: 0.35)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Selection detail - appears above BOTH gauge and chart
            if let point = selectedPoint, showingDetail {
                HStack {
                    Text(qualityLabel(for: point.trendValue))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(qualityColor(point.trendValue))

                    Text("•")
                        .foregroundStyle(Theme.textMuted)

                    Text(formatDate(point.date))
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)

                    Spacer()
                }
                .padding(.bottom, 8)
                .padding(.leading, 50)  // Align with chart
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Gauge + Chart side by side
            HStack(alignment: .top, spacing: 4) {
                // Compact gauge with aligned labels
                CompactGaugeView(
                    value: displayValue,
                    color: color,
                    zones: zones,
                    height: chartHeight
                )
                .animation(.spring(response: 0.2), value: displayValue)

                // Chart area
                GeometryReader { geo in
                    ZStack {
                        // Zone background bands
                        VStack(spacing: 0) {
                            ForEach(zones.reversed(), id: \.threshold) { zone in
                                zoneColor(for: zone.threshold).opacity(0.08)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Zone divider lines
                        ForEach(1..<zones.count, id: \.self) { i in
                            let y = geo.size.height * CGFloat(i) / CGFloat(zones.count)
                            Rectangle()
                                .fill(Theme.textMuted.opacity(0.15))
                                .frame(height: 1)
                                .position(x: geo.size.width / 2, y: y)
                        }

                        // Chart content
                        let processedData = smoothedData
                        if processedData.count >= 2 {
                            chartContent(data: processedData, width: geo.size.width, height: geo.size.height)
                        } else if processedData.count == 1 {
                            singlePointView(point: processedData[0], width: geo.size.width, height: geo.size.height)
                        } else {
                            Text("Not enough data")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }

                        // Touch overlay
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        handleTouch(at: value.location, width: geo.size.width, height: geo.size.height)
                                    }
                                    .onEnded { _ in
                                        onSelectionEnd()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            withAnimation(.airfit) {
                                                showingDetail = false
                                                selectedPoint = nil
                                                onSelectionChange(nil)
                                            }
                                        }
                                    }
                            )
                    }
                }
                .frame(height: chartHeight)
            }
        }
    }

    private func chartContent(data: [ChartDataPoint], width: CGFloat, height: CGFloat) -> some View {
        let points = normalizedPoints(data: data, width: width, height: height)

        return ZStack {
            // Subtle gradient fill
            LinearGradient(
                colors: [Theme.textMuted.opacity(0.1), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .mask(areaPath(through: points, height: height))

            // Zone-colored line segments (muted to match pastel theme)
            ForEach(0..<max(0, data.count - 1), id: \.self) { i in
                let p1 = points[i]
                let p2 = points[i + 1]
                // Use average value of segment for color
                let avgValue = (data[i].trendValue + data[i + 1].trendValue) / 2
                let segmentColor = colorForValue(avgValue).opacity(0.6)

                // Draw smooth curve segment
                segmentPath(from: p1, to: p2, index: i, points: points)
                    .stroke(segmentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }

            // Selected point indicator
            if let point = selectedPoint, let index = data.firstIndex(where: { $0.id == point.id }) {
                let pos = points[index]

                Rectangle()
                    .fill(qualityColor(point.trendValue).opacity(0.5))
                    .frame(width: 1, height: height)
                    .position(x: pos.x, y: height / 2)

                Circle()
                    .fill(Theme.surface)
                    .overlay(Circle().stroke(qualityColor(point.trendValue), lineWidth: 3))
                    .frame(width: 14, height: 14)
                    .shadow(color: qualityColor(point.trendValue).opacity(0.5), radius: 6)
                    .position(pos)
            }
        }
    }

    /// Draw a single smooth curve segment between two points
    private func segmentPath(from p1: CGPoint, to p2: CGPoint, index i: Int, points: [CGPoint]) -> Path {
        Path { path in
            path.move(to: p1)

            let p0 = i > 0 ? points[i - 1] : points[0]
            let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]

            let tension: CGFloat = 0.25
            let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) * tension, y: p1.y + (p2.y - p0.y) * tension)
            let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) * tension, y: p2.y - (p3.y - p1.y) * tension)

            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
    }

    private func singlePointView(point: ChartDataPoint, width: CGFloat, height: CGFloat) -> some View {
        let y = height * (1 - point.value / 100)
        return Circle()
            .fill(Theme.surface)
            .overlay(Circle().stroke(qualityColor(point.value), lineWidth: 2))
            .frame(width: 12, height: 12)
            .position(x: width / 2, y: y)
    }

    private func normalizedPoints(data: [ChartDataPoint], width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard data.count >= 2,
              let firstDate = data.first?.date,
              let lastDate = data.last?.date else { return [] }

        let timeRange = lastDate.timeIntervalSince(firstDate)

        return data.map { point in
            let x = timeRange > 0
                ? CGFloat(point.date.timeIntervalSince(firstDate) / timeRange) * width
                : width / 2
            let value = min(max(point.trendValue, 0), 100)
            let y = height * (1 - value / 100)
            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(through points: [CGPoint]) -> Path {
        Path { path in
            guard points.count >= 2 else { return }
            path.move(to: points[0])

            for i in 0..<(points.count - 1) {
                let p0 = i > 0 ? points[i - 1] : points[0]
                let p1 = points[i]
                let p2 = points[i + 1]
                let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]

                let tension: CGFloat = 0.25
                let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) * tension, y: p1.y + (p2.y - p0.y) * tension)
                let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) * tension, y: p2.y - (p3.y - p1.y) * tension)

                path.addCurve(to: p2, control1: cp1, control2: cp2)
            }
        }
    }

    private func areaPath(through points: [CGPoint], height: CGFloat) -> Path {
        Path { path in
            guard let first = points.first, let last = points.last else { return }

            path.move(to: CGPoint(x: first.x, y: height))
            path.addLine(to: first)

            if points.count >= 2 {
                for i in 0..<(points.count - 1) {
                    let p0 = i > 0 ? points[i - 1] : points[0]
                    let p1 = points[i]
                    let p2 = points[i + 1]
                    let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]

                    let tension: CGFloat = 0.25
                    let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) * tension, y: p1.y + (p2.y - p0.y) * tension)
                    let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) * tension, y: p2.y - (p3.y - p1.y) * tension)

                    path.addCurve(to: p2, control1: cp1, control2: cp2)
                }
            }

            path.addLine(to: CGPoint(x: last.x, y: height))
            path.closeSubpath()
        }
    }

    private func handleTouch(at location: CGPoint, width: CGFloat, height: CGFloat) {
        let processedData = smoothedData
        guard !processedData.isEmpty else { return }

        let points = normalizedPoints(data: processedData, width: width, height: height)
        guard !points.isEmpty else { return }

        var closestIndex = 0
        var closestDistance = CGFloat.infinity

        for (index, point) in points.enumerated() {
            let distance = abs(point.x - location.x)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }

        let newSelection = processedData[closestIndex]
        if selectedPoint?.id != newSelection.id {
            withAnimation(.spring(response: 0.2)) {
                selectedPoint = newSelection
                showingDetail = true
                onSelectionChange(newSelection.trendValue)
            }
        }
    }

    // Intuitive color scale: red → orange → lime → green → blue
    private func zoneColor(for threshold: Double) -> Color {
        switch threshold {
        case 80...: return Color(hex: "3B82F6")   // Blue - Optimal
        case 60..<80: return Color(hex: "22C55E") // Green - Great
        case 40..<60: return Color(hex: "84CC16") // Lime - Good
        case 20..<40: return Color(hex: "F97316") // Orange - Fair
        default: return Color(hex: "EF4444")      // Red - Poor
        }
    }

    private func qualityLabel(for value: Double) -> String {
        switch value {
        case 80...: return "Optimal"
        case 60..<80: return "Great"
        case 40..<60: return "Good"
        case 20..<40: return "Fair"
        default: return "Poor"
        }
    }

    // Get color for a specific value (for line segments)
    private func colorForValue(_ value: Double) -> Color {
        switch value {
        case 80...: return Color(hex: "3B82F6")   // Blue - Optimal
        case 60..<80: return Color(hex: "22C55E") // Green - Great
        case 40..<60: return Color(hex: "84CC16") // Lime - Good
        case 20..<40: return Color(hex: "F97316") // Orange - Fair
        default: return Color(hex: "EF4444")      // Red - Poor
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Compact Gauge View with Proper Label Alignment

struct CompactGaugeView: View {
    let value: Double
    let color: Color
    let zones: [(threshold: Double, label: String)]
    let height: CGFloat

    private let barWidth: CGFloat = 16

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            // Labels - each one exactly matches zone height, right-aligned
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(zones.reversed(), id: \.threshold) { zone in
                    Text(zone.label)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(zoneColor(for: zone.threshold).opacity(isInZone(zone.threshold) ? 1 : 0.4))
                        .frame(height: height / CGFloat(zones.count), alignment: .trailing)
                }
            }
            .frame(width: 34, alignment: .trailing)

            // Gauge bar with indicator
            ZStack(alignment: .topLeading) {
                // Zone colors
                VStack(spacing: 0) {
                    ForEach(zones.reversed(), id: \.threshold) { zone in
                        Rectangle()
                            .fill(zoneColor(for: zone.threshold).opacity(isInZone(zone.threshold) ? 0.5 : 0.15))
                    }
                }
                .frame(width: barWidth)
                .clipShape(RoundedRectangle(cornerRadius: 3))

                // Divider lines
                ForEach(1..<zones.count, id: \.self) { i in
                    Rectangle()
                        .fill(Theme.textMuted.opacity(0.25))
                        .frame(width: barWidth, height: 1)
                        .offset(y: height * CGFloat(i) / CGFloat(zones.count) - 0.5)
                }

                // Indicator
                let y = height * (1 - min(max(value, 0), 100) / 100)
                HStack(spacing: 0) {
                    Triangle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .rotationEffect(.degrees(90))
                    Rectangle()
                        .fill(color)
                        .frame(width: barWidth + 2, height: 2)
                }
                .offset(x: -3, y: y - 3)
            }
            .frame(width: barWidth, height: height)
        }
    }

    private func isInZone(_ threshold: Double) -> Bool {
        let nextThreshold = threshold + 20
        return value >= threshold && value < nextThreshold
    }

    // Intuitive color scale: red → orange → lime → green → blue
    private func zoneColor(for threshold: Double) -> Color {
        switch threshold {
        case 80...: return Color(hex: "3B82F6")   // Blue - Optimal (exceptional)
        case 60..<80: return Color(hex: "22C55E") // Green - Great
        case 40..<60: return Color(hex: "84CC16") // Lime - Good
        case 20..<40: return Color(hex: "F97316") // Orange - Fair
        default: return Color(hex: "EF4444")      // Red - Poor
        }
    }
}

// MARK: - Quality Gauge View (legacy - can be removed after confirming new view works)

struct QualityGaugeView: View {
    let value: Double
    let color: Color
    let zones: [(threshold: Double, label: String)]
    let gaugeHeight: CGFloat

    var body: some View {
        CompactGaugeView(value: value, color: color, zones: zones, height: gaugeHeight)
    }
}

// MARK: - Quality Chart with Zone Backgrounds (legacy - kept for reference)

struct QualityChartView: View {
    let data: [ChartDataPoint]
    let zones: [(threshold: Double, label: String)]
    let qualityColor: (Double) -> Color
    let chartHeight: CGFloat  // Passed in to match gauge
    let onSelectionChange: (Double?) -> Void
    let onSelectionEnd: () -> Void

    @State private var selectedPoint: ChartDataPoint?
    @State private var showingDetail = false

    // Apply EMA smoothing like other body comp charts
    private var smoothedData: [ChartDataPoint] {
        guard data.count > 3 else { return data }
        let period = ChartSmoothing.optimalPeriod(for: data)
        return ChartSmoothing.applyEMA(to: data, period: period)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Selected point detail
            if let point = selectedPoint, showingDetail {
                HStack {
                    Text("\(Int(point.trendValue))%")
                        .font(.metricSmall)
                        .foregroundStyle(qualityColor(point.trendValue))

                    Text(formatDate(point.date))
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)

                    Spacer()
                }
                .padding(.bottom, 6)
                .transition(.opacity)
            }

            // Chart with zone backgrounds
            GeometryReader { geo in
                ZStack {
                    // Zone background bands (no spacing - exact alignment)
                    VStack(spacing: 0) {
                        ForEach(zones.reversed(), id: \.threshold) { zone in
                            zoneColor(for: zone.threshold).opacity(0.08)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Zone divider lines at exact boundaries
                    ForEach(1..<zones.count, id: \.self) { i in
                        let y = geo.size.height * CGFloat(i) / CGFloat(zones.count)
                        Rectangle()
                            .fill(Theme.textMuted.opacity(0.15))
                            .frame(height: 1)
                            .position(x: geo.size.width / 2, y: y)
                    }

                    // Line chart (smoothed)
                    let processedData = smoothedData
                    if processedData.count >= 2 {
                        chartContent(data: processedData, width: geo.size.width, height: geo.size.height)
                    } else if processedData.count == 1 {
                        singlePointView(point: processedData[0], width: geo.size.width, height: geo.size.height)
                    } else {
                        Text("Not enough data")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }

                    // Touch overlay
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleTouch(at: value.location, width: geo.size.width, height: geo.size.height)
                                }
                                .onEnded { _ in
                                    onSelectionEnd()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation(.airfit) {
                                            showingDetail = false
                                            selectedPoint = nil
                                            onSelectionChange(nil)
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(height: chartHeight)

            // X-axis labels
            if let first = data.first?.date, let last = data.last?.date {
                HStack {
                    Text(formatAxisDate(first))
                    Spacer()
                    Text(formatAxisDate(last))
                }
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)
                .padding(.top, 6)
            }
        }
    }

    private func chartContent(data: [ChartDataPoint], width: CGFloat, height: CGFloat) -> some View {
        let points = normalizedPoints(data: data, width: width, height: height)

        return ZStack {
            // Gradient fill under smoothed line
            LinearGradient(
                colors: [Theme.accent.opacity(0.25), Theme.accent.opacity(0.05), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .mask(areaPath(through: points, height: height))

            // Smoothed line
            linePath(through: points)
                .stroke(
                    LinearGradient(
                        colors: [qualityColor(80), qualityColor(50), qualityColor(20)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )

            // Selected point indicator
            if let point = selectedPoint, let index = data.firstIndex(where: { $0.id == point.id }) {
                let pos = points[index]

                // Vertical line
                Rectangle()
                    .fill(qualityColor(point.trendValue).opacity(0.5))
                    .frame(width: 1, height: height)
                    .position(x: pos.x, y: height / 2)

                // Point on trend line
                Circle()
                    .fill(Theme.surface)
                    .overlay(Circle().stroke(qualityColor(point.trendValue), lineWidth: 3))
                    .frame(width: 14, height: 14)
                    .shadow(color: qualityColor(point.trendValue).opacity(0.5), radius: 6)
                    .position(pos)
            }
        }
    }

    private func singlePointView(point: ChartDataPoint, width: CGFloat, height: CGFloat) -> some View {
        let y = height * (1 - point.value / 100)
        return Circle()
            .fill(Theme.surface)
            .overlay(Circle().stroke(qualityColor(point.value), lineWidth: 2))
            .frame(width: 12, height: 12)
            .position(x: width / 2, y: y)
    }

    private func normalizedPoints(data: [ChartDataPoint], width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard data.count >= 2,
              let firstDate = data.first?.date,
              let lastDate = data.last?.date else { return [] }

        let timeRange = lastDate.timeIntervalSince(firstDate)

        return data.map { point in
            let x = timeRange > 0
                ? CGFloat(point.date.timeIntervalSince(firstDate) / timeRange) * width
                : width / 2

            // Fixed 0-100 scale, use smoothed trend value
            let value = min(max(point.trendValue, 0), 100)
            let y = height * (1 - value / 100)

            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(through points: [CGPoint]) -> Path {
        Path { path in
            guard points.count >= 2 else { return }
            path.move(to: points[0])

            for i in 0..<(points.count - 1) {
                let p0 = i > 0 ? points[i - 1] : points[0]
                let p1 = points[i]
                let p2 = points[i + 1]
                let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]

                let tension: CGFloat = 0.25
                let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) * tension, y: p1.y + (p2.y - p0.y) * tension)
                let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) * tension, y: p2.y - (p3.y - p1.y) * tension)

                path.addCurve(to: p2, control1: cp1, control2: cp2)
            }
        }
    }

    private func areaPath(through points: [CGPoint], height: CGFloat) -> Path {
        Path { path in
            guard let first = points.first, let last = points.last else { return }

            path.move(to: CGPoint(x: first.x, y: height))
            path.addLine(to: first)

            if points.count >= 2 {
                for i in 0..<(points.count - 1) {
                    let p0 = i > 0 ? points[i - 1] : points[0]
                    let p1 = points[i]
                    let p2 = points[i + 1]
                    let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]

                    let tension: CGFloat = 0.25
                    let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) * tension, y: p1.y + (p2.y - p0.y) * tension)
                    let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) * tension, y: p2.y - (p3.y - p1.y) * tension)

                    path.addCurve(to: p2, control1: cp1, control2: cp2)
                }
            }

            path.addLine(to: CGPoint(x: last.x, y: height))
            path.closeSubpath()
        }
    }

    private func handleTouch(at location: CGPoint, width: CGFloat, height: CGFloat) {
        let processedData = smoothedData
        guard !processedData.isEmpty else { return }

        let points = normalizedPoints(data: processedData, width: width, height: height)
        guard !points.isEmpty else { return }

        var closestIndex = 0
        var closestDistance = CGFloat.infinity

        for (index, point) in points.enumerated() {
            let distance = abs(point.x - location.x)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }

        let newSelection = processedData[closestIndex]
        if selectedPoint?.id != newSelection.id {
            withAnimation(.spring(response: 0.2)) {
                selectedPoint = newSelection
                showingDetail = true
                // Use smoothed trend value for gauge
                onSelectionChange(newSelection.trendValue)
            }
        }
    }

    private func zoneColor(for threshold: Double) -> Color {
        switch threshold {
        case 80...: return Theme.success
        case 60..<80: return Color(hex: "4ECDC4")
        case 40..<60: return Theme.accent
        case 20..<40: return Theme.warning
        default: return Theme.error
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}


// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Metric Tooltip Sheet (Self-sizing)

struct MetricTooltipSheet: View {
    let title: String
    let explanation: String
    let color: Color

    @State private var contentHeight: CGFloat = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }

            Text(explanation)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: TooltipHeightKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(TooltipHeightKey.self) { height in
            contentHeight = height
        }
        .presentationDetents([.height(contentHeight)])
    }
}

private struct TooltipHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 100
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Cached Data Card Views

/// Card for displaying cached lift progress from Hevy
struct CachedLiftProgressCard: View {
    let lift: CachedLiftProgress

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lift.exerciseName)
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Text("\(lift.workoutCount) sessions")
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            HStack(alignment: .bottom, spacing: 16) {
                // Current PR
                VStack(alignment: .leading, spacing: 2) {
                    Text("PR")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(lift.currentPRWeightLbs))")
                            .font(.metricSmall)
                            .foregroundStyle(Theme.protein)
                        Text("lbs × \(lift.currentPRReps)")
                            .font(.labelMicro)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                // Sparkline from history
                if !lift.history.isEmpty {
                    SparklineView(
                        data: lift.history.map { $0.weightLbs },
                        color: Theme.protein,
                        height: 24
                    )
                    .frame(width: 60)
                }

                // PR date
                Text(dateFormatter.string(from: lift.currentPRDate))
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
    }
}

/// Card for displaying cached workout from Hevy
struct CachedWorkoutCard: View {
    let workout: CachedWorkout

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.title)
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Text(dateFormatter.string(from: workout.workoutDate))
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            HStack(spacing: 12) {
                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(workout.durationMinutes)m")
                }
                .font(.labelMicro)
                .foregroundStyle(Theme.textSecondary)

                // Volume
                HStack(spacing: 4) {
                    Image(systemName: "scalemass")
                        .font(.caption2)
                    Text("\(Int(workout.totalVolumeLbs)) lbs")
                }
                .font(.labelMicro)
                .foregroundStyle(Theme.textSecondary)

                Spacer()
            }

            // Exercises (truncated)
            if !workout.exercises.isEmpty {
                Text(workout.exercises.prefix(4).joined(separator: " • "))
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
    }
}

/// Row for displaying HealthKit workout (fallback when no Hevy cache)
struct HealthKitWorkoutRow: View {
    let workout: HealthKitWorkout

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        HStack {
            // Workout type icon
            Image(systemName: iconForWorkoutType(workout.type))
                .font(.body)
                .foregroundStyle(Theme.tertiary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.type)
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 8) {
                    Text("\(workout.durationMinutes) min")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textSecondary)

                    if let calories = workout.caloriesBurned {
                        Text("\(calories) cal")
                            .font(.labelMicro)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            Spacer()

            Text(dateFormatter.string(from: workout.date))
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
    }

    private func iconForWorkoutType(_ type: String) -> String {
        switch type.lowercased() {
        case let t where t.contains("run"): return "figure.run"
        case let t where t.contains("walk"): return "figure.walk"
        case let t where t.contains("cycl"): return "figure.outdoor.cycle"
        case let t where t.contains("swim"): return "figure.pool.swim"
        case let t where t.contains("strength"), let t where t.contains("weight"): return "figure.strengthtraining.traditional"
        case let t where t.contains("yoga"): return "figure.mind.and.body"
        case let t where t.contains("hiit"): return "figure.highintensity.intervaltraining"
        default: return "figure.mixed.cardio"
        }
    }
}

/// Simple sparkline view for lift progress history
struct SparklineView: View {
    let data: [Double]
    let color: Color
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            if data.count >= 2, let minVal = data.min(), let maxVal = data.max(), maxVal > minVal {
                Path { path in
                    let range = maxVal - minVal
                    let stepX = geo.size.width / CGFloat(data.count - 1)

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geo.size.height - (CGFloat((value - minVal) / range) * geo.size.height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
    }
}
