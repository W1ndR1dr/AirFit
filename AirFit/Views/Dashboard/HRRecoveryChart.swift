import SwiftUI

/// HR Recovery Trend Chart showing post-workout recovery with zone bands.
///
/// Design principles from plan:
/// - Multi-week view (not daily)
/// - Zone bands: Poor (<20), OK (20-30), Good (30-40), Excellent (>40)
/// - Improving trend = better cardio adaptation
/// - Declining trend = potential overtraining flag
/// - User uses HRR tanking mid-workout as "call the workout" signal
struct HRRecoveryChart: View {
    let data: [HRRecoveryReading]

    @State private var selectedPoint: HRRecoveryReading?
    @State private var showingDetail = false

    private let chartHeight: CGFloat = 150

    // Zone definitions
    private let zones: [(threshold: Double, label: String, color: Color)] = [
        (40, "Excellent", Theme.success),
        (30, "Good", Color(hex: "84CC16")),      // Lime green
        (20, "OK", Theme.warning),
        (0, "Poor", Theme.error)
    ]

    // LOESS smoothed data
    private var smoothedData: [ChartDataPoint] {
        let points = data.map { ChartDataPoint(date: $0.date, value: $0.recoveryBpm) }
        guard points.count > 3 else { return points }
        return ChartSmoothing.applyLOESS(to: points, bandwidth: 0.3)
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
        if change > 3 { return .improving }
        if change < -3 { return .declining }
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
                    Image(systemName: "heart.text.square.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.error)
                    Text("HR RECOVERY")
                        .font(.labelHero)
                        .tracking(2)
                        .foregroundStyle(Theme.textMuted)
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
    }

    // MARK: - Selected Point Detail

    private func selectedPointDetail(_ point: HRRecoveryReading) -> some View {
        HStack {
            Text("\(Int(point.recoveryBpm)) bpm")
                .font(.metricSmall)
                .foregroundStyle(colorForRecovery(point.recoveryBpm))

            Text("•")
                .foregroundStyle(Theme.textMuted)

            Text(zoneLabel(for: point.recoveryBpm))
                .font(.labelMedium)
                .foregroundStyle(colorForRecovery(point.recoveryBpm))

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
            Theme.error,
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }

    private func pointOverlay(width: CGFloat, height: CGFloat) -> some View {
        let points = normalizedRawPoints(width: width, height: height)

        return ZStack {
            // Raw data points
            ForEach(Array(zip(data.indices, points)), id: \.0) { index, point in
                Circle()
                    .fill(colorForRecovery(data[index].recoveryBpm).opacity(0.5))
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
                    .fill(Theme.error.opacity(0.5))
                    .frame(width: 1, height: height)
                    .position(x: pos.x, y: height / 2)

                // Point
                Circle()
                    .fill(Theme.surface)
                    .overlay(Circle().stroke(colorForRecovery(selected.recoveryBpm), lineWidth: 3))
                    .frame(width: 14, height: 14)
                    .shadow(color: Theme.error.opacity(0.5), radius: 6)
                    .position(pos)
            }
        }
    }

    private var legendRow: some View {
        HStack(spacing: 12) {
            ForEach(zones, id: \.threshold) { zone in
                HStack(spacing: 4) {
                    Circle()
                        .fill(zone.color)
                        .frame(width: 6, height: 6)
                    Text(zone.label)
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer()

            // Data count
            Text("\(data.count) workouts")
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)
        }
    }

    // MARK: - Helpers

    private var valueRange: (min: Double, max: Double) {
        // Fixed range for zones: 0-60 bpm recovery
        return (0, 60)
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
                let y = height * (1 - CGFloat((data[index].recoveryBpm - minVal) / range))
                return CGPoint(x: x, y: y)
            }
        }

        let timeRange = lastDate.timeIntervalSince(firstDate)

        return data.map { reading in
            let x = CGFloat(reading.date.timeIntervalSince(firstDate) / timeRange) * width
            let y = height * (1 - CGFloat((reading.recoveryBpm - minVal) / range))
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

    private func colorForRecovery(_ bpm: Double) -> Color {
        switch bpm {
        case 40...: return Theme.success
        case 30..<40: return Color(hex: "84CC16")
        case 20..<30: return Theme.warning
        default: return Theme.error
        }
    }

    private func zoneLabel(for bpm: Double) -> String {
        switch bpm {
        case 40...: return "Excellent"
        case 30..<40: return "Good"
        case 20..<30: return "OK"
        default: return "Poor"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleData: [HRRecoveryReading] = (0..<15).map { workout in
        HRRecoveryReading(
            date: Calendar.current.date(byAdding: .day, value: -workout * 2, to: Date())!,
            recoveryBpm: Double.random(in: 22...42)
        )
    }.reversed()

    return VStack {
        HRRecoveryChart(data: sampleData)
    }
    .padding()
    .background(Theme.background)
}
