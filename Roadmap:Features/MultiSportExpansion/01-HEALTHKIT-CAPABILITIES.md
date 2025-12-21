# HealthKit Capabilities

> What data Apple HealthKit provides and what AirFit currently uses

## Currently Fetched by AirFit

Based on analysis of `AirFit/Services/HealthKitManager.swift`:

### Workout Data
- Basic workout summaries: type, date, duration, calories burned
- Up to 10 recent workouts (7-day window)
- Classification as "strength training" or other types

### Activity & Movement
| Metric | HealthKit Identifier | Notes |
|--------|---------------------|-------|
| Step count | `stepCount` | Daily totals |
| Distance | `distanceWalkingRunning`, `distanceCycling`, `distanceSwimming` | By activity type |
| Flights climbed | `flightsClimbed` | |
| Exercise time | `appleExerciseTime` | |
| Move time | `appleMoveTime` | |
| Stand time | `appleStandTime` | |

### Energy
| Metric | HealthKit Identifier |
|--------|---------------------|
| Active energy | `activeEnergyBurned` |
| Basal energy | `basalEnergyBurned` |

### Body Composition
| Metric | HealthKit Identifier |
|--------|---------------------|
| Weight | `bodyMass` |
| Body fat % | `bodyFatPercentage` |
| Lean body mass | `leanBodyMass` |
| Height | `height` |

### Cardiac Metrics
| Metric | HealthKit Identifier | Notes |
|--------|---------------------|-------|
| Heart rate | `heartRate` | |
| Resting HR | `restingHeartRate` | |
| Walking HR avg | `walkingHeartRateAverage` | |
| HRV (SDNN) | `heartRateVariabilitySDNN` | Key recovery metric |
| HR recovery | `heartRateRecoveryOneMinute` | 20+ bpm drop = good fitness |
| VO2 Max | `vo2Max` | |
| SpO2 | `oxygenSaturation` | |

### Running Metrics (Already Read!)
| Metric | HealthKit Identifier | Notes |
|--------|---------------------|-------|
| Running speed | `runningSpeed` | |
| Stride length | `runningStrideLength` | |
| Vertical oscillation | `runningVerticalOscillation` | Lower = more efficient |
| Ground contact time | `runningGroundContactTime` | 200-250ms typical |

### Cycling Metrics (Already Read!)
| Metric | HealthKit Identifier |
|--------|---------------------|
| Cycling cadence | `cyclingCadence` |
| Cycling speed | `cyclingSpeed` |

### Sleep Analysis
- Full stage breakdown: REM, deep, core, awake, in-bed
- Accessed via `HKCategoryTypeIdentifier.sleepAnalysis`

---

## Available but NOT Currently Fetched

### GPS Route Data (`HKWorkoutRoute`)

**The big opportunity for running/cycling features.**

```swift
// What's possible
HKWorkoutRouteQuery(route: workoutRoute) { query, routeData, done, error in
    // routeData is [CLLocation] - full GPS trail
    // Each CLLocation has: latitude, longitude, altitude, speed, timestamp
}
```

**Requirements:**
- Separate `HKWorkoutRouteType` permission (in addition to workout permission)
- Core Location permission for GPS access
- Data loaded asynchronously in batches (can be thousands of points)

**Use cases:**
- Running/cycling route maps with MapKit overlay
- Pace-by-segment visualization
- Elevation profile charts
- Favorite routes recognition

### Workout Metadata

Available via `HKWorkout.metadata` dictionary:

| Key | Data | Use Case |
|-----|------|----------|
| `HKMetadataKeyElevationAscended` | Feet/meters gained | Running/cycling elevation |
| `HKMetadataKeyElevationDescended` | Feet/meters lost | Downhill analysis |
| `HKMetadataKeyWeatherTemperature` | Degrees | Context for performance |
| `HKMetadataKeyWeatherCondition` | Enum | Context for performance |
| `HKMetadataKeyWeatherHumidity` | Percentage | Context for performance |
| `HKMetadataKeyAverageSpeed` | Speed | Overall pace |
| `HKMetadataKeyMaximumSpeed` | Speed | Sprint detection |

### Workout Events

Available via `HKWorkout.workoutEvents`:

