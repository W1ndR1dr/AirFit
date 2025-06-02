# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
**AirFit** - Voice-first AI-powered fitness & nutrition tracking app for iOS 18.0+ using SwiftUI, SwiftData, and multi-LLM AI integration. Chat-based interface with dynamic AI coach personas generated during onboarding.

**Status**: Modules 0-10 COMPLETE ✅. Currently implementing Module 9 & 11 in parallel.

## Build & Run Commands
```bash
# Essential workflow - run after ANY file changes
xcodegen generate  # CRITICAL: Must run after adding/moving files due to XcodeGen bug
swiftlint --strict

# Build
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'

# Test commands
swift test                                           # All tests
swift test --filter AirFitTests.ModuleName          # Module-specific tests
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'
```

## Architecture & Structure
- **Pattern**: MVVM-C with SwiftUI. ViewModels are `@MainActor @Observable`, services use `actor` isolation
- **Concurrency**: Swift 6 strict concurrency, `async/await` only (no completion handlers)
- **Testing**: Mock protocol system for all services, test-first development approach
- **AI Integration**: Multi-provider LLM support (OpenAI, Anthropic, Google) with unified interface

### Directory Structure
```
AirFit/
├── Core/        # Shared utilities, constants, themes, common views
├── Data/        # SwiftData models and persistence layer
├── Modules/     # Feature modules (each with Views/, ViewModels/, Services/, Coordinators/)
├── Services/    # Business logic, AI integration, network, health data
└── Docs/        # Architecture documentation and module specs
```

## Critical File Management
**XcodeGen Bug**: Nested module files MUST be explicitly listed in `project.yml`. After creating any file in `AirFit/Modules/*/`:
1. Add the file path to `project.yml` under the appropriate target
2. Run `xcodegen generate`
3. Verify the file appears in Xcode project navigator

## Key Documents
- **Module Specs**: `Docs/Module9.md` and `Docs/Module11.md` - Current implementation targets
- **Module 12**: `Docs/Module12.md` - Final integration and testing phase
- **Architecture**: `Docs/ArchitectureAnalysis.md` - Comprehensive codebase analysis
- **Agent Communication**: `claude2claude.md` - Inter-agent coordination for parallel work

## Module Implementation Sequence
**Current Implementation Status:**
1. **✅ Module 10**: Services Layer (API Clients & AI Router) - COMPLETE 
2. **🚧 Module 9 & 11** (Parallel - Current Focus): 
   - Module 9: Notifications & Engagement Engine
   - Module 11: Settings Module (UI & Logic)
3. **📋 Module 12**: Testing & Quality Assurance Framework (Next)

## Parallel Development Coordination
- **Agent Communication**: Use `claude2claude.md` for coordination when needed
- **Independence**: Modules 9 & 11 can be developed independently without conflicts
- **Shared Dependencies**: Both modules depend on Module 10 services (already complete)

## Development Standards
- **Performance Targets**: <1.5s app launch, 120fps transitions, <150MB memory, <3s persona generation
- **Error Handling**: Use `async throws` or `Result<Success, Error>`, comprehensive recovery flows
- **Documentation**: `///` docs for public APIs, descriptive names (no abbreviations)
- **Accessibility**: Include identifiers on all interactive elements

## Testing Guidelines
- Run module-specific tests after changes: `swift test --filter AirFitTests.ModuleName`
- Integration tests for critical paths: onboarding, food tracking, workout logging
- Performance tests for AI operations: persona generation, nutrition parsing
- UI tests for user flows using page object pattern

## AI Integration Notes
- **Voice Input**: WhisperKit for on-device transcription, voice adapter pattern for modules
- **LLM Providers**: Unified service with fallback support, response caching, cost tracking
- **Persona System**: Multi-phase synthesis with offline fallback, <3s generation requirement
- **Function Calling**: Dispatcher pattern for AI-triggered actions (nutrition, workouts, goals)