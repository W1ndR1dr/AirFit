# HealthKit Nutrition Integration Plan

## Executive Summary
Currently, AirFit stores nutrition data only in SwiftData, missing the opportunity to integrate with Apple's HealthKit ecosystem. This plan outlines a comprehensive integration to store nutrition data in HealthKit while maintaining SwiftData for app-specific metadata and quick queries, including cleanup of conflicting/incomplete code.

## Current State Analysis

### What's Working
- ✅ HealthKit integration exists for workouts, body metrics, and water intake
- ✅ SwiftData models properly store nutrition data (FoodEntry, FoodItem, NutritionData)
- ✅ HealthKitManager infrastructure is in place and functional
- ✅ Proper authorization flow for HealthKit permissions

### What's Missing
- ❌ No nutrition data (calories, macros, etc.) written to HealthKit
- ❌ HealthKitDataTypes.swift only includes `dietaryWater` for nutrition
- ❌ NutritionService doesn't interact with HealthKit beyond water
- ❌ No synchronization between SwiftData and HealthKit for nutrition
- ❌ HealthKitManager has NO write methods at all (read-only implementation)
- ❌ Water intake tracking is just a placeholder returning 0

### Critical Findings
1. **HealthKitManager is Read-Only**: The current implementation only fetches data from HealthKit, it cannot write any data. This needs fundamental changes.
2. **Water Tracking Not Implemented**: Even though `dietaryWater` is in permissions, the actual implementation just returns 0.
3. **No HealthKit References in Models**: FoodEntry and FoodItem have no way to track their HealthKit counterparts for updates/deletes.
4. **Incomplete Calorie Sync**: NutritionService has `syncCaloriesToHealthKit` (lines 158-180) but only syncs calories, not other macros.

## Code to Clean Up

### 1. NutritionService.swift (lines 158-180)
**Current**: Incomplete implementation that only syncs calories
```swift
func syncCaloriesToHealthKit(for user: User, date: Date) async throws {
    // Only saves calories, ignores protein/carbs/fat
}
```
**Action**: Remove this method and replace with comprehensive nutrition sync in HealthKitManager

### 2. NutritionService.swift (lines 78-82, 108-111)
**Current**: Placeholder water tracking that returns 0
```swift
func getWaterIntake(for user: User, date: Date) async throws -> Double {
    return 0  // Placeholder
}
```
**Action**: Implement proper HealthKit water tracking or remove if not needed

### 3. Duplicate HealthStore Instances
**Current**: Both NutritionService (line 8) and HealthKitManager have separate HKHealthStore instances
**Action**: Remove from NutritionService, use HealthKitManager.shared for all HealthKit operations

## Benefits of Integration

1. **User Value**
   - Nutrition data visible in Apple Health app
   - Integration with other health/fitness apps
   - Comprehensive health picture in one place
   - Apple's native data visualization and trends

2. **Technical Benefits**
   - Automatic iCloud backup via Health
   - Standardized data format
   - Apple handles data privacy/encryption
   - Historical data access across device upgrades

3. **Business Value**
   - Better app store positioning (uses HealthKit fully)
   - Increased user retention (data portability)
   - Reduced support burden (Apple handles sync)

## Implementation Plan

### Phase 1: Update HealthKit Permissions

#### 1.1 Update HealthKitDataTypes.swift
```swift
// Add to writeTypes:
.dietaryEnergyConsumed      // Calories
.dietaryProtein             // Protein
.dietaryCarbohydrates       // Carbohydrates  
.dietaryFatTotal            // Total Fat
.dietaryFiber               // Fiber
.dietarySugar               // Sugar
.dietarySodium              // Sodium

// Add to readTypes (for displaying user's full nutrition):
// Same as above
```

#### 1.2 Update Info.plist
- Update `NSHealthUpdateUsageDescription` to mention nutrition tracking
- Update `NSHealthShareUsageDescription` to mention reading nutrition data

### Phase 2: Extend HealthKitManager

