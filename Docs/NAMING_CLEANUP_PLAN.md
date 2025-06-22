# Naming Cleanup Plan

## Overview
Systematic plan to remove verbose naming patterns from the codebase. **One file at a time, build after each change.**

## Current State
- PersonaEngine methods already cleaned up (buildOptimizedPromptTemplate → promptTemplate, etc.)
- Onboarding simplified from 13,000+ lines to 1,722 lines
- Build currently succeeds with 0 errors, 0 warnings
- **Phase 1 Complete**: OptimizedPersonaSynthesizer → PersonaSynthesizer (merged to Codex1)

## Safety Protocol (FOLLOW EVERY TIME)
```bash
1. git checkout -b refactor/naming-cleanup-[filename]
2. Find all occurrences: grep -r "OldName" --include="*.swift" AirFit/
3. Use Edit tool with replace_all: true for EACH file
4. xcodebuild build -scheme "AirFit" -quiet
5. If build succeeds: git commit -m "refactor: [OldName] → [NewName]"
6. If build fails: git checkout -- .
```

## Priority Order (High Impact, Low Risk)

### Phase 1: Isolated Classes (Low Risk)
- [x] `OptimizedPersonaSynthesizer` → `PersonaSynthesizer` ✅ COMPLETED
  - Files updated:
    1. ✅ `AirFit/Modules/AI/PersonaSynthesis/OptimizedPersonaSynthesizer.swift` → `PersonaSynthesizer.swift`
    2. ✅ `AirFit/Core/DI/DIBootstrapper.swift` (3 occurrences updated)
    3. ✅ `AirFit/AirFitTests/Integration/PersonaGenerationTests.swift` (2 occurrences updated)
    4. ✅ `AirFit/Modules/AI/CoachEngine.swift` (1 occurrence updated)
    5. ✅ `AirFit/Services/Persona/PersonaService.swift` (2 occurrences updated)
    6. ✅ `AirFit/Modules/AI/Models/ConversationPersonalityInsights.swift` (comment updated)
    7. ✅ Added missing `PersonaPreview` struct to `PersonaSynthesizer.swift`
  - Commands:
    ```bash
    # Find all occurrences first
    grep -r "OptimizedPersonaSynthesizer" --include="*.swift" AirFit/
    
    # Edit each file with replace_all: true
    # Then rename the file itself
    mv AirFit/Modules/AI/PersonaSynthesis/OptimizedPersonaSynthesizer.swift \
       AirFit/Modules/AI/PersonaSynthesis/PersonaSynthesizer.swift
    ```
  - Verification: `grep -r "OptimizedPersonaSynthesizer" AirFit/` should return 0

### Phase 2: Verbose Methods in PersonaEngine
- [ ] Already completed ✅

### Phase 3: Test Helpers (Zero Production Risk)
- [ ] `setupDefaultStubs()` → `setupStubs()`
  - File: `AirFit/AirFitTests/Mocks/MockWorkoutService.swift` (line ~50)
  - Only used internally in init()
  - Simple find/replace is safe
- [ ] `test_generateSuggestions_withoutHistory_returnsDefaultPrompts()` → `test_generateSuggestions_withoutHistory_returnsPrompts()`
  - File: `AirFit/AirFitTests/Modules/Chat/ChatSuggestionsEngineTests.swift`
  - Test method name, zero risk

### Phase 4: Model Simplification
- [ ] `CompactWorkout` → `WorkoutSummary` (better describes intent)
  - File: `AirFit/Core/Models/HealthContextSnapshot.swift` (lines 288, 253-299)
  - Used in: `WorkoutContext` struct (4 properties)
  - ⚠️ WARNING: Used in JSON serialization - may affect saved data
  - Consider: Skip this one or add migration code

### Phase 5: Method Prefixes (Use Xcode Refactor)
- [ ] `buildRequest()` → `request()`
  - Need to find exact location: `grep -r "func buildRequest" AirFit/`
