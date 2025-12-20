# Running Deep Dive

> Running-specific features, metrics, and implementation details

## The MAF Hierarchy of Running Metrics

Based on endurance coaching consultation (Phil Maffetone × Greg McMillan perspective):

### Tier 1: Aerobic Development (Foundation)

These are the metrics that matter most for recreational runners:

| Metric | Why It Matters | Source |
|--------|---------------|--------|
| **HR Zone Time** | Time in Zone 2 (MAF = 180-age) predicts long-term improvement better than pace | Calculate from HR samples |
| **Cardiac Drift** | HR increase over steady-state effort. <5% drift = excellent aerobic base | Compare first vs. last 10 min of runs >30 min |
| **HR Recovery** | How fast HR drops after stopping. 20+ BPM in 60 seconds = good fitness | Already in HealthKit: `heartRateRecoveryOneMinute` |

### Tier 2: Efficiency Metrics

| Metric | Why It Matters | Source | Optimal Range |
|--------|---------------|--------|---------------|
| **Cadence** | Higher cadence usually means better form | Derive from stride length + speed | 170-180 spm |
| **Vertical Oscillation** | Lower = more efficient (less energy wasted bouncing) | `runningVerticalOscillation` | 6-8 cm |
| **Ground Contact Time** | Shorter for faster, more efficient runners | `runningGroundContactTime` | 200-250 ms |
| **Running Power** | Work output independent of terrain/wind | `runningPower` (if device supports) | Varies |

### Tier 3: Load Management

| Metric | Formula | Safe Range |
|--------|---------|------------|
| **Acute:Chronic Workload Ratio (ACWR)** | 7-day avg / 28-day avg | 0.8 - 1.3 |
| **Training Stress Score (TSS)** | Duration × Intensity² × 100 | Varies by fitness |
| **Monotony** | Weekly avg / std deviation | Lower = more variety |

---

## Route Visualization Strategy

### Three Levels of Map Display

#### Level 1: Card View (Activity Stream)
- **No full map** - too heavy for lists
- Show mini route "glyph" - the shape reduced to ~24×24pt
- Just distance + pace + duration text

```swift
struct RunningCardView: View {
    let run: RunningWorkout

    var body: some View {
        HStack {
            // Mini route shape
            RouteGlyph(coordinates: run.routeCoordinates)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading) {
                Text(run.title)
                    .font(.headline)
                Text("\(run.distanceMiles, format: .number.precision(.fractionLength(1))) mi • \(run.averagePace)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(run.date, format: .relative(presentation: .named))
                .font(.caption)
        }
    }
}
```

#### Level 2: Detail Sheet (Tap Run Card)
- Route map at ~40% of screen height
- Below map: hero metrics, splits, charts
- Map is interactive but not the star

```swift
struct RunningDetailView: View {
    let run: RunningWorkout
    @State private var selectedMetric: RunMetric = .pace

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Route map (40% height)
                RouteMapView(coordinates: run.routeCoordinates)
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                // Hero metrics
                HStack {
                    StatTile(label: "Distance", value: "\(run.distanceMiles) mi")
                    StatTile(label: "Avg Pace", value: run.averagePace)
                    StatTile(label: "Elevation", value: "+\(run.elevationGain) ft")
                }

                // Metric selector
                Picker("Metric", selection: $selectedMetric) {
                    Text("Pace").tag(RunMetric.pace)
                    Text("HR").tag(RunMetric.heartRate)
                    Text("Cadence").tag(RunMetric.cadence)
                }
                .pickerStyle(.segmented)

                // Chart (reuse InteractiveChartView)
                InteractiveChartView(
                    data: chartData(for: selectedMetric),
                    color: Theme.running,
                    unit: selectedMetric.unit
                )

                // Splits table
                SplitsTableView(splits: run.splits)

                // HR Zone breakdown
                HRZoneBar(zones: run.hrZones)
            }
            .padding()
        }
    }
}
```

#### Level 3: Full-Screen Map (Tap the Map)
- Immersive route exploration
- Color-coded by pace or HR
- Mile markers, start/end pins
- Photo pins (if user took photos during run)

```swift
struct FullRouteMapView: View {
    let run: RunningWorkout
    @State private var colorMode: RouteColorMode = .pace

    var body: some View {
        ZStack {
            Map {
                // Route polyline colored by metric
                MapPolyline(coordinates: run.routeCoordinates)
                    .stroke(gradientFor(colorMode), lineWidth: 4)

                // Start pin
                Marker("Start", coordinate: run.startCoordinate)
                    .tint(.green)

                // End pin
                Marker("Finish", coordinate: run.endCoordinate)
                    .tint(.red)

                // Mile markers
                ForEach(run.mileMarkers) { marker in
                    Annotation("Mile \(marker.mile)", coordinate: marker.coordinate) {
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .overlay(Text("\(marker.mile)").font(.caption2.bold()))
                    }
                }
            }

            // Color mode selector overlay
            VStack {
                Spacer()
                Picker("Color by", selection: $colorMode) {
                    Text("Pace").tag(RouteColorMode.pace)
                    Text("Heart Rate").tag(RouteColorMode.heartRate)
                    Text("Elevation").tag(RouteColorMode.elevation)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}
```

---

## Data Models

### RunningWorkout (SwiftData)

