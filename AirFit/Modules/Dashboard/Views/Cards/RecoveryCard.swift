import SwiftUI
import Charts

struct RecoveryCard: View {
    let recoveryScore: RecoveryScore?

    @State private var animateRing = false
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

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
        LinearGradient(
            colors: [scoreColor.opacity(0.7), scoreColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
        GlassCard {
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
        }
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
                .foregroundStyle(.primary)
            Spacer()
            Text("\(recoveryScore?.score ?? 0)")
                .font(AppFonts.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: recoveryScore?.status.color == "green" ? [Color.green.opacity(0.8), Color.mint] :
                            recoveryScore?.status.color == "yellow" ? [Color.yellow.opacity(0.8), Color.orange.opacity(0.6)] :
                            [Color.orange.opacity(0.8), Color.red.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var componentsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            ForEach(recoveryScore?.factors ?? [], id: \.self) { factor in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green.opacity(0.8), Color.mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.caption)
                    Text(factor)
                        .font(AppFonts.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    private var noDataView: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: "heart.slash")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No recovery data")
                .font(AppFonts.caption)
                .foregroundStyle(.secondary)
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
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animatedProgress)
            Text(label)
                .font(AppFonts.headline)
                .foregroundStyle(.primary)
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
