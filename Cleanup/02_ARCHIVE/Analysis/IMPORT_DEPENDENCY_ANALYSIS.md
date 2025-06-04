# Import Dependency Analysis Report

## Summary
Analysis of import statements across the AirFit codebase to identify architectural violations and circular dependencies.

## Key Findings

### 1. Views Directly Importing Services (VIOLATION)

#### VoiceSettingsView.swift
- **Location**: `/AirFit/Modules/Chat/Views/VoiceSettingsView.swift`
- **Issue**: Directly uses `WhisperModelManager.shared` instead of going through ViewModel
- **Line**: `@ObservedObject var modelManager = WhisperModelManager.shared`
- **Fix**: Should use ChatViewModel to manage WhisperModelManager interactions

#### DashboardView.swift
- **Location**: `/AirFit/Modules/Dashboard/Views/DashboardView.swift`
- **Issue**: Creates service instances directly in the view
- **Lines**: 
  - `let healthKitManager = HealthKitManager.shared`
  - `let healthKitService = DefaultHealthKitService(...)`
  - `let aiCoachService = DefaultAICoachService(...)`
  - `let nutritionService = DefaultDashboardNutritionService(...)`
- **Fix**: Services should be injected into ViewModel, not created in View

#### FoodLoggingView.swift
- **Location**: `/AirFit/Modules/FoodTracking/Views/FoodLoggingView.swift`
- **Issue**: Creates NutritionService directly
- **Line**: `let nutritionService = NutritionService(modelContext: unsafeModelContext)`
- **Fix**: Should use FoodTrackingViewModel

#### ChatView.swift
- **Location**: `/AirFit/Modules/Chat/Views/ChatView.swift`
- **Issue**: Creates MockAIService in preview
- **Line**: `let mockAIService = MockAIService()`
- **Fix**: Use proper preview services pattern

### 2. Layering Violations

#### Core Layer Dependencies
- **Good**: Core layer only imports system frameworks (Foundation, SwiftUI, SwiftData, etc.)
- **Good**: No imports from Services, Modules, or Data layers

#### Services Layer Dependencies
- **Good**: Services don't import from Modules layer
- **Good**: Services properly depend on Core protocols

#### Data Layer Dependencies
- **Good**: Data layer only imports system frameworks
- **Good**: No imports from higher layers

### 3. Module Cross-Dependencies

#### AI Module
- **CoachEngine**: Depends on PersonaEngine and ConversationManager (same module - OK)
- **PersonaEngine**: No dependency on CoachEngine (no circular dependency)
- **ConversationManager**: No dependency on CoachEngine (no circular dependency)

#### Module Isolation
- **Good**: No direct imports between different modules (Chat, Dashboard, FoodTracking, etc.)
- **Good**: Modules communicate through protocols and coordinators

### 4. Potential Issues

#### DependencyContainer
- **Location**: `/AirFit/Core/Utilities/DependencyContainer.swift`
- **Issue**: Creates SimpleMockAIService as fallback in production code
- **Lines**: 56, 60
- **Risk**: Mock service could be used in production if configuration fails

#### Service Creation in Views
- Multiple views create service instances directly rather than receiving them through dependency injection
- This makes testing difficult and violates MVVM pattern

## Recommendations

1. **Refactor View-Service Dependencies**
   - Move all service creation to ViewModels
   - Views should only interact with ViewModels
   - Use dependency injection for services

2. **Fix WhisperModelManager Usage**
   - Create a VoiceSettingsViewModel to manage WhisperModelManager
   - Remove direct singleton access from views

3. **Improve DependencyContainer**
   - Remove mock service fallback in production
   - Use proper error handling instead of falling back to mocks
   - Consider using a more robust DI framework

4. **Enforce Architecture Rules**
   - Add linting rules to prevent Views from importing Services
   - Document the layering rules clearly
   - Consider using Swift packages to enforce module boundaries

## Architecture Compliance Summary

✅ **Compliant Areas:**
- Core layer imports (no violations)
- Services layer imports (no violations)
- Data layer imports (no violations)
- No circular dependencies between major components
- Module isolation (no cross-module imports)

❌ **Non-Compliant Areas:**
- Views directly creating/using services (4 violations)
- Mock service used as production fallback
- Services created in view initializers instead of injected

## Action Items

1. Create ViewModels for VoiceSettingsView
2. Refactor DashboardView to use dependency injection
3. Move service creation out of view initializers
4. Remove mock service fallback from DependencyContainer
5. Add architecture validation to CI/CD pipeline