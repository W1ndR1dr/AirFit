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
        guard let value = insight?.value else { return [] }
        return (0..<7).map { ChartPoint(index: $0, value: value * (1.0 - Double(6 - $0) * 0.05)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            header

            if let insight {
                Text(insight.summary)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(insight.keyMetric)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("\(insight.value, specifier: "%.1f")")
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
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(AppConstants.Layout.defaultCornerRadius)
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
            return "Performance trend for \(insight.keyMetric) is \(String(format: "%.1f", insight.value))"
        } else {
            return "No performance data"
        }
    }
}

private struct TrendIndicator: View {
    let trend: Any

    private var icon: String {
        if let recoveryTrend = trend as? RecoveryScore.Trend {
            switch recoveryTrend {
            case .improving: return "arrow.up.circle.fill"
            case .steady: return "minus.circle.fill"
            case .declining: return "arrow.down.circle.fill"
            }
        } else if let performanceTrend = trend as? PerformanceInsight.Trend {
            switch performanceTrend {
            case .up: return "arrow.up.circle.fill"
            case .steady: return "minus.circle.fill"
            case .down: return "arrow.down.circle.fill"
            }
        }
        return "minus.circle.fill"
    }

    private var color: Color {
        if let recoveryTrend = trend as? RecoveryScore.Trend {
            switch recoveryTrend {
            case .improving: return .green
            case .steady: return .yellow
            case .declining: return .orange
            }
        } else if let performanceTrend = trend as? PerformanceInsight.Trend {
            switch performanceTrend {
            case .up: return .green
            case .steady: return .yellow
            case .down: return .orange
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


