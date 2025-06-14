# @unchecked Sendable Analysis Report

## Executive Summary

Analysis of @unchecked Sendable usage in AirFit services reveals 9 service-level occurrences (excluding test files and data models). The primary pattern is using @unchecked Sendable to bypass Swift's strict concurrency checking while managing internal state synchronization. Most cases can be refactored to proper actors, which would provide compile-time safety and better performance characteristics.

## Service Analysis

### 1. AIService.swift (Line 33)
**Status**: Production AI service  
**Current State**:
```swift
final class AIService: AIServiceProtocol, @unchecked Sendable {
    private(set) var isConfigured: Bool = false
    private(set) var activeProvider: AIProvider = .anthropic
    private(set) var availableModels: [AIModel] = []
    private(set) var totalCost: Double = 0
```

**Why @unchecked Sendable**: 
- Mutable state properties (isConfigured, activeProvider, totalCost)
- No internal synchronization mechanism visible
- ServiceProtocol requires Sendable conformance

**Recommendation**: Convert to actor
```swift
actor AIService: AIServiceProtocol {
    // State management becomes thread-safe automatically
}
```

### 2. BiometricAuthManager.swift (Line 5)
**Status**: Settings module service  
**Current State**:
```swift
final class BiometricAuthManager: ServiceProtocol, @unchecked Sendable {
    private var _isConfigured = false
    private let context = LAContext()
```

**Why @unchecked Sendable**:
- Mutable _isConfigured state
- LAContext is not Sendable
- No synchronization for state access

**Recommendation**: Convert to actor with nonisolated methods
```swift
actor BiometricAuthManager: ServiceProtocol {
    private var _isConfigured = false
    
    nonisolated func canUseBiometrics() -> Bool {
        // Create new LAContext per check
    }
}
```

### 3. OnboardingService.swift (Line 5)
**Status**: Onboarding module service  
**Current State**:
```swift
final class OnboardingService: OnboardingServiceProtocol, ServiceProtocol, @unchecked Sendable {
    private(set) var isConfigured = false
    private let modelContext: ModelContext
```

**Why @unchecked Sendable**:
- Mutable isConfigured state
- ModelContext (SwiftData) is not Sendable
- Needs to conform to ServiceProtocol

**Recommendation**: Keep @unchecked Sendable due to SwiftData
- SwiftData's ModelContext requires special handling
- Document the synchronization strategy

### 4. NotificationManager.swift (Line 5)
**Status**: Notification management service  
**Current State**:
```swift
@MainActor
final class NotificationManager: NSObject, @unchecked Sendable, ServiceProtocol {
    private var _isConfigured = false
    private var pendingNotifications: Set<String> = []
```

**Why @unchecked Sendable**:
- Already @MainActor but needs Sendable for ServiceProtocol
- Manages mutable state (pendingNotifications)
- NSObject inheritance complicates actor conversion

**Recommendation**: Remove @unchecked Sendable
- Already @MainActor provides isolation
- ServiceProtocol should be updated to support @MainActor services

### 5. DemoAIService.swift (Line 4)
**Status**: Demo mode AI service  
**Current State**:
```swift
final class DemoAIService: AIServiceProtocol, @unchecked Sendable {
    private(set) var isConfigured: Bool = true
    private(set) var activeProvider: AIProvider = .gemini
    private var responseDelay: TimeInterval = 1.0
```

**Why @unchecked Sendable**:
- Mutable state properties
- Mimics AIService structure
- No synchronization

**Recommendation**: Convert to actor (match AIService)

### 6. MinimalAIService.swift (Line 5)
**Status**: Minimal AI implementation  
**Current State**:
```swift
final class MinimalAIAPIService: AIServiceProtocol, @unchecked Sendable {
    let serviceIdentifier = "minimal-ai-service"
    let isConfigured = true
```

**Why @unchecked Sendable**:
- All properties are immutable (let)
- Only needed for protocol conformance

**Recommendation**: Use standard Sendable
```swift
final class MinimalAIAPIService: AIServiceProtocol, Sendable {
    // Already safe with immutable properties
}
```

### 7. DashboardNutritionService.swift (Line 6)
**Status**: Dashboard nutrition calculations  
**Current State**:
```swift
@MainActor
final class DashboardNutritionService: DashboardNutritionServiceProtocol, @unchecked Sendable {
    private let modelContext: ModelContext
```

**Why @unchecked Sendable**:
- @MainActor + Sendable requirement
- ModelContext is not Sendable

**Recommendation**: Remove @unchecked Sendable
- Already isolated to @MainActor
- Update protocol requirements

### 8. FunctionCallDispatcher.swift (Line 90)
**Status**: AI function call routing  
**Current State**:
```swift
final class FunctionCallDispatcher: @unchecked Sendable {
    private let metricsQueue = DispatchQueue(label: "com.airfit.function-metrics", attributes: .concurrent)
    private var _functionMetrics: [String: FunctionMetrics] = [:]
```

**Why @unchecked Sendable**:
- Manages mutable metrics state
- Uses DispatchQueue for synchronization
- Complex coordination between services

**Recommendation**: Keep @unchecked Sendable
- Has proper synchronization via DispatchQueue
- Document the thread-safety guarantees

### 9. KeychainWrapper.swift (Line 4)
**Status**: Keychain access utility  
**Current State**:
```swift
public final class KeychainWrapper: @unchecked Sendable {
    static let shared = KeychainWrapper()
    private init() {}
```

**Why @unchecked Sendable**:
- Singleton pattern with static shared instance
- No mutable state (stateless operations)
- Keychain operations are inherently thread-safe

**Recommendation**: Use standard Sendable
```swift
public final class KeychainWrapper: Sendable {
    // No mutable state, can be regular Sendable
}
```

## Summary of Recommendations

### Convert to Actor (4 services)
1. **AIService** - Primary AI service with mutable state
2. **BiometricAuthManager** - Authentication state management
3. **DemoAIService** - Match production AIService pattern
4. **OnboardingService** - If SwiftData allows

### Remove @unchecked Sendable (2 services)
1. **NotificationManager** - Already @MainActor
2. **DashboardNutritionService** - Already @MainActor

### Change to Regular Sendable (2 services)
1. **MinimalAIService** - All immutable properties
2. **KeychainWrapper** - Stateless operations

### Keep @unchecked Sendable (1 service)
1. **FunctionCallDispatcher** - Has proper manual synchronization

## Migration Strategy

### Phase 1: Quick Wins
- Change MinimalAIService and KeychainWrapper to regular Sendable
- Remove @unchecked from @MainActor services

### Phase 2: Actor Conversions
- Convert AIService, DemoAIService, and BiometricAuthManager to actors
- Update dependent code to handle async actor calls

### Phase 3: Protocol Updates
- Update ServiceProtocol to support different isolation domains
- Consider protocol variants: ActorServiceProtocol, MainActorServiceProtocol

## Benefits of Migration

1. **Type Safety**: Compiler-enforced thread safety
2. **Performance**: Actors optimize synchronization better than manual locks
3. **Clarity**: Clear isolation boundaries in code
4. **Maintenance**: Easier to reason about concurrent access
5. **Swift 6 Ready**: Prepares codebase for stricter concurrency checking