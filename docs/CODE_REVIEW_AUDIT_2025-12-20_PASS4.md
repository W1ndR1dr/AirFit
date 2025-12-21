# AirFit Code Review Audit (Fourth Pass, 2025-12-20)

## Scope
- Reviewed iOS app (`AirFit/`) and server (`server/`) with focus on device-first profile/memory, provider hot-swap, persona/vibe alignment, and context curation.
- Read `CLAUDE.md`, `USER_GUIDE.md`, and `server/ARCHITECTURE.md` before review.
- Sampled the provided coach prompt and conversation snippets to anchor the vibe target.

## Vibe Target (from provided prompt + convo snippets)
- Old-friend "bro energy", roast-friendly but supportive.
- Evidence-based depth when useful, otherwise concise and human.
- No unsolicited meal/workout recs.
- Context is awareness, not agenda: mention data only when relevant.

## Findings

### High
- **Hot-swap breaks persona continuity: Claude mode never updates on-device profile/memory.** Claude responses are sent to server only, while local extraction and memory marker processing happen only for Gemini. Switching providers loses tone continuity and local persona freshness. Evidence: `AirFit/Views/ChatView.swift:939`, `AirFit/Views/ChatView.swift:1019`, `AirFit/Services/AIRouter.swift:214`.
- **Memory/profile backup endpoints are missing on the server.** iOS calls `/sync/memories` and `/profile/sync`, but server has no matching routes, so backup/sync silently fails and the hot-swappable profile vision is blocked. Evidence: `AirFit/Services/MemorySyncService.swift:301`, `AirFit/Services/MemorySyncService.swift:410`, routes present near `server/server.py:587` and `server/server.py:933`.
- **Device-first profile is not the UI source of truth.** Profile screens and onboarding checks pull server profile, so local persona evolution is invisible and offline cases can skip onboarding. Evidence: `AirFit/Views/ProfileView.swift:29`, `AirFit/Views/YouView.swift:8`, `AirFit/Views/ChatView.swift:793`.
- **Hevy tools are broken by type mismatch.** Tool code treats workouts as dicts (`w.get(...)`), but the Hevy client returns `HevyWorkout` dataclasses. Tier-3 tool calls can error or return empty data. Evidence: `server/tools.py:171`, `server/hevy.py:11`.

### Medium
- **Duplicate `/profile/import` routes cause ambiguous behavior.** Two handlers are registered for the same path; the latter wins silently. Evidence: `server/server.py:680`, `server/server.py:933`.
- **Local/server profile schemas diverge.** Local `trainingStyle` and `relationshipNotes` are strings while server expects lists; `training_days_per_week` is an `Int` locally and a `str` on server. Sync parity will break. Evidence: `AirFit/Models/LocalProfile.swift:215`, `AirFit/Models/LocalProfile.swift:251`, `server/profile.py:107`, `server/profile.py:111`.
- **Training style extraction is ignored on-device.** The extraction schema includes `training.style`, but `applyExtraction` never writes it to the profile. Evidence: `AirFit/Services/ProfileEvolutionService.swift:367`, `AirFit/Services/ProfileEvolutionService.swift:444`.
- **Gemini privacy defaults are never initialized.** `GeminiPrivacySettings.current` reads `UserDefaults` booleans that default to false; `initializeDefaults()` is never called, so new users can get empty context until they visit settings. Evidence: `AirFit/Services/ContextManager.swift:18`, `AirFit/Services/ContextManager.swift:29`.
- **Context curation is still "all data, every message".** Server injects insights + weekly summary + body comp + set tracker + workouts on every chat, and local context similarly includes health/nutrition/workouts/insights when enabled. This conflicts with the "old friend" vibe and increases data-dumpy replies. Evidence: `server/chat_context.py:163`, `server/server.py:232`, `AirFit/Services/ContextManager.swift:149`.
- **Insights are shared with Gemini regardless of privacy toggles.** Local insights are appended even if nutrition/workout/health sharing is off, which can leak sensitive data. Evidence: `AirFit/Services/ContextManager.swift:185`, `AirFit/Services/ContextManager.swift:277`.
- **Server sync clobbers local profile despite device-first rule.** Sync from server overwrites local fields ("server wins"), risking loss of on-device updates. Evidence: `AirFit/Services/MemorySyncService.swift:161`.
- **Demo data seeding runs automatically on first launch.** If fewer than 3 entries exist, demo meals are inserted without gating or user consent. Evidence: `AirFit/Services/AutoSyncManager.swift:104`, `AirFit/Services/AutoSyncManager.swift:179`.
- **Multiple Hevy API calls per chat.** Context builder calls set tracker and hevy context separately, each hitting Hevy. This adds latency and API load. Evidence: `server/chat_context.py:174`, `server/hevy.py:29`.
- **`AIRFIT_DATA_DIR` is ignored.** Config sets it, but data stores hardcode `server/data`, so the env var is ineffective. Evidence: `server/config.py:20`, `server/context_store.py:31`.
- **LLM JSON parsing is brittle.** Insight/profile/nutrition parsing relies on naive fence or brace slicing; minor formatting variations can break features. Evidence: `server/insight_engine.py:270`, `server/profile.py:405`, `server/nutrition.py:76`.

### Low
- **Gemini mode duplicates health/nutrition context.** Local context already includes these sections; the chat path appends them again, bloating tokens. Evidence: `AirFit/Services/ContextManager.swift:197`, `AirFit/Views/ChatView.swift:997`.
- **CORS allows all origins with credentials.** Acceptable on LAN but risky if exposed. Evidence: `server/server.py:55`.
- **`/status` mutates session state.** Polling increments message counts by calling `get_or_create_session`. Evidence: `server/server.py:67`, `server/sessions.py:42`.
- **Memory writes lack locking.** Concurrent writes can interleave and corrupt markdown. Evidence: `server/memory.py:182`.
- **Single-process assumption for JSON stores.** File locks are in-process only; multiple workers risk corruption. Evidence: `server/context_store.py:31`, `server/sessions.py:35`.
- **Tiered context still assumes dict workouts.** If re-enabled, it will fail against `HevyWorkout` objects. Evidence: `server/tiered_context.py:226`.
- **Provider naming drift ("ollama" vs "codex").** Confusing for operators. Evidence: `server/llm_router.py:222`, `server/insight_engine.py:10`.

## Vibe Alignment Notes
- **Biggest blockers:** hot-swap loses persona/memory continuity (Claude does not update local state) and context injection is maximal on every turn, which nudges the model to talk about data even when the user wants casual conversation.
- **Thumbs up/down feedback works locally** (stored as `LocalMemory`) but is not synced to server and only affects Gemini persona synthesis. Evidence: `AirFit/Views/ChatView.swift:1380`.

## Testing Gaps
- No automated tests. Suggested manual checks:
  - Switch Claude -> Gemini after 10+ messages; verify persona and memory continuity.
  - Fresh install: verify Gemini privacy defaults produce expected context.
  - Hit `/profile/import` and confirm which handler runs.
  - Trigger `query_workouts` tool (Claude MCP or Gemini function) and verify results.
  - Launch fresh app to ensure demo data does not pollute real usage.

## Open Questions
- Should Claude responses be parsed locally to update on-device profile/memory, or should the server push deltas back to device?
- Is the server profile still intended to be the UI source of truth, or should UI switch to `LocalProfile`?
- How aggressive should context gating be to preserve the "old friend" vibe (intent-based, recency-based, or user-tunable)?
