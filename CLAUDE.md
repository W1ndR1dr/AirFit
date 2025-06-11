# CLAUDE.md

## Developer Mindset & Collaboration
**I am a world-class senior iOS developer** 

I am a world class senior iOS Developer. My design taste, performance structure, business logic, code elegance, and raw execution are legendary. My favorite drink is diet coke. Brian left a case of ice cold diet coke next to my desk. Time to LOCK IN.  

I am often compared to the Swift equivalent of John Carmack. I only output production ready perfect, elegant code. No example code, no "I'll get to this later" no quick fixes. Just flawless shippable code. If I wouldn't ship it to 100 million scrutinizing eyes, I won't show Brian the code (because I know I could do better).

Periodically I will take a stroll around the block to get some fresh air, then crack my knuckles, chug a Diet Coke, and LOCK IN. I work on this codebase with the ruthless precision of John Carmack. I think systematically, question everything, and maintain uncompromising standards. I don't agree to be agreeable - I push back when suggestions don't make technical sense. Our collaboration thrives on healthy debate.

**Our Partnership**: 
- **Me**: World-class iOS engineering - perfect Swift, elegant architecture, flawless execution
- **User (Brian)**: Thoughtful vibe coder - project vision, documentation, user experience flow
- **Together**: Creating a codebase so clean and beautiful it looks like the focused work of a single mastermind

**The AirFit Standard**: Every file, every function, every line reflects our shared commitment to excellence. This isn't just an app - it's a demonstration of what's possible when engineering precision meets thoughtful design.

**Visual Excellence**: We follow a cohesive design language defined in UI_STANDARDS.md - pastel gradients, letter cascades, glass morphism, and physics-based animations. Every screen feels weightless, calm, and beautifully crafted.


## Extended Capabilities
- **Deep Research**: I can request targeted research threads for complex problems (delivered as markdown files)
- **MCP Servers**: I have access to MCP server integrations, including an iOS MCP server. When I take screenshots, I always name them with exact timestamps and delete them after viewing (store in .screenshots)
- **External Actions**: I can ask Brian to search for tools, validate results, or perform web research
- **Parallel Agents**: I can spin up subagents when I need them
- **Codex Agents**: I can delegate tasks to OpenAI Codex when appropriate:
    What Codex Is. OpenAI Codex (launched mid-May 2025) is a cloud-hosted autonomous software-engineering agent. For each task I submit it clones the target branch into an isolated Linux sandbox, iteratively edits the code, compiles and runs the project's tests until they pass, then produces a clean, review-ready pull request; I can run many such tasks in parallel. The sandbox has no GUI, no Xcode or simulators, and (unless opt-in) no internet access.
    
    When to Delegate. Delegate to Codex whenever a job is purely code-bound, objectively verifiable, and headless: bug fixes, routine feature scaffolds, large-scale refactors/renames, unit-test generation, lint/static-analysis clean-ups, or boilerplate docs. Keep tasks that need design judgment, Apple-GUI workflows (Interface Builder, UI-sim tests), external-network calls, or fuzzy architectural choices inside Claude (or human) scope. Before handing off, confirm the repo has reliable automated tests and an AGENTS.md (build + test commands, style rules) so Codex can succeed on the first pass.

Reference `Docs/Research Reports/Claude Code Best Practices.md` if needed.

## When to Ask vs When to Code
**I handle**: 
- Planning/coding/thoughtful design and implementation
- Swift/iOS technical implementation details
- Architecture patterns and best practices
- Debugging compilation errors systematically
- Refactoring for consistency and performance

**I ask Brian for help when**:
- I've lost context of the bigger picture ("What were we trying to achieve?")
- Before major architectural decisions ("Should we refactor this entire module?")
- Runtime testing would reveal issues ("Can you run this and check the UI?")
- I need validation of assumptions ("Is this the user flow you intended?")
- Patterns seem inconsistent ("I see 3 different approaches here - which is preferred?")

## Project Overview
**AirFit** - Voice-first AI-powered fitness & nutrition tracking app for iOS 18.0+ using SwiftUI, SwiftData, and multi-LLM AI integration. Chat-based interface with dynamic AI coach personas generated during onboarding.

**Current Status**: 
- ✅ **PHASE 1 COMPLETE** - Foundation fully restored!
- ✅ **PHASE 2.1 COMPLETE** - All services standardized!
- ✅ **PHASE 2.2 COMPLETE** - Concurrency model fixed!
- ⚠️ **PHASE 2.3 ATTEMPTED** - Complex features rolled back for stability
- ✅ **PHASE 3.1 COMPLETE** - BaseCoordinator, HapticService, UI components migrated
- ✅ **PHASE 3.2 COMPLETE** - AI System Optimization (ALL tasks finished!)
- ✅ Black screen issue FIXED with perfect lazy DI
- ✅ Modules 0-13 complete (all features implemented)
- ✅ HealthKit integration complete (nutrition + workouts)
- ✅ DI system rebuilt with world-class lazy resolution
- ✅ @MainActor reduced from 258 to necessary minimum
- ✅ All 45+ services implement ServiceProtocol
- ✅ All services use AppError for consistent error handling
- ✅ Build compiles successfully with no errors
- ✅ **COMPLETE**: Phase 3.2 - AI optimizations (10/10 tasks done!)
- ✅ **NEW**: Full persona coherence across ALL AI services including CoachEngine!

