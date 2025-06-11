# @MainActor Cleanup Standards

**Last Updated**: 2025-01-08  
**Author**: Senior iOS Dev (fueled by Diet Coke)  
**Priority**: 🚨 Critical - This is blocking app performance

## The Golden Rules

### Rule 1: @MainActor is ONLY for UI
```swift
// ✅ CORRECT: ViewModels need @MainActor
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var uiState: DashboardState = .loading
}

// ❌ WRONG: Services should NOT be @MainActor
@MainActor  // DELETE THIS
final class NetworkManager: ServiceProtocol {
    // This runs on main thread for no reason!
}
```

### Rule 2: Services Should Be Actors
```swift
// ✅ CORRECT: Service as actor
actor NetworkManager: ServiceProtocol {
    private var cache: [String: Data] = [:]
    
    func fetchData() async throws -> Data {
        // Runs on actor's executor, not main thread
    }
}

// For services that need some UI updates:
actor HealthKitService {
    // Most work on actor
    func fetchHealthData() async -> HealthData { }
    
    // Only UI updates on MainActor
    @MainActor
    func updateUI(with data: HealthData) {
        // Minimal work here
    }
}
```

### Rule 3: Tests Don't Need @MainActor
```swift
// ❌ WRONG: Entire test class on MainActor
@MainActor
final class NetworkManagerTests: XCTestCase {
    // All tests forced to run sequentially on main thread!
}

// ✅ CORRECT: Only specific UI tests need it
final class NetworkManagerTests: XCTestCase {
    func testNetworkFetch() async {
        // Runs on any thread
    }
    
    @MainActor
    func testViewModelUpdate() async {
        // Only this test needs main thread
    }
}
```

## Categories & Actions

### 1. ViewModels & UI Components ✅ KEEP @MainActor
- All ViewModels (DashboardViewModel, ChatViewModel, etc.)
- All Coordinators (UI navigation)
- View-related utilities (HapticManager)

### 2. Services ❌ REMOVE @MainActor → Convert to Actors
**These 20 services must be converted:**
```
AIAnalyticsService → actor AIAnalyticsService
AIGoalService → actor AIGoalService
AIWorkoutService → actor AIWorkoutService
LLMOrchestrator → actor LLMOrchestrator
TestModeAIService → actor TestModeAIService
AnalyticsService → actor AnalyticsService
ContextAssembler → actor ContextAssembler
GoalService → actor GoalService
HealthKitDataFetcher → actor HealthKitDataFetcher
HealthKitManager → actor HealthKitManager
HealthKitSleepAnalyzer → actor HealthKitSleepAnalyzer
MonitoringService → actor MonitoringService
NetworkManager → actor NetworkManager (already has @preconcurrency)
ServiceConfiguration → Remove @MainActor (just config)
ServiceRegistry → actor ServiceRegistry
VoiceInputManager → actor VoiceInputManager
WhisperModelManager → actor WhisperModelManager
UserService → actor UserService
WorkoutSyncService → actor WorkoutSyncService
```

### 3. Protocols ⚠️ CAREFUL REMOVAL
Remove @MainActor from protocols unless they're UI-specific:
```swift
// ❌ WRONG: Forces all conformers to MainActor
@MainActor
protocol ServiceProtocol {
    var isConfigured: Bool { get }
}

// ✅ CORRECT: Let conformers decide
protocol ServiceProtocol {
    var isConfigured: Bool { get }
}

// ✅ CORRECT: UI protocols can require MainActor
@MainActor
protocol ViewModelProtocol: ObservableObject {
    // This makes sense for UI
}
```

### 4. Test Classes 🧹 BULK REMOVAL
Remove @MainActor from all 96 test classes. Only add it to specific test methods that test UI.

## Migration Pattern

