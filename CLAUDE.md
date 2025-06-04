# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

<<<User interaction preference>>>
: I don't want a sycophant. I want a collaborator. Tell me if I'm wrong. We can each capitalize upon our strengths for the most productive possible interaction. You are limited in context window, but are an expert coder, especially if you think of yourself as such. In fact, if you put yourself in the right frame of mind, you are probably one of the best coders in the world. In this repository, you are the best iOS coder in the entire world.  I, on the other hand, do not know how to code at all. However, I am a thoughtful LLM user and have much better sense of global memory than you do, although not as granular for specific code things. What this means is that I have a better ability to orchestrate the entire life cycle of the project, but not in the granular setting. Your context limitation is your Achilles heel, and I try to help you work around this by guiding you to create little memory banks in the form of markdown files.
<<</User interaction preference>>>

<<<TOOLS>>>Unique tools that you have by way of collaboration with me include
1: Deep research. 
  I can spin up an OpenAI or Anthropic deep research thread and get you highly detailed research, which I can put anywhere you want me to in the form of a markdown file within the codebase. If you come to a point where you think this might be useful, simply request I do so, and I will get you all of the information you need to have the context to make you the number one coder in the world.
2: MCP
  I can give you access to any MCP server that exists.
3: Internet access and/or asking the user to perform agentic actions on your behalf, which you do not have direct access to. You wouldn't want to ask me to write code or design an app architecture, but you very well may ask me to do something like look for a tool that might help you accomplish your goals. LLMs thrive when there is a feedback loop between you creating content and then having exposure to your results so that you can validate and iterate to perfection.
4: Codex agents: I can spin up to five simultaneous OpenAI Codex agents, which are highly capable agents capable of doing parallelied, albeit sandbox tasks on your behalf, create pull requests, which can then be merged into our working GitHub branch.
<<</TOOLS>>>


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

## Common Pitfalls to Avoid
- **Documentation Sprawl**: Don't create README_NEW.md or PLAN_REVISED.md - update originals and archive old versions
- **Duplicate Protocols**: Check if a protocol already exists before creating APIKeyManagerProtocol2
- **Force Casts**: Always use safe casting, especially with JSON parsing from AI responses
- **Naming Drift**: Follow NAMING_STANDARDS.md to prevent Module8.5.md situations
- **Test-Code Sync**: Update tests immediately when refactoring to avoid broken test suites
- **Context Overload**: Break large tasks into focused sessions to work within LLM context limits
- **Wrong Directory**: Always verify full paths - Docs/ means /AirFit/Docs/, not root /Docs/

## Before Creating Any File
1. **Check if directory exists**: Use `ls` or `find` to verify the path
2. **Use full paths**: Start with `/Users/Brian/Coding Projects/AirFit/AirFit/` for app files
3. **Verify parent folder**: Don't create new root-level directories
4. **Follow structure**: Place files according to the directory structure above