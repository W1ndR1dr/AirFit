# Simplified Set Tracker

> Manual set tracking for non-Hevy users (the brothers' use case)

## Purpose

Allow users who don't use Hevy to manually track their strength training volume. This makes AirFit valuable for:

1. **Casual strength trainers** - Occasional lifting without detailed logging
2. **Home workout users** - Simple bodyweight or dumbbell sessions
3. **Multi-sport athletes** - Primary cardio focus, supplementary strength
4. **Hevy-free users** - People who don't want another app

---

## Design Philosophy

### Keep It Dead Simple

- **No exercise details** - Just muscle group and set count
- **No weight tracking** - That's what Hevy is for
- **One-tap increment** - Minimal friction
- **Weekly rolling view** - Same as Hevy-powered tracker

### The Minimum Viable Tracker

```
┌─────────────────────────────────────────────────────┐
│  WEEKLY SETS                          Week of Dec 15 │
├─────────────────────────────────────────────────────┤
│  Chest          ███████░░░  7/12        [−] [+]     │
│  Back           █████████░  9/12        [−] [+]     │
│  Shoulders      ████░░░░░░  4/12        [−] [+]     │
│  Legs           ██████████  12/12 ✓     [−] [+]     │
│  Arms           ██████░░░░  6/12        [−] [+]     │
│  Core           ███░░░░░░░  3/12        [−] [+]     │
└─────────────────────────────────────────────────────┘
```

---

## Data Model

### SwiftData Model

```swift
@Model
class ManualSetEntry {
    var id: UUID = UUID()
    var date: Date
    var muscleGroup: MuscleGroup
    var setCount: Int = 1

    init(muscleGroup: MuscleGroup, date: Date = Date(), setCount: Int = 1) {
        self.date = date
        self.muscleGroup = muscleGroup
        self.setCount = setCount
    }
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest
    case back
    case shoulders
    case legs
    case arms
    case core

    var displayName: String {
        rawValue.capitalized
    }

    var weeklyTarget: Int {
        switch self {
        case .legs: return 15
        case .back: return 15
        case .chest: return 12
        case .shoulders: return 12
        case .arms: return 10
        case .core: return 10
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.climbing"
        case .shoulders: return "figure.boxing"
        case .legs: return "figure.run"
        case .arms: return "figure.strengthtraining.functional"
        case .core: return "figure.core.training"
        }
    }
}
```

### Server-Side Representation

For AI context, manual sets are converted to a simplified WorkoutSnapshot:

```python
@dataclass
class ManualSetsSummary:
    """Aggregated manual set data for context injection."""
    week_start: str  # YYYY-MM-DD
    sets_by_muscle: dict[str, int]  # {"chest": 7, "back": 9, ...}
    total_sets: int
    days_active: int

def format_manual_sets_compact(summary: ManualSetsSummary) -> str:
    """Compact notation for manual sets."""
    # M:42sets|5days chest:7,back:9,legs:12,arms:6
    muscles = ",".join([f"{m}:{c}" for m, c in summary.sets_by_muscle.items()])
    return f"M:{summary.total_sets}sets|{summary.days_active}days {muscles}"
```

---

## UI Implementation

### ManualSetTrackerView

```swift
struct ManualSetTrackerView: View {
    @Query(
        filter: #Predicate<ManualSetEntry> { entry in
            entry.date >= Calendar.current.startOfWeek()
        },
        sort: \ManualSetEntry.date,
        order: .reverse
    )
    private var entries: [ManualSetEntry]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Weekly Sets")
                    .font(.headline)
                Spacer()
                Text("Week of \(weekStartDate, format: .dateTime.month().day())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Muscle group rows
            ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                MuscleGroupRow(
                    muscle: muscle,
                    currentSets: setsFor(muscle),
                    onIncrement: { increment(muscle) },
                    onDecrement: { decrement(muscle) }
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func setsFor(_ muscle: MuscleGroup) -> Int {
        entries
            .filter { $0.muscleGroup == muscle }
            .reduce(0) { $0 + $1.setCount }
    }

    func increment(_ muscle: MuscleGroup) {
        let entry = ManualSetEntry(muscleGroup: muscle)
        modelContext.insert(entry)

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func decrement(_ muscle: MuscleGroup) {
        guard let latest = entries
            .filter({ $0.muscleGroup == muscle })
            .sorted(by: { $0.date > $1.date })
            .first else { return }

        if latest.setCount > 1 {
            latest.setCount -= 1
        } else {
            modelContext.delete(latest)
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    var weekStartDate: Date {
        Calendar.current.startOfWeek()
    }
}

struct MuscleGroupRow: View {
    let muscle: MuscleGroup
    let currentSets: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var progress: Double {
        Double(currentSets) / Double(muscle.weeklyTarget)
    }

    var isComplete: Bool {
        currentSets >= muscle.weeklyTarget
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: muscle.icon)
                .font(.system(size: 16))
                .foregroundStyle(isComplete ? .green : .primary)
                .frame(width: 24)

            // Label
            Text(muscle.displayName)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isComplete ? Color.green : Theme.accent)
                        .frame(width: geo.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 8)

            // Count
            Text("\(currentSets)/\(muscle.weeklyTarget)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 45)

            // Stepper buttons
            Button(action: onDecrement) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(currentSets > 0 ? .primary : .quaternary)
            }
            .disabled(currentSets == 0)

            Button(action: onIncrement) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
            }
        }
    }
}
```

### Integration with Dashboard

```swift
struct TrainingContentView: View {
    @AppStorage("isHevyConfigured") private var isHevyConfigured = false
    @Query private var manualEntries: [ManualSetEntry]

    var showSetTracker: Bool {
        // Show if Hevy is configured OR user has manual entries
        isHevyConfigured || !manualEntries.isEmpty
    }

    var body: some View {
        VStack(spacing: 20) {
            // Weekly activity summary (always show)
            WeeklyActivitySummary()

            // Set tracker (conditional)
            if showSetTracker {
                if isHevyConfigured {
                    HevySetTrackerSection()
                } else {
                    ManualSetTrackerView()
                }
            }

            // Activity stream
            UnifiedActivityStream()
        }
    }
}
```

---

## User Onboarding

### When to Show Manual Tracker

1. **User has no Hevy configured** AND
2. **User has done at least one strength workout** (from HealthKit) OR
3. **User manually adds their first set**

### First-Time Experience

```swift
struct ManualSetTrackerEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Track Your Sets")
                .font(.headline)

            Text("Tap + to log sets for each muscle group. No need to track individual exercises—just keep a simple weekly tally.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

---

## Server Sync

### Sync Endpoint

```python
@app.post("/manual-sets/sync")
async def sync_manual_sets(data: ManualSetsSync):
    """Receive manual set data from iOS."""
    summary = ManualSetsSummary(
        week_start=data.week_start,
        sets_by_muscle=data.sets_by_muscle,
        total_sets=sum(data.sets_by_muscle.values()),
        days_active=data.days_active
    )

    # Store for context injection
    await context_store.update_manual_sets(data.user_id, summary)

    return {"status": "ok"}
```

### iOS Sync Logic

```swift
func syncManualSets() async {
    let thisWeek = entries.filter { Calendar.current.isDateInThisWeek($0.date) }

    let setsByMuscle = Dictionary(grouping: thisWeek, by: \.muscleGroup)
        .mapValues { entries in entries.reduce(0) { $0 + $1.setCount } }

    let activeDays = Set(thisWeek.map { Calendar.current.startOfDay(for: $0.date) }).count

    let payload = ManualSetsSync(
        weekStart: Calendar.current.startOfWeek().ISO8601Format(),
        setsByMuscle: setsByMuscle.mapKeys { $0.rawValue },
        daysActive: activeDays
    )

    try await apiClient.post("/manual-sets/sync", body: payload)
}
```

---

## AI Context Integration

### In Chat Context

When building context for chat, include manual sets if present:

```python
async def build_training_context(user_id: str) -> str:
    lines = []

    # Check for Hevy data first
    hevy_data = await get_hevy_set_tracker(user_id)
    if hevy_data:
        lines.append(format_hevy_set_tracker(hevy_data))
    else:
        # Fall back to manual sets
        manual_data = await get_manual_sets(user_id)
        if manual_data:
            lines.append("[MANUAL SET TRACKER]")
            lines.append(format_manual_sets_compact(manual_data))

    return "\n".join(lines)
```

### Compact Notation

```
M:42sets|5days chest:7,back:9,shoulders:4,legs:12,arms:6,core:3
```

The AI can interpret this as:
- User did 42 total sets this week across 5 active days
- Distribution across muscle groups
- No specific exercise data (it's manual tracking)

---

## Edge Cases

### Switching from Manual to Hevy

If user configures Hevy after using manual tracker:
1. Manual data persists in SwiftData
2. UI switches to Hevy-powered tracker
3. Historical manual data visible in weekly summary

### Accidental Over-Counting

Add undo capability:
- Recent decrements can be undone for 30 seconds
- Show small "Undo" button after decrement

### Weekly Reset

- Data persists indefinitely in SwiftData
- UI only shows current week
- Historical weeks accessible for trends

---

## Future Enhancements

### Phase 1 (Current)
- Basic +/- tracking
- Weekly view
- Server sync

### Phase 2 (Later)
- Workout grouping ("Mark as session")
- Time-of-day tracking
- Notes per session

### Phase 3 (Much Later)
- Simple exercise tracking (optional)
- Weight tracking (optional)
- Migration to Hevy if user wants more detail

---

## Summary

The simplified set tracker serves users who:
1. Don't want the complexity of Hevy
2. Just need to know "did I hit my weekly volume?"
3. Primarily do cardio but want to track strength

It maintains the app's value for the brothers' use case while keeping the UI simple and focused.
