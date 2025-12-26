import SwiftUI
import WidgetKit

// MARK: - Morning Readiness Widget

struct ReadinessWidget: Widget {
    let kind: String = "MorningReadiness"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadinessTimelineProvider()) { entry in
            ReadinessWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Readiness")
        .description("See your training readiness at a glance")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Timeline Provider

struct ReadinessTimelineProvider: TimelineProvider {
    typealias Entry = ReadinessWidgetEntry

    func placeholder(in context: Context) -> ReadinessWidgetEntry {
        ReadinessWidgetEntry(date: Date(), data: .placeholder, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadinessWidgetEntry) -> Void) {
        let data = WidgetDataStore.readinessData ?? .placeholder
        let entry = ReadinessWidgetEntry(date: Date(), data: data, isPlaceholder: context.isPreview)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadinessWidgetEntry>) -> Void) {
        let data = WidgetDataStore.readinessData ?? .placeholder
        let entry = ReadinessWidgetEntry(date: Date(), data: data, isPlaceholder: false)

        // Readiness updates once per day, refresh hourly to catch updates
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct ReadinessWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetReadinessData
    let isPlaceholder: Bool
}

// MARK: - Views

struct ReadinessWidgetView: View {
    let entry: ReadinessWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    private var categoryColor: Color {
        switch entry.data.category {
        case "Great": return .green
        case "Good": return .blue
        case "Moderate": return .orange
        case "Rest": return .red
        default: return .gray
        }
    }

    // MARK: - Circular

    private var circularView: some View {
        ZStack {
            // Score ring
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)

            Circle()
                .trim(from: 0, to: entry.data.score)
                .stroke(categoryColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Category icon
            Image(systemName: entry.data.categoryIcon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(categoryColor)
        }
        .widgetURL(URL(string: "airfit://dashboard"))
    }

    // MARK: - Rectangular

    private var rectangularView: some View {
        HStack(spacing: 10) {
            // Readiness ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: entry.data.score)
                    .stroke(categoryColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Image(systemName: entry.data.categoryIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(categoryColor)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Readiness:")
                        .font(.system(size: 12, weight: .medium))
                    Text(entry.data.category)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(categoryColor)
                }

                Text(entry.data.summaryText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !entry.data.isBaselineReady {
                    Text("Building baseline...")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }
            }
        }
        .widgetURL(URL(string: "airfit://dashboard"))
    }

    // MARK: - Inline

    private var inlineView: some View {
        Label(entry.data.category, systemImage: entry.data.categoryIcon)
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    ReadinessWidget()
} timeline: {
    ReadinessWidgetEntry(date: .now, data: .placeholder, isPlaceholder: false)
    ReadinessWidgetEntry(date: .now, data: WidgetReadinessData(
        category: "Great",
        positiveCount: 3,
        totalCount: 3,
        sleepHours: 8.2,
        hrvDeviation: 8,
        isBaselineReady: true,
        baselineProgress: nil,
        lastUpdated: Date()
    ), isPlaceholder: false)
}

#Preview(as: .accessoryRectangular) {
    ReadinessWidget()
} timeline: {
    ReadinessWidgetEntry(date: .now, data: .placeholder, isPlaceholder: false)
}
