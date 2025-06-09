# Service Error Analysis - AppError Migration

## Summary
Found 25 service files that throw errors. Many are already using AppError properly, but several need updates.

## Services Already Using AppError Correctly ✅
1. **AIService** - Uses `AppError.from(ServiceError.notConfigured)`
2. **HealthKitManager** - Uses `AppError.from(HealthKitError.*)`
3. **GoalService** - Uses `AppError.unknown(message:)`
4. **UserService** - Uses `AppError.userNotFound`
5. **WeatherService** - Uses `AppError.networkError(underlying:)`
6. **NutritionService** - Uses `AppError.unknown(message:)`
7. **PersonaService** - Uses `AppError.userNotFound`
8. **WorkoutService** - Uses `AppError.unknown(message:)`

## Services Needing AppError Updates 🔧

### High Priority (Direct custom errors)
1. **NetworkClient** (21 throws)
   - Throws: `NetworkError.*` (invalidResponse, httpError, decodingError, networkError, invalidURL)
   - Used by: Most ViewModels indirectly through other services
   
2. **LLMOrchestrator** (4 throws)
   - Throws: `LLMError.*` (unsupportedFeature, networkError, etc.)
   - Used by: AIService, ChatViewModel, OnboardingViewModel

3. **AIResponseParser** (3 throws)
   - Throws: `ServiceError.invalidResponse`
   - Used by: AIService

4. **RequestOptimizer** (6 throws)
   - Throws: `RequestOptimizerError.*` (offline, invalidResponse, rateLimited, httpError)
   - Used by: Network layer

5. **KeychainHelper** (7 throws)
   - Throws: `KeychainHelperError.*` (unhandledError, encodingError, itemNotFound, unexpectedItemData)
   - Used by: APIKeyManager, Settings

### Medium Priority (Provider-specific errors)
6. **GeminiProvider** (5 throws)
   - Throws: `LLMError.*`
   - Used by: LLMOrchestrator

7. **OpenAIProvider** (5 throws)
   - Throws: `LLMError.*`
   - Used by: LLMOrchestrator

8. **AnthropicProvider** (5 throws)
   - Throws: `LLMError.*`
   - Used by: LLMOrchestrator

### Lower Priority (Module-specific errors)
9. **VoiceInputManager** (5 throws)
   - Throws: `VoiceInputError.*` (notAuthorized, whisperNotReady)
   - Used by: FoodTrackingViewModel, ChatViewModel

10. **WhisperModelManager** (3 throws)
    - Throws: `ModelError.*` (modelNotFound, insufficientStorage, downloadFailed)
    - Used by: VoiceInputManager

11. **ExerciseDatabase** (1 throw)
    - Throws: `ExerciseDatabaseError.seedDataNotFound`
    - Used by: WorkoutService

12. **NetworkManager** (6 throws)
    - Throws: `ServiceError.*` (networkUnavailable, invalidResponse, unknown)
    - Used by: Various services

13. **APIKeyManager** (2 throws)
    - Throws: `ServiceError.*` (invalidResponse, authenticationFailed)
    - Used by: Settings, AI services

14. **BiometricAuthManager** (2 throws)
    - Throws: `BiometricError.*` (notAvailable, fromLAError)
    - Used by: SettingsViewModel

15. **ConversationFlowManager** (6 throws)
    - Throws: `ConversationError.*`
    - Used by: OnboardingViewModel

16. **OnboardingOrchestrator** (5 throws)
    - Throws: `OnboardingOrchestratorError.*`
    - Used by: OnboardingCoordinator

17. **OnboardingRecovery** (2 throws)
    - Throws: `OnboardingError.*`, `RecoveryError.*`
    - Used by: OnboardingViewModel

18. **OnboardingService** (4 throws)
    - Throws: `OnboardingError.*`
    - Used by: OnboardingViewModel

19. **HealthKitDataFetcher** (2 throws)
    - Throws: `HealthKitManager.HealthKitError.invalidData`
    - Used by: HealthKitManager

20. **HealthKitSleepAnalyzer** (1 throw)
    - Throws: `HealthKitManager.HealthKitError.invalidData`
    - Used by: HealthKitManager

21. **OfflineAIService** (4 throws)
    - Throws: `AIError.unauthorized`
    - Used by: Test/Demo mode

## Error Types to Convert

### Custom Error Enums Found:
1. **NetworkError** - in NetworkClientProtocol.swift
2. **LLMError** - in LLMProvider.swift
3. **ServiceError** - in ServiceModels.swift (some uses need AppError conversion)
4. **KeychainHelperError** - in KeychainHelper.swift
5. **RequestOptimizerError** - in RequestOptimizer.swift
6. **VoiceInputError** - in VoiceInputState.swift
7. **ModelError** - in WhisperModelManager.swift
8. **ExerciseDatabaseError** - in ExerciseDatabase.swift
9. **BiometricError** - in BiometricAuthManager.swift
10. **ConversationError** - in ConversationFlowManager.swift
11. **OnboardingOrchestratorError** - in OnboardingOrchestrator.swift
12. **OnboardingError** - in OnboardingModels.swift
13. **RecoveryError** - in OnboardingRecovery.swift
14. **AIError** - in AIModels.swift
15. **HealthKitError** - in HealthKitManager.swift (already has AppError conversion)

## Prioritized Update Plan

### Phase 1: Core Infrastructure (Highest Impact)
1. **NetworkClient** - Convert NetworkError → AppError
2. **LLMOrchestrator** - Convert LLMError → AppError
3. **AIResponseParser** - Convert ServiceError → AppError
4. **RequestOptimizer** - Convert RequestOptimizerError → AppError
5. **KeychainHelper** - Convert KeychainHelperError → AppError

### Phase 2: AI Providers
6. **GeminiProvider** - Convert LLMError → AppError
7. **OpenAIProvider** - Convert LLMError → AppError
8. **AnthropicProvider** - Convert LLMError → AppError

### Phase 3: Feature Services
9. **VoiceInputManager** - Convert VoiceInputError → AppError
10. **WhisperModelManager** - Convert ModelError → AppError
11. **NetworkManager** - Convert ServiceError usage → AppError
12. **APIKeyManager** - Convert ServiceError usage → AppError

### Phase 4: Module-Specific Services
13. **ConversationFlowManager** - Convert ConversationError → AppError
14. **OnboardingOrchestrator** - Convert OnboardingOrchestratorError → AppError
15. **OnboardingRecovery** - Convert custom errors → AppError
16. **OnboardingService** - Convert OnboardingError → AppError
17. **BiometricAuthManager** - Convert BiometricError → AppError

### Phase 5: Low Priority
18. **ExerciseDatabase** - Convert ExerciseDatabaseError → AppError
19. **HealthKitDataFetcher** - Already uses HealthKitError (which converts to AppError)
20. **HealthKitSleepAnalyzer** - Already uses HealthKitError (which converts to AppError)
21. **OfflineAIService** - Convert AIError → AppError

## Implementation Strategy

For each service:
1. Check if custom error enum has unique error cases that need preserving
2. Add AppError cases if needed (or use existing ones)
3. Update throw statements to use `AppError.from()` or direct AppError cases
4. Update error handling in calling code if necessary
5. Consider keeping the original error as associated data for debugging

Example conversion patterns:
```swift
// Before
throw NetworkError.invalidResponse

// After
throw AppError.networkError(underlying: NetworkError.invalidResponse)
// or
throw AppError.invalidResponse("Network response was invalid")
```