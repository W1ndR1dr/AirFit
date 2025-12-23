import SwiftUI
import WidgetKit

/// Circular complication showing calorie/protein progress rings.
/// Outer ring: protein progress, Inner ring: calorie progress
struct MacroRingComplication: View {
    let macros: MacroProgress

    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(Color.black.opacity(0.3))

            // Calorie ring (inner)
            Circle()
                .trim(from: 0, to: min(1.0, macros.calorieProgress))
                .stroke(
                    Color.orange,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(8)

            // Protein ring (outer)
            Circle()
                .trim(from: 0, to: min(1.0, macros.proteinProgress))
                .stroke(
                    Color.blue,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(2)

            // Center text
            VStack(spacing: 0) {
                Text("\(macros.proteinRemaining)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("g")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

/// Rectangular complication with more detail
struct MacroRectangularComplication: View {
    let macros: MacroProgress

    var body: some View {
        HStack(spacing: 8) {
            // Calories
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("\(macros.calories)")
                        .font(.system(size: 12, weight: .semibold))
                }
                ProgressView(value: min(1.0, macros.calorieProgress))
                    .tint(.orange)
            }

            // Protein
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Text("P")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                    Text("\(macros.protein)g")
                        .font(.system(size: 12, weight: .semibold))
                }
                ProgressView(value: min(1.0, macros.proteinProgress))
                    .tint(.blue)
            }
        }
        .padding(.horizontal, 4)
    }
}

/// Corner complication - just protein remaining
struct MacroCornerComplication: View {
    let macros: MacroProgress

    var body: some View {
        VStack(spacing: 0) {
            Text("\(macros.proteinRemaining)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Text("g P")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Circular") {
    MacroRingComplication(macros: MacroProgress(
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
    ))
    .frame(width: 50, height: 50)
}

#Preview("Rectangular") {
    MacroRectangularComplication(macros: MacroProgress(
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
    ))
    .frame(width: 150, height: 50)
}
