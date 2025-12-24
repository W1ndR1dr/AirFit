import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct HRREntry: TimelineEntry {
    let date: Date
    let data: HRRSessionData?
    let isPlaceholder: Bool

    static let placeholder = HRREntry(
        date: Date(),
        data: .placeholder,
        isPlaceholder: true
    )
}

// MARK: - Timeline Provider

struct HRRTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HRREntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (HRREntry) -> Void) {
        let entry = HRREntry(
            date: Date(),
            data: context.isPreview ? .workoutPreview : (SharedDataStore.hrrSessionData ?? .placeholder),
            isPlaceholder: context.isPreview
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HRREntry>) -> Void) {
        let currentDate = Date()
        let data = SharedDataStore.hrrSessionData

        let entry = HRREntry(
            date: currentDate,
            data: data,
            isPlaceholder: false
        )

        // During active workout, refresh every 10 seconds for live updates
        // Otherwise refresh every 5 minutes
        let refreshInterval: TimeInterval = data?.isWorkoutActive == true ? 10 : 300
        let nextUpdate = currentDate.addingTimeInterval(refreshInterval)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Complication Views

struct HRRComplicationEntryView: View {
    var entry: HRREntry
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

    // MARK: - Circular (Live HR with phase ring)

    private var circularView: some View {
        ZStack {
            if let data = entry.data {
                // Fatigue/phase ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)

                if data.isWorkoutActive {
                    // Animated recovery progress ring
                    Circle()
                        .trim(from: 0, to: recoveryProgress(data))
                        .stroke(
                            phaseGradient(data),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                VStack(spacing: -2) {
                    if data.isWorkoutActive {
                        // Live heart rate
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(heartColor(data))

                            Text("\(Int(data.currentHR))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }

                        // Phase indicator
                        Text(data.phaseDisplayName)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        // Resting state
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.red.opacity(0.7))

                        Text("HRR")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "heart.fill")
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
            if let data = entry.data, data.isWorkoutActive {
                Text("\(Int(data.currentHR))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(heartColor(data))
                    .widgetCurvesContent()
            } else {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red.opacity(0.6))
            }
        }
        .widgetLabel {
            if let data = entry.data, data.isWorkoutActive {
                ProgressView(value: 1.0 - (data.degradationPercent / 100))
                    .tint(fatigueColor(data.fatigueLevel))
            } else {
                Text("HRR Ready")
            }
        }
    }

    // MARK: - Rectangular (Full workout dashboard)

    private var rectangularView: some View {
        HStack(spacing: 8) {
            if let data = entry.data {
                if data.isWorkoutActive {
                    // Live workout view
                    VStack(alignment: .leading, spacing: 2) {
                        // Header row with HR and phase
                        HStack {
                            HStack(spacing: 3) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(heartColor(data))

                                Text("\(Int(data.currentHR))")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }

                            Spacer()

                            // Fatigue badge
                            Text(data.fatigueLevel.capitalized)
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(fatigueColor(data.fatigueLevel).opacity(0.3))
                                .clipShape(Capsule())
                        }

                        // Stats row
                        HStack(spacing: 12) {
                            // Sets completed
                            Label("\(data.setsCompleted)", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)

                            // Peak HR
                            Label("\(Int(data.peakHR))", systemImage: "arrow.up.heart")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)

                            // Recovery rate (if available)
                            if let rate = data.latestRecoveryRate {
                                Label(String(format: "%.1f", rate * 60), systemImage: "arrow.down.heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.green)
                            }
                        }

                        // Recovery progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            colors: [fatigueColor(data.fatigueLevel), fatigueColor(data.fatigueLevel).opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * (1.0 - data.degradationPercent / 100), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                } else {
                    // Idle state - show summary or ready message
                    HStack {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.red.opacity(0.7))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("HRR Tracking")
                                .font(.system(size: 12, weight: .semibold))

                            if data.setsCompleted > 0 {
                                Text("Last: \(data.setsCompleted) sets")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Start a workout")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                }
            } else {
                HStack {
                    Image(systemName: "heart.circle")
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Heart Rate")
                            .font(.caption)
                        Text("Recovery")
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
        if let data = entry.data, data.isWorkoutActive {
            Label("\(Int(data.currentHR)) bpm • \(data.fatigueLevel.capitalized)", systemImage: "heart.fill")
        } else {
            Text("❤️ HRR Ready")
        }
    }

    // MARK: - Helper Functions

    private func recoveryProgress(_ data: HRRSessionData) -> Double {
        switch data.currentPhase {
        case "exertion":
            // Show how close to peak
            guard data.peakHR > 60 else { return 0.8 }
            return min(1.0, data.currentHR / data.peakHR)
        case "recovery":
            // Show recovery progress (current vs peak)
            guard data.peakHR > 60 else { return 0.5 }
            let recovered = data.peakHR - data.currentHR
            let toRecover = data.peakHR - 100 // Target ~100 bpm
            return min(1.0, max(0, recovered / max(1, toRecover)))
        default:
            return 0.3
        }
    }

    private func phaseGradient(_ data: HRRSessionData) -> LinearGradient {
        switch data.currentPhase {
        case "exertion":
            return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "recovery":
            return LinearGradient(colors: [.green, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func heartColor(_ data: HRRSessionData) -> Color {
        switch data.currentPhase {
        case "exertion": return .red
        case "recovery": return .green
        default: return .pink
        }
    }

    private func fatigueColor(_ level: String) -> Color {
        switch level {
        case "fresh": return .green
        case "productive": return .blue
        case "fatigued": return .orange
        case "asymptote": return .red
        case "depleted": return .purple
        default: return .gray
        }
    }
}

// MARK: - Widget Definition

struct HRRComplication: Widget {
    let kind: String = "HRRComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HRRTimelineProvider()) { entry in
            HRRComplicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Heart Rate Recovery")
        .description("Live fatigue tracking during workouts with recovery rate analysis.")
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
    HRRComplication()
} timeline: {
    HRREntry(date: .now, data: .workoutPreview, isPlaceholder: false)
    HRREntry(date: .now, data: .placeholder, isPlaceholder: false)
}

#Preview(as: .accessoryCircular) {
    HRRComplication()
} timeline: {
    HRREntry(date: .now, data: .workoutPreview, isPlaceholder: false)
}
