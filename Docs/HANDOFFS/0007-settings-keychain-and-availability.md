
# Handoff Packet — 0007 Settings Keychain Verification + Provider Availability

Title: Verify API key save/retrieve and surface provider availability via notifications (no UI changes)

Context:
- APIKeyManager handles secure key storage but did not notify the app of changes.
- We want Settings and other parts of the app to react to key changes without tight coupling.

Goals (Exit Criteria):
- Post a `.apiKeysChanged` notification whenever a key is saved or deleted.
- Keep this slice UI-free; Settings can observe later.
- Maintain demo mode fallback; avoid crashes when no keys are present.

Scope:
- APIKeyManager: post `.apiKeysChanged` in `saveAPIKey` and `deleteAPIKey`.
- Notifications+Names: add `.apiKeysChanged` constant.

Validation:
- Build passes.
- Saving/deleting keys triggers the notification.

Return:
- Minimal patch to APIKeyManager and Notifications+Names.
