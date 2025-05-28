# AGENTS.md

## Sandboxed Environment Notice
- This agent runs in an isolated container without network access
- **NO XCODE AVAILABLE**: Cannot run xcodebuild, xcodegen, swiftlint, or any Xcode commands
- **NO BUILD/TEST CAPABILITY**: Cannot compile, build, or run tests - these will be handled at checkpoints
- Swift compiler available for syntax validation only
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

## Environment Limitations (Sandboxed Agent)
- **NO XCODE**: Xcode is not available in this sandboxed environment
- **NO BUILD TOOLS**: Cannot run xcodebuild, xcodegen, swiftlint, or simulators
- **SWIFT ONLY**: Swift compiler available for basic syntax validation
- **CODE CREATION ONLY**: Focus on writing Swift code, updating project.yml, and documentation
- **BUILD/TEST AT CHECKPOINTS**: All compilation, testing, and verification handled externally

**Local Environment (Cursor/Human):**
- Xcode 16.0+ with iOS 18.0 SDK
- iOS 18.4 Simulator (iPhone 16 Pro) - REQUIRED for builds/tests
- watchOS 11.4 Simulator - Available for Apple Watch testing
- Swift 6.0+ with strict concurrency checking
- SwiftLint 0.54.0+ for code quality
- All build/test commands available locally

## Agent Capabilities (Sandboxed Environment)
**WHAT YOU CAN DO:**
- Write Swift code with proper syntax
- Create and edit files in the project structure
- Update project.yml file configuration
- Read and analyze existing code
- Create comprehensive documentation
- Design architecture and patterns
- Validate Swift 6 concurrency patterns
- Target iOS 18.0+ and watchOS 11.0+ APIs

**WHAT YOU CANNOT DO:**
- Run xcodebuild, xcodegen, or swiftlint commands
- Compile or build the project
- Run tests or simulators
- Install packages or dependencies
- Verify builds work (handled at checkpoints)
- Access network or download dependencies

## Build & Test Commands (NOT AVAILABLE IN SANDBOX)
**⚠️ IMPORTANT**: This sandboxed agent CANNOT run these commands. They are provided for reference only.

**Build/test verification happens at checkpoints where a local agent with Xcode will:**
- Run `swiftlint --strict` for code quality
- Execute `xcodebuild` commands for compilation
- Run `xcodegen generate` to update project files
- Execute all test suites to verify functionality

**Your job as sandboxed agent:**
- Write the Swift code
- Update project.yml with new files
- Create comprehensive tests (code only)
- Document your implementation
- Leave build/test verification for checkpoint validation

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

## iOS 18 Features (Target: iOS 18.4 Simulator)
- SwiftData with history tracking
- @NavigationDestination for navigation
- Swift Charts for data visualization
- HealthKit granular permissions
- Control Widget extensions
- @Previewable macro for previews
- ScrollView content margins
- Enhanced Voice Recognition APIs
- Improved Metal Performance Shaders
- Advanced SwiftUI animations and transitions

**Testing Environment:**
- iOS 18.4 Simulator (iPhone 16 Pro) - Primary testing target
- watchOS 11.4 Simulator - Apple Watch testing
- All features must be compatible with iOS 18.0+ deployment target

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

## Module Structure (Follow Schema Below)
**Completed**: Dashboard, Settings, Onboarding  
**Missing**: MealLogging, Progress, MealDiscovery, AICoach, Health, Notifications

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
1. Module 0: Testing Foundation (guidelines, mocks, test patterns)
2. Module 1: Core Setup
3. Module 2: Data Layer
4. Module 3: Onboarding
5. Module 4: HealthKit & Context Aggregation Module
6. Module 5: AI Persona Engine & CoachEngine
7. Module 6: Dashboard Module (UI & Logic)
8. Module 7: Workout Logging Module (iOS & WatchOS)
9. Module 8: Food Tracking Module (Voice-First AI-Powered Nutrition)
10. Module 9: Notifications & Engagement Engine
11. Module 10: Services Layer (API Clients, Multi-Provider AI Support)
12. Module 11: Settings Module (UI & Logic)
13. Module 12: Testing & Quality Assurance Framework
14. Module 13: Chat Interface Module (AI Coach Interaction)

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



