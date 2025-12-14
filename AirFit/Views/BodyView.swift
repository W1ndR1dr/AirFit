import SwiftUI

struct BodyView: View {
    @State private var metrics: APIClient.BodyMetricsResponse?
    @State private var isLoading = true
    @State private var isSyncing = false

    private let apiClient = APIClient()

    var body: some View {
        ZStack {
            // Ethereal background
            EtherealBackground(currentTab: 5)
                .ignoresSafeArea()

            Group {
                if isLoading {
                    loadingView
                } else if let metrics = metrics {
                    if hasData(metrics) {
                        bodyContent(metrics)
                    } else {
                        emptyState
                    }
                } else {
                    errorState
                }
            }
        }
        .navigationTitle("Body")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSyncing {
                    ProgressView()
                        .tint(Theme.accent)
                } else {
                    Button {
                        Task { await refreshData() }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(AirFitSubtleButtonStyle())
                }
            }
        }
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
    }

    private func hasData(_ metrics: APIClient.BodyMetricsResponse) -> Bool {
        return metrics.current.weight_lbs != nil ||
               !metrics.weight_history.isEmpty
    }

    // MARK: - Body Content

    private func bodyContent(_ metrics: APIClient.BodyMetricsResponse) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero: Current Metrics
                currentMetricsSection(metrics)

                // Weight Chart
                if !metrics.weight_history.isEmpty {
                    chartSection(
                        title: "WEIGHT",
                        icon: "scalemass.fill",
                        color: Theme.accent,
                        data: metrics.weight_history,
                        unit: "lbs",
                        trend: metrics.trends.weight_change_30d,
                        trendInverted: true  // Down is good for weight
                    )
                }

                // Body Fat Chart
                if !metrics.body_fat_history.isEmpty {
                    chartSection(
                        title: "BODY FAT",
                        icon: "percent",
                        color: Theme.warning,
                        data: metrics.body_fat_history,
                        unit: "%",
                        trend: metrics.trends.body_fat_change_30d,
                        trendInverted: true  // Down is good for body fat
                    )
                }

                // Lean Mass Chart
                if !metrics.lean_mass_history.isEmpty {
                    chartSection(
                        title: "LEAN MASS",
                        icon: "figure.strengthtraining.traditional",
                        color: Theme.success,
                        data: metrics.lean_mass_history,
                        unit: "lbs",
                        trend: metrics.trends.lean_mass_change_30d,
                        trendInverted: false  // Up is good for lean mass
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Current Metrics Section

    private func currentMetricsSection(_ metrics: APIClient.BodyMetricsResponse) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "figure.stand")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                Text("CURRENT")
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(Theme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                // Weight
                metricTile(
                    value: metrics.current.weight_lbs.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "lbs",
                    label: "Weight",
                    color: Theme.accent
                )

                // Body Fat
                metricTile(
                    value: metrics.current.body_fat_pct.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "%",
                    label: "Body Fat",
                    color: Theme.warning
                )

                // Lean Mass
                metricTile(
                    value: metrics.current.lean_mass_lbs.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "lbs",
                    label: "Lean",
                    color: Theme.success
                )
            }

            // 30-day trend summary
            if let weightTrend = metrics.trends.weight_change_30d {
                HStack(spacing: 4) {
                    Image(systemName: weightTrend < 0 ? "arrow.down.right" : "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(weightTrend < 0 ? Theme.success : Theme.warning)
                    Text(String(format: "%.1f lbs this month", abs(weightTrend)))
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    private func metricTile(value: String, unit: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.metricLarge)
                    .foregroundStyle(color)
                Text(unit)
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }
            Text(label)
                .font(.labelMicro)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chart Section

    private func chartSection(
        title: String,
        icon: String,
        color: Color,
        data: [APIClient.MetricPoint],
        unit: String,
        trend: Double?,
        trendInverted: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)
                    Text(title)
                        .font(.labelHero)
                        .tracking(2)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                // Trend badge
                if let trend = trend {
                    let isPositive = trendInverted ? trend < 0 : trend > 0
                    HStack(spacing: 2) {
                        Image(systemName: trend < 0 ? "arrow.down" : "arrow.up")
                            .font(.caption2)
                        Text(String(format: "%.1f", abs(trend)))
                            .font(.labelMicro)
                    }
                    .foregroundStyle(isPositive ? Theme.success : Theme.error)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((isPositive ? Theme.success : Theme.error).opacity(0.12))
                    )
                }
            }

            // Chart
            LineChartView(data: data, color: color)
                .frame(height: 120)

            // Range label
            if let first = data.first, let last = data.last {
                HStack {
                    Text(formatDate(first.date))
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                    Text(formatDate(last.date))
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Theme.accent)

            Text("Loading body metrics...")
                .font(.labelMedium)
                .foregroundStyle(Theme.textMuted)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                    .opacity(0.5)

                Image(systemName: "figure.stand")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: 8) {
                Text("No body data yet")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)

                Text("Log your weight in the Health app to see your body composition trends here.")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await loadData() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accentGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(AirFitButtonStyle())
        }
        .padding(40)
    }

    // MARK: - Error State

    private var errorState: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundStyle(Theme.textMuted)

            VStack(spacing: 8) {
                Text("Couldn't load data")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)

                Text("Check your connection and try again.")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
            }

            Button {
                Task { await loadData() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accentGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(AirFitButtonStyle())
        }
        .padding(40)
    }

    // MARK: - Actions

    private func loadData() async {
        isLoading = true
        do {
            metrics = try await apiClient.getBodyMetrics(days: 90)
        } catch {
            print("Failed to load body metrics: \(error)")
            metrics = nil
        }
        withAnimation(.airfit) {
            isLoading = false
        }
    }

    private func refreshData() async {
        isSyncing = true
        await loadData()
        isSyncing = false
    }

    private func formatDate(_ isoDate: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: isoDate) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
        return isoDate
    }
}

