# AirFit Testing Guidelines

These guidelines establish the required approach for all unit and UI tests in the AirFit project. Refer to this document when implementing tests in each module.

## Philosophy

Testing ensures reliability, prevents regressions and serves as documentation. Every logic component and user flow must have accompanying tests that run in CI.

## Types of Tests

- **Unit Tests** focus on public methods and logic edge cases.
- **Integration Tests** verify how multiple units interact (used sparingly to keep tests fast).
- **UI Tests** exercise key user flows with accessibility identifiers.

## Test Structure

Follow the Arrange-Act-Assert (AAA) pattern in every test method to keep intent clear.

## Naming Conventions

- Unit tests: `test_MethodName_WithCondition_ShouldReturnExpected()`
- UI tests: `test_Flow_WhenAction_ThenUIIsInExpectedState()`

## Independence and Isolation

Tests must run independently and not rely on shared state.
Use protocol-based mocks and in-memory SwiftData containers to isolate dependencies.

## Readability

Tests are first-class code. Keep them clear and maintainable with descriptive helper methods when needed.

## Mocking & Stubbing

Prefer protocol-based mocks placed under `AirFitTests/Mocks`. Mocks should allow configurable return values and track invocations.

## SwiftData Testing

Use an in-memory `ModelContainer` when a test touches persistence.

## Code Coverage

Aim for at least 70% coverage on business logic. Coverage is measured in CI.

## CI/CD

All tests must run without network access and pass in automated CI pipelines.

## Accessibility Identifiers

Every interactive view used in UI tests must expose identifiers to allow reliable selection.
