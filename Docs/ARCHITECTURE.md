# AirFit Architecture Overview

**Last Updated**: 2025-06-10  
**Architecture Version**: 3.2  
**Status**: Production-Ready

## Executive Summary

AirFit is a voice-first AI-powered fitness & nutrition tracking app built with SwiftUI, SwiftData, and multi-LLM AI integration. The architecture emphasizes modularity, type safety, and performance through lazy dependency injection and clear actor boundaries.

## Architecture Principles

### 1. Lazy Everything
- Services created only when needed (not at app launch)
- Views rendered on-demand
- Models loaded just-in-time
- Result: <0.5s app launch time

### 2. Clear Boundaries
- Modules are self-contained features
- Services are cross-cutting concerns  
- Core provides shared utilities
- Data layer handles persistence

### 3. Type Safety First
- Strongly typed navigation with coordinators
- Type-safe dependency injection
- Compile-time validation where possible
- Runtime checks as last resort

### 4. Performance Conscious
- @MainActor only where required (UI)
- Services as actors for thread safety
- Efficient SwiftData queries
- Optimized AI response caching

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                         │
├─────────────────────────────────────────────────────────────┤
│                   ViewModels (@MainActor)                    │
├─────────────────────────────────────────────────────────────┤
│   Coordinators    │         Services (Actors)               │
├───────────────────┼─────────────────────────────────────────┤
│                      SwiftData Models                        │
├─────────────────────────────────────────────────────────────┤
│               Core Utilities & Extensions                    │
└─────────────────────────────────────────────────────────────┘
```

## Component Layers

### 1. Presentation Layer (Views)
- **Technology**: SwiftUI, iOS 18.0+
- **Patterns**: MVVM with @Observable ViewModels
- **Standards**: StandardButton, StandardCard, BaseScreen (Phase 3.3)
- **Navigation**: Type-safe coordinator pattern

### 2. Business Logic Layer (ViewModels)
- **Isolation**: @MainActor for UI updates
- **State Management**: @Observable with @Bindable
- **Error Handling**: Unified AppError type
- **Lifecycle**: Proper task cancellation on deinit

### 3. Service Layer
- **Pattern**: ServiceProtocol conformance (100% adoption)
- **Concurrency**: Actors for thread safety
- **Initialization**: Async configure() pattern
- **Health**: Built-in health checks

Key Services:
- **AIService**: Multi-LLM orchestration (actor)
- **HealthKitManager**: Fitness data integration (@MainActor for SwiftData)
- **VoiceInputManager**: WhisperKit transcription (@MainActor for UI)
- **UserService**: User profile management (@MainActor for SwiftData)
- **WorkoutSyncService**: Apple Watch sync (in Workouts module)

### 4. Data Layer
- **Technology**: SwiftData with migrations
- **Models**: @Model classes with relationships
- **Constraints**: @MainActor for ModelContext
- **Sync**: HealthKit as source of truth where applicable

### 5. Navigation Layer  
- **Pattern**: BaseCoordinator<Destination, Sheet, Alert>
- **Implementation**: 5 coordinators use BaseCoordinator, 1 uses SimpleCoordinator
- **Benefits**: 500+ lines of duplicate code removed
- **Type Safety**: Compile-time navigation validation
- **Note**: NotificationsCoordinator and flow coordinators are state machines, not navigation

## Dependency Injection

### Perfect Lazy Pattern (Phase 1.3)
```swift
container.register(ServiceProtocol.self, lifetime: .singleton) { resolver in
    // This closure is stored, NOT executed during registration!
    await MyService(dependency: await resolver.resolve(DependencyProtocol.self))
}
```

### Key Features:
- Zero startup cost (closures stored, not executed)
- Async resolution throughout
- No singletons or static dependencies
- Type-safe with compile-time checks

## Module Architecture

### Module Structure
Each feature module contains:
```
Module/
├── Models/        # Feature-specific data types
├── Views/         # SwiftUI views
├── ViewModels/    # Business logic
├── Services/      # Module-specific services
└── Coordinators/  # Navigation handling
```

### Current Modules:
1. **AI** - Core intelligence engine (CoachEngine, function calling)
2. **Dashboard** - Main screen and summaries
3. **Chat** - AI coach interaction
4. **FoodTracking** - Nutrition logging with voice
5. **Workouts** - Exercise planning and tracking
6. **Onboarding** - User setup and persona generation
7. **Settings** - Configuration and preferences
8. **Notifications** - Engagement and reminders
9. **AirFitWatchApp** - Apple Watch companion app (basic implementation)

### Module Communication:
- No direct module-to-module dependencies
- Communication through coordinators
- Data sharing via SwiftData models
- Events through NotificationCenter (sparingly)

## AI Architecture

### Multi-Provider Support
```
User Request → AIService → LLMOrchestrator → Provider
                    ↓                      ├── OpenAI
              DemoAIService               ├── Anthropic
             (when demo mode)             └── Gemini
