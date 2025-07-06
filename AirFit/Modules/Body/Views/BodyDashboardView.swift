import SwiftUI
import SwiftData
import Charts
import PhotosUI

/// Enhanced Body Dashboard - Comprehensive body metrics tracking with AI insights
struct BodyDashboardView: View {
    let user: User
    @State private var viewModel: BodyViewModel?
    @Environment(\.diContainer) private var container
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    @State private var coordinator = BodyCoordinator()
    @State private var hasAppeared = false
    @State private var selectedTimeframe: BodyTimeframe = .month
    @State private var animateIn = false

    enum BodyTimeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"
        case year = "Year"

        var displayName: String { rawValue }

        var startDate: Date {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .week:
                return calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case .quarter:
                return calendar.date(byAdding: .month, value: -3, to: now) ?? now
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: now) ?? now
            }
        }
    }

    var body: some View {
        Group {
            if let viewModel = viewModel {
                bodyContent(viewModel)
            } else {
                ProgressView()
                    .task {
                        let factory = DIViewModelFactory(container: container)
                        viewModel = try? await factory.makeBodyViewModel(user: user)
                        // Set up HealthKit observer for bidirectional sync
                        viewModel?.setupHealthKitObserver()
                    }
            }
        }
    }

    @ViewBuilder
    private func bodyContent(_ viewModel: BodyViewModel) -> some View {
        BaseScreen {
            NavigationStack(path: $coordinator.navigationPath) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Dynamic header with AI insights
                        bodyHeader(viewModel)
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)
                            .animation(MotionToken.standardSpring, value: animateIn)

                        // Timeframe selector
                        timeframePicker
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.lg)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)
                            .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                        // Current metrics overview
                        currentMetricsSection(viewModel)
                            .padding(.top, AppSpacing.xl)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                        // Weight trend chart
                        weightTrendSection(viewModel)
                            .padding(.top, AppSpacing.xl)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

                        // Recovery metrics
                        recoveryMetricsSection(viewModel)
                            .padding(.top, AppSpacing.xl)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
                .scrollContentBackground(.hidden)
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    await viewModel.loadLatestMetrics()
                }
                .navigationDestination(for: BodyCoordinator.BodyDestination.self) { destination in
                    destinationView(for: destination, viewModel: viewModel)
                }
                .sheet(item: $coordinator.presentedSheet) { sheet in
                    sheetView(for: sheet, viewModel: viewModel)
                        .environmentObject(gradientManager)
                }
            }
        }
        .task {
            guard !hasAppeared else { return }
            hasAppeared = true

            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }

            await viewModel.loadLatestMetrics()
            await viewModel.loadWeightHistory()
        }
        .accessibilityIdentifier("body.dashboard")
    }

    // MARK: - Header

    @ViewBuilder
    private func bodyHeader(_ viewModel: BodyViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            CascadeText("Body Metrics")
                .font(.system(size: 34, weight: .thin, design: .rounded))

            // AI-powered body insight
            if let aiInsight = generateBodyInsight(from: viewModel) {
                Text(aiInsight)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Timeframe Picker

    private var timeframePicker: some View {
        HStack(spacing: 0) {
            ForEach(BodyTimeframe.allCases, id: \.self) { timeframe in
                timeframeButton(timeframe)
            }
        }
        .padding(4)
        .background(.thickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func timeframeButton(_ timeframe: BodyTimeframe) -> some View {
        Button {
            HapticService.impact(.light)
            withAnimation(MotionToken.standardSpring) {
                selectedTimeframe = timeframe
            }
        } label: {
            Text(timeframe.displayName)
                .font(.system(size: 16, weight: selectedTimeframe == timeframe ? .semibold : .medium))
                .foregroundStyle(selectedTimeframe == timeframe ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedTimeframe == timeframe ? Color.primary.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Current Metrics

    @ViewBuilder
    private func currentMetricsSection(_ viewModel: BodyViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Current Metrics")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, AppSpacing.screenPadding)

            if let metrics = viewModel.currentMetrics {
                currentMetricsGrid(metrics)
                    .padding(.horizontal, AppSpacing.screenPadding)
            } else {
                emptyMetricsState
                    .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    @ViewBuilder
    private func currentMetricsGrid(_ metrics: BodyMetrics) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
            MetricCard(
                title: "Weight",
                value: formatWeight(metrics.weight),
                trend: metrics.weightTrend,
                icon: "scalemass",
                color: .blue
            )

            MetricCard(
                title: "Body Fat",
                value: formatBodyFat(metrics.bodyFatPercentage),
                trend: metrics.bodyFatTrend,
                icon: "percent",
                color: .orange
            )

            MetricCard(
                title: "BMI",
                value: formatBMI(metrics.bmi),
                trend: nil,
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )

            MetricCard(
                title: "Lean Mass",
                value: formatWeight(metrics.leanBodyMass),
                trend: nil,
                icon: "figure.arms.open",
                color: .purple
            )
        }
    }

    private var emptyMetricsState: some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "figure")
                    .font(.system(size: 48))
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))

                Text("No body metrics recorded")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)

                Text("Your body metrics will sync automatically from Apple Health")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(AppSpacing.lg)
        }
    }

    // MARK: - Weight Trend

    @ViewBuilder
    private func weightTrendSection(_ viewModel: BodyViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Weight Trend")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                if viewModel.weightHistory.count > 1 {
                    NavigationLink(value: BodyCoordinator.BodyDestination.weightHistory) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)

            if viewModel.weightHistory.count > 1 {
                GlassCard {
                    WeightTrendChart(
                        data: filterDataForTimeframe(viewModel.weightHistory),
                        goal: viewModel.weightGoal
                    )
                    .frame(height: 200)
                    .padding(AppSpacing.md)
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            } else {
                emptyChartState(
                    icon: "chart.line.uptrend.xyaxis",
                    message: "Add at least 2 weight entries to see trends"
                )
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }

    // MARK: - Recovery Metrics

    @ViewBuilder
    private func recoveryMetricsSection(_ viewModel: BodyViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Recovery & Wellness")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, AppSpacing.screenPadding)

            GlassCard {
                VStack(spacing: AppSpacing.md) {
                    RecoveryMetricRow(
                        icon: "heart.fill",
                        title: "Resting Heart Rate",
                        value: viewModel.restingHeartRate.map { "\($0) bpm" } ?? "—",
                        trend: viewModel.heartRateTrend,
                        color: .red
                    )

                    RecoveryMetricRow(
                        icon: "waveform.path.ecg",
                        title: "Heart Rate Variability",
                        value: viewModel.hrv.map { "\(Int($0.value)) ms" } ?? "—",
                        trend: viewModel.hrvTrend,
                        color: .purple
                    )

                    RecoveryMetricRow(
                        icon: "bed.double.fill",
                        title: "Sleep Quality",
                        value: viewModel.sleepQuality?.capitalized ?? "—",
                        trend: nil,
                        color: .indigo
                    )

                    RecoveryMetricRow(
                        icon: "battery.75",
                        title: "Energy Level",
                        value: viewModel.energyLevel.map { "\($0)/10" } ?? "—",
                        trend: nil,
                        color: .green
                    )
                }
                .padding(AppSpacing.md)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    // MARK: - Helper Methods

    private func generateBodyInsight(from viewModel: BodyViewModel) -> String? {
        guard let metrics = viewModel.currentMetrics else {
            return "Start tracking your body metrics to unlock personalized insights and progress tracking."
        }

        if let trend = metrics.weightTrend {
            switch trend {
            case .decreasing:
                return "Great progress! You're consistently moving toward your goals. Keep up the momentum."
            case .increasing:
                if viewModel.userGoal == .muscleGain {
                    return "Solid gains! Your weight is trending up, supporting muscle growth."
                } else {
                    return "Let's refocus on your goals. Small adjustments can make a big difference."
                }
            case .stable:
                return "Your weight is stable. Perfect for maintenance or body recomposition."
            }
        }

        return "Track consistently to see meaningful trends and insights about your progress."
    }

    private func filterDataForTimeframe(_ data: [BodyMetrics]) -> [BodyMetrics] {
        data.filter { entry in
            if let date = entry.date {
                return date >= selectedTimeframe.startDate
            }
            return false
        }
    }

    private func formatWeight(_ weight: Measurement<UnitMass>?) -> String {
        guard let weight = weight else { return "—" }
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: weight)
    }

    private func formatBodyFat(_ percentage: Double?) -> String {
        guard let percentage = percentage else { return "—" }
        return String(format: "%.1f%%", percentage)
    }

    private func formatBMI(_ bmi: Double?) -> String {
        guard let bmi = bmi else { return "—" }
        return String(format: "%.1f", bmi)
    }

    @ViewBuilder
    private func emptyChartState(icon: String, message: String) -> some View {
        GlassCard {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)

                Text(message)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: BodyCoordinator.BodyDestination, viewModel: BodyViewModel) -> some View {
        switch destination {
        case .weightHistory:
            Text("Weight History")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .bodyFatHistory:
            Text("Body Fat History")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .bmiHistory:
            Text("BMI History")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        case .leanMassHistory:
            Text("Lean Mass History")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: BodyCoordinator.BodySheet, viewModel: BodyViewModel) -> some View {
        switch sheet {
        case .addMeasurement:
            Text("Add Measurement")
        case .capturePhoto:
            Text("Capture Photo")
        case .settings:
            Text("Body Settings")
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let trend: BodyMetrics.Trend?
    let icon: String
    let color: Color

    @State private var animateIn = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(color)

                    Spacer()

                    if let trend = trend {
                        BodyTrendIndicator(trend: trend)
                    }
                }

                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .opacity(animateIn ? 1 : 0)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(AppSpacing.md)
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
        }
    }
}

struct BodyTrendIndicator: View {
    let trend: BodyMetrics.Trend

    var icon: String {
        switch trend {
        case .increasing: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .decreasing: return "arrow.down.right"
        }
    }

    var color: Color {
        switch trend {
        case .increasing: return .green
        case .stable: return .yellow
        case .decreasing: return .red
        }
    }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(color)
    }
}

struct WeightTrendChart: View {
    let data: [BodyMetrics]
    let goal: Double?
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    var body: some View {
        Chart {
            ForEach(data.indices, id: \.self) { index in
                let entry = data[index]
                if let date = entry.date, let weight = entry.weight {
                    LineMark(
                        x: .value("Date", date),
                        y: .value("Weight", weight.value)
                    )
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    AreaMark(
                        x: .value("Date", date),
                        y: .value("Weight", weight.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                gradientManager.active.colors(for: colorScheme)[0].opacity(0.3),
                                gradientManager.active.colors(for: colorScheme)[0].opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }

            if let goal = goal {
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .trailing, alignment: .trailing) {
                        Text("Goal")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
    }
}

struct RecoveryMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let trend: BodyMetrics.Trend?
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            if let trend = trend {
                BodyTrendIndicator(trend: trend)
            }
        }
    }
}


// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: User.self)
    let user = User(name: "Preview")
    container.mainContext.insert(user)

    return BodyDashboardView(user: user)
        .withDIContainer(DIContainer())
        .modelContainer(container)
}
