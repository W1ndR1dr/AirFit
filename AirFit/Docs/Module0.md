**Modular Sub-Document 0: Foundational Testing Strategy & Module Test Retrofit Mandate**

**Version:** 1.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Conceptual outline or initial drafts of Modular Sub-Documents 1 through 12.
**Date:** May 24, 2025

**1. Module Overview**

*   **Purpose:** To establish a comprehensive and non-negotiable testing strategy that underpins the entire AirFit application development process. This module mandates the integration of testing requirements (unit and UI tests) into all feature-specific Modular Sub-Documents (specifically Modules 3 through 11). It also outlines the creation of core testing guidelines and the setup of a reusable mocking framework.
*   **Responsibilities:**
    *   Defining the overarching testing philosophy and strategy for the AirFit project.
    *   Creating the `TESTING_GUIDELINES.md` document.
    *   Establishing a strategy and initial set of mock objects for common services and dependencies.
    *   **Critically: Tasking an AI Agent (or guiding a process) to systematically review and update all pre-existing feature module sub-documents (Modules 3-11) to explicitly include detailed agent tasks for writing unit and UI tests for their respective components.**
    *   Ensuring that "testability" and "test coverage" are primary concerns from the outset and throughout the development lifecycle.
*   **Key Outputs of this Module (as it pertains to setting project standards and retrofitting):**
    *   `TESTING_GUIDELINES.md` document.
    *   Initial set of core mock object implementations (e.g., for `AIAPIServiceProtocol`, `APIKeyManager`, etc.).
    *   **Revised versions of Modular Sub-Documents 3 through 11**, each now containing explicit tasks for test generation.
    *   A clear directive that no feature module is considered complete without its associated tests being implemented and passing.

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Master Architecture Specification (v1.2) – for understanding component responsibilities and interactions, which informs what needs testing.
    *   Initial drafts/outlines of Modular Sub-Documents 1-12 – these are the documents to be reviewed and updated.
*   **Outputs (from the retrofit process):**
    *   Updated Modular Sub-Documents 3-11, now test-inclusive.
    *   A project-wide understanding and commitment to test-driven or test-aware development.

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 0.1: Establish Core Testing Guidelines**
    *   **Agent Task 0.1.1:**
        *   Instruction: "Create a new Markdown file named `TESTING_GUIDELINES.md` in the project's root directory."
        *   Details: Populate this file with comprehensive testing guidelines. The content should include, but not be limited to:
            *   **Philosophy:** Importance of testing, goals (reliability, regression prevention, documentation).
            *   **Types of Tests:**
                *   Unit Tests: Scope, purpose, what to test (public methods, logic, edge cases).
                *   Integration Tests (Conceptual): How different units work together (can be light initially, focusing on service interactions).
                *   UI Tests: Scope, purpose, what to test (key user flows, UI element states, navigation). Use of accessibility identifiers.
            *   **Test Structure (Arrange-Act-Assert - AAA):** Mandate this pattern.
            *   **Naming Conventions:**
                *   Unit Tests: `test_MethodName_WithCondition_ShouldReturnExpectedBehavior()` or `testGiven[Precondition]_When[Action]_Then[ExpectedResult]()`.
                *   UI Tests: `test_[FlowName]_When[Action]_Then[UIIsInExpectedState]()`.
            *   **Test Independence & Isolation:** Each test must be runnable independently and not affect others.
            *   **Readability & Maintainability:** Tests are code and must be clear and maintainable.
            *   **Mocking & Stubbing:**
                *   Clear guidance on when and how to use mocks/stubs for dependencies.
                *   Preference for protocol-based mocking.
            *   **SwiftData Testing:** Strategy for using in-memory `ModelContainer` for unit tests.
            *   **Code Coverage:** Define an initial target (e.g., 70% for business logic) and emphasize its importance.
            *   **CI/CD:** Note that tests must be runnable in an automated CI environment.
            *   **Accessibility Identifiers:** Mandate their use for UI testing.
        *   Acceptance Criteria: `TESTING_GUIDELINES.md` is created and contains comprehensive, actionable guidelines.

---

