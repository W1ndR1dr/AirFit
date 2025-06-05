# Dependency Injection Migration Plan

## Overview
This document defines the strategy for migrating AirFit from singleton-based architecture to modern dependency injection.

**Status**: 🚧 IN PROGRESS (2025-06-04)
**Completed**: Core DI system implemented (DIContainer, DIBootstrapper, DIViewModelFactory)

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

### Phase 2: First Module Migration (Dashboard)
**Why Dashboard First**: 
- Well-defined boundaries
- Multiple service dependencies
- Good test coverage exists
- Not too complex

**Steps**:
1. Update DashboardViewModel to use constructor injection
2. Remove singleton access from services
3. Update DashboardView to use DIViewModelFactory
4. Migrate tests to use test container
5. Verify functionality

### Phase 3: Module-by-Module Migration ✅ COMPLETE
**Order** (easiest to hardest):
1. ✅ Dashboard
2. ✅ Settings
3. ✅ Workouts  
4. ✅ Notifications (no ViewModel/View pattern - skipped)
5. ✅ Chat
6. ✅ FoodTracking
7. ⏭️ AI/Onboarding (deferred - most complex)

### Phase 4: Service Layer Cleanup
- Remove ServiceRegistry
- Remove DependencyContainer
- Update remaining .shared usage
- Clean up force unwraps

### Phase 5: Test Migration
- Replace all MockX.shared patterns
- Use DIBootstrapper.createTestContainer()
- Remove test pollution between tests
- Improve test speed

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
6. 🚧 Fix mock compilation errors in test suite
7. 🚧 Migrate tests to use DITestHelper
8. 🚧 Remove DependencyContainer usage (3 files remain)
9. 🚧 Remove ServiceRegistry

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