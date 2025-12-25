import SwiftUI

/// HRV Deviation Chart - Shows % deviation from baseline as colored bars.
///
/// Design philosophy:
/// - Raw HRV values are noise; deviation from YOUR baseline is signal
/// - Green bars = above baseline (well recovered)
/// - Red bars = below baseline (stressed/fatigued)
/// - 7-day rolling average line shows trend direction
struct HRVDeviationChart: View {
    let data: [HRVReading]
    let baseline: HRVBaseline?

    @State private var selectedIndex: Int?
    @State private var showingDetail = false

    private let chartHeight: CGFloat = 150
    private let barSpacing: CGFloat = 2

    // Calculate deviation for each reading
    private var deviationData: [(date: Date, deviation: Double, hrvMs: Double)] {
        guard let baseline = baseline, baseline.isReliable else {
            return data.map { (date: $0.date, deviation: 0, hrvMs: $0.hrvMs) }
        }
        return data.map { reading in
            let deviation = baseline.percentDeviation(for: reading.hrvMs)
            return (date: reading.date, deviation: deviation, hrvMs: reading.hrvMs)
        }
    }

    // 7-day rolling average of deviations
    private var rollingAverageData: [ChartDataPoint] {
        guard deviationData.count >= 3 else { return [] }

        var result: [ChartDataPoint] = []
        let windowSize = min(7, deviationData.count)

        for i in (windowSize - 1)..<deviationData.count {
            let window = deviationData[(i - windowSize + 1)...i]
            let avgDeviation = window.reduce(0) { $0 + $1.deviation } / Double(windowSize)
            result.append(ChartDataPoint(date: deviationData[i].date, value: avgDeviation))
        }

        return result
    }

    // Value range for Y axis (symmetric around 0)
    private var valueRange: Double {
        let maxDev = deviationData.map { abs($0.deviation) }.max() ?? 20
        return max(20, ceil(maxDev / 10) * 10)  // Round up to nearest 10, minimum 20%
    }

    // Current status
    private var currentStatus: (label: String, color: Color, deviation: Double)? {
        guard let latest = deviationData.last else { return nil }
        let dev = latest.deviation

        switch dev {
        case 10...: return ("Recovered", Theme.success, dev)
        case 0..<10: return ("Normal", Theme.textSecondary, dev)
        case -10..<0: return ("Slightly Low", Theme.warning, dev)
        default: return ("Low", Theme.error, dev)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with current status
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

                // Current status badge
                if let status = currentStatus {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 6, height: 6)
                        Text(status.label)
                            .font(.labelMicro)
                            .foregroundStyle(status.color)
                        Text("(\(status.deviation >= 0 ? "+" : "")\(Int(status.deviation))%)")
                            .font(.labelMicro)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }

            // Selected point detail
            if let index = selectedIndex, showingDetail, index < deviationData.count {
                selectedPointDetail(deviationData[index])
            }

            // Chart
            GeometryReader { geo in
                ZStack {
                    // Zero line (baseline)
                    let zeroY = geo.size.height / 2
                    Rectangle()
                        .fill(Theme.textMuted.opacity(0.3))
                        .frame(width: geo.size.width, height: 1)
                        .position(x: geo.size.width / 2, y: zeroY)

                    // Deviation bars
                    deviationBars(width: geo.size.width, height: geo.size.height)

                    // 7-day rolling average line
                    if rollingAverageData.count >= 2 {
                        rollingAverageLine(width: geo.size.width, height: geo.size.height)
                    }

                    // Touch handler
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleTouch(at: value.location, width: geo.size.width)
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation(.airfit) {
                                            showingDetail = false
                                            selectedIndex = nil
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
        .sensoryFeedback(.selection, trigger: selectedIndex)
    }

    // MARK: - Selected Point Detail

    private func selectedPointDetail(_ point: (date: Date, deviation: Double, hrvMs: Double)) -> some View {
        HStack {
            Text("\(Int(point.hrvMs)) ms")
                .font(.metricSmall)
                .foregroundStyle(colorForDeviation(point.deviation))

            let sign = point.deviation >= 0 ? "+" : ""
            Text("(\(sign)\(Int(point.deviation))%)")
                .font(.labelMedium)
                .foregroundStyle(colorForDeviation(point.deviation))

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

    private func deviationBars(width: CGFloat, height: CGFloat) -> some View {
        let barWidth = max(2, (width - CGFloat(deviationData.count - 1) * barSpacing) / CGFloat(deviationData.count))
        let scale = (height / 2) / valueRange

        return HStack(alignment: .center, spacing: barSpacing) {
            ForEach(Array(deviationData.enumerated()), id: \.offset) { index, point in
                let barHeight = abs(CGFloat(point.deviation) * scale)
                let isPositive = point.deviation >= 0
                let isSelected = selectedIndex == index

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(colorForDeviation(point.deviation).opacity(isSelected ? 1.0 : 0.6))
                    .frame(width: barWidth, height: max(2, barHeight))
                    .offset(y: isPositive ? -barHeight / 2 : barHeight / 2)
            }
        }
        .frame(height: height)
    }

    private func rollingAverageLine(width: CGFloat, height: CGFloat) -> some View {
        let scale = (height / 2) / valueRange
        let zeroY = height / 2

        guard let firstDate = rollingAverageData.first?.date,
              let lastDate = rollingAverageData.last?.date else { return AnyView(EmptyView()) }

        let timeRange = lastDate.timeIntervalSince(firstDate)

        let points: [CGPoint] = rollingAverageData.map { point in
            let x = timeRange > 0
                ? CGFloat(point.date.timeIntervalSince(firstDate) / timeRange) * width
                : width / 2
            let y = zeroY - CGFloat(point.value) * scale
            return CGPoint(x: x, y: y)
        }

        return AnyView(
            Path { path in
                guard points.count >= 2 else { return }
                path.move(to: points[0])

                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
            }
            .stroke(
                Theme.accent,
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        )
    }

    private var legendRow: some View {
        HStack(spacing: 16) {
            // Legend items
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.success)
                    .frame(width: 12, height: 8)
                Text("Above")
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.error)
                    .frame(width: 12, height: 8)
                Text("Below")
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            HStack(spacing: 4) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 12, height: 2)
                Text("7d Avg")
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
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

    private func handleTouch(at location: CGPoint, width: CGFloat) {
        guard !deviationData.isEmpty else { return }

        let barWidth = (width - CGFloat(deviationData.count - 1) * barSpacing) / CGFloat(deviationData.count)
        let index = Int(location.x / (barWidth + barSpacing))
        let clampedIndex = max(0, min(deviationData.count - 1, index))

        if selectedIndex != clampedIndex {
            withAnimation(.spring(response: 0.2)) {
                selectedIndex = clampedIndex
                showingDetail = true
            }
        }
    }

    private func colorForDeviation(_ deviation: Double) -> Color {
        switch deviation {
        case 10...: return Theme.success
        case 0..<10: return Theme.success.opacity(0.7)
        case -10..<0: return Theme.warning
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
    let baseline = HRVBaseline(
        mean: 50,
        standardDeviation: 8,
        coefficientOfVariation: 0.16,
        sampleCount: 14,
        startDate: Date().addingTimeInterval(-60*24*3600),
        endDate: Date()
    )

    let sampleData: [HRVReading] = (0..<14).map { day in
        HRVReading(
            date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!,
            hrvMs: 50 + Double.random(in: -15...15)
        )
    }.reversed()

    return VStack {
        HRVDeviationChart(data: sampleData, baseline: baseline)
    }
    .padding()
    .background(Theme.background)
}
