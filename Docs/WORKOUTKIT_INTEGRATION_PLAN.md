# WorkoutKit & HealthKit Workout Integration Plan

## Executive Summary
Currently, AirFit stores workout data only in SwiftData, missing critical integration with Apple's fitness ecosystem. This plan outlines comprehensive integration with HealthKit for basic workout storage and WorkoutKit (iOS 16+) for advanced workout tracking features, while cleaning up conflicting code.

## Current State Analysis

### What's Working
- ✅ Basic HealthKit workout reading (`getWorkoutData` in HealthKitManager.swift:252-292)
- ✅ Workout model has `healthKitWorkoutID` field (Workout.swift:19) - but never populated
- ✅ WatchWorkoutManager uses HKWorkoutSession (WatchWorkoutManager.swift)
- ✅ WorkoutSyncService for Watch→iPhone sync (WorkoutSyncService.swift)
- ✅ SwiftData models properly store workout data

### What's Missing
- ❌ **No HealthKit write capabilities** - HealthKitManager is read-only
- ❌ **No WorkoutKit integration** - Missing iOS 16+ advanced features
- ❌ **Incomplete sync** - `healthKitWorkoutID` exists but never used
- ❌ **No exercise details in HealthKit** - Sets/reps not synced as HKWorkoutActivity
- ❌ **Watch sync doesn't write to HealthKit** - Only syncs to SwiftData/CloudKit
- ❌ **No Activity Ring contribution** - Workouts don't update Move/Exercise rings

### Critical Findings
1. **HealthKitManager is Read-Only**: Like nutrition, it only reads workouts, cannot write
2. **WorkoutSyncService Bypasses HealthKit**: Syncs Watch→iPhone→CloudKit but not HealthKit (lines 35-60)
3. **Unused HealthKit Fields**: `healthKitWorkoutID` and `healthKitSyncedDate` in Workout model never populated
4. **Watch Already Uses HKWorkoutSession**: Good foundation, but doesn't save to HealthKit properly

## Code to Clean Up

### 1. WorkoutSyncService.swift (lines 35-60)
**Current**: Syncs to CloudKit, bypassing HealthKit
```swift
// REMOVE: Direct CloudKit sync
func sendWorkoutData(_ data: WorkoutBuilderData) async {
    // ... CloudKit sync code
}
```
**Replace with**: HealthKit-first approach that syncs to both

### 2. WorkoutService.swift (lines 70-87)
**Current**: Only saves to SwiftData
```swift
func endWorkout(_ workout: Workout) async throws {
    workout.completeWorkout()
    // Only saves to SwiftData, no HealthKit
}
```
**Replace with**: Dual save to SwiftData + HealthKit

### 3. Duplicate/Unused Code
- Remove CloudKit sync from WorkoutSyncService (lines 63-80) - use HealthKit as source of truth
- Remove manual calorie calculation (WorkoutService.swift:77) - use HealthKit's calculations
- Clean up unused `healthKitWorkoutID` references if not implementing proper sync

## Benefits of Integration

### User Value
1. **Apple Fitness Integration**
   - Workouts appear in Fitness app
   - Contribute to Activity rings (Move, Exercise, Stand)
   - Show in fitness trends and awards
   - Sync across all Apple devices

2. **WorkoutKit Features** (iOS 16+)
   - Live workout metrics on iPhone during Watch workouts
   - Workout routes with GPS tracking
   - Heart rate zones and training load
   - Detailed exercise breakdowns
   - Mirroring workouts to paired devices

3. **Rich Data Capture**
   - Individual set/rep tracking in HealthKit
   - Exercise-specific metrics
   - Rest periods and workout segments
   - Performance trends over time

## Implementation Plan

### Phase 1: Basic HealthKit Workout Writing

#### 1.1 Update HealthKitDataTypes.swift
```swift
// Already has workout write permission (line 92)
// No changes needed
```

#### 1.2 Add Write Methods to HealthKitManager.swift
**Location**: After line 292, add:
```swift
// MARK: - Workout Writing
func saveWorkout(
    _ workout: Workout,
    metadata: [String: Any]? = nil
) async throws -> String {
    guard let workoutType = workout.workoutTypeEnum else {
        throw HealthKitError.invalidData
    }
    
    let hkWorkoutType = HKWorkoutActivityType(from: workoutType)
    let startDate = workout.plannedDate ?? Date()
    let endDate = workout.completedDate ?? Date()
    
    // Energy burned
    var totalEnergy: HKQuantity?
    if let calories = workout.caloriesBurned {
        totalEnergy = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
    }
    
    // Build workout
    let hkWorkout = HKWorkout(
        activityType: hkWorkoutType,
        start: startDate,
        end: endDate,
        duration: workout.duration ?? 0,
        totalEnergyBurned: totalEnergy,
        totalDistance: nil, // TODO: Add distance tracking
        metadata: metadata
    )
    
    try await healthStore.save(hkWorkout)
    return hkWorkout.uuid.uuidString
}

func deleteWorkout(healthKitID: String) async throws {
    // Implementation for deleting synced workouts
}
```

