import SwiftUI
import WidgetKit

// MARK: - Strength Tracker Widget

struct StrengthTrackerWidget: Widget {
    let kind: String = "StrengthTracker"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StrengthTimelineProvider()) { entry in
            StrengthTrackerView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Training Volume")
        .description("Track your weekly muscle group volume")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline Provider

struct StrengthTimelineProvider: TimelineProvider {
    typealias Entry = StrengthEntry

    func placeholder(in context: Context) -> StrengthEntry {
        StrengthEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (StrengthEntry) -> Void) {
        let data = WidgetDataStore.strengthData ?? .placeholder
        let entry = StrengthEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StrengthEntry>) -> Void) {
        let data = WidgetDataStore.strengthData ?? .placeholder
        let entry = StrengthEntry(date: Date(), data: data)

        // Refresh every hour (workouts don't update that frequently)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct StrengthEntry: TimelineEntry {
    let date: Date
    let data: WidgetStrengthData
}

// MARK: - Views

struct StrengthTrackerView: View {
    let entry: StrengthEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "below": return .orange
        case "in_zone": return .green
        case "above": return .blue
        default: return .gray
        }
    }

    // MARK: - Small View

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Volume")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let pr = entry.data.recentPR {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                        Text("PR")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.yellow)
                    }
                }
            }

            // Muscle groups (top 4)
            ForEach(entry.data.muscleGroups.prefix(4)) { group in
                HStack(spacing: 6) {
                    Text(group.name)
                        .font(.system(size: 10))
                        .frame(width: 50, alignment: .leading)
                        .lineLimit(1)

                    ProgressView(value: group.progress)
                        .tint(statusColor(for: group.status))

                    Text("\(group.currentSets)")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(statusColor(for: group.status))
                        .frame(width: 16, alignment: .trailing)
                }
            }

            Spacer()

            // Behind count
            if !entry.data.behindMuscleGroups.isEmpty {
                Text("\(entry.data.behindMuscleGroups.count) behind target")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .widgetURL(URL(string: "airfit://training"))
    }

    // MARK: - Medium View

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left: Muscle groups
            VStack(alignment: .leading, spacing: 6) {
                Text("Weekly Volume")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                ForEach(entry.data.muscleGroups.prefix(5)) { group in
                    HStack(spacing: 8) {
                        Text(group.name)
                            .font(.system(size: 11))
                            .frame(width: 65, alignment: .leading)
                            .lineLimit(1)

                        ProgressView(value: group.progress)
                            .tint(statusColor(for: group.status))

                        Text("\(group.currentSets)/\(group.targetSets)")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 35, alignment: .trailing)
                    }
                }
            }

            Divider()

            // Right: PR and workout info
            VStack(alignment: .leading, spacing: 12) {
                // Recent PR
                if let pr = entry.data.recentPR {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                            Text("New PR")
                                .font(.system(size: 10, weight: .semibold))
                        }

                        Text(pr.exerciseName)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)

                        Text("\(Int(pr.weight)) \(pr.unit)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.yellow)
                    }
                }

                Spacer()

                // Last workout
                if let workout = entry.data.lastWorkout {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Workout")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)

                        Text(workout.name)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)

                        Text("\(workout.duration) min")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 90)
        }
        .padding()
        .widgetURL(URL(string: "airfit://training"))
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    StrengthTrackerWidget()
} timeline: {
    StrengthEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemMedium) {
    StrengthTrackerWidget()
} timeline: {
    StrengthEntry(date: .now, data: .placeholder)
}
