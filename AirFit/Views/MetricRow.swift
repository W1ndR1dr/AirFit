import SwiftUI

/// Type of metric for expansion tracking
enum MetricType: String, CaseIterable {
    case weight
    case protein
    case calories
    case sleep
    case workouts
}

/// Chart style for the metric row
enum ChartStyle {
    case line                    // Trend line (weight - direction matters)
    case bars                    // Discrete bars (workouts)
    case goalBars(target: Double) // Goal-based colored bars (protein, calories, sleep)
}

// Legacy alias for compatibility
typealias SparklineStyle = ChartStyle

/// A tappable metric row with inline sparkline
struct MetricRow: View {
    let label: String
    let value: String
    let unit: String
    let sparklineData: [Double]
    let color: Color
    let sparklineStyle: SparklineStyle
    let isExpanded: Bool
    let onTap: () -> Void

    init(
        label: String,
        value: String,
        unit: String,
        sparklineData: [Double],
        color: Color,
        sparklineStyle: SparklineStyle = .line,
        isExpanded: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.label = label
        self.value = value
        self.unit = unit
        self.sparklineData = sparklineData
        self.color = color
        self.sparklineStyle = sparklineStyle
        self.isExpanded = isExpanded
        self.onTap = onTap
    }

    var body: some View {
        HStack(spacing: 12) {
            // Label
            Text(label)
                .font(.labelMedium)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 70, alignment: .leading)

            // Chart
            Group {
                switch sparklineStyle {
                case .line:
                    MiniSparkline(data: sparklineData, color: color.opacity(0.7))
                case .bars:
                    MiniBarSparkline(data: sparklineData, color: color.opacity(0.7))
                case .goalBars(let target):
                    GoalBarChart(data: sparklineData, target: target, baseColor: color)
                }
            }

            Spacer()

            // Value + unit
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.metricSmall)
                    .foregroundStyle(color)
                Text(unit)
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            // Chevron (rotates when expanded)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Theme.textMuted)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.spring(response: 0.3), value: isExpanded)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                onTap()
            }
        }
    }
}