#### 2.1 Add Nutrition Writing Methods
```swift
// In HealthKitManager:
func saveNutritionData(
    calories: Double,
    protein: Double,
    carbs: Double,
    fat: Double,
    fiber: Double?,
    sugar: Double?,
    sodium: Double?,
    date: Date,
    metadata: [String: Any]? = nil
) async throws

func saveFoodEntry(
    _ foodEntry: FoodEntry,
    metadata: [String: Any]? = nil
) async throws
```

#### 2.2 Add Nutrition Reading Methods
```swift
func getNutritionData(
    for date: Date,
    types: Set<HKQuantityTypeIdentifier>
) async throws -> NutritionSummary

func getNutritionHistory(
    from startDate: Date,
    to endDate: Date
) async throws -> [DailyNutritionSummary]
```

### Phase 3: Update NutritionService

#### 3.1 Clean Up and Modify saveFoodEntry
```swift
func saveFoodEntry(_ entry: FoodEntry) async throws {
    // 1. Save to SwiftData (existing)
    modelContext.insert(entry)
    try modelContext.save()
    
    // 2. Save to HealthKit (new)
    // REMOVE the incomplete syncCaloriesToHealthKit method
    // REPLACE with comprehensive nutrition sync
    try await HealthKitManager.shared.saveFoodEntry(entry)
}
```

#### 3.2 Remove Duplicate Code
```swift
// REMOVE line 8:
private let healthStore = HKHealthStore()  // Duplicate of HealthKitManager's

// REMOVE lines 158-180:
func syncCaloriesToHealthKit(...) // Incomplete implementation
```

#### 3.3 Add HealthKit Sync Methods
```swift
func syncWithHealthKit(for date: Date) async throws
func resolveHealthKitConflicts(localData: [FoodEntry], healthKitData: [HKSample]) async throws
```

### Phase 4: Data Model Updates

#### 4.1 Add HealthKit References
```swift
// In FoodEntry:
var healthKitSampleID: String?  // HKSample UUID for updates/deletes
var healthKitSyncDate: Date?    // Last sync timestamp

// In FoodItem:
var healthKitCorrelationID: String?  // For grouped samples
```

#### 4.2 Migration Strategy
- Existing data remains in SwiftData
- New entries saved to both systems
- Background migration task for historical data (optional)

### Phase 5: Sync Strategy

#### 5.1 Write Strategy
- **Primary Write**: Always write to SwiftData first (immediate UI updates)
- **Secondary Write**: Queue HealthKit writes (can be async)
- **Failure Handling**: Retry queue for failed HealthKit writes

#### 5.2 Read Strategy
- **App Launch**: Check for HealthKit changes since last sync
- **Pull to Refresh**: Sync with HealthKit
- **Background Refresh**: Periodic sync when app is backgrounded

#### 5.3 Conflict Resolution
- **App Data Priority**: AirFit data takes precedence for entries created in-app
- **External Data**: HealthKit data from other apps is imported but marked
- **User Choice**: For conflicts, present UI for user to choose

## Implementation Details

### HealthKit Sample Structure

#### Individual Nutrients
Each macro/micro nutrient is saved as a separate `HKQuantitySample`:
```swift
// Example for a food item:
- HKQuantitySample(type: .dietaryEnergyConsumed, quantity: 250 kcal)
- HKQuantitySample(type: .dietaryProtein, quantity: 20 g)
- HKQuantitySample(type: .dietaryCarbohydrates, quantity: 30 g)
- HKQuantitySample(type: .dietaryFatTotal, quantity: 10 g)
```

#### Correlation for Meals
Use `HKCorrelation` to group related samples:
```swift
// Correlate all nutrients from one meal/food item
HKCorrelation(
    type: .food(),
    start: date,
    end: date,
    objects: [energySample, proteinSample, carbsSample, fatSample],
    metadata: ["foodName": "Grilled Chicken Salad", "AirFitID": foodEntry.id]
)
```

### Metadata Standards
```swift
let metadata: [String: Any] = [
    "AirFitFoodEntryID": foodEntry.id.uuidString,
    "AirFitMealType": foodEntry.mealType,
    "AirFitFoodName": foodItem.name,
    "AirFitBrand": foodItem.brand ?? "",
    "AirFitSource": "AI-Parsed", // or "Manual", "Barcode"
    "AirFitConfidence": item.confidence ?? 1.0
]
```

