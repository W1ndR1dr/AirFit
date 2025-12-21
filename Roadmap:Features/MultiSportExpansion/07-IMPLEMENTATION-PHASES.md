# Implementation Phases

> Phased roadmap for multi-sport expansion (for future reference)

## Overview

| Phase | Focus | Duration | Key Deliverables |
|-------|-------|----------|------------------|
| 1 | Data Foundation | Week 1-2 | Extended WorkoutSnapshot, HealthKit queries |
| 2 | Running Feature | Week 3-4 | RunningDetailView, RouteMapView |
| 3 | UI Integration | Week 5 | Unified activity stream, filtering |
| 4 | AI Context | Week 6 | Cross-modality insights, cardio context |
| 5 | Simplified Set Tracker | Week 7 | Manual tracking for non-Hevy users |

---

## Phase 1: Data Foundation (Week 1-2)

### Server-Side Tasks

#### 1.1 Extend WorkoutSnapshot

**File:** `server/context_store.py`

```python
@dataclass
class WorkoutSnapshot:
    # NEW: Type discrimination
    workout_type: str  # "strength", "run", "cycle", "swim", "yoga", "other"

    # Universal fields
    duration_minutes: int
    start_time: str
    title: str

    # Strength-specific (existing, now optional)
    volume_kg: Optional[float] = None
    exercises: Optional[list[dict]] = None

    # Cardio-specific (NEW)
    distance_km: Optional[float] = None
    pace_min_per_km: Optional[float] = None
    avg_hr: Optional[int] = None
    hr_zone_minutes: Optional[dict[str, int]] = None
    elevation_m: Optional[float] = None

    # Swim-specific (NEW)
    stroke_breakdown: Optional[dict[str, int]] = None
    avg_swolf: Optional[int] = None

    # Computed (NEW)
    training_load: Optional[float] = None
```

#### 1.2 Add Cardio Topic Detection

**File:** `server/tiered_context.py`

```python
TOPIC_PATTERNS["cardio"] = {
    "keywords": [
        "run", "running", "jog", "bike", "cycling", "ride",
        "swim", "swimming", "pool", "pace", "miles", "km",
        "hr", "heart rate", "zone", "tempo", "interval"
    ],
    "patterns": [
        r"how.*(run|ride|swim)",
        r"(my|the|a|last).*(run|ride|swim|race)",
        r"\d+\s*(mi|km|miles|kilometers)",
        r"(z[1-5]|zone\s*\d)",
    ]
}

TOPIC_PATTERNS["cross_training"] = {
    "keywords": ["brick", "triathlon", "balance", "interference"],
    "patterns": [
        r"(run|ride|swim).*(after|before).*(lift|workout|legs)",
        r"does.*(affect|help|hurt)",
    ]
}
```

#### 1.3 Create Compact Notation Formatters

**File:** `server/workout_notation.py` (NEW)

```python
def format_workout_compact(workout: WorkoutSnapshot) -> str:
    """Format any workout type in compact notation."""
    if workout.workout_type == "strength":
        return format_strength_compact(workout)
    elif workout.workout_type == "run":
        return format_run_compact(workout)
    elif workout.workout_type == "cycle":
        return format_cycle_compact(workout)
    elif workout.workout_type == "swim":
        return format_swim_compact(workout)
    elif workout.workout_type == "yoga":
        return format_yoga_compact(workout)
    else:
        return format_generic_compact(workout)
```

### iOS-Side Tasks

#### 1.4 Extend HealthKitManager

**File:** `AirFit/Services/HealthKitManager.swift`

