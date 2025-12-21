# AirFit Code Review Audit (Third Pass, 2025-12-20)

## Scope
- iOS app (`AirFit/`) and server (`server/`) with emphasis on device-first profile/memory, API alignment, data storage, and LLM parsing robustness.
- Read `CLAUDE.md`, `USER_GUIDE.md`, and `server/ARCHITECTURE.md` before review.

## Findings

### High
- Device-first profile and memory do not update in Claude mode, so switching to Gemini uses stale local data (profile + memories). Claude responses are not parsed locally, and only Gemini paths call local extraction and marker storage.
  Evidence: `AirFit/Views/ChatView.swift#L939`, `AirFit/Views/ChatView.swift#L1019`, `AirFit/Views/ChatView.swift#L1043`.
  Impact: Hot-swapping providers breaks continuity; local profile is incomplete after Claude sessions.
- Local profile is declared the source of truth, but UI and onboarding still depend on server profile and server edits, which do not update local state.
  Evidence: `AirFit/Models/LocalProfile.swift#L161`, `AirFit/Views/ProfileView.swift#L29`, `AirFit/Views/ProfileView.swift#L169`, `AirFit/Views/YouView.swift#L514`, `AirFit/Views/YouView.swift#L534`, `AirFit/Views/ChatView.swift#L793`.
  Impact: Profile edits made in UI may not affect Gemini mode prompts; offline/server-missing cases show empty profile and can skip onboarding.
- Memory/profile backup endpoints are called by iOS but do not exist on the server (`/sync/memories`, `/profile/sync`).
  Evidence: `AirFit/Services/MemorySyncService.swift#L301`, `AirFit/Services/MemorySyncService.swift#L410`, no matching routes in `server/server.py`.
  Impact: Memory and local profile never actually sync to server; backups silently fail.
- Duplicate `/profile/import` endpoints in the server create ambiguous routing and unpredictable behavior.
  Evidence: `server/server.py#L680`, `server/server.py#L933`.
  Impact: Import behavior depends on route ordering; client expectations can break.
- Hevy tools treat workouts as dicts, but `hevy.get_recent_workouts()` returns `HevyWorkout` objects.
  Evidence: `server/tools.py#L171`, `server/hevy.py#L11`.
  Impact: Tool calls can crash or return empty results; Tier 3 queries become unreliable.

### Medium
- Server-to-local sync overwrites local profile fields even when local is source of truth; server data can be stale and clobber recent local updates.
  Evidence: `AirFit/Services/MemorySyncService.swift#L161`, `AirFit/Models/LocalProfile.swift#L161`.
- Gemini privacy defaults are defined but never initialized globally; UserDefaults may read as false for all categories until a settings view is visited.
  Evidence: `AirFit/Services/ContextManager.swift#L29`, no call sites found.
  Impact: Gemini context can be unexpectedly empty, causing “broken” Gemini behavior for new users.
- API base URL is cached at APIClient init and can go stale when server URL changes; some extensions bypass this by reading from UserDefaults each call.
  Evidence: `AirFit/Services/APIClient.swift#L3`, `AirFit/Services/MemorySyncService.swift#L309`.
- Data directory mismatch: `AIRFIT_DATA_DIR` is defined but most storage still hard-codes `server/data`.
  Evidence: `server/config.py#L20`, `server/context_store.py#L31`, `server/profile.py#L11`, `server/exercise_store.py#L23`.
  Impact: Env var is effectively ignored; docs and config diverge.
- LLM JSON parsing remains brittle (code-fence splitting and naive brace slicing).
  Evidence: `server/insight_engine.py#L270`, `server/profile.py#L400`, `server/nutrition.py#L52`.
  Impact: Minor LLM formatting variance can break insights, profile extraction, or nutrition parsing.
- Local profile extraction ignores `training.style` even though it is requested.
  Evidence: `AirFit/Services/ProfileEvolutionService.swift#L367`, `AirFit/Services/ProfileEvolutionService.swift#L444`.
  Impact: Training style is missing from on-device profile prompts.
- Local/server profile schemas diverge (string vs list for `training_style`, `relationship_notes`).
  Evidence: `AirFit/Models/LocalProfile.swift#L215`, `AirFit/Models/LocalProfile.swift#L250`, `server/profile.py#L107`, `server/profile.py#L112`.
  Impact: Future sync will need translation; current assumption of “full parity” is inaccurate.
- Demo data seeding auto-runs on launch when local data is sparse.
  Evidence: `AirFit/Services/AutoSyncManager.swift#L111`.
  Impact: Real users can get demo meals mixed into history unless gated.
- Multiple Hevy API calls per chat context build (set tracker + recent workouts).
  Evidence: `server/chat_context.py#L174`, `server/hevy.py#L29`, `server/hevy.py#L349`.
  Impact: Higher latency and API usage for every chat message.

### Low
- CORS allows all origins with credentials, which browsers will reject and is risky if the server is ever exposed beyond LAN.
  Evidence: `server/server.py#L55`.
- `/status` increments session message_count because it calls `get_or_create_session()`.
  Evidence: `server/server.py#L67`, `server/sessions.py#L45`.
  Impact: Status polling inflates message counts and session metadata.
- Tiered context module (deprecated) still assumes dict workouts and would fail if re-enabled.
  Evidence: `server/tiered_context.py#L228`, `server/hevy.py#L11`.
- Memory file writes are not locked; concurrent writes can interleave.
  Evidence: `server/memory.py#L180`.
- Single-process storage assumption: JSON files are protected by thread locks only.
  Evidence: `server/context_store.py#L35`, `server/exercise_store.py#L28`.

## Open Questions
- Should Claude mode update local profile/memory directly (or via explicit server->local sync) to preserve hot-swap continuity?
- Should UI profile editing operate on LocalProfile first, with a background push to server for backup?
- Is `AIRFIT_DATA_DIR` intended to replace `server/data`, or is it only for CLI instructions?

## Testing Gaps
- No automated tests in repo. High-risk areas for manual smoke:
  - Claude -> Gemini provider switch after several chats (check local profile/memory continuity).
  - Profile edit in UI while in Gemini mode (verify prompt uses edits).
  - Hevy tool calls in Tier 3 (query_workouts) from Claude CLI MCP.
  - `/profile/import` behavior (route ambiguity).

## Persona + Vibe Alignment (Vision Check)
- Desired vibe from provided prompt/transcript: old-friend bro energy, witty/roasting when appropriate, evidence-based citations only when worthwhile, minimal data talk unless the user asks or logs meals/workouts, and clear “don’t give recs unless asked.”
- Current strengths:
  - Prose-first persona synthesis exists and is the gold standard in local mode (`PersonalitySynthesisService` + `LocalProfile.coachingPersona`).
  - UI thumbs up/down feedback is stored as LocalMemory and feeds persona regeneration signals.
  - Universal warmth layer exists for Gemini local prompts.
- Gaps that block the “magical” feel across providers:
  - Claude mode does not update LocalProfile/LocalMemory, so hot-swapping erodes tone continuity.
  - Server persona/warmth layer is separate from local persona and lacks explicit “silent context” rules.
  - Full context injection on the server can nudge the model into data-dumpy responses unless the prompt is very strict.

## Context Curation Status
- Server mode: `chat_context` injects insights + weekly summary + body comp + set tracker + recent workouts for every message. This is maximal context, not curated; tiered context is deprecated.
- Gemini mode: local context respects privacy toggles and staleness but still aggregates many sections every request.
- Net: context is rich but not strongly gated by relevance. The system prompts attempt to curb data-dumping, but the architecture is still “all context, every time.”
