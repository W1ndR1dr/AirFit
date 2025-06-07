# Error Handling Guide

## Overview
AirFit uses a standardized error handling system centered around `AppError` as the single source of truth for all application errors.

## Core Principles

1. **Single Error Type**: All errors should be converted to `AppError`
2. **User-Friendly Messages**: Every error must have a clear user-facing message
3. **Recovery Suggestions**: Provide actionable recovery steps when possible
4. **Consistent UI**: Use standardized error presentation across the app

## Error Type Hierarchy

```
AppError (Core/Enums/AppError.swift)
├── networkError(underlying: Error)
├── decodingError(underlying: Error)
├── validationError(message: String)
├── unauthorized
├── serverError(code: Int, message: String?)
├── unknown(message: String)
├── healthKitNotAuthorized
├── cameraNotAuthorized
├── userNotFound
└── unsupportedProvider
```

## Implementation Patterns

### 1. ViewModels

All ViewModels should adopt the `ErrorHandling` protocol:

```swift
@MainActor
@Observable
final class ExampleViewModel: ErrorHandling {
    // Required by ErrorHandling
    var error: AppError?
    var isShowingError = false
    
    func loadData() async {
        // Use withErrorHandling for automatic error conversion
        await withErrorHandling {
            let data = try await service.fetchData()
            self.processData(data)
        }
    }
}
```

### 2. Services

Services should throw specific errors that get converted to AppError:

```swift
actor ExampleService {
    func fetchData() async throws -> Data {
        do {
            return try await networkClient.get(endpoint)
        } catch {
            // Let the error propagate - it will be converted at the UI layer
            throw error
        }
    }
}
```

### 3. Views

Use the `errorAlert` modifier for consistent error presentation:

```swift
struct ExampleView: View {
    @State private var viewModel = ExampleViewModel()
    
    var body: some View {
        ContentView()
            .errorAlert(
                error: $viewModel.error,
                isPresented: $viewModel.isShowingError
            )
    }
}
```

## Error Conversion

The system automatically converts domain-specific errors to AppError:

- `AIError` → `AppError`
- `NetworkError` → `AppError`
- `ServiceError` → `AppError`
- `WorkoutError` → `AppError`
- `KeychainError` → `AppError`
- `CoachEngineError` → `AppError`
- `DirectAIError` → `AppError`

## Best Practices

### DO:
- ✅ Use `AppError` for all user-facing errors
- ✅ Provide meaningful error messages
- ✅ Include recovery suggestions when possible
- ✅ Use `withErrorHandling` for async operations
- ✅ Log errors with appropriate context

### DON'T:
- ❌ Create new error types without extending AppError
- ❌ Show technical error messages to users
- ❌ Silently swallow errors
- ❌ Use print() for error logging - use AppLogger

## Migration Guide

### Old Pattern:
```swift
do {
    let result = try await service.doWork()
} catch {
    print("Error: \(error)")
    self.errorMessage = error.localizedDescription
}
```

### New Pattern:
```swift
await withErrorHandling {
    let result = try await service.doWork()
    self.processResult(result)
}
```

## Error Properties

AppError includes helpful computed properties:

- `isRecoverable`: Whether the user can take action to fix it
- `shouldRetry`: Whether automatic retry is appropriate
- `retryDelay`: Suggested delay before retry (if applicable)

## Testing

When testing error handling:

```swift
func testErrorHandling() async {
    // Arrange
    let mockService = MockService()
    mockService.shouldThrow = NetworkError.noData
    
    // Act
    await viewModel.loadData()
    
    // Assert
    XCTAssertNotNil(viewModel.error)
    XCTAssertEqual(viewModel.error?.errorDescription, "No data received")
}
```

## Common Scenarios

### Network Timeout
```swift
throw AppError.networkError(underlying: URLError(.timedOut))
```

### Invalid API Response
```swift
throw AppError.decodingError(underlying: DecodingError.dataCorrupted(...))
```

### User Input Validation
```swift
throw AppError.validationError(message: "Please enter a valid email address")
```

### API Rate Limiting
```swift
throw AppError.serverError(code: 429, message: "Too many requests. Please try again later.")
```

## Future Improvements

- [ ] Add error analytics tracking
- [ ] Implement retry policies
- [ ] Add offline error queueing
- [ ] Create error recovery flows