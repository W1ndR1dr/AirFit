# HealthKit Authorization & Integration Guide

**Version:** 1.0
**Last Updated:** May 27, 2025

This document outlines how the AirFit application requests access to HealthKit data and how future dashboard features will integrate with that data.

---

## 1. Authorization Flow Diagram

```text
User launches Onboarding
      |
      v
HealthKit Explanation Screen
      |
Request Authorization -> [Authorized] -> Continue Onboarding
      |                         |
      |                    [Denied or Restricted]
      v                         v
Permission Denied View     Show Re‑authorization Prompt
```

The flow begins during onboarding where the user is presented with a dedicated explanation screen followed by the system authorization prompt. If permission is denied, the user can revisit the prompt from settings or the dashboard.

## 2. UI Integration Points

1. **Onboarding Module** – introduces HealthKit integration with an explanation screen and a button to request authorization.
2. **Permission Denied Handling** – if authorization fails, a lightweight view informs the user and provides a link to the Settings app.
3. **Re‑authorization Prompt** – accessible from the future dashboard and settings screens for users who initially declined access.
4. **Dashboard Widgets** – once authorized, dashboard components will display steps, active energy, and workout summaries sourced from HealthKit.

## 3. Permission Handling Strategies

- Use `HealthKitAuthManager` to request authorization when onboarding reaches the HealthKit screen.
- Store the `authorizationStatus` in the manager and observe it from views.
- Defer HealthKit requests until the explanation screen appears to respect user consent.
- Provide clear messaging when authorization is denied or restricted.

## 4. Error State Management

- Errors from `HealthKitManager` are logged via `AppLogger`.
- The onboarding flow presents a simple alert with a localized description.
- Dashboard widgets will gracefully degrade to placeholder states when data is unavailable.
- Re‑authorization attempts are throttled to prevent repeated prompts.

## 5. Future Dashboard Integration Plans

- **Workout Summary Tile** – displays recent workouts and allows quick logging of new sessions.
- **Activity Rings View** – mirrors Apple's Activity app using HealthKit metrics for move, exercise, and stand goals.
- **Sleep Trends Chart** – visualizes nightly sleep durations sourced from HealthKit.
- **Re‑authorization Entry Point** – a banner or settings option in the dashboard will trigger the HealthKit permission prompt if access is missing.

The placeholder components outlined below will be implemented in the onboarding module to support this flow and serve as hooks for future dashboard widgets.
