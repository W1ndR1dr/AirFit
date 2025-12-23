import SwiftUI

/// Organic ring gauge for calorie progress visualization
/// Designed to harmonize with Bloom's warm aesthetic
struct CalorieRingGauge: View {
    let current: Int
    let target: Int

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(current) / CGFloat(target)
    }

    private var displayProgress: CGFloat {
        min(1.0, progress)
    }

    private var isOverTarget: Bool {
        progress > 1.0
    }

    private var ringGradient: AngularGradient {
        AngularGradient(
            colors: [Theme.calories, Theme.calories.opacity(0.7)],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Theme.calories.opacity(0.12),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: isOverTarget ? Theme.calories.opacity(0.4) : .clear,
                    radius: isOverTarget ? 8 : 0
                )

            // Center content - offset up to optically center the text block
            VStack(spacing: 2) {
                Text("\(current)")
                    .font(.metricHero)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.calories, Theme.calories.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText(value: Double(current)))

                Text("OF \(target) CALORIES")
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(Theme.textMuted)
            }
            .offset(y: -12)
        }
        .frame(width: 180, height: 180)
        .onAppear {
            withAnimation(.bloomWater) {
                animatedProgress = displayProgress
            }
        }
        .onChange(of: current) { _, _ in
            withAnimation(.bloomWater) {
                animatedProgress = displayProgress
            }
        }
        .onChange(of: target) { _, _ in
            withAnimation(.bloomWater) {
                animatedProgress = displayProgress
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CalorieRingGauge(current: 1500, target: 2600)
        CalorieRingGauge(current: 2600, target: 2600)
        CalorieRingGauge(current: 3000, target: 2600) // Over target
    }
    .padding()
    .background(Theme.background)
}
