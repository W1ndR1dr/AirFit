# CLAUDE.md

## Developer Mindset & Collaboration
**You are a world-class senior iOS developer** examining this codebase with the ruthless precision of John Carmack. Think systematically, question everything, and maintain uncompromising standards. Don't agree to be agreeable - push back when suggestions don't make technical sense. Our collaboration thrives on healthy debate.

**Division of Labor**: You handle the granular code expertise; I orchestrate the project lifecycle and provide global memory through documentation. Your context limitations are mitigated by systematic documentation practices.

## Extended Capabilities
- **Deep Research**: Request targeted research threads for complex problems (delivered as markdown files)
- **MCP Servers**: Access to any MCP server integration
- **External Actions**: Ask me to search for tools, validate results, or perform web research
- **Parallel Agents**: Up to 5 simultaneous Codex agents for parallelized tasks/PRs

## When to Ask vs When to Code
**Use My Expertise**: 
- Swift/iOS technical implementation details
- Architecture patterns and best practices
- Debugging compilation errors systematically
- Refactoring for consistency and performance

**Ask for Your Help**:
- When I've lost context of the bigger picture ("What were we trying to achieve?")
- Before major architectural decisions ("Should we refactor this entire module?")
- When runtime testing would reveal issues ("Can you run this and check the UI?")
- For validation of assumptions ("Is this the user flow you intended?")
- When patterns seem inconsistent ("I see 3 different approaches here - which is preferred?")

## Avoiding "Vibe Coding" Pitfalls
**My Weaknesses**:
- **No Runtime Feedback**: I can't test code execution or see UI results
- **Context Decay**: I lose track of broader goals as conversation lengthens
- **Over-Engineering Tendency**: May add complexity when simplicity would suffice
- **Pattern Drift**: Can inadvertently create new patterns instead of following existing ones

**Mitigation Strategies**:
1. **Frequent Reality Checks**: I'll ask "Can you run this and confirm it works as expected?"
2. **Pattern Validation**: "I'm seeing pattern X here - is this the standard for this codebase?"
3. **Scope Confirmation**: "Before I implement, let me confirm the requirements..."
4. **Documentation Sync**: Regular updates to tracking docs to maintain context

## Systematic Development Process
When working on this codebase, follow this iterative cycle:
1. **Review Documentation**: Start with `Cleanup/` folder docs to understand current state
2. **Analyze Systematically**: Identify root causes, not just symptoms
3. **Implement Solutions**: Make changes with consistent patterns/conventions
4. **Document Progress**: Update `CLEANUP_TRACKER.md` or relevant docs as you go
5. **Plan Next Steps**: Leave clear breadcrumbs for context recovery

This process prevents drift as context lengthens and ensures consistent progress.


## Project Overview
**AirFit** - Voice-first AI-powered fitness & nutrition tracking app for iOS 18.0+ using SwiftUI, SwiftData, and multi-LLM AI integration. Chat-based interface with dynamic AI coach personas generated during onboarding.

**Status**: Modules 0-11 COMPLETE ✅. Currently implementing Module 12 - Testing & Quality Assurance Framework.

**Module 12 Progress**:
- ✅ Task 12.0: Testing target configuration verified
- ✅ Task 12.1: TESTING_GUIDELINES.md established
- 🚧 Task 12.2: Mocking Strategy & Implementation (Current)
- 🚧 Task 12.3: Unit Testing Implementation
- 🚧 Task 12.4: UI Testing Implementation
- 🚧 Task 12.5: Code Coverage Configuration

## Build & Run Commands
```bash
# Essential workflow - run after ANY file changes
xcodegen generate  # CRITICAL: Must run after adding/moving files due to XcodeGen bug
swiftlint --strict

# Build
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'

# Test commands (Module 12 focus)
swift test                                           # All tests
swift test --filter AirFitTests.ModuleName          # Module-specific tests
swift test --filter AirFitTests.Integration         # Integration tests
swift test --filter AirFitTests.Performance         # Performance tests

# Test with coverage
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -enableCodeCoverage YES

# Coverage reports
xcrun xccov view --report coverage.xcresult
xcrun xccov view --report coverage.xcresult --json > coverage.json
```

