# AirFit Agent Guidelines

This repository documents AirFit. All code generation and docs must follow these guidelines.

## 1. Source of Truth

* Use `Design.md` and `ArchitectureOverview.md` for UI/UX, structure, and tech choices.
* Feature work is organized into modular sub‑documents (`Module0.md`, `Module1.md`, `Module2.md`, etc.).
* Each module defines agent tasks and acceptance criteria. Follow them carefully.
* Consult the remaining `ModuleX.md` files for feature-specific instructions.
* `OnboardingFlow.md` and `SystemPrompt.md` detail onboarding flows and persona creation.

## 2. Coding Conventions

* Language: **Swift**.
* Follow **Apple's Swift API Design Guidelines**.
* Prefer `let` over `var` when possible and avoid force unwrapping or force casts.
* Organize files by feature module first, then by type as in `Module1.md` (e.g., `AirFit/Modules/Onboarding/Views/`).
* Create small, reusable SwiftUI views and supply preview structs for each view.
* Ensure all network calls and long‑running work use `async/await`.
* Define protocols for service types to enable mocking as outlined in Module0.
* Use `AppLogger` for diagnostics and debug output.
* Comment to explain **why** when intent is not obvious. Use `MARK:` comments to organize large files.

## 3. Linting and Formatting

* Run SwiftFormat if available to maintain consistent style.
* The project integrates **SwiftLint** (see Module1) and optionally **SwiftFormat**.
* Generated code must compile without SwiftLint violations.
* SwiftLint configuration lives at `.swiftlint.yml`; keep new rules consistent.

## 4. Testing Expectations

* Testing is a core requirement. Module0 introduces `TESTING_GUIDELINES.md` and a mocking framework.
* For any logic or view created, generate corresponding **unit tests** or **UI tests** following Module0.
* Tests must use the Arrange-Act-Assert pattern.
* Name test files like `SomeClassTests.swift` or `test_Flow_WhenAction_ThenExpectedState()`.
* Refer to `Module12.md` for code coverage targets and CI considerations.
* Tests must run without network access and rely on mocks from `AirFitTests/Mocks/`.
* Aim for at least 70% code coverage for business logic and keep tests compatible with CI pipelines.

## 5. Commit Guidance

* Each change should be committed with a clear message describing the feature or fix.
* Run any provided build or test scripts before committing.
* Ensure the repository stays clean (`git status` shows no untracked changes`).

## 6. Documentation Updates

* When updating a module plan or creating new documentation, maintain the same style as existing `ModuleX.md` files.
* Keep Markdown lines wrapped at roughly 120 characters to maintain readability.

## 7. General Principles

* Keep the experience "clean, classy & premium" as described in `Design.md`.
* Build modules in the sequence and with the dependencies indicated in `ArchitectureOverview.md`.
* If details are unclear, add TODOs summarizing what needs human input.
* Prefer clarity and maintainability over cleverness.
* If a task is blocked by missing context, pause and ask the user to start a Deep Research thread.

