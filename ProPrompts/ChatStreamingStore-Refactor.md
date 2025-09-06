# GPT‑5 Pro Mode Prompt — ChatStreamingStore Refactor

## Goal
Replace NotificationCenter coupling in chat streaming with an injected, typed `ChatStreamingStore` used by both producers (CoachEngine) and consumers (ChatViewModel).

## Critical Context (include these files)
- AirFit/Core/Protocols/ChatStreamingStore.swift (new wrapper already added)
- AirFit/Modules/Chat/ViewModels/ChatViewModel.swift
- AirFit/Modules/AI/CoachEngine.swift
- AirFit/Core/DI/DIBootstrapper.swift

## Tasks
1) Update CoachEngine to publish `.started/.delta/.finished(usage:)` events to `ChatStreamingStore` instead of posting notifications.
2) Keep NotificationCenter posting temporarily for backwards compatibility; remove after verification.
3) Ensure ChatViewModel subscribes only to `ChatStreamingStore` (drop NotificationCenter listeners once stable).

## Acceptance Criteria
- Streaming text renders correctly; stop button behavior unchanged.
- No regressions in message creation or completion lifecycle.
- Notifications removed from the streaming path after verification.

---

Please implement the refactor and open a PR referencing the updated files and DI registrations.
