# Codex Agent Configuration for AirFit

## Environment Requirements
- Xcode 16.0+ with iOS 18.0 SDK  
- Swift 6.0+
- SwiftLint 0.54.0+ (installed via Homebrew: `brew install swiftlint`)
- iOS Simulator (iPhone 15 Pro with iOS 18.0+)
- macOS 15.0+ (Sonoma) or later for Xcode 16

## Build & Test Commands
run: swiftlint --strict --reporter json
run: xcodebuild -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.0' clean build
run: xcodebuild -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.0' test

## Module-Specific Test Verification
# Run these after implementing each module to verify correctness
run: xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:AirFitTests/OnboardingViewModelTests
run: xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:AirFitUITests/OnboardingFlowUITests

## Coding Standards
- Follow Swift API Design Guidelines (swift.org/documentation/api-design-guidelines)
- Use SwiftUI exclusively for new UI (no UIKit unless interfacing with system APIs)
- Architecture: MVVM pattern with one ViewModel per major View
- All public APIs must have `///` documentation comments
- Use protocols for all dependencies to enable mocking
- All ViewModel state must use `@Published` properties
- Use async/await for all asynchronous operations (no completion handlers)
- Force unwrapping (`!`) is prohibited except in tests
- Enable strict concurrency checking (Swift 6 default)
- Use `@MainActor` for all ViewModels and UI-related classes
- Prefer `Sendable` conformance for data models
- Use structured concurrency with proper actor isolation

## Project Conventions
- File naming: PascalCase matching primary type (e.g., `OnboardingView.swift`)
- Test file naming: `[Component]Tests.swift` in corresponding test target
- Group files by feature in Xcode project navigator
- Use `AppColors`, `AppFonts`, `AppConstants` for all UI styling (no hardcoded values)
- All user-facing strings must use `LocalizedStringKey` or `String(localized:)`
- Accessibility identifiers required for ALL interactive UI elements
- Use semantic color names (e.g., `cardBackground` not `gray3`)

## Testing Requirements
- Unit tests required for all ViewModels and business logic classes
- UI tests required for all major user flows (onboarding, core features)
- Minimum 70% code coverage for ViewModels and Services
- Use in-memory `ModelContainer` for all SwiftData tests
- Mock all external dependencies (no real network calls or HealthKit access in tests)
- Follow AAA pattern (Arrange-Act-Assert) for all tests
- Test naming: `test_methodName_givenCondition_shouldExpectedResult()`

## SwiftData Requirements
- Use `@Model` for all persistent entities
- Define relationships explicitly with `@Relationship`
- Include deletion rules for all relationships
- Use `ModelContainer` with in-memory configuration for tests
- Handle migration with `VersionedSchema` when modifying models
- Leverage iOS 18's enhanced SwiftData features (history tracking, custom stores)
- Use `@Query` with animations for reactive UI updates
- Implement proper actor isolation for background operations

## Error Handling
- All throwing functions must use `async throws` or `Result<Success, Error>`
- Log all errors with `AppLogger.error()`
- User-facing errors must show actionable alert messages
- Network errors must implement retry logic (max 3 attempts)
- Never silently fail - always log or alert

## Git Workflow
- Create feature branches from 'Codex1' branch
- Atomic commits: One logical change per commit
- Commit message format: `Type: Brief description (max 50 chars)`
  - Types: `Feat`, `Fix`, `Test`, `Docs`, `Refactor`, `Style`, `Perf`
- All commits must pass SwiftLint and compile without warnings
- Squash commits before merging if more than 5 commits in PR

## Module Implementation Order
1. Module 1: Core Setup & Configuration (if not complete)
2. Module 2: Data Layer (SwiftData models)
3. Module 0: Testing Foundation & Guidelines
4. Module 3: Onboarding (Persona Blueprint Flow)
5. Modules 4-11: Features (implement in numerical order)
6. Module 12: Integration Testing & Polish

## Documentation Structure
- `Docs/ArchitectureOverview.md` - System design and component relationships
- `Docs/Design.md` - UI/UX specifications and design philosophy
- `Docs/ModuleX.md` - Detailed requirements for each module
- `Docs/TESTING_GUIDELINES.md` - Testing patterns and examples
- `Docs/Agents.md` - Additional AI agent guidance

## Performance Requirements
- App launch to interactive: < 2 seconds
- View transitions: Smooth 60fps animations
- List scrolling: 60fps with 1000+ items
- Memory usage: < 100MB for typical session
- Network timeouts: 30 seconds for API calls

## Before Starting Any Task
1. Read the relevant Module document completely
2. Check for existing code that might conflict
3. Run existing tests to ensure clean baseline
4. Create feature branch with descriptive name

## After Completing Any Task
1. Run `swiftlint --fix` to auto-fix style issues
2. Run all tests to ensure nothing broke
3. Check code coverage meets requirements
4. Commit with descriptive message
5. Update documentation if APIs changed
