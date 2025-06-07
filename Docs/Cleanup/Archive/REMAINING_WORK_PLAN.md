# Remaining Work Plan

## Current Status (2025-06-05)
- ✅ DI system implemented and 6/7 modules migrated
- ✅ Test suite errors resolved (~237 fixed)
- ✅ Major architectural improvements complete
- ✅ Created comprehensive mocks for all test dependencies
- ✅ Fixed all mock ambiguity issues
- ✅ Fixed concurrency issues in tests
- 🆕 Created HealthKit Nutrition Integration Plan
- 🆕 Created WorkoutKit Integration Plan

## Immediate Tasks

### 1. HealthKit Integration (High Priority)
**Nutrition Integration** - See `/Docs/HEALTHKIT_NUTRITION_INTEGRATION_PLAN.md`
- [ ] Clean up conflicting code
  - Remove duplicate HKHealthStore in NutritionService
  - Remove incomplete syncCaloriesToHealthKit method
  - Fix/remove placeholder water tracking
- [ ] Update HealthKitDataTypes.swift with nutrition permissions
- [ ] Add nutrition write methods to HealthKitManager
- [ ] Update NutritionService to write to HealthKit
- [ ] Add HealthKit reference fields to data models

**Workout Integration** - See `/Docs/WORKOUTKIT_INTEGRATION_PLAN.md`
- [ ] Clean up conflicting code
  - Remove CloudKit sync from WorkoutSyncService
  - Remove manual calorie calculations
- [ ] Add workout write methods to HealthKitManager
- [ ] Update WorkoutService to write to HealthKit
- [ ] Implement WorkoutKit for iOS 17+ features
- [ ] Fix Watch sync to include HealthKit IDs

### 2. Complete AI/Onboarding Module DI Migration
- [ ] Migrate CoachEngine to use DI
- [ ] Migrate ConversationManager to use DI
- [ ] Migrate PersonaEngine to use DI
- [ ] Update OnboardingViewModel to use DI factory
- [ ] Remove direct service instantiation

### 3. Remove Legacy Code
- [ ] Remove DependencyContainer (3 files remaining)
  - ContentView.swift
  - OnboardingCoordinator.swift
  - OnboardingFlowCoordinator.swift
- [ ] Remove ServiceRegistry entirely
- [ ] Clean up any remaining singleton usage

### 4. Test Suite Stabilization
- [ ] Run full test suite and fix runtime failures
- [ ] Update tests to use DITestHelper pattern
- [ ] Fix any remaining mock service issues
- [ ] Ensure all tests pass consistently

### 5. Test Coverage Implementation
- [ ] Achieve 80% coverage for ViewModels
- [ ] Achieve 80% coverage for Services
- [ ] Achieve 90% coverage for Utilities
- [ ] Add integration tests for DI system
- [ ] Add UI tests for critical flows

## Technical Details

### DI Migration Pattern
```swift
// Old pattern
let service = WeatherService()

// New pattern
@Environment(\.diContainer) var container
let factory = DIViewModelFactory(container: container)
let viewModel = try await factory.makeViewModel()
```

### Test Pattern
```swift
// Create test container
let container = DIBootstrapper.createTestContainer()
let factory = DIViewModelFactory(container: container)

// Override specific services
await container.register(MockService(), for: ServiceProtocol.self, lifetime: .singleton)
```

## Success Criteria
- Zero compilation errors in test suite
- All modules using DI (no DependencyContainer usage)
- ServiceRegistry removed
- 80%+ test coverage achieved
- All tests passing consistently