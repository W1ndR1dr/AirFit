# Dependency Injection Analysis for AirFit

## Overview
This document analyzes the dependency injection patterns in AirFit, identifying force casting issues, protocol mismatches, and potential circular dependencies.

## Current DI Architecture

### 1. DependencyContainer (Core/Utilities/DependencyContainer.swift)
- **Pattern**: Singleton container with lazy initialization
- **Thread Safety**: Uses `@unchecked Sendable` (potential concurrency issues)
- **Service Registration**: Manual configuration in `configure()` method

### 2. ServiceRegistry (Services/ServiceRegistry.swift)
- **Pattern**: Type-safe service locator with protocol-based registration
- **Thread Safety**: Uses NSLock for thread-safe access
- **Features**: Health checks, service lifecycle management

## Critical Issues Found

### 1. Force Casting Problems

#### DependencyContainer.swift (Line 45)
```swift
LLMOrchestrator(apiKeyManager: keyManager as! APIKeyManagementProtocol)
```
**Issue**: Force casting `APIKeyManagerProtocol?` to `APIKeyManagementProtocol`
**Risk**: Runtime crash if keyManager is nil or wrong type
**Fix**: Add proper type checking or ensure protocol conformance

#### PersonaSynthesizer.swift (Lines 144-147)
```swift
let json = try JSONSerialization.jsonObject(with: response.content.data(using: .utf8)!) as! [String: Any]
let identity = try parseIdentity(from: json["identity"] as! [String: Any])
let style = try parseInteractionStyle(from: json["interactionStyle"] as! [String: Any])
```
**Issue**: Multiple force unwraps and casts in JSON parsing
**Risk**: Crash on malformed JSON responses
**Fix**: Use safe casting with proper error handling

#### EngagementEngine.swift (Lines 33, 42)
```swift
await self.handleLapseDetection(task: task as! BGProcessingTask)
await self.handleEngagementAnalysis(task: task as! BGProcessingTask)
```
**Issue**: Force casting background tasks
**Risk**: Crash if task type doesn't match
**Fix**: Use conditional casting with type checking

### 2. Protocol Confusion

#### Duplicate Protocol Definitions
- `APIKeyManagerProtocol` defined in two files:
  - Core/Protocols/APIKeyManagerProtocol.swift (legacy with sync/async methods)
  - Core/Protocols/APIKeyManagementProtocol.swift (modern async-only)
- `DefaultAPIKeyManager` conforms to BOTH protocols
- This creates confusion about which protocol to use

**Recommendation**: Consolidate into single protocol or clearly separate concerns

### 3. Dependency Injection Patterns

#### Current Patterns Used:
1. **Constructor Injection**: ViewModels receive dependencies via init
2. **Environment Injection**: DependencyContainer as SwiftUI environment value
3. **Service Locator**: ServiceRegistry with @Injected property wrapper
4. **Singleton Access**: Direct static access (e.g., NetworkClient.shared)

#### Issues:
- No consistent pattern across the codebase
- Mix of DependencyContainer and ServiceRegistry creates confusion
- ViewModels use constructor injection but services use singletons
- No clear ownership model for service lifecycle

### 4. Circular Dependency Risks

#### Potential Cycles:
1. **AIService ’ UserService ’ AIService**
   - ProductionAIService might need user context
   - UserService might need AI for persona generation
   
2. **HealthKitManager ’ DashboardServices ’ HealthKitManager**
   - Dashboard services depend on HealthKit
   - HealthKit updates might trigger dashboard refreshes

3. **NotificationManager ’ EngagementEngine ’ NotificationManager**
   - Engagement engine schedules notifications
   - Notifications might trigger engagement analysis

### 5. Service Initialization Order Issues

From DependencyContainer.configure():
```swift
1. ModelContainer set first
2. UserService created with ModelContext
3. AIService created with APIKeyManager
4. Services initialized in Tasks (potential race conditions)
```

**Issues**:
- Async initialization in Tasks without proper coordination
- No guarantee services are ready when accessed
- Force unwrapping in some service initializations

## Recommendations

### 1. Fix Force Casting
```swift
// Instead of:
keyManager as! APIKeyManagementProtocol

// Use:
guard let apiKeyManager = keyManager as? APIKeyManagementProtocol else {
    throw ServiceError.configurationError("Invalid API key manager type")
}
```

### 2. Consolidate DI Approach
- Choose either DependencyContainer OR ServiceRegistry, not both
- Implement consistent initialization patterns
- Use protocol-based dependencies everywhere

### 3. Improve JSON Parsing Safety
```swift
// Instead of force casting JSON:
guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let identity = json["identity"] as? [String: Any],
      let style = json["interactionStyle"] as? [String: Any] else {
    throw ParsingError.invalidJSON
}
```

### 4. Add Dependency Validation
```swift
extension DependencyContainer {
    func validate() throws {
        guard modelContainer != nil else { throw DIError.missingDependency("ModelContainer") }
        guard aiService != nil else { throw DIError.missingDependency("AIService") }
        // etc...
    }
}
```

### 5. Implement Proper Service Lifecycle
```swift
protocol ManagedService: ServiceProtocol {
    var dependencies: [ServiceProtocol.Type] { get }
    func canInitialize(with registry: ServiceRegistry) -> Bool
}
```

### 6. Create Dependency Graph Validator
- Build dependency graph at compile time
- Detect circular dependencies
- Ensure initialization order

## Testing Implications

### Mock Service Issues
- Some production code uses SimpleMockAIService directly (should be test-only)
- Mock services need to match protocol signatures exactly
- Missing mocks for some protocols (found in Module 12.2 work)

### Test Isolation
- Need to ensure DependencyContainer/ServiceRegistry are reset between tests
- Mock injection should be simplified
- Consider test-specific DI container

## Priority Fixes

1. **HIGH**: Remove all force casts in production code
2. **HIGH**: Consolidate APIKeyManager protocols
3. **MEDIUM**: Choose single DI pattern and refactor
4. **MEDIUM**: Fix service initialization race conditions
5. **LOW**: Implement dependency graph validation

## Migration Path

1. Phase 1: Fix force casts and add safety checks
2. Phase 2: Consolidate protocols and remove duplicates
3. Phase 3: Choose DI pattern and migrate incrementally
4. Phase 4: Add validation and testing infrastructure