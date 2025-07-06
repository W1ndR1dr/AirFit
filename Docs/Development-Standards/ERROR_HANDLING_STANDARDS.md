# Error Handling Standards

**Created**: 2025-01-08  
**Status**: Active Standard  
**Focus**: Error Handling Enhancement

## Overview

This document defines the error handling standards for the AirFit codebase. We use a centralized `AppError` system with comprehensive conversion utilities to ensure consistent error handling across all layers.

## Core Principles

1. **User-Facing Clarity**: All errors that reach the UI must be `AppError` instances with clear, actionable messages
2. **Technical Detail Preservation**: Convert technical errors to `AppError` while preserving context
3. **Recovery Guidance**: Every error should suggest how users can resolve the issue
4. **Type Safety**: Use Swift's type system to ensure proper error handling

## Error Type Hierarchy

### 1. AppError (User-Facing)
Primary error type for all user-facing operations:
```swift
public enum AppError: LocalizedError, Sendable {
    case networkError(underlying: Error)
    case decodingError(underlying: Error)
    case validationError(message: String)
    case unauthorized
    case serverError(code: Int, message: String?)
    case unknown(message: String)
    case healthKitNotAuthorized
    case cameraNotAuthorized
    case userNotFound
    case unsupportedProvider
}
```

**Use Cases**:
- ViewModels throwing errors to Views
- Service methods called directly by ViewModels
- Any error that will be displayed to users

### 2. ServiceError (Technical)
Internal service coordination errors:
```swift
enum ServiceError: LocalizedError {
    case notConfigured
    case invalidConfiguration(detail: String)
    case networkUnavailable
    case authenticationFailed
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case invalidResponse(detail: String)
    case streamingError(detail: String)
    case timeout
    case cancelled
    case providerError(code: String, message: String)
    case unknown(Error)
}
```

**Use Cases**:
- Inter-service communication
- Technical failures that need specific handling
- Errors that will be converted to AppError before reaching UI

### 3. Module-Specific Errors
Specialized errors for complex domain logic:
- `HealthKitError` - HealthKit-specific failures
- `LLMError` - AI provider errors
- `OnboardingError` - Onboarding flow errors
- `FoodTrackingError` - Food tracking errors
- etc.

**Rule**: All module errors MUST have conversion methods to `AppError`

## Implementation Patterns

### Pattern 1: Service Throwing AppError Directly
When a service method is called directly by ViewModels:

```swift
// ✅ CORRECT - Service throws AppError
func saveWorkout(_ workout: Workout) async throws {
    guard isConfigured else {
        throw AppError.from(ServiceError.notConfigured)
    }
    
    do {
        try await healthKitManager.save(workout)
    } catch {
        // Convert any error to AppError
        throw error.asAppError() // Uses Result extension
    }
}
```

### Pattern 2: Converting Custom Errors
When working with module-specific errors:

```swift
// ✅ CORRECT - Convert at throw site
func fetchHealthData() async throws -> HealthData {
    do {
        return try await performHealthQuery()
    } catch let healthError as HealthKitError {
        throw AppError.from(healthError)
    } catch {
        throw AppError.networkError(underlying: error)
    }
}
```

### Pattern 3: Error Propagation in ViewModels
ViewModels should always receive AppError:

```swift
@MainActor
class WorkoutViewModel: ObservableObject {
    func saveWorkout() async {
        do {
            try await workoutService.save(currentWorkout)
            // Success handling
        } catch let error as AppError {
            // error is already AppError, display to user
            self.errorMessage = error.localizedDescription
            self.showError = true
        } catch {
            // This should never happen if services follow standards
            self.errorMessage = "An unexpected error occurred"
            AppLogger.error("Non-AppError reached ViewModel", error: error)
        }
    }
}
```

### Pattern 4: Using Result Extension
For functional error handling:

```swift
// ✅ CORRECT - Use mapToAppError() extension
func processData() async -> Result<ProcessedData, AppError> {
    let result = await fetchRawData() // Returns Result<Data, Error>
    return result
        .mapToAppError() // Converts any Error to AppError
        .flatMap { data in
            // Process data
        }
}
```

## Conversion Infrastructure

### AppError+Conversion.swift
Provides `from()` methods for all error types:
```swift
extension AppError {
    static func from(_ serviceError: ServiceError) -> AppError
    static func from(_ healthKitError: HealthKitManager.HealthKitError) -> AppError
    static func from(_ llmError: LLMError) -> AppError
    // ... 20+ more conversions
}
```

### Result Extension
Automatic error mapping:
```swift
extension Result where Failure == Error {
    func mapToAppError() -> Result<Success, AppError> {
        mapError { error in
            // Automatically converts any known error type to AppError
            if let appError = error as? AppError {
                return appError
            }
            // ... checks all known error types
            return AppError.networkError(underlying: error)
        }
    }
}
```