#### 1.3 Update WorkoutService.swift
**Modify** `endWorkout` method (line 70):
```swift
func endWorkout(_ workout: Workout) async throws {
    workout.completeWorkout()
    
    // Calculate calories if not set
    if workout.caloriesBurned == nil {
        workout.caloriesBurned = calculateEstimatedCalories(for: workout)
    }
    
    // Save to SwiftData first
    try modelContext.save()
    
    // Save to HealthKit (new)
    if workout.healthKitWorkoutID == nil {
        do {
            let healthKitID = try await HealthKitManager.shared.saveWorkout(workout)
            workout.healthKitWorkoutID = healthKitID
            workout.healthKitSyncedDate = Date()
            try modelContext.save()
        } catch {
            AppLogger.error("Failed to sync workout to HealthKit", error: error)
            // Don't throw - HealthKit sync is secondary
        }
    }
}
```

### Phase 2: WorkoutKit Integration (iOS 16+)

#### 2.1 Create WorkoutKitManager.swift
**New file**: `Services/Health/WorkoutKitManager.swift`
```swift
import WorkoutKit
import HealthKit

@available(iOS 17.0, watchOS 10.0, *)
actor WorkoutKitManager {
    private let workoutStore = WorkoutStore()
    
    // Create workout plan
    func createWorkoutPlan(from template: WorkoutTemplate) async throws -> WorkoutPlan {
        // Convert template to WorkoutKit plan
    }
    
    // Start mirrored workout (iPhone mirrors Watch)
    func startMirroredWorkout() async throws {
        // Implementation
    }
    
    // Track live metrics
    func observeLiveMetrics() -> AsyncStream<WorkoutMetrics> {
        // Implementation
    }
}
```

#### 2.2 Update Info.plist
Add WorkoutKit usage descriptions:
```xml
<key>NSWorkoutUsageDescription</key>
<string>AirFit uses WorkoutKit to provide live workout tracking and sync your workouts across devices.</string>
```

### Phase 3: Exercise Detail Sync

#### 3.1 Extend HealthKit Workout with Activities
**Add to** HealthKitManager.swift:
```swift
func saveWorkoutWithExercises(
    _ workout: Workout,
    exercises: [Exercise]
) async throws -> String {
    // Create main workout
    let hkWorkout = // ... create as before
    
    // Add workout activities for each exercise
    var activities: [HKWorkoutActivity] = []
    
    for exercise in exercises {
        let activity = HKWorkoutActivity(
            workoutConfiguration: HKWorkoutConfiguration(),
            start: exercise.startTime ?? Date(),
            end: exercise.endTime ?? Date(),
            metadata: [
                "exerciseName": exercise.name,
                "muscleGroups": exercise.muscleGroups.joined(separator: ","),
                "sets": exercise.sets.count
            ]
        )
        activities.append(activity)
    }
    
    // Save with activities
    try await healthStore.save(hkWorkout)
    
    // Save individual samples for sets
    for exercise in exercises {
        try await saveExerciseSets(exercise, workoutID: hkWorkout.uuid)
    }
    
    return hkWorkout.uuid.uuidString
}
```

### Phase 4: Watch Integration Cleanup

#### 4.1 Update WatchWorkoutManager.swift
**Modify** `processCompletedWorkout` (line 242):
```swift
private func processCompletedWorkout(_ workout: HKWorkout) async {
    // Current: Prepares data for sync
    // Add: Direct HealthKit reference
    currentWorkoutData.healthKitWorkoutID = workout.uuid.uuidString
    
    // Send to iPhone with HealthKit ID
    await WorkoutSyncService.shared.sendWorkoutData(currentWorkoutData)
}
```

#### 4.2 Clean Up WorkoutSyncService.swift
**Remove** CloudKit sync (lines 63-80)
**Modify** `processReceivedWorkout` (line 83):
```swift
func processReceivedWorkout(_ data: WorkoutBuilderData, modelContext: ModelContext) async throws {
    // Create workout in SwiftData
    let workout = Workout(...)
    
    // Link to existing HealthKit workout if from Watch
    if let healthKitID = data.healthKitWorkoutID {
        workout.healthKitWorkoutID = healthKitID
        workout.healthKitSyncedDate = Date()
    }
    
    modelContext.insert(workout)
    try modelContext.save()
}
```

## Data Model Updates

