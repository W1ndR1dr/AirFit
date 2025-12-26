import SwiftUI
import WidgetKit

// MARK: - Protein Counter Widget

struct ProteinCounterWidget: Widget {
    let kind: String = "ProteinCounter"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProteinTimelineProvider()) { entry in
            ProteinCounterView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Protein")
        .description("Track your daily protein progress")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Timeline Provider

struct ProteinTimelineProvider: TimelineProvider {
    typealias Entry = ProteinEntry

    func placeholder(in context: Context) -> ProteinEntry {
        ProteinEntry(date: Date(), data: .placeholder, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProteinEntry) -> Void) {
        let data = WidgetDataStore.nutritionData ?? .placeholder
        let entry = ProteinEntry(date: Date(), data: data, isPlaceholder: context.isPreview)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProteinEntry>) -> Void) {
        let data = WidgetDataStore.nutritionData ?? .placeholder
        let entry = ProteinEntry(date: Date(), data: data, isPlaceholder: false)

        // Refresh every 15 minutes for nutrition updates
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct ProteinEntry: TimelineEntry {
    let date: Date
    let data: WidgetNutritionData
    let isPlaceholder: Bool
}

// MARK: - Views

struct ProteinCounterView: View {
    let entry: ProteinEntry
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

    // MARK: - Circular (Lock Screen)

    private var circularView: some View {
        Gauge(value: entry.data.proteinProgress) {
            Text("P")
        } currentValueLabel: {
            Text("\(entry.data.protein)")
                .font(.system(.title3, design: .rounded, weight: .bold))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(.blue)
        .widgetURL(URL(string: "airfit://nutrition"))
    }

    // MARK: - Rectangular (Lock Screen)

    private var rectangularView: some View {
        HStack(spacing: 12) {
            // Protein ring
            Gauge(value: entry.data.proteinProgress) {
                Text("P")
            } currentValueLabel: {
                Text("\(entry.data.protein)g")
                    .font(.system(.caption, design: .rounded, weight: .bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.blue)
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Protein")
                        .font(.system(size: 13, weight: .semibold))
                    if entry.data.isTrainingDay {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.green)
                    }
                }

                Text("\(entry.data.proteinRemaining)g remaining")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                ProgressView(value: entry.data.proteinProgress)
                    .tint(.blue)
            }
        }
        .widgetURL(URL(string: "airfit://nutrition"))
    }

    // MARK: - Inline

    private var inlineView: some View {
        Label("\(entry.data.protein)/\(entry.data.targetProtein)g protein", systemImage: "p.circle.fill")
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    ProteinCounterWidget()
} timeline: {
    ProteinEntry(date: .now, data: .placeholder, isPlaceholder: false)
    ProteinEntry(date: .now, data: WidgetNutritionData(
        calories: 2100,
        protein: 165,
        carbs: 280,
        fat: 60,
        targetCalories: 2600,
        targetProtein: 175,
        targetCarbs: 330,
        targetFat: 67,
        isTrainingDay: true,
        lastUpdated: Date()
    ), isPlaceholder: false)
}

#Preview(as: .accessoryRectangular) {
    ProteinCounterWidget()
} timeline: {
    ProteinEntry(date: .now, data: .placeholder, isPlaceholder: false)
}
