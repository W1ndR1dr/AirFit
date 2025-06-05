# Phase 5: Modern Dependency Injection System

## Overview
Implement a modern, lightweight dependency injection system that aligns with Swift and SwiftUI patterns, replacing the legacy singleton-based DependencyContainer.

## Current State
- **Legacy System**: DependencyContainer uses singleton pattern with hardcoded services
- **New System**: DIContainer with async resolution, lifetime management, and test support
- **Status**: Core DI files created, migration in progress

## Completed Work ✅

### Core DI Infrastructure
1. **DIContainer.swift** - Central service registry
   - Protocol-based registration and resolution
   - Three lifetime scopes: singleton, transient, scoped
   - Thread-safe with actor isolation
   - SwiftUI environment integration

2. **DIBootstrapper.swift** - Service configuration
   - Centralized service registration
   - Separate containers for production, test, and preview
   - Async service initialization support
   - User-scoped service factories

3. **DIViewModelFactory.swift** - ViewModel creation
   - Factory pattern for all ViewModels
   - Removes manual dependency wiring
   - Async ViewModel creation support
   - User-specific service injection

4. **DIExample.swift** - Migration patterns
   - Before/after code examples
   - Gradual migration strategy
   - Testing improvements
   - SwiftUI integration patterns

## Migration Strategy

### Phase 1: Core Services (Singletons)
Services that live for the app's lifetime:
- ✅ ModelContainer
- ✅ NetworkClient
- ✅ APIKeyManager (via DefaultAPIKeyManager)
- ✅ LLMOrchestrator
- ✅ AIResponseCache
- ✅ WeatherService
- ✅ NotificationManager
- ✅ ProductionMonitor

### Phase 2: User-Scoped Services
Created per user via factories:
- [ ] CoachEngine
- [ ] PersonaEngine
- [ ] ContextAnalyzer
- [ ] ConversationManager

### Phase 3: Module Services (Transient)
Created fresh for each use:
- [ ] OnboardingService
- [ ] DashboardServices (AICoach, HealthKit, Nutrition)
- [ ] FoodTrackingServices
- [ ] WorkoutService
- [ ] ChatServices

### Phase 4: ViewModels
All ViewModels using constructor injection:
- [ ] OnboardingViewModel
- [ ] DashboardViewModel
- [ ] FoodTrackingViewModel
- [ ] ChatViewModel
- [ ] SettingsViewModel
- [ ] WorkoutViewModel

## Implementation Tasks

### Task 1: Fix Build Issues ✅
- Fixed Swift 6 concurrency warnings
- Updated service initializations
- Resolved async/await patterns

### Task 2: Update Application Layer
```swift
// In AirFitApp.swift
@main
struct AirFitApp: App {
    @State private var container: DIContainer?
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    ContentView()
                        .environment(\.diContainer, container)
                        .environmentObject(DIViewModelFactory(container: container))
                } else {
                    LoadingView()
                }
            }
            .task {
                do {
                    container = try await DIBootstrapper.createAppContainer(
                        modelContainer: Self.sharedModelContainer
                    )
                } catch {
                    // Handle initialization error
                }
            }
        }
    }
}
```

### Task 3: Migrate First Module (Dashboard)
```swift
// DashboardView.swift
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: DashboardViewModel())
    }
    
    var body: some View {
        // Existing implementation
    }
}

// After migration:
struct DashboardView: View {
    var body: some View {
        DashboardContent()
            .withViewModel { factory in
                try await factory.makeDashboardViewModel()
            }
    }
}

private struct DashboardContent: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    // Existing implementation
}
```

### Task 4: Update Tests
```swift
// Before:
class DashboardViewModelTests: XCTestCase {
    func testSomething() {
        let viewModel = DashboardViewModel()
        // Test with real dependencies
    }
}

// After:
class DashboardViewModelTests: XCTestCase {
    var container: DIContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        container = try await DIBootstrapper.createTestContainer()
    }
    
    func testSomething() async throws {
        let factory = DIViewModelFactory(container: container)
        let viewModel = try await factory.makeDashboardViewModel()
        // Test with mocked dependencies
    }
}
```

## Benefits

### For Testing
- Complete isolation with test containers
- Easy mock injection
- No singleton state pollution
- Parallel test execution

### For Development
- Clear dependency graphs
- Compile-time safety
- No manual wiring
- Easy to add new services

### For Production
- Lazy initialization
- Memory efficiency
- Clear service lifetimes
- Better error handling

## Migration Order

1. **Dashboard Module** (simplest, good test case)
2. **Settings Module** (minimal dependencies)
3. **Chat Module** (moderate complexity)
4. **FoodTracking Module** (voice services)
5. **Workouts Module** (HealthKit integration)
6. **Onboarding Module** (complex, many services)

## Success Criteria

- [ ] All ViewModels use constructor injection
- [ ] No business logic accesses singletons directly
- [ ] All tests use DIBootstrapper.createTestContainer()
- [ ] Legacy DependencyContainer removed
- [ ] Documentation updated
- [ ] Performance targets maintained

## Remaining Singletons (Acceptable)

These remain as singletons for valid reasons:
- **AppLogger** - Global logging infrastructure
- **AppState** - Top-level app state
- **KeychainWrapper** - System resource wrapper
- **HapticManager** - Device hardware access
- **NetworkReachability** - System network monitoring

## Next Steps

1. Fix remaining build issues in DIBootstrapper
2. Implement application layer changes
3. Migrate Dashboard module as proof of concept
4. Create migration guide for other modules
5. Update CLAUDE.md with DI patterns
6. Remove legacy DependencyContainer

## Time Estimate: 5 days

- Fix build issues: 0.5 days ✅
- Application layer: 0.5 days
- Dashboard migration: 1 day
- Other modules: 2 days
- Testing updates: 1 day
- Documentation: 0.5 days
- Cleanup: 0.5 days

This provides a solid foundation for testable, maintainable code without the pitfalls of singleton abuse.