## File Changes Required

### 1. HealthKitDataTypes.swift
**Current State**: Only includes `dietaryWater` for nutrition writes
**Changes Needed**:
- Add nutrition types to `writeTypes` (lines 80-84)
- Add same nutrition types to `readTypes` (lines 39-41)
- Create helper enum for nutrition identifiers

### 2. HealthKitManager.swift  
**Current State**: Read-only implementation, no write methods at all
**Changes Needed**:
- Add nutrition write methods (after line 252)
- Add nutrition read methods
- Add sync status tracking properties
- Update error enum for nutrition-specific errors

### 3. NutritionService.swift
**Current State**: Only saves to SwiftData, incomplete HealthKit integration
**Changes Needed**:
- Remove `healthStore` property (line 8) - use HealthKitManager.shared instead
- Remove `syncCaloriesToHealthKit` method (lines 158-180) - replace with proper implementation
- Modify `saveFoodEntry` to write to HealthKit (line 16)
- Implement actual water tracking with HealthKit (line 78) or remove placeholder
- Add comprehensive sync methods

### 4. FoodEntry.swift & FoodItem.swift
**Current State**: Pure SwiftData models with no HealthKit references
**Changes Needed**:
- Add `healthKitSampleID: String?` to FoodEntry
- Add `healthKitSyncDate: Date?` to FoodEntry
- Add `healthKitCorrelationID: String?` to FoodItem

### 5. Info.plist
**Current State**: Mentions workouts and body measurements but not nutrition
**Changes Needed**:
- Update `NSHealthUpdateUsageDescription` (line 67) to include "nutrition data"
- Update `NSHealthShareUsageDescription` (line 64) to mention "nutrition tracking"

### 6. AppConstants.swift
**Current State**: No HealthKit-specific constants
**Changes Needed**:
- Add `healthKitSyncInterval: TimeInterval = 300` (5 minutes)
- Add `healthKitRetryDelay: TimeInterval = 60`
- Add nutrition serving size defaults

### 7. New Files
- `Services/Health/HealthKitNutritionWriter.swift` - Dedicated nutrition writing
- `Services/Health/HealthKitNutritionReader.swift` - Dedicated nutrition reading
- `Services/Health/HealthKitNutritionSync.swift` - Sync coordinator
- `Core/Models/NutritionConflict.swift` - Conflict resolution models

## Testing Strategy

### Unit Tests
- Mock HealthKitManager for NutritionService tests
- Test data conversion between models and HKSamples
- Test conflict resolution logic

### Integration Tests
- Test full flow: UI → SwiftData → HealthKit
- Test sync scenarios
- Test error handling and recovery

### Manual Testing
- Verify data appears in Apple Health app
- Test with other nutrition apps
- Verify sync across devices

## Migration Plan

### Phase 1: Non-Breaking Changes (Week 1)
1. Update permissions and Info.plist
2. Add new methods to HealthKitManager
3. Deploy without changing save behavior

### Phase 2: Dual-Write (Week 2)
1. Update NutritionService to write to both systems
2. Monitor for issues
3. Add sync UI indicators

### Phase 3: Full Integration (Week 3)
1. Enable read sync from HealthKit
2. Add conflict resolution UI
3. Enable background sync

### Phase 4: Historical Migration (Optional)
1. Background task to migrate existing data
2. User-initiated migration option
3. Progress tracking

## Success Metrics

1. **Technical Metrics**
   - 100% of new nutrition entries saved to HealthKit
   - <100ms additional latency for saves
   - 0% data loss during sync

2. **User Metrics**
   - Nutrition data visible in Health app
   - Successful sync with other apps
   - No increase in crash rate

## Rollback Plan

If issues arise:
1. Feature flag to disable HealthKit writes
2. Keep SwiftData as primary storage
3. Queue HealthKit operations for later retry
4. Clear messaging to users about temporary limitation

## Future Enhancements

1. **Phase 2 Features**
   - Micronutrient tracking (vitamins, minerals)
   - Meal photo storage in HealthKit
   - Recipe correlation support

2. **Phase 3 Features**
   - HealthKit data export
   - Nutrition trends analysis
   - Integration with Apple Watch