### Step 1: Service to Actor
```swift
// BEFORE:
@MainActor
final class HealthKitManager: ServiceProtocol {
    private var healthStore = HKHealthStore()
    @Published var isAuthorized = false
    
    func requestAuthorization() async {
        // Everything runs on main thread
    }
}

// AFTER:
actor HealthKitManager: ServiceProtocol {
    private let healthStore = HKHealthStore()
    private var _isAuthorized = false
    
    // Computed property for protocols
    nonisolated var isConfigured: Bool {
        // Use async mechanism if needed
        true
    }
    
    func requestAuthorization() async {
        // Runs on actor
        _isAuthorized = true
        
        // Only notify UI on main
        await MainActor.run {
            NotificationCenter.default.post(...)
        }
    }
}
```

### Step 2: Fix Task { @MainActor in } Patterns
```swift
// ❌ WRONG: Crossing actor boundaries
func someServiceMethod() {
    Task { @MainActor in
        viewModel.updateUI()
    }
}

// ✅ CORRECT: Clear async boundaries
func someServiceMethod() async {
    let data = await fetchData()
    await viewModel.updateUI(with: data)
}
```

## Testing Strategy

### Before Each Service Conversion:
1. Note current functionality
2. Write/update tests if needed
3. Convert to actor
4. Verify same behavior
5. Check for performance improvement

### Performance Validation:
```swift
func testServicePerformance() async {
    let start = CFAbsoluteTimeGetCurrent()
    
    // Run parallel operations
    async let result1 = service.operation1()
    async let result2 = service.operation2()
    async let result3 = service.operation3()
    
    _ = await (result1, result2, result3)
    
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    XCTAssertLessThan(elapsed, 1.0, "Operations should run in parallel")
}
```

## Service Categorization

### ✅ Services That CAN Be Actors
These services don't depend on SwiftData or UI frameworks:
- **NetworkManager** - Pure networking
- **AIAnalyticsService** - Wraps other services
- **MonitoringService** - Performance monitoring
- **WhisperModelManager** - Model management
- **WorkoutSyncService** - Background sync
- **ContextAssembler** - Data assembly
- **HealthKitDataFetcher** - Data fetching
- **HealthKitSleepAnalyzer** - Pure computation

### ❌ Services That MUST Keep @MainActor
These are tightly coupled to SwiftData's ModelContext:
- **UserService** - Direct ModelContext usage
- **GoalService** - SwiftData CRUD operations
- **AnalyticsService** - Stores in SwiftData
- **AIGoalService** - Wraps GoalService
- **AIWorkoutService** - Wraps WorkoutService

### ⚠️ Services Requiring Careful Conversion
These need special handling due to UI integration:
- **HealthKitManager** - @Observable for SwiftUI
- **LLMOrchestrator** - ObservableObject with @Published
- **VoiceInputManager** - Audio + UI state updates

## Priority Order

### Phase 1: Critical Services
1. NetworkManager (already has @preconcurrency)
2. HealthKitManager (lots of dependencies)
3. UserService (core functionality)
4. AIService family (AI*, LLM*)

### Phase 2: Module Services
1. All Coordinator classes (if they don't need @MainActor)
2. Module-specific services
3. Analytics and Monitoring

### Phase 3: Test Cleanup
1. Bulk remove from test classes
2. Add back only where needed
3. Verify test performance improvement

## Success Metrics

- [ ] Services can run operations in parallel
- [ ] App launch time improved (target: <1s)
- [ ] No more `Task { @MainActor in }` patterns
- [ ] Tests run faster (target: 50% improvement)
- [ ] No UI glitches or race conditions

## Code Smells to Avoid

1. **@MainActor on data types**
   ```swift
   @MainActor struct UserData { }  // NO!
   ```

2. **Forcing async to sync**
   ```swift
   MainActor.assumeIsolated { }  // DANGER!
   ```

3. **Over-abstracting**
   ```swift
   // Don't create "MainActorService" base classes
   ```

## Final Checklist

For each @MainActor removal:
- [ ] Does this type update UI? (Keep @MainActor)
- [ ] Is it a ViewModel/Coordinator? (Keep @MainActor)
- [ ] Is it a service/data processor? (Convert to actor)
- [ ] Is it a test? (Remove @MainActor)
- [ ] Are there compiler errors? (Fix properly, don't just add @MainActor back)

Remember: The goal is PERFORMANCE without sacrificing CORRECTNESS. When in doubt, measure!