## Post-Implementation Checklist (Sandboxed Agent)

### 1. **Code Creation Verification** ✅ YOU CAN DO
- [ ] All Swift files created with proper syntax
- [ ] All test files written (code only, no execution)
- [ ] project.yml updated with new file entries
- [ ] Documentation updated
- [ ] Code follows Swift 6 and iOS 18 patterns

### 2. **File Structure Verification** ✅ YOU CAN DO
- [ ] Files placed in correct module directories
- [ ] Naming conventions followed
- [ ] Import statements correct
- [ ] Protocol conformances implemented

### 3. **Checkpoint Handoff** ⚠️ FOR LOCAL AGENT
**The following will be verified at checkpoint by local agent with Xcode:**
- [ ] XcodeGen project regeneration
- [ ] SwiftLint compliance check
- [ ] Clean build verification
- [ ] Test suite execution
- [ ] Performance validation
- [ ] Git commit and push

### 4. **Your Deliverables Summary**
When handing off to checkpoint, provide:
- List of all files created/modified
- project.yml changes made
- Brief description of implementation
- Any known issues or considerations
- Test coverage summary (theoretical)

## XcodeGen File Inclusion Schema

### CRITICAL: Target-Specific File Assignment

Our `project.yml` defines 3 targets with specific file inclusion rules:

#### 1. **AirFit** (Main App Target)
```yaml
sources:
  - path: AirFit
    includes: ["**/*.swift"]
    excludes: ["**/*.md", "**/.*", "AirFitTests/**", "AirFitUITests/**"]
  # EXPLICIT FILES (due to XcodeGen nesting bug):
  - AirFit/Modules/{ModuleName}/...
  - AirFit/Data/Models/...
  - AirFit/Core/...
  - AirFit/Services/...
  - AirFit/Application/...
```

#### 2. **AirFitTests** (Unit Test Target)
```yaml
sources:
  - path: AirFit/AirFitTests
    includes: ["**/*.swift"]
  # EXPLICIT TEST FILES:
  - AirFit/AirFitTests/Onboarding/OnboardingServiceTests.swift
  - AirFit/AirFitTests/Onboarding/OnboardingFlowViewTests.swift
  - AirFit/AirFitTests/Onboarding/OnboardingViewTests.swift
```

#### 3. **AirFitUITests** (UI Test Target)
```yaml
sources:
  - path: AirFit/AirFitUITests
    includes: ["**/*.swift"]
```

### XcodeGen Nesting Bug Workaround

**Problem**: `**/*.swift` glob pattern fails for nested directories like `AirFit/Modules/*/`  
**Root Cause**: XcodeGen doesn't properly expand globs in nested module structures  
**Solution**: Explicitly list ALL files in nested directories

### File Addition Workflow (Sandboxed Agent)

#### For Main App Files:
1. ✅ Create file in appropriate directory
2. ✅ Add to project.yml under AirFit target sources
3. ⚠️ **CHECKPOINT**: Regenerate project (`xcodegen generate`)
4. ⚠️ **CHECKPOINT**: Verify inclusion in project.pbxproj

#### For Test Files:
1. ✅ Create test file in AirFit/AirFitTests/
2. ✅ Add to project.yml under AirFitTests target sources  
3. ⚠️ **CHECKPOINT**: Regenerate project (`xcodegen generate`)
4. ⚠️ **CHECKPOINT**: Verify inclusion in project.pbxproj

**Your Role**: Create files and update project.yml  
**Checkpoint Role**: Run xcodegen and verify inclusion

### Verification Commands (CHECKPOINT ONLY)
**⚠️ These commands are NOT available in sandbox - for checkpoint reference only:**

