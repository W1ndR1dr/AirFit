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
    private let animationDuration: Double = 0.8

    var body: some View {
        Group {
            switch style {
            case .full:
                fullView
            case .compact:
                compactView
            }
        }
        .onAppear {
            if animateOnAppear {
                withAnimation(.easeInOut(duration: animationDuration).delay(0.1)) {
                    animateRings = true
                }
            } else {
                // If not animating on appear, show rings at full progress immediately
                animateRings = true
            }
        }
    }

    // MARK: - Full View
    private var fullView: some View {
        VStack(spacing: AppSpacing.large) {
            // Rings
            ZStack {
                // Protein Ring (Outer)
                SingleMacroRingView(
                    progress: animateRings ? nutrition.proteinProgress : 0,
                    color: AppColors.proteinColor,
                    gradient: AppColors.proteinGradient,
                    radius: 90,
                    lineWidth: ringWidthFull,
                    animationDuration: animationDuration
                )

                // Carbs Ring (Middle)
                SingleMacroRingView(
                    progress: animateRings ? nutrition.carbProgress : 0,
                    color: AppColors.carbsColor,
                    gradient: AppColors.carbsGradient,
                    radius: 70, // 90 - ringWidthFull - spacing
                    lineWidth: ringWidthFull,
                    animationDuration: animationDuration
                )

                // Fat Ring (Inner)
                SingleMacroRingView(
                    progress: animateRings ? nutrition.fatProgress : 0,
                    color: AppColors.fatColor,
                    gradient: AppColors.fatGradient,
                    radius: 50, // 70 - ringWidthFull - spacing
                    lineWidth: ringWidthFull,
                    animationDuration: animationDuration
                )

                // Center calories
                VStack(spacing: 2) {
                    Text(\"\(Int(nutrition.calories))\")
                        .font(AppFonts.title1)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    Text(\"cal\")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(height: 200) // Adjusted for larger rings

            // Legend
            HStack(spacing: AppSpacing.medium) { // Adjusted spacing
                Spacer()
                MacroLegendItemView(
                    title: \"Protein\",
                    currentValue: nutrition.protein,
                    goalValue: nutrition.proteinGoal,
                    color: AppColors.proteinColor
                )
                Spacer()
                MacroLegendItemView(
                    title: \"Carbs\",
                    currentValue: nutrition.carbs,
                    goalValue: nutrition.carbGoal,
                    color: AppColors.carbsColor
                )
                Spacer()
                MacroLegendItemView(
                    title: \"Fat\",
                    currentValue: nutrition.fat,
                    goalValue: nutrition.fatGoal,
                    color: AppColors.fatColor
                )
                Spacer()
            }
        }
    }

    // MARK: - Compact View
    private var compactView: some View {
        HStack(spacing: AppSpacing.medium) {
            MiniMacroRingView(
                progress: animateRings ? nutrition.proteinProgress : 0,
                color: AppColors.proteinColor,
                gradient: AppColors.proteinGradient,
                value: nutrition.protein,
                label: \"P\",
                lineWidth: ringWidthCompact,
                animationDuration: animationDuration
            )
            MiniMacroRingView(
                progress: animateRings ? nutrition.carbProgress : 0,
                color: AppColors.carbsColor,
                gradient: AppColors.carbsGradient,
                value: nutrition.carbs,
                label: \"C\",
                lineWidth: ringWidthCompact,
                animationDuration: animationDuration
            )
            MiniMacroRingView(
                progress: animateRings ? nutrition.fatProgress : 0,
                color: AppColors.fatColor,
                gradient: AppColors.fatGradient,
                value: nutrition.fat,
                label: \"F\",
                lineWidth: ringWidthCompact,
                animationDuration: animationDuration
            )
        }
    }
}

// MARK: - Helper View: SingleMacroRingView
private struct SingleMacroRingView: View {
    let progress: Double // Can be > 1.0 for overage
    let color: Color
    let gradient: LinearGradient
    let radius: CGFloat
    let lineWidth: CGFloat
    let animationDuration: Double

    private var displayedProgress: Double {
        min(progress, 1.0) // Cap at 1.0 for the main ring
    }

    private var overageProgress: Double {
        max(0, progress - 1.0) // Progress beyond 1.0
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: radius * 2, height: radius * 2)

            // Progress ring
            Circle()
                .trim(from: 0, to: displayedProgress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: animationDuration), value: progress) // Animate based on the raw progress

            // Overage indicator ring
            if overageProgress > 0 {
                Circle()
                    .trim(from: 0, to: min(overageProgress, 1.0)) // Overage can also exceed another 100%
                    .stroke(
                        color.opacity(0.6), // Slightly different appearance for overage
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: [5, 3]) // Dashed line for overage
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: animationDuration).delay(animationDuration * 0.5), value: progress) // Delay overage animation slightly
            }
        }
    }
}

