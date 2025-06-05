# AI Service File Categorization

## Summary
The codebase has multiple AI service implementations that represent different stages of evolution:
1. Old Combine-based implementations using `AIAPIServiceProtocol` 
2. New async/await implementations using `AIServiceProtocol`
3. Bridge implementations attempting to connect both

## DEPRECATED - Files to Exclude from Build

### 1. **AIAPIService.swift**
- **Status**: DEPRECATED
- **Reason**: Bridge implementation between old `AIAPIServiceProtocol` (Combine-based) and new LLM infrastructure
- **Indicators**:
  - Uses Combine with `AnyPublisher`
  - Implements deprecated `AIAPIServiceProtocol`
  - Has TODO comment: "Implement proper streaming support in Phase 5"
  - Returns empty publisher to avoid concurrency issues
- **Dependencies**: Still used by `CoachEngine.swift` and `WorkoutAnalysisEngine.swift`

### 2. **UnifiedAIService.swift**
- **Status**: DEPRECATED
- **Reason**: Another bridge attempt that mixes old and new patterns
- **Indicators**:
  - Implements deprecated `AIAPIServiceProtocol`
  - Uses Combine alongside AsyncThrowingStream
  - Comment states "combines the best of both implementations" indicating transitional code
  - Not referenced in production code

### 3. **MockAIAPIService.swift** (in Services/MockServices/)
- **Status**: DEPRECATED
- **Reason**: Mock for deprecated protocol
- **Indicators**:
  - Implements deprecated `AIAPIServiceProtocol`
  - Uses Combine patterns

## NEEDS_FIX - Current Files with Issues

### 1. **CoachEngine.swift**
- **Status**: NEEDS_FIX
- **Issue**: Uses deprecated `AIAPIServiceProtocol`
- **Fix Required**: Update to use `AIServiceProtocol` instead
- **Line 129**: `private let aiService: AIAPIServiceProtocol`
- **Impact**: Core functionality currently depends on deprecated service

### 2. **WorkoutAnalysisEngine.swift**
- **Status**: NEEDS_FIX
- **Issue**: Uses deprecated `AIAPIServiceProtocol`
- **Fix Required**: Update to use `AIServiceProtocol` instead

### 3. **EnhancedAIAPIService.swift**
- **Status**: NEEDS_FIX
- **Issue**: Incorrectly implements `AIServiceProtocol` but still uses Combine internally
- **Indicators**:
  - Implements modern `AIServiceProtocol`
  - But still uses Combine and NetworkManagementProtocol
  - Referenced in `ServiceBootstrapper` but with wrong interface
- **Fix Required**: Either fully modernize or replace with ProductionAIService

## CURRENT - Working Implementations

### 1. **ProductionAIService.swift**
- **Status**: CURRENT
- **Reason**: Proper implementation of new `AIServiceProtocol`
- **Indicators**:
  - Uses `AsyncThrowingStream` for streaming
  - Implements modern `AIServiceProtocol`
  - Used by `DependencyContainer` as the main AI service
  - Has proper error handling and fallback to SimpleMockAIService

### 2. **SimpleMockAIService.swift**
- **Status**: CURRENT
- **Reason**: Mock implementation for new protocol
- **Indicators**:
  - Implements modern `AIServiceProtocol`
  - Used as fallback in DependencyContainer
  - Provides test responses without external dependencies

### 3. **LLMOrchestrator.swift**
- **Status**: CURRENT
- **Reason**: Core LLM management service
- **Indicators**:
  - Modern async/await implementation
  - Manages multiple LLM providers
  - Used by ProductionAIService

### 4. **LLM Provider Implementations** (AnthropicProvider, OpenAIProvider, GeminiProvider)
- **Status**: CURRENT
- **Reason**: Concrete provider implementations
- **Indicators**:
  - Implement modern `LLMProvider` protocol
  - Use `AsyncThrowingStream` for streaming
  - Properly handle API interactions

## Protocol Status

### DEPRECATED Protocols
- **AIAPIServiceProtocol**: Uses Combine, should be removed
- **AIAPIRequestProtocol**: Old request format

### CURRENT Protocols  
- **AIServiceProtocol**: Modern async/await interface
- **LLMProvider**: Provider abstraction for LLM services

## Migration Path

1. **Update CoachEngine and WorkoutAnalysisEngine**:
   - Change from `AIAPIServiceProtocol` to `AIServiceProtocol`
   - Update method calls from `getStreamingResponse()` to `sendRequest()`
   - Handle AsyncThrowingStream instead of Combine publishers

2. **Remove deprecated files**:
   - AIAPIService.swift
   - UnifiedAIService.swift
   - MockAIAPIService.swift (in MockServices)
   - AIAPIServiceProtocol.swift

3. **Fix ServiceBootstrapper**:
   - Remove EnhancedAIAPIService
   - Use ProductionAIService instead

4. **Update tests**:
   - Replace MockAIAPIService with MockAIService
   - Update test expectations for new protocol