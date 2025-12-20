# Other Modalities

> Cycling, swimming, yoga, and other workout types

## Cycling

### Key Metrics

| Metric | Source | Importance |
|--------|--------|------------|
| **Distance** | HealthKit | Primary - weekly volume matters |
| **Average Speed** | HealthKit or calculate | Secondary - varies by terrain |
| **Elevation Gain** | Workout metadata | High for hilly riders |
| **Cadence** | `cyclingCadence` | 80-100 rpm optimal |
| **Power** | External power meter | Gold standard (if available) |
| **Heart Rate Zones** | Calculate from samples | For training intensity |

### Normalized Power (if power meter)

For users with power meters, Normalized Power (NP) is more meaningful than average power:

```python
def calculate_normalized_power(power_samples):
    """
    NP = 4th root of average of (power^4)
    Accounts for variability - steady 200w ≠ spiking 400w/0w
    """
    powered = [p**4 for p in power_samples]
    return (sum(powered) / len(powered)) ** 0.25
```

### Cycling-Specific UI

Similar pattern to running:

```swift
struct CyclingDetailView: View {
    let ride: CyclingWorkout

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Route map (if outdoor)
                if let coordinates = ride.routeCoordinates {
                    RouteMapView(coordinates: coordinates)
                        .frame(height: 300)
                }

                // Hero metrics
                HStack {
                    StatTile(label: "Distance", value: "\(ride.distanceMiles) mi")
                    StatTile(label: "Avg Speed", value: "\(ride.avgSpeedMph) mph")
                    StatTile(label: "Elevation", value: "+\(ride.elevationGain) ft")
                }

                // Power metrics (if available)
                if let power = ride.avgPower {
                    HStack {
                        StatTile(label: "Avg Power", value: "\(power) W")
                        StatTile(label: "NP", value: "\(ride.normalizedPower) W")
                        StatTile(label: "Cadence", value: "\(ride.avgCadence) rpm")
                    }
                }

                // Elevation profile
                ElevationProfileChart(data: ride.elevationProfile)

                // HR zones
                HRZoneBar(zones: ride.hrZones)
            }
        }
    }
}
```

### Compact Notation

```
C:90m|28.4mi|18.9mph|Z2:65m,Z3:20m|np185w|+1250ft
│  │     │      │       │          │      └── Elevation gain
│  │     │      │       │          └── Normalized power (if available)
│  │     │      │       └── Time in HR zones
│  │     │      └── Average speed
│  │     └── Distance
│  └── Duration
└── Type: C=Cycle
```

---

## Swimming

### Key Metrics

| Metric | Source | Notes |
|--------|--------|-------|
| **Distance** | HealthKit | Yards or meters (pool-dependent) |
| **Pace per 100** | Calculate | Universal benchmark |
| **SWOLF** | Calculate: strokes + time | Efficiency score (70-80 excellent) |
| **Stroke Count** | `swimmingStrokeCount` | Per lap |
| **Stroke Type** | Workout events | Freestyle, back, breast, fly |
| **Lap Count** | Workout events | Auto-detected by Watch |

### Lap Data from HealthKit

```swift
func parseSwimmingLaps(from workout: HKWorkout) -> [SwimLap] {
    guard let events = workout.workoutEvents else { return [] }

    return events
        .filter { $0.type == .lap }
        .map { event in
            SwimLap(
                lapNumber: event.metadata?["lapNumber"] as? Int ?? 0,
                timeSeconds: event.dateInterval.duration,
                strokeType: event.metadata?["strokeStyle"] as? String ?? "freestyle",
                strokeCount: event.metadata?["strokeCount"] as? Int
            )
        }
}
```

### SWOLF Calculation

```swift
struct SwimLap {
    let lapNumber: Int
    let timeSeconds: Double
    let strokeCount: Int?

    var swolf: Int? {
        guard let strokes = strokeCount else { return nil }
        return Int(timeSeconds) + strokes
    }
}

// Example: 30 seconds + 20 strokes = SWOLF 50 (excellent)
```

### Swimming-Specific UI

```swift
struct SwimmingDetailView: View {
    let swim: SwimmingWorkout

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero metrics
                HStack {
                    StatTile(label: "Distance", value: "\(swim.distanceYards) yd")
                    StatTile(label: "Pace", value: swim.pacePer100)
                    StatTile(label: "Avg SWOLF", value: "\(swim.avgSwolf)")
                }

                // Stroke distribution (pie chart)
                StrokeDistributionChart(strokes: swim.strokeBreakdown)

                // Lap-by-lap breakdown
                LapTableView(laps: swim.laps)

                // Pace trend
                PaceChartView(laps: swim.laps)
            }
        }
    }
}
```

### Compact Notation

```
W:35m|1650yd|2:08/100|free:28,back:4|spm24|swolf72
│  │     │       │        │         │      └── Avg SWOLF
│  │     │       │        │         └── Strokes per minute
│  │     │       │        └── Laps by stroke type
│  │     │       └── Pace per 100
│  │     └── Distance
│  └── Duration
└── Type: W=sWim (S was taken by Strength)
```

---

## Yoga / Mobility

### The Hard Truth About Yoga Metrics

