**Modular Sub-Document 0: Foundational Testing Strategy & Module Test Retrofit Mandate**

**Version:** 2.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Conceptual outline or initial drafts of Modular Sub-Documents 1 through 12.
**Date:** May 2025
**Updated For:** iOS 18+, macOS 15+, Xcode 16+, Swift 6+

**1. Module Overview**

*   **Purpose:** To establish a comprehensive and non-negotiable testing strategy that underpins the entire AirFit application development process. This module mandates the integration of testing requirements (unit and UI tests) into all feature-specific Modular Sub-Documents (specifically Modules 3 through 11). It also outlines the creation of core testing guidelines and the setup of a reusable mocking framework.
*   **Responsibilities:**
    *   Defining the overarching testing philosophy and strategy for the AirFit project.
    *   Creating the `TESTING_GUIDELINES.md` document with exact content structure.
    *   Establishing concrete mock object templates for all service protocols.
    *   Providing SwiftData test helper utilities.
    *   Implementing UI test page object pattern examples.
    *   **Critically: Tasking an AI Agent to systematically review and update all pre-existing feature module sub-documents (Modules 3-11) to explicitly include detailed agent tasks for writing unit and UI tests for their respective components.**
*   **Key Outputs:**
    *   `TESTING_GUIDELINES.md` document (500-800 lines).
    *   Complete mock implementations in `AirFitTests/Mocks/`.
    *   SwiftData test utilities in `AirFitTests/Utilities/`.
    *   UI test page objects in `AirFitUITests/Pages/`.
    *   **Revised versions of Modular Sub-Documents 3 through 11**.

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Master Architecture Specification (v1.2).
    *   Module 1 completion (Core Setup with protocols defined).
    *   Module 2 completion (Data Layer with models defined).
*   **Outputs:**
    *   Testing foundation that all subsequent modules depend on.
    *   Updated Module 3-11 documents with test tasks.

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 0.1: Create Comprehensive Testing Guidelines**

**Agent Task 0.1.1:**
- Instruction: "Create TESTING_GUIDELINES.md with the following exact sections and content structure"
- Required File Location: `AirFit/Docs/TESTING_GUIDELINES.md`
- Required Sections:
  1. **Testing Philosophy** (100-200 words)
     - Why testing matters for AirFit
     - Goals: reliability, regression prevention, documentation
     - Testing as first-class citizen in development
  
  2. **Test Types** (with definitions and examples)
     - **Unit Tests:**
       - Definition: Tests for individual units of code in isolation
       - Scope: ViewModels, Services, Utilities, Data transformations
       - Example structure with actual Swift 6 code
     - **Integration Tests:**
       - Definition: Tests for component interactions
       - Scope: Service + Repository, ViewModel + Service
       - When to use vs unit tests
     - **UI Tests:**
       - Definition: End-to-end user flow tests
       - Scope: Complete user journeys, critical paths
       - Accessibility requirements
  
  3. **Test Naming Conventions** (with 5+ examples each)
     ```swift
     // Unit Test Pattern
     func test_methodName_givenCondition_shouldExpectedResult()
     func test_calculateBMR_givenValidUserProfile_shouldReturnPositiveValue()
     func test_saveProfile_givenNetworkError_shouldThrowConnectionError()
     
     // UI Test Pattern  
     func test_userFlow_whenAction_thenUIState()
     func test_onboardingFlow_whenCompletingAllSteps_thenDashboardIsVisible()
     func test_mealLogging_whenAddingMeal_thenMealAppearsInList()
     ```
  
  4. **AAA Pattern** (with 3 complete examples)
     ```swift
     // Example 1: Testing calculation logic
     func test_calculateTDEE_givenSedentaryUser_shouldApplyCorrectMultiplier() {
         // Arrange
         let profile = UserProfile(
             age: 30, weight: 70, height: 175,
             biologicalSex: .male, activityLevel: .sedentary
         )
         let calculator = TDEECalculator()
         
         // Act
         let tdee = calculator.calculateTDEE(for: profile)
         
         // Assert
         XCTAssertEqual(tdee, 1750, accuracy: 50) // BMR * 1.2
     }
     
     // Example 2: Testing async operations
     func test_fetchMeals_givenValidResponse_shouldUpdatePublishedProperty() async {
         // Arrange
         let mockService = MockMealService()
         mockService.mockResponse = [Meal(id: "1", name: "Salad")]
         let viewModel = MealViewModel(mealService: mockService)
         
         // Act
         await viewModel.loadMeals()
         
         // Assert
         XCTAssertEqual(viewModel.meals.count, 1)
         XCTAssertEqual(viewModel.meals.first?.name, "Salad")
     }
     
     // Example 3: Testing error handling
     func test_login_givenInvalidCredentials_shouldShowErrorAlert() async {
         // Arrange
         let mockAuth = MockAuthService()
         mockAuth.shouldFailWithError = AuthError.invalidCredentials
         let viewModel = LoginViewModel(authService: mockAuth)
         
         // Act
         await viewModel.login(email: "test@test.com", password: "wrong")
         
         // Assert
         XCTAssertTrue(viewModel.showAlert)
         XCTAssertEqual(viewModel.alertMessage, "Invalid email or password")
     }
     ```
  
  5. **Mocking Strategy** (with protocol example and mock implementation)
     ```swift
     // Protocol definition
     protocol NetworkClientProtocol: Sendable {
         func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
     }
     
     // Mock implementation
     final class MockNetworkClient: NetworkClientProtocol {
         var mockResponses: [String: Any] = [:]
         var capturedRequests: [Endpoint] = []
         var shouldThrowError: Error?
         
         func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
             capturedRequests.append(endpoint)
             
             if let error = shouldThrowError {
                 throw error
             }
             
             guard let response = mockResponses[endpoint.path] as? T else {
                 throw NetworkError.invalidResponse
             }
             
             return response
         }
     }
     ```
  
  6. **SwiftData Testing** (with complete in-memory container setup)
     ```swift
     // Test helper for SwiftData
     @MainActor
     class SwiftDataTestHelper {
         static func createTestContainer(for types: any PersistentModel.Type...) throws -> ModelContainer {
             let config = ModelConfiguration(isStoredInMemoryOnly: true)
             let schema = Schema(types)
             return try ModelContainer(for: schema, configurations: config)
         }
         
         static func createTestContext(for types: any PersistentModel.Type...) throws -> ModelContext {
             let container = try createTestContainer(for: types)
             return ModelContext(container)
         }
     }
     
     // Usage in tests
     override func setUp() async throws {
         try await super.setUp()
         modelContext = try SwiftDataTestHelper.createTestContext(
             for: User.self, Meal.self, NutritionData.self
         )
     }
     ```
  
  7. **Code Coverage Requirements**
     - ViewModels: 80% minimum
     - Services: 70% minimum  
     - Utilities: 90% minimum
     - UI Tests: Cover all critical user paths
     - How to measure: `xcrun xccov view --report coverage.xcresult`
  
  8. **CI/CD Integration**
     - Tests must run headlessly
     - No external dependencies
     - Timeout considerations
     - Parallel test execution setup
  
  9. **Accessibility Testing**
     - All interactive elements must have identifiers
     - Naming convention: `module.component.element`
     - Example: `onboarding.welcome.continueButton`
     - VoiceOver testing requirements

