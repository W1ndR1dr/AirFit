import SwiftUI

/// HRV Trend Chart showing values with baseline band (±1 SD shaded).
///
/// Design principles from plan:
/// - 30-day view with LOESS smoothing
/// - Baseline band shows ±1 standard deviation
/// - Highlights deviations above/below baseline
/// - Single-day values are noise, trend is signal
struct HRVTrendChart: View {
    let data: [HRVReading]
    let baseline: HRVBaseline?

    @State private var selectedPoint: HRVReading?
    @State private var showingDetail = false

    private let chartHeight: CGFloat = 150

    // LOESS smoothed data
    private var smoothedData: [ChartDataPoint] {
        let points = data.map { ChartDataPoint(date: $0.date, value: $0.hrvMs) }
        guard points.count > 3 else { return points }
        return ChartSmoothing.applyLOESS(to: points, bandwidth: 0.25)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                    Text("HRV TREND")
                        .font(.labelHero)
                        .tracking(2)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                Text("\(data.count) readings")
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            // Selected point detail
            if let point = selectedPoint, showingDetail {
                selectedPointDetail(point)
            }

            // Chart with baseline band
            GeometryReader { geo in
                ZStack {
                    // Baseline band (±1 SD)
                    if let baseline = baseline, baseline.isReliable {
                        baselineBand(width: geo.size.width, height: geo.size.height, baseline: baseline)
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
    }

    // MARK: - Selected Point Detail

    private func selectedPointDetail(_ point: HRVReading) -> some View {
        HStack {
            Text("\(Int(point.hrvMs)) ms")
                .font(.metricSmall)
                .foregroundStyle(colorForHRV(point.hrvMs))

            if let baseline = baseline, baseline.isReliable {
                let deviation = baseline.percentDeviation(for: point.hrvMs)
                let sign = deviation >= 0 ? "+" : ""
                Text("(\(sign)\(Int(deviation))%)")
                    .font(.labelMedium)
                    .foregroundStyle(colorForHRV(point.hrvMs))
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

    private func baselineBand(width: CGFloat, height: CGFloat, baseline: HRVBaseline) -> some View {
        let (minVal, maxVal) = valueRange
        let range = maxVal - minVal

        // Baseline ± 1 SD band
        let upperY = height * (1 - CGFloat((baseline.mean + baseline.standardDeviation - minVal) / range))
        let lowerY = height * (1 - CGFloat((baseline.mean - baseline.standardDeviation - minVal) / range))
        let meanY = height * (1 - CGFloat((baseline.mean - minVal) / range))

        return ZStack {
            // ±1 SD shaded band
            Rectangle()
                .fill(Theme.accent.opacity(0.1))
                .frame(height: max(0, lowerY - upperY))
                .position(x: width / 2, y: (upperY + lowerY) / 2)

            // Mean line
            Rectangle()
                .fill(Theme.accent.opacity(0.5))
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
            LinearGradient(
                colors: [Theme.accent, Theme.secondary],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }

    private func pointOverlay(width: CGFloat, height: CGFloat) -> some View {
        let points = normalizedRawPoints(width: width, height: height)

        return ZStack {
            // Raw data points (subtle)
            ForEach(Array(zip(data.indices, points)), id: \.0) { index, point in
                Circle()
                    .fill(colorForHRV(data[index].hrvMs).opacity(0.3))
                    .frame(width: 4, height: 4)
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
                    .overlay(Circle().stroke(colorForHRV(selected.hrvMs), lineWidth: 3))
                    .frame(width: 14, height: 14)
                    .shadow(color: Theme.accent.opacity(0.5), radius: 6)
                    .position(pos)
            }
        }
    }

    private var legendRow: some View {
        HStack(spacing: 16) {
            // Baseline legend
            if let baseline = baseline, baseline.isReliable {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Theme.accent.opacity(0.3))
                        .frame(width: 16, height: 8)
                        .overlay(
                            Rectangle()
                                .fill(Theme.accent.opacity(0.5))
                                .frame(height: 1)
                        )
                    Text("Baseline ±1 SD")
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
        guard !data.isEmpty else { return (0, 100) }

        var minVal = data.map { $0.hrvMs }.min() ?? 0
        var maxVal = data.map { $0.hrvMs }.max() ?? 100

        // Include baseline in range calculation
        if let baseline = baseline, baseline.isReliable {
            minVal = min(minVal, baseline.mean - baseline.standardDeviation)
            maxVal = max(maxVal, baseline.mean + baseline.standardDeviation)
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
            let y = height * (1 - CGFloat((reading.hrvMs - minVal) / range))
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

    private func colorForHRV(_ hrv: Double) -> Color {
        guard let baseline = baseline, baseline.isReliable else { return Theme.accent }

        let deviation = baseline.percentDeviation(for: hrv)

        switch deviation {
        case 10...: return Theme.success      // Well above baseline
        case -5..<10: return Theme.accent     // Normal range
        case -15..<(-5): return Theme.warning // Below baseline
        default: return Theme.error           // Significantly below
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleData: [HRVReading] = (0..<30).map { day in
        HRVReading(
            date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!,
            hrvMs: Double.random(in: 35...65)
        )
    }.reversed()

    let sampleBaseline = HRVBaseline(
        mean: 50,
        standardDeviation: 8,
        coefficientOfVariation: 0.16,
        sampleCount: 7,
        startDate: Date().addingTimeInterval(-7*24*3600),
        endDate: Date()
    )

    return VStack {
        HRVTrendChart(data: sampleData, baseline: sampleBaseline)
    }
    .padding()
    .background(Theme.background)
}
