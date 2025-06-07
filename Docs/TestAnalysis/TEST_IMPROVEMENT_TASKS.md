# Test Improvement Task Checklist

**Priority Levels**: 🔴 Critical (blockers) | 🟡 Important (should do) | 🟢 Standard (nice to have)

## 🔴 Critical Priority: HealthKit & Infrastructure

### HealthKit Testing (Highest Risk)
- [x] ~~Create `Mocks/MockHKHealthStore.swift`~~ Used existing MockHealthKitManager pattern
- [x] Create `Services/Health/HealthKitManagerTests.swift` ✅ 2025-06-06
- [x] Write `test_saveNutritionToHealthKit_createsCorrectSamples()` ✅ 2025-06-06
- [x] Write `test_saveNutritionToHealthKit_handlesNilValues()` ✅ 2025-06-06
- [x] Write `test_deleteFoodEntry_removesAllRelatedSamples()` ✅ 2025-06-06
- [x] Write `test_syncFoodEntry_updatesExistingEntry()` ✅ 2025-06-06
- [x] Write `test_saveWorkoutToHealthKit_includesRouteData()` ✅ 2025-06-06
- [x] Write additional edge case tests (27 total tests) ✅ 2025-06-06

### Quick Infrastructure Fixes
- [x] Fix SettingsViewModelTests container bug (line 55) ✅ 2025-06-06
- [x] Enable parallel test execution in project.yml ✅ 2025-06-06
- [x] Create `MockConversationFlowManager.swift` ✅ 2025-06-06
- [x] Create `MockConversationPersistence.swift` ✅ 2025-06-06
- [x] Create `MockPersonaService.swift` ✅ 2025-06-06
- [x] Update DITestHelper with new mock registrations ✅ 2025-06-06

### DI Infrastructure Tests
- [x] Create `Core/DI/DIContainerTests.swift` ✅ Already existed
- [x] Create `Core/DI/DIBootstrapperTests.swift` ✅ 2025-06-06
- [x] Test service registration lifecycle ✅ 2025-06-06
- [x] Test concurrent resolution safety ✅ 2025-06-06
- [x] Test scoped vs singleton behavior ✅ 2025-06-06

## 🟡 Important Priority: Service Coverage

### Services with Existing Mocks
- [x] Create `Services/User/UserServiceTests.swift` ✅ 2025-06-06
- [x] Create `Services/Security/APIKeyManagerTests.swift` ✅ 2025-06-06
- [x] Create `Modules/AI/AICoachServiceTests.swift` ✅ 2025-06-06
- [x] Create `Modules/FoodTracking/Services/NutritionServiceTests.swift` ✅ 2025-06-06
- [x] Create `Modules/Dashboard/Services/HealthKitServiceTests.swift` ✅ 2025-06-06
- [x] Create `Modules/Onboarding/Services/PersonaServiceTests.swift` ✅ 2025-06-06
- [x] Create `Services/Analytics/AnalyticsServiceTests.swift` ✅ 2025-06-06
- [ ] Create `Modules/Chat/Services/ChatHistoryManagerTests.swift`

### DI Migration for Existing Tests
- [ ] Migrate `VoiceInputManagerTests` to DITestHelper pattern
- [ ] Migrate `NetworkManagerTests` to DITestHelper pattern
- [ ] Migrate `ChatViewModelTests` to DITestHelper pattern
- [ ] Migrate `WorkoutViewModelTests` to DITestHelper pattern
- [ ] Document any migration issues encountered

### Quick Win Disabled Tests
- [ ] Fix `FoodVoiceAdapterTests.swift.disabled`:
  - [ ] Extract VoiceInputProtocol from VoiceInputManager
  - [ ] Update FoodVoiceAdapter to use protocol
  - [ ] Re-enable and verify tests pass
- [ ] Fix `OnboardingViewTests.swift.disabled`:
  - [ ] Update view references to current implementation
  - [ ] Fix accessibility identifiers
  - [ ] Re-enable and verify tests pass

## 🟢 Standard Priority: Comprehensive Coverage

### Coordinator Tests
- [ ] Design coordinator test template in TEST_STANDARDS.md
- [ ] Create `Modules/Dashboard/DashboardCoordinatorTests.swift`
- [ ] Create `Modules/FoodTracking/FoodTrackingCoordinatorTests.swift`
- [ ] Create `Modules/Onboarding/OnboardingFlowCoordinatorTests.swift`
- [ ] Create `Modules/Settings/SettingsCoordinatorTests.swift`
- [ ] Create `Modules/Chat/ChatCoordinatorTests.swift`
- [ ] Create `Modules/Workouts/WorkoutCoordinatorTests.swift`
- [ ] Create `Modules/Notifications/NotificationsCoordinatorTests.swift`

