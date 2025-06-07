# AirFit Test Execution Plan

**Purpose**: Prioritized task list with persistent progress tracking for test suite refactoring.  
**Last Updated**: 2025-01-07  
**Current Status**: Phase 1 in progress  
**Overall Progress**: 18/156 tasks (11.5%)

## 🚀 Quick Start for New Agents

1. **Read Current Status** section below
2. **Review TEST_STANDARDS.md** - MANDATORY before writing any code
3. **Find the NEXT unchecked [ ] task** in the current phase
4. **Work on ONE task at a time**
5. **Update this file** after completing each task
6. **Commit changes** with message like "test: Complete deletion of PersonaEngineTests"

## 📊 Current Status

### Phase Progress
- **Phase 1: Clean House** - 18/23 tasks (78.3%) 🔴 CURRENT
- **Phase 2: Standardize** - 0/89 tasks (0%) ⏸️ WAITING
- **Phase 3: Fill Gaps** - 0/44 tasks (0%) ⏸️ WAITING

### Known Issues
- Compilation errors: 24 (down from ~38)
- Disabled tests: 0 files (all deleted)
- Tests using old patterns: ~50%

### Last Completed Task
- Fixed async setUp/tearDown in 2 integration tests (10 total)

### Currently Working On
- Fixing async/await issues in remaining test files (manual approach)

## 📋 Progress Tracking Guidelines

**Task Status Markers:**
- [ ] Not started
- [🚧] In progress (only ONE task should have this)
- [✅] Completed
- [❌] Blocked - add reason in parentheses

**After Each Task:**
1. Change [ ] to [✅]
2. Update phase task count (e.g., "3/23 tasks")
3. Update overall progress count
4. Update "Last Completed Task"
5. Add notes if helpful for next agent
6. Commit with descriptive message

## Phase 1: Clean House
**Goal**: Remove outdated code and fix compilation errors  
**Progress**: 18/23 tasks (78.3%)

### Delete Outdated Tests
**Why**: These test deprecated features or use old patterns that no longer apply

- [✅] Delete `AirFit/AirFitTests/Modules/AI/PersonaEngineTests.swift`
  - Reason: Tests old Blend system, not current PersonaMode
  
- [✅] Delete `AirFit/AirFitTests/Services/ServiceProtocolsTests.swift`
  - Reason: Tests services that no longer exist
  
- [✅] Delete all disabled test files:
  - [✅] `PersonaSystemIntegrationTests.swift.disabled`
  - [✅] `PersonaEnginePerformanceTests.swift.disabled`
  - [✅] `NutritionParsingFinalIntegrationTests.swift.disabled`
  - [✅] `OnboardingViewTests.swift.disabled`
  - [✅] `PersonaGenerationStressTests.swift.disabled`
  - [✅] `ServicePerformanceTests.swift.disabled`

- [✅] Search for and delete any test referencing:
  - [✅] `MockFoodDatabaseService` (service removed) - None found
  - [✅] `NetworkManager.shared` (singleton removed) - None found
  - [✅] `ServiceRegistry` (replaced by DIContainer) - None found

### Fix Compilation Errors
**Why**: Can't refactor tests that don't compile

- [✅] Fix `LLMOrchestratorTests` - Swift 6 concurrency
  - Completed: Changed tearDown to async
  
- [✅] Fix `VoiceInputManagerTests` - MockWhisperModelManager type
  - Completed: Using default manager for now, needs protocol extraction
  
- [✅] Fix `WorkoutSyncServiceTests` - MainActor isolation
  - Completed: Added @MainActor annotation

- [🚧] Fix remaining async/await issues:
  - [✅] Find all `override func setUp()` without async - Found ~20 files
  - [✅] Find all `override func tearDown()` without async - Found ~40 files
  - [🚧] Update method signatures - Fixed 10 files total, manual approach working well

- [ ] Fix Swift 6 compliance:
  - [ ] Add @MainActor to UI-related test classes
  - [ ] Fix "sending non-Sendable type" warnings
  - [ ] Fix "actor-isolated property" errors

### Verify Current Code
**Why**: Ensure we're testing features that actually exist

- [ ] Verify PersonaMode is used everywhere (not Blend)
  - Check: OnboardingModels, PersonaEngine, etc.
  
- [ ] Verify all service protocols exist:
  - [ ] List all protocols in Mocks/
  - [ ] Confirm each has a corresponding real protocol
  
