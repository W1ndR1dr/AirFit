# AI-Native Implementation Guide

## Quick Reference for Future Implementation

### 🎯 Primary Goal
Make AirFit truly AI-native by ensuring all coach-voice content comes from the LLM, not hardcoded arrays.

### 🔍 How to Find Violations

```bash
# Find hardcoded message arrays
grep -r "return \[" --include="*.swift" AirFit/ | grep -E "(message|greeting|encouragement|reminder)"

# Find random selection from arrays
grep -r "randomElement()" --include="*.swift" AirFit/

# Find switch statements with hardcoded messages
grep -r "switch.*{" -A 20 --include="*.swift" AirFit/ | grep -E "return \".*!\""

# Find generic error messages
grep -r "Something went wrong\|An error occurred\|Failed to" --include="*.swift" AirFit/
```

### 📋 Checklist for Each Violation

1. **Identify the violation type**:
   - [ ] Hardcoded message array
   - [ ] Generic error message
   - [ ] Empty state message
   - [ ] Achievement/celebration
   - [ ] Coaching/motivational content

2. **Determine the fix approach**:
   - [ ] Can use existing CoachEngine?
   - [ ] Need access to user context?
   - [ ] Need persona information?
   - [ ] Requires caching for performance?

3. **Implementation steps**:
   - [ ] Remove hardcoded content
   - [ ] Add AI generation with persona context
   - [ ] Add retry logic (3 attempts)
   - [ ] Add simple one-line fallback
   - [ ] Add proper error logging
   - [ ] Test with real API keys

### 🏗️ Standard Implementation Pattern

```swift
// ❌ WRONG - Hardcoded arrays
let messages = [
    "Great job! Keep it up!",
    "You're crushing it!",
    "Amazing progress!"
]
return messages.randomElement()!

// ✅ RIGHT - AI generated with simple fallback
do {
    // Try AI generation with retries
    for attempt in 1...3 {
        do {
            let content = try await coachEngine.generateContent(
                type: .encouragement,
                context: userContext
            )
            return content
        } catch {
            if attempt < 3 {
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
    // Simple fallback - no persona logic
    return "Great job!"
} catch {
    return "Great job!"
}
```

### 🚫 What NOT to Do

1. **Don't create new AI services** - Use CoachEngine
2. **Don't make complex fallbacks** - One simple line only
3. **Don't try to mimic personas in code** - That's the LLM's job
4. **Don't use isWarm/isHighEnergy logic** - Let the LLM handle personality
5. **Don't build arrays of variations** - The LLM provides variety

### ✅ What TO Keep Hardcoded

- Button labels: "Save", "Cancel", "Next"
- System status: "Loading...", "Syncing..."
- Navigation: "Back", "Settings", "Profile"
- Units: "lbs", "kg", "miles"
- Tab names: Fixed navigation structure

### 🔧 Key Services & Patterns

#### CoachEngine
- Central AI service for all coach interactions
- Has access to user context and persona
- Handles streaming responses
- Location: `AirFit/Modules/AI/CoachEngine.swift`

#### Persona Context
- Always include when calling AI
- Available from: `user.onboardingProfile?.persona`
- Contains: voice characteristics, interaction style, system prompt

#### Error Handling Pattern
```swift
AppLogger.error("Descriptive error message",
                error: actualError,
                category: .ai)
```

### 📊 Progress Tracking

Update `AI_NATIVE_PROGRESS.md` after each implementation:
1. Move item from "Not Started" to "In Progress"
2. Document what changed
3. Note any blockers or learnings
4. Update metrics if available

### 🎓 Key Learning
**The infrastructure already exists** - AirFit was designed to be AI-native but was never fully implemented. We're not adding AI, we're connecting it properly.

---

*Use this guide when implementing AI-native features. Update it with new patterns as discovered.*