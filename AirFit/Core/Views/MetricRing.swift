import SwiftUI

/// Circular progress indicator with gradient stroke
/// Perfect for displaying metrics like calories, steps, or completion
struct MetricRing: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    let value: Double
    let goal: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let showPercentage: Bool
    let animation: Bool

    @State private var animatedValue: Double = 0

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(animatedValue / goal, 1.0)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    init(
        value: Double,
        goal: Double,
        lineWidth: CGFloat = 12,
        size: CGFloat = 100,
        showPercentage: Bool = true,
        animation: Bool = true
    ) {
        self.value = value
        self.goal = goal
        self.lineWidth = lineWidth
        self.size = size
        self.showPercentage = showPercentage
        self.animation = animation
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.primary.opacity(0.1),
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    gradientManager.currentGradient(for: colorScheme),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    animation ? .bouncy(extraBounce: 0.2) : nil,
                    value: animatedValue
                )

            // Center content
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(percentage)")
                        .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            gradientManager.currentGradient(for: colorScheme)
                        )
                        .contentTransition(.numericText(value: Double(percentage)))

                    Text("%")
                        .font(.system(size: size * 0.15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if animation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animatedValue = value
                }
            } else {
                animatedValue = value
            }
        }
        .onChange(of: value) { _, newValue in
            if animation {
                animatedValue = newValue
            } else {
                animatedValue = newValue
            }
        }
    }
}

// MARK: - Metric Ring with Label

struct MetricRingWithLabel: View {
    let value: Double
    let goal: Double
    let label: String
    let icon: String?
    let size: CGFloat

    init(
        value: Double,
        goal: Double,
        label: String,
        icon: String? = nil,
        size: CGFloat = 100
    ) {
        self.value = value
        self.goal = goal
        self.label = label
        self.icon = icon
        self.size = size
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            MetricRing(
                value: value,
                goal: goal,
                size: size,
                showPercentage: false
            )
            .overlay {
                VStack(spacing: 4) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size * 0.2, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Text("\(Int(value))")
                        .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                        .contentTransition(.numericText(value: value))
                }
            }

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Triple Metric Rings (Activity Style)

struct TripleMetricRings: View {
    @Environment(\.colorScheme) private var colorScheme

    let moveValue: Double
    let moveGoal: Double
    let exerciseValue: Double
    let exerciseGoal: Double
    let standValue: Double
    let standGoal: Double
    let size: CGFloat

    init(
        moveValue: Double,
        moveGoal: Double,
        exerciseValue: Double,
        exerciseGoal: Double,
        standValue: Double,
        standGoal: Double,
        size: CGFloat = 150
    ) {
        self.moveValue = moveValue
        self.moveGoal = moveGoal
        self.exerciseValue = exerciseValue
        self.exerciseGoal = exerciseGoal
        self.standValue = standValue
        self.standGoal = standGoal
        self.size = size
    }

    var body: some View {
        ZStack {
            // Move ring (largest)
            MetricRing(
                value: moveValue,
                goal: moveGoal,
                lineWidth: 14,
                size: size,
                showPercentage: false
            )

            // Exercise ring (middle)
            MetricRing(
                value: exerciseValue,
                goal: exerciseGoal,
                lineWidth: 14,
                size: size * 0.75,
                showPercentage: false
            )

            // Stand ring (smallest)
            MetricRing(
                value: standValue,
                goal: standGoal,
                lineWidth: 14,
                size: size * 0.5,
                showPercentage: false
            )
        }
    }
}
