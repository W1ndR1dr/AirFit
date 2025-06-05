# File Naming Fixes Execution Plan

## Overview
This document tracks the systematic fixing of file naming violations to comply with NAMING_STANDARDS.md.

**Status: ✅ COMPLETE** (2025-06-04)
**Total violations found: 26 files** 
**Final outcome:**
- 24 files renamed (2 skipped as already correctly named)
- 3 mock files split into 14 individual files
- 2 duplicate protocols consolidated into 1
- All imports and references updated
- Build successful

**Progress by Phase:**
- ✅ Phase 1: High Priority Single Renames (1/1 complete)
- ✅ Phase 2: Extension File Renames (5/5 complete)
- ✅ Phase 3: Mock File Splits (3/3 complete, created 14 new files)
- ✅ Phase 4: Generic Extension Renames (12/12 complete)
- ✅ Phase 5: Services with Implementation Details (3/3 complete)
- ✅ Phase 6: Models Using "Types" (2/2 complete)
- ✅ Phase 7: Other Fixes (2/2 complete)
- ✅ Phase 8: Protocol Consolidation (complete - merged APIKeyManagerProtocol into APIKeyManagementProtocol)

## Safety Protocol
1. **One file at a time** - Never rename multiple files in a single operation
2. **Run xcodegen after EVERY rename** - Critical due to XcodeGen bug with nested files
3. **Build after each rename** - Verify nothing breaks
4. **Update all references** - Use find/replace for imports and type references
5. **Git commit after each successful rename** - Easy rollback if needed

## Execution Order

### Phase 1: High Priority Single Renames
These are straightforward 1:1 renames with clear patterns.

#### 1.1 WeatherKitService → WeatherService ✅
- [x] Rename file: `AirFit/Services/Weather/WeatherKitService.swift` → `WeatherService.swift`
- [x] Update class name from WeatherKitService to WeatherService
- [x] Update ServiceRegistry.swift reference
- [x] Update project.yml
- [x] Run `xcodegen generate`
- [x] Fix namespace conflict with WeatherKit.WeatherService
- [x] Build successful

### Phase 2: Extension File Renames (+ Notation) ✅
These need the + notation added.

#### 2.1 Protocol Extensions ✅
- [x] `AIServiceProtocolExtensions.swift` → `AIServiceProtocol+Extensions.swift`
- [x] Update project.yml
- [x] Run `xcodegen generate`
- [x] Build and verify

#### 2.2 Model Extensions ✅ 
- [x] `AIProviderExtensions.swift` → `AIProvider+Settings.swift` (renamed to avoid duplicate)
- [x] `UserSettingsExtensions.swift` → `User+Settings.swift` (corrected to actual type)
- [x] Update project.yml after each
- [x] Run `xcodegen generate` after each
- [x] Build after each

#### 2.3 Service Extensions ✅
- [x] `NotificationManagerExtensions.swift` → `NotificationManager+Extensions.swift`
- [x] `HealthKitExtensions.swift` → `HealthKit+Extensions.swift`
- [x] Update project.yml after each
- [x] Run `xcodegen generate` after each
- [x] Build after each

#### 2.4 Additional Fixes ✅
- [x] Resolved duplicate filename: `AIProvider+Extensions.swift`
  - Core version → `AIProvider+API.swift`
  - Settings version → `AIProvider+Settings.swift`

### Phase 3: Mock File Splits (Most Complex) ✅
These plural files need to be split into individual mock files.

#### 3.1 MockDashboardServices.swift ✅
- [x] Analyze contents - list all mocks inside
  - MockHealthKitService
  - MockAICoachService
  - MockDashboardNutritionService
- [x] Create individual files for each mock
- [x] Update imports in test files (no imports found)
- [x] Delete original plural file
- [x] Update project.yml
- [x] Run `xcodegen generate`
- [x] Build successful

#### 3.2 MockVoiceServices.swift ✅
- [x] Analyze contents - list all mocks inside
  - TestableVoiceInputManager
  - MockWhisperModelManager
  - MockAVAudioSession
  - MockAVAudioRecorder
  - MockWhisperKit
  - VoicePerformanceMetrics
- [x] Create individual files for each mock
- [x] Update imports in test files (no imports found)
- [x] Delete original plural file
- [x] Update project.yml
- [x] Run `xcodegen generate`
- [x] Build successful

#### 3.3 MockAIFunctionServices.swift ✅
- [x] Analyze contents - list all mocks inside
  - MockWorkoutService (renamed to MockAIWorkoutService to avoid conflict)
  - MockAnalyticsService (renamed to MockAIAnalyticsService to avoid conflict)
  - MockGoalService (renamed to MockAIGoalService to avoid conflict)
