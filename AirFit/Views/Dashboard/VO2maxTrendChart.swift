import SwiftUI

/// VO2max Trend Chart showing cardiorespiratory fitness with zone bands.
///
/// Design principles:
/// - Zone bands based on age/gender norms (currently 30-40 y/o male)
/// - Higher VO2max = better cardiovascular fitness
/// - Trend indicator shows improvement/decline direction
/// - Info tooltip for Apple Watch measurement limitations
struct VO2maxTrendChart: View {
    let data: [VO2maxReading]

    @State private var selectedPoint: VO2maxReading?
    @State private var showingDetail = false
    @State private var showingInfoTooltip = false

    private let chartHeight: CGFloat = 150

    // Zone definitions (30-40 y/o male norms)
    // Higher thresholds = better fitness
    private let zones: [(threshold: Double, label: String, color: Color)] = [
        (50, "Excellent", Theme.success),
        (45, "Good", Color(hex: "84CC16")),      // Lime green
        (40, "Above Avg", Theme.accent),
        (35, "Average", Theme.warning),
        (0, "Below Avg", Theme.error)
    ]

    // LOESS smoothed data (0.25 bandwidth for VO2max - less frequent measurements)
    private var smoothedData: [ChartDataPoint] {
        let points = data.map { ChartDataPoint(date: $0.date, value: $0.vo2max) }
        guard points.count > 3 else { return points }
        return ChartSmoothing.applyLOESS(to: points, bandwidth: 0.25)
    }

    // Trend direction
    private var trendDirection: TrendDirection {
        guard smoothedData.count >= 2 else { return .stable }

        let recentHalf = smoothedData.suffix(smoothedData.count / 2)
        let olderHalf = smoothedData.prefix(smoothedData.count / 2)

        guard !recentHalf.isEmpty, !olderHalf.isEmpty else { return .stable }

        let recentAvg = recentHalf.reduce(0) { $0 + $1.trendValue } / Double(recentHalf.count)
        let olderAvg = olderHalf.reduce(0) { $0 + $1.trendValue } / Double(olderHalf.count)

        let change = recentAvg - olderAvg
        // VO2max changes slowly, 1.0 ml/kg/min is meaningful
        if change > 1.0 { return .improving }
        if change < -1.0 { return .declining }
        return .stable
    }

    enum TrendDirection {
        case improving, stable, declining

