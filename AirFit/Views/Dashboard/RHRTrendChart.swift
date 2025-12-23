import SwiftUI

/// Resting HR Trend Chart with zone bands relative to baseline.
///
/// Design: Lower RHR indicates better cardiovascular fitness.
/// - Well below baseline = excellent (green zone)
/// - Near baseline = normal (neutral zone)
/// - Above baseline = elevated (warning/error zone)
///
/// Uses LOESS smoothing and shows current status badge.
struct RHRTrendChart: View {
    let data: [RestingHRReading]
    let baseline: (mean: Double, standardDeviation: Double, sampleCount: Int)?

    @State private var selectedPoint: RestingHRReading?
    @State private var showingDetail = false

    private let chartHeight: CGFloat = 150

    // LOESS smoothed data (0.3 bandwidth for moderate smoothing)
    private var smoothedData: [ChartDataPoint] {
        let points = data.map { ChartDataPoint(date: $0.date, value: $0.bpm) }
        guard points.count > 3 else { return points }
        return ChartSmoothing.applyLOESS(to: points, bandwidth: 0.3)
    }

    // Current status based on latest value vs baseline
    private var currentStatus: (label: String, color: Color, deviation: Double)? {
        guard let latest = data.last,
              let baseline = baseline,
              baseline.sampleCount >= 5 else { return nil }

        let deviation = latest.bpm - baseline.mean

        switch deviation {
        case ...(-5): return ("Excellent", Theme.success, deviation)
        case -5..<3: return ("Normal", Theme.textSecondary, deviation)
        case 3..<8: return ("Elevated", Theme.warning, deviation)
        default: return ("High", Theme.error, deviation)
        }
    }

    // Zone definitions relative to baseline
    private var zones: [(minOffset: Double, maxOffset: Double, label: String, color: Color)] {
        [
            (-100, -5, "Excellent", Theme.success),
            (-5, 3, "Normal", Theme.textSecondary),
            (3, 8, "Elevated", Theme.warning),
            (8, 100, "High", Theme.error)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with current status
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.error)
                    Text("RESTING HR")
                        .font(.labelHero)
                        .tracking(2)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                // Current status badge
                if let status = currentStatus {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 6, height: 6)
                        Text(status.label)
                            .font(.labelMicro)
                            .foregroundStyle(status.color)
                        Text("(\(status.deviation >= 0 ? "+" : "")\(Int(status.deviation)))")
                            .font(.labelMicro)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }

            // Selected point detail
            if let point = selectedPoint, showingDetail {
                selectedPointDetail(point)
            }