```swift
// NEW: Fetch workout route (GPS coordinates)
func fetchWorkoutRoute(for workout: HKWorkout) async throws -> [CLLocation] {
    guard let routes = workout.workoutRoutes else { return [] }

    var allLocations: [CLLocation] = []
    for route in routes {
        let locations = try await withCheckedThrowingContinuation { continuation in
            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let locations = locations {
                    allLocations.append(contentsOf: locations)
                }
                if done {
                    continuation.resume(returning: allLocations)
                }
            }
            healthStore.execute(query)
        }
    }
    return allLocations
}

// NEW: Fetch heart rate samples during workout
func fetchHeartRateSamples(during workout: HKWorkout) async throws -> [HRSample] {
    let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    let predicate = HKQuery.predicateForSamples(
        withStart: workout.startDate,
        end: workout.endDate,
        options: .strictStartDate
    )

    return try await withCheckedThrowingContinuation { continuation in
        let query = HKSampleQuery(
            sampleType: hrType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            if let error = error {
                continuation.resume(throwing: error)
                return
            }
            let hrSamples = (samples as? [HKQuantitySample])?.map { sample in
                HRSample(
                    bpm: Int(sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))),
                    timestamp: sample.startDate
                )
            } ?? []
            continuation.resume(returning: hrSamples)
        }
        healthStore.execute(query)
    }
}

// NEW: Calculate HR zones
func calculateHRZones(samples: [HRSample], maxHR: Int) -> HRZoneBreakdown {
    var zones = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]  // Minutes in each zone

    for sample in samples {
        let percentMax = Double(sample.bpm) / Double(maxHR) * 100
        let zone: Int
        switch percentMax {
        case ..<60: zone = 1
        case 60..<70: zone = 2
        case 70..<80: zone = 3
        case 80..<90: zone = 4
        default: zone = 5
        }
        zones[zone, default: 0] += 1  // Assuming ~1 sample per second
    }

    // Convert to minutes (divide by 60)
    return HRZoneBreakdown(
        zone1Minutes: zones[1]! / 60,
        zone2Minutes: zones[2]! / 60,
        zone3Minutes: zones[3]! / 60,
        zone4Minutes: zones[4]! / 60,
        zone5Minutes: zones[5]! / 60
    )
}
```

---

## Phase 2: Running Feature (Week 3-4)

### 2.1 Create RunningWorkout Model

**File:** `AirFit/Models/RunningWorkout.swift` (NEW)

```swift
@Model
class RunningWorkout {
    var id: String
    var title: String
    var workoutDate: Date
    var durationMinutes: Int

    var distanceMeters: Double
    var averagePaceSecondsPerKm: Double
    var elevationGainMeters: Double

    var routeCoordinates: [Coordinate]?
    var splits: [Split]?
    var hrZones: HRZoneBreakdown?

    var avgCadence: Int?
    var avgGroundContactMs: Int?

    // Computed properties
    var distanceMiles: Double { distanceMeters / 1609.34 }
    var averagePace: String { /* format as "X:XX /mi" */ }
}
```

### 2.2 Create RouteMapView

**File:** `AirFit/Views/Components/RouteMapView.swift` (NEW)

```swift
struct RouteMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    var colorMode: RouteColorMode = .solid

    var body: some View {
        Map {
            MapPolyline(coordinates: coordinates)
                .stroke(lineWidth: 4)

            if let first = coordinates.first {
                Marker("Start", coordinate: first)
                    .tint(.green)
            }
            if let last = coordinates.last {
                Marker("Finish", coordinate: last)
                    .tint(.red)
            }
        }
    }
}

struct RouteGlyph: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        // Render route as simplified path shape
        GeometryReader { geo in
            Path { path in
                guard let normalized = normalizeCoordinates(coordinates, to: geo.size) else { return }
                path.move(to: normalized.first!)
                for point in normalized.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(Theme.running, lineWidth: 1.5)
        }
    }
}
```

### 2.3 Create RunningDetailView

**File:** `AirFit/Views/RunningDetailView.swift` (NEW)

