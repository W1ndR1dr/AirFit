# Disabled Tests Recovery Plan

**Date**: 2025-06-05
**Total Disabled Tests**: 10 files

> **Navigation**: This is document 4 of 7 in the test analysis series.  
> **Previous**: [TEST_EXECUTION_ANALYSIS.md](./TEST_EXECUTION_ANALYSIS.md)  
> **Next**: [MOCK_PATTERNS_GUIDE.md](./MOCK_PATTERNS_GUIDE.md) - Mock implementation standards

## Overview

The disabled tests fall into three main categories:
1. **Persona System Refactoring** (40% - architectural changes)
2. **Missing Mock Dependencies** (30% - infrastructure gaps)  
3. **API Signature Changes** (30% - method updates needed)

## Detailed Recovery Plan

### Priority 1: Low-Hanging Fruit

#### 1. FoodVoiceAdapterTests.swift.disabled
**Issue**: Cannot inject VoiceInputManager (concrete dependency)
**Solution**: 
```swift
// Extract protocol from VoiceInputManager
protocol VoiceInputProtocol {
    func requestPermission(completion: @escaping (Bool) -> Void)
    func startTranscription(completion: @escaping (Result<String, Error>) -> Void)
    func stopTranscription()
    var isTranscribing: Bool { get }
}

// Update FoodVoiceAdapter to use protocol
class FoodVoiceAdapter {
    private let voiceInput: VoiceInputProtocol // Instead of VoiceInputManager
}
```
**Status**: Quick fix - extract protocol

#### 2. OnboardingViewTests.swift.disabled
**Issue**: UI tests for refactored views
**Solution**:
- Update view references to match current implementation
- Fix accessibility identifiers
- Update expected view hierarchy
**Status**: Quick fix - update references

### Priority 2: Create Missing Infrastructure

#### 1. Create Missing Mocks
**Files Affected**: ConversationViewModelTests, several integration tests
**Required Mocks**:
```swift
// MockConversationFlowManager.swift
@MainActor
class MockConversationFlowManager: ConversationFlowManagerProtocol, MockProtocol {
    // Implement protocol methods
    // Track invocations
    // Provide stubbing
}

// MockConversationPersistence.swift  
class MockConversationPersistence: ConversationPersistenceProtocol, MockProtocol {
    // Implement save/load methods
    // Simulate persistence
}

// MockConversationAnalytics.swift
class MockConversationAnalytics: ConversationAnalyticsProtocol, MockProtocol {
    // Track analytics events
    // Provide verification helpers
}
```
**Status**: Required for multiple tests

#### 2. Recreate TestDataGenerators
**Files Affected**: ServicePerformanceTests
**Solution**:
```swift
// TestDataGenerators.swift
enum TestDataGenerators {
    static func makeAIRequest() -> AIRequest
    static func makeAIResponse() -> AIResponse
    static func makeUserProfile() -> User
    static func makeHealthContext() -> HealthContext
    // ... other factory methods
}
```
**Status**: Needed for ServicePerformanceTests

### Priority 3: Update API Calls

#### 1. Phase2ValidationTests.swift.disabled
**Issue**: Uses old conversation manager APIs
**Solution**:
- Update to new ConversationFlowManager methods
- Fix predicate optimization tests
- Remove references to deleted functionality
**Status**: API changes needed

#### 2. NutritionParsingFinalIntegrationTests.swift.disabled
**Issue**: Old CoachEngine patterns
**Solution**:
- Update to use DI-based CoachEngine creation
- Fix nutrition parsing API calls
- Update mock patterns
**Status**: API changes needed

#### 3. ConversationViewModelTests.swift.disabled
**Issue**: Missing mocks + API changes
**Solution**:
- Use newly created mocks
- Update ViewModel initialization
- Fix test assertions for new behavior
**Status**: Depends on new mocks

### Priority 4: Major Refactoring

#### 1. PersonaEngineTests.swift.disabled
**Issue**: Complete API rewrite needed
**Old vs New**:
```swift
// Old API
buildSystemPrompt(userProfile, healthContext, conversationHistory)

// New API  
buildSystemPrompt(personaMode, userGoal, userContext)
```
**Solution Options**:
- Option A: Rewrite tests for new simplified API
- Option B: Delete and write new tests from scratch
**Recommendation**: Option B - the persona system is fundamentally different

#### 2. PersonaSystemIntegrationTests.swift.disabled
**Issue**: Tests entire old persona generation flow
**Solution**:
- Evaluate if integration test is still needed
- If yes: Rewrite for new architecture
- If no: Delete and ensure unit test coverage
**Recommendation**: Evaluate if still needed

#### 3. ServicePerformanceTests.swift.disabled
**Issue**: References removed EnhancedAIAPIService
**Solution**:
- Rewrite for new AIService + LLMOrchestrator
- Update streaming API tests
- Create new performance benchmarks
**Recommendation**: Rewrite for new architecture

### Priority 5: Evaluate for Deletion

#### 1. PersonaEnginePerformanceTests.swift.disabled
**Reason**: Tests token optimization that's already complete (2000→600)
**Recommendation**: Delete - optimization is done

#### 2. PersonaGenerationStressTests.swift.disabled  
**Reason**: Tests old persona generation under load
**Recommendation**: Rewrite if load testing is still needed

## Implementation Order

### Dependencies First
1. Create all missing mocks (required by multiple tests)
2. Create TestDataGenerators (required by ServicePerformanceTests)

### Quick Wins Next
3. Fix FoodVoiceAdapterTests (protocol extraction)
4. Fix OnboardingViewTests (reference updates)

### API Updates
5. Fix tests with simple API changes
6. Fix tests requiring new mocks

### Major Work Last
7. Evaluate tests for rewrite vs deletion
8. Implement rewrites for valuable tests

## Success Metrics

1. **Coverage Recovery**
   - Before: 90.8% of tests enabled
   - Target: 95%+ enabled (some may be deleted)

2. **Test Execution Time**
   - Baseline: Current suite time
   - Target: No more than 10% increase

3. **Mock Reusability**
   - New mocks used in 3+ test files
   - Consistent pattern adoption

## Risk Mitigation

### Risk 1: Broken Tests After Re-enabling
**Mitigation**: 
- Run each test in isolation first
- Use version control to track changes
- Keep disabled version until new one passes

### Risk 2: Performance Regression
**Mitigation**:
- Profile tests before/after
- Set timeout limits
- Use parallel execution

### Risk 3: Architectural Mismatch
**Mitigation**:
- Verify current architecture before fixing
- Consult with team on unclear areas
- Document assumptions

## Alternatives to Consider

1. **Don't Fix, Rewrite**: For tests >6 months old
2. **Convert to Integration Tests**: For complex unit tests
3. **Delete and Monitor**: For redundant coverage
4. **Defer Indefinitely**: For deprecated features

## Conclusion

The disabled tests represent ~10% of the test suite but significant technical debt. The persona system refactoring is the root cause of 40% of failures. By systematically creating missing infrastructure and updating API calls, we can recover most tests. Some tests should be deleted rather than fixed, particularly those testing optimizations that are already complete.