## Code Examples

### Writing Nutrition to HealthKit
```swift
extension HealthKitManager {
    func saveFoodItem(_ item: FoodItem, date: Date) async throws {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
              let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
              let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates),
              let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        var samples: [HKQuantitySample] = []
        
        // Create metadata
        let metadata: [String: Any] = [
            "AirFitFoodItemID": item.id.uuidString,
            "AirFitFoodName": item.name,
            "AirFitServingSize": "\(item.quantity ?? 1) \(item.unit ?? "serving")"
        ]
        
        // Energy
        if let calories = item.calories {
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let sample = HKQuantitySample(
                type: energyType,
                quantity: quantity,
                start: date,
                end: date,
                metadata: metadata
            )
            samples.append(sample)
        }
        
        // Continue for other nutrients...
        
        try await healthStore.save(samples)
    }
}
```

### Reading Nutrition from HealthKit
```swift
func getTodaysNutrition() async throws -> NutritionSummary {
    let calendar = Calendar.current
    let now = Date()
    let startOfDay = calendar.startOfDay(for: now)
    let predicate = HKQuery.predicateForSamples(
        withStart: startOfDay,
        end: now,
        options: .strictStartDate
    )
    
    // Query each nutrition type
    let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
    let energySamples = try await withCheckedThrowingContinuation { continuation in
        let query = HKSampleQuery(
            sampleType: energyType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
        }
        healthStore.execute(query)
    }
    
    // Sum up calories
    let totalCalories = energySamples.reduce(0) { sum, sample in
        sum + sample.quantity.doubleValue(for: .kilocalorie())
    }
    
    // Continue for other nutrients...
}
```

## Implementation Priority

Given the current test suite issues, here's the recommended order:

### Immediate (Before Test Fixes)
1. **Update HealthKitDataTypes.swift** - Add nutrition permissions
2. **Create HealthKitNutritionWriter.swift** - Basic write functionality
3. **Update Info.plist** - Add nutrition to descriptions

### Phase 1 (With Test Updates)
1. **Update NutritionService** - Add HealthKit writes
2. **Update FoodEntry/FoodItem models** - Add HealthKit IDs
3. **Create unit tests** - Mock HealthKit operations

### Phase 2 (After Tests Pass)
1. **Implement sync logic** - Background sync
2. **Add conflict resolution** - Handle external data
3. **Create UI indicators** - Show sync status

## Risk Mitigation

1. **Feature Flag**: Add `AppConstants.healthKitNutritionEnabled = false` initially
2. **Gradual Rollout**: Test with internal users first
3. **Fallback**: Always save to SwiftData first, HealthKit is secondary
4. **Error Handling**: Silent failures for HealthKit, always show success if SwiftData saves

## Summary of Code Cleanup

### Files to Modify
1. **NutritionService.swift**
   - Remove `healthStore` property (line 8)
   - Remove `syncCaloriesToHealthKit` method (lines 158-180)
   - Update `saveFoodEntry` to use HealthKitManager
   - Fix or remove water tracking placeholders

2. **HealthKitDataTypes.swift**
   - Add nutrition types to read/write permissions

3. **HealthKitManager.swift**
   - Add comprehensive nutrition write methods
   - Add nutrition read methods
   - Consolidate all HealthKit operations here

4. **Data Models**
   - Add HealthKit reference fields to FoodEntry/FoodItem

### Code to Remove
- Duplicate HKHealthStore instance in NutritionService
- Incomplete syncCaloriesToHealthKit implementation
- Placeholder water tracking that returns 0

## Conclusion

This integration will position AirFit as a best-in-class iOS health app that properly leverages Apple's health ecosystem. The phased approach minimizes risk while delivering immediate value to users.

The key is:
1. **Clean up conflicting code** - Remove incomplete implementations
2. **Centralize HealthKit operations** - All through HealthKitManager
3. **Maintain dual storage** - SwiftData for app features, HealthKit for ecosystem

**Next Steps**: 
1. Review and approve this plan
2. Clean up conflicting code first
3. Implement "Immediate" changes (low risk, high value)
4. Update test mocks to support HealthKit operations
5. Proceed with Phase 1 implementation