- Acceptance Criteria: 
  - File exists at `AirFit/Docs/TESTING_GUIDELINES.md`
  - Contains all 9 sections with code examples
  - At least 3 code examples per section where applicable
  - File is 500-800 lines
  - All code examples compile with Swift 6

---

**Task 0.2: Create Comprehensive Mock Framework**

**Agent Task 0.2.1: Create Base Mock Protocols**
- Instruction: "Create MockProtocol.swift with base mock functionality"
- File Location: `AirFit/AirFitTests/Mocks/Base/MockProtocol.swift`
- Content:
  ```swift
  import Foundation
  
  /// Base protocol for all mocks to track method calls
  protocol MockProtocol: AnyObject {
      var invocations: [String: [Any]] { get set }
      var stubbedResults: [String: Any] { get set }
      
      func recordInvocation(_ method: String, arguments: Any...)
      func stub<T>(_ method: String, with result: T)
      func verify(_ method: String, called times: Int)
  }
  
  extension MockProtocol {
      func recordInvocation(_ method: String, arguments: Any...) {
          if invocations[method] == nil {
              invocations[method] = []
          }
          invocations[method]?.append(arguments)
      }
      
      func stub<T>(_ method: String, with result: T) {
          stubbedResults[method] = result
      }
      
      func verify(_ method: String, called times: Int) {
          let actual = invocations[method]?.count ?? 0
          assert(actual == times, "\(method) was called \(actual) times, expected \(times)")
      }
  }
  ```

**Agent Task 0.2.2: Create Service Mocks**
- Instruction: "Create mock implementations for all service protocols"
- Required Mocks:
  1. `MockUserService.swift`
  2. `MockMealService.swift`
  3. `MockHealthKitService.swift`
  4. `MockAICoachService.swift`
  5. `MockNotificationService.swift`
  6. `MockNetworkClient.swift`

