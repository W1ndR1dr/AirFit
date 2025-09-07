# Watch Connectivity Manual Testing Guide

## Overview
This document provides comprehensive manual testing procedures for the enhanced Watch Connectivity system in AirFit. The improvements focus on hardened queueing, reachability handling, and automatic retry mechanisms.

## Prerequisites

### Hardware Setup
- iPhone 16 Pro with iOS 26.0 running AirFit
- Apple Watch (Series 4+) paired with iPhone
- AirFit Watch App installed on Apple Watch
- Both devices charged and nearby

### Software Setup
- Xcode with debug console access
- AirFit app in debug/development mode
- Watch Simulator (for some connectivity scenarios)

### Test Data
Create test workout plans through the AI system or use these sample plans:

```swift
// Sample Workout Plan for Testing
PlannedWorkoutData(
    name: "Connectivity Test Workout",
    workoutType: 1,
    estimatedDuration: 30,
    estimatedCalories: 200,
    plannedExercises: [
        PlannedExerciseData(
            name: "Push-ups",
            sets: 3,
            targetReps: 10,
            restSeconds: 60,
            orderIndex: 0
        ),
        PlannedExerciseData(
            name: "Squats", 
            sets: 3,
            targetReps: 15,
            restSeconds: 60,
            orderIndex: 1
        )
    ],
    targetMuscleGroups: ["chest", "legs"],
    userId: UUID()
)
```

## Test Categories

## 1. Queue Persistence Testing

### Test 1.1: Basic Queue Operations
**Objective**: Verify queue management functionality

**Steps**:
1. Launch AirFit iOS app
2. Navigate to workout creation and generate a workout plan
3. With watch disconnected, attempt to send workout to watch
4. Verify plan is queued (check queue count in debug UI/logs)
5. Add 2-3 more workout plans while watch remains disconnected
6. Verify queue shows correct count
7. Force-quit and relaunch AirFit
8. Verify queue persisted across app restarts

**Expected Results**:
- Plans are queued when watch unavailable
- Queue count updates correctly
- Queue persists across app restarts
- Logs show queue operations

**Debug Commands**:
```
// Check queue status in debug console
WatchStatusStore.shared.getQueueStatistics().debugDescription
WatchStatusStore.shared.queuedPlansCount
```

### Test 1.2: Queue Size Limits
**Objective**: Verify queue size enforcement

**Steps**:
1. Generate 55 workout plans (exceeding 50-item limit)
2. Queue all plans by sending while watch disconnected
3. Verify queue caps at 50 items
4. Check that oldest items are removed first

**Expected Results**:
- Queue never exceeds 50 items
- Oldest items removed when limit exceeded
- Queue statistics track removal operations

### Test 1.3: Queue Expiration
**Objective**: Verify expired item cleanup

**Steps**:
1. Manually set queue items with old timestamps (requires debug modification)
2. Trigger queue cleanup
3. Verify expired items are removed

**Expected Results**:
- Items older than 7 days are removed
- Statistics track expired item removals

## 2. Reachability and Reconnection Testing

### Test 2.1: Watch Disconnection Scenarios
**Objective**: Test various disconnection scenarios

**Scenarios**:
A. **Watch out of range**:
   1. Move Apple Watch >30 feet from iPhone
   2. Attempt workout transfer
   3. Verify plan is queued with reason "watch_unavailable"

B. **Watch airplane mode**:
   1. Enable airplane mode on Apple Watch
   2. Attempt workout transfer
   3. Verify appropriate queue behavior

C. **iPhone airplane mode**:
   1. Enable airplane mode on iPhone
   2. Attempt workout transfer
   3. Verify network error handling

D. **Watch app not running**:
   1. Force-quit AirFit Watch app
   2. Attempt workout transfer
   3. Verify transfer behavior

**Expected Results**:
- Each scenario queues plans appropriately
- Different disconnection reasons are logged
- UI shows appropriate error messages

### Test 2.2: Automatic Reconnection
**Objective**: Verify automatic retry when connection restored

