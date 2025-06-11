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
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    enum Style {
        case full
        case compact
    }

    private let ringWidthFull: CGFloat = 20
    private let ringWidthCompact: CGFloat = 10
    private let ringSpacing: CGFloat = 8

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
                withAnimation(MotionToken.standardSpring.delay(0.2)) {
                    animateRings = true
                }
            } else {
                animateRings = true
            }
        }
    }

    // MARK: - Full Rings View
    private var fullRingsView: some View {
        GlassCard {
            VStack(spacing: AppSpacing.lg) {
                // Rings container with gradient accent
                ZStack {
                    // Gradient glow behind rings
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    gradientManager.active.colors(for: colorScheme).first?.opacity(0.2) ?? Color.clear,
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 60,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .blur(radius: 20)
                        .opacity(animateRings ? 1 : 0)
                    
                    // Background rings with glass effect
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(Color.primary.opacity(0.05), lineWidth: ringWidthFull)
                            .frame(width: ringDiameter(for: index), height: ringDiameter(for: index))
                            .blur(radius: 0.5)
                    }

                    // Progress rings with gradients
                    ForEach(Array(macroData.enumerated()), id: \.offset) { index, macro in
                        Circle()
                            .trim(from: 0, to: animateRings ? macro.progress : 0)
                            .stroke(
                                LinearGradient(
                                    colors: [macro.color, macro.color.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: ringWidthFull, lineCap: .round)
                            )
                            .frame(width: ringDiameter(for: index), height: ringDiameter(for: index))
                            .rotationEffect(.degrees(-90))
                            .shadow(color: macro.color.opacity(0.3), radius: 4, y: 2)
                            .animation(MotionToken.standardSpring.delay(Double(index) * 0.15), value: animateRings)
                    }

                    // Center calories with gradient number
                    VStack(spacing: 4) {
                        GradientNumber(value: Double(nutrition.calories))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                        
                        Text("calories")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                    .scaleEffect(animateRings ? 1 : 0.8)
                    .opacity(animateRings ? 1 : 0)
                    .animation(MotionToken.standardSpring.delay(0.3), value: animateRings)
                }
                .frame(height: 220)

                // Gradient divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                gradientManager.active.colors(for: colorScheme).first?.opacity(0.2) ?? Color.clear,
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, AppSpacing.md)

                // Legend with staggered animation
                HStack(spacing: AppSpacing.lg) {
                    MacroLegendItem(
                        title: "Protein",
                        value: nutrition.protein,
                        goal: nutrition.proteinGoal,
                        color: AppColors.proteinColor,
                        unit: "g",
                        index: 0,
                        animateIn: animateRings
                    )
                    MacroLegendItem(
                        title: "Carbs",
                        value: nutrition.carbs,
                        goal: nutrition.carbGoal,
                        color: AppColors.carbsColor,
                        unit: "g",
                        index: 1,
                        animateIn: animateRings
                    )
                    MacroLegendItem(
                        title: "Fat",
                        value: nutrition.fat,
                        goal: nutrition.fatGoal,
                        color: AppColors.fatColor,
                        unit: "g",
                        index: 2,
                        animateIn: animateRings
                    )
                }
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Compact Rings View
    private var compactRingsView: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(Array(macroData.enumerated()), id: \.offset) { index, macro in
                CompactRingView(
                    macro: macro,
                    animate: animateRings,
                    delay: Double(index) * 0.1
                )
                .environmentObject(gradientManager)
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
    let index: Int
    let animateIn: Bool
    
    @State private var isPressed = false

    private var progress: Double {
        min(value / goal, 1.0)
    }

    private var isOverGoal: Bool {
        value > goal
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            // Progress indicator with gradient
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 5)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: animateIn ? progress : 0)
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.3), radius: 2, y: 1)
                    .animation(MotionToken.standardSpring.delay(Double(index) * 0.15 + 0.5), value: animateIn)

                Text(title.prefix(1))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .opacity(animateIn ? 1 : 0)
                    .animation(MotionToken.standardSpring.delay(Double(index) * 0.15 + 0.6), value: animateIn)
            }

            // Values with gradient when over goal
            VStack(spacing: 2) {
                if isOverGoal {
                    Text("\(Int(value))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    GradientNumber(value: value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }

                Text("/ \(Int(goal))\(unit)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary.opacity(0.8))
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 10)
            .animation(MotionToken.standardSpring.delay(Double(index) * 0.15 + 0.7), value: animateIn)

            // Title
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary)
                .opacity(animateIn ? 1 : 0)
                .animation(MotionToken.standardSpring.delay(Double(index) * 0.15 + 0.8), value: animateIn)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(MotionToken.microAnimation, value: isPressed)
        .onTapGesture {
            HapticService.impact(.light)
            withAnimation(MotionToken.microAnimation) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(MotionToken.microAnimation) {
                    isPressed = false
                }
            }
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
    @State private var isPressed = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                // Gradient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                macro.color.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 15,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .blur(radius: 8)
                    .opacity(animateProgress ? 1 : 0)
                
                // Background ring with glass effect
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 8)
                    .frame(width: 52, height: 52)
                    .blur(radius: 0.3)

                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: animateProgress ? macro.progress : 0)
                    .stroke(
                        LinearGradient(
                            colors: [macro.color, macro.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: macro.color.opacity(0.4), radius: 3, y: 1)
                    .animation(MotionToken.standardSpring.delay(delay), value: animateProgress)

                Text(macro.label)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(macro.color)
                    .scaleEffect(animateProgress ? 1 : 0.8)
                    .opacity(animateProgress ? 1 : 0)
                    .animation(MotionToken.standardSpring.delay(delay + 0.2), value: animateProgress)
            }

            VStack(spacing: 0) {
                GradientNumber(value: macro.value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                
                Text("g")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary.opacity(0.8))
            }
            .opacity(animateProgress ? 1 : 0)
            .offset(y: animateProgress ? 0 : 8)
            .animation(MotionToken.standardSpring.delay(delay + 0.3), value: animateProgress)
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(MotionToken.microAnimation, value: isPressed)
        .onTapGesture {
            HapticService.impact(.light)
            withAnimation(MotionToken.microAnimation) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(MotionToken.microAnimation) {
                    isPressed = false
                }
            }
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