```bash
# Check if file is included in project
grep -c "FileName" AirFit.xcodeproj/project.pbxproj

# If count = 0: File missing, add to project.yml
# If count > 0: File included successfully

# Verify build includes your files
xcodebuild clean build 2>&1 | grep "YourFileName"
```

**Sandboxed Agent**: Focus on creating files and updating project.yml correctly

### Module File Template
```yaml
# Add to AirFit target sources in project.yml:
- AirFit/Modules/{ModuleName}/Models/{ModuleName}Models.swift
- AirFit/Modules/{ModuleName}/ViewModels/{ModuleName}ViewModel.swift
- AirFit/Modules/{ModuleName}/Views/{ModuleName}FlowView.swift
- AirFit/Modules/{ModuleName}/Views/{Feature}View.swift
- AirFit/Modules/{ModuleName}/Services/{ModuleName}Service.swift
- AirFit/Modules/{ModuleName}/Services/{ModuleName}ServiceProtocol.swift
```

### Test File Template
```yaml
# Add to AirFitTests target sources in project.yml:
- AirFit/AirFitTests/{ModuleName}/{ModuleName}ServiceTests.swift
- AirFit/AirFitTests/{ModuleName}/{ModuleName}ViewModelTests.swift
- AirFit/AirFitTests/{ModuleName}/{ModuleName}ViewTests.swift
```

## Module 8 (Food Tracking) Specific Requirements

### WhisperKit Integration
- **Dependency**: WhisperKit Swift package (https://github.com/argmaxinc/WhisperKit.git)
- **Version**: 0.9.0 or newer
- **Model**: Uses MLX-optimized Whisper models (mlx-community/whisper-large-v3-mlx)
- **Memory**: Large model requires ~1.6GB RAM
- **Performance**: 2-5s cold start, real-time warm inference
- **Platform**: iOS 17.0+ required for optimal performance

### VoiceInputManager Dependency
- **CRITICAL**: Module 8 requires VoiceInputManager from Module 13 (Chat Interface)
- **Location**: `AirFit/Modules/Chat/Services/VoiceInputManager.swift`
- **Integration**: Module 8 creates adapter pattern around existing VoiceInputManager
- **Fallback**: If Module 13 not complete, implement VoiceInputManager first

### Audio Permissions
```xml
<!-- Required in Info.plist -->
<key>NSMicrophoneUsageDescription</key>
<string>AirFit uses your microphone to log food through voice input for convenient nutrition tracking.</string>
```

### Performance Targets (Module 8)
- Voice transcription: <2s latency
- AI food parsing: <5s response time
- Food search: <1s response time
- UI animations: 60fps
- Memory usage: <100MB typical, <1.8GB with large model

## Module 13 (Chat Interface) Documentation References

### **Current Implementation Target: Module 13**
The project is currently implementing **Module 13: Chat Interface Module** with comprehensive WhisperKit voice integration.

### **Key Documentation Files:**
- **`/MODULE13_PROMPT_CHAIN.md`** - Complete implementation prompt chain with all tasks, acceptance criteria, and sequencing
- **`/AirFit/Docs/Module13.md`** - Detailed technical specifications and requirements
- **`/AirFit/Docs/Research Reports/MLX Whisper Integration Report.md`** - WhisperKit optimization research
- **`/AirFit/Docs/Research Reports/Codex Optimization Report.md`** - Agent best practices

### **Task Context:**
Even if you receive a single task prompt (e.g., "Implement Task 13.1.2"), you should:
1. **Reference the full prompt chain** in `MODULE13_PROMPT_CHAIN.md` for context
2. **Check dependencies** and prerequisites from other tasks
3. **Follow the acceptance criteria** specified in the prompt chain
4. **Maintain consistency** with the overall module architecture
5. **Verify file placement** matches the project structure in the prompt chain

### **Implementation Strategy:**
- Module 13 provides the **foundation voice infrastructure** for the entire app
- WhisperKit integration is **centralized** in Module 13's VoiceInputManager
- Module 8 (Food Tracking) will **consume** Module 13's voice services via adapter pattern
- All voice-related features should be **consistent** across modules
