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

/// Inline expansion view for sleep - shows nightly hours
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
