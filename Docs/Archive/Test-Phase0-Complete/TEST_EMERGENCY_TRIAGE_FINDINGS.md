# Test Emergency Triage - Detailed Findings

**Date**: 2025-01-07  
**Auditor**: Senior iOS Developer  
**Status**: 🔴 342 Issues Found Requiring Systematic Fix

## Executive Summary

Automated audit revealed 342 issues across the test suite. These aren't just style issues - they represent fundamental misunderstandings about the codebase's current state.

## Detailed Findings by Category

### 1. Wrong Async Patterns (97 instances in 45 files)
**Pattern**: `try await super.setUp()` and `try await super.tearDown()`  
**Issue**: XCTestCase's setUp/tearDown aren't async in the parent  
**Fix**: Remove `await` - just use `try super.setUp()`

**Example Files**:
- KeychainWrapperTests.swift
- PersonaGenerationTests.swift  
- OnboardingErrorRecoveryTests.swift
- HealthKitManagerTests.swift
- AIServiceTests.swift

### 2. Undefined References (40 instances)
**Pattern**: Using `context` instead of `modelContext`  
**Issue**: Variable naming inconsistency  
**Fix**: Standardize on `modelContext`

**Pattern**: Using `mockHealth` instead of `mockHealthKitManager`  
**Issue**: Incomplete variable names  
**Fix**: Use full, descriptive names

### 3. Missing @MainActor (Multiple files)
**Pattern**: Test classes using ModelContext without @MainActor  
**Issue**: Swift 6 strict concurrency requires actor isolation  
**Fix**: Add @MainActor to test class declaration

### 4. Mock Usage Issues (5 instances)
**Pattern**: Tests expecting MockCoachEngine but getting wrong type  
**Issue**: Multiple mocks for same protocol, confusion about which to use  
**Fix**: Standardize on one mock per protocol

## Systematic Fix Approach

### Phase 0.1: Document Standards First
Before fixing anything, document the correct patterns:

```swift
// ✅ CORRECT: Test Class Structure
@MainActor
final class SomeViewModelTests: XCTestCase {
    // Properties
    private var container: DIContainer!
    private var modelContext: ModelContext!  // Always 'modelContext', not 'context'
    private var sut: SomeViewModel!
    
    // Setup
    override func setUp() async throws {
        try super.setUp()  // No 'await' needed
        
        container = try await DITestHelper.createTestContainer()
        let modelContainer = try await container.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
    }
    
    override func tearDown() async throws {
        // Reset mocks if they have async reset
        await mockService?.reset()
        
        // Clear references
        sut = nil
        container = nil
        modelContext = nil
        
        try super.tearDown()  // No 'await' needed
    }
}
```

### Phase 0.2: Fix One Module at a Time
Start with the most critical module and fix ALL issues before moving on:

1. **Dashboard Module** (Core user-facing feature)
   - Fix async patterns
   - Add @MainActor where needed
   - Standardize variable names
   - Verify each test compiles AND runs

2. **Food Tracking Module** (Complex with voice input)
   - Same systematic approach
   - Special attention to mock usage

3. **Onboarding Module** (First user experience)
   - Many issues found here
   - Careful with mock references

### Phase 0.3: Validation After Each Fix
After fixing each file:
1. Run `xcodebuild` to verify compilation
2. Run the specific test to verify it passes
3. Document any new patterns discovered
4. Update this document with learnings

## Quality Gates

Before marking any test file as "fixed":
- [ ] Compiles without warnings
- [ ] All tests in file pass
- [ ] Follows documented patterns exactly
- [ ] Variable names are consistent
- [ ] Proper actor isolation
- [ ] Mocks are correctly typed
- [ ] No force unwrapping
- [ ] Proper async/await usage

## Lessons Learned

1. **Mass fixes are dangerous** - Each file may have unique context
2. **Patterns evolve** - What worked in Swift 5 doesn't in Swift 6
3. **Documentation prevents drift** - Without docs, developers guess
4. **Validation is critical** - Don't assume, verify

## Next Actions

1. Fix Dashboard tests completely (one file at a time)
2. Document any new patterns discovered
3. Update TEST_STANDARDS.md with Swift 6 patterns
4. Create module-specific fix tracking

## Module Fix Tracking

### Dashboard Module
- [ ] DashboardViewModelTests.swift
- [ ] AICoachServiceTests.swift  
- [ ] DashboardNutritionServiceTests.swift
- [ ] HealthKitServiceTests.swift

### Food Tracking Module
- [ ] FoodTrackingViewModelTests.swift
- [ ] FoodVoiceAdapterTests.swift
- [ ] NutritionServiceTests.swift
- [ ] AINutritionParsingTests.swift

### Onboarding Module
- [ ] OnboardingViewModelTests.swift (partially fixed)
- [ ] OnboardingServiceTests.swift
- [ ] ConversationViewModelTests.swift
- [ ] OnboardingIntegrationTests.swift

Each checkbox represents a file that:
1. Compiles without errors
2. All tests pass
3. Follows all documented standards
4. Has been peer reviewed (by future context)

This is the path to a world-class test suite.