# o3 Pro Refactoring Opportunities

## Overview
This document tracks complex systems in AirFit that would benefit from o3 pro's advanced capabilities.

## Priority Matrix

### 🔴 Critical Priority (Do First)
1. **CoachEngine.swift** (2,064 lines)
   - **Current Problems**:
     - Nutrition parsing takes 3+ seconds, causes UI lag
     - Function routing logic spans 500+ lines with deep nesting
     - Streaming responses sometimes drop chunks
     - Hard to add new functions without breaking existing ones
   - **Success Criteria**:
     - Sub-second response for all message types
     - Easy to add new capabilities
     - Reliable streaming without data loss
     - Clear separation of concerns

### 🟠 High Priority (Do Next)
2. **ContextAssembler.swift** (873 lines)
   - **Current Problems**:
     - Fetches same data multiple times per session
     - Takes 2+ seconds to assemble full context
     - Trend calculations are basic (just weekly averages)
     - No predictive capabilities
   - **Success Criteria**:
     - Context ready in <500ms
     - Intelligent data freshness (not just TTL)
     - Meaningful trend insights
     - Graceful partial data handling

3. **RecoveryInference.swift** (402 lines)
   - **Current Problems**:
     - Recovery scores feel arbitrary to users
     - No learning from user feedback
     - Doesn't account for individual variation
     - Limited to 7-day historical window
   - **Success Criteria**:
     - Scores align with how users actually feel
     - Adapts to individual recovery patterns
     - Explains contributing factors clearly
     - Works with limited data for new users

4. **PersonaSynthesizer.swift** (385 lines)
   - **Current Problems**:
     - Takes 30+ seconds to generate persona
     - Generated personalities feel generic
     - Voice characteristics don't match personality
     - No way to refine if user doesn't like result
   - **Success Criteria**:
     - Generation under 10 seconds
     - Unique, memorable personalities
     - Coherent voice/personality matching
     - Ability to evolve based on interaction

### 🟡 Medium Priority (Nice to Have)
5. **NutritionCalculator.swift** (151 lines)
   - **Current Problems**:
     - Uses same formula for 18yo athlete and 60yo sedentary
     - Doesn't adjust based on actual weight changes
     - Macro ratios are fixed regardless of training
     - No consideration for metabolic adaptation
   - **Success Criteria**:
     - Personalized to individual metabolism
     - Learns from actual results
     - Dynamic macro adjustments
     - Handles edge cases gracefully

6. **StrengthProgressionService.swift** (221 lines)
   - **Current Problems**:
     - 1RM calculations vary wildly between formulas
     - No fatigue or readiness consideration
     - Treats all exercises the same
     - Can't predict plateau or deload needs
   - **Success Criteria**:
     - Consistent, reliable strength estimates
     - Accounts for recovery state
     - Exercise-specific calculations
     - Proactive training recommendations

### 🟢 Future Opportunities (Not Yet Built)
7. **Workout Analysis Engine** (0 lines - doesn't exist)
   - **User Problems**:
     - "How was my workout?" gets generic response
     - No insight into form breakdown or fatigue
     - Can't tell if progressing optimally
     - No early warning for overtraining
   - **Success Criteria**:
     - Specific, actionable workout feedback
     - Identifies when to push vs back off
     - Tracks quality beyond just weight/reps
     - Prevents injury through pattern detection

8. **Goal Achievement Engine** (minimal implementation)
   - **User Problems**:
     - Goals are static once set
     - No guidance on realistic timelines
     - Can't adapt when life happens
     - No celebration of progress milestones
   - **Success Criteria**:
     - Dynamic goal adjustment
     - Realistic timeline predictions
     - Handles setbacks gracefully
     - Meaningful progress recognition

9. **Meal Planning Engine** (0 lines - doesn't exist)
   - **User Problems**:
     - "What should I eat?" has no answer
     - Hitting macros requires manual math
     - No consideration for preferences/restrictions
     - Meal prep is disconnected from training
   - **Success Criteria**:
     - Practical meal suggestions
     - Automatic macro optimization
     - Respects dietary preferences
     - Adapts to training schedule

10. **Sleep Optimization Engine** (0 lines - doesn't exist)
    - **User Problems**:
      - Sleep data sits unused
      - No connection to recovery/performance
      - Can't identify sleep issues
      - No actionable improvement suggestions
    - **Success Criteria**:
      - Correlates sleep with performance
      - Identifies problem patterns
      - Provides specific improvements
      - Tracks intervention effectiveness

## How to Request o3 Pro Refactoring

### 1. Gather Context
```bash
# Find all files that use the system
grep -r "SystemName" --include="*.swift" AirFit/ | cut -d: -f1 | sort -u

# Find protocols it must conform to
grep -r "protocol.*Protocol" --include="*.swift" AirFit/

# Find current usage patterns
grep -r "SystemName\." --include="*.swift" AirFit/ | head -20
```

### 2. Measure Current State
- **Performance**: Time the operations that feel slow
- **Reliability**: Document crashes or errors with frequency
- **User Impact**: What do users complain about?
- **Developer Pain**: What's hard to modify or extend?

### 3. Define Success Without Prescribing Solution
❌ "Needs better caching strategy"
✅ "Currently fetches same data 10x per minute"

❌ "Should use dependency injection"  
✅ "Hard to test because of tight coupling"

❌ "Implement state machine"
✅ "Has 12 different states with unclear transitions"

### 4. Let o3 Pro Surprise You
The best solutions often come from fresh perspectives. By focusing on problems rather than solutions, we give o3 pro room to innovate.

## Tracking Refactors

### Completed ✅
- RecoveryInference (v1) - Basic implementation
- ContextAssembler (v1) - Progress reporting and caching
- HealthKitManager (v1) - Global caching

### In Progress 🚧
- None currently

### Queued 📋
1. CoachEngine - Routing optimization
2. PersonaSynthesizer - Enhanced generation
3. NutritionCalculator - Adaptive formulas

## Success Metrics

### Before o3 Pro
- CoachEngine: 2,064 lines, 3s nutrition parsing
- ContextAssembler: 873 lines, 2s assembly time
- RecoveryInference: 402 lines, basic scoring

### After o3 Pro (Target)
- CoachEngine: <1,500 lines, <1s nutrition parsing
- ContextAssembler: <700 lines, <1s assembly time
- RecoveryInference: <500 lines, ML-enhanced scoring

## Notes
- Always benchmark before and after refactoring
- Ensure backward compatibility with existing APIs
- Document any breaking changes
- Test with production-like data volumes