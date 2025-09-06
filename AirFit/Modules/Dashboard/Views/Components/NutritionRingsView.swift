import SwiftUI

struct NutritionRingsView: View {
    let nutrition: DashboardNutritionData
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var animateRings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Nutrition")
                .font(.system(size: 18, weight: .light))
                .opacity(0.7)

            HStack(spacing: 24) {
                // Large calorie ring with value in center
                ZStack {
                    MetricRing(
                        value: animateRings ? nutrition.calories : 0,
                        goal: nutrition.calorieTarget,
                        lineWidth: 10,
                        size: 90
                    )

                    VStack(spacing: 2) {
                        GradientNumber(
                            value: nutrition.calories,
                            fontSize: 24,
                            fontWeight: .semibold
                        )
                        Text("cal")
                            .font(.system(size: 12, weight: .light))
                            .opacity(0.6)
                    }
                }

                // Three macro rings
                HStack(spacing: 16) {
                    MacroRing(
                        value: animateRings ? nutrition.protein : 0,
                        goal: nutrition.proteinTarget,
                        color: .red,
                        label: "P"
                    )

                    MacroRing(
                        value: animateRings ? nutrition.carbs : 0,
                        goal: nutrition.carbTarget,
                        color: .teal,
                        label: "C"
                    )

                    MacroRing(
                        value: animateRings ? nutrition.fat : 0,
                        goal: nutrition.fatTarget,
                        color: .yellow,
                        label: "F"
                    )
                }
            }
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.1)) {
                animateRings = true
            }
        }
    }
}

// MARK: - Macro Ring Component
private struct MacroRing: View {
    let value: Double
    let goal: Double
    let color: Color
    let label: String

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 50, height: 50)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color.opacity(0.8),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 50, height: 50)

                // Value in center
                Text("\(Int(value))")
                    .font(.system(size: 16, weight: .medium))
            }

            Text(label)
                .font(.system(size: 12, weight: .light))
                .opacity(0.6)
        }
    }
}

// MARK: - Preview
#Preview {
    BaseScreen {
        VStack {
            NutritionRingsView(
                nutrition: DashboardNutritionData(
                    calories: 1_450,
                    calorieTarget: 2_000,
                    protein: 85,
                    proteinTarget: 150,
                    carbs: 180,
                    carbTarget: 250,
                    fat: 45,
                    fatTarget: 65
                )
            )
            .padding()

            Spacer()
        }
    }
    .environmentObject(GradientManager())
}
