# Error Handling Migration Guide

**Created**: 2025-01-08  
**Purpose**: Step-by-step guide to migrate services from custom errors to AppError  
**Time Estimate**: 5-10 minutes per service

## Quick Start

If your service throws custom errors, follow these 5 steps:

1. **Check** if your error has a converter in `AppError+Conversion.swift`
2. **Add** converter if missing
3. **Update** all `throw` statements to use `AppError.from()`
4. **Test** error propagation
5. **Verify** error messages in UI

## Step-by-Step Migration

### Step 1: Identify Current Error Usage

Run these commands to find what errors your service throws:

```bash
# Find all throw statements in your service
grep -n "throw" YourService.swift

# Find custom error definitions
grep -n "enum.*Error" YourService.swift
grep -n "struct.*Error" YourService.swift
```

### Step 2: Check for Existing Converters

Open `Core/Enums/AppError+Conversion.swift` and search for your error type:
- If found ✅ → Skip to Step 3
- If not found ❌ → Continue to Step 2a

#### Step 2a: Add Converter for Your Error Type

Add a new conversion method:

```swift
// MARK: - YourModule Errors

/// Creates AppError from YourCustomError
static func from(_ customError: YourCustomError) -> AppError {
    switch customError {
    case .specificCase1:
        // Map to existing AppError case if appropriate
        return .networkError(underlying: NSError(domain: "YourModule", code: 0, userInfo: [NSLocalizedDescriptionKey: "Specific error message"]))
    
    case .specificCase2(let detail):
        // Use validationError for input-related errors
        return .validationError(message: "Invalid input: \(detail)")
    
    case .authorizationError:
        // Map to specific AppError cases when available
        return .unauthorized
    
    default:
        // Fallback with context
        return .unknown(message: "YourModule error: \(customError.localizedDescription)")
    }
}
```

#### Step 2b: Update Result Extension

Add your error type to the Result extension at the bottom of the file:

```swift
extension Result where Failure == Error {
    func mapToAppError() -> Result<Success, AppError> {
        mapError { error in
            // ... existing checks ...
            
            // Add your error type
            } else if let yourError = error as? YourCustomError {
                return AppError.from(yourError)
            
            // ... rest of checks ...
        }
    }
}
```

### Step 3: Update Throw Statements

Find and replace error throwing patterns:

#### Pattern 1: Direct Throws
```swift
// ❌ BEFORE
throw YourCustomError.notConfigured

// ✅ AFTER  
throw AppError.from(YourCustomError.notConfigured)
```

#### Pattern 2: Guard Statements
```swift
// ❌ BEFORE
guard isValid else {
    throw YourCustomError.invalidInput("Missing required field")
}

// ✅ AFTER
guard isValid else {
    throw AppError.from(YourCustomError.invalidInput("Missing required field"))
}
```

#### Pattern 3: Do-Catch Blocks
```swift
// ❌ BEFORE
do {
    try await someOperation()
} catch {
    throw YourCustomError.operationFailed(error)
}

// ✅ AFTER
do {
    try await someOperation()
} catch {
    // Convert to AppError
    if let customError = error as? YourCustomError {
        throw AppError.from(customError)
    } else {
        throw AppError.networkError(underlying: error)
    }
}
```

#### Pattern 4: Rethrowing Functions
```swift
// ❌ BEFORE
func processData() throws {
    try riskyOperation()
}

// ✅ AFTER
func processData() throws {
    do {
        try riskyOperation()
    } catch {
        throw error.asAppError
    }
}
```

### Step 4: Update Error Handling

#### In Services
```swift
// Service method that ViewModels call
func fetchUserData() async throws -> UserData {
    do {
        // Your implementation
        let data = try await networkCall()
        return data
    } catch let error as NetworkError {
        // Convert known errors
        throw AppError.from(error)
    } catch {
        // Catch-all conversion
        throw error.asAppError
    }
}
```

#### In ViewModels
```swift
@MainActor
class MyViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var showError = false
    
    func loadData() async {
        do {
            let data = try await service.fetchUserData()
            // Handle success
        } catch let error as AppError {
            // AppError is expected - show to user
            errorMessage = error.errorDescription
            showError = true
            
            // Log for debugging
            AppLogger.error("Failed to load data", error: error, category: .ui)
        } catch {
            // This shouldn't happen if services follow standards
            errorMessage = "An unexpected error occurred"
            showError = true
            AppLogger.error("Non-AppError in ViewModel", error: error, category: .ui)
        }
    }
}
```

### Step 5: Test Error Handling

