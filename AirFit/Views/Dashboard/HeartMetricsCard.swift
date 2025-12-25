import SwiftUI

/// Cardiac Fitness card showing HRV, RHR, VO2max, and HRR with scrubbable charts.
///
/// Design:
/// - Collapsed: 2x2 grid of metric tiles (VO2max/HRR only if data exists)
/// - Expanded: Tabbed scrubbable charts matching body composition pattern
/// - Per-metric time windows based on physiological response times
struct CardiacFitnessCard: View {
    private let healthKit = HealthKitManager()

    // MARK: - Metric Types

    enum CardiacMetric: String, CaseIterable, Identifiable {
        case hrv = "HRV"
        case rhr = "RHR"
        case vo2max = "VO2max"
        case hrr = "HRR"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .hrv: return "waveform.path.ecg"
            case .rhr: return "heart.fill"
            case .vo2max: return "lungs.fill"
            case .hrr: return "heart.text.square.fill"
            }
        }

        var color: Color {
            switch self {
            case .hrv: return Theme.accent
            case .rhr: return Theme.error
            case .vo2max: return Theme.accent
            case .hrr: return Theme.error
            }
        }

        var subtitle: String {
            switch self {
            case .hrv: return "Variability"
            case .rhr: return "Resting"
            case .vo2max: return "Cardio"
            case .hrr: return "Recovery"
            }
        }

        /// Default time window based on physiological response time
        var defaultTimeRange: CardiacTimeRange {
            switch self {
            case .hrv: return .twoWeeks      // Fast responder - acute changes in 24-48h
            case .rhr: return .threeMonths   // Slow responder - adaptations in 8-12 weeks
            case .vo2max: return .year       // Very slow - quarterly measurements
            case .hrr: return .twoMonths     // Moderate - improvements in 6-12 weeks
            }
        }

        /// Available time ranges for this metric
        var availableRanges: [CardiacTimeRange] {
            switch self {
            case .hrv: return [.week, .twoWeeks, .month, .twoMonths]
            case .rhr: return [.month, .twoMonths, .threeMonths, .year]
            case .vo2max: return [.threeMonths, .year, .all]
            case .hrr: return [.month, .twoMonths, .threeMonths]
            }
        }
    }

    /// Time range options for cardiac metrics
    enum CardiacTimeRange: String, CaseIterable, Identifiable {
        case week = "1W"
        case twoWeeks = "2W"
        case month = "1M"
        case twoMonths = "2M"
        case threeMonths = "3M"
        case year = "1Y"
        case all = "All"

        var id: String { rawValue }

        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            case .twoMonths: return 60
            case .threeMonths: return 90
            case .year: return 365
            case .all: return 3650  // 10 years
            }
        }
    }

    // MARK: - State

    @State private var isLoading = true
    @State private var isExpanded = false
    @State private var selectedMetric: CardiacMetric = .hrv
    @State private var showingTooltip = false
    @State private var timeRanges: [CardiacMetric: CardiacTimeRange] = [
        .hrv: .twoWeeks,
        .rhr: .threeMonths,
        .vo2max: .year,
        .hrr: .twoMonths
    ]

    private var currentTimeRange: CardiacTimeRange {
        timeRanges[selectedMetric] ?? selectedMetric.defaultTimeRange
    }

    // MARK: - Tooltips

    private var currentTooltip: String {
        switch selectedMetric {
        case .hrv:
            return """
            The chaos between heartbeats—Heraclitus would approve. High variability means your autonomic nervous system can pivot between parasympathetic calm and sympathetic overdrive without drama. It's biological optionality.

            Your nervous system's antifragility score. Rigid rhythms are for metronomes and the metabolically stressed; healthy hearts improvise like jazz drummers. Deviation from YOUR baseline is signal; absolute numbers are astrology.

            Rebounds in 24-48 hours with proper recovery. Crashed after a rough night? That's data, not destiny. Watch the 7-day trend and ignore daily noise.
            """
        case .rhr:
            return """
            Your cardiac idle speed—what the engine does when the car is parked. Lower is better; it means each pump moves more blood, so fewer pumps are needed. Thermodynamic elegance.

            Elite endurance athletes cruise in the 40s. The rest of us oscillate in the 50s-70s, which is perfectly fine unless your Watch starts sending you notifications you didn't ask for.

            RHR adapts slowly (8-12 weeks of consistent training). A sudden overnight spike of 5+ bpm is your body's polite way of saying "something's wrong"—illness, stress, or the classic overtraining-plus-bad-sleep combo. Listen to it.
            """
        case .vo2max:
            return """
            The gold standard of cardiorespiratory fitness: how many milliliters of oxygen you can transport and metabolize per kilogram of bodyweight per minute. It's your aerobic ceiling, the point where effort meets thermodynamic reality.

            Caveat emptor: Apple Watch estimates this from outdoor walks and runs with GPS. If you primarily hoist iron or spin indoors, you're seeing Plato's shadow on the cave wall, not the Form of Fitness itself.

            Improves glacially (3-6 weeks to detect signal), plateaus after 3-6 months of training, and declines about 1% per year after 30. The good news: even modest cardio bends the curve. The bad news: genetics sets the ceiling.
            """
        case .hrr:
            return """
            How fast your heart downshifts after exertion—specifically, the bpm drop in the first 60 seconds post-workout. It's your parasympathetic nervous system's return-to-baseline speed, the physiological equivalent of composure under pressure.

            Stoics would admire a high HRR: stress comes, stress goes, equilibrium restored. Fast recovery correlates with cardiovascular fitness and predicts longevity better than most metrics you'll encounter in a doctor's office.

            Improves in 6-12 weeks of training. If it tanks mid-session, consider it a biological tap-out—you've extracted the useful stimulus, and further effort yields diminishing returns.
            """
        }
    }

    // Today's values
    @State private var todayHRV: Double?
    @State private var todayRHR: Int?

    // Baselines
    @State private var hrvBaseline: HRVBaseline?
    @State private var rhrBaseline: (mean: Double, standardDeviation: Double, sampleCount: Int)?

    // History arrays (for charts)
    @State private var hrvHistory: [HRVReading] = []
    @State private var rhrHistory: [RestingHRReading] = []
    @State private var vo2maxHistory: [VO2maxReading] = []
    @State private var hrrHistory: [HRRecoveryReading] = []

    // Available metrics (only show tiles for metrics with data)
    private var availableMetrics: [CardiacMetric] {
        var metrics: [CardiacMetric] = [.hrv, .rhr]  // Always show HRV and RHR
        if !vo2maxHistory.isEmpty { metrics.append(.vo2max) }
        if !hrrHistory.isEmpty { metrics.append(.hrr) }
        return metrics
    }

    // MARK: - Computed Properties

    private var hrvDeviationPercent: Double? {
        guard let hrv = todayHRV, let baseline = hrvBaseline, baseline.isReliable else { return nil }
        return baseline.percentDeviation(for: hrv)
    }

    private var rhrDeviationBpm: Double? {
        guard let rhr = todayRHR, let baseline = rhrBaseline, baseline.sampleCount >= 5 else { return nil }
        return Double(rhr) - baseline.mean
    }

    private var latestVO2max: VO2maxReading? {
        vo2maxHistory.last
    }

    private var latestHRR: HRRecoveryReading? {
        hrrHistory.last
    }

    // MARK: - Filtered Data (respects time range)

    /// HRV data filtered by current time range with smart downsampling
    private var filteredHRVHistory: [HRVReading] {
        let range = currentTimeRange
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: Date()) ?? Date()
        let filtered = hrvHistory.filter { $0.date >= cutoff }

        // Downsample if too many points (performance optimization)
        // HRV: daily points <14d, 7-day avg for 14-60d, weekly for 60d+
        if range.days <= 14 {
            return filtered  // Daily granularity
        } else if range.days <= 60 {
            return downsampleHRVToDaily(filtered)  // One reading per day
        } else {
            return downsampleHRVToWeekly(filtered)  // Weekly averages
        }
    }

    /// RHR data filtered by current time range
    private var filteredRHRHistory: [RestingHRReading] {
        let range = currentTimeRange
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: Date()) ?? Date()
        return rhrHistory.filter { $0.date >= cutoff }
    }

    /// VO2max data filtered by current time range
    private var filteredVO2maxHistory: [VO2maxReading] {
        let range = currentTimeRange
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: Date()) ?? Date()
        return vo2maxHistory.filter { $0.date >= cutoff }
    }

    /// HRR data filtered by current time range
    private var filteredHRRHistory: [HRRecoveryReading] {
        let range = currentTimeRange
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: Date()) ?? Date()
        return hrrHistory.filter { $0.date >= cutoff }
    }

    // MARK: - Downsampling Helpers

    /// Downsample HRV to one reading per day (use daily average)
    private func downsampleHRVToDaily(_ readings: [HRVReading]) -> [HRVReading] {
        let calendar = Calendar.current
        var dailyGroups: [Date: [HRVReading]] = [:]

        for reading in readings {
            let dayStart = calendar.startOfDay(for: reading.date)
            dailyGroups[dayStart, default: []].append(reading)
        }

        return dailyGroups.map { (day, readings) in
            let avgHRV = readings.map { $0.hrvMs }.reduce(0, +) / Double(readings.count)
            return HRVReading(date: day, hrvMs: avgHRV)
        }.sorted { $0.date < $1.date }
    }

    /// Downsample HRV to weekly averages
    private func downsampleHRVToWeekly(_ readings: [HRVReading]) -> [HRVReading] {
        let calendar = Calendar.current
        var weeklyGroups: [Date: [HRVReading]] = [:]

        for reading in readings {
            // Get start of week
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reading.date)) ?? reading.date
            weeklyGroups[weekStart, default: []].append(reading)
        }

        return weeklyGroups.map { (weekStart, readings) in
            let avgHRV = readings.map { $0.hrvMs }.reduce(0, +) / Double(readings.count)
            // Use mid-week date for plotting
            let midWeek = calendar.date(byAdding: .day, value: 3, to: weekStart) ?? weekStart
            return HRVReading(date: midWeek, hrvMs: avgHRV)
        }.sorted { $0.date < $1.date }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { withAnimation(.airfit) { isExpanded.toggle() } }) {
                headerRow
            }
            .buttonStyle(.plain)

            // Metrics grid (2x2)
            metricsGrid

            // Expanded: tabbed charts
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                    ))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.error.opacity(0.06))
        )
        .sensoryFeedback(.selection, trigger: selectedMetric)
        .task {
            await loadData()
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.title3)
                .foregroundStyle(Theme.error)
                .symbolEffect(.pulse, options: .repeating, value: isLoading)

            VStack(alignment: .leading, spacing: 2) {
                Text("Cardiac Fitness")
                    .font(.labelHero)
                    .tracking(1)
                    .foregroundStyle(Theme.textMuted)

                if isLoading {
                    Text("Loading...")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textMuted)
                } else {
                    Text(statusSummary)
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
    }

    private var statusSummary: String {
        var parts: [String] = []

        if let deviation = hrvDeviationPercent {
            let sign = deviation >= 0 ? "+" : ""
            parts.append("HRV \(sign)\(Int(deviation))%")
        }

        if let rhr = todayRHR {
            parts.append("RHR \(rhr)")
        }

        if let vo2 = latestVO2max {
            parts.append("VO2 \(Int(vo2.vo2max))")
        }

        return parts.isEmpty ? "Tap to view" : parts.joined(separator: " • ")
    }

    // MARK: - Metrics Grid (2x2)

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(availableMetrics) { metric in
                metricTile(for: metric)
                    .onTapGesture {
                        withAnimation(.airfit) {
                            selectedMetric = metric
                            if !isExpanded {
                                isExpanded = true
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func metricTile(for metric: CardiacMetric) -> some View {
        let isSelected = selectedMetric == metric && isExpanded

        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: metric.icon)
                    .font(.caption2)
                    .foregroundStyle(metric.color)
                Text(metric.rawValue)
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            Text(valueText(for: metric))
                .font(.metricSmall)
                .foregroundStyle(valueColor(for: metric))

            Text(subtitleText(for: metric))
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? metric.color.opacity(0.12) : Theme.surface.opacity(0.5))
        )
    }

    private func valueText(for metric: CardiacMetric) -> String {
        switch metric {
        case .hrv:
            if let deviation = hrvDeviationPercent {
                let sign = deviation >= 0 ? "+" : ""
                return "\(sign)\(Int(deviation))%"
            }
            return todayHRV.map { "\(Int($0))" } ?? "—"

        case .rhr:
            return todayRHR.map { "\($0)" } ?? "—"

        case .vo2max:
            return latestVO2max.map { String(format: "%.1f", $0.vo2max) } ?? "—"

        case .hrr:
            return latestHRR.map { "\(Int($0.recoveryBpm))" } ?? "—"
        }
    }

    private func subtitleText(for metric: CardiacMetric) -> String {
        switch metric {
        case .hrv:
            if let baseline = hrvBaseline, baseline.isReliable {
                return "vs \(Int(baseline.mean)) avg"
            }
            return "ms"

        case .rhr:
            if let deviation = rhrDeviationBpm {
                let sign = deviation >= 0 ? "+" : ""
                return "\(sign)\(Int(deviation)) vs avg"
            }
            return "bpm"

        case .vo2max:
            return latestVO2max?.category.rawValue ?? "ml/kg/min"

        case .hrr:
            if let hrr = latestHRR {
                return zoneLabel(for: hrr.recoveryBpm)
            }
            return "bpm drop"
        }
    }

    private func valueColor(for metric: CardiacMetric) -> Color {
        switch metric {
        case .hrv:
            guard let deviation = hrvDeviationPercent else { return Theme.textMuted }
            switch deviation {
            case 5...: return Theme.success
            case -5..<5: return Theme.textSecondary
            case -15..<(-5): return Theme.warning
            default: return Theme.error
            }

        case .rhr:
            guard let deviation = rhrDeviationBpm else { return Theme.textMuted }
            switch deviation {
            case ...(-3): return Theme.success      // Lower is better
            case -3...3: return Theme.textSecondary
            case 3...8: return Theme.warning
            default: return Theme.error
            }

        case .vo2max:
            guard let vo2 = latestVO2max else { return Theme.textMuted }
            switch vo2.vo2max {
            case 50...: return Theme.success
            case 45..<50: return Color(hex: "84CC16")
            case 40..<45: return Theme.accent
            case 35..<40: return Theme.warning
            default: return Theme.error
            }

        case .hrr:
            guard let hrr = latestHRR else { return Theme.textMuted }
            switch hrr.recoveryBpm {
            case 40...: return Theme.success
            case 30..<40: return Color(hex: "84CC16")
            case 20..<30: return Theme.warning
            default: return Theme.error
            }
        }
    }

    private func zoneLabel(for bpm: Double) -> String {
        switch bpm {
        case 40...: return "Excellent"
        case 30..<40: return "Good"
        case 20..<30: return "OK"
        default: return "Poor"
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.vertical, 4)

            // Chart header with time range picker and info button
            HStack {
                // Metric name with info button
                HStack(spacing: 6) {
                    Image(systemName: selectedMetric.icon)
                        .font(.caption)
                        .foregroundStyle(selectedMetric.color)
                    Text(selectedMetric.rawValue)
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textPrimary)

                    Button {
                        showingTooltip = true
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                timeRangePicker
            }

            // Quality indicator legend
            qualityLegend

            // Active chart based on selection
            activeChart
        }
        .sensoryFeedback(.selection, trigger: currentTimeRange.rawValue)
        .sheet(isPresented: $showingTooltip) {
            MetricTooltipSheet(
                title: selectedMetric.rawValue,
                explanation: currentTooltip,
                color: selectedMetric.color
            )
            .presentationDragIndicator(.visible)
            .presentationBackground(Theme.surface)
        }
    }

    private var qualityLegend: some View {
        HStack(spacing: 12) {
            switch selectedMetric {
            case .hrv, .rhr:
                // Baseline-based legend
                legendItem(color: Theme.success, label: selectedMetric == .hrv ? "Above" : "Below")
                legendItem(color: Theme.textSecondary, label: "Normal")
                legendItem(color: Theme.warning, label: selectedMetric == .hrv ? "Low" : "Elevated")
            case .vo2max:
                // Zone legend (condensed)
                legendItem(color: Theme.success, label: "Good")
                legendItem(color: Theme.accent, label: "Avg")
                legendItem(color: Theme.warning, label: "Low")
            case .hrr:
                // Zone legend
                legendItem(color: Theme.success, label: "40+")
                legendItem(color: Color(hex: "84CC16"), label: "30-40")
                legendItem(color: Theme.warning, label: "20-30")
            }
            Spacer()
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)
        }
    }

    private var timeRangePicker: some View {
        HStack(spacing: 4) {
            ForEach(selectedMetric.availableRanges) { range in
                Button {
                    withAnimation(.airfit) {
                        timeRanges[selectedMetric] = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(currentTimeRange == range ? Theme.textPrimary : Theme.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(currentTimeRange == range ? Theme.surface : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.textMuted.opacity(0.1))
        )
    }

    @ViewBuilder
    private var activeChart: some View {
        switch selectedMetric {
        case .hrv:
            if !filteredHRVHistory.isEmpty {
                HRVDeviationChart(data: filteredHRVHistory, baseline: hrvBaseline)
                    .id("hrv-\(currentTimeRange.rawValue)")  // Force re-render on range change
            } else {
                emptyChartPlaceholder(for: .hrv)
            }

        case .rhr:
            if !filteredRHRHistory.isEmpty {
                RHRTrendChart(data: filteredRHRHistory, baseline: rhrBaseline)
                    .id("rhr-\(currentTimeRange.rawValue)")
            } else {
                emptyChartPlaceholder(for: .rhr)
            }

        case .vo2max:
            if !filteredVO2maxHistory.isEmpty {
                VO2maxTrendChart(data: filteredVO2maxHistory)
                    .id("vo2-\(currentTimeRange.rawValue)")
            } else {
                emptyChartPlaceholder(for: .vo2max)
            }

        case .hrr:
            if !filteredHRRHistory.isEmpty {
                HRRecoveryChart(data: filteredHRRHistory)
                    .id("hrr-\(currentTimeRange.rawValue)")
            } else {
                emptyChartPlaceholder(for: .hrr)
            }
        }
    }

    private func emptyChartPlaceholder(for metric: CardiacMetric) -> some View {
        VStack(spacing: 8) {
            Image(systemName: metric.icon)
                .font(.title2)
                .foregroundStyle(Theme.textMuted)

            Text("No \(metric.rawValue) data yet")
                .font(.labelMedium)
                .foregroundStyle(Theme.textMuted)

            Text(emptyStateHint(for: metric))
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func emptyStateHint(for metric: CardiacMetric) -> String {
        switch metric {
        case .hrv: return "HRV is recorded while you sleep with Apple Watch"
        case .rhr: return "Resting HR is measured throughout the day"
        case .vo2max: return "Do outdoor walks or runs with GPS to estimate VO2max"
        case .hrr: return "Complete workouts with Apple Watch to track recovery"
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true

        let today = Date()

        // Fetch data for each metric's max available time range
        // HRV: max 2 months (60 days)
        // RHR: max 1 year (365 days)
        // VO2max: all available
        // HRR: max 3 months (90 days)
        async let snapshotTask = healthKit.getDailySnapshot(for: today)
        async let hrvBaselineTask = healthKit.getHRVBaseline()
        async let rhrBaselineTask = healthKit.getRestingHRBaseline()
        async let hrvHistoryTask = healthKit.getHRVHistory(days: 60)      // Max range for HRV
        async let rhrHistoryTask = healthKit.getRestingHRHistoryAsReadings(days: 365)  // Max range for RHR
        async let vo2HistoryTask = healthKit.getAllVO2maxHistory()
        async let hrrHistoryTask = healthKit.getHRRecoveryHistory(days: 90)  // Max range for HRR

        let snapshot = await snapshotTask
        let hrvBase = await hrvBaselineTask
        let rhrBase = await rhrBaselineTask
        let hrvHist = await hrvHistoryTask
        let rhrHist = await rhrHistoryTask
        let vo2Hist = await vo2HistoryTask
        let hrrHist = await hrrHistoryTask

        await MainActor.run {
            withAnimation(.airfit) {
                todayHRV = snapshot.hrvMs
                todayRHR = snapshot.restingHR
                hrvBaseline = hrvBase
                rhrBaseline = rhrBase
                hrvHistory = hrvHist
                rhrHistory = rhrHist
                vo2maxHistory = vo2Hist
                hrrHistory = hrrHist
                isLoading = false
            }
        }
    }
}

// MARK: - Legacy Alias

typealias HeartMetricsCard = CardiacFitnessCard

#Preview("With Data") {
    VStack {
        CardiacFitnessCard()
    }
    .padding()
    .background(Theme.background)
}
