# File Naming Standards

## Overview
Consistent file naming is **CRITICAL** for preventing duplicate implementations, confusion about canonical versions, and wasted development effort. These standards apply to ALL files in the AirFit codebase.

## Core Principles
1. **Predictability**: Developers should know exactly what a file is named without searching
2. **Searchability**: Patterns like `Mock*.swift` should find all relevant files
3. **Uniqueness**: Names should prevent accidental duplication
4. **Clarity**: File names should clearly indicate purpose and type

## Naming Patterns

### 1. Services
**Pattern**: `{Feature}Service.swift`
```
✅ CORRECT:
WeatherService.swift
AIService.swift
UserService.swift
NotificationService.swift

❌ INCORRECT:
WeatherKitService.swift      // Don't include implementation details
DefaultUserService.swift     // No "Default" prefix
ProductionAIService.swift    // No environment prefixes
SimpleMockAIService.swift    // Mocks follow different pattern
```

### 2. Service Protocols
**Pattern**: `{Feature}ServiceProtocol.swift`
```
✅ CORRECT:
WeatherServiceProtocol.swift
AIServiceProtocol.swift
UserServiceProtocol.swift

❌ INCORRECT:
IWeatherService.swift        // No "I" prefix
WeatherServiceInterface.swift // Use "Protocol" not "Interface"
WeatherProtocol.swift        // Include "Service" for clarity
```

### 3. Mock Services
**Pattern**: `Mock{Feature}Service.swift` (SINGULAR)
```
✅ CORRECT:
MockWeatherService.swift
MockAIService.swift
MockUserService.swift

❌ INCORRECT:
MockWeatherServices.swift    // No plural
SimpleMockAIService.swift    // No extra qualifiers
MockWeather.swift           // Include "Service"
TestWeatherService.swift    // Use "Mock" not "Test"
```

### 4. ViewModels
**Pattern**: `{Feature}ViewModel.swift`
```
✅ CORRECT:
DashboardViewModel.swift
OnboardingViewModel.swift
ChatViewModel.swift

❌ INCORRECT:
DashboardVM.swift           // No abbreviations
DashboardViewModelImpl.swift // No "Impl" suffix
DashboardController.swift    // Use "ViewModel" for MVVM
```

### 5. Models
**Pattern**: `{Feature}Models.swift` (PLURAL for collections)
```
✅ CORRECT:
DashboardModels.swift       // Multiple related models
ChatModels.swift
OnboardingModels.swift

❌ INCORRECT:
DashboardModel.swift        // Use plural for collections
DashboardTypes.swift        // Use "Models" not "Types"
DashboardStructs.swift      // Use "Models" regardless of type
```

**Exception**: Single model files use singular
```
✅ CORRECT:
User.swift                  // Single model
Workout.swift
FoodEntry.swift
```

### 6. Extensions
**Pattern**: `{Type}+{Purpose}.swift`
```
✅ CORRECT:
Date+Formatting.swift       // Specific purpose
String+Validation.swift
Color+Theme.swift
View+Modifiers.swift

❌ INCORRECT:
DateExtensions.swift        // Use + notation
Date+Extensions.swift       // Too generic
Date+Ext.swift             // No abbreviations
Date+Utils.swift           // Be specific about purpose
```

### 7. Coordinators
**Pattern**: `{Feature}Coordinator.swift`
```
✅ CORRECT:
OnboardingCoordinator.swift
DashboardCoordinator.swift
ChatCoordinator.swift

❌ INCORRECT:
OnboardingFlowCoordinator.swift  // No "Flow" unless needed
OnboardingCoord.swift           // No abbreviations
```

### 8. Error Types
**Pattern**: `{Feature}Error.swift` or use `AppError` with extensions
```
✅ CORRECT:
AppError.swift              // Central error type
AppError+AI.swift          // Domain-specific extensions
NetworkError.swift         // If truly separate

❌ INCORRECT:
AIErrors.swift             // Singular for enums
ErrorTypes.swift           // Too generic
Errors.swift               // Include domain
```

