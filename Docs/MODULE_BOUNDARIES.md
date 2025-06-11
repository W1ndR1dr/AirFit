# Module Boundaries and Architecture

**Created**: 2025-06-09  
**Author**: World-Class Senior iOS Developer  
**Purpose**: Define clear module boundaries and dependencies for AirFit

## Overview

AirFit follows a modular architecture with clear boundaries between features. Each module is self-contained with its own models, views, view models, and services.

## Module Structure

```
AirFit/
├── Application/          # App entry point and global configuration
├── Core/                 # Shared foundation (no feature-specific code)
├── Data/                 # SwiftData models and persistence
├── Services/             # Cross-cutting services (AI, HealthKit, etc.)
└── Modules/              # Feature modules
    ├── Dashboard/
    ├── Chat/
    ├── FoodTracking/
    ├── Workouts/
    ├── Onboarding/
    ├── Settings/
    └── Notifications/
```

## Core Module Principles

### 1. Self-Containment
Each module should contain everything needed for its feature:
- **Models**: Feature-specific data structures
- **Views**: All UI components for the feature
- **ViewModels**: Business logic and state management
- **Services**: Feature-specific services (not shared)
- **Coordinators**: Navigation within the module

### 2. Clear Dependencies

#### Allowed Dependencies
- Modules → Core (utilities, base types, protocols)
- Modules → Services (shared services like AI, HealthKit)
- Modules → Data (SwiftData models)

#### Forbidden Dependencies
- Module → Module (no direct dependencies between features)
- Core → Modules (core should never depend on features)
- Services → Modules (services should be feature-agnostic)

### 3. Communication Patterns

#### Between Modules
Use coordinators and completion handlers:
```swift
// Good - Dashboard launching FoodTracking
coordinator.showFoodTracking { result in
    // Handle result
}

// Bad - Direct module reference
let foodVM = FoodTrackingViewModel()
```

#### Data Sharing
Use SwiftData models or service interfaces:
```swift
// Good - Through data layer
let workouts = try await dataManager.fetchWorkouts()

// Bad - Direct module data access
let workouts = workoutModule.workouts
```

## Module Catalog

### AI Module 🆕
**Purpose**: AI coach intelligence, LLM orchestration, function calling  
**Dependencies**: AIService, LLMProviders, GoalService, various data models  
**Exports**: CoachEngine (used by Chat, Dashboard, Onboarding)  
**Note**: Central AI brain - exception to leaf module rule

### Dashboard Module
**Purpose**: Main screen, quick actions, summary views  
**Dependencies**: All services, navigation to other modules, CoachEngine  
**Exports**: Nothing (leaf module)

### Chat Module  
**Purpose**: AI coach interaction, conversation history  
**Dependencies**: AIService, UserService, ChatSession model, CoachEngine  
**Exports**: Nothing (leaf module)

### FoodTracking Module
**Purpose**: Food logging, nutrition tracking, voice input  
**Dependencies**: NutritionService, VoiceInputManager, FoodEntry model  
**Exports**: Nothing (leaf module)

### Workouts Module
**Purpose**: Workout planning, execution, history  
**Dependencies**: WorkoutService, HealthKitManager, Workout model  
**Exports**: Nothing (leaf module)

### Onboarding Module
**Purpose**: User onboarding, persona generation  
**Dependencies**: OnboardingService, PersonaService, User model  
**Exports**: Nothing (leaf module)  
**Note**: Most complex module with 10 internal services

### Settings Module
**Purpose**: App configuration, user preferences  
**Dependencies**: UserService, APIKeyManager, User model  
**Exports**: Nothing (leaf module)

### Notifications Module
**Purpose**: Push notifications, engagement tracking  
**Dependencies**: NotificationManager, EngagementEngine  
**Exports**: Nothing (leaf module)  
**Note**: Not a navigation module, more of a service wrapper

## Data Layer Architecture Decision

### SwiftData Models as Shared Layer
After careful analysis, we've made an explicit architectural decision:

**Decision**: SwiftData models (in Data/) form a shared data layer that all modules can access.

