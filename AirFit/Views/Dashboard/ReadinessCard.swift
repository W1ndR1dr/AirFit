import SwiftUI

/// Readiness card showing categorical assessment (Great/Good/Moderate/Rest).
///
/// Design principles from plan:
/// - Categorical descriptors, NOT numeric scores (avoids false precision)
/// - Shows indicator dots for transparency
/// - "Building baseline" state for new users (<14 days data)
/// - Expandable to show individual indicator breakdown
struct ReadinessCard: View {
    @StateObject private var engine = ReadinessEngine()
    @State private var assessment: ReadinessEngine.Assessment?
    @State private var isExpanded = false
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with expand button
            Button(action: { withAnimation(.airfit) { isExpanded.toggle() } }) {
                HStack(spacing: 8) {
                    // Category icon
                    Image(systemName: assessment?.category.icon ?? "circle.dashed")
                        .font(.title3)
                        .foregroundStyle(categoryColor)
                        .symbolEffect(.pulse, options: .repeating, value: isLoading)

                    VStack(alignment: .leading, spacing: 2) {
                        // Main label
                        Text("Readiness")
                            .font(.labelHero)
                            .tracking(1)
                            .foregroundStyle(Theme.textMuted)

                        // Category or baseline progress
                        if isLoading {
                            Text("Loading...")
                                .font(.labelMedium)
                                .foregroundStyle(Theme.textMuted)
                        } else if let assessment = assessment {
                            if assessment.isBaselineReady {
                                Text(assessment.category.rawValue)
                                    .font(.metricSmall)
                                    .foregroundStyle(categoryColor)
                            } else if let progress = assessment.baselineProgress {
                                Text("Day \(progress.currentDays) of \(progress.requiredDays)")
                                    .font(.labelMedium)
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                    }

                    Spacer()

                    // Indicator dots
                    if let assessment = assessment, assessment.isBaselineReady {
                        indicatorDots(assessment)
                    } else if let progress = assessment?.baselineProgress, !progress.isReady {
                        // Show progress bar for baseline building
                        progressBar(progress)
                    }

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            // Expanded indicator breakdown
            if isExpanded, let assessment = assessment {
                if assessment.isBaselineReady {
                    indicatorBreakdown(assessment)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                        ))
                } else {
                    baselineBuilding(assessment)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                        ))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(categoryColor.opacity(0.08))
        )
        .task {
            await loadAssessment()
        }
    }

    // MARK: - Subviews

    private func indicatorDots(_ assessment: ReadinessEngine.Assessment) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<assessment.totalCount, id: \.self) { index in
                Circle()
                    .fill(index < assessment.positiveCount ? categoryColor : Theme.textMuted.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func progressBar(_ progress: ReadinessEngine.BaselineProgress) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.textMuted.opacity(0.2))

                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * progress.progressPercent)
            }
        }
        .frame(width: 60, height: 6)
    }

    private func indicatorBreakdown(_ assessment: ReadinessEngine.Assessment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 4)

            // Category description
            Text(assessment.category.description)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, 4)

            // Individual indicators
            ForEach(assessment.indicators) { indicator in
                HStack(spacing: 8) {
                    Image(systemName: indicator.isPositive ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundStyle(indicator.isPositive ? Theme.success : Theme.textMuted)

                    Text(indicator.name)
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    Text(indicator.detail)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            // Empty state if no indicators
            if assessment.indicators.isEmpty {
                Text("No recovery data available today")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }

    private func baselineBuilding(_ assessment: ReadinessEngine.Assessment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 4)

            Text("Building your personal baseline")
                .font(.labelMedium)
                .foregroundStyle(Theme.textPrimary)

            Text("AirFit needs 14 days of HRV, sleep, and heart rate data to provide personalized readiness insights. Keep wearing your Apple Watch!")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)

            if let progress = assessment.baselineProgress {
                // Detail breakdown
                HStack(spacing: 16) {
                    baselineMetric("HRV", days: progress.hrvDays, required: 5)
                    baselineMetric("Sleep", days: progress.sleepDays, required: 5)
                    baselineMetric("RHR", days: progress.rhrDays, required: 5)
                }
                .padding(.top, 4)
            }
        }
    }

    private func baselineMetric(_ name: String, days: Int, required: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(days)/\(required)")
                .font(.labelMedium)
                .foregroundStyle(days >= required ? Theme.success : Theme.textMuted)
            Text(name)
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)
        }
    }

    // MARK: - Computed Properties

    private var categoryColor: Color {
        guard let category = assessment?.category else { return Theme.accent }

        switch category {
        case .great: return Theme.success
        case .good: return Theme.accent
        case .moderate: return Theme.warning
        case .rest: return Theme.error
        }
    }

    // MARK: - Data Loading

    private func loadAssessment() async {
        isLoading = true
        let result = await engine.getReadinessAssessment()
        await MainActor.run {
            withAnimation(.airfit) {
                assessment = result
                isLoading = false
            }
        }
    }
}

#Preview("With Baseline") {
    VStack {
        ReadinessCard()
    }
    .padding()
    .background(Theme.background)
}
