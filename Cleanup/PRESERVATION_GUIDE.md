# Code Preservation Guide - DO NOT DELETE THESE!

This guide identifies the **high-quality, thoughtful implementations** that MUST be preserved during the cleanup process. These represent significant engineering effort and working solutions.

## 🛡️ Critical Implementations to Preserve

### 1. Persona Synthesis System (KEEP ALL)
**Location**: `/AirFit/Modules/AI/PersonaSynthesis/`
- ✅ **PersonaEngine.swift** - Optimized persona generation with caching
- ✅ **PersonaSynthesizer.swift** - Achieves <5s generation with parallel processing
- ✅ **OptimizedPersonaSynthesizer.swift** - Single LLM call, <3s generation
- ✅ **FallbackPersonaGenerator.swift** - Offline fallback capabilities
- ✅ **PreviewGenerator.swift** - Persona preview generation

**Why Keep**: This is the result of extensive optimization work. The system achieves <3s persona generation through careful prompt engineering and caching.

### 2. Modern AI Integration (KEEP ALL)
**Location**: `/AirFit/Services/AI/`
- ✅ **LLMOrchestrator.swift** - Multi-provider orchestration with fallback
- ✅ **ProductionAIService.swift** - Production-ready async/await implementation
- ✅ **AIServiceProtocol.swift** & **AIServiceProtocolExtensions.swift** - Modern protocol
- ✅ **LLMProviders/** - All provider implementations (Anthropic, OpenAI, Gemini)
- ✅ **AIResponseCache.swift** - Response caching for performance
- ✅ **AIRequestBuilder.swift** - Request construction utilities
- ✅ **AIResponseParser.swift** - Response parsing logic

**Why Keep**: This is the modern, production-ready AI system with proper error handling, caching, and multi-provider support.

### 3. Onboarding Conversation System (KEEP ALL)
**Location**: `/AirFit/Modules/Onboarding/`
- ✅ **ConversationFlowManager.swift** - Sophisticated conversation state management
- ✅ **OnboardingFlowCoordinator.swift** - Single source of truth for navigation
- ✅ **ConversationViewModel.swift** - Clean MVVM implementation
- ✅ **ResponseAnalyzer.swift** - Intelligent response analysis
- ✅ **OnboardingCache.swift** - Two-tier caching for recovery
- ✅ **OnboardingRecovery.swift** - Comprehensive error recovery
- ✅ **PersonaService.swift** - Clean persona generation interface

**Why Keep**: This represents months of UX refinement and handles complex conversational flows with interruption recovery.

### 4. Function Calling System (KEEP ALL)
**Location**: `/AirFit/Modules/AI/Functions/`
- ✅ **FunctionCallDispatcher.swift** - Clean dispatcher pattern
- ✅ **FunctionRegistry.swift** - Centralized registration
- ✅ **NutritionFunctions.swift** - AI-triggered nutrition logging
- ✅ **WorkoutFunctions.swift** - AI-triggered workout actions
- ✅ **GoalFunctions.swift** - Goal management functions
- ✅ **AnalysisFunctions.swift** - Analysis capabilities

**Why Keep**: Clean implementation of AI function calling with proper type safety.

### 5. Voice & Context Systems (KEEP ALL)
- ✅ **VoiceInputManager.swift** - WhisperKit integration
- ✅ **ContextAssembler.swift** - Context building for AI
- ✅ **ContextAnalyzer.swift** - Context analysis
- ✅ **ConversationManager.swift** - Conversation management

**Why Keep**: These handle complex voice input and context management for AI interactions.

## ❌ Code to Remove (But Check First!)

### 1. Deprecated AI Services
**SAFE TO DELETE** (already marked in git):
- ❌ `AIAPIService.swift` - Old Combine bridge
- ❌ `EnhancedAIAPIService.swift` - Failed hybrid attempt
- ❌ `UnifiedAIService.swift` - Another failed bridge
- ❌ `MockAIService.swift` (in Services/AI/)
- ❌ `AIAPIServiceProtocol.swift` - Deprecated protocol
- ❌ `/Services/MockServices/` - Entire directory

### 2. Production Mock Usage
**NEEDS MIGRATION FIRST**:
- ⚠️ `SimpleMockAIService.swift` - Currently used as fallback in DependencyContainer
  - **Action**: Create `OfflineAIService.swift` as proper fallback before removing

### 3. Code Needing Updates
**UPDATE, DON'T DELETE**:
- ⚠️ `CoachEngine.swift` - Update to use `AIServiceProtocol`
- ⚠️ `WorkoutAnalysisEngine.swift` - Update to use `AIServiceProtocol`

## 🚨 Critical Warnings

1. **DO NOT** delete anything in `/Modules/AI/PersonaSynthesis/` - This is our crown jewel
2. **DO NOT** delete `LLMOrchestrator` or modern AI services - These are production-ready
3. **DO NOT** delete onboarding conversation flow - Months of UX work here
4. **CHECK DEPENDENCIES** before deleting any service - Use grep/search first
5. **TEST AFTER CHANGES** - Especially persona generation and AI interactions

## Migration Patterns

When updating code, follow these patterns:

### Old Pattern (Remove):
```swift
// Combine-based, uses AIAPIServiceProtocol
func sendMessage(_ message: String) -> AnyPublisher<String, Error> {
    return aiService.sendMessage(message)
        .eraseToAnyPublisher()
}
```

### New Pattern (Keep):
```swift
// Async/await, uses AIServiceProtocol
func sendMessage(_ message: String) async throws -> String {
    return try await aiService.sendMessage(message, withContext: context)
}
```

## Verification Checklist

Before removing ANY file:
- [ ] Search for all imports of that file
- [ ] Check if it's used in DependencyContainer
- [ ] Verify it's not referenced in XIB/Storyboards
- [ ] Ensure tests don't depend on it
- [ ] Confirm it's truly deprecated (check git history)

## Recovery Plan

If something critical gets deleted:
1. Check git history: `git log --all -- <deleted_file_path>`
2. Restore: `git checkout <commit_hash> -- <file_path>`
3. Review this guide before proceeding