        var label: String {
            switch self {
            case .improving: return "Improving"
            case .stable: return "Stable"
            case .declining: return "Declining"
            }
        }

        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .declining: return "arrow.down.right"
            }
        }

        var color: Color {
            switch self {
            case .improving: return Theme.success
            case .stable: return Theme.textSecondary
            case .declining: return Theme.warning
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "lungs.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                    Text("VO2 MAX")
                        .font(.labelHero)
                        .tracking(2)
                        .foregroundStyle(Theme.textMuted)

                    // Info button for Apple Watch limitations
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showingInfoTooltip.toggle()
                        }
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                Spacer()

                // Trend indicator
                HStack(spacing: 4) {
                    Image(systemName: trendDirection.icon)
                        .font(.caption)
                    Text(trendDirection.label)
                        .font(.labelMicro)
                }
                .foregroundStyle(trendDirection.color)
            }

            // Info tooltip (collapsible)
            if showingInfoTooltip {
                infoTooltip
            }

            // Selected point detail
            if let point = selectedPoint, showingDetail {
                selectedPointDetail(point)
            }

            // Chart with zone bands
            GeometryReader { geo in
                ZStack {
                    // Zone background bands
                    zoneBands(width: geo.size.width, height: geo.size.height)

                    // Trend line
                    if smoothedData.count >= 2 {
                        trendLine(width: geo.size.width, height: geo.size.height)
                    }

                    // Individual points
                    pointOverlay(width: geo.size.width, height: geo.size.height)

                    // Touch handler
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleTouch(at: value.location, width: geo.size.width, height: geo.size.height)
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation(.airfit) {
                                            showingDetail = false
                                            selectedPoint = nil
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(height: chartHeight)

            // Legend
            legendRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
        .sensoryFeedback(.selection, trigger: selectedPoint?.id)
    }

    // MARK: - Info Tooltip

    private var infoTooltip: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "applewatch")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)

            Text("Apple Watch estimates VO2max from outdoor walking/running with GPS. If you primarily lift weights or do indoor cardio, this estimate may be inaccurate.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.accent.opacity(0.08))
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Selected Point Detail

    private func selectedPointDetail(_ point: VO2maxReading) -> some View {
        HStack {
            Text(String(format: "%.1f", point.vo2max))
                .font(.metricSmall)
                .foregroundStyle(colorForVO2max(point.vo2max))
            Text("ml/kg/min")
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)

            Text("•")
                .foregroundStyle(Theme.textMuted)

            Text(point.category.rawValue)
                .font(.labelMedium)
                .foregroundStyle(colorForVO2max(point.vo2max))

            Text("•")
                .foregroundStyle(Theme.textMuted)

            Text(formatDate(point.date))
                .font(.caption)
                .foregroundStyle(Theme.textMuted)

            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - Chart Components

    private func zoneBands(width: CGFloat, height: CGFloat) -> some View {
        let (minVal, maxVal) = valueRange
        let range = maxVal - minVal

        return ZStack {
            ForEach(Array(zones.enumerated()), id: \.offset) { index, zone in
                let nextThreshold = index > 0 ? zones[index - 1].threshold : 60
                let zoneHeight = CGFloat((nextThreshold - zone.threshold) / range) * height
                let yPos = height * (1 - CGFloat((nextThreshold - minVal) / range)) + zoneHeight / 2

                Rectangle()
                    .fill(zone.color.opacity(0.08))
                    .frame(width: width, height: zoneHeight)
                    .position(x: width / 2, y: yPos)
            }

            // Zone divider lines
            ForEach(zones.dropLast(), id: \.threshold) { zone in
                let y = height * (1 - CGFloat((zone.threshold - minVal) / range))
                Rectangle()
                    .fill(Theme.textMuted.opacity(0.2))
                    .frame(width: width, height: 1)
                    .position(x: width / 2, y: y)
            }
        }
    }

    private func trendLine(width: CGFloat, height: CGFloat) -> some View {
        let points = normalizedPoints(width: width, height: height)

        return Path { path in
            guard points.count >= 2 else { return }
            path.move(to: points[0])

            for i in 0..<(points.count - 1) {
                let p0 = i > 0 ? points[i - 1] : points[0]
                let p1 = points[i]
                let p2 = points[i + 1]
                let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]

                let tension: CGFloat = 0.25
                let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) * tension, y: p1.y + (p2.y - p0.y) * tension)
                let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) * tension, y: p2.y - (p3.y - p1.y) * tension)

                path.addCurve(to: p2, control1: cp1, control2: cp2)
            }
        }
        .stroke(
            Theme.accent,
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }

    private func pointOverlay(width: CGFloat, height: CGFloat) -> some View {
        let points = normalizedRawPoints(width: width, height: height)

        return ZStack {
            // Raw data points
            ForEach(Array(zip(data.indices, points)), id: \.0) { index, point in
                Circle()
                    .fill(colorForVO2max(data[index].vo2max).opacity(0.5))
                    .frame(width: 6, height: 6)
                    .position(point)
            }

            // Selected point highlight
            if let selected = selectedPoint,
               let index = data.firstIndex(where: { $0.id == selected.id }),
               index < points.count {
                let pos = points[index]

                // Vertical line
                Rectangle()
                    .fill(Theme.accent.opacity(0.5))
                    .frame(width: 1, height: height)
                    .position(x: pos.x, y: height / 2)

                // Point
                Circle()
                    .fill(Theme.surface)
                    .overlay(Circle().stroke(colorForVO2max(selected.vo2max), lineWidth: 3))
                    .frame(width: 14, height: 14)
                    .shadow(color: Theme.accent.opacity(0.5), radius: 6)
                    .position(pos)
            }
        }
    }

    private var legendRow: some View {
        HStack(spacing: 12) {
            // Only show first 3 zones to save space
            ForEach(zones.prefix(3), id: \.threshold) { zone in
                HStack(spacing: 4) {
                    Circle()
                        .fill(zone.color)
                        .frame(width: 6, height: 6)
                    Text(zone.label)
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer()

            // Date range
            if let first = data.first?.date, let last = data.last?.date {
                Text("\(formatShortDate(first)) - \(formatShortDate(last))")
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }

    // MARK: - Helpers

    private var valueRange: (min: Double, max: Double) {
        // Fixed range for zones: 25-60 ml/kg/min (covers most adults)
        return (25, 60)
    }

    private func normalizedPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard smoothedData.count >= 2 else { return [] }

        let (minVal, maxVal) = valueRange
        let range = maxVal - minVal

        guard let firstDate = smoothedData.first?.date,
              let lastDate = smoothedData.last?.date else { return [] }

        let timeRange = lastDate.timeIntervalSince(firstDate)

        return smoothedData.map { point in
            let x = timeRange > 0
                ? CGFloat(point.date.timeIntervalSince(firstDate) / timeRange) * width
                : width / 2
            let y = height * (1 - CGFloat((point.trendValue - minVal) / range))
            return CGPoint(x: x, y: y)
        }
    }

    private func normalizedRawPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard !data.isEmpty else { return [] }

        let (minVal, maxVal) = valueRange
        let range = maxVal - minVal

        guard let firstDate = data.first?.date,
              let lastDate = data.last?.date,
              firstDate != lastDate else {
            return data.enumerated().map { index, _ in
                let x = CGFloat(index) / CGFloat(max(1, data.count - 1)) * width
                let y = height * (1 - CGFloat((data[index].vo2max - minVal) / range))
                return CGPoint(x: x, y: y)
            }
        }

        let timeRange = lastDate.timeIntervalSince(firstDate)

        return data.map { reading in
            let x = CGFloat(reading.date.timeIntervalSince(firstDate) / timeRange) * width
            let y = height * (1 - CGFloat((reading.vo2max - minVal) / range))
            return CGPoint(x: x, y: y)
        }
    }

    private func handleTouch(at location: CGPoint, width: CGFloat, height: CGFloat) {
        let points = normalizedRawPoints(width: width, height: height)
        guard !points.isEmpty else { return }

        var closestIndex = 0
        var closestDistance = CGFloat.infinity

        for (index, point) in points.enumerated() {
            let distance = abs(point.x - location.x)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }

        let newSelection = data[closestIndex]
        if selectedPoint?.id != newSelection.id {
            withAnimation(.spring(response: 0.2)) {
                selectedPoint = newSelection
                showingDetail = true
            }
        }
    }

    private func colorForVO2max(_ value: Double) -> Color {
        switch value {
        case 50...: return Theme.success
        case 45..<50: return Color(hex: "84CC16")
        case 40..<45: return Theme.accent
        case 35..<40: return Theme.warning
        default: return Theme.error
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleData: [VO2maxReading] = (0..<12).map { week in
        VO2maxReading(
            date: Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date())!,
            vo2max: Double.random(in: 38...48)
        )
    }.reversed()

    return VStack {
        VO2maxTrendChart(data: sampleData)
    }
    .padding()
    .background(Theme.background)
}