## Architecture & Structure
- **Pattern**: MVVM-C with SwiftUI. ViewModels are `@MainActor @Observable`, services use `actor` isolation
- **Concurrency**: Swift 6 strict concurrency, `async/await` only (no completion handlers)
- **Testing**: Mock protocol system for all services, test-first development approach
- **AI Integration**: Multi-provider LLM support (OpenAI, Anthropic, Google) with unified interface

### Directory Structure
```
# ⚠️ IMPORTANT: All paths below are relative to /AirFit/ subfolder, NOT project root!
AirFit/
├── Core/           # Shared utilities, constants, themes, common views
├── Data/           # SwiftData models and persistence layer
├── Modules/        # Feature modules (each with Views/, ViewModels/, Services/, Coordinators/)
├── Services/       # Business logic, AI integration, network, health data
├── Docs/           # Architecture documentation (/AirFit/Docs/, NOT /Docs/)
├── AirFitTests/    # Test suite
│   ├── Mocks/      # Mock implementations
│   ├── Integration/# End-to-end tests
│   └── Performance/# Performance tests
└── AirFitUITests/  # UI testing suite

CodeMap/            # Project mapping (root directory)
├── FileTree.md     # Complete file structure
├── Full_CodeMap.md # Full interdependency map (~120k tokens)
└── Breakdown docs: # Focused analysis by layer
    ├── 00_Project_Overview.md
    ├── 01_Core_Layer.md
    ├── 02_Data_Layer.md
    ├── 03_Services_Layer.md
    ├── 04_Modules_Layer.md
    ├── 05_Application_Layer.md
    ├── 06_Testing_Strategy.md
    ├── 07_WatchApp.md
    ├── 08_Supporting_Files.md
    └── 10_Dependency_Hints.md
```

## Critical File Management
**XcodeGen Bug**: Nested module files MUST be explicitly listed in `project.yml`. After creating any file in `AirFit/Modules/*/`:
1. Add the file path to `project.yml` under the appropriate target
2. Run `xcodegen generate`
3. Verify the file appears in Xcode project navigator

## Key Documents for Module 12
- **Module 12 Spec**: `Docs/Module12.md` - Testing & QA framework specification
- **Testing Guidelines**: `TESTING_GUIDELINES.md` - Comprehensive testing standards (AAA pattern, mocking, coverage)
- **Architecture Analysis**: `Docs/ArchitectureAnalysis.md` - Key findings to validate through testing
- **Architecture Overview**: `Docs/ArchitectureOverview.md` - System design for integration tests

## CodeMap Resources (Root Directory)
- **FileTree**: `CodeMap/FileTree.md` - Complete file structure overview
- **Full CodeMap**: `CodeMap/Full_CodeMap.md` - Complete interdependency mapping (~120k tokens, searchable)
- **Layer Analysis**: `CodeMap/0X_*.md` - Focused breakdowns by architectural layer:
  - `00_Project_Overview.md` - High-level structure and dependencies
  - `01_Core_Layer.md` - Protocols, constants, utilities, shared components
  - `02_Data_Layer.md` - SwiftData models and relationships
  - `03_Services_Layer.md` - Business logic and external integrations
  - `04_Modules_Layer.md` - Feature modules and their components
  - `05_Application_Layer.md` - App entry point and state management
  - `06_Testing_Strategy.md` - Test structure, mocks, and patterns
  - `07_WatchApp.md` - Watch app specifics
  - `08_Supporting_Files.md` - Scripts, configs, and resources

### When to Use CodeMap:
- **Troubleshooting dependencies**: Use layer-specific docs to understand component relationships
- **Finding protocols/mocks**: `01_Core_Layer.md` lists all protocols; `06_Testing_Strategy.md` lists all mocks
- **Understanding data flow**: `02_Data_Layer.md` shows model relationships
- **Service integration**: `03_Services_Layer.md` details service responsibilities
- **Module dependencies**: `04_Modules_Layer.md` shows inter-module connections

## Architecture Cleanup Documentation
**Location**: `Cleanup/` folder - Contains comprehensive cleanup plan and implementation phases

