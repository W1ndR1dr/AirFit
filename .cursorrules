# AGENTS.md

## Sandboxed Environment Notice
- This agent runs in an isolated container without network access
- All project documentation is available locally in /AirFit/Docs/
- Research reports and analysis are stored in /AirFit/Docs/Research Reports/
- New research reports may be added during development
- Consult existing documentation before requesting external information

## Requesting External Research
When external information is needed:
1. Create a file: `/AirFit/Docs/Research Reports/REQUEST_[Topic].md`
2. Include:
   - Specific questions needing answers
   - Context about why information is needed
   - Expected format for response
3. Example filename: `REQUEST_HealthKitAPI.md`
4. Check for response in: `RESPONSE_[Topic].md`

## Environment Requirements
- Xcode 16.0+ with iOS 18.0 SDK
- Swift 6.0+ with strict concurrency
- SwiftLint 0.54.0+ 
- macOS 15.0+ (Sequoia)
- iPhone 16 Pro Simulator or physical device with iOS 18.0+

## Environment Setup Script
run: |
  # Install SwiftLint if not present
  if ! command -v swiftlint &> /dev/null; then
    brew install swiftlint || mint install realm/SwiftLint
  fi
  
  # Verify Xcode version
  xcodebuild -version | grep -E "Xcode 16" || echo "ERROR: Xcode 16+ required for iOS 18 SDK"
  
  # Verify Swift version
  swift --version | grep -E "Swift version 6" || echo "ERROR: Swift 6+ required"
  
  # Install xcbeautify for readable test output (optional)
  if ! command -v xcbeautify &> /dev/null; then
    brew install xcbeautify
  fi
  
  # Verify iOS 18 SDK
  xcodebuild -showsdks | grep -E "iOS 18" || echo "ERROR: iOS 18 SDK not found"

## Build Commands
```bash
swiftlint --strict
xcodebuild -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' clean build
xcodebuild -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' test
```

## Test Commands
```bash
# Module 0 - Testing Foundation
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/TestingFoundationTests

# Module 1 - Core Setup
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/CoreSetupTests

# Module 2 - Data Layer
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/DataLayerTests

# Module 3 - Onboarding
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/OnboardingViewModelTests
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitUITests/OnboardingFlowUITests

# Module 4 - Dashboard
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/DashboardTests

# Module 5 - Meal Logging
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/MealLoggingTests

# Module 6 - Progress Tracking
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/ProgressTrackingTests

# Module 7 - Settings
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/SettingsTests

# Module 8 - Meal Discovery
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/MealDiscoveryTests

# Module 9 - AI Coach
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/AICoachTests

# Module 10 - Health Integration
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/HealthIntegrationTests

# Module 11 - Notifications
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitTests/NotificationTests

# Module 12 - Integration
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AirFitUITests/IntegrationTests
```

## Project Structure
```
AirFit/
├── Core/
│   ├── Constants/
│   ├── Extensions/
│   ├── Theme/
│   └── Utilities/
├── Modules/
│   ├── Dashboard/
│   ├── Onboarding/
│   ├── MealLogging/
│   ├── Progress/
│   ├── Settings/
│   ├── MealDiscovery/
│   ├── AICoach/
│   ├── Health/
│   └── Notifications/
├── Assets.xcassets/
├── Docs/
└── Tests/
```

## Swift 6 Requirements
- Enable complete concurrency checking
- All ViewModels: @MainActor @Observable
- All data models: Sendable
- Use actor isolation for services
- Async/await for all asynchronous operations
- No completion handlers

## iOS 18 Features
- SwiftData with history tracking
- @NavigationDestination for navigation
- Swift Charts for data visualization
- HealthKit granular permissions
- Control Widget extensions
- @Previewable macro for previews
- ScrollView content margins

## Architecture Pattern
- MVVM-C (Model-View-ViewModel-Coordinator)
- ViewModels handle business logic and state
- Views are purely declarative SwiftUI
- Coordinators manage navigation flow
- Services handle data operations
- Dependency injection via protocols