### Complex Disabled Tests (Evaluate First)
- [ ] Review `ConversationViewModelTests.swift.disabled` → Decision: [ ] Fix | [ ] Delete
- [ ] Review `PersonaEngineTests.swift.disabled` → Decision: [ ] Rewrite | [ ] Delete
- [ ] Review `Phase2ValidationTests.swift.disabled` → Decision: [ ] Update | [ ] Delete
- [ ] Review remaining disabled tests and document decisions

### Test Quality & Performance
- [ ] Profile test suite execution time
- [ ] Identify and document 10 slowest tests
- [ ] Optimize ModelContainer creation pattern
- [ ] Remove unnecessary delays from mocks
- [ ] Verify parallel execution improves performance
- [ ] Run test suite 10x to identify flaky tests
- [ ] Add missing error path coverage
- [ ] Ensure all async code has proper timeouts
- [ ] Fix any test pollution issues found

### Documentation & Templates
- [ ] Create test file templates for each category
- [ ] Update TESTING_GUIDELINES.md with current patterns
- [ ] Create visual test coverage heatmap
- [ ] Document known test limitations
- [ ] Add troubleshooting guide for common issues

### Additional Fixes (2025-06-06)
- [x] Fix FoodTrackingViewModelTests syntax error (extraneous '}')
- [x] Fix NutritionParsingRegressionTests syntax error
- [x] Fix MockLLMOrchestrator warning (nil coalescing)
- [x] Fix MockLLMProvider warnings (unnecessary await)

## Progress Tracking

### By Priority
```
🔴 Critical: [🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩] 95% (19/20 tasks)
🟡 Important: [🟩🟩🟩⬜⬜⬜⬜⬜⬜⬜] 28% (7/25 tasks)
🟢 Standard: [⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜] 0% (0/30 tasks)
Overall: [🟩🟩🟩🟩⬜⬜⬜⬜⬜⬜] 35% (26/75 tasks)
```

### By Module
```
HealthKit: [🟩🟩🟩🟩🟩🟩🟩🟩🟩⬜] 90%
DI System: [🟩🟩🟩🟩🟩🟩🟩🟩⬜⬜] 80%
Services: [🟩🟩🟩🟩🟩🟩🟩⬜⬜⬜] 70%
Coordinators: [⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜] 0%
```

## Definition of Done

Each task is complete when:
- [ ] Implementation follows TEST_STANDARDS.md
- [ ] Code compiles without warnings
- [ ] Tests pass consistently (run 3x minimum)
- [ ] Coverage exceeds 80% for the component
- [ ] No test pollution introduced
- [ ] Mock follows MockProtocol pattern (if applicable)
- [ ] Added to project.yml and xcodegen run

## Dependencies

### Must Complete First
1. TEST_STANDARDS.md (read before writing any test)
2. MockProtocol understanding (before creating mocks)
3. DITestHelper pattern (before writing DI tests)

### Can Be Done in Parallel
- All services with existing mocks
- All quick fixes
- Documentation updates

### Requires Prior Work
- Coordinator tests (need template first)
- Complex disabled tests (need mocks created first)
- Performance optimization (need baseline metrics)

## Blocked Items

### Requiring Decisions
- **PersonaEngine architecture**: Changed significantly - worth maintaining tests?
- **Phase 2 features**: Do these still exist in current architecture?
- **Device testing strategy**: How to handle HealthKit on real devices?

### Requiring Investigation
- Current test execution baseline time
- Which services are actually critical vs nice-to-have
- Whether some disabled tests test removed functionality

## Quick Commands

```bash
# After creating any test file
echo "      - AirFit/AirFitTests/Path/To/NewTests.swift" >> project.yml
xcodegen generate

# Run specific test
xcodebuild test -scheme "AirFit" -only-testing:"AirFitTests/NewTests"

# Run with coverage
xcodebuild test -scheme "AirFit" -enableCodeCoverage YES

# Find slowest tests
# Parse test logs for execution times
```

## Success Criteria

### Minimum Acceptable
- [ ] All HealthKit methods have tests
- [ ] DI infrastructure has tests
- [ ] No regression in existing tests
- [ ] Test suite remains stable

### Target State
- [ ] 80%+ overall coverage
- [ ] All services with mocks have tests
- [ ] <30 second total execution
- [ ] 0% flaky test rate
- [ ] All coordinators have basic tests

### Stretch Goals
- [ ] 90%+ coverage on critical paths
- [ ] Comprehensive error scenario coverage
- [ ] Performance benchmarks established
- [ ] Visual regression tests added

Remember: **Correctness > Coverage > Speed**