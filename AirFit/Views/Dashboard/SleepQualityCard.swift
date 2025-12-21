import SwiftUI

/// Sleep quality card showing proportional stages with visual uncertainty.
///
/// Design principles from plan:
/// - **Proportions, not minutes**: "22% REM" not "1h 32m REM" (Apple Watch is 75-85% accurate)
/// - **Soft gradient edges**: Communicate stage boundary uncertainty
/// - **Bedtime consistency badge**: Strongest predictor of feeling rested
/// - **Anti-orthosomnia**: Weekly trends, not daily obsession
/// - **No push notifications** for sleep data
struct SleepQualityCard: View {
    let breakdowns: [SleepBreakdown]  // 7 nights of detailed data

    private let healthKit = HealthKitManager()

    @State private var bedtimeConsistency: BedtimeConsistency?
    @State private var isExpanded = false

    // Last night's data
    private var lastNight: SleepBreakdown? { breakdowns.last }

    // Week averages
    private var avgDuration: Double {
        guard !breakdowns.isEmpty else { return 0 }
        return breakdowns.reduce(0) { $0 + $1.totalSleep } / Double(breakdowns.count)
    }

    private var avgEfficiency: Double {
        guard !breakdowns.isEmpty else { return 0 }
        return breakdowns.reduce(0) { $0 + $1.efficiency } / Double(breakdowns.count)
    }

    // Goal hit rate
    private var goalHitCount: Int {
        breakdowns.filter { $0.totalSleep >= 7.5 }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { withAnimation(.airfit) { isExpanded.toggle() } }) {
                headerRow
            }
            .buttonStyle(.plain)

            // Proportional stage bar with gradient edges
            if let breakdown = lastNight {
                proportionalStageBar(breakdown)
            }

