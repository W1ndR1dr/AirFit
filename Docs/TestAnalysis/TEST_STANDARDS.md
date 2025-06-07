# AirFit Test Standards & Conventions

**Purpose**: Single source of truth for all test standards, patterns, and conventions
**Last Updated**: 2025-06-05

## 🎯 Test Types & When to Use Them

### Decision Tree
```
Is it testing a single class/function in isolation?
  ├─ YES → Unit Test
  └─ NO → Does it test multiple components working together?
      ├─ YES → Integration Test
      └─ NO → Does it test end-to-end user flows?
          ├─ YES → UI Test (not currently used)
          └─ NO → Performance Test
```

### Test Type Standards

| Type | Naming | Location | Typical Duration | Mock Usage |
|------|---------|----------|------------------|------------|
| Unit | `{Class}Tests.swift` | Next to source | <100ms | Heavy mocking |
| Integration | `{Feature}IntegrationTests.swift` | `/Integration/` | 100ms-1s | Selective mocking |
| Performance | `{Feature}PerformanceTests.swift` | `/Performance/` | Varies | Minimal mocking |

## 📝 Naming Conventions

### Test Method Names
```swift
// Pattern: test_{methodName}_{scenario}_{expectedResult}
func test_saveNutrition_withValidData_savesSuccessfully()
func test_saveNutrition_withNilCalories_throwsValidationError()
func test_syncWorkout_whenOffline_queuesForLaterSync()
```

### Mock Names
```swift
// Always prefix with Mock
class MockHealthKitManager: HealthKitManagerProtocol
class MockNetworkClient: NetworkClientProtocol

// Never use suffix
❌ HealthKitManagerMock
❌ NetworkClientMockImpl
```

### Test File Organization
```swift
// Standard structure for all test files
import XCTest
@testable import AirFit

final class ExampleTests: XCTestCase {
    // MARK: - Properties
    private var sut: SystemUnderTest!  // Always name SUT as 'sut'
    private var mockDependency: MockDependency!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        // Minimal setup only
    }
    
    override func tearDown() {
        sut = nil
        mockDependency = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    private func setupTest(/* test-specific params */) async throws {
        // Async setup pattern
    }
    
    // MARK: - Tests
    // Group by functionality
    
    // MARK: - {Feature} Tests
    func test_feature_scenario_result() async throws {
        // Arrange
        // Act  
        // Assert
    }
}
```

## 🔧 Standard Patterns

### 1. Async Test Setup (Required for DI)
```swift
@MainActor
final class ViewModelTests: XCTestCase {
    private var container: DIContainer!
    private var sut: ViewModel!
    
    private func setupTest(
        stubbedData: [String: Any] = [:],
        shouldThrow: Bool = false
    ) async throws {
        container = try await DITestHelper.createTestContainer()
        
        // Configure mocks
        let mockService = try await container.resolve(ServiceProtocol.self) as? MockService
        mockService?.stubbedResults = stubbedData
        mockService?.shouldThrowError = shouldThrow
        
        // Create SUT
        let factory = DIViewModelFactory(container: container)
        sut = try await factory.makeViewModel()
    }
    
    func test_example() async throws {
        // Arrange
        try await setupTest(stubbedData: ["key": "value"])
        
        // Act
        await sut.performAction()
        
        // Assert
        XCTAssertEqual(sut.state, .expected)
    }
}
```

### 2. Mock Implementation Standard
```swift
import Foundation
@testable import AirFit

final class MockService: ServiceProtocol, MockProtocol {
    // MARK: - MockProtocol
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - Configuration
    var shouldThrowError = false
    var errorToThrow: Error = MockError.generic
    var simulatedDelay: TimeInterval = 0
    
    // MARK: - ServiceProtocol
    func fetchData(id: String) async throws -> Data {
        recordInvocation("fetchData", arguments: id)
        
        // Simulate delay if configured
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        // Throw if configured
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Return stubbed result
        return stubbedResult(for: "fetchData", default: Data())
    }
    
    // MARK: - Verification Helpers
    func verifyFetchDataCalled(withId id: String, file: StaticString = #file, line: UInt = #line) {
        let calls = invocations["fetchData"] as? [[Any]] ?? []
        let wasCalled = calls.contains { args in
            args.first as? String == id
        }
        XCTAssertTrue(wasCalled, "fetchData not called with id: \(id)", file: file, line: line)
    }
}
```

### 3. Test Data Builders
```swift
extension User {
    static func makeStub(
        id: UUID = UUID(),
        name: String = "Test User",
        email: String = "test@example.com"
    ) -> User {
        User(id: id, name: name, email: email)
    }
}

extension NutritionData {
    static let stub = NutritionData(
        calories: 500,
        protein: 30,
        carbs: 50,
        fat: 20
    )
    
    static func makeStub(calories: Double = 500) -> NutritionData {
        NutritionData(
            calories: calories,
            protein: calories * 0.06,
            carbs: calories * 0.1,
            fat: calories * 0.04
        )
    }
}
```

