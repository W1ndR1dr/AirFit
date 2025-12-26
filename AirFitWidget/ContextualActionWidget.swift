import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Contextual Action Widget

struct ContextualActionWidget: Widget {
    let kind: String = "ContextualAction"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ContextualActionTimelineProvider()) { entry in
            ContextualActionView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Smart Action")
        .description("Context-aware action button that adapts to your day")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Timeline Provider

struct ContextualActionTimelineProvider: TimelineProvider {
    typealias Entry = ContextualActionEntry

    func placeholder(in context: Context) -> ContextualActionEntry {
        ContextualActionEntry(date: Date(), context: .morning, nudge: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ContextualActionEntry) -> Void) {
        let currentContext = WidgetDataStore.currentContext
        let nudge = WidgetDataStore.coachNudge ?? .placeholder
        let entry = ContextualActionEntry(date: Date(), context: currentContext, nudge: nudge)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ContextualActionEntry>) -> Void) {
        var entries: [ContextualActionEntry] = []
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        // Create current entry
        let currentContext = WidgetDataStore.currentContext
        let nudge = WidgetDataStore.coachNudge ?? .placeholder
        entries.append(ContextualActionEntry(date: now, context: currentContext, nudge: nudge))

        // Schedule context transitions
        let transitionHours = [6, 10, 12, 17, 22]
        for targetHour in transitionHours {
            if targetHour > hour {
                if let transitionDate = calendar.date(bySettingHour: targetHour, minute: 0, second: 0, of: now) {
                    let futureContext = contextForHour(targetHour)
                    entries.append(ContextualActionEntry(date: transitionDate, context: futureContext, nudge: nudge))
                }
            }
        }

        // Refresh at next transition or in 1 hour
        let nextUpdate = entries.count > 1
            ? entries[1].date
            : calendar.date(byAdding: .hour, value: 1, to: now)!

        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }

    private func contextForHour(_ hour: Int) -> WidgetContext {
        switch hour {
        case 5..<10: return .morning
        case 10..<12: return .preWorkout
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .night
        }
    }
}

struct ContextualActionEntry: TimelineEntry {
    let date: Date
    let context: WidgetContext
    let nudge: WidgetCoachNudge
}

// MARK: - Views

struct ContextualActionView: View {
    let entry: ContextualActionEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        default:
            smallView
        }
    }

    private var actionColor: Color {
        switch entry.context {
        case .morning: return .orange
        case .preWorkout: return .green
        case .postWorkout: return .blue
        case .afternoon: return .green
        case .evening: return .purple
        case .night: return .indigo
        }
    }

    private var deepLinkURL: URL {
        switch entry.context {
        case .morning: return URL(string: "airfit://log/voice")!
        case .preWorkout: return URL(string: "airfit://dashboard")!
        case .postWorkout: return URL(string: "airfit://sync/hevy")!
        case .afternoon: return URL(string: "airfit://log/voice")!
        case .evening: return URL(string: "airfit://nutrition")!
        case .night: return URL(string: "airfit://insights")!
        }
    }

    // MARK: - Small View

    private var smallView: some View {
        VStack(spacing: 12) {
            Spacer()

            // Action button visualization
            ZStack {
                Circle()
                    .fill(actionColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(actionColor.opacity(0.3))
                    .frame(width: 60, height: 60)

                Image(systemName: entry.context.actionIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(actionColor)
            }

            // Action label
            Text(entry.context.suggestedAction)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.center)

            Spacer()

            // Nudge (if available)
            if !entry.nudge.message.isEmpty {
                Text(entry.nudge.message)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
        }
        .padding()
        .widgetURL(deepLinkURL)
    }

    // MARK: - Circular (Lock Screen)

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()

            Image(systemName: entry.context.actionIcon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .widgetURL(deepLinkURL)
    }

    // MARK: - Rectangular (Lock Screen)

    private var rectangularView: some View {
        HStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: entry.context.actionIcon)
                    .font(.system(size: 16, weight: .semibold))
            }

            // Action text
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.context.suggestedAction)
                    .font(.system(size: 13, weight: .semibold))

                Text(contextDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(deepLinkURL)
    }

    private var contextDescription: String {
        switch entry.context {
        case .morning: return "Start your day"
        case .preWorkout: return "Check your readiness"
        case .postWorkout: return "Log your workout"
        case .afternoon: return "Keep tracking"
        case .evening: return "Review your progress"
        case .night: return "See what AI found"
        }
    }
}

// MARK: - Training Day Toggle (Control Widget)

struct TrainingDayToggleWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "TrainingDayToggle") {
            ControlWidgetToggle(
                "Training Day",
                isOn: TrainingDayToggleValueProvider(),
                action: ToggleTrainingDayIntent()
            ) { isOn in
                Label(isOn ? "Training" : "Rest", systemImage: isOn ? "dumbbell.fill" : "moon.fill")
            }
        }
        .displayName("Training Day")
        .description("Toggle between training and rest day targets")
    }
}

struct TrainingDayToggleValueProvider: ControlWidgetValueProvider {
    var previewValue: Bool { true }

    func currentValue() async throws -> Bool {
        WidgetDataStore.nutritionData?.isTrainingDay ?? true
    }
}

struct ToggleTrainingDayIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Toggle Training Day"

    @Parameter(title: "Training Day")
    var value: Bool

    func perform() async throws -> some IntentResult {
        // Post notification to main app to toggle training day
        // The app will handle updating the data and refreshing widgets
        if let url = URL(string: "airfit://toggle-training-day/\(value)") {
            // Note: This would need to be handled via a shared state mechanism
            // For now, we'll just trigger a widget reload
            WidgetCenter.shared.reloadAllTimelines()
        }
        return .result()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    ContextualActionWidget()
} timeline: {
    ContextualActionEntry(date: .now, context: .morning, nudge: .placeholder)
    ContextualActionEntry(date: .now, context: .preWorkout, nudge: .placeholder)
    ContextualActionEntry(date: .now, context: .evening, nudge: .placeholder)
}

#Preview(as: .accessoryCircular) {
    ContextualActionWidget()
} timeline: {
    ContextualActionEntry(date: .now, context: .morning, nudge: .placeholder)
}

#Preview(as: .accessoryRectangular) {
    ContextualActionWidget()
} timeline: {
    ContextualActionEntry(date: .now, context: .afternoon, nudge: .placeholder)
}