**Steps**:
1. Queue 3-5 workout plans while watch disconnected
2. Restore watch connectivity (bring watch in range)
3. Observe automatic retry attempts
4. Verify successful transfers remove items from queue

**Expected Results**:
- Automatic retry triggers within 1-2 seconds of connectivity
- Successfully transferred items removed from queue
- Failed items remain queued with updated retry counts
- Logs show retry attempts and results

### Test 2.3: Reachability Monitoring
**Objective**: Test background reachability checks

**Steps**:
1. Queue workout plans
2. Observe background reachability monitoring (30-second intervals)
3. Connect/disconnect watch multiple times
4. Verify retry attempts occur at appropriate times

**Expected Results**:
- Background monitoring detects connectivity changes
- Retry attempts scheduled appropriately
- No excessive battery drain from monitoring

## 3. Enhanced Retry Logic Testing

### Test 3.1: Exponential Backoff
**Objective**: Verify retry timing follows exponential backoff

**Steps**:
1. Queue a workout plan
2. Simulate repeated transfer failures
3. Monitor retry timing intervals
4. Verify exponential backoff pattern (2s, 4s, 8s, etc.)

**Expected Results**:
- Retry delays increase exponentially
- Jitter is applied to prevent thundering herd
- Maximum delay caps at 5 minutes
- Failed items removed after 5 retry attempts

### Test 3.2: Mixed Success/Failure Scenarios
**Objective**: Test retry behavior with partial successes

**Steps**:
1. Queue 5 workout plans
2. Simulate scenario where 2 succeed, 3 fail
3. Verify successful items removed from queue
4. Verify failed items scheduled for retry
5. Observe subsequent retry attempts

**Expected Results**:
- Successfully transferred plans removed immediately
- Failed plans remain with incremented retry counts
- Retry timing calculated individually per plan
- Statistics accurately track success/failure rates

### Test 3.3: Retry Statistics
**Objective**: Verify comprehensive retry statistics

**Steps**:
1. Perform multiple queue operations over time
2. Mix successful and failed transfers
3. Check queue statistics periodically
4. Verify accuracy of success rates and counts

**Expected Results**:
- Statistics accurately reflect all operations
- Success rate calculation is correct
- Debug information provides useful insights
- Statistics persist across app restarts

## 4. Integration Testing

### Test 4.1: End-to-End Workout Transfer
**Objective**: Complete workflow from AI generation to watch execution

**Steps**:
1. Generate workout using AI coach
2. Send workout to watch with good connectivity
3. Verify successful transfer
4. Start workout on watch
5. Complete workout and sync back to iPhone

**Expected Results**:
- Smooth end-to-end experience
- No data loss during transfer
- Watch displays workout correctly
- Completed workout syncs back to iPhone

### Test 4.2: Transfer During Watch App Use
**Objective**: Test transfers while watch app is active

**Steps**:
1. Open AirFit Watch app and navigate to workout view
2. From iPhone, send new workout plan
3. Verify transfer completes successfully
4. Verify watch app updates with new plan

**Expected Results**:
- Transfer succeeds even with watch app active
- Watch app UI updates appropriately
- No crashes or UI issues

### Test 4.3: Multiple Concurrent Operations
**Objective**: Test system under load

**Steps**:
1. Generate multiple workout plans rapidly
2. Send all to watch simultaneously
3. Disconnect and reconnect watch during process
4. Verify all plans eventually transfer or queue appropriately

**Expected Results**:
- System handles concurrent operations gracefully
- No race conditions or data corruption
- Queue operations remain atomic
- All plans accounted for correctly

## 5. Error Handling and Recovery Testing

### Test 5.1: Watch App Rejection
**Objective**: Test handling of workout plan rejection by watch

**Steps**:
1. Send intentionally invalid workout data (requires debug modification)
2. Verify watch rejects the plan
3. Check error handling and queue behavior