```

### Concurrency Design:
- **LLMOrchestrator**: Heavy operations are `nonisolated` for performance
- **FunctionCallDispatcher**: @MainActor for ModelContext safety
- **DemoAIService**: Actor-based for thread-safe demo responses
- **SendableValue**: Type-safe cross-actor data transfer

### Key Features:
- Automatic fallback between providers
- Response caching for performance
- Function calling for actions
- Streaming support for real-time responses

### Persona System:
- Dynamic coach personalities
- Context-aware responses
- Conversation memory
- Goal-oriented interactions

## Concurrency Model (Phase 2.2)

### Actor Boundaries
- **Services**: Actors (except SwiftData-dependent)
- **ViewModels**: @MainActor
- **Views**: @MainActor (implicit)
- **Models**: Sendable where possible

### Best Practices:
- No Task in init() - use configure()
- Proper task cancellation in ViewModels
- Avoid unnecessary Task wrappers
- Error handling at boundaries

## Error Handling

### Unified AppError Type
```swift
enum AppError: LocalizedError {
    case network(NetworkError)
    case database(DatabaseError)
    case validation(ValidationError)
    case ai(AIError)
    // ... comprehensive error cases
}
```

### Features:
- User-friendly descriptions
- Recovery suggestions  
- Detailed debug info
- Proper error propagation

## Performance Optimizations

### App Launch (<0.5s)
- Lazy DI system
- No blocking operations
- Minimal initial UI
- Background service configuration

### Runtime Performance
- Efficient SwiftData queries
- AI response caching
- Image loading optimization
- Background task management

### Memory Management
- Proper model lifecycle
- Cache size limits
- Background memory warnings
- Efficient data structures

## Testing Architecture

### Test Pyramid
1. **Unit Tests** - Service and ViewModel logic
2. **Integration Tests** - Module interactions
3. **UI Tests** - Critical user flows
4. **Performance Tests** - Launch time, memory

### Mock System
- Protocol-based mocking
- Consistent mock implementations
- Test-specific DI container
- Deterministic test data

## Security Architecture

### Data Protection
- Keychain for sensitive data
- Encrypted API keys
- No hardcoded secrets
- Secure user defaults

### Network Security
- Certificate pinning ready
- Request signing
- API key rotation support
- Timeout enforcement

## Future Architecture (Phase 3.3)

### UI Excellence
- Glass morphism design system
- Pastel gradient themes
- Physics-based animations
- 120Hz optimization

### Technical Debt
- Manager consolidations
- Service simplification
- SwiftData relationship optimization
- Test coverage improvement

## Architecture Decision Records

### ADR-001: Lazy DI over Eager
**Decision**: Store factory closures, not instances  
**Rationale**: Eliminated app launch delays  
**Status**: Implemented in Phase 1.3

### ADR-002: ServiceProtocol for All Services
**Decision**: Every service implements ServiceProtocol  
**Rationale**: Consistent lifecycle and error handling  
**Status**: 100% adoption in Phase 2.1

### ADR-003: BaseCoordinator Pattern
**Decision**: Generic base coordinator for navigation  
**Rationale**: Eliminate duplicate navigation code  
**Status**: Implemented in Phase 3.1

### ADR-004: @MainActor Minimization
**Decision**: Only ViewModels and UI on main actor  
**Rationale**: Better performance and concurrency  
**Status**: Significantly reduced (services are actors except SwiftData-dependent)

### ADR-005: SwiftData Models as Shared Layer
**Decision**: Data models form an explicit shared layer  
**Rationale**: Modules can share data without direct dependencies  
**Status**: Established pattern

### ADR-006: Nonisolated AI Operations
**Decision**: Make heavy AI operations nonisolated while keeping UI updates @MainActor  
**Rationale**: Prevents UI blocking during AI processing, improves performance  
**Status**: Standard pattern for AI services

### ADR-007: Demo Mode at DI Level
**Decision**: Implement demo mode through DI container, not runtime checks  
**Rationale**: Zero overhead when disabled, clean separation of concerns  
**Status**: Available via AppConstants.Configuration.isUsingDemoMode

## Monitoring and Metrics

### Key Metrics Tracked
- App launch time
- Service initialization time
- AI response latency
- Memory usage
- Crash rate

### Health Checks
- All services report health status
- Background monitoring
- Automatic error reporting
- Performance profiling

## Getting Started

### For New Developers
1. Read MODULE_BOUNDARIES.md
2. Study DI_STANDARDS.md  
3. Review ServiceProtocol pattern
4. Understand coordinator navigation

### Adding a New Feature
1. Create module structure
2. Define service protocols
3. Implement with ServiceProtocol
4. Add coordinator for navigation
5. Register in DIBootstrapper

### Common Pitfalls
- Don't create singletons
- Don't add unnecessary @MainActor
- Don't couple modules directly
- Don't skip error handling

## Conclusion

AirFit's architecture balances elegance with pragmatism. Every architectural decision serves our users by ensuring the app is fast, reliable, and delightful to use. The codebase should be a joy to work with - clear, consistent, and well-documented.

**Remember**: Good architecture is invisible to users but invaluable to developers.