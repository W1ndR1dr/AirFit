import SwiftUI
import WidgetKit

// MARK: - Morning Brief Smart Widget

struct MorningBriefWidget: Widget {
    let kind: String = "MorningBrief"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MorningBriefTimelineProvider()) { entry in
            MorningBriefView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Brief")
        .description("Context-aware daily summary that adapts throughout the day")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider

struct MorningBriefTimelineProvider: TimelineProvider {
    typealias Entry = MorningBriefEntry

    func placeholder(in context: Context) -> MorningBriefEntry {
        MorningBriefEntry(
            date: Date(),
            context: .morning,
            readiness: .placeholder,
            nutrition: .placeholder,
            energy: .placeholder,
            insight: .placeholder,
            nudge: .placeholder
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MorningBriefEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MorningBriefEntry>) -> Void) {
        var entries: [MorningBriefEntry] = []
        let now = Date()

        // Create entries for different times of day
        // The widget content changes based on context
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        // Create entry for now
        entries.append(createEntry(for: now))

        // Schedule transitions at key times
        let transitionHours = [6, 10, 12, 17, 22]
        for targetHour in transitionHours {
            if targetHour > hour {
                if let transitionDate = calendar.date(bySettingHour: targetHour, minute: 0, second: 0, of: now) {
                    entries.append(createEntry(for: transitionDate))
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

    private func createEntry(for date: Date = Date()) -> MorningBriefEntry {
        let nutrition = WidgetDataStore.nutritionData ?? .placeholder
        let isTrainingDay = nutrition.isTrainingDay

        return MorningBriefEntry(
            date: date,
            context: WidgetContext.current(isTrainingDay: isTrainingDay, hasWorkoutToday: false),
            readiness: WidgetDataStore.readinessData ?? .placeholder,
            nutrition: nutrition,
            energy: WidgetDataStore.energyData ?? .placeholder,
            insight: WidgetDataStore.insights.first ?? .placeholder,
            nudge: WidgetDataStore.coachNudge ?? .placeholder
        )
    }
}

struct MorningBriefEntry: TimelineEntry {
    let date: Date
    let context: WidgetContext
    let readiness: WidgetReadinessData
    let nutrition: WidgetNutritionData
    let energy: WidgetEnergyData
    let insight: WidgetInsight
    let nudge: WidgetCoachNudge
}

// MARK: - Views

struct MorningBriefView: View {
    let entry: MorningBriefEntry
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

    private var contextTitle: String {
        switch entry.context {
        case .morning: return "Good Morning"
        case .preWorkout: return "Pre-Workout"
        case .postWorkout: return "Post-Workout"
        case .afternoon: return "Afternoon Check"
        case .evening: return "Evening Review"
        case .night: return "Night Summary"
        }
    }

    private var readinessColor: Color {
        switch entry.readiness.category {
        case "Great": return .green
        case "Good": return .blue
        case "Moderate": return .orange
        case "Rest": return .red
        default: return .gray
        }
    }

    // MARK: - Medium View (Primary content based on context)

    private var mediumView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(contextTitle)
                        .font(.system(size: 14, weight: .bold))

                    if entry.nutrition.isTrainingDay {
                        Label("Training Day", systemImage: "dumbbell.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    } else {
                        Label("Rest Day", systemImage: "moon.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Readiness badge
                HStack(spacing: 4) {
                    Image(systemName: entry.readiness.categoryIcon)
                    Text(entry.readiness.category)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(readinessColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(readinessColor.opacity(0.15), in: Capsule())
            }
            .padding(.horizontal)
            .padding(.top)

            Spacer()

            // Context-specific content
            contextContent
                .padding(.horizontal)

            Spacer()

            // Coach nudge
            Text(entry.nudge.message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .widgetURL(URL(string: "airfit://\(entry.context.rawValue)"))
    }

    @ViewBuilder
    private var contextContent: some View {
        switch entry.context {
        case .morning:
            // Morning: Focus on readiness + protein goal
            HStack(spacing: 16) {
                // Readiness summary
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.readiness.summaryText)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Text(entry.readiness.category == "Great" ? "Train hard today!" :
                         entry.readiness.category == "Rest" ? "Recovery day" : "Normal training")
                        .font(.system(size: 13, weight: .semibold))
                }

                Spacer()

                // Today's protein target
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Protein Goal")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("\(entry.nutrition.targetProtein)g")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                }
            }

        case .preWorkout:
            // Pre-workout: Readiness focus
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Readiness")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    HStack {
                        Image(systemName: entry.readiness.categoryIcon)
                            .font(.system(size: 24))
                        Text(entry.readiness.category)
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundStyle(readinessColor)
                }

                Spacer()

                // Protein so far
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Protein")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("\(entry.nutrition.protein)g")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("of \(entry.nutrition.targetProtein)g")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

        case .afternoon, .evening, .postWorkout:
            // Afternoon/Evening/Post-workout: Macro progress
            HStack(spacing: 12) {
                MacroProgressColumn(label: "Cal", current: entry.nutrition.calories, target: entry.nutrition.targetCalories, color: .orange)
                MacroProgressColumn(label: "Protein", current: entry.nutrition.protein, target: entry.nutrition.targetProtein, color: .blue)
                MacroProgressColumn(label: "Net", value: entry.energy.netLabel, color: entry.energy.isDeficit ? .red : .green)
            }

        case .night:
            // Night: Day summary
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Intake")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("\(entry.nutrition.calories) cal")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("\(entry.nutrition.protein)g protein")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Energy Balance")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(entry.energy.netLabel)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(entry.energy.isDeficit ? .red : .green)
                }
            }
        }
    }

    // MARK: - Large View (Full dashboard)

    private var largeView: some View {
        VStack(spacing: 12) {
            // Header (same as medium)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(contextTitle)
                        .font(.system(size: 16, weight: .bold))

                    if entry.nutrition.isTrainingDay {
                        Label("Training Day", systemImage: "dumbbell.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                    } else {
                        Label("Rest Day", systemImage: "moon.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Readiness badge
                HStack(spacing: 4) {
                    Image(systemName: entry.readiness.categoryIcon)
                    Text(entry.readiness.category)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(readinessColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(readinessColor.opacity(0.15), in: Capsule())
            }
            .padding(.horizontal)
            .padding(.top)

            // Macro progress bars
            VStack(spacing: 8) {
                MacroProgressRow(label: "Calories", current: entry.nutrition.calories, target: entry.nutrition.targetCalories, color: .orange)
                MacroProgressRow(label: "Protein", current: entry.nutrition.protein, target: entry.nutrition.targetProtein, color: .blue)
                MacroProgressRow(label: "Carbs", current: entry.nutrition.carbs, target: entry.nutrition.targetCarbs, color: .green)
                MacroProgressRow(label: "Fat", current: entry.nutrition.fat, target: entry.nutrition.targetFat, color: .yellow)
            }
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            // Energy balance
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Projected Balance")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text(entry.energy.netLabel)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(entry.energy.isDeficit ? .red : .green)
                        Text("cal")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Confidence indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Confidence")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("\(Int(entry.energy.confidence * 100))%")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
            }
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            // Insight teaser
            HStack(spacing: 8) {
                Image(systemName: entry.insight.categoryIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(.purple)

                Text(entry.insight.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()

            // Coach nudge
            Text(entry.nudge.message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .widgetURL(URL(string: "airfit://\(entry.context.rawValue)"))
    }
}

// MARK: - Helper Views

struct MacroProgressColumn: View {
    let label: String
    var current: Int = 0
    var target: Int = 1
    var value: String?
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            if let value = value {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            } else {
                Text("\(current)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))

                ProgressView(value: min(1.0, Double(current) / Double(target)))
                    .tint(color)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MacroProgressRow: View {
    let label: String
    let current: Int
    let target: Int
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(current) / Double(target))
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 55, alignment: .leading)

            ProgressView(value: progress)
                .tint(color)

            Text("\(current)/\(target)")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    MorningBriefWidget()
} timeline: {
    MorningBriefEntry(
        date: .now,
        context: .morning,
        readiness: .placeholder,
        nutrition: .placeholder,
        energy: .placeholder,
        insight: .placeholder,
        nudge: .placeholder
    )
}

#Preview(as: .systemLarge) {
    MorningBriefWidget()
} timeline: {
    MorningBriefEntry(
        date: .now,
        context: .evening,
        readiness: .placeholder,
        nutrition: .placeholder,
        energy: .placeholder,
        insight: .placeholder,
        nudge: .placeholder
    )
}