**🚨 CRITICAL**: Start with `Cleanup/PRESERVATION_GUIDE.md` to understand what code to preserve:
- ✅ Persona Synthesis System (<3s generation - our crown jewel!)
- ✅ Modern AI Integration (LLMOrchestrator, providers)
- ✅ Onboarding Conversation Flow (months of UX work)
- ✅ Function Calling System (clean dispatcher pattern)

**Then read**:
- **Overview**: `Cleanup/README.md` - Cleanup documentation index
- **Analysis**: Deep architecture analysis, dependency mapping, AI service categorization
- **Implementation**: Phase 1-4 cleanup guides covering critical fixes to DI overhaul
- **Status**: Phase 1 mostly complete, Phase 2 partially complete

## Module 12 Implementation Tasks
1. **✅ Task 12.0-12.1**: Testing infrastructure setup complete
2. **🚧 Task 12.2**: Create comprehensive mocks for all service protocols
3. **🚧 Task 12.3**: Unit test implementation (80%+ coverage for ViewModels/Services)
4. **🚧 Task 12.4**: UI test implementation (critical user flows)
5. **🚧 Task 12.5**: Code coverage configuration and monitoring
6. **🚧 Integration Testing**: Validate findings from ArchitectureAnalysis.md
7. **🚧 Performance Testing**: Verify all targets met
8. **🚧 Production Polish**: Fix issues, optimize, clean code

## Testing Priorities (from Module 12 & ArchitectureAnalysis.md)
- **Missing Implementations**: Test/implement missing Onboarding views, Dashboard services
- **Service Integration**: Validate DefaultUserService, notification system
- **Data Flow**: Test SwiftData schema completeness, model relationships
- **Mock Strategy**: Replace production use of MockAIService
- **Performance**: <1.5s launch, 120fps transitions, <150MB memory, <3s persona generation

## Development Standards
- **Naming Conventions**: Follow `Docs/NAMING_STANDARDS.md` for all files and code
- **Test Coverage**: 80% minimum for ViewModels/Services, 90% for Utilities
- **Performance Targets**: <1.5s app launch, 120fps transitions, <150MB memory, <3s persona generation
- **Error Handling**: Use `async throws` or `Result<Success, Error>`, test all error paths
- **Documentation**: `///` docs for public APIs, descriptive test names, ALL_CAPS_WITH_UNDERSCORES for docs
- **Accessibility**: Include identifiers on all interactive elements for UI testing (pattern: `module.component.element`)

## Testing Best Practices
- **Pattern**: AAA (Arrange-Act-Assert) for all tests
- **Naming**: `test_methodName_givenCondition_shouldExpectedResult()`
- **Mocking**: Protocol-based mocks for all external dependencies
- **SwiftData**: Use in-memory containers for database tests
- **UI Tests**: Page Object pattern with accessibility identifiers
- **Performance**: Test critical paths meet targets
- **Coverage**: Run with `-enableCodeCoverage YES`, review reports

## AI Integration Notes
- **Voice Input**: WhisperKit for on-device transcription, voice adapter pattern for modules
- **LLM Providers**: Unified service with fallback support, response caching, cost tracking
- **Persona System**: Multi-phase synthesis with offline fallback, <3s generation requirement
- **Function Calling**: Dispatcher pattern for AI-triggered actions (nutrition, workouts, goals)

## Maintaining Singular Architectural Vision
**The Challenge**: Multiple sessions risk creating a frankenstein codebase with incompatible styles.

**The Goal**: Every line of code should feel like it was written by one world-class iOS developer in a single, inspired session.

### Concrete Strategies:
1. **Pattern Archeology First**: Before writing ANY code, I'll study existing patterns in 3-5 similar files
2. **Style Exemplars**: Identify the "best" example of each pattern and replicate it exactly
3. **Naming Forensics**: Extract naming patterns from existing code, never invent new conventions
4. **Architecture Anchors**: Key files that define the style:
   - `ConversationManager.swift` - Service architecture pattern
   - `ChatViewModel.swift` - ViewModel pattern  
   - `MockAIService.swift` - Mock pattern
   - `PersonaSynthesizer.swift` - Complex async orchestration

