import SwiftUI
import Charts

/// Detailed recovery metrics view accessible from Today dashboard
struct RecoveryDetailView: View {
    let user: User
    let container: DIContainer
    
    @State private var selectedTimeframe: TimeframeOption = .week
    @State private var animateIn = false
    @State private var recoveryData: RecoveryInference.Output?
    @State private var isLoading = true
    @State private var healthSnapshot: HealthContextSnapshot?

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

                    if isLoading {
                        ProgressView()
                            .padding(.top, 100)
                            .frame(maxWidth: .infinity)
                    } else {
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
            }
            .navigationTitle("Recovery Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadRecoveryData()
        }
    }

    // MARK: - Data Loading
    
    private func loadRecoveryData() async {
        do {
            // Get services from DI container
            let contextAssembler = try await container.resolve(ContextAssemblerProtocol.self)
            let healthKitManager = try await container.resolve(HealthKitManaging.self)
            let recoveryInference = RecoveryInference()
            let adapter = RecoveryDataAdapter(healthKitManager: healthKitManager)
            
            // Fetch health context
            let snapshot = await contextAssembler.assembleContext()
            self.healthSnapshot = snapshot
            
            // Prepare recovery input
            let input = try await adapter.prepareRecoveryInput(
                currentSnapshot: snapshot,
                subjectiveRating: nil
            )
            
            // Analyze recovery
            let output = await recoveryInference.analyzeRecovery(input: input)
            
            await MainActor.run {
                self.recoveryData = output
                self.isLoading = false
            }
        } catch {
            AppLogger.error("Failed to load recovery data", error: error, category: .health)
            await MainActor.run {
                self.isLoading = false
            }
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
                            .trim(from: 0, to: (recoveryData?.readinessScore ?? 0) / 100.0)
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
                            .animation(.easeInOut(duration: 0.8), value: recoveryData?.readinessScore)

                        VStack(spacing: AppSpacing.xs) {
                            Text("\(Int(recoveryData?.readinessScore ?? 0))")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text(recoveryData?.recoveryStatus.rawValue ?? "Unknown")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Limiting factors
                    if let factors = recoveryData?.limitingFactors, !factors.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Limiting Factors")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            ForEach(factors, id: \.self) { factor in
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange.opacity(0.8))
                                    
                                    Text(factor)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary.opacity(0.9))
                                    
                                    Spacer()
                                }
                            }
                        }
                    } else {
                        // Show positive indicators when no limiting factors
                        VStack(spacing: AppSpacing.md) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green.opacity(0.8))
                                
                                Text("All systems optimal")
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary.opacity(0.9))
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }


    // MARK: - Sleep Helpers
    
    @ViewBuilder
    private func sleepStageRow(stage: String, duration: TimeInterval, color: Color) -> some View {
        HStack {
            Text(stage)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(color.gradient)
                        .frame(width: geometry.size.width * min(duration / 10800, 1.0), height: 4) // 3 hours max
                        .cornerRadius(2)
                }
            }
            .frame(width: 100, height: 4)
            
            Text("\(Int(duration / 3600))h \((Int(duration) % 3600) / 60)m")
                .font(.system(size: 12))
                .foregroundColor(.primary.opacity(0.7))
                .frame(width: 60, alignment: .trailing)
        }
    }
    
    // MARK: - Sleep Analysis

    @ViewBuilder
    private var sleepAnalysisSection: some View {
        VStack(spacing: AppSpacing.lg) {
            DashboardSectionHeader(title: "Sleep Analysis")

            GlassCard {
                VStack(spacing: AppSpacing.lg) {
                    // Sleep quality summary
                    if let sleep = healthSnapshot?.sleep.lastNight {
                        VStack(spacing: AppSpacing.md) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Last Night")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Text("\(Int(sleep.totalSleepTime ?? 0) / 3600)h \((Int(sleep.totalSleepTime ?? 0) % 3600) / 60)m")
                                        .font(.system(size: 20, weight: .semibold))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Efficiency")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Text("\(Int(sleep.efficiency ?? 0))%")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(sleep.quality == .excellent ? .green : 
                                                      sleep.quality == .good ? .blue : .orange)
                                }
                            }
                            
                            // Sleep stages breakdown
                            if let deep = sleep.deepTime, let rem = sleep.remTime, let core = sleep.coreTime {
                                VStack(spacing: AppSpacing.sm) {
                                    sleepStageRow(stage: "Deep", duration: deep, color: .indigo)
                                    sleepStageRow(stage: "REM", duration: rem, color: .purple)
                                    sleepStageRow(stage: "Core", duration: core, color: .blue)
                                }
                                .padding(.top, AppSpacing.sm)
                            }
                        }
                    } else {
                        Text("No sleep data available")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 100)
                    }

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

            if let recommendation = recoveryData?.trainingRecommendation {
                VStack(spacing: AppSpacing.md) {
                    // Primary recommendation based on recovery status
                    recommendationCard(
                        icon: getRecommendationIcon(for: recommendation),
                        title: recommendation.rawValue,
                        message: recommendation.description,
                        color: getRecommendationColor(for: recommendation)
                    )
                    
                    // Additional recommendations based on limiting factors
                    if let factors = recoveryData?.limitingFactors {
                        if factors.contains(where: { $0.contains("sleep") || $0.contains("Sleep") }) {
                            recommendationCard(
                                icon: "moon.zzz.fill",
                                title: "Prioritize Sleep",
                                message: "Your sleep quality is affecting recovery. Aim for 8+ hours tonight.",
                                color: .indigo
                            )
                        }
                        
                        if factors.contains(where: { $0.contains("HRV") || $0.contains("hrv") }) {
                            recommendationCard(
                                icon: "heart.text.square.fill",
                                title: "Manage Stress",
                                message: "HRV indicates elevated stress. Consider meditation or breathing exercises.",
                                color: .purple
                            )
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }
    
    private func getRecommendationIcon(for recommendation: RecoveryInference.TrainingIntensity) -> String {
        switch recommendation {
        case .highIntensity:
            return "flame.fill"
        case .moderate:
            return "figure.walk"
        case .activeRecovery:
            return "figure.yoga"
        case .rest:
            return "bed.double.fill"
        }
    }
    
    private func getRecommendationColor(for recommendation: RecoveryInference.TrainingIntensity) -> Color {
        switch recommendation {
        case .highIntensity:
            return .orange
        case .moderate:
            return .blue
        case .activeRecovery:
            return .green
        case .rest:
            return .purple
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

// MARK: - TODO: Connect Real Data
// This view needs to be connected to HealthKitManager and RecoveryInference
// to display actual sleep data instead of placeholder content

// Temporary struct - remove when real data is connected
private struct RecoverySleepData: Identifiable {
    let id = UUID()
    let date: Date
    let deep: Double
    let rem: Double
    let light: Double
}
