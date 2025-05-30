# Persona System Optimization Plan

## Objective
Develop a step-by-step approach to reduce PersonaEngine complexity and token usage while retaining a personalized coaching experience.

## Codebase Alignment Overview
- **System Prompt Size**: `PersonaEngine.buildSystemPromptTemplate()` embeds a large prompt (~70 lines) starting at line 20 in `PersonaEngine.swift`. This directly causes high token counts.
- **Token Logging**: Lines 129‑137 in `PersonaEngine.buildSystemPrompt()` already calculate token estimates and log warnings, aligning with the need for instrumentation.
- **Granular Adjustments**: Lines 165‑334 contain numerous small blend adjustments (±0.05–0.20). This matches the observed over‑granularity from the analysis.
- **Onboarding Complexity**: `OnboardingViewModel` builds a full `UserProfileJsonBlob` (lines 135‑183) with many sliders defined in `OnboardingModels.swift`. This contributes to friction and data bloat.

## Optimization Plan
1. **Trim the System Prompt**
   - Extract only the essential rules from lines 20‑90 of `PersonaEngine.swift` and move extended guidance to documentation.
   - Target a 70% reduction in template length.
2. **Introduce Discrete Persona Modes**
   - Replace the continuous `Blend` adjustments with 3–5 predefined persona modes.
   - Map existing blend values to the closest mode when migrating stored profiles.
3. **Cache Prompt Components**
   - Cache user profile JSON and system prompt base string after onboarding.
   - Rebuild the final prompt only when context or persona mode changes.
4. **Simplify Onboarding Inputs**
   - Remove low‑impact sliders and use a short quiz to select persona mode.
   - Retain essential fields (goal text, timezone) as seen in `OnboardingViewModel` lines 124‑182.
5. **Instrumentation & Metrics**
   - Expand token logging around `buildSystemPrompt` to record average token use per interaction.
   - Measure response latency to verify runtime improvements.
6. **Migration Strategy**
   - Write a script to transform existing `OnboardingProfile` records to the new persona mode structure.
   - Provide in‑app messaging to inform users of the simplified persona system.

## Expected Outcomes
- **Token Reduction**: System prompts shrink from ~2000 tokens to under 600.
- **Simplified Code**: Persona adjustments drop from ~170 lines to <50.
- **Faster Onboarding**: Fewer screens and inputs reduce completion time.
- **Maintain Personalization**: Predefined modes still capture major coaching styles with minimal user effort.