```swift
struct RunningDetailView: View {
    let run: RunningWorkout
    @State private var selectedMetric: RunMetric = .pace

    var body: some View {
        ZStack {
            BreathingMeshBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Route map
                    if let coords = run.routeCoordinates {
                        RouteMapView(coordinates: coords.map { $0.clLocation })
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Hero metrics
                    HStack {
                        StatTile(label: "Distance", value: "\(run.distanceMiles, format: .number.precision(.fractionLength(1))) mi")
                        StatTile(label: "Pace", value: run.averagePace)
                        StatTile(label: "Elevation", value: "+\(Int(run.elevationGainMeters * 3.281)) ft")
                    }

                    // Metric picker
                    Picker("Metric", selection: $selectedMetric) {
                        Text("Pace").tag(RunMetric.pace)
                        Text("Heart Rate").tag(RunMetric.heartRate)
                    }
                    .pickerStyle(.segmented)

                    // Chart (reuse existing)
                    InteractiveChartView(
                        data: chartData(for: selectedMetric),
                        color: Theme.running,
                        unit: selectedMetric.unit
                    )

                    // Splits
                    if let splits = run.splits {
                        SplitsTableView(splits: splits)
                    }

                    // HR Zones
                    if let zones = run.hrZones {
                        HRZoneBar(zones: zones)
                    }
                }
                .padding()
                .padding(.bottom, 100)
            }
        }
    }
}
```

### 2.4 Add Running Section to Dashboard

**File:** `AirFit/Views/DashboardView.swift`

Add to TrainingContentView:
- Recent runs list (below set tracker or as alternative)
- Weekly running summary card

---

## Phase 3: UI Integration (Week 5)

### 3.1 Create Unified Activity Stream

**File:** `AirFit/Views/Components/UnifiedActivityStream.swift` (NEW)

```swift
struct UnifiedActivityStream: View {
    let activities: [any Workout]
    @Binding var filter: ActivityFilter

    var body: some View {
        VStack(spacing: 12) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(ActivityFilter.allCases, id: \.self) { filterType in
                        FilterChip(
                            label: filterType.label,
                            isSelected: filter == filterType
                        ) {
                            filter = filterType
                        }
                    }
                }
            }

            // Activity cards
            ForEach(filteredActivities, id: \.id) { activity in
                ActivityCard(activity: activity)
                    .onTapGesture {
                        navigateToDetail(for: activity)
                    }
            }
        }
    }
}
```

### 3.2 Implement Implicit Personalization

```swift
class ActivityProfileManager {
    func calculateProfile() -> [WorkoutType: Priority] {
        let recent = getRecentWorkouts(days: 30)
        let counts = Dictionary(grouping: recent, by: \.type)
            .mapValues { $0.count }

        return counts.mapValues { count in
            switch count {
            case 4...: return .primary
            case 1...3: return .secondary
            default: return .tertiary
            }
        }
    }
}
```

### 3.3 Add Activity Type Colors to Theme

**File:** `AirFit/Views/Theme.swift`

```swift
extension Theme {
    static let running = Color.adaptive(light: 0x5DA5A3, dark: 0x7EBFBD)
    static let cycling = Color.adaptive(light: 0x7DB095, dark: 0x9DCAB0)
    static let swimming = Color.adaptive(light: 0x8BB4B8, dark: 0xA8CED2)
    static let yoga = Color.adaptive(light: 0xB4A0C7, dark: 0xCFC0DC)
    static let hiit = Color.adaptive(light: 0xE9B879, dark: 0xF4CFA0)
}
```

---

## Phase 4: AI Context (Week 6)

### 4.1 Update Insight Engine

**File:** `server/insight_engine.py`

Add cross-modality analysis prompt section.

### 4.2 Add Cardio Context Builder

**File:** `server/chat_context.py`

```python
async def build_cardio_context(days: int = 14) -> str:
    runs = await get_recent_runs(days=days)
    if not runs:
        return ""

    lines = ["[CARDIO]"]
    this_week = [r for r in runs if r.days_ago < 7]
    lines.append(f"This week: {len(this_week)} runs, {sum(r.distance_mi for r in this_week):.1f}mi")
    lines.append("Recent:")
    for run in runs[:5]:
        lines.append(f"  {run.to_compact()}")
    return "\n".join(lines)
```

### 4.3 Implement Workout Type Inference

**File:** `server/tiered_context.py`

