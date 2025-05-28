import SwiftUI

struct NutritionCard: View {
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

    private var waterProgress: Double {
        guard targets.water > 0 else { return 0 }
        return min(summary.waterLiters / targets.water, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            cardHeader

            HStack(spacing: AppSpacing.medium) {
                caloriesRing
                macroBreakdown
            }

            waterIntakeRow
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(AppConstants.Layout.defaultCornerRadius)
        .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .onAppear {
            withAnimation(.bouncy.delay(0.1)) {
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
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    var caloriesRing: some View {
        ZStack {
            AnimatedRing(
                progress: animateRings ? caloriesProgress : 0,
                gradient: AppColors.caloriesGradient,
                lineWidth: 12
            )
            .frame(width: 80, height: 80)

            VStack(spacing: 2) {
                Text("\(Int(summary.calories))")
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text("cal")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    var macroBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            MacroRow(
                label: "Protein",
                value: summary.protein,
                target: targets.protein,
                color: AppColors.proteinColor,
                progress: animateRings ? proteinProgress : 0
            )

            MacroRow(
                label: "Carbs",
                value: summary.carbs,
                target: targets.carbs,
                color: AppColors.carbsColor,
                progress: animateRings ? carbsProgress : 0
            )

            MacroRow(
                label: "Fat",
                value: summary.fat,
                target: targets.fat,
                color: AppColors.fatColor,
                progress: animateRings ? fatProgress : 0
            )
        }
    }

    var waterIntakeRow: some View {
        HStack {
            Image(systemName: "drop.fill")
                .foregroundStyle(.blue)
                .font(.caption)

            Text("\(summary.waterLiters, specifier: "%.1f")L / \(targets.water, specifier: "%.1f")L")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            ProgressView(value: waterProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(width: 60)
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
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 50, alignment: .leading)

            Text("\(Int(value))g")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textPrimary)

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
                .stroke(AppColors.dividerColor, lineWidth: lineWidth)

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
            calories: 850, protein: 40, carbs: 120, fat: 25, fiber: 10, waterLiters: 1.2, meals: [:]
        ),
        targets: .default
    )
}
