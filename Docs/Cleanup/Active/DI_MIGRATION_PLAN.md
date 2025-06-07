# Dependency Injection Migration Plan

## Overview
This document defines the strategy for migrating AirFit from singleton-based architecture to modern dependency injection.

**Status**: ✅ COMPLETE (2025-06-05)
**Completed**: All modules migrated to DI, including complex Onboarding module

## Core Principles

### 1. Pragmatic Approach
- Keep true singletons where appropriate (system resources)
- Don't over-engineer - Swift isn't Java
- Align with SwiftUI patterns (Environment)
- Gradual migration - don't break working code

### 2. What to Include in DI
✅ **INCLUDE**:
- All services with business logic
- ViewModels and their dependencies
- Anything that needs mocking for tests
- User-scoped services (CoachEngine, PersonaEngine)
- Cross-cutting concerns (logging, analytics)

### 3. What to Exclude from DI
❌ **EXCLUDE** (Keep as Singletons):
- `KeychainWrapper` - True system resource wrapper
- `AppLogger` - Stateless utility, needs global access
- `HapticManager` - UI utility, stateless
- `WhisperKit` - Heavy ML model, must be singleton
- `RoutingConfiguration` - App-wide configuration
- Pure utility extensions (Date+Helpers, String+Helpers)
- SwiftUI Environment values

## Migration Strategy

### Phase 1: Foundation ✅ COMPLETE
- Created DIContainer.swift
- Created DIBootstrapper.swift  
- Created DIViewModelFactory.swift
- Created DIExample.swift with patterns

### Phase 2: Module Migration Progress
**Status**: ✅ COMPLETE - All 6 modules migrated (2025-06-05)

✅ **Completed Modules**:
1. Dashboard - Well-defined boundaries, good example
2. FoodTracking - Complex dependencies, good DI showcase  
3. Chat - Message handling, AI integration
4. Settings - User preferences, configuration
5. Workouts - Exercise tracking, templates
6. Onboarding - Complex flow with coordinator pattern, migrated successfully

**Note**: Notifications module has no ViewModel/View pattern, so DI migration is N/A

### Phase 3: Test Suite Migration
**Status**: 🚧 IN PROGRESS (2025-06-05) - Only 2 test files migrated

**Key Issues**:
- Tests accessing private APIs after refactoring
- Mock pattern mismatches with new DI
- Initialization signature changes
- Protocol vs concrete type expectations

**Migration Steps**:
1. **Test Infrastructure** (Prerequisites)
   - Update mock pattern to support DI (property injection → constructor injection)
   - Create test-specific DIContainer configurations
   - Add protocol-based initializers where needed

2. **Core Module Tests** (Priority 1)
   - FoodTrackingViewModelTests: Refactor to use public APIs
   - NutritionParsingRegressionTests: Update initializers
   - Create factory methods for test scenarios

3. **Integration Tests** (Priority 2)
   - Update to use full DI initialization
   - Mock at service boundaries, not internals
   - Test complete flows, not implementation details

4. **Onboarding Tests** (After module migration)
   - Complete onboarding DI migration first
   - Update all onboarding tests together
   - Maintain test coverage during migration
5. Verify functionality

### Phase 3: Module-by-Module Migration ✅ COMPLETE
**Order** (easiest to hardest):
1. ✅ Dashboard
2. ✅ Settings
3. ✅ Workouts  
4. ⏭️ Notifications (no ViewModel/View pattern - N/A)
5. ✅ Chat
6. ✅ FoodTracking
7. ✅ AI/Onboarding (most complex - completed successfully)

### Phase 4: Service Layer Cleanup ✅ COMPLETE
- ✅ ServiceRegistry marked as deprecated (kept for test compatibility)
- ✅ DependencyContainer marked as deprecated (kept for Onboarding compatibility)
- ✅ DIViewModelFactory duplicate makeFoodTrackingViewModel removed
- ✅ Update remaining .shared usage (ExerciseDatabase and WorkoutSyncService now injected via DI)
- ✅ WorkoutViewModel updated to use DI for all dependencies
- ✅ DIBootstrapper and DIViewModelFactory updated to register/inject these services

