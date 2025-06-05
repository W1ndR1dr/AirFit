# Phase 3.2: Error Handling Standardization TODO

## ✅ Completed
1. Created `AppError+Extensions.swift` with centralized error conversion
2. Created `ErrorHandling.swift` protocol for ViewModels
3. Created `ERROR_HANDLING_GUIDE.md` documentation
4. Started updating `DashboardViewModel` as example

## 🚧 Build Issues to Fix
1. Fix error enum case matching in `AppError+Extensions.swift`:
   - Check actual cases in `ServiceError`, `WorkoutError` enums
   - Update conversion functions to match actual cases

## 📋 Remaining Work

### 1. Fix AppError+Extensions.swift
- [ ] Verify actual error cases in each error enum
- [ ] Update conversion functions to match
- [ ] Ensure all error types are properly mapped

### 2. Update All ViewModels
ViewModels to update with ErrorHandling protocol:
- [ ] `DashboardViewModel` (partially done)
- [ ] `ChatViewModel`
- [ ] `OnboardingViewModel`
- [ ] `ConversationViewModel`
- [ ] `FoodTrackingViewModel`
- [ ] `WorkoutViewModel`
- [ ] `SettingsViewModel`

For each ViewModel:
1. Add `: ErrorHandling` to class declaration
2. Change `error: Error?` to `error: AppError?`
3. Add `var isShowingError = false`
4. Replace `catch { self.error = error }` with `catch { handleError(error) }`
5. Use `withErrorHandling { }` for async operations

### 3. Update Views
For each View using the ViewModel:
- [ ] Replace custom error alerts with `.errorAlert()` modifier
- [ ] Bind to `viewModel.error` and `viewModel.isShowingError`

### 4. Service Error Handling
- [ ] Add `ServiceErrorHandling` protocol to services
- [ ] Ensure services throw specific errors (not generic)
- [ ] Remove error conversion at service layer (let UI handle it)

### 5. Remove Duplicate Error Types
Error types to consolidate/remove:
- [ ] `CoachEngineError` - some cases duplicate AppError
- [ ] `ServiceError` - merge common cases into AppError
- [ ] Custom error strings - convert to AppError cases

### 6. Testing
- [ ] Update mock services to throw appropriate errors
- [ ] Add error handling tests for each ViewModel
- [ ] Test error conversion logic

## Example Migration

### Before:
```swift
do {
    let data = try await service.loadData()
    self.data = data
} catch {
    self.error = error
    self.errorMessage = error.localizedDescription
    AppLogger.error("Failed", error: error)
}
```

### After:
```swift
await withErrorHandling {
    let data = try await service.loadData()
    self.data = data
}
```

## Benefits
- Consistent error presentation across app
- Automatic error logging
- User-friendly error messages
- Recovery suggestions
- Retry capabilities
- Reduced boilerplate

## Next Steps
1. Fix build errors in AppError+Extensions.swift
2. Complete DashboardViewModel migration
3. Migrate one module at a time
4. Update tests as you go