## Code Organization
```
Module/
├── Views/              # SwiftUI views
├── ViewModels/         # @Observable ViewModels
├── Models/             # Data models (Sendable)
├── Services/           # Business logic and API
├── Coordinators/       # Navigation management
└── Tests/              # Unit and UI tests
```

## Required Module Structure
Each module in /AirFit/Modules/ must have:
- Models/ folder (if module has data models)
- Views/ folder
- ViewModels/ folder
- Services/ folder (if module needs services)
- Coordinators/ folder (for navigation)

Note: Currently only Dashboard and Settings modules exist.
Missing modules that need creation:
- Onboarding, MealLogging, Progress, MealDiscovery, 
- AICoach, Health, Notifications

## Code Style Format
```swift
// MARK: - View
struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    
    var body: some View {
        // SwiftUI content
    }
}

// MARK: - ViewModel
@MainActor
@Observable
final class OnboardingViewModel {
    private(set) var state: ViewState = .idle
    private let service: ServiceProtocol
    
    init(service: ServiceProtocol) {
        self.service = service
    }
}

// MARK: - Service Protocol
protocol OnboardingServiceProtocol: Sendable {
    func saveProfile(_ profile: Profile) async throws
}

// MARK: - Coordinator
@MainActor
final class OnboardingCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func showNextScreen() {
        path.append(OnboardingRoute.profileSetup)
    }
}
```

## Coding Standards
- Swift API Design Guidelines
- SwiftUI only (no UIKit)
- Protocol-oriented programming
- /// documentation for public APIs
- Meaningful names (no abbreviations)
- AppColors, AppFonts, AppConstants for styling
- Localizable.strings for all UI text
- Accessibility identifiers on interactive elements

## Testing Standards
- Unit tests for all business logic
- UI tests for major user flows
- 70% minimum code coverage
- AAA pattern (Arrange-Act-Assert)
- In-memory ModelContainer for SwiftData tests
- Mock all external dependencies
- Test naming: test_method_givenCondition_shouldResult()

## Error Handling
- Use Result<Success, Error> or async throws
- User-friendly error messages in alerts
- AppLogger.error() for all errors
- Specific catch blocks for known errors
- Generic fallback for unknown errors

## Git Standards
- Atomic commits
- Format: "Type: Brief description"
- Types: Feat/Fix/Test/Docs/Refactor/Style
- Run tests before commit
- Feature branches from main

## Module Order
1. Module 1: Core Setup
2. Module 2: Data Layer
3. Module 0: Testing Foundation (guidelines, mocks, test patterns)
4. Module 12: Testing & QA Framework (test targets, CI/CD setup)
5. Module 3: Onboarding
6. Module 4: Dashboard
7. Module 5: Meal Logging
8. Module 6: Progress Tracking
9. Module 7: Settings
10. Module 8: Meal Discovery
11. Module 9: AI Coach
12. Module 10: Health Integration
13. Module 11: Notifications
14. Module 13: Chat Interface (AI Coach Interaction)

## Performance Targets
- App launch: < 1.5s
- Transitions: 120fps
- List scrolling: 120fps with 1000+ items
- Memory: < 150MB typical
- SwiftData queries: < 50ms
- Network timeout: 30s

## Documentation References
- Docs/Module*.md for specifications
- Docs/Design.md for UI/UX
- Docs/ArchitectureOverview.md for system design
- Docs/TESTING_GUIDELINES.md for test patterns
- Docs/OnboardingFlow.md for user flow
- Docs/Research Reports/ contains deep research and analysis
- All module documentation is in /AirFit/Docs/
- Research reports may be added during development

## Pre-Implementation Checklist
- [ ] Read module documentation in /AirFit/Docs/
- [ ] Check Research Reports for relevant analysis
- [ ] Review existing implementations
- [ ] Check Design.md for UI specifications
- [ ] Verify module dependencies are complete
- [ ] Create feature branch from main

## Post-Implementation Checklist
- [ ] Run swiftlint --fix
- [ ] Run all tests (unit and UI)
- [ ] Verify 70% code coverage
- [ ] Update relevant documentation
- [ ] Add accessibility identifiers
- [ ] Test on iPhone 16 Pro simulator
- [ ] Verify MVVM-C pattern compliance
- [ ] Commit with descriptive message