### 1. Workout.swift
**Add** missing sync fields:
```swift
// Line 19 - already exists but unused
var healthKitWorkoutID: String?
var healthKitSyncedDate: Date?

// Add new fields
var healthKitMetadata: Data? // JSON encoded metadata
var workoutSegments: Data? // JSON encoded segments
```

### 2. Exercise.swift
**Add** HealthKit activity reference:
```swift
// After line 13
var healthKitActivityID: String?
var startTime: Date?
var endTime: Date?
```

### 3. WorkoutBuilderData.swift
**Add** HealthKit reference:
```swift
struct WorkoutBuilderData: Codable {
    // ... existing fields
    var healthKitWorkoutID: String? // Add this
}
```

## Migration Strategy

### Phase 1: Non-Breaking Changes (Week 1)
1. Add write methods to HealthKitManager
2. Update WorkoutService to dual-write
3. Deploy without breaking existing functionality

### Phase 2: Watch Integration (Week 2)
1. Update WatchWorkoutManager to include HealthKit IDs
2. Modify sync service to preserve HealthKit references
3. Remove CloudKit direct sync

### Phase 3: WorkoutKit Features (Week 3)
1. Add WorkoutKitManager for iOS 17+ devices
2. Implement live workout mirroring
3. Add detailed exercise tracking

### Phase 4: Historical Migration (Optional)
1. Background task to sync existing workouts
2. Match by date/duration/type
3. Update healthKitWorkoutID for matches

## Code to Remove

### 1. CloudKit Sync (WorkoutSyncService.swift)
```swift
// REMOVE lines 63-80: syncToCloudKit method
// REMOVE lines 16-22: CloudKit container
// This functionality is replaced by HealthKit sync
```

### 2. Manual Calculations (WorkoutService.swift)
```swift
// REMOVE line 77: calculateEstimatedCalories
// Use HealthKit's energy calculations instead
```

### 3. Redundant Sync Logic
- Remove `pendingWorkouts` queue (WorkoutSyncService.swift:12)
- Remove CloudKit-specific error handling
- Simplify to HealthKit-first approach

## Testing Strategy

### Unit Tests
1. Mock HealthKitManager for workout saves
2. Test HealthKit ID persistence
3. Test sync conflict resolution

### Integration Tests
1. Test Watch → iPhone → HealthKit flow
2. Test WorkoutKit live metrics (iOS 17+)
3. Test exercise detail preservation

### Manual Testing
1. Verify workouts appear in Fitness app
2. Check Activity ring updates
3. Test cross-device sync
4. Verify exercise details in Health app

## Success Metrics

1. **Technical Metrics**
   - 100% of workouts saved to HealthKit
   - <200ms additional save latency
   - Zero data loss during sync

2. **User Metrics**
   - Workouts visible in Fitness app
   - Activity rings update correctly
   - Exercise details preserved
   - Live metrics during workouts (iOS 17+)

## Risk Mitigation

1. **Feature Flags**
   ```swift
   AppConstants.healthKitWorkoutSyncEnabled = false // Initially
   AppConstants.workoutKitEnabled = false // For iOS 17+
   ```

2. **Gradual Rollout**
   - Test with internal users
   - Monitor crash rates
   - Verify HealthKit permissions

3. **Fallback Strategy**
   - Always save to SwiftData first
   - HealthKit sync is non-blocking
   - Queue failed syncs for retry

## Implementation Priority

### Immediate (Before Test Fixes)
1. **Add HealthKit write methods** - Low risk, high value
2. **Update WorkoutService** - Dual-write pattern
3. **Fix Watch sync** - Include HealthKit IDs

### Phase 1 (With Test Updates)
1. **Remove CloudKit sync** - Simplify architecture
2. **Update models** - Add missing fields
3. **Create unit tests** - Mock HealthKit operations

### Phase 2 (After Tests Pass)
1. **Implement WorkoutKit** - iOS 17+ features
2. **Add live metrics** - Enhanced tracking
3. **Historical migration** - Sync old workouts

## Conclusion

This integration positions AirFit as a first-class iOS fitness app that properly leverages Apple's ecosystem. The phased approach:

1. **Fixes immediate issues**: Workouts not appearing in Fitness app
2. **Cleans up architecture**: Removes redundant CloudKit sync
3. **Adds advanced features**: WorkoutKit for live tracking
4. **Preserves functionality**: No breaking changes

The key is maintaining SwiftData as the primary store while using HealthKit as the integration point with the Apple ecosystem.

**Next Steps**:
1. Review and approve this plan
2. Implement Phase 1 (basic HealthKit writing)
3. Clean up redundant sync code
4. Test with Watch workouts
5. Roll out WorkoutKit features for iOS 17+ users