// MARK: - Helper View: MacroLegendItemView
private struct MacroLegendItemView: View {
    let title: String
    let currentValue: Double
    let goalValue: Double
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xxSmall) {
            HStack(spacing: AppSpacing.xSmall) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            Text(\"\(Int(currentValue)) / \(Int(goalValue))g\")
                .font(AppFonts.footnote)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

// MARK: - Helper View: MiniMacroRingView
private struct MiniMacroRingView: View {
    let progress: Double
    let color: Color
    let gradient: LinearGradient
    let value: Double
    let label: String
    let lineWidth: CGFloat
    let animationDuration: Double
    
    private var displayedProgress: Double {
        min(progress, 1.0)
    }

    private var overageProgress: Double {
        max(0, progress - 1.0)
    }

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: lineWidth)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: displayedProgress)
                    .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: animationDuration), value: progress)
                
                if overageProgress > 0 {
                    Circle()
                        .trim(from: 0, to: min(overageProgress, 1.0))
                        .stroke(
                            color.opacity(0.6),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: [3,2])
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: animationDuration).delay(animationDuration * 0.5), value: progress)
                }

                Text(label)
                    .font(AppFonts.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            Text(\"\(Int(value))g\")
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Previews
#Preview("Full Style - Under Goal") {
    MacroRingsView(
        nutrition: FoodNutritionSummary(
            calories: 1500, protein: 70, carbs: 180, fat: 50,
            calorieGoal: 2200, proteinGoal: 120, carbGoal: 280, fatGoal: 70
        ),
        style: .full
    )
    .padding()
    .background(AppColors.backgroundSecondary)
}

#Preview("Full Style - Over Goal") {
    MacroRingsView(
        nutrition: FoodNutritionSummary(
            calories: 2500, protein: 150, carbs: 300, fat: 80,
            calorieGoal: 2000, proteinGoal: 100, carbGoal: 250, fatGoal: 60
        ),
        style: .full
    )
    .padding()
    .background(AppColors.backgroundSecondary)
}

#Preview("Full Style - Mixed Progress") {
    MacroRingsView(
        nutrition: FoodNutritionSummary(
            calories: 1800, protein: 110, carbs: 200, fat: 75,
            calorieGoal: 2000, proteinGoal: 100, carbGoal: 300, fatGoal: 60
        ),
        style: .full,
        animateOnAppear: false // Show immediately for snapshot
    )
    .padding()
    .background(AppColors.backgroundSecondary)
}


#Preview("Compact Style - Under Goal") {
    MacroRingsView(
        nutrition: FoodNutritionSummary(
            calories: 1500, protein: 70, carbs: 180, fat: 50,
            calorieGoal: 2200, proteinGoal: 120, carbGoal: 280, fatGoal: 70
        ),
        style: .compact
    )
    .padding()
    .background(AppColors.backgroundSecondary)
}

#Preview("Compact Style - Over Goal") {
    MacroRingsView(
        nutrition: FoodNutritionSummary(
            calories: 2500, protein: 150, carbs: 300, fat: 80,
            calorieGoal: 2000, proteinGoal: 100, carbGoal: 250, fatGoal: 60
        ),
        style: .compact
    )
    .padding()
    .background(AppColors.backgroundSecondary)
}

#Preview("Compact Style - No Animation") {
    MacroRingsView(
        nutrition: FoodNutritionSummary(
            calories: 1000, protein: 50, carbs: 100, fat: 30,
            calorieGoal: 2000, proteinGoal: 100, carbGoal: 250, fatGoal: 60
        ),
        style: .compact,
        animateOnAppear: false
    )
    .padding()
    .background(AppColors.backgroundSecondary)
}