- Example Template for `MockUserService.swift`:
  ```swift
  import Foundation
  @testable import AirFit
  
  @MainActor
  final class MockUserService: UserServiceProtocol, MockProtocol {
      var invocations: [String: [Any]] = [:]
      var stubbedResults: [String: Any] = [:]
      
      // Stubbed responses
      var createUserResult: Result<User, Error> = .success(User.mock)
      var updateProfileResult: Result<Void, Error> = .success(())
      var getCurrentUserResult: User? = User.mock
      
      func createUser(from profile: OnboardingProfile) async throws -> User {
          recordInvocation(#function, arguments: profile)
          
          switch createUserResult {
          case .success(let user):
              return user
          case .failure(let error):
              throw error
          }
      }
      
      func updateProfile(_ updates: ProfileUpdate) async throws {
          recordInvocation(#function, arguments: updates)
          
          if case .failure(let error) = updateProfileResult {
              throw error
          }
      }
      
      func getCurrentUser() -> User? {
          recordInvocation(#function)
          return getCurrentUserResult
      }
  }
  
  // Test data extensions
  extension User {
      static var mock: User {
          User(
              id: UUID(),
              name: "Test User",
              email: "test@example.com",
              profile: UserProfile.mock
          )
      }
  }
  ```

**Agent Task 0.2.3: Create UI Test Helpers**
- Instruction: "Create page object base class and examples"
- File Location: `AirFit/AirFitUITests/Pages/BasePage.swift`
- Content:
  ```swift
  import XCTest
  
  class BasePage {
      let app: XCUIApplication
      let timeout: TimeInterval = 10
      
      required init(app: XCUIApplication) {
          self.app = app
      }
      
      func waitForElement(_ element: XCUIElement, timeout: TimeInterval? = nil) -> Bool {
          element.waitForExistence(timeout: timeout ?? self.timeout)
      }
      
      func tapElement(_ element: XCUIElement) {
          XCTAssertTrue(waitForElement(element), "\(element) not found")
          element.tap()
      }
      
      func typeText(in element: XCUIElement, text: String) {
          XCTAssertTrue(waitForElement(element), "\(element) not found")
          element.tap()
          element.typeText(text)
      }
      
      func verifyElement(exists element: XCUIElement) {
          XCTAssertTrue(waitForElement(element), "\(element) should exist")
      }
      
      func verifyElement(notExists element: XCUIElement) {
          XCTAssertFalse(element.exists, "\(element) should not exist")
      }
  }
  
  // Example page object
  class OnboardingPage: BasePage {
      // Elements
      var welcomeTitle: XCUIElement {
          app.staticTexts["onboarding.welcome.title"]
      }
      
      var continueButton: XCUIElement {
          app.buttons["onboarding.continue.button"]
      }
      
      var nameField: XCUIElement {
          app.textFields["onboarding.name.field"]
      }
      
      // Actions
      func tapContinue() {
          tapElement(continueButton)
      }
      
      func enterName(_ name: String) {
          typeText(in: nameField, text: name)
      }
      
      // Verifications
      func verifyOnWelcomeScreen() {
          verifyElement(exists: welcomeTitle)
          verifyElement(exists: continueButton)
      }
  }
  ```

**Agent Task 0.2.4: Create Test Data Builders**
- Instruction: "Create builder pattern for test data creation"
- File Location: `AirFit/AirFitTests/Utilities/TestDataBuilders.swift`
- Example:
  ```swift
  // Builder for creating test data with Swift 6 features
  @MainActor
  final class UserProfileBuilder {
      private var age: Int = 30
      private var weight: Double = 70
      private var height: Double = 175
      private var biologicalSex: BiologicalSex = .male
      private var activityLevel: ActivityLevel = .moderate
      private var goal: FitnessGoal = .maintainWeight
      
      func with(age: Int) -> Self {
          self.age = age
          return self
      }
      
      func with(weight: Double) -> Self {
          self.weight = weight
          return self
      }
      
      func with(activityLevel: ActivityLevel) -> Self {
          self.activityLevel = activityLevel
          return self
      }
      
      func build() -> UserProfile {
          UserProfile(
              age: age,
              weight: weight,
              height: height,
              biologicalSex: biologicalSex,
              activityLevel: activityLevel,
              goal: goal
          )
      }
  }
  ```

---

**Task 0.3: Retrofit Testing Requirements into Feature Modules**

**Agent Task 0.3.1: Update Module Documentation Structure**
- Instruction: "Update each Module (3-11) documentation with specific test tasks"
- For each module, add:
  1. **Testing Requirements** section after component specifications
  2. Specific unit test tasks for each ViewModel/Service
  3. Specific UI test tasks for each user flow
  4. Test file naming and location specifications
  5. Concrete acceptance criteria with metrics