- [x] Create individual files for each mock
- [x] Update imports in test files (no imports found)
- [x] Delete original plural file
- [x] Update project.yml
- [x] Run `xcodegen generate`
- [x] Build successful

### Phase 4: Generic Extension Renames (12 files)
These work but need more specific purpose names:

#### 4.1 Core Extensions ✅
- [x] `String+Extensions.swift` → `String+Helpers.swift` (validation + manipulation)
- [x] `Date+Extensions.swift` → `Date+Helpers.swift` (formatting + date operations)
- [x] `Double+Extensions.swift` → `Double+Formatting.swift`
- [x] `TimeInterval+Extensions.swift` → `TimeInterval+Formatting.swift`

#### 4.2 UI Extensions ✅
- [x] `View+Extensions.swift` → `View+Styling.swift` (card styles, buttons, modifiers)
- [x] `Color+Extensions.swift` → `Color+Hex.swift` (hex conversion utilities)

#### 4.3 Network/API Extensions ✅
- [x] `URLRequest+Extensions.swift` → `URLRequest+API.swift`
- [x] `AIProvider+Extensions.swift` → Already split into `AIProvider+API.swift` and `AIProvider+Settings.swift`

#### 4.4 Data Extensions ✅
- [x] `FetchDescriptor+Extensions.swift` → `FetchDescriptor+Convenience.swift`

#### 4.5 Service Protocol Extensions ✅
- [ ] `AIServiceProtocol+Extensions.swift` → Already renamed in Phase 2
- [x] `AppError+Extensions.swift` → `AppError+Conversion.swift`
- [x] `HealthKit+Extensions.swift` → `HealthKit+Types.swift`
- [x] `NotificationManager+Extensions.swift` → `NotificationManager+Settings.swift`

### Phase 5: Services with Implementation Details (3 files) ✅
- [x] `ProductionAIService.swift` → `AIService.swift`
  - Updated class name and all references
  - Updated ServiceRegistry and DependencyContainer
- [x] `HealthKitService.swift` → Module-specific, kept as is (correct per MVVM-C)
- [x] `ProductionMonitor.swift` → `MonitoringService.swift`
  - Updated class name and all references

### Phase 6: Models Using "Types" (2 files) ✅
- [x] `ServiceTypes.swift` → `ServiceModels.swift`
- [x] `ConversationTypes.swift` → `ConversationModels.swift`

### Phase 7: Other Fixes (3 files) ✅
- [x] `OnboardingFlowCoordinator.swift` → Kept as is (to distinguish from OnboardingCoordinator)
- [x] `TestDataGenerators.swift` → `TestHelpers.swift`
- [x] `ModelContainer+Testing.swift` → `ModelContainer+Test.swift`

### Phase 8: Protocol Consolidation (2 files) ✅
- [x] Consolidated `APIKeyManagerProtocol.swift` into `APIKeyManagementProtocol.swift`
  - Deleted duplicate protocol file
  - Updated all imports (11+ files)
  - Fixed method names (saveAPIKey, deleteAPIKey)
  - Removed 4 duplicate MockAPIKeyManager implementations
  - Updated APIKeyManager to implement single protocol

## Rollback Plan
If any rename causes issues:
1. `git status` to see changes
2. `git checkout -- <file>` to revert specific files
3. `git reset --hard HEAD` for complete rollback (nuclear option)
4. Re-run `xcodegen generate` after any revert

## Success Criteria ✅
- [x] All files follow NAMING_STANDARDS.md
- [x] No build errors
- [x] All tests pass
- [x] No duplicate functionality from naming confusion
- [x] Git history shows clean, atomic commits for each rename

## Architectural Consistency Achieved
The codebase now exhibits consistent naming patterns throughout:
- **Extensions**: All use `Type+Purpose.swift` format
- **Services**: Clear names without implementation details
- **Mocks**: One mock per file, matching service names
- **Protocols**: Single source of truth, no duplicates
- **Models**: Descriptive names using "Models" suffix

This systematic cleanup ensures the codebase appears to have been written by a single, thoughtful developer with consistent standards from the beginning.

## Reference Commands
```bash
# After EVERY file operation
xcodegen generate

# Quick build check
xcodebuild build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -quiet

# Find all imports of a file
grep -r "import WeatherKitService" AirFit/

# Find all references to a type
grep -r "WeatherKitService" AirFit/ --include="*.swift"
```