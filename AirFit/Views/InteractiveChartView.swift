import SwiftUI

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
    var smoothedValue: Double?  // EMA-smoothed value for trend line

    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        lhs.id == rhs.id
    }

    /// The value to use for the trend line (smoothed if available)
    var trendValue: Double { smoothedValue ?? value }
}

// MARK: - Smoothing Algorithm

enum ChartSmoothing {
    /// Apply Exponential Moving Average smoothing to data points
    /// - Parameters:
    ///   - data: Raw data points
    ///   - period: Number of points for EMA calculation (higher = smoother). 0 = no smoothing.
    /// - Returns: Data points with smoothedValue populated
    static func applyEMA(to data: [ChartDataPoint], period: Int) -> [ChartDataPoint] {
        // No smoothing if period is 0 or not enough data
        guard data.count > 1, period > 0 else {
            // Return data with smoothedValue = value (no smoothing)
            return data.map { point in
                var p = point
                p.smoothedValue = point.value
                return p
            }
        }

        // EMA multiplier: k = 2 / (N + 1)
        let k = 2.0 / Double(period + 1)

        var result: [ChartDataPoint] = []
        var ema = data[0].value  // Start with first value

        for point in data {
            // EMA = (value * k) + (previous_ema * (1 - k))
            ema = (point.value * k) + (ema * (1 - k))

            var smoothedPoint = point
            smoothedPoint.smoothedValue = ema
            result.append(smoothedPoint)
        }

        return result
    }

    /// Determine optimal smoothing period based on data count and time span
    /// Returns 0 for week view (no smoothing - not enough data for meaningful trend)
    static func optimalPeriod(for data: [ChartDataPoint]) -> Int {
        guard let first = data.first?.date, let last = data.last?.date else { return 0 }

        let daySpan = Calendar.current.dateComponents([.day], from: first, to: last).day ?? 0
        let dataCount = data.count

        // Adaptive EMA smoothing (keeps fit accurate, bezier curves handle visual smoothness)
        // - Week view: NO smoothing (too few data points)
        // - Month view: light smoothing (5-7 day EMA)
        // - Year view: moderate smoothing (10-14 day EMA)
        // - All time: moderate smoothing (14-21 day EMA)

        if daySpan <= 7 {
            return 0  // No smoothing for week view
        } else if daySpan <= 30 {
            return min(7, max(5, dataCount / 5))
        } else if daySpan <= 365 {
            return min(14, max(10, dataCount / 20))
        } else {
            return min(21, max(14, dataCount / 25))
        }
    }
}

// MARK: - Time Range

enum ChartTimeRange: String, CaseIterable {
    case week = "W"
    case month = "M"
    case year = "Y"
    case all = "ALL"

    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .all: return nil
        }
    }

    var label: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        case .all: return "All Time"
        }
    }
}

// MARK: - Interactive Chart View

struct InteractiveChartView: View {
    let data: [ChartDataPoint]
    let color: Color
    let unit: String
    let formatValue: (Double) -> String
    let showSmoothing: Bool

    @State private var selectedPoint: ChartDataPoint?
    @State private var touchLocation: CGPoint = .zero
    @State private var showingDetail = false

    private let chartHeight: CGFloat = 180
    private let yAxisWidth: CGFloat = 45
    private let rawDotRadius: CGFloat = 2.5
    private let selectedDotRadius: CGFloat = 10

    // Smoothed data for trend line
    private var smoothedData: [ChartDataPoint] {
        guard showSmoothing, data.count > 3 else { return data }
        let period = ChartSmoothing.optimalPeriod(for: data)
        return ChartSmoothing.applyEMA(to: data, period: period)
    }

    init(
        data: [ChartDataPoint],
        color: Color,
        unit: String = "",
        showSmoothing: Bool = true,
        formatValue: @escaping (Double) -> String = { String(format: "%.1f", $0) }
    ) {
        self.data = data
        self.color = color
        self.unit = unit
        self.showSmoothing = showSmoothing
        self.formatValue = formatValue
    }

