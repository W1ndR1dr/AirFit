import ActivityKit
import WidgetKit
import SwiftUI

struct NutritionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NutritionActivityAttributes.self) { context in
            // Lock Screen / Banner view
            LockScreenView(state: context.state)
                .activityBackgroundTint(.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(context.state.calories)")
                            .font(.title2.bold())
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 4) {
                        Text("\(context.state.protein)g")
                            .font(.title2.bold())
                        Image(systemName: "p.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        MacroProgressBar(
                            label: "Cal",
                            current: context.state.calories,
                            target: context.state.targetCalories,
                            color: .orange
                        )
                        MacroProgressBar(
                            label: "Protein",
                            current: context.state.protein,
                            target: context.state.targetProtein,
                            color: .blue
                        )
                        MacroProgressBar(
                            label: "Carbs",
                            current: context.state.carbs,
                            target: context.state.targetCarbs,
                            color: .green
                        )
                        MacroProgressBar(
                            label: "Fat",
                            current: context.state.fat,
                            target: context.state.targetFat,
                            color: .yellow
                        )
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Compact leading - calories
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(context.state.calories)")
                        .font(.caption.bold())
                }
            } compactTrailing: {
                // Compact trailing - protein remaining
                HStack(spacing: 2) {
                    Text("\(context.state.proteinRemaining)g")
                        .font(.caption.bold())
                    Image(systemName: "p.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            } minimal: {
                // Minimal view - just protein progress
                CircularProgressView(
                    progress: context.state.proteinProgress,
                    color: .blue
                )
            }
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let state: NutritionActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text(state.isTrainingDay ? "Training Day" : "Rest Day")
                    .font(.caption.bold())
                    .foregroundColor(state.isTrainingDay ? .green : .gray)
                Spacer()
                Text("\(state.proteinRemaining)g protein to go")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Main progress bars
            HStack(spacing: 16) {
                MacroProgressBar(
                    label: "Calories",
                    current: state.calories,
                    target: state.targetCalories,
                    color: .orange
                )
                MacroProgressBar(
                    label: "Protein",
                    current: state.protein,
                    target: state.targetProtein,
                    color: .blue
                )
                MacroProgressBar(
                    label: "Carbs",
                    current: state.carbs,
                    target: state.targetCarbs,
                    color: .green
                )
                MacroProgressBar(
                    label: "Fat",
                    current: state.fat,
                    target: state.targetFat,
                    color: .yellow
                )
            }
        }
        .padding()
    }
}

// MARK: - Macro Progress Bar

private struct MacroProgressBar: View {
    let label: String
    let current: Int
    let target: Int
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(current) / Double(target))
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.2))
                    .frame(width: 24, height: 40)

                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 24, height: CGFloat(progress) * 40)
            }

            Text("\(current)")
                .font(.caption2.bold())
        }
    }
}

// MARK: - Circular Progress (for minimal Dynamic Island)

private struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 3)

            Circle()
                .trim(from: 0, to: min(1.0, progress))
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 16, height: 16)
    }
}

// MARK: - Preview

#Preview("Live Activity", as: .content, using: NutritionActivityAttributes(date: Date())) {
    NutritionLiveActivity()
} contentStates: {
    NutritionActivityAttributes.ContentState(
        calories: 1847,
        protein: 142,
        carbs: 220,
        fat: 48,
        targetCalories: 2600,
        targetProtein: 175,
        targetCarbs: 330,
        targetFat: 67,
        isTrainingDay: true,
        lastUpdated: Date()
    )
}
