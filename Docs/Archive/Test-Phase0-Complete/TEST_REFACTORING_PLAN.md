# AirFit Test Suite Refactoring Plan

**Date**: 2025-01-07  
**Status**: Active  
**Goal**: Transform the test suite from partial coverage with mixed patterns to comprehensive, standardized testing that ensures reliability and maintainability.

## Executive Summary

The AirFit test suite is currently in transition, with ~30% following modern patterns, ~20% testing outdated code, and ~50% needing minor updates. This plan outlines a systematic approach to standardize all tests while preserving existing coverage.

## Current State Analysis

### Test Distribution
- **Total Test Files**: ~75 files
- **Good Tests (30%)**: Follow DI patterns, test current code
- **Outdated Tests (20%)**: Test deprecated features or use old patterns  
- **Minor Issues (50%)**: Work but need DI migration

### Key Problems
1. **Inconsistent Patterns**: Mix of manual mocking vs DI container
2. **Outdated Tests**: PersonaEngine tests using old Blend system
3. **Missing Coverage**: Critical services lack tests despite having mocks
4. **Compilation Errors**: ~38 errors from Swift 6 concurrency and API changes
5. **Disabled Tests**: 6 test files disabled due to major refactoring

### Strengths to Preserve
1. **Good Examples**: DIBootstrapperTests, HealthKitManagerTests (90% coverage)
2. **Mock Infrastructure**: Comprehensive MockProtocol pattern
3. **DI System**: Modern DIContainer with test support
4. **AAA Pattern**: Already established in newer tests

## Strategic Approach

### Principles
1. **Preserve Working Tests**: Don't delete everything - use good tests as templates
2. **Delete Outdated Code**: Remove tests for deprecated features
3. **Standardize Patterns**: All tests must use DIContainer
4. **Test Current Reality**: Tests must match actual implementation
5. **Enable Parallelization**: No shared state or singletons

### Three-Phase Approach

#### Phase 1: Clean House (1-2 days)
- Delete tests for deprecated code
- Fix compilation errors
- Document patterns from good tests

#### Phase 2: Standardize (3-4 days)
- Migrate all tests to DI pattern
- Update to Swift 6 concurrency
- Ensure consistent naming

#### Phase 3: Fill Gaps (3-4 days)
- Create missing service tests
- Add integration tests
- Achieve 80%+ coverage

## Success Criteria

1. **Zero Compilation Errors**: All tests build successfully
2. **80%+ Coverage**: Critical paths fully tested
3. **Consistent Patterns**: All tests follow same DI/mock patterns
4. **Fast Execution**: Unit tests complete in <2 minutes
5. **Parallel Safe**: Tests can run concurrently without issues

## Documentation Structure

1. **TEST_README.md** - START HERE - Quick overview and current status
2. **TEST_REFACTORING_PLAN.md** (this file) - Overall strategy
3. **TEST_STANDARDS.md** - Patterns and conventions all tests must follow
4. **TEST_MIGRATION_GUIDE.md** - Step-by-step migration instructions
5. **TEST_EXECUTION_PLAN.md** - Prioritized list of tasks with progress tracking

## Next Steps

1. Review and approve this plan
2. Begin Phase 1: Clean House
3. Use TEST_EXECUTION_PLAN.md to track progress
4. Update documentation as patterns emerge

## Risk Mitigation

- **Risk**: Losing test coverage during refactor
- **Mitigation**: Git branch for each phase, run coverage reports

- **Risk**: Breaking working tests
- **Mitigation**: Fix compilation errors first, then refactor

- **Risk**: Scope creep
- **Mitigation**: Strict adherence to phases, defer nice-to-haves

## Success Metrics

- Test execution time: <2 minutes for unit tests
- Coverage: 80%+ for ViewModels/Services
- Consistency: 100% tests use DIContainer
- Reliability: Zero flaky tests
- Maintainability: New developers can add tests easily