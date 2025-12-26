import SwiftUI
import WidgetKit

// MARK: - Energy Balance Widget

struct EnergyBalanceWidget: Widget {
    let kind: String = "EnergyBalance"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EnergyTimelineProvider()) { entry in
            EnergyBalanceView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Energy Balance")
        .description("See your projected calorie surplus or deficit")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

// MARK: - Timeline Provider

struct EnergyTimelineProvider: TimelineProvider {
    typealias Entry = EnergyEntry

    func placeholder(in context: Context) -> EnergyEntry {
        EnergyEntry(date: Date(), data: .placeholder, nutrition: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (EnergyEntry) -> Void) {
        let energy = WidgetDataStore.energyData ?? .placeholder
        let nutrition = WidgetDataStore.nutritionData ?? .placeholder
        let entry = EnergyEntry(date: Date(), data: energy, nutrition: nutrition)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EnergyEntry>) -> Void) {
        let energy = WidgetDataStore.energyData ?? .placeholder
        let nutrition = WidgetDataStore.nutritionData ?? .placeholder
        let entry = EnergyEntry(date: Date(), data: energy, nutrition: nutrition)

        // Refresh every 15 minutes as TDEE updates
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct EnergyEntry: TimelineEntry {
    let date: Date
    let data: WidgetEnergyData
    let nutrition: WidgetNutritionData
}

// MARK: - Views

struct EnergyBalanceView: View {
    let entry: EnergyEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .accessoryCircular:
            circularView
        default:
            smallView
        }
    }

    private var dialColor: Color {
        let net = entry.data.projectedNet
        if net < -300 { return .red }
        if net < -100 { return .orange }
        if net < 100 { return .green }
        if net < 300 { return .yellow }
        return .orange
    }

    private var netDescription: String {
        let net = entry.data.projectedNet
        if net < -200 { return "Deficit" }
        if net < 0 { return "Slight deficit" }
        if net < 200 { return "Target zone" }
        return "Surplus"
    }

    // MARK: - Small (Home Screen)

    private var smallView: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Energy")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if entry.data.isTrainingDay {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            // Dial gauge
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .rotationEffect(.degrees(90))

                // Colored arc based on position
                Circle()
                    .trim(from: 0.15, to: 0.15 + (entry.data.dialPosition * 0.7))
                    .stroke(
                        AngularGradient(
                            colors: [.red, .orange, .green, .green, .yellow, .orange],
                            center: .center,
                            startAngle: .degrees(125),
                            endAngle: .degrees(415)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))

                // Net value
                VStack(spacing: 2) {
                    Text(entry.data.netLabel)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(dialColor)
                    Text("cal")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            Spacer()

            // Confidence indicator
            HStack(spacing: 4) {
                Text(netDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if entry.data.confidence < 0.5 {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "airfit://nutrition"))
    }

    // MARK: - Circular (Lock Screen)

    private var circularView: some View {
        Gauge(value: entry.data.dialPosition) {
            Text("")
        } currentValueLabel: {
            VStack(spacing: 0) {
                Text(entry.data.projectedNet >= 0 ? "+" : "")
                    .font(.system(size: 8)) +
                Text("\(abs(entry.data.projectedNet))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
        }
        .gaugeStyle(.accessoryCircular)
        .tint(Gradient(colors: [.red, .orange, .green, .yellow, .orange]))
        .widgetURL(URL(string: "airfit://nutrition"))
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    EnergyBalanceWidget()
} timeline: {
    EnergyEntry(date: .now, data: .placeholder, nutrition: .placeholder)
    EnergyEntry(date: .now, data: WidgetEnergyData(
        currentTDEE: 2200,
        projectedTDEE: 2800,
        projectedNet: 350,
        confidence: 0.8,
        isTrainingDay: true,
        caloriesConsumed: 3150,
        lastUpdated: Date()
    ), nutrition: .placeholder)
}

#Preview(as: .accessoryCircular) {
    EnergyBalanceWidget()
} timeline: {
    EnergyEntry(date: .now, data: .placeholder, nutrition: .placeholder)
}