// MARK: - Line Chart View

struct LineChartView: View {
    let data: [APIClient.MetricPoint]
    let color: Color

    private var values: [Double] {
        data.map { $0.value }
    }

    private var normalizedData: [Double] {
        guard let minVal = values.min(), let maxVal = values.max(), maxVal > minVal else {
            return values.map { _ in 0.5 }
        }
        // Add padding to range
        let range = maxVal - minVal
        let paddedMin = minVal - range * 0.1
        let paddedMax = maxVal + range * 0.1
        return values.map { ($0 - paddedMin) / (paddedMax - paddedMin) }
    }

    private var yAxisLabels: (min: String, max: String) {
        guard let minVal = values.min(), let maxVal = values.max() else {
            return ("—", "—")
        }
        return (String(format: "%.0f", minVal), String(format: "%.0f", maxVal))
    }

    // Horizontal step between data points (assuming 200pt chart width as fallback)
    private var stepX: Double {
        guard normalizedData.count > 1 else { return 0 }
        return 200 / Double(normalizedData.count - 1)
    }

    // Convert normalized data to CGPoints for a given size
    private func chartPoints(in size: CGSize) -> [CGPoint] {
        guard normalizedData.count > 1 else { return [] }
        let step = size.width / Double(normalizedData.count - 1)
        return normalizedData.enumerated().map { index, value in
            CGPoint(
                x: Double(index) * step,
                y: size.height * (1 - value)
            )
        }
    }

    // Draw a smooth Catmull-Rom spline through points
    private func addSmoothCurve(to path: inout Path, points: [CGPoint]) {
        guard points.count >= 2 else { return }

        path.move(to: points[0])

        if points.count == 2 {
            path.addLine(to: points[1])
            return
        }

        // Catmull-Rom spline with tension 0.5 for smooth curves
        let tension: CGFloat = 0.5

        for i in 0..<(points.count - 1) {
            let p0 = i > 0 ? points[i - 1] : points[0]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i < points.count - 2 ? points[i + 2] : points[i + 1]

            // Control points for cubic bezier
            let cp1x = p1.x + (p2.x - p0.x) / 6 * tension
            let cp1y = p1.y + (p2.y - p0.y) / 6 * tension
            let cp2x = p2.x - (p3.x - p1.x) / 6 * tension
            let cp2y = p2.y - (p3.y - p1.y) / 6 * tension

            path.addCurve(
                to: p2,
                control1: CGPoint(x: cp1x, y: cp1y),
                control2: CGPoint(x: cp2x, y: cp2y)
            )
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Y-axis labels
            VStack {
                Text(yAxisLabels.max)
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Text(yAxisLabels.min)
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }
            .frame(width: 32)

            // Chart area
            GeometryReader { geo in
                let points = chartPoints(in: geo.size)

                ZStack {
                    // Grid lines
                    VStack {
                        Divider().background(Theme.textMuted.opacity(0.2))
                        Spacer()
                        Divider().background(Theme.textMuted.opacity(0.2))
                        Spacer()
                        Divider().background(Theme.textMuted.opacity(0.2))
                    }

                    // Gradient fill under line (smooth)
                    Path { path in
                        guard points.count >= 2 else { return }
                        addSmoothCurve(to: &path, points: points)
                        // Close the path for fill
                        path.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height))
                        path.addLine(to: CGPoint(x: points.first!.x, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Smooth line (Catmull-Rom spline)
                    Path { path in
                        guard points.count >= 2 else { return }
                        addSmoothCurve(to: &path, points: points)
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Current value dot (last point)
                    if let lastPoint = points.last {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                            .position(x: lastPoint.x, y: lastPoint.y)

                        // Value label
                        if let currentValue = values.last {
                            Text(String(format: "%.1f", currentValue))
                                .font(.labelMicro)
                                .fontWeight(.semibold)
                                .foregroundStyle(color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Theme.surface)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                )
                                .position(x: lastPoint.x, y: lastPoint.y - 16)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BodyView()
    }
}
