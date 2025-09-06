# GPT‑5 Pro Mode Prompt — Autonomous Exploration Brief

## How This Works (Context Bundling)
RepoPrompt does not auto‑load the whole codebase. For each run, provide a tight “Context Bundle” with:
- Narrative docs: intent + constraints + gates
- Minimal set of relevant files (source and tests)

Use the “Context Packs” below to pick files. Keep bundles small (10–20 files max) and focused per run.

## Mission
You have full creative latitude to propose and implement the best solution for the selected target. Begin with a brief plan, then implement incrementally under explicit quality gates.

## Target Areas (choose one per run)
- CoachEngine streaming/decomposition
- ModelContainer architecture integrity (SwiftData)
- Watch app state machine (WCSession)
- Provider/tool‑call enhancements with structured JSON

## Recommended Context Packs
Include these files alongside the docs listed under “Docs To Include”.

Docs To Include (always):
- `Docs/Codex-Independent-Analysis/Ground-Truth.md`
- `Docs/Codex-Independent-Analysis/Architecture-Review.md`
- `Docs/Quality/QUALITY_GATES.md`

1) Chat Streaming / CoachEngine
- `AirFit/Modules/AI/CoachEngine.swift`
- `AirFit/Modules/AI/Components/StreamingResponseHandler.swift`
- `AirFit/Core/Protocols/ChatStreamingStore.swift`
- `AirFit/Modules/Chat/ViewModels/ChatViewModel.swift`
- `AirFit/Modules/AI/ConversationManager.swift`
- `AirFit/Core/DI/DIBootstrapper.swift`
- `AirFit/Core/DI/DIViewModelFactory.swift`

2) ModelContainer Architecture
- `AirFit/Application/AirFitApp.swift`
- `AirFit/Services/Context/ContextAssembler.swift`
- `AirFit/Core/DI/DIBootstrapper.swift`
- `AirFit/Core/DI/DIViewModelFactory.swift`
- Any files currently creating `ModelContainer(` (search hits)

3) Watch State Machine
- `AirFit/Services/Watch/WorkoutPlanTransferService.swift`
- `AirFit/Services/Watch/WatchConnectivityManager.swift`
- `AirFit/Modules/Workouts/Services/WorkoutSyncService.swift`
- `AirFit/Core/Models/PlannedWorkoutData.swift`

4) Provider / Tool‑Calls
- `AirFit/Services/AI/LLMProviders/OpenAIProvider.swift`
- `AirFit/Services/AI/LLMProviders/GeminiProvider.swift`
- `AirFit/Core/Protocols/LLMProvider.swift`
- `AirFit/Services/AI/AIService.swift`

## Objectives
- Propose a design (500 words max), call out trade‑offs.
- Respect `Docs/Quality/QUALITY_GATES.md`.
- Keep public behavior stable unless improvements are documented.
- Add minimal tests/guards where they pay off.

## Deliverables
- A PR‑style summary (what/why, files changed, risks, validation).
- Focused diffs; avoid sweeping renames.
- Tests or sanity checks when it’s cheap and effective.

## Acceptance
- Builds and existing tests pass.
- No regressions on affected flows.
- Meets relevant quality gates (polish verified on device where applicable).

## Prompt Skeleton (copy into GPT‑5 with your Context Bundle)
```
Mission: [e.g., Replace NotificationCenter with ChatStreamingStore in CoachEngine and fully decouple streaming]

Context (docs):
- Ground‑Truth.md
- Architecture‑Review.md
- QUALITY_GATES.md

Context (code):
- [list of files from the relevant Context Pack]

Constraints:
- Maintain public behavior unless an improvement is documented
- Keep diffs focused; no mass renames
- Meet quality gates for this component

Output:
1) Brief design + plan (≤500 words)
2) Proposed diffs (unified patches)
3) Validation steps (how to verify)
4) Follow‑ups (next iteration scope)
```

---

Please explore, propose, and implement. Submit a PR with a concise design note.