- Template for adding to each module:
  ```markdown
  ## Testing Requirements
  
  ### Unit Tests
  
  **Agent Task X.Y.Z: Create [Component]Tests**
  - File: `AirFitTests/[Module]/[Component]Tests.swift`
  - Requirements:
    - Test all public methods
    - Use mocks from `AirFitTests/Mocks/`
    - Achieve 80% code coverage for ViewModels
    - Follow AAA pattern from TESTING_GUIDELINES.md
  - Test Cases:
    1. `test_[method]_given[Condition]_should[Result]()`
    2. `test_[method]_whenErrorOccurs_shouldHandleGracefully()`
    3. [List specific test cases for this component]
  - Acceptance: All tests pass, coverage ≥ 80%
  
  ### UI Tests
  
  **Agent Task X.Y.Z: Create [Flow]UITests**
  - File: `AirFitUITests/[Module]/[Flow]UITests.swift`
  - Requirements:
    - Use page object pattern
    - Test happy path and error cases
    - Verify accessibility
  - Test Scenarios:
    1. Complete flow successfully
    2. Handle validation errors
    3. Verify navigation
  - Acceptance: All UI tests pass on iPhone 16 Pro simulator
  ```

**Agent Task 0.3.2: Create Module Test Verification Script**
- Instruction: "Create a shell script to verify module test completion"
- File: `AirFit/Scripts/verify_module_tests.sh`
- Content:
  ```bash
  #!/bin/bash
  
  # Usage: ./verify_module_tests.sh [module_number]
  
  MODULE=$1
  
  if [ -z "$MODULE" ]; then
      echo "Usage: $0 [module_number]"
      exit 1
  fi
  
  echo "Verifying tests for Module $MODULE..."
  
  # Run module-specific tests
  xcodebuild test \
      -scheme "AirFit" \
      -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
      -only-testing:AirFitTests/Module${MODULE} \
      -resultBundlePath Module${MODULE}TestResults.xcresult
  
  # Extract coverage metrics
  xcrun xccov view --report Module${MODULE}TestResults.xcresult --json > coverage.json
  
  # Check coverage threshold
  python3 -c "
  import json
  with open('coverage.json') as f:
      data = json.load(f)
      coverage = data['lineCoverage']
      print(f'Module ${MODULE} coverage: {coverage*100:.1f}%')
      exit(0 if coverage >= 0.7 else 1)
  "
  ```

---

**Task 0.4: Create Testing Dashboard and Documentation**

**Agent Task 0.4.1: Create Test Status Dashboard**
- Instruction: "Create TEST_STATUS.md to track testing progress"
- File: `AirFit/Docs/TEST_STATUS.md`
- Template:
  ```markdown
  # AirFit Test Status Dashboard
  
  Last Updated: [Date]
  
  ## Overall Coverage: X%
  
  | Module | Unit Tests | UI Tests | Coverage | Status |
  |--------|------------|----------|----------|---------|
  | Module 0 | ✅ 15/15 | N/A | 95% | Complete |
  | Module 1 | ✅ 20/20 | N/A | 88% | Complete |
  | Module 2 | ⏳ 18/25 | N/A | 72% | In Progress |
  | Module 3 | ❌ 0/30 | ❌ 0/5 | 0% | Not Started |
  ...
  
  ## Test Execution Commands
  
  ```bash
  # Run all tests
  xcodebuild test -scheme "AirFit" 
  
  # Run specific module tests
  ./Scripts/verify_module_tests.sh 3
  ```
  ```

**Agent Task 0.4.2: Create Example Test Implementation**
- Instruction: "Create a complete example test file demonstrating all patterns"
- File: `AirFit/AirFitTests/Examples/ExampleViewModelTests.swift`
- Must include:
  - Swift 6 concurrency (@MainActor)
  - Mock usage
  - SwiftData setup
  - Async testing
  - Error handling tests
  - Published property observation

---

**4. Acceptance Criteria for Module Completion**

- ✅ `TESTING_GUIDELINES.md` created with all 9 sections (500-800 lines)
- ✅ Base mock protocol and utilities created
- ✅ Mock implementations for all 6 core services
- ✅ UI test page object pattern implemented with base class
- ✅ Test data builders created
- ✅ All Modules 3-11 updated with specific test tasks
- ✅ Module test verification script functional
- ✅ TEST_STATUS.md dashboard created
- ✅ Example test implementation demonstrates all patterns
- ✅ All code compiles with Swift 6 and Xcode 16
- ✅ CI can execute all tests successfully

**5. Module Dependencies**

- **Requires Completion Of:** Module 1 (protocols defined), Module 2 (data models)
- **Must Be Completed Before:** Module 3-12 implementation
- **Can Run In Parallel With:** None (foundational requirement)

**6. Performance Requirements**

- Test suite execution: < 5 minutes for all unit tests
- Individual test: < 100ms (except integration tests)
- UI test execution: < 30 seconds per flow
- Mock setup: < 10ms per mock

---
