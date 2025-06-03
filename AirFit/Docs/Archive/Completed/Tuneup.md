# AirFit Architecture Tuneup

**Version:** 1.0  
**Date:** January 2025  
**Purpose:** Critical foundation fixes required before completing Modules 9-12  
**Status:** Pre-Implementation

## Executive Summary

Based on comprehensive architectural analysis, **4 critical foundation issues** must be resolved before proceeding with remaining development modules (9-12). These issues, if left unaddressed, would require significant rework and create production instability.

**Timeline Impact:** 2-3 hours of tuneup work will prevent 10-15 hours of later rework.

## Critical Issues Identified

### Issue #1: SwiftData Schema Foundation Failure
**Severity:** 🔴 **CRITICAL**  
**Impact:** All modules 9-12 depend on data persistence

**Problem:**
- `ConversationSession` and `ConversationResponse` models misplaced in `AirFit/Modules/Onboarding/Models/`
- Main schema in `AirFitApp.swift` missing critical models
- `ChatMessage` model missing from schema despite `ChatSession` dependency

### Issue #2: Production Service Mock Usage
**Severity:** 🔴 **CRITICAL**  
**Impact:** Module 10 AI services cannot integrate

**Problem:**
- `MockAIService()` hardcoded in production `ContentView.swift:18`
- No dependency injection pattern for service replacement
- Blocks Module 10 real AI service integration

### Issue #3: Service Architecture Misalignment  
**Severity:** 🟡 **MEDIUM**  
**Impact:** Protocol naming and placement inconsistencies

**Problem:**
- Service protocols scattered instead of centralized in `Core/Protocols/`
- Naming pattern mismatches (`APIKeyManager` vs expected `DefaultAPIKeyManager`)
- Missing concrete service implementations

### Issue #4: Settings Module Completely Empty
**Severity:** 🟡 **MEDIUM**  
**Impact:** Module 11 blocked, marked "Completed" but empty

**Problem:**
- All Settings subdirectories empty despite "Completed" status
- Module 11 would create complete implementation

## Tuneup Implementation Plan

### Phase 1: SwiftData Schema Fixes (Priority 1)

#### Task 1.1: Relocate Conversation Models
```bash
# Current location (WRONG)
AirFit/Modules/Onboarding/Models/ConversationModels.swift

# Target location (CORRECT)  
AirFit/Data/Models/ConversationSession.swift
AirFit/Data/Models/ConversationResponse.swift
```

**Actions:**
1. Extract `@Model` classes from `ConversationModels.swift`
2. Create separate files in `AirFit/Data/Models/`
3. Update all imports in dependent files
4. Add proper `@Relationship` attributes

**Acceptance Criteria:**
- [ ] `ConversationSession.swift` in `AirFit/Data/Models/`
- [ ] `ConversationResponse.swift` in `AirFit/Data/Models/`
- [ ] All imports updated
- [ ] Project builds without errors

#### Task 1.2: Update Main Schema
**File:** `AirFit/Application/AirFitApp.swift`

**Current Schema (Incomplete):**
```swift
let schema = Schema([
    User.self,
    OnboardingProfile.self,
    FoodEntry.self,
    Workout.self,
    DailyLog.self,
    CoachMessage.self,
    HealthKitSyncRecord.self,
    ChatSession.self
])
```

**Updated Schema (Complete):**
```swift
let schema = Schema([
    User.self,
    OnboardingProfile.self,
    FoodEntry.self,
    Workout.self,
    DailyLog.self,
    CoachMessage.swift,
    HealthKitSyncRecord.self,
    ChatSession.self,
    ChatMessage.self,           // ADD: Missing from current schema
    ConversationSession.self,   // ADD: Moved from Onboarding
    ConversationResponse.self   // ADD: Moved from Onboarding
])
```

**Acceptance Criteria:**
- [ ] All SwiftData models included in schema
- [ ] App launches without ModelContainer errors
- [ ] Data persistence tests pass

### Phase 2: Production Service Fixes (Priority 1)

#### Task 2.1: Replace MockAIService Usage
**File:** `AirFit/Application/ContentView.swift:18`

**Current (Production Risk):**
```swift
OnboardingFlowView(
    aiService: MockAIService(),  // ❌ MOCK IN PRODUCTION
    // ...
)
```

**Fixed (Dependency Injection):**
```swift
OnboardingFlowView(
    aiService: DependencyContainer.shared.aiService,  // ✅ REAL SERVICE
    // ...
)
```

**Additional Changes:**
1. Update `DependencyContainer` to provide AI service
2. Create placeholder until Module 10 provides real implementation
3. Ensure graceful fallback if service unavailable