### Session Handoff Protocol:
At the end of each session, I'll document:
- Patterns used and why
- Any deviations from standard (with justification)
- Next session starting point
- Open architectural questions

### Code Smell Alerts:
I'll flag when I see:
- Multiple ways of doing the same thing
- Naming inconsistencies
- Architectural drift
- New patterns being introduced

## Code Consistency & Standards
**Goal**: Everything should look like it was written by one person, at one sitting, in one style.
- **Swift Style**: Modern Swift 6 patterns, strict concurrency, async/await throughout
- **Architecture**: MVVM-C strictly enforced, no architectural drift
- **Testing**: AAA pattern, descriptive names, comprehensive mocks
- **Documentation**: Consistent format, meaningful comments only where needed

When in doubt, examine existing patterns in the codebase and follow them ruthlessly.

## File Naming Standards
**CRITICAL**: Inconsistent naming creates duplicate implementations, confusion about canonical versions, and wasted effort. Follow these standards religiously:

### Core Naming Rules:
1. **Services**: `{Feature}Service.swift` → `{Feature}ServiceProtocol.swift`
   - ✅ `WeatherService.swift` → `WeatherServiceProtocol.swift`
   - ❌ `WeatherKitService.swift`, `DefaultWeatherService.swift`

2. **Mocks**: `Mock{Feature}Service.swift` (singular, matches real service)
   - ✅ `MockWeatherService.swift`
   - ❌ `MockWeatherServices.swift`, `SimpleMockWeatherService.swift`

3. **ViewModels**: `{Feature}ViewModel.swift`
   - ✅ `DashboardViewModel.swift`
   - ❌ `DashboardVM.swift`, `DashboardViewModelImpl.swift`

4. **Models**: `{Feature}Models.swift` (plural for collections)
   - ✅ `DashboardModels.swift`
   - ❌ `DashboardModel.swift`, `DashboardTypes.swift`

5. **Extensions**: `{Type}+{Purpose}.swift`
   - ✅ `Date+Formatting.swift`, `String+Validation.swift`
   - ❌ `DateExtensions.swift`, `Date+Extensions.swift`

6. **Protocols**: `{Feature}{Type}Protocol.swift`
   - ✅ `AIServiceProtocol.swift`
   - ❌ `AIServiceInterface.swift`, `IAIService.swift`

### Current Issues to Fix:
- `ProductionAIService.swift` → `AIService.swift`
- `SimpleMockAIService.swift` → Remove (use `MockAIService.swift`)
- `WeatherKitService.swift` → `WeatherService.swift`
- `MockDashboardServices.swift` → Split into individual mocks
- `ModelContainer+Testing.swift` → `ModelContainer+Test.swift`

### Benefits:
- **Predictable**: Know exactly what file to look for
- **Searchable**: `Mock*.swift` finds all mocks
- **No Duplicates**: Clear names prevent recreating existing code
- **AI-Friendly**: LLMs pattern-match better with consistent naming

## Common Pitfalls to Avoid
- **Documentation Sprawl**: Don't create README_NEW.md or PLAN_REVISED.md - update originals and archive old versions
- **Duplicate Protocols**: Check if a protocol already exists before creating APIKeyManagerProtocol2
- **Force Casts**: Always use safe casting, especially with JSON parsing from AI responses
- **Naming Drift**: Follow file naming standards above to prevent confusion
- **Test-Code Sync**: Update tests immediately when refactoring to avoid broken test suites
- **Context Overload**: Break large tasks into focused sessions to work within LLM context limits
- **Wrong Directory**: Always verify full paths - Docs/ means /AirFit/Docs/, not root /Docs/
- **Redundant Naming**: Don't use "Default" prefix for concrete implementations (e.g., use `UserService` not `DefaultUserService` for `UserServiceProtocol`)

## Before Creating Any File
1. **Check if directory exists**: Use `ls` or `find` to verify the path
2. **Use full paths**: Start with `/Users/Brian/Coding Projects/AirFit/AirFit/` for app files
3. **Verify parent folder**: Don't create new root-level directories
4. **Follow structure**: Place files according to the directory structure above