import SwiftUI

/// Compact sparkline for inline metric display (60×24pt)
struct MiniSparkline: View {
    let data: [Double]
    let color: Color
    var showDots: Bool = false

    var body: some View {
        GeometryReader { geo in
            if data.count >= 2 {
                let (minVal, _, range) = computeRange()

                ZStack {
                    // Line path
                    Path { path in
                        for (index, value) in data.enumerated() {
                            let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                            let y = geo.size.height * (1 - normalizedY(value, min: minVal, range: range))

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Optional dots at endpoints
                    if showDots {
                        // Start dot
                        Circle()
                            .fill(color.opacity(0.5))
                            .frame(width: 4, height: 4)
                            .position(
                                x: 0,
                                y: geo.size.height * (1 - normalizedY(data.first!, min: minVal, range: range))
                            )

                        // End dot (current value)
                        Circle()
                            .fill(color)
                            .frame(width: 5, height: 5)
                            .position(
                                x: geo.size.width,
                                y: geo.size.height * (1 - normalizedY(data.last!, min: minVal, range: range))
                            )
                    }
                }
            } else if data.count == 1 {
                // Single point - show as centered dot
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            // Empty data shows nothing
        }
        .frame(width: 60, height: 24)
    }

    private func computeRange() -> (min: Double, max: Double, range: Double) {
        let minVal = data.min() ?? 0
        let maxVal = data.max() ?? 0
        let range = maxVal - minVal
        // Ensure minimum range to avoid flat lines
        let safeRange = range > 0 ? range : 1
        return (minVal, maxVal, safeRange)
    }

    // Note: maxVal from computeRange() is used in the return tuple for potential future use

    private func normalizedY(_ value: Double, min: Double, range: Double) -> CGFloat {
        // Add 10% padding top/bottom for visual breathing room
        let padding = 0.1
        let normalized = (value - min) / range
        return CGFloat(padding + normalized * (1 - 2 * padding))
    }
}

/// Bar-style sparkline for discrete values (like workout days)
struct MiniBarSparkline: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let maxVal = data.max() ?? 1
            let barWidth = (geo.size.width - CGFloat(data.count - 1) * 2) / CGFloat(data.count)

            HStack(spacing: 2) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(value > 0 ? color : color.opacity(0.15))
                        .frame(
                            width: barWidth,
                            height: value > 0 ? max(4, geo.size.height * CGFloat(value / maxVal)) : 4
                        )
                        .frame(height: geo.size.height, alignment: .bottom)
                }
            }
        }
        .frame(width: 60, height: 24)
    }
}

/// Goal-based bar chart with color coding (60×24pt)
/// Shows daily values against a target with visual feedback:
/// - Muted: <80% of target (missed)
/// - Amber: 80-99% (close but under)
/// - Green: 100-110% (hit target)
/// - Bright: >110% (surplus banked)
struct GoalBarChart: View {
    let data: [Double]  // Daily values (7 days)
    let target: Double
    let baseColor: Color

    var body: some View {
        GeometryReader { geo in
            let barWidth = (geo.size.width - CGFloat(max(0, data.count - 1)) * 2) / CGFloat(max(1, data.count))
            // Use 120% of target as visual max so hitting target shows ~83% bar height
            let visualMax = target * 1.2

            HStack(spacing: 2) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    let pct = target > 0 ? value / target : 0
                    let barColor = colorForPercentage(pct)
                    let barHeight = target > 0 ? min(1.0, value / visualMax) : 0

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(barColor)
                        .frame(
                            width: barWidth,
                            height: max(3, geo.size.height * barHeight)
                        )
                        .frame(height: geo.size.height, alignment: .bottom)
                }
            }

            // Target line (subtle)
            let targetY = geo.size.height * (1 - (target / visualMax))
            Path { path in
                path.move(to: CGPoint(x: 0, y: targetY))
                path.addLine(to: CGPoint(x: geo.size.width, y: targetY))
            }
            .stroke(Theme.textMuted.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
        }
        .frame(width: 60, height: 24)
    }

    private func colorForPercentage(_ pct: Double) -> Color {
        switch pct {
        case ..<0.8:
            // Missed - muted/gray
            return baseColor.opacity(0.25)
        case 0.8..<1.0:
            // Close but under - amber warning
            return Theme.warning
        case 1.0..<1.1:
            // Hit target - success green
            return Theme.success
        default:
            // Surplus (>110%) - bright accent
            return baseColor
        }
    }
}

/// Compact goal summary showing value + compliance
struct GoalComplianceBadge: View {
    let hitDays: Int
    let totalDays: Int

    var body: some View {
        Text("\(hitDays)/\(totalDays)")
            .font(.labelMicro)
            .foregroundStyle(hitDays >= totalDays / 2 ? Theme.success : Theme.warning)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill((hitDays >= totalDays / 2 ? Theme.success : Theme.warning).opacity(0.15))
            )
    }
}

#Preview("Charts") {
    VStack(spacing: 20) {
        // Weight trend - sparkline (trend matters)
        HStack {
            Text("Weight")
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            MiniSparkline(
                data: [174.5, 174.2, 173.8, 174.0, 173.5, 173.2, 172.8],
                color: Theme.accent,
                showDots: true
            )
            Text("172.8 lbs")
                .foregroundStyle(Theme.textPrimary)
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)

        // Protein - goal bars (target: 175g)
        HStack {
            Text("Protein")
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            GoalBarChart(
                data: [180, 165, 148, 190, 142, 178, 155],
                target: 175,
                baseColor: Theme.protein
            )
            Text("165g avg")
                .foregroundStyle(Theme.textPrimary)
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)

        // Calories - goal bars (target: 2600)
        HStack {
            Text("Calories")
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            GoalBarChart(
                data: [2650, 2400, 2100, 2800, 2550, 2700, 2450],
                target: 2600,
                baseColor: Theme.calories
            )
            Text("2,521 avg")
                .foregroundStyle(Theme.textPrimary)
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)

        // Sleep - goal bars (target: 7.5h)
        HStack {
            Text("Sleep")
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            GoalBarChart(
                data: [7.2, 8.1, 6.5, 7.8, 5.9, 7.5, 7.0],
                target: 7.5,
                baseColor: Color.indigo
            )
            Text("7.1 hrs")
                .foregroundStyle(Theme.textPrimary)
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)

        // Workouts - bar sparkline (discrete)
        HStack {
            Text("Workouts")
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            MiniBarSparkline(
                data: [0, 0, 1, 0, 1, 0, 1],
                color: Theme.secondary
            )
            Text("3")
                .foregroundStyle(Theme.textPrimary)
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
    }
    .padding()
    .background(Theme.background)
}
