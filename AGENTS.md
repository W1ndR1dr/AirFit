# AGENTS.md

## Sandboxed Environment Notice
- This agent runs in an isolated container without network access
- **NO XCODE**: Cannot run xcodebuild, xcodegen, swiftlint, or any Xcode commands
- **NO BUILD/TEST**: Cannot compile, build, or run tests - handled at checkpoints
- Swift compiler available for syntax validation only
- All project documentation available locally in /AirFit/Docs/
- Research reports in /AirFit/Docs/Research Reports/

## Agent Capabilities
**WHAT YOU CAN DO:**
- Write Swift code with proper syntax
- Create and edit files in project structure
- Update project.yml file configuration
- Read and analyze existing code
- Create comprehensive documentation
- Design architecture and patterns

**WHAT YOU CANNOT DO:**
- Run any build/test commands
- Compile or verify builds work
- Install packages or dependencies
- Access network or download dependencies
- Verify functionality (handled at checkpoints)

## Swift 6 Requirements
- All ViewModels: @MainActor @Observable
- All data models: Sendable
- Use actor isolation for services
- Async/await for all asynchronous operations
- No completion handlers

## Architecture Pattern
- MVVM-C (Model-View-ViewModel-Coordinator)
- ViewModels handle business logic and state
- Views are purely declarative SwiftUI
- Coordinators manage navigation flow
- Services handle data operations
- Dependency injection via protocols

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
```

## Testing Standards
- Unit tests for all business logic
- AAA pattern (Arrange-Act-Assert)
- In-memory ModelContainer for SwiftData tests
- Mock all external dependencies
- Test naming: test_method_givenCondition_shouldResult()

## XcodeGen File Inclusion Schema

### CRITICAL: All files must be explicitly listed in project.yml

**Main App Files:**
```yaml
# Add to AirFit target sources:
- AirFit/Modules/{ModuleName}/ViewModels/{ClassName}.swift
- AirFit/Modules/{ModuleName}/Views/{ClassName}.swift
- AirFit/Modules/{ModuleName}/Services/{ClassName}.swift
```

**Test Files:**
```yaml
# Add to AirFitTests target sources:
- AirFit/AirFitTests/{ModuleName}/{ClassName}Tests.swift
```

## Module 8 Specific Requirements

### WhisperKit Integration
- **Dependency**: WhisperKit Swift package (0.9.0+)
- **Model**: Device-specific selection (base/medium/large-v3)
- **Memory**: Large model requires ~1.6GB RAM
- **Performance**: 2-5s cold start, real-time warm inference

### VoiceInputManager Dependency
- **CRITICAL**: Extract to `AirFit/Services/Speech/VoiceInputManager.swift`
- **Shared Service**: Used by both Module 8 and Module 13
- **Integration**: WhisperKit adapter with device-specific model selection

### Audio Permissions
```xml
<key>NSMicrophoneUsageDescription</key>
<string>AirFit uses your microphone to log food through voice input.</string>
```

## Post-Implementation Checklist

### Your Deliverables
- [ ] All Swift files created with proper syntax
- [ ] All test files written (code only)
- [ ] project.yml updated with new file entries
- [ ] Documentation updated
- [ ] Code follows Swift 6 patterns

### Checkpoint Handoff
Provide:
- List of all files created/modified
- project.yml changes made
- Brief implementation description
- Any known issues or considerations
- Test coverage summary
