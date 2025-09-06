import SwiftUI

struct StrengthProgressionCard: View {
    let recentPRs: [ExercisePR]
    let onViewAll: () -> Void

    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                HStack {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Recent PRs")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                    }

                    Spacer()

                    Button(action: onViewAll) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }

                if recentPRs.isEmpty {
                    EmptyPRView()
                } else {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(Array(recentPRs.prefix(3).enumerated()), id: \.element.exercise) { index, pr in
                            PRRow(pr: pr, index: index, animateIn: animateIn)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.2)) {
                animateIn = true
            }
        }
    }
}

// MARK: - PR Row
private struct PRRow: View {
    let pr: ExercisePR
    let index: Int
    let animateIn: Bool

    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    private var improvementColor: Color {
        guard let improvement = pr.improvement else { return .gray }
        if improvement > 5 { return .green }
        if improvement > 0 { return .blue }
        return .orange
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Exercise name and weight
            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exercise)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Text("\(Int(pr.oneRepMax))kg")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    if let weight = pr.actualWeight, let reps = pr.actualReps {
                        Text("(\(Int(weight))kg × \(reps))")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Improvement indicator
            if let improvement = pr.improvement {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 2) {
                        Image(systemName: improvement > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 12, weight: .bold))
                        Text("\(abs(Int(improvement)))%")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(improvementColor)

                    Text(pr.date.formatted(.relative(presentation: .named)))
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .opacity(animateIn ? 1 : 0)
        .offset(x: animateIn ? 0 : 20)
        .animation(
            MotionToken.standardSpring.delay(Double(index) * 0.1 + 0.3),
            value: animateIn
        )
    }
}

// MARK: - Empty State
private struct EmptyPRView: View {
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "dumbbell")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.5) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("No PRs recorded yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Complete workouts to track your strength progress")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }
}

// MARK: - Preview
#Preview {
    BaseScreen {
        VStack {
            StrengthProgressionCard(
                recentPRs: [
                    ExercisePR(
                        exercise: "Bench Press",
                        oneRepMax: 120,
                        date: Date().addingTimeInterval(-86_400),
                        improvement: 5.2,
                        actualWeight: 100,
                        actualReps: 5
                    ),
                    ExercisePR(
                        exercise: "Squat",
                        oneRepMax: 180,
                        date: Date().addingTimeInterval(-172_800),
                        improvement: 3.1,
                        actualWeight: 150,
                        actualReps: 5
                    ),
                    ExercisePR(
                        exercise: "Deadlift",
                        oneRepMax: 200,
                        date: Date().addingTimeInterval(-259_200),
                        improvement: 7.8,
                        actualWeight: 170,
                        actualReps: 4
                    )
                ],
                onViewAll: {}
            )
            .padding()

            Spacer()
        }
    }
    .environmentObject(GradientManager())
}