**Expected Results**:
- Rejection handled gracefully
- Plan queued with "watch_rejected" reason
- User receives appropriate error message
- Retry logic applies correctly

### Test 5.2: Data Corruption Scenarios
**Objective**: Test resilience to data corruption

**Steps**:
1. Manually corrupt persisted queue data (edit UserDefaults)
2. Restart app
3. Verify graceful recovery

**Expected Results**:
- App doesn't crash with corrupted data
- Queue resets to empty state safely
- Error logged appropriately
- Fresh operations work normally

### Test 5.3: Memory Pressure
**Objective**: Test behavior under memory constraints

**Steps**:
1. Queue maximum number of workout plans (50)
2. Use Xcode memory debugging tools
3. Simulate memory pressure
4. Verify no memory leaks or excessive usage

**Expected Results**:
- Memory usage remains reasonable
- No memory leaks detected
- Queue operations continue under pressure
- Graceful degradation if needed

## 6. Performance Testing

### Test 6.1: Queue Performance
**Objective**: Verify queue operations are performant

**Steps**:
1. Queue 50 workout plans rapidly
2. Measure time to queue all plans
3. Measure time to process queue when watch available
4. Verify no UI freezing during operations

**Expected Results**:
- Queue operations complete in <1 second
- UI remains responsive during all operations
- Background processing doesn't block main thread
- Memory usage scales linearly

### Test 6.2: Battery Impact
**Objective**: Assess battery usage

**Steps**:
1. Monitor battery usage with watch connectivity features active
2. Run overnight with queued plans and periodic retry attempts
3. Compare to baseline battery usage

**Expected Results**:
- Minimal battery impact from connectivity monitoring
- Reasonable battery usage for retry attempts
- No excessive wake-ups or background processing

## Debugging Tools

### Console Commands
```bash
# Monitor watch connectivity logs
log stream --predicate 'category == "services" AND subsystem CONTAINS "AirFit"'

# Watch for specific events
log stream --predicate 'eventMessage CONTAINS "queue" OR eventMessage CONTAINS "retry"'
```

### Debug UI Components
Create temporary debug views to display:
- Current queue status and statistics
- Watch connectivity state
- Recent retry attempts and results
- Manual queue processing triggers

### Breakpoint Locations
Key debugging points:
- `WatchStatusStore.queuePlan()`
- `WatchStatusStore.processQueueWithRetry()`
- `WorkoutPlanTransferService.directTransfer()`
- WCSession delegate methods

## Success Criteria

### Primary Objectives
- ✅ No workout plans lost during connectivity issues
- ✅ Automatic retry when connection restored
- ✅ Queue persists across app restarts
- ✅ Exponential backoff prevents connection flooding
- ✅ Clear error messages and recovery options

### Performance Objectives
- ✅ Queue operations complete in <1 second
- ✅ UI remains responsive during all operations
- ✅ Battery usage impact <2% of normal usage
- ✅ Memory usage scales reasonably with queue size

### Reliability Objectives
- ✅ No crashes under any connectivity scenario
- ✅ Graceful handling of all error conditions
- ✅ Complete data consistency across restarts
- ✅ 99%+ success rate for valid transfers when watch available

## Known Issues and Workarounds

### Simulator Limitations
- WatchConnectivity framework has limited simulator support
- Some tests require physical devices
- Mock objects provided for unit testing scenarios

### Framework Constraints
- WCSession singleton pattern limits dependency injection
- Some integration tests require real connectivity
- Timing-sensitive operations may vary on hardware

### Testing Environment Notes
- Ensure both devices have sufficient battery
- Test in various network conditions (WiFi, Cellular, Airplane mode)
- Consider environmental factors (distance, interference)

## Reporting Issues

When reporting issues, include:
1. Specific test case and steps
2. Device models and OS versions
3. Console logs and crash reports
4. Queue statistics and state information
5. Network/connectivity conditions
6. Screenshots or video of unexpected behavior

Use the issue template and tag with `watch-connectivity` and `manual-testing` labels.
