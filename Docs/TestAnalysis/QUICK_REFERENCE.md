# Test Suite Quick Reference

## 🚨 Critical Issues
1. **HealthKit writes untested** → See [HEALTHKIT_TESTING_PRIORITY.md](./HEALTHKIT_TESTING_PRIORITY.md)
2. **DI infrastructure untested** → Create DIContainerTests, DIBootstrapperTests
3. **20+ mocks without tests** → See "Services with Mocks but No Tests" below

## 🏃 Quick Fixes (Copy & Paste)

### Fix SettingsViewModelTests
```swift
// In SettingsViewModelTests.swift
// DELETE line 55 - it's a duplicate container declaration
// Keep only line 8: private var container: DIContainer!
```

### Enable Parallel Tests
```yaml
# In project.yml, add:
test:
  parallelizeBuildables: true
  buildConfiguration: Debug
  targets:
    - name: AirFitTests
      parallelizable: true
      randomExecutionOrder: true
```

### Fix FoodVoiceAdapterTests
```swift
// 1. Create VoiceInputProtocol.swift
protocol VoiceInputProtocol {
    var isTranscribing: Bool { get }
    func requestPermission(completion: @escaping (Bool) -> Void)
    func startTranscription(completion: @escaping (Result<String, Error>) -> Void)
    func stopTranscription()
}

// 2. Make VoiceInputManager conform
extension VoiceInputManager: VoiceInputProtocol {}

// 3. Update FoodVoiceAdapter
class FoodVoiceAdapter {
    private let voiceInput: VoiceInputProtocol // Changed from concrete type
    
    init(voiceInput: VoiceInputProtocol = VoiceInputManager.shared) {
        self.voiceInput = voiceInput
    }
}
```

## 📋 Services with Mocks but No Tests

Copy this list to track progress:
- [ ] `UserService` → UserServiceTests.swift
- [ ] `APIKeyManager` → APIKeyManagerTests.swift  
- [ ] `AICoachService` → AICoachServiceTests.swift
- [ ] `NutritionService` → NutritionServiceTests.swift
- [ ] `PersonaService` → PersonaServiceTests.swift
- [ ] `AnalyticsService` → AnalyticsServiceTests.swift
- [ ] `HealthKitService` → HealthKitServiceTests.swift
- [ ] `ChatHistoryManager` → ChatHistoryManagerTests.swift

## 🔧 Test Patterns (Copy & Adapt)

### Standard Test Setup
```swift
@MainActor
final class ExampleTests: XCTestCase {
    private var container: DIContainer!
    private var sut: ExampleClass!
    
    override func tearDown() {
        sut = nil
        container = nil
        super.tearDown()
    }
    
    private func setupTest() async throws {
        container = try await DITestHelper.createTestContainer()
        let factory = DIViewModelFactory(container: container)
        sut = try await factory.makeExample()
    }
    
    func test_methodName_scenario_expectedResult() async throws {
        // Arrange
        try await setupTest()
        
        // Act
        let result = try await sut.performAction()
        
        // Assert
        XCTAssertEqual(result, expectedValue)
    }
}
```

### Mock Template
```swift
final class MockNewService: NewServiceProtocol, MockProtocol {
    // MARK: - MockProtocol
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - Configuration
    var shouldThrowError = false
    var errorToThrow: Error = MockError.generic
    
    // MARK: - NewServiceProtocol
    func doSomething() async throws -> Result {
        recordInvocation("doSomething")
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return stubbedResult(for: "doSomething", default: Result.mock)
    }
}
```

## 🔍 Common Issues & Solutions

### Issue: "Cannot find DITestHelper"
```swift
// Add to test file:
@testable import AirFit
```

### Issue: "Test pollution detected"
```swift
// In tearDown:
override func tearDown() {
    // Reset all properties
    sut = nil
    mockService?.reset()
    container = nil
    super.tearDown()
}
```

### Issue: "Async test hanging"
```swift
// Add timeout:
func test_example() async throws {
    try await withTimeout(seconds: 5) {
        try await sut.performAction()
    }
}
```

## 📁 Key File Locations
```
AirFit/AirFitTests/
├── Mocks/Base/MockProtocol.swift      # Base mock pattern
├── TestUtils/DITestHelper.swift       # Test container setup
├── Services/TestHelpers.swift         # Async utilities
└── TEST_STRUCTURE.md                  # Testing guidelines
```

## 🏃 Running Tests
```bash
# Single test
xcodebuild test -scheme "AirFit" \
  -only-testing:"AirFitTests/ExampleTests/test_example"

# All tests with parallel execution
xcodebuild test -scheme "AirFit" \
  -parallel-testing-enabled YES \
  -maximum-parallel-test-workers 4

# Generate coverage report
xcodebuild test -scheme "AirFit" \
  -enableCodeCoverage YES
```

## 📊 Coverage Commands
```bash
# View coverage in terminal
xcrun llvm-cov report -instr-profile=path/to/Coverage.profdata \
  -arch=arm64 path/to/AirFit.app/AirFit

# Generate HTML report
xcrun llvm-cov show -instr-profile=path/to/Coverage.profdata \
  -arch=arm64 -format=html -output-dir=coverage_report \
  path/to/AirFit.app/AirFit
```

## ⚠️ Don't Forget
1. Run `xcodegen generate` after adding new test files
2. Add test files to `project.yml`
3. Follow naming convention: `{Class}Tests.swift`
4. Mock all external dependencies
5. Test both success and failure paths

---
**Need more detail?** See [TEST_STANDARDS.md](./TEST_STANDARDS.md) for comprehensive patterns.