# HealthKit Testing Priority Plan

**Date**: 2025-06-05
**Critical**: New HealthKit write functionality is completely untested
**Risk Level**: 🔴 CRITICAL - User health data integrity at risk

> **Navigation**: Critical priority - read this early!  
> **Previous**: [TEST_COVERAGE_GAP_ANALYSIS.md](./TEST_COVERAGE_GAP_ANALYSIS.md)  
> **Next**: [TEST_STANDARDS.md](./TEST_STANDARDS.md) - Learn the standards before implementing

## Overview

The recent HealthKit integration (completed 2025-06-05) added bidirectional sync for nutrition and workout data. This functionality is currently **100% untested**, representing the highest risk in the codebase.

## Untested HealthKit Methods

### Nutrition Write Methods
```swift
// In HealthKitManager
func saveNutritionToHealthKit(_ nutrition: NutritionData, date: Date) async throws -> Bool
func syncFoodEntryToHealthKit(_ entry: FoodEntry) async throws
func deleteFoodEntryFromHealthKit(_ entry: FoodEntry) async throws -> Bool

// In DashboardNutritionService  
@MainActor func syncTodayToHealthKit() async throws
```

### Workout Write Methods
```swift
// In HealthKitManager
func saveWorkoutToHealthKit(_ workout: Workout) async throws -> HKWorkout
func deleteWorkoutFromHealthKit(_ workoutId: UUID) async throws

// In WorkoutSyncService
func syncWorkoutToHealthKit(_ workout: Workout) async
func syncAllPendingWorkouts() async
```

### Data Types Being Written
- Dietary Energy (calories)
- Macronutrients (protein, carbs, fat)
- Workout data with routes
- Correlation between nutrition samples
- Metadata with AirFit identifiers

## Testing Challenges

### 1. HealthKit Simulator Limitations
- HealthKit not available in iOS Simulator
- Requires device testing or sophisticated mocking

### 2. Data Integrity Requirements
- Must ensure no duplicate entries
- Proper cleanup on deletion
- Accurate unit conversions
- Timezone handling

### 3. Async Complexity
- Background sync operations
- Error recovery patterns
- State management during sync

## Proposed Testing Strategy

### Layer 1: Unit Tests with Mocks

**File**: `HealthKitManagerUnitTests.swift`

```swift
@MainActor
final class HealthKitManagerUnitTests: XCTestCase {
    var sut: HealthKitManager!
    var mockHealthStore: MockHKHealthStore!
    
    override func setUp() async throws {
        mockHealthStore = MockHKHealthStore()
        sut = HealthKitManager(healthStore: mockHealthStore)
    }
    
    func test_saveNutritionToHealthKit_createsCorrectSamples() async throws {
        // Arrange
        let nutrition = NutritionData(
            calories: 500,
            protein: 30,
            carbs: 50,
            fat: 20
        )
        
        // Act
        let success = try await sut.saveNutritionToHealthKit(nutrition, date: Date())
        
        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(mockHealthStore.savedSamples.count, 5) // 4 nutrients + 1 correlation
        
        // Verify calories
        let calorieSample = mockHealthStore.savedSamples.first { 
            $0.quantityType == HKQuantityType(.dietaryEnergyConsumed)
        }
        XCTAssertEqual(calorieSample?.quantity.doubleValue(for: .kilocalorie()), 500)
    }
    
    func test_deleteFoodEntry_removesAllRelatedSamples() async throws {
        // Test deletion removes all correlated samples
    }
    
    func test_syncFoodEntry_handlesExisting() async throws {
        // Test update vs create logic
    }
}
```

### Layer 2: Integration Tests

**File**: `HealthKitIntegrationTests.swift`

