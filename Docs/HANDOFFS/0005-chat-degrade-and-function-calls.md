
# Handoff Packet — 0005 Chat Graceful‑Degrade + Basic Function Calls

Title: Make chat resilient without API keys and standardize function‑call handling

Context:
- With no API keys configured, chat should not error; it should use demo mode or a friendly fallback.
- Function calls should be recognized and handled centrally; when a tool isn’t available, we no‑op with a clear assistant message.

Goals (Exit Criteria):
- If AI service is not configured, chat uses demo/test behavior automatically (no crashes; friendly replies).
- Function calls: central check + safe no‑op path; assistant message indicates action queued/unsupported.
- Minimal diffs; no UI changes.

Scope & Guidance:
- DIBootstrapper/AIService selection:
  - If `AIService.configure()` fails due to missing keys, automatically switch to `.demo` mode or re‑init AIService in demo mode.
  - Alternatively, set `AppConstants.Configuration.isUsingDemoMode = true` on first configure failure and recreate the service.
- CoachEngine.function handling:
  - If a function call is detected but the tool is unavailable, record a no‑op with an assistant status line (e.g., “(Note: scheduling not configured yet)”) 
  - Keep it minimal and safe.

Validation:
- Build passes.
- With no keys set, opening chat and sending a message produces a friendly AI response (no errors/crashes).
- When a function call appears, no crash; assistant message shows a short status line.

Return:
- One apply_patch block; touch minimal files (e.g., DIBootstrapper, CoachEngine function invocation).
