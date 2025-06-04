# AirFit Architecture Cleanup Plan

## Current State Assessment (January 2025)
The codebase shows signs of rapid development ("vibe coding"):
- Duplicate protocols and implementations
- Force casting between similar types
- Mock services in production code
- Protocol method misalignment
- Inconsistent naming conventions

## Priority 1: Critical Architecture Fixes

### 1.1 Consolidate API Key Management
**Problem**: Two protocols doing the same thing
- `APIKeyManagerProtocol` (legacy sync + async string-based)
- `APIKeyManagementProtocol` (modern async with AIProvider enum)

**Solution**:
```swift
// Keep only APIKeyManagementProtocol, extend it if needed
protocol APIKeyManagementProtocol: AnyObject, Sendable {
    // Existing methods...
    
    // Add legacy support if needed
    func getAPIKey(for providerString: String) async -> String?
}
```

**Files to update**:
- Merge `/AirFit/Core/Protocols/APIKeyManagerProtocol.swift` into `APIKeyManagementProtocol.swift`
- Update `DefaultAPIKeyManager` to implement only one protocol
- Update all references (~15 files based on grep results)

### 1.2 Fix FunctionCallDispatcher Protocol Alignment
**Problem**: Dispatcher expects methods not in protocols
- `WorkoutServiceProtocol` doesn't have `generatePlan`
- `AnalyticsServiceProtocol` doesn't have `analyzePerformance`
- `GoalServiceProtocol` doesn't have `createOrRefineGoal`

**Solution**: Create AI-specific protocol extensions
```swift
// New file: /AirFit/Core/Protocols/AIServiceProtocolExtensions.swift
protocol AIWorkoutServiceProtocol: WorkoutServiceProtocol {
    func generatePlan(...) async throws -> WorkoutPlanResult
}

protocol AIAnalyticsServiceProtocol: AnalyticsServiceProtocol {
    func analyzePerformance(...) async throws -> PerformanceAnalysisResult
}

protocol AIGoalServiceProtocol: GoalServiceProtocol {
    func createOrRefineGoal(...) async throws -> GoalResult
}
```

**Files to update**:
- Create new protocol file
- Update `FunctionCallDispatcher` to use AI-specific protocols
- Remove hacky Dev services from `CoachEngine`

### 1.3 Unify Personality Insights Types
**Problem**: Two similar but incompatible types
- `PersonalityInsights` (onboarding flow)
- `ConversationPersonalityInsights` (AI/persona generation)

**Solution**: Create conversion extension
```swift
extension ConversationPersonalityInsights {
    init(from insights: PersonalityInsights) {
        // Proper conversion logic
    }
}

extension PersonaMetadata {
    init(from persona: CoachPersona, sourceInsights: PersonalityInsights) {
        // Create with proper conversion
    }
}
```

**Files to update**:
- `/AirFit/Modules/Onboarding/Models/PersonalityInsights.swift`
- `/AirFit/Modules/AI/Models/ConversationPersonalityInsights.swift`
- `/AirFit/Services/User/DefaultUserService.swift`

## Priority 2: Remove Production Code Smells

### 2.1 Move Mock Services to Test Target
**Problem**: Mock implementations in production
- `SimpleMockAIService` in `/AirFit/Services/AI/`
- Dev services in `CoachEngine`

**Solution**:
1. Create `/AirFit/AirFitTests/Mocks/Services/` directory
2. Move all mocks there
3. Create proper preview providers using DependencyContainer

### 2.2 Fix Force Casting
**Problem**: Using `as!` throughout codebase

**Solution**: Type-safe conversions
```swift
// Instead of: keyManager as! APIKeyManagementProtocol
if let keyManager = self.apiKeyManager as? APIKeyManagementProtocol {
    // use it
} else {
    // handle error properly
}
```

**Critical locations**:
- `DependencyContainer.swift:44`
- `UnifiedOnboardingView.swift:76` (removed)
- All coordinator initializations

## Priority 3: Naming & Organization

### 3.1 Consolidate Duplicate Implementations
- **PersonaSynthesizer** vs **OptimizedPersonaSynthesizer**: Keep optimized, update references
- **OnboardingCoordinator** (2 versions): Investigate commit history, keep newer
- **LoadingOverlay** duplicates: Create single CommonComponents version

### 3.2 Standardize Naming
- Protocols: `*Protocol` suffix (not `*Providing` or `*Management`)
- Services: `*Service` suffix
- Managers: `*Manager` suffix
- ViewModels: `*ViewModel` suffix

## Implementation Order

### Phase 1: Foundation (Do First)
1. ❌ Consolidate API key protocols
2. ✅ Create AI service protocol extensions (AIServiceProtocolExtensions.swift)
3. ✅ Fix FunctionCallDispatcher (updated to use AI protocols)

### Phase 2: Type Safety
1. Add PersonalityInsights conversions
2. Remove all force casts
3. Add proper error handling

### Phase 3: Cleanup
1. Move mocks to test target
2. Remove duplicate implementations
3. Standardize naming

### Phase 4: Validation
1. Run full test suite
2. Verify no force casts remain
3. Ensure consistent naming

## Success Metrics
- Zero force casts in production code
- No mock services in production target
- All protocols properly aligned with implementations
- Consistent naming throughout
- Clean build with zero warnings

## Quick Reference Commands
```bash
# Find force casts
grep -r "as!" --include="*.swift" AirFit/

# Find duplicate types
grep -r "struct.*{" --include="*.swift" AirFit/ | sort | uniq -d

# Find protocol conformances
grep -r "protocol.*Protocol" --include="*.swift" AirFit/

# Run after changes
xcodegen generate
swiftlint --strict
xcodebuild -scheme "AirFit" clean build
```

## Notes for Context Switches
- This plan is in `/Users/Brian/Coding Projects/AirFit/ARCHITECTURE_CLEANUP_PLAN.md`
- Current focus: Making Phase 1 changes
- Check git status to see which phase we're in
- Each phase can be completed independently