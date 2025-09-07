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
    @State private var isInitializing = true

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
        BaseScreen {
            NavigationStack(path: $coordinator.navigationPath) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header is always visible
                        bodyHeaderImmediate()
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)
                            .animation(MotionToken.standardSpring, value: animateIn)

                        // Timeframe selector - always visible
                        timeframePicker
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.lg)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)
                            .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                        if let viewModel = viewModel {
                            // Real content when loaded
                            VStack(spacing: AppSpacing.xl) {
                                currentMetricsSection(viewModel)
                                    .padding(.top, AppSpacing.xl)
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                                weightTrendSection(viewModel)
                                    .padding(.top, AppSpacing.xl)
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

                                recoveryMetricsSection(viewModel)
                                    .padding(.top, AppSpacing.xl)
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)

                                progressPhotosSection(viewModel)
                                    .padding(.top, AppSpacing.xl)
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(MotionToken.standardSpring.delay(0.5), value: animateIn)

                                bodyCompositionGoals(viewModel)
                                    .padding(.horizontal, AppSpacing.screenPadding)
                                    .padding(.top, AppSpacing.xl)
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(MotionToken.standardSpring.delay(0.6), value: animateIn)
                            }
                        } else if isInitializing {
                            // Skeleton content while loading
                            bodySkeletonContent()
                        }
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
                .scrollContentBackground(.hidden)
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    if let viewModel = viewModel {
                        await viewModel.refresh()
                    }
                }
                .navigationDestination(for: BodyCoordinator.BodyDestination.self) { destination in
                    if let viewModel = viewModel {
                        destinationView(for: destination, viewModel: viewModel)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            HapticService.impact(.light)
                            coordinator.presentMeasurementEntry()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                        }
                        .accessibilityLabel("Add Measurement")
                        .disabled(viewModel == nil)
                        .opacity(viewModel == nil ? 0.5 : 1)
                    }
                }
                .sheet(isPresented: $coordinator.showingMeasurementEntry) {
                    if let viewModel = viewModel {
                        MeasurementEntryView(viewModel: viewModel)
                    }
                }
                .sheet(isPresented: $coordinator.showingPhotoCapture) {
                    if let viewModel = viewModel {
                        PhotoCaptureView(viewModel: viewModel)
                    }
                }
            }
        }
        .task {
            guard viewModel == nil else { return }
            isInitializing = true
            let factory = DIViewModelFactory(container: container)
            viewModel = try? await factory.makeBodyViewModel(user: user)
            isInitializing = false
            
            // Set up HealthKit observer for bidirectional sync
            viewModel?.setupHealthKitObserver()
            
            if !hasAppeared {
                hasAppeared = true
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
        .onAppear {
            coordinator.updateActiveTab(.body)
        }
        .accessibilityIdentifier("body.dashboard")
    }


    // MARK: - Header

    @ViewBuilder
    private func bodyHeaderImmediate() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            CascadeText("Body Metrics")
                .font(.system(size: 34, weight: .thin, design: .rounded))

            Text(bodyLoadingMessage())
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func bodyLoadingMessage() -> String {
        let components = Calendar.current.dateComponents([.weekday], from: Date())
        if components.weekday == 2 { // Monday
            return "Loading your weekly progress report..."
        } else if components.weekday == 1 { // Sunday
            return "Loading your recovery metrics..."
        } else {
            return "Analyzing your body composition data..."
        }
    }

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
        .glassEffect(.thick, in: .rect(cornerRadius: 16))
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
                        value: viewModel.hrv.map { "\(Int($0.converted(to: .milliseconds).value)) ms" } ?? "—",
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
                return "Great progress. You're consistently moving toward your goals. Keep up the momentum."
            case .increasing:
                if viewModel.userGoal == .muscleGain {
                    return "Solid gains. Your weight is trending up, supporting muscle growth."
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
    
    
    // MARK: - Progress Photos Section
    
    @ViewBuilder
    private func progressPhotosSection(_ viewModel: BodyViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Progress Photos")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, AppSpacing.screenPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    // Add photo button
                    Button {
                        HapticService.impact(.light)
                        coordinator.presentPhotoCapture()
                    } label: {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                            
                            Text("Add Photo")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 100, height: 120)
                        .glassEffect(in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    
                    // Placeholder for existing photos
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 100, height: 120)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
    }
    
    // MARK: - Body Composition Goals
    
    @ViewBuilder
    private func bodyCompositionGoals(_ viewModel: BodyViewModel) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Body Composition Goals")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                
                VStack(spacing: AppSpacing.sm) {
                    GoalProgressRow(
                        title: "Weight Goal",
                        current: viewModel.metrics?.weight?.converted(to: .pounds).value ?? 0,
                        target: 180,
                        unit: "lbs"
                    )
                    
                    GoalProgressRow(
                        title: "Body Fat Goal",
                        current: (viewModel.metrics?.bodyFatPercentage ?? 0) * 100,
                        target: 15,
                        unit: "%"
                    )
                    
                    GoalProgressRow(
                        title: "Lean Mass Goal",
                        current: viewModel.metrics?.leanBodyMass?.converted(to: .pounds).value ?? 0,
                        target: 160,
                        unit: "lbs"
                    )
                }
            }
            .padding(AppSpacing.md)
        }
    }
    
    
    // MARK: - Skeleton Content
    
    @ViewBuilder
    private func bodySkeletonContent() -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Key metrics skeleton
            HStack(spacing: AppSpacing.lg) {
                ForEach(0..<3, id: \.self) { _ in
                    GlassCard {
                        VStack(spacing: AppSpacing.sm) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 60, height: 30)
                                .shimmering()
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 50, height: 12)
                                .shimmering()
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 40, height: 10)
                                .shimmering()
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.top, AppSpacing.xl)
            
            // Weight chart skeleton
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 100, height: 20)
                            .shimmering()
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 80, height: 16)
                            .shimmering()
                    }
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 200)
                        .shimmering()
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            // Recovery metrics skeleton
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 150, height: 20)
                    .shimmering()
                
                GlassCard {
                    VStack(spacing: AppSpacing.md) {
                        ForEach(0..<4, id: \.self) { _ in
                            HStack {
                                Circle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .shimmering()
                                
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 80, height: 12)
                                        .shimmering()
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 60, height: 18)
                                        .shimmering()
                                }
                                
                                Spacer()
                                
                                Circle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                    .shimmering()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            // Progress photos skeleton
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 130, height: 20)
                    .shimmering()
                
                HStack(spacing: AppSpacing.md) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 100, height: 120)
                            .shimmering()
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)
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
                        y: .value("Weight", weight.converted(to: .pounds).value)
                    )
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    AreaMark(
                        x: .value("Date", date),
                        y: .value("Weight", weight.converted(to: .pounds).value)
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

struct GoalProgressRow: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    
    private var progress: Double {
        min(1.0, current / target)
    }
    
    private var difference: Double {
        target - current
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(current)) / \(Int(target)) \(unit)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
            
            if difference > 0 {
                Text("\(Int(difference)) \(unit) to go")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.tertiary)
            } else {
                Text("Goal achieved.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - Placeholder Views

struct MeasurementEntryView: View {
    let viewModel: BodyViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Measurement")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                
                Text("Coming Soon")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PhotoCaptureView: View {
    let viewModel: BodyViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Capture Progress Photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                
                Text("Coming Soon")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Progress Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let container = ModelContainer.preview
    let user = User(name: "Preview")
    
    BodyDashboardView(user: user)
        .withDIContainer(DIContainer())
        .modelContainer(container)
}
