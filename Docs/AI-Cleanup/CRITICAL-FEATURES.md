# Critical AI Features - DO NOT BREAK

## 🔴 Core Features (Breaking these = Stop Everything)

### 1. Persona Synthesis & Consistency
**Files**: PersonaSynthesizer.swift, PersonaService.swift, PersonaEngine.swift
**Why Critical**: This is AirFit's key differentiator
**Test**: Create new persona, ensure it maintains voice across sessions
**Do NOT Touch**: Persona generation logic, voice characteristics system

### 2. Context Assembly
**Files**: ContextAssembler.swift, HealthContextSnapshot.swift
**Why Critical**: Provides health data context for personalized responses
**Test**: Verify AI has access to workouts, nutrition, sleep data
**Keep**: All context building logic

### 3. Coach-User Conversation
**Files**: CoachEngine.swift, ConversationManager.swift
**Why Critical**: Primary user interaction point
**Test**: Send message, get response with correct persona voice
**Preserve**: Message flow, streaming, persona integration

### 4. Function Calling System
**Current Files**: FunctionRegistry.swift, FunctionCallDispatcher.swift
**Why Critical**: Enables complex operations (set goals, log workouts, etc.)
**Test**: "Set a goal for muscle gain" → Creates actual goal in database
**Note**: Can simplify HOW it works, not IF it works

### 5. Nutrition Parsing
**Files**: DirectAIProcessor.swift, nutrition parsing in CoachEngine
**Why Critical**: Core feature for food logging
**Test**: "I ate a chicken salad" → Correct nutrition data
**Performance**: Currently optimized for direct AI, keep that

## 🟡 Important Features (Degradation = Bad UX)

### 1. Streaming Responses
**Why Important**: Responsive UI, doesn't freeze during AI calls
**Test**: Long response streams in character by character
**Note**: Already works well in providers

### 2. Multiple Provider Support  
**Why Important**: Fallback when Gemini is down
**Current**: Anthropic, OpenAI, Gemini
**Minimum**: Keep Gemini + one fallback

### 3. Error Handling
**Why Important**: User-friendly error messages
**Test**: Bad API key → "Please check your settings"
**Keep**: Error message conversion logic

### 4. Dashboard AI Content
**Files**: AICoachService.swift, dashboard content generation
**Why Important**: Dynamic, personalized dashboard
**Test**: Dashboard shows AI-generated insights

## 🟢 Nice to Have (Can Simplify Aggressively)

### 1. Response Caching
**Current**: Never hits due to conversation uniqueness
**Action**: DELETE

### 2. Health Checks
**Current**: ServiceProtocol pattern everywhere
**Action**: REMOVE - This isn't Kubernetes

### 3. Detailed Metrics
**Current**: Token counting, execution time, success rates
**Action**: Keep simple token count only

### 4. Multiple Test Services
**Current**: Demo, Test, Offline variants
**Action**: Merge into single service with mode flag

## Testing Protocol

Before ANY phase:
1. Screenshot current persona responses
2. Save example function calls
3. Document current error messages
4. Record streaming behavior

After changes:
1. Compare persona consistency
2. Verify function calls work identically  
3. Check error messages remain user-friendly
4. Confirm streaming performance

## The Carmack Rule
"If you can't explain why code exists in one sentence, it probably shouldn't exist."

Every line we keep must pass this test.