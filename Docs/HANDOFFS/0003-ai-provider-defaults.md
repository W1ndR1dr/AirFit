# Handoff Packet — 0003 AI Provider Defaults (Onboarding vs Chat)

Title: Set AI provider/model defaults per context with safe fallbacks

Context:
- We want world-class onboarding quality. Use GPT‑5 (thinking-capable) for persona synthesis if available.
- For day-to-day chat, prefer cost-effective GPT‑5 Mini by default.
- Keep Gemini 2.5 Flash Thinking available as an option.
- We already have: `LLMModel` with `gpt5`, `gpt5Mini`, `gemini25FlashThinking`; `AIService` manages providers; `PersonaSynthesizer` accepts a preferred model; `AIRequest` supports an optional `model` override.

Goals (Exit Criteria):
- Onboarding (persona synthesis) uses GPT‑5 by default when OpenAI is configured, otherwise falls back to best available.
- Chat default model is GPT‑5 Mini when OpenAI is configured; otherwise existing best.
- Gemini 2.5 Flash Thinking remains selectable and functional.
- No UI regressions; no changes required to Settings UI yet.

Constraints:
- Swift 6, strict concurrency.
- Minimal diffs; respect layering.

Scope & Guidance:
- AIService:
  - Prefer OpenAI by default for chat if key present: `_activeProvider = .openAI`, `currentModel = LLMModel.gpt5Mini.identifier`.
  - Keep Gemini and Anthropic providers registered when keys exist; preserve fallback logic.
  - `handleProductionRequest`: use `AIRequest.model` to override provider/model per request when set.
- PersonaSynthesizer / OnboardingIntelligence:
  - Ensure persona synthesis picks `.gpt5` when available; otherwise fallback to `getBestAvailableModel()`.
  - When building `AIRequest`s for persona facets, pass `model: chosen.identifier` so the override is honored.
- LLMModels / AIService.availableModels:
  - Ensure Gemini 2.5 Flash Thinking appears in available models (if not already).
- Documentation: add 2–3 lines to `Docs/AI_PAIRING.md` or `CLAUDE.md` summarizing defaults (Onboarding=GPT‑5, Chat=GPT‑5 Mini; Gemini 2.5 Flash Thinking available).

Validation:
- Build.
- Confirm OpenAI present → default provider `.openAI` and model `gpt-5-mini`.
- Remove OpenAI key → fallback provider/model unchanged; onboarding still works with best available.

Return:
- A single patch in apply_patch format touching only necessary files (likely: `AirFit/Services/AI/AIService.swift`, `AirFit/Modules/AI/PersonaSynthesis/PersonaSynthesizer.swift`, optionally `AirFit/Services/AI/AIService.swift` availableModels; tiny doc tweak).
- Keep changes minimal and annotated by context if needed.
