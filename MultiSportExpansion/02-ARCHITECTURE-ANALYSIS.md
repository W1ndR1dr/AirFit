# Architecture Analysis

> Current system design and integration points for multi-sport expansion

## Current Workout Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                          iOS APP                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  HealthKitManager ◄──── Apple Watch / Health App                │
│        │                                                         │
│        │ (workouts, metrics,                                     │
│        │  body composition)                                      │
│        ▼                                                         │
│  ┌─────────────┐     ┌──────────────────┐                       │
│  │ HevyService │────►│ HevyCacheManager │                       │
│  └─────────────┘     └──────────────────┘                       │
│        │                      │                                  │
│        │ (device-first        │ (SwiftData cache)               │
│        │  API calls)          │                                  │
│        ▼                      ▼                                  │
│  ┌────────────────────────────────────────┐                     │
│  │           AutoSyncManager               │                     │
│  │  (coordinates sync on app launch)       │                     │
│  └────────────────────────────────────────┘                     │
│                       │                                          │
└───────────────────────┼──────────────────────────────────────────┘
                        │ HTTP
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                       PYTHON SERVER                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  server.py (FastAPI)                                            │
│        │                                                         │
│        ├──► hevy.py ──────────────────┐                         │
│        │    (Hevy API integration)     │                         │
│        │                               ▼                         │
│        │                        ┌──────────────┐                │
│        │                        │context_store │                │
│        │                        │   .py        │                │
│        │                        │(JSON storage)│                │
│        │                        └──────────────┘                │
│        │                               │                         │
│        ├──► tiered_context.py ◄────────┤                        │
│        │    (topic detection)          │                         │
│        │                               │                         │
│        ├──► chat_context.py ◄──────────┘                        │
│        │    (builds LLM context)                                │
│        │                                                         │
│        ▼                                                         │
│  ┌──────────────┐                                               │
│  │ llm_router.py│──────► Claude CLI / Gemini CLI                │
│  └──────────────┘                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Current Data Structures

### WorkoutSnapshot (server/context_store.py)

**Problem**: Currently strength-training specific.

```python
@dataclass
class WorkoutSnapshot:
    workout_count: int
    total_duration_minutes: int
    total_volume_kg: float  # Strength-specific!
    exercises: list[dict]   # [{name, sets, total_reps, max_weight_kg}]
    workout_titles: list[str]
```

**Missing for cardio:**
- `workout_type` field
- `distance_km` / `distance_miles`
- `pace_min_per_km`
- `avg_hr` / `hr_zones`
- `elevation_m`
- `route_data` (or reference to cached route)

### HevyWorkout (iOS: HevyService.swift)

```swift
struct HevyWorkout: Codable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let exercises: [HevyExercise]

    var durationMinutes: Int
    var totalVolumeKg: Double
    var totalVolumeLbs: Double
}
```

### CachedWorkout (iOS: HevyCacheManager.swift)

```swift
@Model
class CachedWorkout {
    var id: String
    var title: String
    var workoutDate: Date
    var durationMinutes: Int
    var totalVolumeLbs: Double
    var exercises: [String]
    var syncedAt: Date
}
```

---

## Integration Points for Multi-Sport

### 1. HealthKitManager.swift

**Current**: Reads basic workout info, doesn't fetch routes or per-workout HR.

**Needed**:
```swift
// New methods to add
func fetchWorkoutRoute(for workout: HKWorkout) async throws -> [CLLocation]
func fetchHeartRateSamples(during workout: HKWorkout) async throws -> [HRSample]
func calculateHRZones(samples: [HRSample], maxHR: Int) -> HRZoneBreakdown
func fetchRecentWorkouts(ofType: HKWorkoutActivityType, days: Int) async throws -> [HKWorkout]
```

### 2. HevyService.swift → WorkoutProvider Protocol

**Current**: Tightly coupled to Hevy API.

**Proposed abstraction**:
```swift
protocol WorkoutProvider {
    associatedtype WorkoutType

    func fetchRecentWorkouts(days: Int) async throws -> [WorkoutType]
    func getWorkoutDetails(id: String) async throws -> WorkoutType
    func syncToServer() async throws
}

// Implementations
class HevyWorkoutProvider: WorkoutProvider { ... }
class HealthKitCardioProvider: WorkoutProvider { ... }  // NEW
```

### 3. context_store.py

**Current**: Single `WorkoutSnapshot` structure.

**Proposed**: Extended dataclass with type discrimination.

```python
@dataclass
class WorkoutSnapshot:
    workout_type: str  # "strength", "run", "cycle", "swim", "yoga"

    # Universal fields
    duration_minutes: int
    start_time: str
    title: str

    # Strength-specific (optional)
    volume_kg: Optional[float] = None
    exercises: Optional[list[dict]] = None

    # Cardio-specific (optional)
    distance_km: Optional[float] = None
    pace_min_per_km: Optional[float] = None
    avg_hr: Optional[int] = None
    hr_zone_minutes: Optional[dict[str, int]] = None
    elevation_m: Optional[float] = None

    # Computed
    training_load: Optional[float] = None  # Normalized 0-100
```

### 4. tiered_context.py

**Current**: Topic patterns for training, nutrition, recovery, etc.

**Needed**: Add cardio and cross-training patterns.

```python
TOPIC_PATTERNS = {
    # ... existing ...

    "cardio": {
        "keywords": [
            "run", "running", "jog", "bike", "cycling", "ride",
            "swim", "swimming", "pool", "pace", "miles", "km",
            "hr", "heart rate", "zone", "tempo", "interval", "fartlek"
        ],
        "patterns": [
            r"how.*(run|ride|swim)",
            r"(my|the|a|last).*(run|ride|swim|race)",
            r"\d+\s*(mi|km|miles|kilometers)",
            r"(pace|split|time).*(run|race)",
            r"(z[1-5]|zone\s*\d)",
        ]
    },

    "cross_training": {
        "keywords": [
            "brick", "triathlon", "balance", "interference"
        ],
        "patterns": [
            r"(run|ride|swim).*(after|before).*(lift|workout|legs)",
            r"does.*(affect|help|hurt)",
        ]
    }
}
```

