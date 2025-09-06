# AirFit Architecture Overview

**Last Updated**: 2025-09-03  
**Status**: Active - Core Architecture Reference

## Executive Summary

AirFit is an AI-powered fitness & nutrition tracking app built with SwiftUI, SwiftData, and multi-LLM AI integration. Features Whisper transcription as an optional alternative to Apple's transcription for any text input. The architecture emphasizes modularity, type safety, and performance through lazy dependency injection and clear actor boundaries.

## Architecture Principles

### 1. Lazy Everything
- Services created only when needed (not at app launch)
- Views rendered on-demand
- Models loaded just-in-time
- Target: Fast app launch with responsive UI

### 2. Clear Boundaries
- Modules are self-contained features with no direct dependencies
- Services provide cross-cutting functionality via protocols
- Core layer offers shared utilities and components
- Data layer abstracts persistence (SwiftData + HealthKit)

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
- **Standards**: GlassCard, CascadeText, gradient system (current UI standards)
- **Navigation**: Type-safe coordinator pattern

### 2. Business Logic Layer (ViewModels)
- **Isolation**: @MainActor for UI updates
- **State Management**: @Observable with @Bindable
- **Error Handling**: Unified AppError type
- **Lifecycle**: Proper task cancellation on deinit

### 3. Service Layer
- **Pattern**: ServiceProtocol conformance with consistent lifecycle
- **Concurrency**: Actors for thread safety, @MainActor only when required
- **Isolation**: SwiftData constraints force some services to @MainActor
- **Health**: Built-in health checks and error handling

Key Services:
- **AIService**: Multi-LLM orchestration (actor)
- **HealthKitManager**: Fitness data integration (@MainActor for SwiftData)
- **VoiceInputManager**: WhisperKit transcription (@MainActor for UI)
- **UserService**: User profile management (@MainActor for SwiftData)
- **WorkoutSyncService**: Apple Watch sync (in Workouts module)

### 4. Data Layer
- **Primary**: SwiftData for app-specific data (AI personas, chat history, preferences)
- **Secondary**: HealthKit for health/fitness data (nutrition, workouts, body metrics)
- **Constraint**: SwiftData ModelContext forces @MainActor service isolation
- **Strategy**: Minimize SwiftData usage to maximize actor-based concurrency

### 5. Navigation Layer  
- **Pattern**: BaseCoordinator<Destination, Sheet, Alert> for module navigation
- **Implementation**: Type-safe coordinator pattern with enum-based destinations
- **Coverage**: Core modules use BaseCoordinator, specialized flows use custom patterns
- **Benefits**: Eliminated navigation code duplication, compile-time route validation

## Dependency Injection

Lazy async dependency injection ensures fast app startup and proper service lifecycle management. Factory closures are registered but not executed until services are needed.

**Details**: See [DEPENDENCY_INJECTION.md](./DEPENDENCY_INJECTION.md) for complete implementation patterns.

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

## Concurrency Model

Swift 6 compliant concurrency with clear actor isolation boundaries.

**Details**: See [CONCURRENCY.md](./CONCURRENCY.md) for complete patterns and best practices.

## Error Handling

Unified AppError system provides consistent error handling across all layers with user-friendly messages and recovery suggestions.

**Details**: See [ERROR_HANDLING.md](./ERROR_HANDLING.md) for complete error patterns.

## Performance Strategy

- **App Launch**: Lazy DI system ensures fast startup with minimal blocking operations
- **Runtime**: Actor-based concurrency maximizes throughput, efficient data access patterns
- **Memory**: Careful lifecycle management and cache size limits
- **AI**: Response caching and background processing for smooth user experience

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

## User Interface

Glass morphism design system with pastel gradients, physics-based animations, and premium feel.

**Details**: See [UI.md](./UI.md) for complete design system and component library.

## Key Architectural Decisions

- **Lazy DI**: Factory closures stored, not executed at startup → fast app launch
- **ServiceProtocol**: Consistent service lifecycle and error handling patterns
- **Actor Isolation**: Services as actors except when SwiftData constrains to @MainActor
- **SwiftData Strategy**: Minimize usage, prefer HealthKit for health data
- **Module Boundaries**: Self-contained features with protocol-based communication
- **Type Safety**: Compile-time validation preferred over runtime checks

## Quality Assurance

- **Service Health**: All services implement health check protocols
- **Performance**: Launch time, memory usage, and AI response latency monitoring
- **Testing**: Unit, integration, UI, and performance test coverage
- **Standards**: Zero-warning builds, SwiftLint compliance, actor isolation validation

## Development Guidelines

**For New Developers**: Read [README.md](./README.md) for complete AI agent onboarding sequence.

**Key Patterns**:
- Services implement ServiceProtocol with async configuration
- Modules are self-contained with coordinator-based navigation  
- SwiftData usage minimized in favor of HealthKit where applicable
- Actor isolation maximized except where SwiftData constrains to @MainActor

**Quality Gates**: Zero-warning builds, SwiftLint compliance, proper error handling

## Conclusion

AirFit's architecture balances elegance with pragmatism. Every architectural decision serves our users by ensuring the app is fast, reliable, and delightful to use. The codebase should be a joy to work with - clear, consistent, and well-documented.

**Remember**: Good architecture is invisible to users but invaluable to developers.
---

## Adaptive Nutrition Goals (New)

AirFit adjusts daily nutrition targets based on activity and recent intake. This is implemented by:
- `NutritionGoalServiceProtocol` + `NutritionGoalService` (@MainActor) computing an adjustment percent (clamped to ±15%).
- `DailyNutritionAdjustment` (SwiftData) persists applied targets and rationale per day.
- `DashboardViewModel` uses adjusted targets for Today’s Macro Rings and shows a small note (e.g., “Adjusted +8% based on activity/intake”).

Signals:
- Activity signal: today’s active energy vs baseline (~300 kcal), scaled to ±10%.
- Intake trend: recent 3‑day average vs baseline 2000 kcal, scaled to ±8%.

DI:
- `DIBootstrapper` registers `NutritionGoalService` as a singleton.
- `DIViewModelFactory` injects the service into `DashboardViewModel`.

---

## Streaming Notification Flow (New)

Chat streaming uses a small NotificationCenter bus to deliver deltas to the UI:
- CoachEngine posts `.chatStreamStarted`, `.chatStreamDelta`, `.chatStreamFinished`.
- ChatViewModel maintains an ephemeral `streamingText` buffer and renders a streaming bubble.
- ConversationManager persists the final assistant message and posts `.coachAssistantMessageCreated`, upon which ChatViewModel appends and clears streaming state.

Stop Action:
- Chat exposes a “Stop” button to cancel streaming and persist the partial text as an assistant message.