- [ ] Document any mismatches found

## Phase 2: Standardize
**Goal**: Migrate all tests to use consistent DI patterns  
**Progress**: 0/89 tasks (0%)

### Prerequisites
**Complete these before any module migration:**

- [ ] Audit DITestHelper.createTestContainer()
  - [ ] List all protocols that need mocks
  - [ ] List all existing mocks
  - [ ] Identify missing mocks
  
- [ ] Create missing mocks:
  - [ ] MockWhisperServiceWrapper
  - [ ] MockNotificationManager  
  - [ ] MockEngagementEngine
  - [ ] MockLiveActivityManager
  - [ ] MockWhisperModelManager (with protocol)
  - [ ] Any others identified in audit

- [ ] Standardize existing mocks:
  - [ ] Ensure all implement MockProtocol
  - [ ] Add reset() method to any missing it
  - [ ] Use consistent property names:
    - `{method}Called: Bool`
    - `{method}CallCount: Int`
    - `{method}ReceivedParams: ParamType?`
    - `stubbed{Method}Result: ResultType`

### Module: Dashboard (High Priority)
**Why**: Core user-facing feature, needs reliable tests

- [ ] Migrate `DashboardViewModelTests.swift`
  - Current: Manual mocking
  - Target: Full DI pattern
  - See TEST_MIGRATION_GUIDE.md Pattern 1
  
- [ ] Migrate `AICoachServiceTests.swift`
  - Current: Uses some DI
  - Target: Consistent patterns
  
- [ ] Migrate `DashboardNutritionServiceTests.swift`
- [ ] Migrate `HealthKitServiceTests.swift`

### Module: Food Tracking (High Priority)
**Why**: Complex feature with voice input, critical path

- [ ] Migrate `FoodTrackingViewModelTests.swift`
  - Issues: Manual mocking, private API access
  - Needs: VoiceInputProtocol extraction
  
- [ ] Migrate `FoodVoiceAdapterTests.swift`
- [ ] Migrate `NutritionServiceTests.swift`
- [ ] Delete old `NutritionParsingTests.swift` variants
- [ ] Create new `AINutritionParsingTests.swift`
  - Test current AI parsing implementation
  - Use DirectAIProcessor patterns

### Module: AI Services
**Why**: Core infrastructure, all features depend on it

- [ ] Keep `AIServiceTests.swift` (check if needs updates)
- [ ] Keep `LLMOrchestratorTests.swift` (already fixed)
- [ ] Migrate `AIAnalyticsServiceTests.swift`
- [ ] Migrate `AIGoalServiceTests.swift`
- [ ] Migrate `AIWorkoutServiceTests.swift`

### Module: Onboarding
**Why**: First user experience, must work perfectly

- [ ] Decide: Keep or rewrite `OnboardingViewModelTests.swift`
  - Currently tests old patterns
  - Major refactor vs fresh start?
  
- [ ] Migrate `OnboardingServiceTests.swift`
- [ ] Migrate `PersonaServiceTests.swift`
- [ ] Migrate `ConversationViewModelTests.swift`
- [ ] Update all to use new PersonaMode (not Blend)

### Module: Chat
**Why**: Primary interaction method

- [ ] Migrate `ChatViewModelTests.swift`
- [ ] Migrate `ChatSuggestionsEngineTests.swift`
- [ ] Keep `ChatCoordinatorTests.swift` (verify patterns)

### Module: Settings
**Why**: User preferences and configuration

- [ ] Keep `SettingsViewModelTests.swift` (already good)
- [ ] Migrate `BiometricAuthManagerTests.swift`
- [ ] Verify all use proper DI patterns

### Module: Workouts
**Why**: Core fitness tracking feature

- [ ] Decision: Enable `WorkoutViewModelTests.swift`?
  - Currently disabled
  - Assess effort vs value
  
- [ ] Migrate or create `WorkoutServiceTests.swift`
- [ ] Migrate `WorkoutCoordinatorTests.swift`

### Module: Core Infrastructure

- [ ] Keep `DIBootstrapperTests.swift` (exemplar)
- [ ] Keep `DIContainerTests.swift` (exemplar)  
- [ ] Migrate extension tests to async if needed
- [ ] Ensure all follow AAA pattern

### Service Layer

