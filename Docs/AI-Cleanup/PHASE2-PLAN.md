# AI System Cleanup - Phase 2: Consolidate Core Services
**Status**: Planning
**Risk Level**: Medium
**Estimated Time**: 2 hours

## Objective
Merge redundant services and eliminate unnecessary abstraction layers while preserving ALL functionality.

## Core Insight
The current architecture has 2 services doing the same job:
- `AIService` - Wrapper that adds minimal value
- `LLMOrchestrator` - Actually manages providers and does the work

## Consolidation Plan

### 1. Merge AIService + LLMOrchestrator
**New Service**: `AIService.swift` (keep the name, merge the functionality)
**What to Keep**:
- ✅ Provider management from LLMOrchestrator
- ✅ Model selection logic
- ✅ Fallback logic (simplified)
- ✅ Direct streaming support
- ✅ Token counting
- ✅ Error conversion for user-friendly messages

**What to Remove**:
- ❌ Duplicate configuration logic
- ❌ Cache checks (removing cache)
- ❌ ServiceProtocol ceremony
- ❌ Health checks that aren't used
- ❌ Redundant async wrappers

### 2. Simplify AI Wrapper Services
**Current State**: AIGoalService, AIAnalyticsService, AIWorkoutService are thin wrappers
**Proposed Change**: 
- Move their prompt-building logic into domain services
- Call AIService directly from domain services
- Reduce 3 files (~2,100 lines) to simple prompt builders (~300 lines)

### 3. Streamline Function Dispatcher
**Current**: 880 lines of Enterprise Java patterns
**Proposed**: Simple function registry (~200 lines)
```swift
// Instead of complex dispatcher, just:
private let functions: [String: (args: [String: Any]) async throws -> Any] = [
    "setGoal": executeSetGoal,
    "generateWorkout": executeGenerateWorkout,
    // etc...
]
```

## What We're Preserving
- ✅ ALL user-facing features remain identical
- ✅ Function calling capability
- ✅ Multiple provider support (simplified)
- ✅ Streaming responses
- ✅ Persona system integration
- ✅ Error handling and user-friendly messages

## Migration Strategy
1. Create new consolidated AIService
2. Update DIBootstrapper to use new service
3. Update imports in dependent services
4. Remove old services
5. Run full test suite

## Risk Mitigation
- Each consolidation step in separate commit
- Keep old code until new code is verified
- Extensive testing of each AI feature
- Clear rollback points

## Success Criteria
- All AI features work identically
- ~5,000 lines of code removed
- Simpler dependency graph
- New developer can understand flow in 10 minutes