Add `infer_workout_from_context()` function.

### 4.4 Add Query Tools

**File:** `server/tools.py`

Add `query_cardio` and `query_cross_modality` tool schemas.

---

## Phase 5: Simplified Set Tracker (Week 7)

### 5.1 Create ManualSetEntry Model

**File:** `AirFit/Models/ManualSetEntry.swift` (NEW)

```swift
@Model
class ManualSetEntry {
    var id: UUID
    var date: Date
    var muscleGroup: String  // "chest", "back", "legs", etc.
    var setCount: Int

    init(muscleGroup: String, date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.muscleGroup = muscleGroup
        self.setCount = 1
    }
}
```

### 5.2 Build ManualSetTrackerView

**File:** `AirFit/Views/Components/ManualSetTrackerView.swift` (NEW)

```swift
struct ManualSetTrackerView: View {
    @Query private var entries: [ManualSetEntry]
    @Environment(\.modelContext) private var modelContext

    let muscleGroups = ["Chest", "Back", "Shoulders", "Legs", "Arms", "Core"]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(muscleGroups, id: \.self) { muscle in
                HStack {
                    Text(muscle)
                        .font(.subheadline)

                    Spacer()

                    // Progress bar
                    ProgressBar(current: setsFor(muscle), target: 12)
                        .frame(width: 100)

                    Text("\(setsFor(muscle))/12")
                        .font(.caption)
                        .monospacedDigit()

                    // Stepper buttons
                    Button { decrement(muscle) } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .disabled(setsFor(muscle) == 0)

                    Button { increment(muscle) } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }

    func setsFor(_ muscle: String) -> Int {
        entries
            .filter { $0.muscleGroup == muscle && Calendar.current.isDateInThisWeek($0.date) }
            .reduce(0) { $0 + $1.setCount }
    }

    func increment(_ muscle: String) {
        let entry = ManualSetEntry(muscleGroup: muscle)
        modelContext.insert(entry)
    }

    func decrement(_ muscle: String) {
        guard let latest = entries
            .filter({ $0.muscleGroup == muscle })
            .sorted(by: { $0.date > $1.date })
            .first else { return }
        modelContext.delete(latest)
    }
}
```

### 5.3 Integrate as Fallback

**File:** `AirFit/Views/DashboardView.swift`

```swift
@AppStorage("isHevyConfigured") private var isHevyConfigured = false

var setTrackerSection: some View {
    Group {
        if isHevyConfigured {
            // Existing Hevy-powered set tracker
            HevySetTrackerSection()
        } else {
            // Manual fallback
            ManualSetTrackerView()
        }
    }
}
```

### 5.4 Sync to Server

Add endpoint to receive manual set data and store in context_store.

---

## File Summary

### New iOS Files

| File | Phase |
|------|-------|
| `AirFit/Models/RunningWorkout.swift` | 2 |
| `AirFit/Models/ManualSetEntry.swift` | 5 |
| `AirFit/Views/RunningDetailView.swift` | 2 |
| `AirFit/Views/Components/RouteMapView.swift` | 2 |
| `AirFit/Views/Components/RouteGlyph.swift` | 2 |
| `AirFit/Views/Components/UnifiedActivityStream.swift` | 3 |
| `AirFit/Views/Components/ActivityCard.swift` | 3 |
| `AirFit/Views/Components/ManualSetTrackerView.swift` | 5 |

### Modified iOS Files

| File | Phase |
|------|-------|
| `AirFit/Services/HealthKitManager.swift` | 1 |
| `AirFit/Views/DashboardView.swift` | 2, 3, 5 |
| `AirFit/Views/Theme.swift` | 3 |

### New Server Files

| File | Phase |
|------|-------|
| `server/workout_notation.py` | 1 |

### Modified Server Files

| File | Phase |
|------|-------|
| `server/context_store.py` | 1 |
| `server/tiered_context.py` | 1, 4 |
| `server/insight_engine.py` | 4 |
| `server/chat_context.py` | 4 |
| `server/tools.py` | 4 |
