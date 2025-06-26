import SwiftUI

/// Shows the user what we understood from their conversation
/// Allows them to confirm or refine before persona generation
struct InsightsConfirmationView: View {
    let insights: ExtractedInsights?
    let onConfirm: () -> Void
    let onRefine: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 16) {
                Image(systemName: "brain.filled.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor.gradient)
                    .symbolEffect(.pulse)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8)

                CascadeText("Here's what I understood")
                    .font(.system(size: 32, weight: .thin, design: .rounded))
            }

            // Insights Card
            if let insights = insights {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        InsightRow(
                            icon: "target",
                            title: "Your Goal",
                            value: insights.primaryGoal
                        )

                        if !insights.keyObstacles.isEmpty {
                            InsightRow(
                                icon: "exclamationmark.triangle",
                                title: "Challenges",
                                value: insights.keyObstacles.joined(separator: ", ")
                            )
                        }

                        if !insights.exercisePreferences.isEmpty {
                            InsightRow(
                                icon: "figure.run",
                                title: "Preferences",
                                value: insights.exercisePreferences.joined(separator: ", ")
                            )
                        }

                        InsightRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Fitness Level",
                            value: insights.currentFitnessLevel
                        )

                        InsightRow(
                            icon: "calendar",
                            title: "Schedule",
                            value: insights.dailySchedule
                        )

                        if !insights.motivationalNeeds.isEmpty {
                            InsightRow(
                                icon: "sparkles",
                                title: "What You Need",
                                value: insights.motivationalNeeds.joined(separator: ", ")
                            )
                        }
                    }
                    .padding(24)
                }
                .frame(maxHeight: 300)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Material.regular)
                )
                .padding(.horizontal, 24)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
            } else {
                // Fallback if no insights
                Text("I'm still learning about you. Let's continue our conversation!")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    HStack {
                        Text("This sounds right")
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button(action: onRefine) {
                    Text("Let me clarify")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Insight Row Component

private struct InsightRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    InsightsConfirmationView(
        insights: ExtractedInsights(
            primaryGoal: "lose 20 pounds",
            keyObstacles: ["busy schedule", "lack of motivation"],
            exercisePreferences: ["walking", "yoga"],
            currentFitnessLevel: "beginner",
            dailySchedule: "work from home, flexible mornings",
            motivationalNeeds: ["daily encouragement", "small wins celebration"],
            communicationStyle: "friendly and supportive"
        ),
        onConfirm: {},
        onRefine: {}
    )
    .preferredColorScheme(.dark)
}