### 5. insight_engine.py

**Current**: Looks for patterns in strength data.

**Needed**: Cross-modality correlation prompts.

```python
CROSS_MODALITY_PROMPT = """
Analyze this athlete's multi-sport training data for patterns:

1. SEQUENCING EFFECTS
   - Do heavy leg days affect running performance the next day?
   - Does yoga/mobility correlate with fewer issues?

2. INTERFERENCE PATTERNS
   - High running volume vs. lower body strength gains
   - Competing adaptations

3. SYNERGY PATTERNS
   - Zone 2 cardio volume vs. recovery metrics
   - Cross-training benefits

4. RECOVERY OPTIMIZATION
   - Which activity combinations lead to better sleep?
   - HRV patterns after different training loads
"""
```

### 6. DashboardView.swift

**Current**: Body/Training segmented view, Training shows Hevy data.

**Needed**: Unified activity stream that handles all workout types.

```swift
// In TrainingContentView
struct TrainingContentView: View {
    @State private var activityFilter: ActivityType = .all

    enum ActivityType: CaseIterable {
        case all, strength, running, cycling, swimming, yoga
    }

    var body: some View {
        VStack {
            // Activity type picker
            HStack {
                ForEach(ActivityType.allCases, id: \.self) { type in
                    FilterChip(type: type, selected: activityFilter == type) {
                        activityFilter = type
                    }
                }
            }

            // Unified activity stream
            ForEach(filteredActivities) { activity in
                ActivityCard(activity: activity)
                    .onTapGesture {
                        // Navigate to type-specific detail view
                        navigateToDetail(for: activity)
                    }
            }
        }
    }
}
```

---

## Key Architectural Decisions

### 1. Device-First for Cardio

HealthKit data lives on device. No need to sync to server unless:
- Generating insights (server can request via API)
- Building chat context (send summary, not raw data)

**Recommendation**: HealthKit workouts stay on iOS, synced to server as daily aggregates only.

### 2. Unified vs. Separate Views

**Options**:
- A: One `WorkoutDetailView` that adapts to type
- B: Separate views per type (`RunningDetailView`, `CyclingDetailView`, etc.)

**Recommendation**: Option B. Each modality has unique metrics and visualizations. A single view would become a mess of conditionals.

### 3. Route Data Storage

**Options**:
- A: Cache full GPS routes in SwiftData
- B: Generate route images and cache those
- C: Load routes on-demand from HealthKit

**Recommendation**: Hybrid. Cache route geometry for frequently-accessed runs, generate thumbnails for cards, load full detail on-demand.

### 4. HR Zone Calculation

**Options**:
- A: Calculate zones on device, send to server
- B: Send raw HR samples to server
- C: Store pre-calculated zones in HealthKit

**Recommendation**: Option A. HR samples are large; zone breakdown is small. Calculate once, cache in SwiftData.

---

## File Change Map

### iOS Files to Modify

| File | Changes |
|------|---------|
| `HealthKitManager.swift` | Add route/HR queries, zone calculation |
| `DashboardView.swift` | Unified activity stream |
| `TrainingView.swift` | Running section (or merge into Dashboard) |
| `Theme.swift` | Activity type colors |

### iOS Files to Create

| File | Purpose |
|------|---------|
| `RunningDetailView.swift` | Running workout drill-down |
| `RouteMapView.swift` | MapKit with workout route overlay |
| `WorkoutProvider.swift` | Protocol for multiple data sources |
| `HealthKitCardioProvider.swift` | Cardio workout provider |
| `CachedRunningWorkout.swift` | SwiftData model for runs |
| `ManualSetEntry.swift` | SwiftData model for manual sets |

### Server Files to Modify

| File | Changes |
|------|---------|
| `context_store.py` | Extended WorkoutSnapshot |
| `tiered_context.py` | Cardio topic detection |
| `insight_engine.py` | Cross-modality prompts |
| `chat_context.py` | Cardio context building |

### Server Files to Create

| File | Purpose |
|------|---------|
| `workout_notation.py` | Compact formatters for all types |
| `cardio_provider.py` | (Optional) If server needs to query external cardio APIs |

---

## API Endpoint Changes

### Existing Endpoints (No Change)
- `GET /hevy/set-tracker`
- `GET /hevy/lift-progress`
- `GET /hevy/recent-workouts`
- `POST /insights/sync-hevy`

### New Endpoints Needed

| Endpoint | Purpose |
|----------|---------|
| `POST /workouts/sync-cardio` | Receive cardio data from iOS |
| `GET /workouts/unified?days=7` | All workout types |
| `GET /insights/cross-modality` | Multi-sport pattern analysis |

### Context Endpoint Updates

The `/chat` endpoint's context injection needs to include:
- Cardio summary when relevant topic detected
- Cross-modality patterns when user asks about training balance
- Most recent workout regardless of type

---

## Migration Strategy

### Phase 1: Non-Breaking Changes
1. Add new fields to WorkoutSnapshot with defaults
2. Add cardio topic detection (doesn't break existing)
3. Add new iOS models (parallel to existing)

### Phase 2: UI Integration
1. Build running views (new, doesn't break existing)
2. Add unified stream (can coexist with current Training)
3. Add activity type filter

### Phase 3: Unification
1. Refactor Training tab to unified view
2. Implicit personalization based on usage
3. Graceful degradation for cardio-only users
