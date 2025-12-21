import SwiftUI

/// Heart metrics card showing HRV and Resting HR with baseline context.
///
/// Design principles from plan:
/// - HRV shown as **% deviation from baseline** (single-day HRV is noise)
/// - Resting HR shown with trend indicator
/// - 7-day rolling baseline with confidence indicator
/// - Expandable for detailed trend charts
struct HeartMetricsCard: View {
    private let healthKit = HealthKitManager()

    @State private var todayHRV: Double?
    @State private var hrvBaseline: HRVBaseline?
    @State private var todayRHR: Int?
    @State private var rhrBaseline: (mean: Double, standardDeviation: Double, sampleCount: Int)?
    @State private var isLoading = true
    @State private var isExpanded = false

    // Computed HRV deviation
    private var hrvDeviationPercent: Double? {
        guard let hrv = todayHRV, let baseline = hrvBaseline, baseline.isReliable else { return nil }
        return baseline.percentDeviation(for: hrv)
    }

    // Computed RHR deviation
    private var rhrDeviationBpm: Double? {
        guard let rhr = todayRHR, let baseline = rhrBaseline, baseline.sampleCount >= 5 else { return nil }
        return Double(rhr) - baseline.mean
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { withAnimation(.airfit) { isExpanded.toggle() } }) {
                headerRow
            }
            .buttonStyle(.plain)

            // Metrics row
            metricsRow

            // Expanded: trend charts
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
        .task {
            await loadData()
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 8) {
            // Heart icon
            Image(systemName: "heart.fill")
                .font(.title3)
                .foregroundStyle(Theme.error)
                .symbolEffect(.pulse, options: .repeating, value: isLoading)

            VStack(alignment: .leading, spacing: 2) {
                Text("Heart & Recovery")
                    .font(.labelHero)
                    .tracking(1)
                    .foregroundStyle(Theme.textMuted)

                // Status summary
                if isLoading {
                    Text("Loading...")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textMuted)
                } else if hrvBaseline == nil || !(hrvBaseline?.isReliable ?? false) {
                    Text("Building baseline...")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textMuted)
                } else {
                    Text(statusSummary)
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            // Chevron
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

        return parts.joined(separator: " • ")
    }

    // MARK: - Metrics Row

    private var metricsRow: some View {
        HStack(spacing: 0) {
            // HRV metric
            metricTile(
                title: "HRV",
                value: hrvValueText,
                subtitle: hrvSubtitleText,
                color: hrvColor,
                icon: "waveform.path.ecg"
            )

            // Divider
            Rectangle()
                .fill(Theme.textMuted.opacity(0.2))
                .frame(width: 1, height: 50)

            // Resting HR metric
            metricTile(
                title: "Resting HR",
                value: rhrValueText,
                subtitle: rhrSubtitleText,
                color: rhrColor,
                icon: "heart.fill"
            )
        }
    }

    private func metricTile(title: String, value: String, subtitle: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            Text(value)
                .font(.metricSmall)
                .foregroundStyle(color)

            Text(subtitle)
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Values

    private var hrvValueText: String {
        guard let deviation = hrvDeviationPercent else {
            return todayHRV.map { "\(Int($0))" } ?? "—"
        }
        let sign = deviation >= 0 ? "+" : ""
        return "\(sign)\(Int(deviation))%"
    }

    private var hrvSubtitleText: String {
        guard let baseline = hrvBaseline, baseline.isReliable else {
            return "vs baseline"
        }
        return "vs \(Int(baseline.mean)) avg"
    }

    private var hrvColor: Color {
        guard let deviation = hrvDeviationPercent else { return Theme.textMuted }

        switch deviation {
        case 5...: return Theme.success       // Above baseline = good
        case -5..<5: return Theme.textSecondary  // Normal range
        case -15..<(-5): return Theme.warning   // Slightly below
        default: return Theme.error           // Significantly below
        }
    }

    private var rhrValueText: String {
        guard let rhr = todayRHR else { return "—" }
        return "\(rhr)"
    }

    private var rhrSubtitleText: String {
        guard let deviation = rhrDeviationBpm else { return "bpm" }
        let sign = deviation >= 0 ? "+" : ""
        return "\(sign)\(Int(deviation)) vs avg"
    }

    private var rhrColor: Color {
        guard let deviation = rhrDeviationBpm else { return Theme.textMuted }

        switch deviation {
        case ...(-3): return Theme.success      // Below baseline = good
        case -3...3: return Theme.textSecondary // Normal range
        case 3...8: return Theme.warning        // Slightly elevated
        default: return Theme.error             // Significantly elevated
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.vertical, 4)

            // Baseline info
            if let baseline = hrvBaseline, baseline.isReliable {
                HStack(spacing: 16) {
                    baselineInfo("HRV Baseline", value: "\(Int(baseline.mean)) ms", detail: "CV: \(Int(baseline.coefficientOfVariation * 100))%")
                    if let rhrBase = rhrBaseline, rhrBase.sampleCount >= 5 {
                        baselineInfo("RHR Baseline", value: "\(Int(rhrBase.mean)) bpm", detail: "±\(Int(rhrBase.standardDeviation))")
                    }
                }
            }

            // Placeholder for trend charts (Phase 4 continued)
            Text("Trend charts coming soon")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        }
    }

    private func baselineInfo(_ title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)
            Text(value)
                .font(.labelMedium)
                .foregroundStyle(Theme.textPrimary)
            Text(detail)
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true

        let today = Date()
        async let snapshotTask = healthKit.getDailySnapshot(for: today)
        async let hrvBaselineTask = healthKit.getHRVBaseline()
        async let rhrBaselineTask = healthKit.getRestingHRBaseline()

        let snapshot = await snapshotTask
        let hrvBase = await hrvBaselineTask
        let rhrBase = await rhrBaselineTask

        await MainActor.run {
            withAnimation(.airfit) {
                todayHRV = snapshot.hrvMs
                todayRHR = snapshot.restingHR
                hrvBaseline = hrvBase
                rhrBaseline = rhrBase
                isLoading = false
            }
        }
    }
}

#Preview {
    VStack {
        HeartMetricsCard()
    }
    .padding()
    .background(Theme.background)
}