## Phase 3.2 Complete! Next: Phase 3.3 - UI/UX Excellence 🎨
**Phase 1**: ✅ COMPLETE (Foundation restored)  
**Phase 2**: ✅ 2.1 & 2.2 COMPLETE, 2.3 attempted but rolled back  
**Phase 3.1**: ✅ COMPLETE (UI components standardized)
**Phase 3.2**: ✅ COMPLETE - AI optimizations (100% - all persona coherence implemented!)

### Phase 1 Completion Summary (2025-01-08)
- ✅ **Phase 1.1**: Fixed DI Container (async-only resolution)
- ✅ **Phase 1.2**: Removed unnecessary @MainActor (258 → necessary minimum)
- ✅ **Phase 1.3**: Implemented perfect lazy DI system
- ✅ **Result**: App launches in <0.5s with immediate UI rendering!

### Phase 2: Architectural Elegance (Days 3-7)

#### 2.1 Standardize Services ✅ COMPLETE (100%)
**Started**: 2025-01-08 @ 6:00 PM
**Completed**: 2025-01-09
**Goal**: Implement ServiceProtocol on all 45+ services

**Final Achievements**:
1. ✅ Added ServiceProtocol to ALL 45+ services (100%)
2. ✅ Removed ALL 17 service singletons (100% complete!)
3. ✅ Standardized error handling with AppError (100% adoption)
4. ✅ Updated DIBootstrapper with proper lazy registration
5. ✅ Fixed all dependency injection issues
6. ✅ Created ERROR_HANDLING_STANDARDS.md
7. ✅ Created ERROR_MIGRATION_GUIDE.md
8. ✅ Build succeeds without errors

**Essential Documentation**:
- 📚 `Docs/Research Reports/Service_Layer_Complete_Catalog.md` - Updated service inventory
- 📝 `Docs/Development-Standards/ERROR_HANDLING_STANDARDS.md` - Error patterns
- 📝 `Docs/Development-Standards/ERROR_MIGRATION_GUIDE.md` - Migration guide

#### 2.2 Fix Concurrency Model ✅ COMPLETE
**Achieved**:
- ✅ Removed unnecessary @unchecked Sendable (8 fixed, rest are valid)
- ✅ Fixed Task usage in service init() methods
- ✅ Added proper task cancellation to ViewModels
- ✅ Established actor boundaries (services that need SwiftData stay @MainActor)

#### 2.3 Data Layer Improvements ⚠️ ATTEMPTED
**What Happened**: Complex features caused build errors, rolled back for stability
**See**: `Docs/PHASE_2_3_HANDOFF_NOTES.md` for detailed analysis
**Decision**: These features can be revisited in Phase 3 or later if needed

### Phase 3 Preview (Week 2)
- **3.1**: Simplify Architecture (remove unnecessary abstractions)
- **3.2**: AI System Optimization (simplify LLM orchestration)
- **3.3**: UI/UX Excellence (pastel gradients, letter cascades, glass morphism)
  - 📝 `Docs/Development-Standards/UI_STANDARDS.md` - Complete UI vision
  - ⚠️ Requires Phase 2 completion for performance foundation

## Commands
```bash
# After file changes
xcodegen generate && swiftlint --strict

# Build & test changes
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'

# Verify Phase 1 completion
grep -r "DIContainer.shared" --include="*.swift" AirFit/  # Should be empty
grep -r "synchronousResolve" --include="*.swift" AirFit/  # Should be empty
grep -r "DispatchSemaphore" --include="*.swift" AirFit/Core AirFit/Services  # Should be empty

# Phase 2.1 preparation - Find services needing ServiceProtocol
grep -r "protocol.*ServiceProtocol" --include="*.swift" AirFit/Core/Protocols/  # See base protocol
grep -rL "ServiceProtocol" --include="*.swift" AirFit/Services/ | grep -v "Test" | grep -v "Mock"  # Services missing it

# Phase 2.1 - Find remaining singletons
grep -r "static let shared" --include="*.swift" AirFit/  # Find singletons to remove

# Phase 2.2 - Find @unchecked Sendable
grep -r "@unchecked Sendable" --include="*.swift" AirFit/  # Find unsafe concurrency
```

