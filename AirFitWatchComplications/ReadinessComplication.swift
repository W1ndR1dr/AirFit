import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct ReadinessEntry: TimelineEntry {
    let date: Date
    let data: ReadinessData?
    let isPlaceholder: Bool

    static let placeholder = ReadinessEntry(
        date: Date(),
        data: .placeholder,
        isPlaceholder: true
    )
}

// MARK: - Timeline Provider

struct ReadinessTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReadinessEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadinessEntry) -> Void) {
        let entry = ReadinessEntry(
            date: Date(),
            data: SharedDataStore.readinessData ?? .placeholder,
            isPlaceholder: context.isPreview
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadinessEntry>) -> Void) {
        let currentDate = Date()
        let data = SharedDataStore.readinessData

        let entry = ReadinessEntry(
            date: currentDate,
            data: data,
            isPlaceholder: false
        )

        // Readiness typically updates once per day (morning)
        // Refresh every hour to catch updates
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Complication Views

struct ReadinessComplicationEntryView: View {
    var entry: ReadinessEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryCorner:
            cornerView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    // MARK: - Circular

    private var circularView: some View {
        ZStack {
            if let data = entry.data {
                // Score ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: data.score)
                    .stroke(
                        categoryColor(data.category),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Category icon
                Image(systemName: data.categoryIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(categoryColor(data.category))
            } else {
                // No baseline / no data
                VStack(spacing: 2) {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                    Text("--")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .widgetAccentable()
    }

    // MARK: - Corner

    private var cornerView: some View {
        ZStack {
            if let data = entry.data {
                Image(systemName: data.categoryIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(categoryColor(data.category))
                    .widgetCurvesContent()
            } else {
                Image(systemName: "questionmark.circle")
            }
        }
        .widgetLabel {
            if let data = entry.data {
                Text(data.category)
            } else {
                Text("No data")
            }
        }
    }

    // MARK: - Rectangular

    private var rectangularView: some View {
        HStack(spacing: 8) {
            if let data = entry.data {
                // Readiness icon with ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: data.score)
                        .stroke(categoryColor(data.category), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Image(systemName: data.categoryIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(categoryColor(data.category))
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Readiness:")
                            .font(.system(size: 12, weight: .medium))
                        Text(data.category)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(categoryColor(data.category))
                    }

                    HStack(spacing: 8) {
                        if let sleep = data.sleepHours {
                            Label("\(String(format: "%.1f", sleep))h", systemImage: "bed.double.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }

                        Text("\(data.positiveCount)/\(data.totalCount) signals")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    if !data.isBaselineReady {
                        Text("Building baseline...")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                    }
                }
            } else {
                Image(systemName: "heart.text.square")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Readiness")
                        .font(.caption)
                    Text("No data yet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .widgetAccentable()
    }

    // MARK: - Inline

    @ViewBuilder
    private var inlineView: some View {
        if let data = entry.data {
            Label(data.category, systemImage: data.categoryIcon)
        } else {
            Text("Readiness: --")
        }
    }

    // MARK: - Helpers

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Great": return .green
        case "Good": return .blue
        case "Moderate": return .orange
        case "Rest": return .red
        default: return .gray
        }
    }
}

// MARK: - Widget Definition

struct ReadinessComplication: Widget {
    let kind: String = "ReadinessComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadinessTimelineProvider()) { entry in
            ReadinessComplicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Readiness")
        .description("See your training readiness at a glance.")
        #if os(watchOS)
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
        #else
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        #endif
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    ReadinessComplication()
} timeline: {
    ReadinessEntry(date: .now, data: .placeholder, isPlaceholder: false)
    ReadinessEntry(date: .now, data: ReadinessData(
        category: "Great",
        positiveCount: 3,
        totalCount: 3,
        hrvDeviation: nil,
        sleepHours: 8.2,
        rhrDeviation: nil,
        isBaselineReady: true,
        lastUpdated: Date()
    ), isPlaceholder: false)
}