Most yoga metrics are meaningless in isolation:
- Duration doesn't equal quality
- Heart rate during yoga tells you almost nothing
- Flexibility improvements are glacially slow

### What Actually Matters

For the AI to track and surface:

| Signal | Why It Matters | How to Track |
|--------|---------------|--------------|
| **Consistency** | Habit > intensity | "4/7 days for 3 weeks" |
| **Pre/Post Workout Correlation** | Does it help performance? | Next-day workout quality |
| **Sleep Quality Link** | Evening yoga → better sleep? | Correlate with sleep data |
| **Injury Prevention** | Gap detection | "No hip mobility in 10 days" |

### Minimal Data Model

```swift
@Model
class YogaSession {
    var id: String
    var workoutDate: Date
    var durationMinutes: Int
    var style: String?  // "vinyasa", "yin", "power", "restorative"
    var focusAreas: [String]?  // ["hips", "shoulders", "core"]
    var perceivedBenefit: Int?  // 1-5 optional user rating
}
```

### Yoga-Specific UI

Keep it minimal. Don't try to quantify the unquantifiable.

```swift
struct YogaContentView: View {
    let sessions: [YogaSession]

    var body: some View {
        VStack(spacing: 20) {
            // Streak / consistency hero
            ConsistencyCard(
                currentStreak: yogaStreak,
                longestStreak: longestYogaStreak,
                thisWeek: sessionsThisWeek
            )

            // Weekly duration trend
            WeeklyDurationBar(sessions: sessions)

            // Recent sessions (simple list)
            ForEach(sessions.prefix(5)) { session in
                YogaSessionRow(session: session)
            }
        }
    }
}
```

### Compact Notation

```
Y:45m|vinyasa|hips,shoulders|rpe4
│  │     │         │         └── Perceived benefit/exertion
│  │     │         └── Focus areas
│  │     └── Style
│  └── Duration
└── Type: Y=Yoga
```

---

## HIIT / Interval Training

### Key Metrics

| Metric | Source | Notes |
|--------|--------|-------|
| **Duration** | HealthKit | Total time |
| **Avg HR** | Calculate | Overall intensity |
| **Max HR** | HealthKit | Peak effort |
| **Calories** | HealthKit | Energy expenditure |
| **HR Zone Distribution** | Calculate | Should be mostly Z4-Z5 |

### What Makes HIIT Different

- Very high intensity, short duration
- HR should spike and recover repeatedly
- Recovery HR between intervals matters

### Compact Notation

```
H:25m|285cal|hr172avg/189max|Z4:12m,Z5:8m
│  │     │        │             └── Zone distribution
│  │     │        └── Avg/max heart rate
│  │     └── Calories burned
│  └── Duration
└── Type: H=HIIT
```

---

## Generic "Other" Workouts

For workout types we don't have specialized handling for:

### Basic Data Model

```swift
struct GenericWorkout {
    let id: String
    let workoutType: HKWorkoutActivityType
    let date: Date
    let durationMinutes: Int
    let caloriesBurned: Int?
    let avgHR: Int?
}
```

### Compact Notation

```
O:30m|hiking|180cal|hr125avg
│  │     │      │      └── Avg HR
│  │     │      └── Calories
│  │     └── Workout type name
│  └── Duration
└── Type: O=Other
```

---

## Unified Activity Card Component

All workout types can share a common card layout with type-specific accents:

```swift
struct ActivityCard: View {
    let workout: any Workout

    var body: some View {
        HStack {
            // Type icon with color accent
            Image(systemName: workout.iconName)
                .foregroundStyle(workout.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading) {
                Text(workout.title)
                    .font(.headline)
                Text(workout.subtitle)  // Type-specific summary
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Type-specific mini visualization
            workout.miniVisualization
                .frame(width: 48, height: 32)
        }
        .padding()
        .background(workout.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Type-specific subtitle examples:
// Strength: "Chest & Triceps • 6200 lbs"
// Running: "5.2 mi • 8:42 /mi"
// Cycling: "18.5 mi • 245 ft gain"
// Swimming: "1650 yd • 2:05 /100"
// Yoga: "45 min • Vinyasa"
```

---

## Activity Type Colors

Extend Theme.swift:

```swift
extension Theme {
    static let strength = Color.adaptive(light: 0xE88B7F, dark: 0xF4A99F)  // Coral
    static let running = Color.adaptive(light: 0x5DA5A3, dark: 0x7EBFBD)   // Teal
    static let cycling = Color.adaptive(light: 0x7DB095, dark: 0x9DCAB0)   // Sage
    static let swimming = Color.adaptive(light: 0x8BB4B8, dark: 0xA8CED2)  // Pool blue
    static let yoga = Color.adaptive(light: 0xB4A0C7, dark: 0xCFC0DC)      // Lavender
    static let hiit = Color.adaptive(light: 0xE9B879, dark: 0xF4CFA0)      // Amber
}
```

---

## Priority Order for Implementation

1. **Running** - Most data-rich, highest value for cardio users
2. **Yoga** - Simple to implement, high consistency value
3. **Cycling** - Similar to running architecture
4. **Swimming** - Unique UI needs (laps, strokes)
5. **HIIT** - Can use generic workout pattern initially
6. **Other** - Generic fallback for any HealthKit type