/// Inline expansion view for protein/calories - shows daily breakdown
struct NutritionDetailView: View {
    let label: String
    let dailyValues: [Double]  // 7 days, oldest to newest
    let target: Double
    let unit: String
    let color: Color

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(spacing: 12) {
            // Day labels
            HStack(spacing: 0) {
                ForEach(recentDayLabels(), id: \.self) { day in
                    Text(day)
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            // Values
            HStack(spacing: 0) {
                ForEach(Array(paddedValues().enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 4) {
                        Text(value > 0 ? "\(Int(value))" : "—")
                            .font(.labelMedium)
                            .foregroundStyle(value > 0 ? Theme.textPrimary : Theme.textMuted)

                        // Hit/miss indicator
                        if value > 0 {
                            Image(systemName: value >= target * 0.9 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(value >= target * 0.9 ? Theme.success : Theme.error.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Target reference
            HStack {
                Spacer()
                Text("Target: \(Int(target))\(unit)")
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.06))
        )
    }

    /// Get day labels for the last 7 days
    private func recentDayLabels() -> [String] {
        let calendar = Calendar.current
        let today = Date()
        var labels: [String] = []

        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let weekday = calendar.component(.weekday, from: date)
                // weekday: 1 = Sunday, 2 = Monday, etc.
                let dayIndex = (weekday + 5) % 7  // Convert to Mon=0
                labels.append(dayLabels[dayIndex])
            }
        }
        return labels
    }

    /// Ensure we have 7 values (pad with 0 if needed)
    private func paddedValues() -> [Double] {
        if dailyValues.count >= 7 {
            return Array(dailyValues.suffix(7))
        }
        let padding = Array(repeating: 0.0, count: 7 - dailyValues.count)
        return padding + dailyValues
    }
}

/// Inline expansion view for sleep - shows nightly hours (legacy, used as fallback)
struct SleepDetailView: View {
    let dailyValues: [Double]  // 7 nights of sleep hours

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(spacing: 12) {
            // Day labels
            HStack(spacing: 0) {
                ForEach(recentDayLabels(), id: \.self) { day in
                    Text(day)
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            // Visual bars + values
            HStack(spacing: 0) {
                ForEach(Array(paddedValues().enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 4) {
                        // Bar representation
                        RoundedRectangle(cornerRadius: 3)
                            .fill(sleepColor(for: value))
                            .frame(width: 8, height: barHeight(for: value))

                        // Hours
                        Text(value > 0 ? String(format: "%.1f", value) : "—")
                            .font(.labelMicro)
                            .foregroundStyle(value > 0 ? Theme.textSecondary : Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60, alignment: .bottom)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.indigo.opacity(0.06))
        )
    }

    private func recentDayLabels() -> [String] {
        let calendar = Calendar.current
        let today = Date()
        var labels: [String] = []

        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let weekday = calendar.component(.weekday, from: date)
                let dayIndex = (weekday + 5) % 7
                labels.append(dayLabels[dayIndex])
            }
        }
        return labels
    }

    private func paddedValues() -> [Double] {
        if dailyValues.count >= 7 {
            return Array(dailyValues.suffix(7))
        }
        let padding = Array(repeating: 0.0, count: 7 - dailyValues.count)
        return padding + dailyValues
    }

    private func barHeight(for hours: Double) -> CGFloat {
        guard hours > 0 else { return 4 }
        // Scale: 4hrs = 10pt, 10hrs = 40pt
        let normalized = min(1, max(0, (hours - 4) / 6))
        return 10 + CGFloat(normalized) * 30
    }

    private func sleepColor(for hours: Double) -> Color {
        guard hours > 0 else { return Color.indigo.opacity(0.2) }
        if hours >= 7.5 { return Theme.success }
        if hours >= 6.5 { return Color.indigo }
        return Theme.warning
    }
}

// MARK: - Sleep Breakdown View

/// Enhanced sleep detail view showing stage breakdown with stacked bars
struct SleepBreakdownView: View {
    let breakdowns: [SleepBreakdown]  // 7 nights of detailed data
    let dailyValues: [Double]  // Fallback simple hours if breakdown unavailable

    // Sleep stage colors
    private let remColor = Color(red: 0.6, green: 0.4, blue: 0.9)      // Purple-ish
    private let deepColor = Color(red: 0.2, green: 0.4, blue: 0.8)     // Deep blue
    private let coreColor = Color(red: 0.4, green: 0.6, blue: 0.9)     // Light blue
    private let awakeColor = Color.orange.opacity(0.6)

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(spacing: 16) {
            // Last night summary (if available)
            if let lastNight = breakdowns.last {
                lastNightSummary(lastNight)
            }

            Divider()
                .background(Theme.textMuted.opacity(0.2))

            // Weekly stacked bars
            weeklyBreakdown
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.indigo.opacity(0.06))
        )
    }

    // MARK: - Last Night Summary

    private func lastNightSummary(_ breakdown: SleepBreakdown) -> some View {
        VStack(spacing: 12) {
            // Header row
            HStack {
                Text("Last Night")
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                // Efficiency badge
                HStack(spacing: 4) {
                    Image(systemName: efficiencyIcon(breakdown.efficiency))
                        .font(.system(size: 10))
                    Text("\(Int(breakdown.efficiency))% efficient")
                        .font(.labelMicro)
                }
                .foregroundStyle(efficiencyColor(breakdown.efficiency))
            }

            // Time in bed vs actual sleep
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("In Bed")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                    Text(formatHours(breakdown.timeInBed))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Asleep")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                    Text(formatHours(breakdown.totalSleep))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()
            }

            // Stacked horizontal bar
            GeometryReader { geo in
                HStack(spacing: 1) {
                    // Deep sleep (most restorative)
                    if breakdown.deepSleep > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(deepColor)
                            .frame(width: barWidth(breakdown.deepSleep, total: breakdown.timeInBed, availableWidth: geo.size.width))
                    }

                    // REM sleep
                    if breakdown.remSleep > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(remColor)
                            .frame(width: barWidth(breakdown.remSleep, total: breakdown.timeInBed, availableWidth: geo.size.width))
                    }

                    // Core/light sleep
                    if breakdown.coreSleep > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(coreColor)
                            .frame(width: barWidth(breakdown.coreSleep, total: breakdown.timeInBed, availableWidth: geo.size.width))
                    }

                    // Awake time
                    if breakdown.awakeTime > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(awakeColor)
                            .frame(width: barWidth(breakdown.awakeTime, total: breakdown.timeInBed, availableWidth: geo.size.width))
                    }
                }
            }
            .frame(height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Legend
            HStack(spacing: 12) {
                legendItem(color: deepColor, label: "Deep", value: breakdown.deepSleep)
                legendItem(color: remColor, label: "REM", value: breakdown.remSleep)
                legendItem(color: coreColor, label: "Core", value: breakdown.coreSleep)
                if breakdown.awakeTime > 0.1 {
                    legendItem(color: awakeColor, label: "Awake", value: breakdown.awakeTime)
                }
                Spacer()
            }
        }
    }

    private func legendItem(color: Color, label: String, value: Double) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label) \(formatHoursShort(value))")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textMuted)
        }
    }

    // MARK: - Weekly Breakdown

    private var weeklyBreakdown: some View {
        VStack(spacing: 8) {
            // Day labels
            HStack(spacing: 0) {
                ForEach(recentDayLabels(), id: \.self) { day in
                    Text(day)
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            // Stacked mini bars for each day
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    if index < breakdowns.count {
                        miniStackedBar(breakdowns[index])
                    } else if index < dailyValues.count {
                        // Fallback to simple bar
                        simpleMiniBar(dailyValues[index])
                    } else {
                        emptyMiniBar
                    }
                }
            }
            .frame(height: 50)

            // Hours labels
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    if index < breakdowns.count {
                        Text(formatHoursShort(breakdowns[index].totalSleep))
                            .font(.labelMicro)
                            .foregroundStyle(sleepColor(for: breakdowns[index].totalSleep))
                            .frame(maxWidth: .infinity)
                    } else if index < dailyValues.count && dailyValues[index] > 0 {
                        Text(formatHoursShort(dailyValues[index]))
                            .font(.labelMicro)
                            .foregroundStyle(sleepColor(for: dailyValues[index]))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("—")
                            .font(.labelMicro)
                            .foregroundStyle(Theme.textMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func miniStackedBar(_ breakdown: SleepBreakdown) -> some View {
        let total = breakdown.timeInBed
        let maxHeight: CGFloat = 50

        return VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 0) {
                // Awake (if significant)
                if breakdown.awakeTime > 0.1 {
                    Rectangle()
                        .fill(awakeColor)
                        .frame(height: stageHeight(breakdown.awakeTime, total: total, maxHeight: maxHeight * 0.8))
                }

                // Core
                Rectangle()
                    .fill(coreColor)
                    .frame(height: stageHeight(breakdown.coreSleep, total: total, maxHeight: maxHeight * 0.8))

                // REM
                Rectangle()
                    .fill(remColor)
                    .frame(height: stageHeight(breakdown.remSleep, total: total, maxHeight: maxHeight * 0.8))

                // Deep (at bottom - most important)
                Rectangle()
                    .fill(deepColor)
                    .frame(height: stageHeight(breakdown.deepSleep, total: total, maxHeight: maxHeight * 0.8))
            }
            .frame(height: barTotalHeight(breakdown.totalSleep, maxHeight: maxHeight))
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .frame(maxWidth: .infinity)
    }

    private func simpleMiniBar(_ hours: Double) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.indigo)
                .frame(height: barTotalHeight(hours, maxHeight: 50))
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyMiniBar: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.indigo.opacity(0.2))
                .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }

    private func formatHoursShort(_ hours: Double) -> String {
        return String(format: "%.1f", hours)
    }

    private func barWidth(_ stage: Double, total: Double, availableWidth: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        return (stage / total) * availableWidth
    }

    private func stageHeight(_ stage: Double, total: Double, maxHeight: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        return (stage / total) * maxHeight
    }

    private func barTotalHeight(_ hours: Double, maxHeight: CGFloat) -> CGFloat {
        guard hours > 0 else { return 4 }
        // Scale: 4hrs = 20%, 10hrs = 100%
        let normalized = min(1, max(0, (hours - 4) / 6))
        return max(8, normalized * maxHeight)
    }

    private func sleepColor(for hours: Double) -> Color {
        guard hours > 0 else { return Theme.textMuted }
        if hours >= 7.5 { return Theme.success }
        if hours >= 6.5 { return Color.indigo }
        return Theme.warning
    }

    private func efficiencyIcon(_ efficiency: Double) -> String {
        if efficiency >= 90 { return "star.fill" }
        if efficiency >= 80 { return "checkmark.circle.fill" }
        return "moon.zzz.fill"
    }

    private func efficiencyColor(_ efficiency: Double) -> Color {
        if efficiency >= 90 { return Theme.success }
        if efficiency >= 80 { return Color.indigo }
        return Theme.warning
    }

    private func recentDayLabels() -> [String] {
        let calendar = Calendar.current
        let today = Date()
        var labels: [String] = []

        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let weekday = calendar.component(.weekday, from: date)
                let dayIndex = (weekday + 5) % 7
                labels.append(dayLabels[dayIndex])
            }
        }
        return labels
    }
}

