# AI System Cleanup - Phase 3: Simplify Architecture
**Status**: Planning  
**Risk Level**: Medium-High
**Estimated Time**: 3 hours

## Objective
Remove over-engineered patterns while maintaining flexibility for future needs.

## Architectural Simplifications

### 1. Provider Abstraction
**Current**: Complex provider protocol with retry handlers, capabilities, etc.
**Proposed**: Minimal provider interface
```swift
protocol LLMProvider {
    func complete(_ prompt: String, model: String) async throws -> LLMResponse
    func stream(_ prompt: String, model: String) -> AsyncThrowingStream<String, Error>
}
```
**Keep**: Gemini as primary, OpenAI as backup
**Remove**: Complex retry logic (let it fail fast)

### 2. Remove ServiceProtocol
**Why**: This isn't a microservice architecture
**Impact**: Remove from 30+ services
**Keep**: Simple initialization
**Remove**: Health checks, configuration state, reset methods

### 3. Consolidate Test Services  
**Current**: DemoAIService, TestModeAIService, OfflineAIService
**Proposed**: Single AIService with mode enum
```swift
enum AIMode {
    case production
    case demo
    case test
    case offline
}
```

### 4. Direct Function Execution
**Current**: Function calls go through dispatcher → service → AI → service
**Proposed**: Function implementation directly in CoachEngine
**Benefit**: Remove entire abstraction layer, same functionality

## Critical Features to Preserve
- ✅ Persona synthesis (core differentiator)
- ✅ Context assembly (needed for personalization)
- ✅ Function calling (for complex operations)
- ✅ Streaming (for responsive UI)
- ✅ Multiple models (for quality/cost optimization)

## What We're NOT Changing
- ❌ PersonaSynthesizer - This is core IP
- ❌ CoachEngine - Central coordinator stays
- ❌ Context assembly - Needed for good responses
- ❌ SwiftData models - Data layer is fine

## Validation Plan
1. Create feature test checklist
2. Test each AI feature before/after
3. Verify persona consistency
4. Check streaming performance
5. Validate function calls

## Success Metrics
- Code reduction: ~8,000 lines
- Build time: -20%
- AI response latency: Same or better
- Developer onboarding: <30 minutes to understand AI flow

## Red Flags (Stop if these happen)
- Any user-facing feature breaks
- AI response quality degrades
- Persona consistency issues
- Function calls stop working

## Final Architecture
```
User Input → CoachEngine → AIService → GeminiProvider → Response
                ↓
         Function Execution (direct)
                ↓
         Database Updates
```

Simple. Direct. Maintainable.