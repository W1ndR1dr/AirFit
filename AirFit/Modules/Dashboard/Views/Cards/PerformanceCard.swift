import SwiftUI
import Charts

struct PerformanceCard: View {
    let insight: PerformanceInsight?

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let index: Int
        let value: Double
    }

    private var history: [ChartPoint] {
        guard let valueString = insight?.value,
              let value = Double(valueString) else { return [] }
        return (0..<7).map { ChartPoint(index: $0, value: value * (1.0 - Double(6 - $0) * 0.05)) }
    }

    var body: some View {
        StandardCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                header

                if let insight {
                    Text(insight.insight)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Text(insight.metric)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text(insight.value)
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.accentColor)
                    }

                    Chart(history) { point in
                        LineMark(x: .value("Day", point.index),
                                 y: .value("Value", point.value))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppColors.accentColor)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 40)
                } else {
                    noDataView
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var header: some View {
        HStack {
            Label("Performance", systemImage: "chart.line.uptrend.xyaxis")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            if let trend = insight?.trend {
                TrendIndicator(trend: trend)
            }
        }
    }

    private var noDataView: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: "chart.xyaxis.line")
                .font(.title)
                .foregroundColor(AppColors.textTertiary)
            Text("Building your insights…")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private var accessibilityDescription: String {
        if let insight {
            return "Performance trend for \(insight.metric) is \(insight.value)"
        } else {
            return "No performance data"
        }
    }
}

private struct TrendIndicator: View {
    let trend: Any

    private var icon: String {
        if let performanceTrend = trend as? PerformanceInsight.Trend {
            switch performanceTrend {
            case .improving: return "arrow.up.circle.fill"
            case .stable: return "minus.circle.fill"
            case .declining: return "arrow.down.circle.fill"
            }
        }
        return "minus.circle.fill"
    }

    private var color: Color {
        if let performanceTrend = trend as? PerformanceInsight.Trend {
            switch performanceTrend {
            case .improving: return .green
            case .stable: return .yellow
            case .declining: return .orange
            }
        }
        return .gray
    }

    var body: some View {
        Image(systemName: icon)
            .font(.caption)
            .foregroundColor(color)
    }
}
