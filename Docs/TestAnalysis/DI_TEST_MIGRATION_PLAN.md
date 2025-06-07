# DI Test Migration Plan

**Date**: 2025-06-05
**Objective**: Complete migration of test suite to modern DI patterns

> **Navigation**: This is document 6 of 7 in the test analysis series.  
> **Previous**: [MOCK_PATTERNS_GUIDE.md](./MOCK_PATTERNS_GUIDE.md)  
> **Next**: [HEALTHKIT_TESTING_PRIORITY.md](./HEALTHKIT_TESTING_PRIORITY.md) - Critical untested functionality

## Current State

### Migration Progress
- ✅ DITestHelper infrastructure created
- ✅ ~60% of tests use DI patterns
- ❌ ~40% still use legacy patterns
- ❌ 10 disabled test files
- ❌ Missing mock implementations

### Test Files Status

#### Already Using DI (Keep as Examples)
- `DashboardViewModelTests` ✅
- `NutritionParsingIntegrationTests` ✅
- `NutritionParsingRegressionTests` ✅
- `OnboardingIntegrationTests` ✅

#### Need Migration (Priority Order)
1. **Core Module Tests** (High Priority)
   - `VoiceInputManagerTests`
   - `ExtensionsTests`
   - `FormattersTests`
   - `ValidatorsTests`

2. **Service Tests** (High Priority)
   - `NetworkManagerTests`
   - `WeatherServiceTests`
   - `WorkoutSyncServiceTests`
   - `ServiceIntegrationTests`

3. **Module Tests** (Medium Priority)
   - `ChatViewModelTests`
   - `ChatCoordinatorTests`
   - `SettingsViewModelTests`
   - `WorkoutViewModelTests`
   - `WorkoutCoordinatorTests`

4. **AI/Complex Tests** (Low Priority)
   - `CoachEngineTests`
   - `ConversationManagerTests`
   - `FunctionCallDispatcherTests`

## Migration Strategy

### Phase 1: Foundation
**Goal**: Establish patterns and fix infrastructure

#### 1.1 Fix DITestHelper Issues
```swift
// Current issue in SettingsViewModelTests
private var container: DIContainer! // Line 8
// ... 47 lines later ...
container = DIContainer() // Line 55 - Wrong!

// Fix: Use DITestHelper
private func setupTest() async throws {
    container = try await DITestHelper.createTestContainer()
}
```

#### 1.2 Create Missing Mocks
Priority mocks to create:
- `MockConversationFlowManager`
- `MockConversationPersistence`
- `MockConversationAnalytics`
- `MockAIPerformanceAnalytics`
- `MockCoachEngine` (implement FoodCoachEngineProtocol)

#### 1.3 Establish Standard Patterns

**Pattern A: Simple ViewModel Tests**
```swift
@MainActor
final class ExampleViewModelTests: XCTestCase {
    private var container: DIContainer!
    private var factory: DIViewModelFactory!
    private var sut: ExampleViewModel!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        container = nil
        super.tearDown()
    }
    
    private func setupTest(
        // Optional: test-specific mock configurations
        stubbedResults: [String: Any] = [:]
    ) async throws {
        container = try await DITestHelper.createTestContainer()
        factory = DIViewModelFactory(container: container)
        
        // Configure mocks if needed
        if !stubbedResults.isEmpty {
            let mockService = try await container.resolve(SomeProtocol.self) as? MockService
            mockService?.stubbedResults = stubbedResults
        }
        
        sut = try await factory.makeExampleViewModel()
    }
    
    func testExample() async throws {
        try await setupTest()
        // Test implementation
    }
}
```

**Pattern B: Service Tests**
```swift
final class ServiceTests: XCTestCase {
    private var container: DIContainer!
    private var sut: ServiceProtocol!
    private var mockDependency: MockDependency!
    
    override func setUp() {
        super.setUp()
    }
    
    private func setupTest() async throws {
        container = try await DITestHelper.createTestContainer()
        
        // Get mock references for verification
        mockDependency = try await container.resolve(DependencyProtocol.self) as? MockDependency
        
        // Resolve SUT
        sut = try await container.resolve(ServiceProtocol.self)
    }
}
```

### Phase 2: Core Migration
**Goal**: Migrate all core and service tests

#### 2.1 Core Module Tests
- Update to use DITestHelper pattern
- Remove direct mock instantiation
- Ensure proper async setup/teardown

#### 2.2 Service Layer Tests
- Special attention to ServiceIntegrationTests
- Remove ServiceRegistry references
- Update to test DI container integration

#### 2.3 Create Migration Checklist
For each test file:
- [ ] Add setupTest() method
- [ ] Move initialization from setUp() to setupTest()
- [ ] Update all test methods to call setupTest()
- [ ] Remove manual mock creation
- [ ] Add proper teardown
- [ ] Verify no shared state between tests
- [ ] Run tests individually and as suite

### Phase 3: Module Tests
**Goal**: Migrate all module-specific tests

#### 3.1 Simple Modules First
- Chat (3 files)
- Settings (3 files)
- Notifications (2 files)
- Dashboard (1 file)

#### 3.2 Complex Modules
- FoodTracking (5 files)
- Workouts (2 files)
- Onboarding (5 files)
- AI (8 files)

### Phase 4: Disabled Tests
**Goal**: Re-enable or rewrite disabled tests

#### 4.1 Quick Wins
- `FoodVoiceAdapterTests` - Extract protocol
- `OnboardingViewTests` - Update view references

#### 4.2 Mock Creation
- Create all missing mocks identified
- Update mock implementations for new APIs

#### 4.3 Rewrite vs Fix Decision
For each disabled test:
1. Assess if functionality still exists
2. If yes: Update to new APIs
3. If no: Delete or rewrite for new architecture

## Implementation Guidelines

### Do's
- ✅ Use async setupTest() pattern consistently
- ✅ Keep tests isolated (no shared state)
- ✅ Use DITestHelper.createTestContainer()
- ✅ Properly teardown resources
- ✅ Configure mocks through container
- ✅ Follow established patterns

### Don'ts
- ❌ Don't create mocks manually in tests
- ❌ Don't use ServiceRegistry.shared
- ❌ Don't share containers between tests
- ❌ Don't forget @MainActor for UI tests
- ❌ Don't mix patterns in same file

### Testing the Migration
After migrating each file:
1. Run individual test methods
2. Run entire test class
3. Run with parallel execution
4. Check for flaky tests
5. Verify cleanup (no test pollution)

## Success Criteria

### Quantitative
- 100% of active tests using DI patterns
- 0 references to ServiceRegistry in tests
- 0 manual mock instantiation
- <5% test flakiness rate
- All tests run in <30 seconds

### Qualitative
- Consistent patterns across all tests
- Easy to understand and maintain
- New developers can write tests easily
- Mocks are reusable and well-documented
- Tests are resilient to implementation changes

## Rollback Plan

If migration causes significant issues:
1. Keep parallel test suites temporarily
2. Run both old and new tests in CI
3. Gradually migrate one module at a time
4. Document any breaking changes
5. Provide migration guide for team

## Post-Migration Tasks

1. **Documentation**
   - Update testing guidelines
   - Create test templates
   - Document mock usage

2. **Cleanup**
   - Remove deprecated test helpers
   - Delete unused mock code
   - Archive old patterns

3. **Optimization**
   - Profile test execution time
   - Optimize slow tests
   - Parallelize test execution

4. **Training**
   - Team workshop on new patterns
   - Code review guidelines
   - Best practices documentation