| Event Type | Use Case |
|------------|----------|
| `.lap` | Auto-detected laps (especially swimming) |
| `.pause` / `.resume` | Rest interval detection |
| `.marker` | Custom user markers |
| `.segment` | Multi-activity segments (triathlon) |

### Heart Rate Samples During Workouts

Currently we read aggregate HR. For zone analysis, we'd need:

```swift
// Query HR samples for a specific workout's time range
let predicate = HKQuery.predicateForSamples(
    withStart: workout.startDate,
    end: workout.endDate
)
// Returns individual HR readings, typically every 5-10 seconds
```

**Use cases:**
- Heart rate zone time calculation
- Cardiac drift analysis
- Zone-based training feedback

### Swimming-Specific Data

| Metric | Access Method | Notes |
|--------|---------------|-------|
| Stroke count | `HKQuantityType.swimmingStrokeCount` | Per-lap or total |
| Stroke type | Workout event metadata | Freestyle, backstroke, etc. |
| Lap times | `HKWorkoutEvent` with `.lap` type | Auto-detected |
| SWOLF | Calculate: strokes + time | Efficiency score |
| Pool length | Workout configuration | User-set or detected |

---

## Workout Types Available

HealthKit supports 80+ workout activity types. Key ones for AirFit:

### Primary (High-Value Data)
| Type | Code | Notes |
|------|------|-------|
| Running | `.running` | Rich: GPS, pace, cadence, efficiency |
| Cycling | `.cycling` | Rich: GPS, speed, cadence, power (if meter) |
| Swimming | `.swimming` | Rich: laps, strokes, SWOLF |
| Traditional Strength | `.traditionalStrengthTraining` | Current Hevy focus |
| Functional Strength | `.functionalStrengthTraining` | CrossFit-style |
| HIIT | `.highIntensityIntervalTraining` | Duration, HR zones |
| Yoga | `.yoga` | Duration, HR (minimal metrics) |

### Secondary (Basic Metrics)
| Type | Code |
|------|------|
| Walking | `.walking` |
| Hiking | `.hiking` |
| Elliptical | `.elliptical` |
| Rowing | `.rowing` |
| Stair climbing | `.stairClimbing` |
| Pilates | `.pilates` |
| Dance | `.dance` |
| Core training | `.coreTraining` |

### Multi-Activity (iOS 16+)
| Type | Code | Notes |
|------|------|-------|
| Triathlon | `.swimBikeRun` | Contains sub-activities |
| Transition | `.transition` | Between segments |

---

## Permission Requirements

### Current Permissions (Already Requested)
- `HKWorkoutType.workoutType()` - Basic workout access
- Individual quantity types (steps, HR, etc.)
- Sleep analysis
- Nutrition write access

### Additional Permissions Needed

For full running/cycling features:

```swift
// Add to HealthKitManager authorization
let additionalTypes: Set<HKObjectType> = [
    HKSeriesType.workoutRoute(),  // GPS routes
    HKQuantityType.workoutType(), // Already have this
]
```

**Also requires:**
- `NSLocationWhenInUseUsageDescription` in Info.plist (for route display)
- User consent for location access

---

## Data Volume Considerations

### GPS Route Data
- **Typical run**: 500-2000 GPS points (1 point per 1-3 seconds)
- **Long ride**: 5000-20000 points
- **Performance**: Must load asynchronously, consider caching

### Heart Rate Samples
- **Typical workout**: 100-500 samples (every 5-10 seconds)
- **Processing**: Calculate zones client-side, cache results

### Recommendation
Cache processed workout data (routes, zone times) in SwiftData to avoid re-querying HealthKit on every view.

---

## Quick Wins (Low Effort, High Value)

1. **Elevation data** - Already in workout metadata, just extract and display
2. **Weather context** - Temperature/humidity from metadata for AI context
3. **Workout events** - Pause/resume patterns for rest interval insights
4. **Average/max speed** - Already in metadata, surface in UI

## Medium Effort

1. **HR zone calculation** - Query samples, bucket by zone, cache result
2. **Swimming lap data** - Parse workout events for stroke/lap breakdown
3. **Route thumbnails** - Generate mini-map images for cards

## High Effort (High Value)

1. **Full route visualization** - MapKit integration with overlays
2. **Multi-activity support** - Handle triathlon/brick workouts
3. **Cross-workout correlation** - Feed to insight engine