### Phase 5: Test Migration 🚧 IN PROGRESS
- ✅ Test compilation errors fixed using automated scripts
- ✅ DITestHelper.createTestContainer() properly implemented with mock registrations
- ✅ Fixed async setUp() issues in test files (converted to setupTest() pattern)
- ✅ Fixed duplicate @MainActor attributes
- ✅ Updated DITestHelper to properly register all mock services
- ❌ Replace all MockX.shared patterns (most tests still use old patterns)
- ✅ DIBootstrapper+Test.swift created with createMockContainer for UI testing
- ✅ DITestHelper exists and used by 2 test files (Dashboard, NutritionParsing)
- ❌ Remove test pollution between tests
- ❌ Improve test speed

## Registration Patterns

### 1. Singleton Services
```swift
// For app-lifetime services
container.register(WeatherServiceProtocol.self, lifetime: .singleton) { _ in
    WeatherService()
}
```

### 2. Transient Services  
```swift
// For per-use services (ViewModels, module services)
container.register(NutritionServiceProtocol.self) { container in
    let modelContext = try await container.resolve(ModelContext.self)
    return NutritionService(modelContext: modelContext)
}
```

### 3. User-Scoped Services
```swift
// Created in ViewModelFactory per-user
let coachEngine = CoachEngine(/* user-specific deps */)
```

### 4. Named Registrations
```swift
// For multiple implementations
container.register(AIServiceProtocol.self, name: "offline") { _ in
    OfflineAIService()
}
```

## Service Categories

### Core Services (Singletons)
- APIKeyManager
- NetworkClient  
- LLMOrchestrator
- WeatherService
- HealthKitManager (via .shared)
- NotificationManager (via .shared)

### Module Services (Transient)
- NutritionService
- WorkoutService
- AnalyticsService
- Module-specific ViewModels

### User-Scoped Services (Factory-Created)
- CoachEngine
- PersonaEngine
- ConversationManager
- AICoachService

### Keep as Singletons (Not in DI)
- KeychainWrapper.shared
- AppLogger.shared
- HapticManager.shared
- DataManager.shared (until refactored)

## ViewModel Patterns

### Before (Singleton Access)
```swift
class DashboardViewModel {
    init() {
        self.apiKeyManager = APIKeyManager.shared
        self.healthKit = HealthKitManager.shared
    }
}
```

### After (Constructor Injection)
```swift
class DashboardViewModel {
    init(
        apiKeyManager: APIKeyManagementProtocol,
        healthKitService: HealthKitService,
        // ... other deps
    ) {
        self.apiKeyManager = apiKeyManager
        self.healthKitService = healthKitService
    }
}
```

## View Patterns

### Before (Manual Creation)
```swift
struct DashboardView: View {
    @State private var viewModel: DashboardViewModel?
    
    var body: some View {
        if let viewModel {
            // content
        } else {
            ProgressView().task {
                // Manual wiring of 6+ dependencies
            }
        }
    }
}
```

### After (DI Factory)
```swift
struct DashboardView: View {
    let user: User
    
    var body: some View {
        DashboardContent()
            .withViewModel { factory in
                try await factory.makeDashboardViewModel(user: user)
            }
    }
}
```

## Testing Patterns

### Before (Singleton Pollution)
```swift
class DashboardTests: XCTestCase {
    override func tearDown() {
        // Complex singleton cleanup
        APIKeyManager.shared.reset()
        // Hope nothing leaked...
    }
}
```

### After (Clean DI)
```swift
class DashboardTests: XCTestCase {
    var container: DIContainer!
    
    override func setUp() {
        container = DIBootstrapper.createTestContainer()
    }
    
    func testSomething() async {
        let factory = DIViewModelFactory(container: container)
        let vm = try await factory.makeDashboardViewModel(user: .mock)
        // Clean, isolated test
    }
}
```

## Special Cases

### 1. ModelContext
- Not Sendable, needs careful handling
- Always use mainContext from ModelContainer
- Pass through DI but access carefully