**Task 0.2: Develop Initial Mocking Framework**
    *   **Agent Task 0.2.1:**
        *   Instruction: "Based on the protocols defined for key services in early modules (e.g., `AIAPIServiceProtocol` from Module 10, `WhisperServiceWrapperProtocol` from Module 8, `APIKeyManager` if refactored to a protocol, `NotificationManager` if refactored to a protocol), create initial mock implementations for each."
        *   Details:
            *   Place mocks in a dedicated test support directory accessible by test targets (e.g., `AirFit/AirFitTests/Mocks/` or a shared test utilities target).
            *   Mocks should:
                *   Conform to their respective protocols.
                *   Allow configuration of return values for their methods.
                *   Track whether methods were called and with what parameters.
                *   Provide default, non-crashing behavior.
            *   Example structure (reiterating from Module 12 for clarity):
                ```swift
                // Example: MockAIAPIService.swift
                class MockAIAPIService: AIAPIServiceProtocol {
                    var configureCalledWith: (provider: AIProvider, apiKey: String, modelIdentifier: String?)?
                    var getStreamingResponseCalledWithRequest: AIRequest?
                    var mockStreamingResponsePublisher: AnyPublisher<AIResponseType, Error> = Empty().eraseToAnyPublisher()

                    func configure(provider: AIProvider, apiKey: String, modelIdentifier: String?) {
                        configureCalledWith = (provider, apiKey, modelIdentifier)
                    }

                    func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponseType, Error> {
                        getStreamingResponseCalledWithRequest = request
                        return mockStreamingResponsePublisher
                    }
                }
                ```
        *   Acceptance Criteria: Initial mock objects for critical, defined service protocols are created and functional for use in unit tests. *(Vibe-Coder Note: This task might require instructing the agent to first ensure that these services *do* have protocols. If a service was implemented as a concrete class without a protocol in an earlier module's definition, a preceding sub-task here would be "Refactor `[ServiceName].swift` to define and conform to `[ServiceNameProtocol]` to enable mocking.")*

---

**Task 0.3: Mandate and Execute Retrofit of Testing Tasks into Modules 3-11**
    *   **Agent Task 0.3.1 (The Retrofit Operation):**
        *   Instruction: "Systematically review each Modular Sub-Document from Module 3 (Onboarding) through Module 11 (Settings). For each module:
            1.  Identify every significant logic-bearing component (ViewModels, Engines, Managers, Services, etc.) and every major UI View/User Flow defined.
            2.  For each such component/flow, append new, explicit 'Agent Tasks' that instruct the Code Generation Agent to write corresponding XCTest unit tests (for logic components) or XCTest UI tests (for UI flows).
            3.  These new test-generation tasks must adhere to the specifications laid out in the 'General Instructions for the Agent' section of the 'Task Refinement Pass: Integrating Testing Requirements' document (which details how to structure these new test tasks, including references to `TESTING_GUIDELINES.md`, mocking, SwiftData setup, and accessibility identifiers).
            4.  Update the 'Acceptance Criteria for Module Completion' section of each reviewed module to include successful implementation and passing of these newly defined unit and UI tests."
        *   Details: The agent performing this "retrofit" task is essentially editing the existing Markdown documents for Modules 3-11. It needs to understand the structure of those documents and inject the new test-related tasks appropriately.
        *   Example of an injected task (from previous discussion):
            ```
            **Agent Task X.Y.Z (Unit Tests for [ComponentName]):**
                *   Instruction: "Create an XCTest unit test file named `[ComponentName]Tests.swift`..."
                *   Details: "Utilize mock implementations... For SwiftData, use in-memory ModelContainer... Follow TESTING_GUIDELINES.md..."
                *   Acceptance Criteria: "Unit tests for `[ComponentName]` are created, compile, and pass..."
            ```
        *   Acceptance Criteria: Revised versions of Modular Sub-Documents 3 through 11 are produced, each now containing explicitly defined tasks for generating unit and UI tests for its components. The overall module acceptance criteria are also updated to reflect testing requirements.

---

**Task 0.4: Final Review & Commit of Foundational Testing Artifacts**
    *   **Agent Task 0.4.1:**
        *   Instruction: "Review the created `TESTING_GUIDELINES.md` and the initial set of mock object implementations for clarity, completeness, and adherence to best practices."
        *   Acceptance Criteria: Core testing documentation and initial mocks are of high quality.
    *   **Agent Task 0.4.2:**
        *   Instruction: "Verify that the AI Agent performing Task 0.3 has correctly updated at least one representative feature module sub-document (e.g., Module 3 - Onboarding) with the new testing tasks, and that these new tasks are well-defined."
        *   Acceptance Criteria: The retrofit process itself is demonstrated to be working correctly on a sample. *(Vibe-Coder Note: You will likely need to review all retrofitted documents from Task 0.3 yourself or with the agent.)*
    *   **Agent Task 0.4.3:**
        *   Instruction: "Stage and commit `TESTING_GUIDELINES.md`, all created mock object files, and all *revised* Modular Sub-Documents (Modules 3-11)."
        *   Details: Commit message: "Feat: Establish Foundational Testing Strategy (Module 0) and retrofit testing tasks into feature modules".
        *   Acceptance Criteria: All foundational testing artifacts and revised module plans are committed to the Git repository.

---

**4. Acceptance Criteria for Module Completion**

*   A comprehensive `TESTING_GUIDELINES.md` document is created and committed.
*   Initial mock implementations for key service protocols are created and committed.
*   **All feature-specific Modular Sub-Documents (Modules 3 through 11) have been successfully revised to include explicit tasks for the generation of unit and UI tests, and their overall acceptance criteria now mandate the completion of these tests.**
*   The project has a clear, documented, and mandated approach to testing that will be applied throughout the development of all subsequent features.

**5. Implications for AI Agent Workflow**

*   **Order of Execution:** This "Module 0" and its Task 0.3 (the retrofit) should conceptually be completed *before* AI Code Generation Agents begin implementing the feature code for Modules 3-11 based on their *revised* sub-documents.
*   **Agent Instructions:** When an AI Code Generation Agent is tasked with implementing a component from a revised module (e.g., `OnboardingViewModel.swift`), it will now see an accompanying task to also generate `OnboardingViewModelTests.swift`.
*   **Iterative Refinement:** The `TESTING_GUIDELINES.md` and mock implementations may evolve as the project progresses and new testing challenges arise.

---
