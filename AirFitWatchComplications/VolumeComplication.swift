import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct VolumeEntry: TimelineEntry {
    let date: Date
    let progress: VolumeProgress?
    let isPlaceholder: Bool

    static let placeholder = VolumeEntry(
        date: Date(),
        progress: .placeholder,
        isPlaceholder: true
    )
}

// MARK: - Timeline Provider

struct VolumeTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> VolumeEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (VolumeEntry) -> Void) {
        let entry = VolumeEntry(
            date: Date(),
            progress: SharedDataStore.volumeProgress ?? .placeholder,
            isPlaceholder: context.isPreview
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VolumeEntry>) -> Void) {
        let currentDate = Date()
        let progress = SharedDataStore.volumeProgress

        let entry = VolumeEntry(
            date: currentDate,
            progress: progress,
            isPlaceholder: false
        )

        // Volume updates after workouts, refresh hourly
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Complication Views

struct VolumeComplicationEntryView: View {
    var entry: VolumeEntry
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
            if let progress = entry.progress {
                let completedCount = progress.muscleGroups.filter { $0.isComplete }.count
                let totalCount = progress.muscleGroups.count
                let overallProgress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0

                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: overallProgress)
                    .stroke(
                        Color.purple,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(completedCount)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))

                    Text("/\(totalCount)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "dumbbell")
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
                let completedCount = progress.muscleGroups.filter { $0.isComplete }.count
                Text("\(completedCount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .widgetCurvesContent()
            } else {
                Image(systemName: "dumbbell")
            }
        }
        .widgetLabel {
            if let progress = entry.progress {
                let totalCount = progress.muscleGroups.count
                Text("\(progress.muscleGroups.filter { $0.isComplete }.count)/\(totalCount) complete")
            } else {
                Text("No data")
            }
        }
    }

    // MARK: - Rectangular

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let progress = entry.progress {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .font(.caption)
                    Text("Weekly Volume")
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                }

                // Show top 3 muscle groups with progress bars
                ForEach(Array(progress.muscleGroups.prefix(3))) { group in
                    HStack(spacing: 4) {
                        Text(shortName(group.name))
                            .font(.system(size: 9))
                            .frame(width: 32, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(statusColor(group.status))
                                    .frame(width: geo.size.width * group.progress, height: 4)
                            }
                        }
                        .frame(height: 4)

                        Text("\(group.currentSets)/\(group.targetSets)")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "dumbbell")
                        .font(.title3)
                    VStack(alignment: .leading) {
                        Text("Volume")
                            .font(.caption)
                        Text("No workout data")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .widgetAccentable()
    }

    // MARK: - Inline

    @ViewBuilder
    private var inlineView: some View {
        if let progress = entry.progress {
            let completedCount = progress.muscleGroups.filter { $0.isComplete }.count
            let totalCount = progress.muscleGroups.count
            Text("💪 \(completedCount)/\(totalCount) groups done")
        } else {
            Text("💪 --")
        }
    }

    // MARK: - Helpers

    private func shortName(_ name: String) -> String {
        // Abbreviate muscle group names for space
        switch name.lowercased() {
        case "chest": return "Chst"
        case "back": return "Back"
        case "shoulders": return "Shld"
        case "biceps": return "Bic"
        case "triceps": return "Tri"
        case "legs", "quads": return "Legs"
        case "hamstrings": return "Ham"
        case "glutes": return "Glut"
        case "calves": return "Calv"
        case "abs", "core": return "Abs"
        default: return String(name.prefix(4))
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "in_zone": return .green
        case "above": return .blue
        case "below": return .orange
        case "at_floor": return .red
        default: return .gray
        }
    }
}

// MARK: - Widget Definition

struct VolumeComplication: Widget {
    let kind: String = "VolumeComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VolumeTimelineProvider()) { entry in
            VolumeComplicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Volume")
        .description("Track weekly training volume by muscle group.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    VolumeComplication()
} timeline: {
    VolumeEntry(date: .now, progress: .placeholder, isPlaceholder: false)
}
