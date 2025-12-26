import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Quick Log Intent (for Lock Screen button)

struct QuickLogIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Food"
    static var description = IntentDescription("Open AirFit to log food with voice or camera")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Mode")
    var mode: LogMode

    enum LogMode: String, AppEnum {
        case voice = "voice"
        case camera = "camera"

        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Log Mode"
        static var caseDisplayRepresentations: [LogMode: DisplayRepresentation] = [
            .voice: "Voice",
            .camera: "Camera"
        ]
    }

    init() {
        self.mode = .voice
    }

    init(mode: LogMode) {
        self.mode = mode
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        // App will handle the deep link via onOpenURL
        return .result(opensIntent: OpenURLIntent(URL(string: "airfit://log/\(mode.rawValue)")!))
    }
}

// MARK: - Quick Log Widget (Control Center / Lock Screen Button)

struct QuickLogWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "QuickLog") {
            ControlWidgetButton(action: QuickLogIntent(mode: .voice)) {
                Label("Log Food", systemImage: "mic.fill")
            }
        }
        .displayName("Quick Log")
        .description("Quickly log food with your voice")
    }
}

// MARK: - Camera Quick Log Widget

struct CameraLogWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "CameraLog") {
            ControlWidgetButton(action: QuickLogIntent(mode: .camera)) {
                Label("Snap Food", systemImage: "camera.fill")
            }
        }
        .displayName("Snap Food")
        .description("Log food by taking a photo")
    }
}

// MARK: - Lock Screen Accessory Widget (alternative approach)

struct QuickLogAccessoryWidget: Widget {
    let kind: String = "QuickLogAccessory"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickLogTimelineProvider()) { entry in
            QuickLogAccessoryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Log")
        .description("Tap to log food")
        .supportedFamilies([.accessoryCircular])
    }
}

struct QuickLogTimelineProvider: TimelineProvider {
    typealias Entry = QuickLogEntry

    func placeholder(in context: Context) -> QuickLogEntry {
        QuickLogEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> Void) {
        completion(QuickLogEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogEntry>) -> Void) {
        let entry = QuickLogEntry(date: Date())
        // Static widget, refresh once per hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct QuickLogEntry: TimelineEntry {
    let date: Date
}

struct QuickLogAccessoryView: View {
    let entry: QuickLogEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.primary)
        }
        .widgetURL(URL(string: "airfit://log/voice"))
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    QuickLogAccessoryWidget()
} timeline: {
    QuickLogEntry(date: .now)
}
