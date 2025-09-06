
# Project Status (Rolling)

Updated: 2025-09-03
Owner: Solo (AI‑paired)

## Current Posture
- Boot path: Stable (Today tab default).
- Onboarding: Persona-first; AI optional via toggles.
- Today: Macro Rings live with adaptive targets note (if applied).
- Chat: True streaming with Stop; no duplicate messages.
- Watch: Deferred.

## AI System
- Multi-provider support remains; personal mode optimized for responsiveness.
- Streaming: CoachEngine emits streaming notifications; Chat uses ephemeral bubble + persisted final message.
- Timeouts: AIService enforces timeouts and graceful degradation.
- Metrics: os_signpost around requests.

## Feature Toggles
- `FeatureToggles.aiOptionalForOnboarding = true`
- `FeatureToggles.newOnboardingEnabled = true`
- `FeatureToggles.watchSetupEnabled = false`
- Adaptive goals toggle stored at `AirFit.AdaptiveNutritionEnabled` (UserDefaults)

## Recent Work Completed
- Macro Rings on Today (always-on) — shipped.
- AI Provider Defaults — shipped.
- AI Core Overhaul v1 — shipped.
- Chat graceful streaming + Stop — shipped.
- HealthKit nutrition fallback → Today — shipped.
- Adaptive Nutrition Goals v1 — shipped.

## Next Up (Proposed)
- Food logging via photo (single-pass parse with verify).
- Recovery dashboard banner + suggestions.
- Watch push ‘Send to Watch’ and receiver validation.

## How To Continue
- Use standard git/PR workflow and XcodeGen; keep slices small and documented here.
- Update this STATUS.md after each slice with “What changed” and “Next up”.

## Notes
- Removed all Claude-related documentation and scripts per direction.

- 0010 Onboarding Persona-first V2 polish — shipped.
- 0011 Cleanup wave — removed legacy onboarding flow (state machine + views); routing now uses Persona-first exclusively.
