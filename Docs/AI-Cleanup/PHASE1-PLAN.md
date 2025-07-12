# AI System Cleanup - Phase 1: Remove Dead Weight
**Status**: Planning
**Risk Level**: Low
**Estimated Time**: 30 minutes

## Objective
Remove completely unused code and obvious bloat without touching any active functionality.

## What We're Removing

### 1. Unused Services (Already Verified)
- ✅ `MinimalAIService.swift` - No references (ALREADY DELETED)
- ✅ `AIRequestBuilder.swift` - No references (ALREADY DELETED)
- ✅ `AIResponseParser.swift` - No references (ALREADY DELETED)
- ✅ `ContextSerializer.swift` - No references (ALREADY DELETED)
- ✅ `ContextFormattingProtocol.swift` - No references (ALREADY DELETED)

### 2. Never-Hit Cache System
**File**: `AIResponseCache.swift`
**Why Remove**: 
- Cache key includes entire conversation history via SHA256
- Probability of cache hit: ~0% (users never have identical conversations)
- Adds 480 lines of complexity for no benefit
**Verification**: Only 3 call sites, all can handle nil/empty cache

### 3. Empty/Unused Directories
- `ModelSelection/` - Empty directory

## What We're NOT Touching (Yet)
- ❌ Any service registered in DIBootstrapper
- ❌ Any protocol with multiple implementations
- ❌ Core AI flow (CoachEngine → AIService → LLMOrchestrator → Providers)
- ❌ Test/Demo services (might be needed for development)

## Pre-Flight Checklist
- [x] Full project builds successfully
- [x] No test failures related to AI
- [x] Grep verification shows no external dependencies
- [ ] Backup current state with git commit

## Success Criteria
- Build succeeds with 0 errors, 0 warnings
- All existing AI features work identically
- ~1,000 lines of code removed
- No user-facing changes

## Rollback Plan
Simple git revert if anything breaks