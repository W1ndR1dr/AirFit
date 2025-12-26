import SwiftUI
import WidgetKit

// MARK: - Insight Ticker Widget

struct InsightTickerWidget: Widget {
    let kind: String = "InsightTicker"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InsightTimelineProvider()) { entry in
            InsightTickerView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("AI Insights")
        .description("Your latest AI-generated health insight")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

// MARK: - Timeline Provider

struct InsightTimelineProvider: TimelineProvider {
    typealias Entry = InsightEntry

    func placeholder(in context: Context) -> InsightEntry {
        InsightEntry(date: Date(), insight: .placeholder, insightIndex: 0, totalInsights: 1)
    }

    func getSnapshot(in context: Context, completion: @escaping (InsightEntry) -> Void) {
        let insights = WidgetDataStore.insights
        let insight = insights.first ?? .placeholder
        let entry = InsightEntry(date: Date(), insight: insight, insightIndex: 0, totalInsights: max(1, insights.count))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InsightEntry>) -> Void) {
        let insights = WidgetDataStore.insights
        var entries: [InsightEntry] = []

        // Create entries that rotate through insights
        let now = Date()
        for (index, insight) in insights.prefix(5).enumerated() {
            // Show each insight for 30 minutes
            let entryDate = Calendar.current.date(byAdding: .minute, value: index * 30, to: now)!
            entries.append(InsightEntry(
                date: entryDate,
                insight: insight,
                insightIndex: index,
                totalInsights: min(5, insights.count)
            ))
        }

        // If no insights, show placeholder
        if entries.isEmpty {
            entries.append(InsightEntry(
                date: now,
                insight: .placeholder,
                insightIndex: 0,
                totalInsights: 1
            ))
        }

        // Refresh after cycling through all insights (or 2.5 hours max)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct InsightEntry: TimelineEntry {
    let date: Date
    let insight: WidgetInsight
    let insightIndex: Int
    let totalInsights: Int
}

// MARK: - Views

struct InsightTickerView: View {
    let entry: InsightEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .accessoryRectangular:
            accessoryView
        default:
            smallView
        }
    }

    private var categoryColor: Color {
        switch entry.insight.category {
        case "correlation": return .purple
        case "trend": return .blue
        case "anomaly": return .orange
        case "milestone": return .yellow
        case "nudge": return .green
        default: return .gray
        }
    }

    // MARK: - Small (Home Screen)

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category badge
            HStack(spacing: 4) {
                Image(systemName: entry.insight.categoryIcon)
                    .font(.system(size: 10, weight: .semibold))
                Text(entry.insight.category.capitalized)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(categoryColor)

            // Title
            Text(entry.insight.title)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            Spacer()

            // Sparkline if available
            if let values = entry.insight.sparklineValues, !values.isEmpty {
                SparklineView(values: values, color: categoryColor)
                    .frame(height: 24)
            }

            // Pagination dots
            if entry.totalInsights > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<entry.totalInsights, id: \.self) { index in
                        Circle()
                            .fill(index == entry.insightIndex ? categoryColor : Color.gray.opacity(0.3))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "airfit://insights/\(entry.insight.id)"))
    }

    // MARK: - Medium (Home Screen)

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left side - insight content
            VStack(alignment: .leading, spacing: 8) {
                // Category badge
                HStack(spacing: 4) {
                    Image(systemName: entry.insight.categoryIcon)
                        .font(.system(size: 11, weight: .semibold))
                    Text(entry.insight.category.capitalized)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(categoryColor)

                // Title
                Text(entry.insight.title)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(2)

                // Body
                Text(entry.insight.body)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer()

                // Pagination
                if entry.totalInsights > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<entry.totalInsights, id: \.self) { index in
                            Circle()
                                .fill(index == entry.insightIndex ? categoryColor : Color.gray.opacity(0.3))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }

            // Right side - sparkline
            if let values = entry.insight.sparklineValues, !values.isEmpty {
                VStack {
                    SparklineView(values: values, color: categoryColor)
                        .frame(width: 80)
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "airfit://insights/\(entry.insight.id)"))
    }

    // MARK: - Accessory Rectangular (Lock Screen)

    private var accessoryView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.insight.categoryIcon)
                    .font(.system(size: 10))
                Text("Insight")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(.secondary)

            Text(entry.insight.title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)
        }
        .widgetURL(URL(string: "airfit://insights/\(entry.insight.id)"))
    }
}

// MARK: - Sparkline View

struct SparklineView: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 1
            let range = max(maxValue - minValue, 1)

            Path { path in
                for (index, value) in values.enumerated() {
                    let x = geometry.size.width * CGFloat(index) / CGFloat(max(1, values.count - 1))
                    let y = geometry.size.height * (1 - CGFloat((value - minValue) / range))

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    InsightTickerWidget()
} timeline: {
    InsightEntry(date: .now, insight: .placeholder, insightIndex: 0, totalInsights: 3)
}

#Preview(as: .systemMedium) {
    InsightTickerWidget()
} timeline: {
    InsightEntry(date: .now, insight: .placeholder, insightIndex: 0, totalInsights: 3)
}