            // Expanded: 7-night trend + consistency
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
                .fill(Theme.sleepDeep.opacity(0.08))
        )
        .task {
            await loadBedtimeConsistency()
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: "moon.fill")
                .font(.title3)
                .foregroundStyle(Theme.sleepDeep)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep Quality")
                    .font(.labelHero)
                    .tracking(1)
                    .foregroundStyle(Theme.textMuted)

                // Last night summary
                if let breakdown = lastNight {
                    HStack(spacing: 8) {
                        Text(formatHours(breakdown.totalSleep))
                            .font(.metricSmall)
                            .foregroundStyle(Theme.textPrimary)

                        Text("•")
                            .foregroundStyle(Theme.textMuted)

                        Text("\(Int(breakdown.efficiency))% eff")
                            .font(.labelMedium)
                            .foregroundStyle(efficiencyColor(breakdown.efficiency))
                    }
                }
            }

            Spacer()

            // Bedtime consistency badge
            if let consistency = bedtimeConsistency {
                consistencyBadge(consistency)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
    }

    // MARK: - Proportional Stage Bar

    /// Safe division helper to prevent crash when totalSleep is 0
    private func safeProportion(_ part: Double, of total: Double) -> Double {
        total > 0 ? part / total : 0
    }

    @ViewBuilder
    private func proportionalStageBar(_ breakdown: SleepBreakdown) -> some View {
        // Guard against division by zero when no sleep stage data available
        if breakdown.totalSleep > 0 {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Deep sleep (most restorative)
                    stageSegment(
                        proportion: safeProportion(breakdown.deepSleep, of: breakdown.totalSleep),
                        color: Theme.sleepDeep,
                        width: geo.size.width,
                        isFirst: true
                    )

                    // REM sleep
                    stageSegment(
                        proportion: safeProportion(breakdown.remSleep, of: breakdown.totalSleep),
                        color: Theme.sleepREM,
                        width: geo.size.width
                    )

                    // Core/light sleep
                    stageSegment(
                        proportion: safeProportion(breakdown.coreSleep, of: breakdown.totalSleep),
                        color: Theme.sleepCore,
                        width: geo.size.width,
                        isLast: true
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(height: 24)
        } else {
            // Fallback when no sleep stage data (only "in bed" recorded)
            HStack(spacing: 8) {
                Image(systemName: "moon.zzz")
                    .foregroundStyle(Theme.textMuted)
                Text("No stage data")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
            .frame(height: 24)
        }
    }

    private func stageSegment(
        proportion: Double,
        color: Color,
        width: CGFloat,
        isFirst: Bool = false,
        isLast: Bool = false
    ) -> some View {
        // Gradient for soft edges to communicate uncertainty
        let gradient = LinearGradient(
            stops: [
                .init(color: color.opacity(isFirst ? 1 : 0.7), location: 0),
                .init(color: color, location: 0.15),
                .init(color: color, location: 0.85),
                .init(color: color.opacity(isLast ? 1 : 0.7), location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        return Rectangle()
            .fill(gradient)
            .frame(width: max(4, width * proportion))
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.vertical, 4)

            // Stage proportions as percentages
            if let breakdown = lastNight {
                stageProportionLegend(breakdown)
            }

            // 7-night mini bars
            sevenNightBars

            // Goal hit rate
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.success)
                Text("\(goalHitCount) of \(breakdowns.count) nights hit 7.5h goal")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func stageProportionLegend(_ breakdown: SleepBreakdown) -> some View {
        if breakdown.totalSleep > 0 {
            HStack(spacing: 16) {
                stageLegendItem("Deep", proportion: safeProportion(breakdown.deepSleep, of: breakdown.totalSleep), color: Theme.sleepDeep)
                stageLegendItem("REM", proportion: safeProportion(breakdown.remSleep, of: breakdown.totalSleep), color: Theme.sleepREM)
                stageLegendItem("Core", proportion: safeProportion(breakdown.coreSleep, of: breakdown.totalSleep), color: Theme.sleepCore)
            }
        } else {
            Text("No sleep stage breakdown available")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
    }

    private func stageLegendItem(_ name: String, proportion: Double, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
                Text("\(Int(proportion * 100))%")
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textPrimary)
            }
        }
    }

    private var sevenNightBars: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(breakdowns.enumerated()), id: \.offset) { index, breakdown in
                VStack(spacing: 4) {
                    // Mini stacked bar
                    miniStackedBar(breakdown)
                        .frame(width: 24)

                    // Day label (uses actual breakdown date, not calculated from index)
                    Text(dayLabel(for: breakdown.date))
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }

    private func miniStackedBar(_ breakdown: SleepBreakdown) -> some View {
        GeometryReader { geo in
            let total = breakdown.totalSleep
            let maxHeight = geo.size.height

            VStack(spacing: 0) {
                Spacer()

                if total > 0 {
                    // Scale to max ~10 hours
                    let scaleFactor = min(1, total / 10)

                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Theme.sleepDeep)
                            .frame(height: maxHeight * scaleFactor * safeProportion(breakdown.deepSleep, of: total))

                        Rectangle()
                            .fill(Theme.sleepREM)
                            .frame(height: maxHeight * scaleFactor * safeProportion(breakdown.remSleep, of: total))

                        Rectangle()
                            .fill(Theme.sleepCore)
                            .frame(height: maxHeight * scaleFactor * safeProportion(breakdown.coreSleep, of: total))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    // No sleep data for this night
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.textMuted.opacity(0.2))
                        .frame(height: 4)
                }
            }
        }
        .frame(height: 50)
    }

    // MARK: - Helpers

    private func consistencyBadge(_ consistency: BedtimeConsistency) -> some View {
        HStack(spacing: 4) {
            Image(systemName: consistencyIcon(consistency.category))
                .font(.caption2)
            Text(consistency.category.rawValue)
                .font(.labelMicro)
        }
        .foregroundStyle(consistencyColor(consistency.category))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(consistencyColor(consistency.category).opacity(0.12))
        )
    }

    private func consistencyIcon(_ category: BedtimeConsistency.ConsistencyCategory) -> String {
        switch category {
        case .stable: return "checkmark.circle.fill"
        case .variable: return "arrow.left.arrow.right"
        case .irregular: return "exclamationmark.circle"
        }
    }

    private func consistencyColor(_ category: BedtimeConsistency.ConsistencyCategory) -> Color {
        switch category {
        case .stable: return Theme.success
        case .variable: return Theme.warning
        case .irregular: return Theme.error
        }
    }

    private func efficiencyColor(_ efficiency: Double) -> Color {
        switch efficiency {
        case 90...: return Theme.success
        case 80..<90: return Theme.textSecondary
        case 70..<80: return Theme.warning
        default: return Theme.error
        }
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h\(m > 0 ? " \(m)m" : "")"
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }

    private func loadBedtimeConsistency() async {
        bedtimeConsistency = await healthKit.getBedtimeConsistency(days: 7)
    }
}

#Preview {
    VStack {
        SleepQualityCard(breakdowns: [
            SleepBreakdown(date: Date(), timeInBed: 8, totalSleep: 7.2, remSleep: 1.5, deepSleep: 1.8, coreSleep: 3.9, awakeTime: 0.8),
            SleepBreakdown(date: Date(), timeInBed: 7.5, totalSleep: 6.8, remSleep: 1.3, deepSleep: 1.5, coreSleep: 4.0, awakeTime: 0.7),
            SleepBreakdown(date: Date(), timeInBed: 8.2, totalSleep: 7.5, remSleep: 1.7, deepSleep: 2.0, coreSleep: 3.8, awakeTime: 0.7)
        ])
    }
    .padding()
    .background(Theme.background)
}
