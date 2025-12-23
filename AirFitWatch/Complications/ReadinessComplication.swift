import SwiftUI
import WidgetKit

/// Circular complication showing readiness score.
/// Ring indicates readiness level, center shows category icon.
struct ReadinessCircularComplication: View {
    let readiness: ReadinessData

    private var ringColor: Color {
        switch readiness.category {
        case "Great": return .green
        case "Good": return .blue
        case "Moderate": return .yellow
        case "Rest": return .red
        default: return .gray
        }
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(ringColor.opacity(0.3), lineWidth: 4)

            // Progress ring
            Circle()
                .trim(from: 0, to: readiness.score)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center icon
            VStack(spacing: 0) {
                Image(systemName: readiness.categoryIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ringColor)

                if readiness.isBaselineReady {
                    Text("\(Int(readiness.score * 100))")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

/// Rectangular complication with more detail
struct ReadinessRectangularComplication: View {
    let readiness: ReadinessData

    private var statusColor: Color {
        switch readiness.category {
        case "Great": return .green
        case "Good": return .blue
        case "Moderate": return .yellow
        case "Rest": return .red
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: readiness.categoryIcon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(statusColor)

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(readiness.category)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(statusColor)

                if readiness.isBaselineReady {
                    Text("\(readiness.positiveCount)/\(readiness.totalCount) indicators")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                } else {
                    Text("Building baseline...")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

/// Corner complication - just the icon
struct ReadinessCornerComplication: View {
    let readiness: ReadinessData

    private var statusColor: Color {
        switch readiness.category {
        case "Great": return .green
        case "Good": return .blue
        case "Moderate": return .yellow
        case "Rest": return .red
        default: return .gray
        }
    }

    var body: some View {
        Image(systemName: readiness.categoryIcon)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(statusColor)
    }
}

// MARK: - Previews

#Preview("Circular - Great") {
    ReadinessCircularComplication(readiness: ReadinessData(
        category: "Great",
        positiveCount: 3,
        totalCount: 3,
        hrvDeviation: 5.0,
        sleepHours: 8.2,
        rhrDeviation: -2.0,
        isBaselineReady: true,
        lastUpdated: Date()
    ))
    .frame(width: 50, height: 50)
}

#Preview("Rectangular - Good") {
    ReadinessRectangularComplication(readiness: ReadinessData(
        category: "Good",
        positiveCount: 2,
        totalCount: 3,
        hrvDeviation: -3.0,
        sleepHours: 7.5,
        rhrDeviation: 2.0,
        isBaselineReady: true,
        lastUpdated: Date()
    ))
    .frame(width: 150, height: 50)
}
