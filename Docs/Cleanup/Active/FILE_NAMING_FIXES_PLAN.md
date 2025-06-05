# File Naming Fixes Execution Plan

## Overview
This document tracks the systematic fixing of file naming violations to comply with NAMING_STANDARDS.md.

**Total violations found: 26 files** (6 completed, 20 remaining)

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

### Phase 3: Mock File Splits (Most Complex)
These plural files need to be split into individual mock files.

#### 3.1 MockDashboardServices.swift
- [ ] Analyze contents - list all mocks inside
- [ ] Create individual files for each mock
- [ ] Update imports in test files
- [ ] Delete original plural file
- [ ] Update project.yml
- [ ] Run `xcodegen generate`
- [ ] Run tests

#### 3.2 MockVoiceServices.swift
- [ ] Analyze contents - list all mocks inside
- [ ] Create individual files for each mock
- [ ] Update imports in test files
- [ ] Delete original plural file
- [ ] Update project.yml
- [ ] Run `xcodegen generate`
- [ ] Run tests

#### 3.3 MockAIFunctionServices.swift
- [ ] Analyze contents - list all mocks inside
- [ ] Create individual files for each mock
- [ ] Update imports in test files
- [ ] Delete original plural file
- [ ] Update project.yml
- [ ] Run `xcodegen generate`
- [ ] Run tests

### Phase 4: Generic Extension Renames (12 files)
These work but need more specific purpose names:

#### 4.1 Core Extensions
- [ ] `String+Extensions.swift` → `String+Validation.swift` (email validation, trimming)
- [ ] `Date+Extensions.swift` → `Date+Helpers.swift` (formatting + date operations)
- [ ] `Double+Extensions.swift` → `Double+Formatting.swift`
- [ ] `TimeInterval+Extensions.swift` → `TimeInterval+Formatting.swift`

#### 4.2 UI Extensions
- [ ] `View+Extensions.swift` → `View+Styling.swift` (card styles, buttons, modifiers)
- [ ] `Color+Extensions.swift` → `Color+Theme.swift`

#### 4.3 Network/API Extensions
- [ ] `URLRequest+Extensions.swift` → `URLRequest+API.swift`
- [ ] `AIProvider+Extensions.swift` → Already split into `AIProvider+API.swift` and `AIProvider+Settings.swift`

#### 4.4 Data Extensions
- [ ] `FetchDescriptor+Extensions.swift` → `FetchDescriptor+Convenience.swift`

#### 4.5 Service Protocol Extensions
- [ ] `AIServiceProtocol+Extensions.swift` → `AIServiceProtocol+AI.swift`
- [ ] `AppError+Extensions.swift` → `AppError+Conversion.swift`
- [ ] `HealthKit+Extensions.swift` → `HealthKit+Types.swift`
- [ ] `NotificationManager+Extensions.swift` → `NotificationManager+Settings.swift`

### Phase 5: Services with Implementation Details (3 files)
- [ ] `ProductionAIService.swift` → `AIService.swift`
- [ ] `HealthKitService.swift` → `HealthService.swift` 
- [ ] `ProductionMonitor.swift` → `MonitoringService.swift`

### Phase 6: Models Using "Types" (2 files)
- [ ] `ServiceTypes.swift` → `ServiceModels.swift`
- [ ] `ConversationTypes.swift` → `ConversationModels.swift`

### Phase 7: Other Fixes (3 files)
- [ ] `OnboardingFlowCoordinator.swift` → `OnboardingCoordinator.swift`
- [ ] `TestDataGenerators.swift` → `TestHelpers.swift`
- [ ] `ModelContainer+Testing.swift` → `ModelContainer+Test.swift`

### Phase 8: Protocol Consolidation (2 files)
- [ ] Investigate and merge `APIKeyManagementProtocol.swift` and `APIKeyManagerProtocol.swift`

## Rollback Plan
If any rename causes issues:
1. `git status` to see changes
2. `git checkout -- <file>` to revert specific files
3. `git reset --hard HEAD` for complete rollback (nuclear option)
4. Re-run `xcodegen generate` after any revert

## Success Criteria
- [ ] All files follow NAMING_STANDARDS.md
- [ ] No build errors
- [ ] All tests pass
- [ ] No duplicate functionality from naming confusion
- [ ] Git history shows clean, atomic commits for each rename

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