### 9. Test Files
**Pattern**: `{OriginalFileName}Tests.swift`
```
✅ CORRECT:
DashboardViewModelTests.swift
WeatherServiceTests.swift
UserTests.swift

❌ INCORRECT:
TestDashboardViewModel.swift    // "Tests" suffix, not prefix
DashboardViewModelTest.swift    // Use plural "Tests"
DashboardVM_Tests.swift         // No underscores or abbreviations
```

### 10. Configuration Files
**Pattern**: `{Purpose}Configuration.swift`
```
✅ CORRECT:
RoutingConfiguration.swift
ServiceConfiguration.swift
AppConfiguration.swift

❌ INCORRECT:
RoutingConfig.swift        // No abbreviations
Config.swift               // Too generic
Settings.swift             // Use "Configuration"
```

## Special Cases

### 1. SwiftData Models
Follow single model pattern:
```
User.swift
Workout.swift
ChatMessage.swift
```

### 2. View Components
For reusable view components:
```
{Feature}Card.swift         // Dashboard cards
{Feature}Row.swift          // List rows
{Feature}Button.swift       // Custom buttons
```

### 3. Utilities
For utility classes/structs:
```
{Purpose}Manager.swift      // NotificationManager.swift
{Purpose}Helper.swift       // KeychainHelper.swift
{Purpose}Builder.swift      // RequestBuilder.swift
```

## Migration Priority

### Phase 1 - Critical Renames (Immediate)
1. `ProductionAIService.swift` → `AIService.swift`
2. `SimpleMockAIService.swift` → Delete (use `MockAIService.swift`)
3. `WeatherKitService.swift` → `WeatherService.swift`

### Phase 2 - Mock Consolidation
1. `MockDashboardServices.swift` → Split into individual mocks
2. `MockVoiceServices.swift` → Split into individual mocks
3. `MockAIFunctionServices.swift` → Split by function

### Phase 3 - Extension Standardization
1. `ModelContainer+Testing.swift` → `ModelContainer+Test.swift`
2. `AIProvider+Extensions.swift` → `AIProvider+Configuration.swift`
3. Review all extensions for specific purposes

## Enforcement

### 1. Code Review Checklist
- [ ] Does the file name match the pattern?
- [ ] Is there already a file serving this purpose?
- [ ] Will this name be clear to future developers?
- [ ] Can it be found with standard search patterns?

### 2. Automated Checks
Consider adding SwiftLint rules:
```yaml
# .swiftlint.yml
custom_rules:
  mock_naming:
    regex: "Mock[A-Z][a-zA-Z]*Services\.swift"
    message: "Mock files should be singular: MockXService.swift"
```

### 3. Documentation Updates
When adding new patterns, update this document FIRST.

## Common Mistakes

### 1. Environment Prefixes
❌ `ProductionAIService.swift`
❌ `DevWeatherService.swift`
✅ Use configuration/DI to handle environments

### 2. Implementation Details in Names
❌ `WeatherKitService.swift`
❌ `URLSessionNetworkClient.swift`
✅ `WeatherService.swift`
✅ `NetworkClient.swift`

### 3. Redundant Type Information
❌ `DashboardViewModelClass.swift`
❌ `UserModelStruct.swift`
✅ `DashboardViewModel.swift`
✅ `User.swift`

### 4. Inconsistent Pluralization
❌ Mix of `MockService.swift` and `MockServices.swift`
✅ Always singular for individual mocks

## Benefits of Consistency

1. **Reduced Duplication**: Clear names prevent recreating existing code
2. **Faster Onboarding**: New developers understand structure immediately
3. **Better AI Assistance**: LLMs pattern-match more effectively
4. **Easier Refactoring**: Find-and-replace works predictably
5. **Cleaner Git History**: Clear what changed from file names alone

## Questions?
When in doubt:
1. Check existing similar files
2. Refer to this guide
3. Choose clarity over brevity
4. Be consistent with existing patterns