### 2. @MainActor Services
- HealthKitService, DashboardNutritionService, etc.
- Initialize with `await` in factories
- Keep actor isolation correct

### 3. Heavy Resources
- WhisperKit models - keep singleton
- CoreML models - keep singleton
- Large caches - evaluate case by case

### 4. SwiftUI Previews
```swift
.task {
    let container = try? await DIBootstrapper.createPreviewContainer()
}
.withDIContainer(container)
```

## Migration Checklist

For each module:
- [ ] Identify all dependencies
- [ ] Update ViewModel to constructor injection
- [ ] Create/update factory method in DIViewModelFactory
- [ ] Update View to use .withViewModel
- [ ] Migrate unit tests to use test container
- [ ] Update previews to use preview container
- [ ] Remove singleton access
- [ ] Test thoroughly
- [ ] Document any special cases

## Success Metrics

1. **No more .shared in ViewModels** (except approved list)
2. **All ViewModels created via factory**
3. **Tests run faster and in isolation**
4. **Clear dependency graphs**
5. **Easy to add new implementations**

## Common Pitfalls to Avoid

1. **Don't force everything into DI** - Some singletons are fine
2. **Don't create protocols just for DI** - Use concrete types when there's only one implementation
3. **Don't forget @MainActor** - Many services need it
4. **Don't use synchronous resolution** - Always use async/await
5. **Don't register user-specific services globally** - Use factories

## Next Immediate Steps

1. ✅ Fixed build issues with AIServiceProtocol Sendable conformance
2. ✅ Created DI integration for Dashboard
3. ✅ Discovered @Observable incompatibility with withViewModel helper
4. ✅ Migrated all 6 viable modules to DI (AI/Onboarding deferred)
5. ✅ Removed UnifiedOnboardingView and MinimalContentView (cleanup)
6. ✅ Fix mock compilation errors in test suite
7. 🚧 Migrate tests to use DITestHelper
8. ✅ Marked DependencyContainer as deprecated (kept for Onboarding compatibility)
9. ✅ Marked ServiceRegistry as deprecated (kept for test compatibility)
10. ✅ Removed ServiceLocator pattern from ServiceConfiguration
11. 🚧 Complete AI/Onboarding migration when ready

## @Observable Migration Pattern

Since ViewModels use the new `@Observable` macro instead of `ObservableObject`, the withViewModel helper doesn't work. Instead, use this pattern:

```swift
struct DashboardView: View {
    let user: User
    @State private var viewModel: DashboardViewModel?
    @Environment(\.diContainer) private var container
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                DashboardContent(user: user, viewModel: viewModel)
            } else {
                ProgressView()
                    .task {
                        let factory = DIViewModelFactory(container: container)
                        viewModel = try? await factory.makeDashboardViewModel(user: user)
                    }
            }
        }
    }
}
```

## Questions for Later

1. Should we create a @StateObject wrapper for async ViewModel creation?
2. Should module services be singleton or transient?
3. How to handle deep linking with DI?
4. Preview performance with full DI setup?

## Actual Status Summary (2025-06-05)

### ✅ Completed
- Core DI infrastructure (DIContainer, DIBootstrapper, DIViewModelFactory)
- All 7 modules migrated to DI including complex Onboarding
- DIBootstrapper+Test.swift for UI testing support
- DITestHelper.createTestContainer() properly implemented
- Deprecated markers on old systems
- Service layer cleanup complete (all .shared usage now injected via DI)
- Test suite compilation errors fixed
- Duplicate makeFoodTrackingViewModel removed
- OnboardingFlowCoordinator integrated with DI
- OnboardingContainerView and OnboardingFlowViewDI created
- ContentView updated to use DI-based onboarding

### ❌ Not Completed
- Full test suite migration to DITestHelper pattern (most tests still use old patterns)
- Remove test pollution between tests
- Improve test speed
- Remove deprecated DependencyContainer and ServiceRegistry (kept for compatibility)

### 📊 Overall Progress: ~95% Complete
The main app fully works with DI including all modules. Only complete test migration and cleanup of deprecated systems remain.