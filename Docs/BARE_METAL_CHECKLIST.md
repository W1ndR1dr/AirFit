# Bare‑Metal Rehab Checklist

Use this as a fast, repeatable sanity list during cleanup.

## App Boot
- [x] Build passes (iOS 18.4 sim)
- [x] Launch to Today tab without keys
- [x] Create user path works (no crashes)
- [x] Onboarding gated/simplified (no heavy flows by default)

## Today Dashboard
- [x] Macro Rings (no placeholders)
- [ ] Quick Actions stable
- [ ] AI guidance optional (no blocking)

## Settings
- [ ] API key entry persists to Keychain (basic verification)
- [ ] Feature toggles surface (optional)

## Chat
- [ ] Degrade gracefully without keys (no crash)
- [ ] Basic send/receive with single provider (Claude or GPT‑5 mini)

## Food Tracking
- [ ] Text logging → parsed/save path works locally
- [ ] Nutrition summary updates Today rings

## Health
- [ ] Permission request succeeds or skips cleanly
- [ ] Basic reads (sleep/workouts) soft‑fail without blocking UI

## Watch (Deferred)
- [ ] Disabled until iOS path stable

## Tooling
- [x] XcodeGen → build loop documented
- [x] SwiftLint strict documented (can tune noisy rules later)
- [x] Claude wrapper + docs verified

