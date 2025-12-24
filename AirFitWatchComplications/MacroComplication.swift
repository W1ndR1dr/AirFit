import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct MacroEntry: TimelineEntry {
    let date: Date
    let progress: MacroProgress?
    let isPlaceholder: Bool

    static let placeholder = MacroEntry(
        date: Date(),
        progress: .placeholder,
        isPlaceholder: true
    )
}

// MARK: - Timeline Provider

struct MacroTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MacroEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (MacroEntry) -> Void) {
        let entry = MacroEntry(
            date: Date(),
            progress: SharedDataStore.macroProgress ?? .placeholder,
            isPlaceholder: context.isPreview
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MacroEntry>) -> Void) {
        let currentDate = Date()
        let progress = SharedDataStore.macroProgress

        let entry = MacroEntry(
            date: currentDate,
            progress: progress,
            isPlaceholder: false
        )

        // Refresh every 30 minutes, or when app updates data
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Complication Views

struct MacroComplicationEntryView: View {
    var entry: MacroEntry
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

    // MARK: - Circular (most common)

    private var circularView: some View {
        ZStack {
            if let progress = entry.progress {
                // Protein ring (outer)
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: min(progress.proteinProgress, 1.0))
                    .stroke(
                        Color.orange,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: 0) {
                    Text("\(progress.proteinRemaining)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)

                    Text("g")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            } else {
                // No data state
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .widgetAccentable()
    }

    // MARK: - Corner

    private var cornerView: some View {
        ZStack {
            if let progress = entry.progress {
                Text("\(progress.proteinRemaining)g")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .widgetCurvesContent()
            } else {
                Image(systemName: "fork.knife")
            }
        }
        .widgetLabel {
            if let progress = entry.progress {
                Gauge(value: progress.proteinProgress) {
                    Text("Protein")
                }
                .tint(.orange)
            }
        }
    }

    // MARK: - Rectangular

    private var rectangularView: some View {
        HStack(spacing: 8) {
            if let progress = entry.progress {
                // Protein ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: min(progress.proteinProgress, 1.0))
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(progress.protein)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Protein: \(progress.protein)/\(progress.targetProtein)g")
                        .font(.system(size: 12, weight: .medium))

                    Text("Calories: \(progress.calories)/\(progress.targetCalories)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    // Calorie progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(progress.caloriesRemaining > 0 ? Color.green : Color.red)
                                .frame(width: geo.size.width * min(progress.calorieProgress, 1.0), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            } else {
                Image(systemName: "fork.knife")
                    .font(.title2)
                Text("No data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .widgetAccentable()
    }

    // MARK: - Inline

    private var inlineView: some View {
        if let progress = entry.progress {
            Text("🥩 \(progress.proteinRemaining)g left")
        } else {
            Text("🥩 --g")
        }
    }
}

// MARK: - Widget Definition

struct MacroComplication: Widget {
    let kind: String = "MacroComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacroTimelineProvider()) { entry in
            MacroComplicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Macros")
        .description("Track protein and calorie progress at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    MacroComplication()
} timeline: {
    MacroEntry(date: .now, progress: .placeholder, isPlaceholder: false)
    MacroEntry(date: .now, progress: nil, isPlaceholder: false)
}
