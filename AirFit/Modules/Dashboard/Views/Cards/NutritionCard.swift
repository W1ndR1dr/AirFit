import SwiftUI

struct NutritionCard: View {
    @EnvironmentObject private var gradientManager: GradientManager

    let summary: NutritionSummary
    let targets: NutritionTargets
    var onTap: (() -> Void)?

    @State private var animateRings = false

    private var caloriesProgress: Double {
        guard targets.calories > 0 else { return 0 }
        return min(summary.calories / targets.calories, 1.0)
    }

    private var proteinProgress: Double {
        guard targets.protein > 0 else { return 0 }
        return min(summary.protein / targets.protein, 1.0)
    }

    private var carbsProgress: Double {
        guard targets.carbs > 0 else { return 0 }
        return min(summary.carbs / targets.carbs, 1.0)
    }

    private var fatProgress: Double {
        guard targets.fat > 0 else { return 0 }
        return min(summary.fat / targets.fat, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            cardHeader

            HStack(spacing: AppSpacing.md) {
                caloriesRing
                macroBreakdown
            }
        }
        .onTapGesture {
            HapticService.impact(.soft)
            onTap?()
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.1)) {
                animateRings = true
            }
        }
    }
}

// MARK: - Subviews
private extension NutritionCard {
    var cardHeader: some View {
        HStack {
            Label("Nutrition", systemImage: "fork.knife")
                .font(AppFonts.headline)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    var caloriesRing: some View {
        MetricRing(
            value: animateRings ? summary.calories : 0,
            goal: targets.calories,
            lineWidth: 12,
            size: 80,
            showPercentage: false
        )
        .overlay {
            VStack(spacing: 2) {
                GradientNumber(
                    value: summary.calories,
                    fontSize: 20,
                    fontWeight: .semibold
                )
                Text("cal")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var macroBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            MacroRow(
                label: "Protein",
                value: summary.protein,
                target: targets.protein,
                color: Color(hex: "#FF6B6B"),
                progress: animateRings ? proteinProgress : 0
            )

            MacroRow(
                label: "Carbs",
                value: summary.carbs,
                target: targets.carbs,
                color: Color(hex: "#4ECDC4"),
                progress: animateRings ? carbsProgress : 0
            )

            MacroRow(
                label: "Fat",
                value: summary.fat,
                target: targets.fat,
                color: Color(hex: "#FFD93D"),
                progress: animateRings ? fatProgress : 0
            )
        }
    }

}

// MARK: - Components
private struct MacroRow: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color
    let progress: Double

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            Text("\(Int(value))g")
                .font(AppFonts.caption)
                .foregroundStyle(.primary)

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(width: 40)
        }
    }
}

private struct AnimatedRing: View {
    let progress: Double
    let gradient: LinearGradient
    let lineWidth: CGFloat

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animatedProgress)
        }
        .onAppear { animatedProgress = progress }
        .onChange(of: progress) { _, newValue in
            animatedProgress = newValue
        }
    }
}

#Preview {
    NutritionCard(
        summary: NutritionSummary(
            calories: 850,
            caloriesTarget: 2_000,
            protein: 40,
            proteinTarget: 150,
            carbs: 120,
            carbsTarget: 250,
            fat: 25,
            fatTarget: 65,
            fiber: 10,
            fiberTarget: 25,
            mealCount: 2
        ),
        targets: NutritionTargets.default
    )
}