            // Chart with zone bands
            GeometryReader { geo in
                ZStack {
                    // Zone bands (relative to baseline)
                    if let baseline = baseline, baseline.sampleCount >= 5 {
                        zoneBands(width: geo.size.width, height: geo.size.height, baseline: baseline)
                    }

                    // Trend line
                    if smoothedData.count >= 2 {
                        trendLine(width: geo.size.width, height: geo.size.height)
                    }

                    // Individual points (for interaction)
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

    // MARK: - Selected Point Detail

    private func selectedPointDetail(_ point: RestingHRReading) -> some View {
        HStack {
            Text("\(Int(point.bpm)) bpm")
                .font(.metricSmall)
                .foregroundStyle(colorForRHR(point.bpm))

            if let baseline = baseline, baseline.sampleCount >= 5 {
                let deviation = point.bpm - baseline.mean
                let sign = deviation >= 0 ? "+" : ""
                Text("(\(sign)\(Int(deviation)))")
                    .font(.labelMedium)
                    .foregroundStyle(colorForRHR(point.bpm))
            }

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

    private func zoneBands(width: CGFloat, height: CGFloat, baseline: (mean: Double, standardDeviation: Double, sampleCount: Int)) -> some View {
        let (minVal, maxVal) = valueRange
        let range = maxVal - minVal

        return ZStack {
            // Draw zone bands
            ForEach(zones.indices, id: \.self) { index in
                let zone = zones[index]
                let zoneMin = baseline.mean + zone.minOffset
                let zoneMax = baseline.mean + zone.maxOffset

                // Clamp to visible range
                let clampedMin = max(minVal, zoneMin)
                let clampedMax = min(maxVal, zoneMax)

                if clampedMax > clampedMin {
                    let topY = height * (1 - CGFloat((clampedMax - minVal) / range))
                    let bottomY = height * (1 - CGFloat((clampedMin - minVal) / range))
                    let bandHeight = bottomY - topY

                    Rectangle()
                        .fill(zone.color.opacity(0.12))
                        .frame(width: width, height: bandHeight)
                        .position(x: width / 2, y: topY + bandHeight / 2)
                }
            }

            // Baseline mean line
            let meanY = height * (1 - CGFloat((baseline.mean - minVal) / range))
            Rectangle()
                .fill(Theme.textMuted.opacity(0.4))
                .frame(width: width, height: 1)
                .position(x: width / 2, y: meanY)
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
            Theme.error,
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }

    private func pointOverlay(width: CGFloat, height: CGFloat) -> some View {
        let points = normalizedRawPoints(width: width, height: height)

        return ZStack {
            // Raw data points (colored by zone)
            ForEach(Array(zip(data.indices, points)), id: \.0) { index, point in
                Circle()
                    .fill(colorForRHR(data[index].bpm).opacity(0.5))
                    .frame(width: 5, height: 5)
                    .position(point)
            }

            // Selected point highlight
            if let selected = selectedPoint,
               let index = data.firstIndex(where: { $0.id == selected.id }),
               index < points.count {
                let pos = points[index]

                // Vertical line
                Rectangle()
                    .fill(colorForRHR(selected.bpm).opacity(0.5))
                    .frame(width: 1, height: height)
                    .position(x: pos.x, y: height / 2)

                // Point
                Circle()
                    .fill(Theme.surface)
                    .overlay(Circle().stroke(colorForRHR(selected.bpm), lineWidth: 3))
                    .frame(width: 14, height: 14)
                    .shadow(color: colorForRHR(selected.bpm).opacity(0.5), radius: 6)
                    .position(pos)
            }
        }
    }

    private var legendRow: some View {
        HStack(spacing: 12) {
            // Zone legend (condensed)
            ForEach([0, 1, 2], id: \.self) { index in
                let zone = zones[index]
                HStack(spacing: 3) {
                    Circle()
                        .fill(zone.color)
                        .frame(width: 5, height: 5)
                    Text(zone.label)
                        .font(.system(size: 8))
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
        guard !data.isEmpty else { return (40, 80) }

        var minVal = data.map { $0.bpm }.min() ?? 40
        var maxVal = data.map { $0.bpm }.max() ?? 80

        // Include baseline zones in range calculation
        if let baseline = baseline, baseline.sampleCount >= 5 {
            minVal = min(minVal, baseline.mean - 10)
            maxVal = max(maxVal, baseline.mean + 12)
        }

        // Add padding
        let padding = (maxVal - minVal) * 0.1
        return (minVal - padding, maxVal + padding)
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
        guard data.count >= 2 else { return [] }

        let (minVal, maxVal) = valueRange
        let range = maxVal - minVal

        guard let firstDate = data.first?.date,
              let lastDate = data.last?.date else { return [] }

        let timeRange = lastDate.timeIntervalSince(firstDate)

        return data.map { reading in
            let x = timeRange > 0
                ? CGFloat(reading.date.timeIntervalSince(firstDate) / timeRange) * width
                : width / 2
            let y = height * (1 - CGFloat((reading.bpm - minVal) / range))
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

    // MARK: - Color Logic (Inverted - lower is better)

    private func colorForRHR(_ bpm: Double) -> Color {
        guard let baseline = baseline, baseline.sampleCount >= 5 else { return Theme.error }

        let deviation = bpm - baseline.mean

        switch deviation {
        case ...(-5): return Theme.success      // Well below = excellent
        case -5..<3: return Theme.textSecondary // Normal range
        case 3..<8: return Theme.warning        // Slightly elevated
        default: return Theme.error             // Significantly elevated
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
    let sampleData: [RestingHRReading] = (0..<30).map { day in
        RestingHRReading(
            date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!,
            bpm: Double.random(in: 52...68)
        )
    }.reversed()

    let sampleBaseline = (mean: 58.0, standardDeviation: 4.0, sampleCount: 14)

    return VStack {
        RHRTrendChart(data: sampleData, baseline: sampleBaseline)
    }
    .padding()
    .background(Theme.background)
}