### Error Extension
Convenience method for quick conversion:
```swift
extension Error {
    var asAppError: AppError {
        Result<Void, Error>.failure(self).mapToAppError().error!
    }
}
```

## Best Practices

### DO ✅

1. **Throw AppError from services** when called by ViewModels:
   ```swift
   throw AppError.from(ServiceError.notConfigured)
   ```

2. **Use specific AppError cases** when available:
   ```swift
   throw AppError.healthKitNotAuthorized // Not .unknown("HealthKit not authorized")
   ```

3. **Preserve error context** in conversions:
   ```swift
   case .queryFailed(let error):
       return .unknown(message: "Query failed: \(error.localizedDescription)")
   ```

4. **Add recovery suggestions** for custom errors:
   ```swift
   var recoverySuggestion: String? {
       switch self {
       case .networkError:
           return "Check your internet connection"
       }
   }
   ```

5. **Log errors with context** before converting:
   ```swift
   AppLogger.error("HealthKit query failed", error: error, category: .health)
   throw AppError.from(healthKitError)
   ```

### Missing Data Patterns

When HealthKit or other data sources return nil:

1. **Services should return nil** (don't fabricate data):
   ```swift
   func fetchBodyMetrics() async throws -> (weight: Double?, height: Double?) {
       // Return actual values or nil - don't guess
       return (healthKit.weight, healthKit.height)
   }
   ```

2. **ViewModels handle display defaults**:
   ```swift
   // ViewModel decides what to show users
   let displayWeight = bodyMetrics.weight ?? "Add weight in Health app"
   ```

3. **Calculations should validate inputs**:
   ```swift
   func calculateBMR(weight: Double?, height: Double?) throws -> Double {
       guard let weight = weight, let height = height else {
           throw AppError.validationError(message: "Height and weight required for BMR calculation")
       }
       return // ... actual calculation
   }
   ```

### DON'T ❌

1. **Don't throw generic errors**:
   ```swift
   // ❌ WRONG
   throw NSError(domain: "Service", code: 0, userInfo: nil)
   
   // ✅ CORRECT
   throw AppError.unknown(message: "Service configuration failed")
   ```

2. **Don't lose error information**:
   ```swift
   // ❌ WRONG
   } catch {
       throw AppError.unknown(message: "Failed")
   }
   
   // ✅ CORRECT
   } catch {
       throw AppError.unknown(message: "Failed: \(error.localizedDescription)")
   }
   ```

3. **Don't throw ServiceError from ViewModels**:
   ```swift
   // ❌ WRONG - ViewModel throwing ServiceError
   throw ServiceError.notConfigured
   
   // ✅ CORRECT - ViewModel receives AppError
   // (Service should have converted it)
   ```

4. **Don't create new error types** without conversion:
   ```swift
   // ❌ WRONG - No conversion method
   enum MyCustomError: Error {
       case somethingBad
   }
   
   // ✅ CORRECT - Add to AppError+Conversion.swift
   extension AppError {
       static func from(_ customError: MyCustomError) -> AppError
   }
   ```

## Testing Error Handling

### Unit Tests
```swift
func testServiceThrowsAppError() async throws {
    // Given
    let service = MyService()
    
    // When/Then
    do {
        try await service.performAction()
        XCTFail("Expected error")
    } catch let error as AppError {
        // Verify it's AppError, not custom type
        XCTAssertEqual(error, AppError.networkError)
    } catch {
        XCTFail("Expected AppError, got \(error)")
    }
}
```

### Integration Tests
```swift
func testErrorPropagationToUI() async throws {
    // Given
    let viewModel = MyViewModel(service: MockService())
    
    // When
    await viewModel.performAction()
    
    // Then
    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertTrue(viewModel.errorMessage!.contains("user-friendly"))
}
```

## Migration Checklist

When updating a service to follow error standards:

- [ ] Identify all `throw` statements
- [ ] Check if error type has AppError conversion
- [ ] Add conversion if missing (in AppError+Conversion.swift)
- [ ] Update throws to use `AppError.from()`
- [ ] Test error propagation to ViewModel
- [ ] Verify user-facing error messages
- [ ] Update any catch blocks to handle AppError

## Error Monitoring

Use AppLogger to track error patterns:
```swift
AppLogger.error("Service error occurred", 
    error: error,
    category: .services,
    metadata: [
        "service": serviceIdentifier,
        "operation": "fetchData"
    ]
)
```

## Future Enhancements

1. **Error Analytics**: Track most common errors
2. **Error Recovery Actions**: Add interactive recovery options
3. **Error Grouping**: Consolidate similar errors
4. **Offline Error Queue**: Store errors when offline for later reporting

## Conclusion

Consistent error handling improves:
- **User Experience**: Clear, actionable error messages
- **Debugging**: Preserved error context and stack traces
- **Maintenance**: Single point of error message management
- **Testing**: Predictable error types and behaviors

Follow these standards to ensure errors are helpful, not frustrating.