# 🚀 START HERE - AirFit Cleanup Guide

## The 30-Second Summary

We're cleaning up technical debt while **preserving our best code**. The app works great, but has some deprecated code and force casts that need fixing.

**Your mission**: Fix dangerous code without breaking the good stuff.

## The 5-Minute Orientation

### What's Actually Broken?
1. **Force cast at DependencyContainer:45** - Will crash at runtime
2. **SimpleMockAIService in production** - Should be a proper offline service
3. **Duplicate API protocols** - Two protocols doing the same thing
4. **ChatViewModel** - Still using old ObservableObject pattern

### What's Working Great (DO NOT BREAK!)
- **PersonaSynthesis** - Generates AI personas in <3 seconds
- **LLMOrchestrator** - Handles multiple AI providers with fallback
- **Onboarding Flow** - Months of UX refinement
- **Function Calling** - Clean dispatcher for AI actions

### The Plan (4 Phases)
1. **Critical Fixes** (2 hrs) - Fix crashes and build errors
2. **Service Migration** (1 day) - Standardize services, add WeatherKit
3. **Pattern Updates** (4 hrs) - Update ChatViewModel, extend errors
4. **DI Polish** (2 hrs) - Document what we have, minor improvements

## Your First Task

```bash
# 1. Check out the code
git checkout Codex1

# 2. Find the force cast
grep -n "as!" AirFit/Core/Utilities/DependencyContainer.swift
# Line 45: apiKeyManager as! APIKeyManagementProtocol

# 3. Fix it (see PHASE_1_CRITICAL_FIXES.md for details)

# 4. Verify
xcodegen generate
xcodebuild clean build -scheme "AirFit"

# 5. Update CLEANUP_TRACKER.md when done
```

## Quick Reference

**Must Read First**: `PRESERVATION_GUIDE.md` - What code to protect  
**Current Phase**: `PHASE_1_CRITICAL_FIXES.md` - What we're doing now  
**Progress**: `CLEANUP_TRACKER.md` - Visual progress tracker  

**Get Help**: If unsure about deleting something, check PRESERVATION_GUIDE or ask!

---

Ready? Start with that force cast. It's a ticking time bomb. 💣 → 🎯