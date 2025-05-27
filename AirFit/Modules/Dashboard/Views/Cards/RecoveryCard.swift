import SwiftUI
import Charts

struct RecoveryCard: View {
    let recoveryScore: RecoveryScore?

    @State private var animateRing = false

    private var progress: Double {
        Double(recoveryScore?.score ?? 0) / 100.0
    }

    private var scoreColor: Color {
        switch recoveryScore?.score ?? 0 {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .orange
        }
    }

    private var ringGradient: LinearGradient {
        LinearGradient(colors: [scoreColor.opacity(0.7), scoreColor], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let index: Int
        let value: Double
    }

    private var history: [ChartPoint] {
        guard let score = recoveryScore?.score else { return [] }
        return (0..<7).map { ChartPoint(index: $0, value: Double(score) * (1.0 - Double(6 - $0) * 0.03)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            header

            if let score = recoveryScore {
                HStack(spacing: AppSpacing.medium) {
                    ProgressRing(progress: animateRing ? progress : 0,
                                 gradient: ringGradient,
                                 lineWidth: 12,
                                 label: "\(score.score)")
                        .frame(width: 80, height: 80)

                    componentsView
                }

                Chart(history) { point in
                    LineMark(x: .value("Day", point.index),
                             y: .value("Score", point.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(scoreColor)
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
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateRing = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var header: some View {
        HStack {
            Label("Recovery", systemImage: "heart.fill")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            if let trend = recoveryScore?.trend {
                TrendIndicator(trend: trend)
            }
        }
    }

    private var componentsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            ForEach(recoveryScore?.components.prefix(3) ?? [], id: \.name) { component in
                HStack {
                    Text(component.name)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    ProgressView(value: component.value)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.accentColor))
                        .frame(width: 60)
                }
            }
        }
    }

    private var noDataView: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: "heart.slash")
                .font(.title)
                .foregroundColor(AppColors.textTertiary)
            Text("No recovery data")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private var accessibilityDescription: String {
        if let score = recoveryScore?.score {
            return "Recovery score \(score) out of 100"
        } else {
            return "No recovery data"
        }
    }
}

private struct ProgressRing: View {
    let progress: Double
    let gradient: LinearGradient
    let lineWidth: CGFloat
    let label: String

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.dividerColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animatedProgress)
            Text(label)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
        }
        .onAppear { animatedProgress = progress }
        .onChange(of: progress) { _, newValue in
            animatedProgress = newValue
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

