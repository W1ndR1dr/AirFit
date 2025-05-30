import SwiftUI
import Charts

/// A view that displays macronutrient progress using animated rings.
///
/// This view can be configured to show a full detailed display with concentric rings
/// and a legend, or a compact display with smaller individual rings.
struct MacroRingsView: View {
    let nutrition: FoodNutritionSummary
    var style: Style = .full
    var animateOnAppear: Bool = true

    @State private var animateRings = false

    enum Style {
        case full
        case compact
    }

    private let ringWidthFull: CGFloat = 16
    private let ringWidthCompact: CGFloat = 8
    private let ringSpacing: CGFloat = 4

    var body: some View {
        Group {
            switch style {
            case .full:
                fullRingsView
            case .compact:
                compactRingsView
            }
        }
        .onAppear {
            if animateOnAppear {
                withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                    animateRings = true
                }
            } else {
                animateRings = true
            }
        }
    }

    // MARK: - Full Rings View
    private var fullRingsView: some View {
        VStack(spacing: AppSpacing.large) {
            ZStack {
                // Background rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(AppColors.backgroundTertiary, lineWidth: ringWidthFull)
                        .frame(width: ringDiameter(for: index), height: ringDiameter(for: index))
                }

                // Progress rings
                ForEach(Array(macroData.enumerated()), id: \.offset) { index, macro in
                    Circle()
                        .trim(from: 0, to: animateRings ? macro.progress : 0)
                        .stroke(
                            macro.color,
                            style: StrokeStyle(lineWidth: ringWidthFull, lineCap: .round)
                        )
                        .frame(width: ringDiameter(for: index), height: ringDiameter(for: index))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0).delay(Double(index) * 0.2), value: animateRings)
                }

                // Center calories
                VStack(spacing: 2) {
                    Text("\(Int(nutrition.calories))")
                        .font(AppFonts.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    Text("cal")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(height: 200)

            // Legend
            HStack(spacing: AppSpacing.large) {
                MacroLegendItem(
                    title: "Protein",
                    value: nutrition.protein,
                    goal: nutrition.proteinGoal,
                    color: AppColors.proteinColor,
                    unit: "g"
                )
                MacroLegendItem(
                    title: "Carbs",
                    value: nutrition.carbs,
                    goal: nutrition.carbGoal,
                    color: AppColors.carbsColor,
                    unit: "g"
                )
                MacroLegendItem(
                    title: "Fat",
                    value: nutrition.fat,
                    goal: nutrition.fatGoal,
                    color: AppColors.fatColor,
                    unit: "g"
                )
            }
        }
    }

    // MARK: - Compact Rings View
    private var compactRingsView: some View {
        HStack(spacing: AppSpacing.medium) {
            ForEach(Array(macroData.enumerated()), id: \.offset) { index, macro in
                CompactRingView(
                    macro: macro,
                    animate: animateRings,
                    delay: Double(index) * 0.1
                )
            }
        }
    }

    // MARK: - Helper Properties
    private var macroData: [MacroData] {
        [
            MacroData(
                label: "P",
                value: nutrition.protein,
                goal: nutrition.proteinGoal,
                color: AppColors.proteinColor,
                progress: min(nutrition.protein / nutrition.proteinGoal, 1.0)
            ),
            MacroData(
                label: "C",
                value: nutrition.carbs,
                goal: nutrition.carbGoal,
                color: AppColors.carbsColor,
                progress: min(nutrition.carbs / nutrition.carbGoal, 1.0)
            ),
            MacroData(
                label: "F",
                value: nutrition.fat,
                goal: nutrition.fatGoal,
                color: AppColors.fatColor,
                progress: min(nutrition.fat / nutrition.fatGoal, 1.0)
            )
        ]
    }

    private func ringDiameter(for index: Int) -> CGFloat {
        let baseSize: CGFloat = 120
        let spacing = ringWidthFull + ringSpacing
        return baseSize + CGFloat(index) * spacing * 2
    }
}

// MARK: - Supporting Views
struct MacroLegendItem: View {
    let title: String
    let value: Double
    let goal: Double
    let color: Color
    let unit: String

    private var progress: Double {
        min(value / goal, 1.0)
    }

    private var isOverGoal: Bool {
        value > goal
    }

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            // Progress indicator
            ZStack {
                Circle()
                    .stroke(AppColors.backgroundTertiary, lineWidth: 4)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))

                Text(title.prefix(1))
                    .font(AppFonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            // Values
            VStack(spacing: 2) {
                Text("\(Int(value))")
                    .font(AppFonts.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(isOverGoal ? AppColors.errorColor : AppColors.textPrimary)

                Text("/ \(Int(goal))\(unit)")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            // Title
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(Int(value)) of \(Int(goal)) \(unit)")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}

struct CompactRingView: View {
    let macro: MacroData
    let animate: Bool
    let delay: Double

    @State private var animateProgress = false

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            ZStack {
                Circle()
                    .stroke(AppColors.backgroundTertiary, lineWidth: 6)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: animateProgress ? macro.progress : 0)
                    .stroke(macro.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8).delay(delay), value: animateProgress)

                Text(macro.label)
                    .font(AppFonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(macro.color)
            }

            Text("\(Int(macro.value))g")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .onChange(of: animate) { _, newValue in
            animateProgress = newValue
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(macro.label): \(Int(macro.value)) grams")
        .accessibilityValue("\(Int(macro.progress * 100)) percent of goal")
    }
}

// MARK: - Supporting Types
struct MacroData {
    let label: String
    let value: Double
    let goal: Double
    let color: Color
    let progress: Double
}

// MARK: - Preview
#if DEBUG
#Preview("Full Style") {
    MacroRingsView(
        nutrition: FoodNutritionSummary(
            calories: 1850,
            protein: 120,
            carbs: 180,
            fat: 65,
            fiber: 25,
            sugar: 45,
            sodium: 2100,
            calorieGoal: 2000,
            proteinGoal: 150,
            carbGoal: 200,
            fatGoal: 70
        ),
        style: .full
    )
    .padding()
}

#Preview("Compact Style") {
    MacroRingsView(
        nutrition: FoodNutritionSummary(
            calories: 1850,
            protein: 120,
            carbs: 180,
            fat: 65,
            fiber: 25,
            sugar: 45,
            sodium: 2100,
            calorieGoal: 2000,
            proteinGoal: 150,
            carbGoal: 200,
            fatGoal: 70
        ),
        style: .compact
    )
    .padding()
}
#endif
