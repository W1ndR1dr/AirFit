# Service @MainActor Categorization

**Created**: 2025-01-08  
**Purpose**: Quick reference for which services can be converted to actors

## ✅ Services That CAN Be Converted to Actors

These services don't depend on SwiftData or UI frameworks:

1. **NetworkManager** ✓ DONE
   - Pure networking logic
   - Only notification posting needs MainActor

2. **AIAnalyticsService** ✓ DONE
   - Wraps another service
   - No UI dependencies

3. **MonitoringService**
   - Performance monitoring
   - Can run on actor

4. **TestModeAIService**
   - Mock service for testing
   - No real dependencies

5. **ServiceConfiguration**
   - Just configuration data
   - Should remove @MainActor entirely

6. **ServiceRegistry**
   - Service management
   - Can be actor-based

7. **WhisperModelManager**
   - Model management
   - File operations don't need MainActor

8. **WorkoutSyncService**
   - Background sync operations
   - Perfect for actor

9. **ContextAssembler**
   - Data assembly
   - Can run on actor

10. **HealthKitDataFetcher**
    - Data fetching logic
    - HealthKit operations don't need MainActor

11. **HealthKitSleepAnalyzer**
    - Data analysis
    - Pure computation

## ❌ Services That MUST Keep @MainActor

These services are tightly coupled to SwiftData's ModelContext:

1. **UserService**
   - Direct ModelContext usage
   - All operations touch SwiftData

2. **GoalService**
   - ModelContext for goal persistence
   - SwiftData CRUD operations

3. **AnalyticsService**
   - Uses ModelContext
   - Stores analytics in SwiftData

4. **AIGoalService**
   - Wraps GoalService which uses ModelContext
   - Inherits SwiftData dependency

5. **AIWorkoutService**
   - Wraps WorkoutService which uses ModelContext
   - SwiftData dependency

## ⚠️ Services Requiring Careful Conversion

These need special handling due to UI integration:

1. **HealthKitManager**
   - Uses @Observable for SwiftUI
   - Need to separate data fetching from UI updates
   - Pattern: Actor for logic, MainActor methods for UI

2. **LLMOrchestrator**
   - Uses ObservableObject with @Published
   - Pattern: Actor core with MainActor wrapper for UI

3. **VoiceInputManager**
   - Audio session management
   - UI updates for recording state
   - Pattern: Actor for audio, MainActor for UI state

## Conversion Patterns

### Pattern 1: Pure Service → Actor
```swift
// BEFORE
@MainActor
final class NetworkManager: ServiceProtocol {
    func fetchData() async -> Data { }
}

// AFTER
actor NetworkManager: ServiceProtocol {
    func fetchData() async -> Data { }
}
```

### Pattern 2: Service with UI Updates
```swift
// BEFORE
@MainActor
final class HealthService: ObservableObject {
    @Published var status: String = ""
    
    func updateHealth() async {
        // All on MainActor
        status = "Updating..."
        let data = await fetchData()
        status = "Done"
    }
}

// AFTER
actor HealthService {
    private var _status: String = ""
    
    func updateHealth() async {
        _status = "Updating..."
        let data = await fetchData()
        _status = "Done"
        
        // Only UI update on MainActor
        await MainActor.run {
            NotificationCenter.default.post(...)
        }
    }
}

// Separate UI State Manager
@MainActor
final class HealthServiceUIState: ObservableObject {
    @Published var status: String = ""
    
    init(service: HealthService) {
        // Subscribe to notifications
    }
}
```

### Pattern 3: SwiftData Services (Keep @MainActor)
```swift
// These MUST stay @MainActor
@MainActor
final class UserService {
    private let modelContext: ModelContext
    
    func saveUser(_ user: User) async throws {
        modelContext.insert(user)
        try modelContext.save() // Must be on MainActor
    }
}
```

## Priority Conversion List

1. **High Impact** (Convert First):
   - MonitoringService (performance critical)
   - WorkoutSyncService (background operations)
   - ContextAssembler (frequent calls)

2. **Medium Impact**:
   - TestModeAIService
   - WhisperModelManager
   - HealthKitDataFetcher
   - HealthKitSleepAnalyzer

3. **Low Impact**:
   - ServiceConfiguration (just remove @MainActor)
   - ServiceRegistry

## Testing Strategy

For each conversion:
```swift
func testActorConcurrency() async {
    let service = MyService()
    
    // Should run in parallel
    async let result1 = service.operation1()
    async let result2 = service.operation2()
    
    let results = await (result1, result2)
    // Verify both completed
}
```