```swift
@Model
class RunningWorkout {
    var id: String
    var title: String
    var workoutDate: Date
    var durationMinutes: Int

    // Core metrics
    var distanceMeters: Double
    var averagePaceSecondsPerKm: Double
    var elevationGainMeters: Double

    // Optional rich data
    var routeCoordinates: [Coordinate]?  // Cached from HealthKit
    var splits: [Split]?
    var hrZones: HRZoneBreakdown?

    // Efficiency metrics
    var avgCadence: Int?
    var avgGroundContactMs: Int?
    var avgVerticalOscillationCm: Double?

    // Computed
    var distanceMiles: Double { distanceMeters / 1609.34 }
    var averagePace: String {
        let pacePerMile = averagePaceSecondsPerKm * 1.60934
        let minutes = Int(pacePerMile) / 60
        let seconds = Int(pacePerMile) % 60
        return String(format: "%d:%02d /mi", minutes, seconds)
    }
}

struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let speed: Double?
    let timestamp: Date
}

struct Split: Codable {
    let mile: Int
    let timeSeconds: Int
    let avgHR: Int?
    let elevationChange: Double?
}

struct HRZoneBreakdown: Codable {
    let zone1Minutes: Int  // <60% max
    let zone2Minutes: Int  // 60-70%
    let zone3Minutes: Int  // 70-80%
    let zone4Minutes: Int  // 80-90%
    let zone5Minutes: Int  // >90%
}
```

### Compact Notation for AI Context

```
R:45m|6.2mi|9:42/mi|Z2:32m,Z3:8m|+420ft|hr156avg
│  │    │      │      │          │      └── Average heart rate
│  │    │      │      │          └── Elevation gain
│  │    │      │      └── Time in HR zones
│  │    │      └── Average pace
│  │    └── Distance
│  └── Duration
└── Type: R=Run
```

---

## Progression Markers for Recreational Runners

These are more meaningful than pace PRs:

### 1. Aerobic Decoupling Trend
"Are you drifting less at the same HR over weeks?"

```python
def calculate_decoupling(run):
    first_half_hr = avg(hr_samples[:len/2])
    second_half_hr = avg(hr_samples[len/2:])
    return (second_half_hr - first_half_hr) / first_half_hr * 100

# <5% = excellent, 5-10% = good, >10% = needs work
```

### 2. Pace at MAF HR
"Getting faster at 180-age HR means real aerobic development"

Track: What was your average pace when HR was in Zone 2?
- Week 1: 10:30 /mi at 140 bpm
- Week 4: 10:00 /mi at 140 bpm
- Week 8: 9:30 /mi at 140 bpm

### 3. Consistent Volume Without Breakdown
"4 weeks at target weekly mileage without injury = milestone"

Track weekly mileage, flag when user maintains target for 4+ weeks.

### 4. HRV Trend
"Rising baseline HRV = improved recovery capacity"

Already captured, surface in running context.

---

## Cross-Training Correlations

What the AI should look for when user does both strength and running:

### Interference Patterns
```
IF workout(type=legs, RPE>7) yesterday
AND run today
THEN check:
  - Cardiac drift increase?
  - Pace slower at same HR?
  - Ground contact time longer?
```

### Recovery Signals
```
IF HRV < 10-day average by >15%
AND run scheduled
THEN suggest:
  - "HRV is low. Consider an easy Zone 2 run or rest day."
```

### Synergy Patterns
```
CORRELATE:
  - Days with morning yoga -> same-day run performance
  - Weekly strength volume -> running efficiency trends
  - Sleep quality -> next-day run metrics
```

---

## Stickiness Features (What Works in Other Apps)

Based on analysis of Strava, Garmin, Nike Run Club:

### Copy These
1. **Relative Effort Score** - Normalizes all activities to comparable load
2. **Segment History** - "You've run this route 12 times. Today was your 3rd fastest."
3. **Personal Records Board** - Fastest 5K, longest run, biggest week, etc.
4. **Training Load Visualization** - See when you're in the zone vs. overreaching

### Avoid These
1. Too many badges (gamification fatigue)
2. Pace obsession (leads to overtraining)
3. Comparison-heavy features ("You're slower than 80% of runners")
4. Complex metrics without explanation

---

## Implementation Checklist

### Phase 1: Data Layer
- [ ] Add `fetchWorkoutRoute()` to HealthKitManager
- [ ] Add `fetchHeartRateSamples()` to HealthKitManager
- [ ] Create `RunningWorkout` SwiftData model
- [ ] Create `HRZoneBreakdown` calculation function
- [ ] Add running compact notation to server

### Phase 2: UI Layer
- [ ] Create `RouteGlyph` component (mini route shape)
- [ ] Create `RouteMapView` component (MapKit integration)
- [ ] Create `RunningDetailView` (full detail screen)
- [ ] Create `SplitsTableView` component
- [ ] Create `HRZoneBar` component
- [ ] Add running section to Dashboard

### Phase 3: Context Layer
- [ ] Add running topic detection in tiered_context.py
- [ ] Add running context builder in chat_context.py
- [ ] Add cross-modality prompts in insight_engine.py

### Phase 4: Polish
- [ ] Route caching strategy
- [ ] Thumbnail generation for cards
- [ ] Performance optimization for long routes