#Preview("MetricRows") {
    VStack(spacing: 0) {
        // Weight - trend line (direction matters)
        MetricRow(
            label: "Weight",
            value: "172.8",
            unit: "lbs",
            sparklineData: [174.5, 174.2, 173.8, 174.0, 173.5, 173.2, 172.8],
            color: Theme.accent,
            sparklineStyle: .line,
            isExpanded: false
        ) {}

        Divider().padding(.leading, 70)

        // Protein - goal bars (target: 175g)
        MetricRow(
            label: "Protein",
            value: "165",
            unit: "g avg",
            sparklineData: [180, 165, 148, 190, 142, 178, 155],
            color: Theme.protein,
            sparklineStyle: .goalBars(target: 175),
            isExpanded: true
        ) {}

        NutritionDetailView(
            label: "Protein",
            dailyValues: [180, 165, 148, 190, 142, 178, 155],
            target: 175,
            unit: "g",
            color: Theme.protein
        )
        .padding(.horizontal, 4)
        .padding(.bottom, 8)

        Divider().padding(.leading, 70)

        // Calories - goal bars (target: 2600)
        MetricRow(
            label: "Calories",
            value: "2,480",
            unit: "avg",
            sparklineData: [2650, 2400, 2100, 2800, 2550, 2700, 2450],
            color: Theme.calories,
            sparklineStyle: .goalBars(target: 2600),
            isExpanded: false
        ) {}

        Divider().padding(.leading, 70)

        // Sleep - goal bars (target: 7.5h)
        MetricRow(
            label: "Sleep",
            value: "7.2",
            unit: "hrs",
            sparklineData: [7.5, 6.8, 8.1, 7.0, 5.9, 7.8, 7.5],
            color: Color.indigo,
            sparklineStyle: .goalBars(target: 7.5),
            isExpanded: false
        ) {}

        Divider().padding(.leading, 70)

        // Workouts - discrete bars
        MetricRow(
            label: "Workouts",
            value: "4",
            unit: "",
            sparklineData: [0, 1, 0, 1, 0, 1, 1],
            color: Theme.secondary,
            sparklineStyle: .bars,
            isExpanded: false
        ) {}
    }
    .padding(20)
    .background(Theme.surface)
    .cornerRadius(20)
    .padding()
    .background(Theme.background)
}
