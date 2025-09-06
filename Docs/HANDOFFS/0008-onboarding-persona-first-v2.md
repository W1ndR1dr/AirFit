
# Handoff Packet — 0008 Onboarding Persona‑First V2

Title: Replace heavy onboarding with a focused persona‑first flow (3 steps)

Context:
- Current OnboardingView/StateMachine is heavy; simpleOnboarding bypass is set just to keep app bootable.
- We want a crisp, reliable onboarding that creates/saves a persona (GPT‑5 preferred), marks onboarding complete, and navigates to Today.

Goals (Exit Criteria):
- Add `PersonaOnboardingView` (3 steps): Welcome → Generate Persona (progress) → Confirm & Continue.
- Use `PersonaSynthesizer` with a minimal `ConversationData` + default `ConversationPersonalityInsights` (safe defaults) and preferred model (GPT‑5 when available).
- Save persona via `PersonaService.savePersona`, mark user onboarded via `UserService.completeOnboarding`, and post `.onboardingCompleted`.
- Gate usage via a toggle; update `ContentView` to use new view when enabled.
- Keep old onboarding intact but unused when toggle is on; no watch step.

Scope & Guidance:
- Add file: `AirFit/Modules/Onboarding/PersonaOnboardingView.swift`.
- Update `FeatureToggles`: `simpleOnboarding = false` (default), `newOnboardingEnabled = true` (default).
- Update `ContentView` to present `PersonaOnboardingView` when `shouldShowOnboarding` and `FeatureToggles.newOnboardingEnabled`.
- If AI isn’t configured (demo mode), show a friendly status and allow a fallback persona (basic) or ask to enter keys.

Validation:
- Build passes.
- New users flow through PersonaOnboardingView; on completion, Today shows and persona is retrievable via PersonaService.

Return:
- One apply_patch block (new view file + small edits to FeatureToggles.swift and ContentView.swift).
