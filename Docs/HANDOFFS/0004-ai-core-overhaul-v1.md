# Handoff Packet — 0004 AI Core Overhaul v1

Title: Stabilize AI pipeline (requests, streaming, errors, function-calls)

Context:
- AI works but is inconsistent across providers and call sites. We want a dependable core for personal use with clean fallbacks.
- Key pieces: `AIService` (providers + per-request model override), `DirectAIProcessor`, `CoachEngine`, `StreamingResponseHandler`, `FunctionRegistry`.

Goals (Exit Criteria):
- Consistent per-request behavior: timeouts respected; streaming merges into coherent text; structured JSON respected when requested.
- Robust error mapping: convert provider/network errors into friendly `AppError` consistently.
- Function calling: central helper to wrap tool/function calls when response indicates one (no-op_OK if provider doesn’t use it yet).
- Minimal metrics: add lightweight `os_signpost` markers for request start/end (label includes model + user tag), no heavy tracing.
- Non-breaking changes; small, focused diffs.

Constraints:
- Swift 6 strict; minimal surface area changes; keep features working.

Scope & Guidance:
- AIService:
  - Add optional `withSignposts` behavior: if `metadata["user"]` exists, include it in signpost name; record duration (no external deps).
  - Ensure `request.timeout` is respected in both complete and stream flows (cancel task after timeout).
- StreamingResponseHandler:
  - Provide a small utility to accumulate deltas into `String` and surface a final `done` with usage; guard against out-of-order chunks.
- CoachEngine:
  - Replace ad-hoc response stitching with the utility; use per-request `timeout` tuned to context (chat ~30s).
- DirectAIProcessor:
  - For structured requests, ensure we set `responseFormat: .structuredJson` and handle both `.structuredData` and fallback text uniformly; already mostly present — refactor lightly to use the same utility.

Validation:
- Build.
- Manual: send a chat message; observe streaming; verify no crash on timeout/network failure.

Return:
- A single `apply_patch` touching only minimal files: likely `AIService.swift`, `StreamingResponseHandler.swift`, `CoachEngine.swift`, `DirectAIProcessor.swift`.
- Keep implementation lean and focused. No UI changes.