#### Unit Test Example
```swift
func testServiceConvertsErrorsToAppError() async {
    // Given
    let service = MyService()
    mockNetworkClient.shouldFail = true
    
    // When/Then
    do {
        _ = try await service.fetchData()
        XCTFail("Expected error")
    } catch let error as AppError {
        // Verify we get AppError, not ServiceError
        switch error {
        case .networkError:
            XCTAssertTrue(true) // Expected
        default:
            XCTFail("Expected network error, got \(error)")
        }
    } catch {
        XCTFail("Expected AppError, got \(type(of: error))")
    }
}
```

#### UI Test Example
```swift
func testErrorDisplaysUserFriendlyMessage() {
    // Given
    let viewModel = MyViewModel(service: MockFailingService())
    
    // When
    await viewModel.performAction()
    
    // Then
    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertFalse(viewModel.errorMessage!.contains("Error("))
    XCTAssertTrue(viewModel.errorMessage!.count > 10) // Not just "Error"
}
```

## Common Migration Scenarios

### Scenario 1: Service with Multiple Error Types

If your service uses multiple error types:

```swift
// Service might throw:
// - NetworkError
// - DatabaseError  
// - ValidationError

// Solution: Convert at the service boundary
func publicMethod() async throws -> Result {
    do {
        let networkData = try await networkOperation()
        let dbResult = try await databaseOperation()
        return try validate(dbResult)
    } catch {
        // Single conversion point
        throw error.asAppError
    }
}
```

### Scenario 2: Generic String Errors

Replace string-based errors:

```swift
// ❌ BEFORE
throw NSError(domain: "MyService", code: 0, userInfo: [
    NSLocalizedDescriptionKey: "Something went wrong"
])

// ✅ AFTER
throw AppError.unknown(message: "Failed to process request: specific reason")
```

### Scenario 3: Silent Error Swallowing

Don't hide errors:

```swift
// ❌ BEFORE
do {
    try await riskyOperation()
} catch {
    // Silently fail
    return defaultValue
}

// ✅ AFTER
do {
    try await riskyOperation()
} catch {
    // Log for debugging
    AppLogger.error("Operation failed, using default", error: error)
    
    // Still throw if it's important
    throw AppError.from(ServiceError.operationFailed)
    
    // OR return default with logging
    return defaultValue
}
```

## Migration Checklist

For each service being migrated:

- [ ] Run grep to find all `throw` statements
- [ ] Identify custom error types used
- [ ] Check `AppError+Conversion.swift` for existing converters
- [ ] Add missing converters with meaningful mappings
- [ ] Update Result extension if needed
- [ ] Replace all throw statements with `AppError.from()`
- [ ] Update error handling in catch blocks
- [ ] Test error propagation with unit tests
- [ ] Verify error messages in UI are user-friendly
- [ ] Update documentation if service has special error cases

## Quick Reference

### Import Required
```swift
import Foundation // AppError is in Core
```

### Common Conversions
```swift
// ServiceError
throw AppError.from(ServiceError.notConfigured)

// Network errors
throw AppError.networkError(underlying: error)

// Validation
throw AppError.validationError(message: "Specific issue")

// Generic with context
throw AppError.unknown(message: "Context: \(error)")

// Using extension
throw error.asAppError
```

### Error Properties to Use
```swift
// In ViewModels
error.errorDescription      // User-facing message
error.recoverySuggestion   // How to fix
error.isRecoverable        // Can user fix it?
error.shouldRetry          // Should we retry?
error.retryDelay          // How long to wait?
```

## Verification

After migration, verify:

1. **Build succeeds** without warnings
2. **Tests pass** with proper error types
3. **UI shows** friendly error messages
4. **Logs contain** technical details
5. **No ServiceError** reaches ViewModels

## Getting Help

- Check `ERROR_HANDLING_STANDARDS.md` for patterns
- Look at migrated services for examples:
  - `HealthKitManager` - Complex error conversion
  - `AIService` - ServiceError to AppError
  - `NetworkManager` - Network error handling
- Ask in #ios-dev if you need help with specific conversions

## Time-Saving Tips

1. Use **Find & Replace** with regex:
   - Find: `throw (\w+Error\.\w+)`
   - Replace: `throw AppError.from($1)`

2. Use **Xcode's Refactor** for enum case renaming

3. Create a **code snippet** for common patterns:
   ```swift
   do {
       try await <#operation#>()
   } catch {
       throw error.asAppError
   }
   ```

4. Run **tests frequently** to catch issues early

5. **Commit after each service** for easy rollback

Remember: The goal is user-friendly errors with preserved technical context. When in doubt, use `AppError.unknown(message:)` with descriptive context.