**Rationale**:
1. SwiftData relationships require model awareness
2. Creating DTOs for every cross-module interaction adds complexity
3. The User model naturally connects different aspects of the app
4. This mirrors common iOS architecture patterns

**Implications**:
- Models in Data/ are NOT subject to module boundary restrictions
- Modules can have relationships through shared models
- This is the ONLY exception to the "no cross-module dependencies" rule

**Best Practices**:
- Keep business logic in modules, not in models
- Models should be primarily data containers
- Use computed properties sparingly in models
- Complex operations belong in services

## Service Layer Boundaries

### Shared Services (in Services/)
These are used across multiple modules:
- **AIService**: LLM integration, shared by Chat, Onboarding, Dashboard
- **HealthKitManager**: Health data, shared by Workouts, Dashboard, FoodTracking
- **UserService**: User management, used everywhere
- **NetworkManager**: API communication, used by all services

### Module-Specific Services
These should stay within their modules:
- **OnboardingOrchestrator**: Only used in Onboarding
- **ChatHistoryManager**: Only used in Chat
- **WorkoutBuilder**: Only used in Workouts
- **NutritionCalculator**: Only used in FoodTracking

## Boundary Violations Fixed ✅

### 1. ~~Cross-Module View Imports~~ ✅ None Found
Verified no modules import views/viewmodels from other modules.

### 2. ~~Service Leakage~~ ✅ Fixed
- **WorkoutSyncService**: Moved to `/Modules/Workouts/Services/` (2025-06-10)
- **GoalService**: Remains in global Services/ (used by AI module, but AI exports CoachEngine)

### 3. ~~Model Coupling~~ ✅ Documented Decision
SwiftData models are explicitly allowed as a shared layer (see Data Layer Architecture Decision above).

## Best Practices

### 1. Use Protocols for Contracts
```swift
// Define in Core/Protocols
protocol FoodLoggingCoordinatorProtocol {
    func showFoodLogging(completion: @escaping (FoodEntry?) -> Void)
}
```

### 2. Coordinator-Based Navigation
```swift
// Module exposes only its coordinator
public final class FoodTrackingCoordinator: BaseCoordinator<...> {
    // Navigation API
}
```

### 3. Service Injection
```swift
// Inject only what's needed
init(nutritionService: NutritionServiceProtocol) {
    // Not the entire DIContainer
}
```

### 4. Data Transfer Objects
When passing data between modules, use simple DTOs:
```swift
// Good - Simple data structure
struct FoodLogSummary {
    let calories: Int
    let protein: Double
}

// Bad - Exposing internal models
var foodEntry: FoodEntry // Internal model leaked
```

## Module Refactoring Opportunities

### High Priority
1. **Extract module-specific services** from Services/ to their modules
2. **Remove cross-module imports** by using coordinator navigation
3. **Standardize coordinator APIs** for consistent module interfaces

### Medium Priority  
1. **Consolidate Onboarding services** (10 → 3-4 services)
2. **Create service protocols** in Core for better contracts
3. **Reduce SwiftData model coupling** with DTOs

### Low Priority
1. **Add module-level README** files
2. **Create module dependency graphs**
3. **Add module-level tests**

## Enforcement

### Build Time
- SwiftLint rules to prevent cross-module imports
- Compiler flags to enforce module boundaries

### Code Review
- Check for boundary violations
- Ensure new features follow module principles
- Verify service placement (shared vs module-specific)

## Future Considerations

### Module Extraction
As modules grow, consider extracting them into packages:
- Better build times
- Enforced boundaries
- Potential for reuse

### Feature Flags
Add feature flag support for:
- A/B testing module variations
- Gradual rollouts
- Module-level kill switches

## Summary

Clear module boundaries lead to:
- ✅ Faster development (work in isolation)
- ✅ Easier testing (mock dependencies)
- ✅ Better performance (lazy loading)
- ✅ Cleaner architecture (no spaghetti)
- ✅ Team scalability (parallel development)

Remember: **A module should be a black box. You should be able to understand what it does without looking inside.**