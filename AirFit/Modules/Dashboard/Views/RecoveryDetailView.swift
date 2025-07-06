import SwiftUI
import Charts

/// Detailed recovery metrics view accessible from Today dashboard
struct RecoveryDetailView: View {
    let user: User
    @State private var selectedTimeframe: TimeframeOption = .week
    @State private var animateIn = false

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(NavigationState.self) private var navigationState

    enum TimeframeOption: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }

    var body: some View {
        BaseScreen {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, AppSpacing.md)

                    // Timeframe picker
                    DashboardTimeframePicker(selection: $selectedTimeframe)
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, AppSpacing.lg)

                    // Content sections
                    DashboardContentView(delay: 0.1) {
                        recoveryScoreSection
                    }
                    .padding(.top, AppSpacing.xl)

                    DashboardContentView(delay: 0.2) {
                        sleepAnalysisSection
                    }
                    .padding(.top, AppSpacing.xl)

                    DashboardContentView(delay: 0.3) {
                        heartMetricsSection
                    }
                    .padding(.top, AppSpacing.xl)

                    DashboardContentView(delay: 0.4) {
                        stressIndicatorsSection
                    }
                    .padding(.top, AppSpacing.xl)

                    DashboardContentView(delay: 0.5) {
                        recoveryRecommendationsSection
                    }
                    .padding(.top, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationTitle("Recovery Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            CascadeText("Recovery Analytics")
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.5)

            Text("Monitor your body's recovery patterns")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Recovery Score

    @ViewBuilder
    private var recoveryScoreSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "Recovery Score")

            GlassCard {
                VStack(spacing: AppSpacing.lg) {
                    // Current score
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 20)
                            .frame(width: 180, height: 180)

                        Circle()
                            .trim(from: 0, to: 0.78)
                            .stroke(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: AppSpacing.xs) {
                            Text("78")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Good")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Score factors
                    VStack(spacing: AppSpacing.md) {
                        scoreFactorRow(title: "Sleep Quality", value: 85, contribution: "+15")
                        scoreFactorRow(title: "HRV Trend", value: 72, contribution: "+8")
                        scoreFactorRow(title: "Resting HR", value: 90, contribution: "+12")
                        scoreFactorRow(title: "Activity Balance", value: 68, contribution: "-5")
                    }
                }
                .padding(AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    @ViewBuilder
    private func scoreFactorRow(title: String, value: Int, contribution: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: AppSpacing.sm) {
                DashboardProgressIndicator(progress: Double(value) / 100.0, label: nil)
                    .frame(width: 60)

                Text(contribution)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(contribution.hasPrefix("+") ? .green : .orange)
                    .frame(width: 30, alignment: .trailing)
            }
        }
    }

    // MARK: - Sleep Analysis

    @ViewBuilder
    private var sleepAnalysisSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "Sleep Analysis")

            GlassCard {
                VStack(spacing: AppSpacing.lg) {
                    // Sleep stages chart
                    Chart {
                        ForEach(mockSleepData) { data in
                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                yStart: .value("Start", 0),
                                yEnd: .value("Deep", data.deep)
                            )
                            .foregroundStyle(Color.indigo.gradient)

                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                yStart: .value("Start", data.deep),
                                yEnd: .value("REM", data.deep + data.rem)
                            )
                            .foregroundStyle(Color.purple.gradient)

                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                yStart: .value("Start", data.deep + data.rem),
                                yEnd: .value("Light", data.deep + data.rem + data.light)
                            )
                            .foregroundStyle(Color.blue.gradient.opacity(0.5))
                        }
                    }
                    .frame(height: 200)
                    .chartYAxisLabel("Hours")

                    // Sleep stats
                    HStack(spacing: AppSpacing.xl) {
                        sleepStatItem(title: "Avg Duration", value: "7h 24m", icon: "moon.fill")
                        sleepStatItem(title: "Sleep Debt", value: "-2h 15m", icon: "clock.fill")
                        sleepStatItem(title: "Quality", value: "82%", icon: "star.fill")
                    }

                    // Stage breakdown
                    VStack(spacing: AppSpacing.sm) {
                        stageRow(stage: "Deep Sleep", duration: "1h 45m", percentage: 23, color: .indigo)
                        stageRow(stage: "REM Sleep", duration: "1h 52m", percentage: 25, color: .purple)
                        stageRow(stage: "Light Sleep", duration: "3h 47m", percentage: 52, color: .blue.opacity(0.7))
                    }
                }
                .padding(AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    @ViewBuilder
    private func sleepStatItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(value)
                .font(.system(size: 16, weight: .semibold))

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func stageRow(stage: String, duration: String, percentage: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color.gradient)
                .frame(width: 8, height: 8)

            Text(stage)
                .font(.system(size: 14))

            Spacer()

            Text(duration)
                .font(.system(size: 14, weight: .medium))

            Text("\(percentage)%")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    // MARK: - Heart Metrics

    @ViewBuilder
    private var heartMetricsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "Heart Metrics")

            HStack(spacing: AppSpacing.md) {
                // HRV Card
                GlassCard {
                    VStack(spacing: AppSpacing.md) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.red.gradient)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("HRV")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            Text("42ms")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("+3ms vs avg")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(AppSpacing.md)
                }

                // Resting HR Card
                GlassCard {
                    VStack(spacing: AppSpacing.md) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.pink.gradient)

                            Spacer()

                            Image(systemName: "arrow.down.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Resting HR")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            Text("58")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("-2 bpm vs avg")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    // MARK: - Stress Indicators

    @ViewBuilder
    private var stressIndicatorsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "Stress Indicators")

            GlassCard {
                VStack(spacing: AppSpacing.lg) {
                    // Stress level gauge
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(0..<5) { level in
                            VStack(spacing: AppSpacing.xs) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        AnyShapeStyle(
                                            level < 2 ?
                                                LinearGradient(
                                                    colors: [.green, .yellow],
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                ) : LinearGradient(
                                                    colors: [Color.primary.opacity(0.1), Color.primary.opacity(0.1)],
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                )
                                        )
                                    )
                                    .frame(height: 60)

                                Text(["Low", "Mild", "Mod", "High", "Severe"][level])
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Current status
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Current Stress Level")
                                .font(.system(size: 16, weight: .semibold))

                            Text("Based on HRV, activity, and sleep patterns")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                            Text("Low")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.green)

                            Text("Optimal")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    // MARK: - Recovery Recommendations

    @ViewBuilder
    private var recoveryRecommendationsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "AI Recommendations")

            VStack(spacing: AppSpacing.md) {
                recommendationCard(
                    icon: "moon.zzz.fill",
                    title: "Prioritize Sleep Tonight",
                    message: "Your sleep debt is accumulating. Aim for 8+ hours tonight.",
                    color: .indigo
                )

                recommendationCard(
                    icon: "figure.yoga",
                    title: "Active Recovery Day",
                    message: "Light movement or yoga would support recovery better than intense training.",
                    color: .green
                )
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    @ViewBuilder
    private func recommendationCard(icon: String, title: String, message: String, color: Color) -> some View {
        GlassCard {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color.gradient)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))

                    Text(message)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(AppSpacing.md)
        }
    }
}

// MARK: - Mock Data

private struct RecoverySleepData: Identifiable {
    let id = UUID()
    let date: Date
    let deep: Double
    let rem: Double
    let light: Double
}

private let mockSleepData: [RecoverySleepData] = {
    let calendar = Calendar.current
    let today = Date()

    return (0..<7).map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
        return RecoverySleepData(
            date: date,
            deep: Double.random(in: 1.2...2.0),
            rem: Double.random(in: 1.5...2.5),
            light: Double.random(in: 3.0...4.5)
        )
    }
}()