- [ ] Keep `UserServiceTests.swift` (exemplar)
- [ ] Keep `HealthKitManagerTests.swift` (exemplar)
- [ ] Keep `APIKeyManagerTests.swift` (good patterns)
- [ ] Migrate `WeatherServiceTests.swift`
- [ ] Migrate `NetworkClientTests.swift`
- [ ] Create proper `WorkoutSyncServiceTests.swift`

## Phase 3: Fill Gaps
**Goal**: Create missing tests and achieve 80%+ coverage  
**Progress**: 0/44 tasks (0%)

### Missing Service Tests
**These have mocks but no tests - high value targets**

- [ ] Create `ConversationManagerTests.swift`
  - Test conversation flow
  - Test message persistence
  - Test analytics integration
  
- [ ] Create `CoachEngineTests.swift`
  - Test prompt building
  - Test response processing
  - Test function calling
  
- [ ] Create `DirectAIProcessorTests.swift`
  - Test nutrition parsing
  - Test workout analysis
  - Test goal generation

- [ ] Create `NotificationManagerTests.swift`
- [ ] Create `EngagementEngineTests.swift`
- [ ] Create `ChatHistoryManagerTests.swift`
- [ ] Create `ChatExporterTests.swift`

### Missing Data Layer Tests

- [ ] Create `DataManagerTests.swift`
- [ ] Create `OnboardingCacheTests.swift`
- [ ] Create `AIResponseCacheTests.swift`
- [ ] Create model relationship tests

### Integration Tests
**Test multiple components working together**

- [ ] Create `UserOnboardingIntegrationTests.swift`
  - Full onboarding flow
  - Persona generation
  - Profile creation
  
- [ ] Create `FoodLoggingIntegrationTests.swift`
  - Voice input → AI parsing → Storage
  - HealthKit sync
  
- [ ] Create `WorkoutTrackingIntegrationTests.swift`
  - Workout creation → Execution → HealthKit
  
- [ ] Create `HealthKitSyncIntegrationTests.swift`
  - Bidirectional sync
  - Conflict resolution

### UI Tests

- [ ] Fix `OnboardingFlowUITests.swift`
- [ ] Fix `DashboardUITests.swift`
- [ ] Fix `FoodTrackingFlowUITests.swift`
- [ ] Add accessibility identifiers:
  - [ ] Audit all user-facing views
  - [ ] Add .accessibilityIdentifier()
  - [ ] Follow naming: module.component.element

### Coverage Gap Analysis

- [ ] Run coverage report
- [ ] Document current coverage by module
- [ ] Identify critical paths below 80%
- [ ] Create tests for gaps
- [ ] Re-run coverage report
- [ ] Document final coverage

### Performance Validation

- [ ] Measure total test execution time
- [ ] Identify tests taking >100ms
- [ ] Optimize slow tests
- [ ] Verify parallel execution works
- [ ] Document any flaky tests

## 📝 Completion Checklist

When ALL tasks are complete:

- [ ] All tests compile without warnings
- [ ] All tests pass reliably
- [ ] 80%+ coverage on critical paths
- [ ] All tests follow TEST_STANDARDS.md
- [ ] No manual mocking (all use DI)
- [ ] Documentation updated
- [ ] Final coverage report generated
- [ ] This plan marked as COMPLETE

## 🔧 Common Commands

```bash
# Run all tests
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'

# Run specific test class
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' \
  -only-testing:"AirFitTests/UserServiceTests"

# Generate coverage report
xcodebuild test -scheme "AirFit" -enableCodeCoverage YES -resultBundlePath coverage.xcresult

# Check what needs fixing
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' \
  2>&1 | grep -E "(error:|warning:)" | sort | uniq
```

## 🐛 Issue Log

Track problems and solutions discovered during execution:

### Issue #1: [Example - will be filled as issues are found]
- **Problem**: Description of what went wrong
- **Solution**: How it was fixed
- **Pattern**: Reusable fix for similar issues
- **Files Affected**: List of files

## 📌 Notes for Future Agents

1. **Always check TEST_STANDARDS.md** before writing any test code
2. **Good examples**: DIBootstrapperTests, HealthKitManagerTests
3. **One task at a time** - mark with [🚧] while working
4. **Update progress** - other agents need to know what's done
5. **Commit frequently** - at least after each completed task
6. **Ask questions** - better to clarify than assume

## Status History

- 2025-01-07: Plan created, ready to execute
- [Agents will add entries as work progresses]