- [ ] `createUser(from profile:)` → Keep as is
  - File: `AirFit/Services/User/UserService.swift`
  - This is descriptive and not a factory method
- [ ] `generatePlan()` → Keep as is
  - Multiple contexts, the verb adds clarity

## What NOT to Touch
- `GradientManager` - Clear and not overly verbose
- `HapticService` - Standard iOS naming pattern
- `UserService` - Service suffix is meaningful here
- Any protocol names - These follow Swift conventions
- `UserDefaults` - System API
- `DefaultValue` - When used for actual default values
- Methods like `createUser()` that aren't factory methods
- `generatePlan()` where multiple contexts exist

## Verification Script
Save as `verify-naming.sh`:
```bash
#!/bin/bash
echo "Checking for remaining verbose patterns..."
grep -r "Optimized[A-Z]\|Default[A-Z]\|Simple[A-Z]\|Basic[A-Z]" --include="*.swift" AirFit/ | grep -v "UserDefaults\|DefaultValue"
echo "Files with 'build' prefix:"
grep -r "func build" --include="*.swift" AirFit/ | wc -l
```

## Progress Tracking
- [x] Create branch: `refactor/naming-cleanup` ✅
- [x] Phase 1: OptimizedPersonaSynthesizer ✅ (Merged to Codex1)
- [ ] Phase 3: Test helpers (2 methods)
- [ ] Phase 4: CompactWorkout 
- [ ] Phase 5: Method prefixes (assess count first)
- [ ] Final review and merge

## Success Metrics
- No build failures
- All tests pass
- ~50-100 fewer verbose names
- Code reads more naturally

Remember: **One change, one build, one commit.** Don't rush.

## Specific Commands for Phase 1 (Start Here - Claude Code)
```bash
# 1. Create branch
git checkout -b refactor/persona-synthesizer-naming

# 2. Find all occurrences
grep -r "OptimizedPersonaSynthesizer" --include="*.swift" AirFit/

# 3. Use Edit tool on each file:
# - DIBootstrapper.swift: Edit with old_string="OptimizedPersonaSynthesizer" new_string="PersonaSynthesizer" replace_all=true
# - PersonaGenerationTests.swift: Same edit with replace_all=true
# - OptimizedPersonaSynthesizer.swift: Same edit with replace_all=true

# 4. Rename the file
mv AirFit/Modules/AI/PersonaSynthesis/OptimizedPersonaSynthesizer.swift \
   AirFit/Modules/AI/PersonaSynthesis/PersonaSynthesizer.swift

# 5. Build immediately
xcodebuild build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -quiet

# 6. If successful
git add -A
git commit -m "refactor: OptimizedPersonaSynthesizer → PersonaSynthesizer"

# 7. Verify
grep -r "OptimizedPersonaSynthesizer" AirFit/  # Should return nothing
```

## Edit Tool Pattern for Claude Code
When using the Edit tool for renaming:
```
Edit(
  file_path: "path/to/file.swift",
  old_string: "OptimizedPersonaSynthesizer",
  new_string: "PersonaSynthesizer", 
  replace_all: true
)
```

## Additional High-Value Renames Found
- [ ] `ConversationPersonalityInsights` → `PersonalityInsights`
  - File: `AirFit/Modules/AI/Models/PersonalityInsights.swift`
  - Check usage: `grep -r "ConversationPersonalityInsights" AirFit/ | wc -l`
- [ ] `VoiceCharacteristics` → Consider keeping (descriptive)
- [ ] Remove "Default" prefix from any non-test classes
  - Search: `grep -r "class Default" AirFit/ | grep -v Test`

## Risk Assessment
- **Lowest Risk**: Test file renames (Phase 3)
- **Low Risk**: OptimizedPersonaSynthesizer (Phase 1)
- **Medium Risk**: Model renames that might affect JSON
- **Highest Risk**: Core service renames (avoid for now)