### 4. Async Testing Utilities
```swift
extension XCTestCase {
    /// Wait for async condition with timeout
    func waitForCondition(
        timeout: TimeInterval = 2.0,
        condition: () async -> Bool
    ) async throws {
        let startTime = Date()
        while !(await condition()) {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timeout waiting for condition")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
    
    /// Assert async throwing expression
    func assertAsyncThrows<T>(
        _ expression: () async throws -> T,
        _ errorHandler: (Error) -> Void = { _ in }
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error but none was thrown")
        } catch {
            errorHandler(error)
        }
    }
}
```

## ✅ Test Quality Checklist

### Every Test Must:
- [ ] Follow AAA pattern (Arrange, Act, Assert)
- [ ] Test one behavior only
- [ ] Have descriptive name indicating scenario and expected result
- [ ] Clean up resources in tearDown
- [ ] Use mocks for external dependencies
- [ ] Run in isolation (no shared state)
- [ ] Complete in reasonable time (<1s for unit tests)

### Every Mock Must:
- [ ] Implement MockProtocol
- [ ] Be thread-safe (use mockLock)
- [ ] Provide reset() method
- [ ] Have verification helpers for common assertions
- [ ] Support both success and failure scenarios
- [ ] Document any special behavior

## 🚫 Anti-Patterns to Avoid

### 1. Test Pollution
```swift
// ❌ BAD: Shared state between tests
class BadTests: XCTestCase {
    static var sharedService = ServiceImplementation()  // Shared state!
    
    func test_one() {
        Self.sharedService.configure(apiKey: "test")  // Pollutes other tests
    }
}

// ✅ GOOD: Isolated tests
class GoodTests: XCTestCase {
    var service: ServiceProtocol!
    
    override func tearDown() {
        service = nil  // Clean slate for each test
        super.tearDown()
    }
}
```

### 2. Testing Implementation Details
```swift
// ❌ BAD: Testing private methods
func test_privateHelperMethod() {
    // Don't test private methods directly
}

// ✅ GOOD: Test public behavior
func test_publicAPI_producesExpectedResult() {
    // Test through public interface
}
```

### 3. Overly Complex Mocks
```swift
// ❌ BAD: Mock with business logic
class BadMock: ServiceProtocol {
    func process(data: Data) -> Result {
        // 50 lines of processing logic
        // This tests the mock, not the SUT!
    }
}

// ✅ GOOD: Simple stubbed responses
class GoodMock: ServiceProtocol {
    func process(data: Data) -> Result {
        stubbedResult(for: "process", default: .success)
    }
}
```

## 📊 Coverage Standards

### Minimum Requirements
- New code: 90% coverage
- Modified code: 80% coverage  
- Critical paths: 100% coverage
- Overall project: 80% coverage

### What Counts as "Covered"
- Line coverage: Code was executed
- Branch coverage: All conditions tested
- Error paths: Failure scenarios tested
- Edge cases: Boundary conditions tested

### What to Exclude from Coverage
- Mock implementations
- Test utilities
- SwiftUI previews
- Generated code

## 🔍 Test Review Criteria

### Code Review Checklist
- [ ] Tests follow naming conventions
- [ ] AAA pattern is clear
- [ ] Mocks are properly reset
- [ ] No test pollution risk
- [ ] Async code properly handled
- [ ] Error scenarios tested
- [ ] Performance is reasonable
- [ ] Documentation is adequate

### PR Requirements
- [ ] All new code has tests
- [ ] Tests pass locally
- [ ] No decrease in coverage
- [ ] No flaky tests introduced
- [ ] Test names are descriptive
- [ ] Mocks follow standards

## 🎯 Quick Reference

### Create New Test File
```bash
# Copy template
cp Docs/TestAnalysis/Templates/TestTemplate.swift AirFit/AirFitTests/NewTests.swift

# Update project.yml
echo "      - AirFit/AirFitTests/NewTests.swift" >> project.yml

# Regenerate project
xcodegen generate
```

### Run Specific Tests
```bash
# Single test method
xcodebuild test -scheme "AirFit" -only-testing:"AirFitTests/ClassName/testMethodName"

# Single test class
xcodebuild test -scheme "AirFit" -only-testing:"AirFitTests/ClassName"

# With parallel execution
xcodebuild test -scheme "AirFit" -parallel-testing-enabled YES
```

### Debug Flaky Tests
1. Run test 10 times in loop
2. Check for shared state
3. Add delays to find race conditions
4. Use Thread Sanitizer
5. Review async timing

Remember: **Consistency is more important than perfection**. Follow these standards for all new tests and gradually update existing tests during refactoring.