```swift
final class HealthKitIntegrationTests: XCTestCase {
    // These tests require device or advanced mocking
    
    func test_nutritionSync_endToEnd() async throws {
        // 1. Create FoodEntry in SwiftData
        // 2. Sync to HealthKit
        // 3. Verify in HealthKit
        // 4. Update FoodEntry
        // 5. Verify update in HealthKit
        // 6. Delete FoodEntry
        // 7. Verify removal from HealthKit
    }
    
    func test_workoutSync_withRoute() async throws {
        // Test workout with GPS route data
    }
    
    func test_concurrentSync_preventsDuplicates() async throws {
        // Test race conditions
    }
}
```

### Layer 3: Mock Infrastructure

**File**: `MockHKHealthStore.swift`

```swift
class MockHKHealthStore: HKHealthStore {
    var savedSamples: [HKSample] = []
    var deletedSamples: [HKSample] = []
    var authorizationStatus: [HKObjectType: HKAuthorizationStatus] = [:]
    
    override func save(_ samples: [HKSample], withCompletion completion: @escaping (Bool, Error?) -> Void) {
        savedSamples.append(contentsOf: samples)
        completion(true, nil)
    }
    
    override func delete(_ samples: [HKSample], withCompletion completion: @escaping (Bool, Error?) -> Void) {
        deletedSamples.append(contentsOf: samples)
        completion(true, nil)
    }
}
```

## Test Cases Priority List

### 🔴 Critical (Must Have)

1. **Nutrition Save Tests**
   - ✓ Correct calorie conversion
   - ✓ All macros saved
   - ✓ Correlation created
   - ✓ Metadata includes identifiers
   - ✓ Error handling

2. **Nutrition Delete Tests**
   - ✓ All samples removed
   - ✓ Correlation cleaned up
   - ✓ No orphaned data
   - ✓ Error recovery

3. **Workout Save Tests**
   - ✓ Duration and calories
   - ✓ Exercise type mapping
   - ✓ Route data included
   - ✓ Metadata preserved

### 🟡 Important (Should Have)

4. **Edge Cases**
   - Zero values
   - Nil optionals
   - Invalid dates
   - Missing permissions

5. **Sync State**
   - Pending sync queue
   - Retry logic
   - Offline behavior

6. **Data Integrity**
   - No duplicates
   - Accurate totals
   - Timezone handling

### 🟢 Nice to Have

7. **Performance**
   - Bulk operations
   - Memory usage
   - Sync timing

8. **UI Integration**
   - Progress indicators
   - Error messages
   - Success feedback

## Implementation Plan

### Phase 1: Mock Infrastructure
- Create MockHKHealthStore
- Create MockHKWorkout  
- Create test data builders
- Add to DITestHelper

### Phase 2: Core Nutrition Tests
- Unit tests for save/update/delete
- Integration test setup
- Error case coverage
- Nil value handling

### Phase 3: Workout Tests
- Unit tests for workout sync
- Route data handling
- Metadata verification
- Deletion tests

### Phase 4: Integration & Edge Cases
- End-to-end flows
- Concurrent operation tests
- Permission handling
- Race condition tests

### Phase 5: Documentation
- Test documentation
- Coverage report
- Known limitations
- Device testing guide

## Device Testing Strategy

Since HealthKit requires device testing:

1. **Create Test Harness App**
   - Minimal UI for triggering operations
   - Real HealthKit integration
   - Logging and verification

2. **Manual Test Protocol**
   - Step-by-step procedures
   - Expected outcomes
   - Verification queries

3. **CI/CD Considerations**
   - Skip HealthKit tests in CI
   - Mark as manual verification
   - Document testing process

## Success Criteria

1. **100% method coverage** for HealthKit writes
2. **All edge cases handled** gracefully
3. **No data corruption** scenarios
4. **Clear error messages** for failures
5. **Performance benchmarks** established

## Risk Mitigation

Without these tests, risks include:
- Duplicate health entries
- Incorrect nutritional data
- Lost workout data  
- User trust erosion
- App Store rejection

This testing is **non-negotiable** before release.

## Conclusion

HealthKit testing should be the #1 priority given:
- User health data sensitivity
- No current test coverage
- Recent implementation (high change risk)
- Core feature importance

Priority: Critical - Complete before any other test work