**Acceptance Criteria:**
- [ ] No `MockAIService` in production code paths
- [ ] Dependency injection pattern implemented
- [ ] Graceful service unavailable handling

### Phase 3: Service Architecture Alignment (Priority 2)

#### Task 3.1: Centralize Service Protocols
**Actions:**
1. Move service protocols to `AirFit/Core/Protocols/`
2. Standardize naming: `DefaultXXXService` pattern
3. Update dependency injection to use protocols

**Target Protocol Locations:**
```
AirFit/Core/Protocols/
├── AIServiceProtocol.swift
├── APIKeyManagementProtocol.swift  
├── NotificationManagerProtocol.swift
├── UserServiceProtocol.swift
└── NetworkManagementProtocol.swift
```

**Acceptance Criteria:**
- [ ] All service protocols in `Core/Protocols/`
- [ ] Consistent naming patterns
- [ ] All services implement protocols

#### Task 3.2: Create Missing Concrete Services
**Required Implementations:**
- `AirFit/Services/User/DefaultUserService.swift`
- `AirFit/Services/Security/DefaultAPIKeyManager.swift` 
- `AirFit/Services/Platform/DefaultNotificationManager.swift`

**Acceptance Criteria:**
- [ ] All concrete services implement their protocols
- [ ] Services registered in `DependencyContainer`
- [ ] Basic functionality verified

### Phase 4: Settings Module Foundation (Priority 3)

#### Task 4.1: Document Settings Module Status
**Investigation Required:**
1. Verify if Settings files exist elsewhere in codebase
2. Document actual vs. expected state
3. Prepare for Module 11 clean implementation

**Acceptance Criteria:**
- [ ] Settings module status documented
- [ ] Clear path for Module 11 implementation

## Coordination with Concurrent Work

### Persona Synthesis Integration
**Current:** Another agent working on Persona Synthesis/onboarding  
**Coordination Point:** `ConversationSession` model relocation

**Actions:**
1. Coordinate model relocation timing
2. Ensure consistent import updates
3. Verify onboarding flow integration after fixes

### Module Development Sequencing Post-Tuneup
```
Phase 1-4 Tuneup (2-3 hours)
    ↓
Module 10: Services Layer (Foundation)
    ↓  
Module 9 + Module 11: Parallel Implementation
    ↓
Module 12: Testing & Validation
```

## Risk Mitigation

### High-Risk Operations
1. **SwiftData Model Migration:** Create backup before model relocation
2. **Schema Changes:** Test with fresh app install and existing data
3. **Service Replacement:** Gradual rollout with fallback mechanisms

### Testing Strategy
```bash
# After each phase, verify:
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'

# Data persistence test:
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -only-testing:AirFitTests/DataLayerTests
```

### Rollback Plan
- Git branch for each phase
- Atomic commits per task
- Quick rollback capability if issues arise

## Success Criteria

### Phase Completion Gates
- [ ] **Phase 1 Complete:** App builds and launches with correct SwiftData schema
- [ ] **Phase 2 Complete:** No mock services in production code paths  
- [ ] **Phase 3 Complete:** Service architecture follows defined patterns
- [ ] **Phase 4 Complete:** Settings module status clarified

### Final Validation
- [ ] All tests pass
- [ ] App launches successfully
- [ ] Data persistence working
- [ ] Ready for Module 9-12 development

### Performance Targets
- [ ] App launch time unchanged (< 1.5s)
- [ ] SwiftData operations < 50ms
- [ ] No memory leaks introduced

## Implementation Priority Matrix

| Task | Impact | Effort | Priority | Dependencies |
|------|--------|--------|----------|--------------|
| 1.1: Move Conversation Models | High | Medium | P1 | Coordinate with Persona agent |
| 1.2: Update Schema | High | Low | P1 | Task 1.1 |
| 2.1: Replace MockAIService | High | Medium | P1 | None |
| 3.1: Centralize Protocols | Medium | Medium | P2 | None |
| 3.2: Create Concrete Services | Medium | High | P2 | Task 3.1 |
| 4.1: Settings Status | Low | Low | P3 | None |

## Post-Tuneup Benefits

1. **Solid Foundation:** Clean architecture for modules 9-12
2. **Reduced Risk:** No production mocks or data integrity issues  
3. **Faster Development:** No rework needed during module implementation
4. **Better Testing:** Module 12 can validate correct architecture
5. **Production Ready:** Real services integrated from start

---

**Next Steps:** Execute Phase 1 tasks immediately, coordinate with Persona Synthesis agent, then proceed with module development in defined sequence. 