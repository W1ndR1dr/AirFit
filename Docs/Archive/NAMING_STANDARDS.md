# AirFit Naming Standards

## Overview
Consistent naming prevents confusion, reduces refactoring, and makes the codebase more maintainable. These standards apply to all code and documentation.

## Swift Code Naming

### Files
- **Views**: `DescriptiveNameView.swift` (e.g., `PersonaSelectionView.swift`)
- **ViewModels**: `FeatureNameViewModel.swift` (e.g., `ChatViewModel.swift`)
- **Coordinators**: `ModuleNameCoordinator.swift` (e.g., `OnboardingCoordinator.swift`)
- **Services**: `ServiceName.swift` (e.g., `UserService.swift`, `WorkoutService.swift`)
- **Protocols**: `ServiceNameProtocol.swift` (e.g., `AIServiceProtocol.swift`)
- **Models**: `ModelName.swift` (singular, e.g., `User.swift`, `Workout.swift`)
- **Tests**: `ComponentNameTests.swift` (e.g., `PersonaEngineTests.swift`)

### Classes/Structs/Protocols
```swift
// Protocol names describe capabilities
protocol AIServiceProtocol { }  // NOT: AIServiceProtocolInterface

// Concrete implementations use clean names (no "Default" prefix)
class AIService: AIServiceProtocol { }  // NOT: DefaultAIService, AIServiceImpl

// Mock implementations prefix with "Mock"
class MockAIService: AIServiceProtocol { }  // NOT: AIServiceMock, TestAIService

// Specialized implementations are descriptive
class OfflineAIService: AIServiceProtocol { }  // Alternative implementation
class ProductionAIService: AIServiceProtocol { }  // When multiple variants exist
```

## Documentation Naming

### File Types & Prefixes
- **Guides**: `GUIDE_PURPOSE.md` (e.g., `GUIDE_TESTING.md`)
- **Analysis**: `ANALYSIS_TOPIC.md` (e.g., `ANALYSIS_ARCHITECTURE.md`)
- **Plans**: `PLAN_INITIATIVE.md` (e.g., `PLAN_CLEANUP.md`)
- **Status**: `STATUS_PROJECT.md` (e.g., `STATUS_MODULE_12.md`)
- **Phases**: `PHASE_N_DESCRIPTION.md` (e.g., `PHASE_1_CRITICAL_FIXES.md`)

### Rules
1. **ALL_CAPS_WITH_UNDERSCORES** for documentation
2. **Prefix indicates type** (GUIDE_, PLAN_, etc.)
3. **No dates in filenames** - use git history
4. **No version numbers** - use git tags
5. **No "NEW" or "OLD"** - archive old files instead

### Bad Examples (What NOT to do)
```
❌ README_NEW.md          → Use README.md, archive old one
❌ Module8.5.md           → Use MODULE_8_FEATURE_NAME.md
❌ cleanup-v2-final.md    → Use PLAN_CLEANUP.md
❌ START_HERE.md          → Use README.md with clear sections
❌ REVISED_PLAN.md        → Update original, archive if needed
```

### Directory Structure
```
Docs/
├── README.md                    # Overview and index
├── Guides/                      # How-to documentation
│   ├── GUIDE_TESTING.md
│   └── GUIDE_ARCHITECTURE.md
├── Plans/                       # Project plans
│   ├── PLAN_CLEANUP.md
│   └── STATUS_CLEANUP.md
└── Archive/                     # Old/superseded docs
    └── 2025_01/                 # Year_Month folders
        └── PLAN_CLEANUP_V1.md
```

## Test Naming

### Test Methods
```swift
// Pattern: test_methodName_givenCondition_shouldExpectedResult
func test_generatePersona_givenValidInput_shouldReturnWithinThreeSeconds()
func test_parseJSON_givenMalformedData_shouldThrowError()

// UI Tests add user perspective
func test_onboarding_whenUserTapsSkip_shouldShowDashboard()
```

### Test Files Organization
```
ModuleNameTests/
├── Unit/
│   ├── ViewModelTests.swift
│   └── ServiceTests.swift
├── Integration/
│   └── ModuleIntegrationTests.swift
└── Mocks/
    └── MockServices.swift
```

## API & Network

### Endpoints
- Use lowercase with hyphens: `/api/user-profile`
- Version in path: `/api/v1/workouts`
- Resource names are plural: `/users`, `/workouts`

### JSON Keys
- Use camelCase: `{ "userId": 123, "workoutName": "..." }`
- Match Swift property names where possible

## Module Structure

### Standard Module Layout
```
ModuleName/
├── Coordinators/
│   └── ModuleNameCoordinator.swift
├── Models/
│   └── ModuleNameModels.swift
├── Services/
│   └── ModuleNameService.swift
├── ViewModels/
│   └── ModuleNameViewModel.swift
└── Views/
    └── ModuleNameView.swift
```

## Accessibility Identifiers

Pattern: `module.component.element`
```swift
.accessibilityIdentifier("onboarding.welcome.continueButton")
.accessibilityIdentifier("dashboard.nutrition.addFoodButton")
.accessibilityIdentifier("chat.input.sendButton")
```

## Git Commits

### Branch Names
- Feature: `feature/module-description` (e.g., `feature/chat-voice-input`)
- Fix: `fix/issue-description` (e.g., `fix/persona-generation-crash`)
- Cleanup: `cleanup/area-description` (e.g., `cleanup/force-casts`)

### Commit Messages
Follow conventional commits:
```
type(scope): description

feat(chat): add voice input support
fix(persona): handle malformed JSON responses
refactor(di): migrate to ServiceRegistry
docs(cleanup): add naming standards
```

## Common Mistakes to Avoid

1. **Duplicate Protocol Names**
   ```swift
   ❌ APIKeyManagerProtocol & APIKeyManagementProtocol
   ✅ APIKeyManagerProtocol (single, clear name)
   ```

2. **Inconsistent Service Naming**
   ```swift
   ❌ DefaultAIService, UserServiceImpl, MockWeatherSvc
   ✅ AIService, UserService, MockWeatherService
   ```

3. **Vague Documentation Names**
   ```
   ❌ notes.md, TODO.md, ideas_v2.md
   ✅ PLAN_FEATURE_X.md, ANALYSIS_PERFORMANCE.md
   ```

4. **Module Inconsistency**
   ```
   ❌ foodTracking/, Notifications/, chat_module/
   ✅ FoodTracking/, Notifications/, Chat/
   ```

## Enforcement

1. **SwiftLint Rules**: Configure for naming conventions
2. **PR Reviews**: Check naming compliance
3. **Documentation Reviews**: Ensure docs follow standards
4. **Regular Audits**: Clean up drift quarterly

## When to Break Rules

Sometimes breaking conventions is necessary:
- External API requirements
- Framework constraints
- Legacy system integration

Document why in comments:
```swift
// Named to match external API expectation
struct user_profile: Codable { }
```

---
*Last updated: January 2025*