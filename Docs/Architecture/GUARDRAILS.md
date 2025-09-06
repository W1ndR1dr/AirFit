# Architecture Guardrails

This document outlines the automated guardrails in place to maintain AirFit's architecture quality and coding standards.

## Overview

AirFit uses multiple layers of automated enforcement to catch architecture violations and maintain code quality:

1. **CI Guards Script** (`Scripts/ci-guards.sh`) - Comprehensive quality checks
2. **SwiftLint Custom Rules** (`.swiftlint.yml`) - Real-time linting during development
3. **Documentation** - This living document tracks violations and fix priorities

## Current Status (as of 2025-09-06)

**Total Violations Found: 1,421**

## Guardrails in Place

### 1. CI Guards Script (`Scripts/ci-guards.sh`)

#### Critical Architecture Violations

| Guard | Description | Current Count | Priority |
|-------|-------------|---------------|----------|
| `ADHOC_MODELCONTAINER` | Ad-hoc ModelContainer usage outside DI | 5 | 🚨 CRITICAL |
| `SWIFTDATA_UI` | SwiftData imports in UI/ViewModels | 15 | 🚨 CRITICAL |
| `FORCE_TRY` | Force try operations (try!) | 9 | 🚨 CRITICAL |
| `FORCE_UNWRAP` | Force unwrapping operations (!) | 187 | 🚨 CRITICAL |

#### High Priority Architecture Issues

| Guard | Description | Current Count | Priority |
|-------|-------------|---------------|----------|
| `NOTIFICATIONCENTER_CHAT` | NotificationCenter in Chat/AI modules | 2 | ⚠️ HIGH |
| `DIRECT_URLSESSION` | Direct URLSession usage | 1 | ⚠️ HIGH |

#### Code Quality Issues

| Guard | Description | Current Count | Priority |
|-------|-------------|---------------|----------|
| `FILE_SIZE` | Files exceeding 1000 lines | 7 | 📋 MEDIUM |
| `FUNCTION_SIZE` | Functions exceeding 50 lines | 107 | 📋 MEDIUM |
| `TYPE_SIZE` | Types exceeding 300 lines | 22 | 📋 MEDIUM |
| `ACCESS_CONTROL` | Missing access control modifiers | 593 | 📋 MEDIUM |
| `STATE_NOT_PRIVATE` | Non-private @State properties | 14 | 📋 MEDIUM |
| `HARDCODED_STRING` | Hardcoded user-facing strings | 440 | 📋 MEDIUM |
| `TODO_FIXME` | TODO/FIXME comments | 18 | 📋 LOW |
| `DEBUG_PRINT` | Debug print statements | 1 | 📋 LOW |

### 2. SwiftLint Custom Rules (`.swiftlint.yml`)

#### Architecture Boundary Rules

- **`no_swiftdata_in_ui`**: Prevents SwiftData imports in UI/ViewModels (ERROR)
- **`no_notificationcenter_chat`**: Prevents NotificationCenter in Chat/AI modules (ERROR)
- **`no_force_ops`**: Prevents force operations (try!, as!, !) (ERROR)
- **`no_adhoc_modelcontainer`**: Prevents ad-hoc ModelContainer creation (ERROR)
- **`require_mainactor_viewmodels`**: Ensures ViewModels have @MainActor (WARNING)
- **`no_direct_urlsession`**: Prevents direct URLSession usage (WARNING)
- **`no_public_state`**: Prevents public @State properties (WARNING)

## Major Violations to Fix

### 1. SwiftData Architecture Violations (20 files)

**Issue**: UI/ViewModels directly importing SwiftData instead of using repositories.

**Files with violations**:
- `AirFit/Modules/Workouts/Views/WorkoutListView.swift`
- `AirFit/Modules/Workouts/Views/WorkoutDetailView.swift`
- `AirFit/Modules/Workouts/Views/WorkoutDashboardView.swift`
- `AirFit/Modules/Settings/Views/SettingsListView.swift`
- `AirFit/Modules/Dashboard/Views/*` (multiple files)
- And 15+ other files

**Fix Strategy**: Replace direct SwiftData access with repository pattern through DI.

### 2. Ad-hoc ModelContainer Creation (5 files)

**Issue**: ModelContainer being created directly in views instead of using DI.

**Files with violations**:
- `AirFit/Modules/Workouts/Views/WorkoutDashboardView.swift:1105`
- `AirFit/Modules/Body/Views/BodyDashboardView.swift:1014`
- `AirFit/Modules/Dashboard/Views/DashboardView.swift:219`
- `AirFit/Modules/Dashboard/Views/NutritionDashboardView.swift:936`
- `AirFit/Modules/Dashboard/Views/TodayDashboardView.swift:632`

**Fix Strategy**: Use existing DI container or create proper service layer.

### 3. Force Operations (196 total)

**Critical safety violations** requiring immediate attention:
- 187 force unwraps (!)
- 9 force try operations (try!)

**Fix Strategy**: Replace with safe handling patterns (guard/if let/nil coalescing).

### 4. NotificationCenter in Chat/AI (2 files)

**Issue**: Using NotificationCenter instead of proper streaming protocols.

**Files**:
- `AirFit/Modules/Chat/ViewModels/ChatViewModel.swift:57`
- `AirFit/Modules/AI/ConversationManager.swift:82`

**Fix Strategy**: Implement ChatStreamingStore protocol.

## Fix Priorities

### Phase 1: Critical Safety Issues
1. **Force Operations** (196 violations) - Replace with safe handling
2. **Ad-hoc ModelContainer** (5 violations) - Use DI pattern

### Phase 2: Architecture Compliance
1. **SwiftData UI Violations** (15 violations) - Implement repository pattern
2. **NotificationCenter in Chat** (2 violations) - Use proper streaming

### Phase 3: Code Quality
1. **Large Files/Functions** (136 violations) - Refactor for maintainability
2. **Access Control** (593 violations) - Add proper access modifiers
3. **Hardcoded Strings** (440 violations) - Implement localization

## Enforcement Strategy

### Development Time
- SwiftLint runs in Xcode providing real-time feedback
- Custom rules catch architecture violations immediately
- Build failures on critical violations

### CI Pipeline
- `Scripts/ci-guards.sh` runs on every push
- Currently in monitoring mode (doesn't fail CI)
- Plan to enforce failure on critical violations

### Future Enhancements
- Automated fix suggestions
- Integration with code review process
- Metrics tracking over time

## Running the Guardrails

### Full Analysis
```bash
Scripts/ci-guards.sh
```

### SwiftLint Only
```bash
swiftlint lint --config AirFit/.swiftlint.yml
```

### View Current Violations
```bash
cat ci-guards-violations.txt
```

## Exclusions and Exceptions

### Allowed Force Operations
- Test files (`**/Tests/**`, `**/Previews/**`)
- ExerciseDatabase.swift (legacy data loading)

### Allowed ModelContainer Creation
- DI/Bootstrapper classes
- Test utilities
- App entry point
- Data managers

### Allowed SwiftData Imports
- Data layer (Repositories, Managers)
- Service layer
- Test utilities

## Maintenance

This document should be updated:
- After each guardrails run
- When new rules are added
- When violations are fixed
- Before major releases

---

*Last updated: 2025-09-06*
*Total violations: 1,421*
*Script version: Enhanced with architecture checks*