import SwiftUI
import WidgetKit

// MARK: - Weekly Rhythm Widget

struct WeeklyRhythmWidget: Widget {
    let kind: String = "WeeklyRhythm"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyTimelineProvider()) { entry in
            WeeklyRhythmView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Weekly Rhythm")
        .description("See your training and nutrition patterns for the week")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider

struct WeeklyTimelineProvider: TimelineProvider {
    typealias Entry = WeeklyEntry

    func placeholder(in context: Context) -> WeeklyEntry {
        WeeklyEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyEntry) -> Void) {
        let data = WidgetDataStore.weeklyData ?? .placeholder
        let entry = WeeklyEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyEntry>) -> Void) {
        let data = WidgetDataStore.weeklyData ?? .placeholder
        let entry = WeeklyEntry(date: Date(), data: data)

        // Refresh hourly
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct WeeklyEntry: TimelineEntry {
    let date: Date
    let data: WidgetWeeklyData
}

// MARK: - Views

struct WeeklyRhythmView: View {
    let entry: WeeklyEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }

    private func complianceColor(for value: Double?) -> Color {
        guard let value = value else { return .gray.opacity(0.3) }
        if value >= 0.9 { return .green }
        if value >= 0.7 { return .yellow }
        return .red
    }

    private func sleepColor(for value: Double?) -> Color {
        guard let value = value else { return .gray.opacity(0.3) }
        if value >= 0.8 { return .blue }
        if value >= 0.6 { return .orange }
        return .red
    }

    // MARK: - Medium View

    private var mediumView: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("This Week")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                // Summary stats
                HStack(spacing: 12) {
                    let workoutCount = entry.data.days.filter { $0.hasWorkout }.count
                    Label("\(workoutCount) workouts", systemImage: "dumbbell.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Week grid
            HStack(spacing: 4) {
                ForEach(entry.data.days) { day in
                    DayColumn(day: day, showDetails: false)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom)
        }
        .widgetURL(URL(string: "airfit://nutrition"))
    }

    // MARK: - Large View

    private var largeView: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Weekly Rhythm")
                    .font(.system(size: 15, weight: .bold))

                Spacer()

                // Summary
                let workoutCount = entry.data.days.filter { $0.hasWorkout }.count
                let avgCompliance = entry.data.days.compactMap(\.nutritionCompliance).reduce(0, +) / max(1, Double(entry.data.days.filter { $0.nutritionCompliance != nil }.count))

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 10))
                        Text("\(workoutCount)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.green)

                    HStack(spacing: 4) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 10))
                        Text("\(Int(avgCompliance * 100))%")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(complianceColor(for: avgCompliance))
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Week grid with details
            HStack(spacing: 6) {
                ForEach(entry.data.days) { day in
                    DayColumn(day: day, showDetails: true)
                }
            }
            .padding(.horizontal, 8)

            Divider()
                .padding(.horizontal)

            // Legend
            HStack(spacing: 20) {
                LegendItem(color: .green, label: "Workout")
                LegendItem(color: .blue, label: "Good sleep")
                LegendItem(color: .yellow, label: "Nutrition OK")
                LegendItem(color: .red, label: "Missed target")
            }
            .font(.system(size: 9))
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .widgetURL(URL(string: "airfit://nutrition"))
    }
}

// MARK: - Day Column

struct DayColumn: View {
    let day: WidgetWeeklyData.DayData
    let showDetails: Bool

    private var backgroundColor: Color {
        if day.isToday {
            return Color.blue.opacity(0.1)
        }
        return Color.clear
    }

    var body: some View {
        VStack(spacing: 4) {
            // Day label
            Text(day.dayOfWeek)
                .font(.system(size: 10, weight: day.isToday ? .bold : .regular))
                .foregroundStyle(day.isToday ? .primary : .secondary)

            // Workout indicator
            if day.hasWorkout {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 14, height: 14)
            }

            if showDetails {
                // Nutrition compliance
                RoundedRectangle(cornerRadius: 2)
                    .fill(complianceColor(for: day.nutritionCompliance))
                    .frame(height: 6)

                // Sleep quality
                RoundedRectangle(cornerRadius: 2)
                    .fill(sleepColor(for: day.sleepQuality))
                    .frame(height: 6)
            } else {
                // Compact: single compliance indicator
                Circle()
                    .fill(complianceColor(for: day.nutritionCompliance))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
    }

    private func complianceColor(for value: Double?) -> Color {
        guard let value = value else { return .gray.opacity(0.3) }
        if value >= 0.9 { return .green }
        if value >= 0.7 { return .yellow }
        return .red
    }

    private func sleepColor(for value: Double?) -> Color {
        guard let value = value else { return .gray.opacity(0.3) }
        if value >= 0.8 { return .blue }
        if value >= 0.6 { return .orange }
        return .red
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    WeeklyRhythmWidget()
} timeline: {
    WeeklyEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemLarge) {
    WeeklyRhythmWidget()
} timeline: {
    WeeklyEntry(date: .now, data: .placeholder)
}