    var body: some View {
        VStack(spacing: 0) {
            // Selected point detail
            if let point = selectedPoint, showingDetail {
                selectedPointDetail(point)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Chart area
            GeometryReader { geometry in
                let chartWidth = geometry.size.width - yAxisWidth

                HStack(spacing: 0) {
                    // Y-axis labels
                    yAxisLabels
                        .frame(width: yAxisWidth)

                    // Chart content
                    ZStack {
                        // Grid lines
                        gridLines(width: chartWidth)

                        // Line and area
                        if data.count >= 2 {
                            chartContent(width: chartWidth, height: chartHeight)
                        } else if data.count == 1 {
                            singlePointView(width: chartWidth, height: chartHeight)
                        }

                        // Touch overlay
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        handleTouch(at: value.location, chartWidth: chartWidth)
                                    }
                                    .onEnded { _ in
                                        // Keep selection visible for a moment
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            withAnimation(.airfit) {
                                                showingDetail = false
                                                selectedPoint = nil
                                            }
                                        }
                                    }
                            )
                    }
                    .frame(width: chartWidth, height: chartHeight)
                }
            }
            .frame(height: chartHeight)

            // X-axis labels
            xAxisLabels
                .padding(.leading, yAxisWidth)
                .padding(.top, 8)
        }
        .sensoryFeedback(.selection, trigger: selectedPoint?.id)
    }

    // MARK: - Y Axis

    private var yAxisLabels: some View {
        let (minVal, maxVal) = yAxisRange
        let midVal = (minVal + maxVal) / 2

        return VStack {
            Text(formatValue(maxVal))
            Spacer()
            Text(formatValue(midVal))
            Spacer()
            Text(formatValue(minVal))
        }
        .font(.labelMicro)
        .foregroundStyle(Theme.textMuted)
        .frame(height: chartHeight)
    }

    private var yAxisRange: (min: Double, max: Double) {
        guard !data.isEmpty else { return (0, 100) }

        let values = data.map(\.value)
        let dataMin = values.min() ?? 0
        let dataMax = values.max() ?? 100

        // Add padding (10% on each side, minimum 1 unit)
        let range = dataMax - dataMin
        let padding = max(range * 0.1, 1)

        return (dataMin - padding, dataMax + padding)
    }

    // MARK: - X Axis

    private var xAxisLabels: some View {
        guard let first = data.first?.date, let last = data.last?.date else {
            return AnyView(EmptyView())
        }

        let formatter = DateFormatter()
        let daySpan = Calendar.current.dateComponents([.day], from: first, to: last).day ?? 0

        if daySpan <= 7 {
            formatter.dateFormat = "EEE"
        } else if daySpan <= 60 {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM ''yy"
        }

        return AnyView(
            HStack {
                Text(formatter.string(from: first))
                Spacer()
                if daySpan > 1 {
                    Text(formatter.string(from: last))
                }
            }
            .font(.labelMicro)
            .foregroundStyle(Theme.textMuted)
        )
    }

    // MARK: - Grid Lines

    private func gridLines(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<3) { i in
                if i > 0 { Spacer() }
                Rectangle()
                    .fill(Theme.textMuted.opacity(0.1))
                    .frame(height: 1)
                if i < 2 { Spacer() }
            }
        }
        .frame(width: width, height: chartHeight)
    }

    // MARK: - Chart Content

    private func chartContent(width: CGFloat, height: CGFloat) -> some View {
        let processedData = smoothedData
        let trendPoints = normalizedTrendPoints(data: processedData, width: width, height: height)
        let rawPoints = normalizedRawPoints(data: processedData, width: width, height: height)

        return ZStack {
            // Gradient fill under smoothed trend line
            LinearGradient(
                colors: [color.opacity(0.25), color.opacity(0.05), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .mask(smoothCurveAreaPath(through: trendPoints, height: height))

            // Smoothed trend line (thicker, main visual) - bezier curves for smoothness
            smoothCurvePath(through: trendPoints)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

            // Raw data points as subtle dots (only show significant deviations from trend)
            ForEach(Array(processedData.enumerated()), id: \.element.id) { index, point in
                let rawPos = rawPoints[index]
                let trendPos = trendPoints[index]
                let isSelected = selectedPoint?.id == point.id

                // Only show dots that deviate noticeably from trend, or thin out dense data
                let deviationThreshold: CGFloat = 3 // pixels
                let showEveryNth = max(1, processedData.count / 40) // limit to ~40 dots max
                let significantDeviation = abs(rawPos.y - trendPos.y) > deviationThreshold
                let shouldShow = !isSelected && (significantDeviation || index % showEveryNth == 0)

                if shouldShow {
                    Circle()
                        .fill(color.opacity(0.35))
                        .frame(width: rawDotRadius * 2, height: rawDotRadius * 2)
                        .position(rawPos)
                }
            }

            // Selected point highlight (shows raw value position)
            if let point = selectedPoint, let index = processedData.firstIndex(where: { $0.id == point.id }) {
                let rawPos = rawPoints[index]
                let trendPos = trendPoints[index]

                // Vertical indicator line
                Rectangle()
                    .fill(color.opacity(0.3))
                    .frame(width: 1, height: height)
                    .position(x: rawPos.x, y: height / 2)

                // Line connecting raw to trend (shows smoothing delta)
                if showSmoothing && abs(rawPos.y - trendPos.y) > 4 {
                    Path { path in
                        path.move(to: rawPos)
                        path.addLine(to: trendPos)
                    }
                    .stroke(color.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }

                // Trend point on line
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .position(trendPos)

                // Raw data point (larger, highlighted)
                Circle()
                    .fill(Theme.surface)
                    .overlay(
                        Circle()
                            .stroke(color, lineWidth: 3)
                    )
                    .frame(width: selectedDotRadius * 2, height: selectedDotRadius * 2)
                    .shadow(color: color.opacity(0.5), radius: 8)
                    .position(rawPos)
            }
        }
    }

    private func singlePointView(width: CGFloat, height: CGFloat) -> some View {
        let point = data[0]
        let isSelected = selectedPoint?.id == point.id

        return Circle()
            .fill(isSelected ? color : Theme.surface)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: isSelected ? 3 : 2)
            )
            .frame(width: isSelected ? selectedDotRadius * 2 : rawDotRadius * 2)
            .position(x: width / 2, y: height / 2)
    }

    // MARK: - Selection Detail

    private func selectedPointDetail(_ point: ChartDataPoint) -> some View {
        HStack(spacing: 16) {
            // Raw value (actual reading)
            VStack(alignment: .leading, spacing: 2) {
                Text(formatValue(point.value) + (unit.isEmpty ? "" : " \(unit)"))
                    .font(.metricSmall)
                    .foregroundStyle(color)

                Text(formatDetailDate(point.date))
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            // Show smoothed trend value if different
            if showSmoothing, let smoothed = point.smoothedValue, abs(smoothed - point.value) > 0.1 {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.path")
                            .font(.caption2)
                        Text(formatValue(smoothed))
                            .font(.labelMedium)
                    }
                    .foregroundStyle(color.opacity(0.7))

                    Text("trend")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer()

            // Delta from trend (noise indicator)
            if showSmoothing, let smoothed = point.smoothedValue {
                let delta = point.value - smoothed
                if abs(delta) > 0.1 {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption2)
                            Text(String(format: "%.1f", abs(delta)))
                                .font(.labelMicro)
                        }
                        .foregroundStyle(Theme.textSecondary)

                        Text("vs trend")
                            .font(.labelMicro)
                            .foregroundStyle(Theme.textMuted)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Theme.surface)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    /// Points normalized using smoothed/trend values (for the trend line)
    private func normalizedTrendPoints(data: [ChartDataPoint], width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard data.count >= 2 else { return [] }

        let (minVal, maxVal) = yAxisRange
        let valueRange = maxVal - minVal

        guard let firstDate = data.first?.date, let lastDate = data.last?.date else { return [] }
        let timeRange = lastDate.timeIntervalSince(firstDate)

        return data.map { point in
            let x: CGFloat
            if timeRange > 0 {
                x = CGFloat(point.date.timeIntervalSince(firstDate) / timeRange) * width
            } else {
                x = width / 2
            }

            let normalizedY = (point.trendValue - minVal) / valueRange
            let y = height - (CGFloat(normalizedY) * height)

            return CGPoint(x: x, y: y)
        }
    }

    /// Points normalized using raw values (for data point dots)
    private func normalizedRawPoints(data: [ChartDataPoint], width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard data.count >= 2 else { return [] }

        let (minVal, maxVal) = yAxisRange
        let valueRange = maxVal - minVal

        guard let firstDate = data.first?.date, let lastDate = data.last?.date else { return [] }
        let timeRange = lastDate.timeIntervalSince(firstDate)

        return data.map { point in
            let x: CGFloat
            if timeRange > 0 {
                x = CGFloat(point.date.timeIntervalSince(firstDate) / timeRange) * width
            } else {
                x = width / 2
            }

            let normalizedY = (point.value - minVal) / valueRange
            let y = height - (CGFloat(normalizedY) * height)

            return CGPoint(x: x, y: y)
        }
    }

    private func handleTouch(at location: CGPoint, chartWidth: CGFloat) {
        let processedData = smoothedData
        guard !processedData.isEmpty else { return }

        let points = normalizedRawPoints(data: processedData, width: chartWidth, height: chartHeight)

        // Find closest point
        var closestIndex = 0
        var closestDistance = CGFloat.infinity

        for (index, point) in points.enumerated() {
            let distance = abs(point.x - location.x)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }

        let newSelection = processedData[closestIndex]
        if selectedPoint?.id != newSelection.id {
            withAnimation(.spring(response: 0.25)) {
                selectedPoint = newSelection
                showingDetail = true
            }
        }
    }

    private func formatDetailDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Smooth Curve Helpers (Catmull-Rom to Bezier)

    /// Creates a smooth bezier curve path through all points
    private func smoothCurvePath(through points: [CGPoint]) -> Path {
        Path { path in
            guard points.count >= 2 else { return }

            if points.count == 2 {
                path.move(to: points[0])
                path.addLine(to: points[1])
                return
            }

            path.move(to: points[0])

            for i in 0..<(points.count - 1) {
                let p0 = i > 0 ? points[i - 1] : points[0]
                let p1 = points[i]
                let p2 = points[i + 1]
                let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]

                let (cp1, cp2) = catmullRomToBezier(p0: p0, p1: p1, p2: p2, p3: p3)
                path.addCurve(to: p2, control1: cp1, control2: cp2)
            }
        }
    }

    /// Creates a closed area path with smooth curve on top
    private func smoothCurveAreaPath(through points: [CGPoint], height: CGFloat) -> Path {
        Path { path in
            guard let first = points.first, let last = points.last else { return }

            // Start at bottom-left
            path.move(to: CGPoint(x: first.x, y: height))
            path.addLine(to: first)

            if points.count == 2 {
                path.addLine(to: points[1])
            } else if points.count > 2 {
                for i in 0..<(points.count - 1) {
                    let p0 = i > 0 ? points[i - 1] : points[0]
                    let p1 = points[i]
                    let p2 = points[i + 1]
                    let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]

                    let (cp1, cp2) = catmullRomToBezier(p0: p0, p1: p1, p2: p2, p3: p3)
                    path.addCurve(to: p2, control1: cp1, control2: cp2)
                }
            }

            // Close at bottom-right
            path.addLine(to: CGPoint(x: last.x, y: height))
            path.closeSubpath()
        }
    }

    /// Convert Catmull-Rom spline segment to cubic Bezier control points
    private func catmullRomToBezier(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> (CGPoint, CGPoint) {
        let tension: CGFloat = 0.25  // Smooth curves that still follow the data

        let cp1 = CGPoint(
            x: p1.x + (p2.x - p0.x) * tension,
            y: p1.y + (p2.y - p0.y) * tension
        )
        let cp2 = CGPoint(
            x: p2.x - (p3.x - p1.x) * tension,
            y: p2.y - (p3.y - p1.y) * tension
        )

        return (cp1, cp2)
    }
}

// MARK: - Time Range Picker

struct ChartTimeRangePicker: View {
    @Binding var selection: ChartTimeRange

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ChartTimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.airfit) {
                        selection = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.labelMedium)
                        .foregroundStyle(selection == range ? .white : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selection == range
                                ? Capsule().fill(Theme.accent)
                                : Capsule().fill(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Theme.surface)
        )
        .sensoryFeedback(.selection, trigger: selection)
    }
}

// MARK: - Preview

#Preview {
    let sampleData = (0..<30).map { i in
        ChartDataPoint(
            date: Calendar.current.date(byAdding: .day, value: -29 + i, to: Date())!,
            value: 175.0 + Double.random(in: -3...3)
        )
    }

    return VStack(spacing: 32) {
        InteractiveChartView(
            data: sampleData,
            color: Theme.accent,
            unit: "lbs"
        )
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding()
    }
    .background(Theme.background)
}