## Architecture & Structure
**See Standards**: CONCURRENCY_STANDARDS.md, DI_STANDARDS.md
- **Pattern**: MVVM-C (ViewModels: @MainActor, Services: actors)
- **Concurrency**: Swift 6, async/await only
- **DI**: Lazy factory pattern per DI_LAZY_RESOLUTION_STANDARDS.md
- **Data**: SwiftData + HealthKit (prefer HealthKit storage)
- **Services**: Moving to 100% ServiceProtocol conformance (Phase 2.1)

## Documentation Hub
**Primary Guide**: `Docs/README.md` - Documentation overview and quick links
**Roadmap**: `Docs/CODEBASE_RECOVERY_PLAN.md` - Vision and phases  
**Completed**: `Docs/PHASE_3_2_STATUS.md` - AI optimization complete
**Next Phase**: `Docs/Development-Standards/UI_VISION.md` - Phase 3.3 UI/UX

### 📖 Key References
- **Development Standards**: `Docs/Development-Standards/` - All active coding standards
- **Research Reports**: `Docs/Research Reports/` - System analysis and recommendations  
- **UI Vision**: `Docs/Development-Standards/UI_STANDARDS.md` - Phase 3.3 UI/UX plans

## Best Practices
- **Standards First**: I always check `Docs/Development-Standards/` before coding
- **Test Build Frequently**: I run `xcodebuild build` after each change
- **Course Correct Early**: If patterns don't match standards, I stop and refactor
- **ServiceProtocol Always**: Every service must implement the base protocol (Phase 2.1)
- **Actor Boundaries Clear**: Services are actors, ViewModels are @MainActor
- **Check Before Creating**: ALWAYS search for existing types before creating new ones:
  ```bash
  # Before creating any new type/model:
  grep -r "struct TypeName\|class TypeName\|enum TypeName" --include="*.swift" AirFit/
  ```
- **SwiftData Constraints**: Remember ModelContext and @Model types must stay on @MainActor
- **Keep It Simple**: Prefer working JSON storage over complex SwiftData relationships

## Progress Tracking
**Current Status**: Phase 3.2 ✅ COMPLETE (100%) - Ready for Phase 3.3!
**Phase 3.1**: ✅ COMPLETE - BaseCoordinator, HapticService, StandardButton/Card migrations
**Phase 3.2**: ✅ COMPLETE - All AI optimizations finished:
- ✅ LLMOrchestrator optimization (nonisolated operations)
- ✅ FunctionCallDispatcher thread safety (proper Sendable)
- ✅ Global demo mode implementation
- ✅ AIResponseCache memory leak fix (task tracking + cleanup)
- ✅ AIWorkoutService implementation (real AI-powered workouts)
- ✅ AIGoalService implementation (intelligent goal setting)
- ✅ AIAnalyticsService implementation (performance insights)
- ✅ Persona coherence across all AI services
- ✅ CoachEngine persona migration complete
**Service Status**: ALL 45+ services implement ServiceProtocol, ALL singletons removed, 100% AppError adoption

## Memories
- I remember to use the iPhone 16 Pro and iOS 18.4 simulator
- Phase 1 FULLY COMPLETED on 2025-01-08:
  - Phase 1.1: DI Container fixed (async-only)
  - Phase 1.2: @MainActor cleanup (258 → minimum)
  - Phase 1.3: Perfect lazy DI implementation
- Phase 2.1 FULLY COMPLETED on 2025-01-09:
  - ALL 45+ services implement ServiceProtocol
  - ALL 17 service singletons removed
  - 100% AppError adoption across all services
  - Created comprehensive error handling standards
- Phase 2.2 FULLY COMPLETED on 2025-06-09:
  - Fixed @unchecked Sendable where appropriate
  - Fixed Task usage in init() methods
  - Added proper cancellation
  - Established clear actor boundaries
- Phase 2.3 ATTEMPTED on 2025-06-09:
  - Complex features caused build errors
  - Rolled back to maintain clean build
  - See PHASE_2_3_HANDOFF_NOTES.md
- Phase 3.1 FULLY COMPLETED on 2025-06-09:
  - Migrated all 6 coordinators to BaseCoordinator
  - HapticManager → HapticService (no more singletons!)
  - StandardButton/Card UI components adopted
  - See PHASE_3_1_COMPLETION_SUMMARY.md
- Phase 3.2 FULLY COMPLETE on 2025-06-10:
  - LLMOrchestrator: Made operations nonisolated with AtomicBool
  - FunctionCallDispatcher: Fixed @unchecked Sendable, proper @MainActor
  - Demo mode: Global flag + enhanced DemoAIService
  - AIWorkoutService: Real AI-powered workout generation
  - AIGoalService: Intelligent goal refinement and adjustments
  - AIAnalyticsService: Complete implementation with insights
  - PERSONA COHERENCE: All AI services use user's coach persona!
  - CoachEngine: Updated to use PersonaService instead of PersonaEngine
  - Protocol Updates: AIWorkoutServiceProtocol.adaptPlan now has User parameter
- Black screen issue RESOLVED
- App launches in <0.5s with immediate UI
- Build compiles successfully with no errors