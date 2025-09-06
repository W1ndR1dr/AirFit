# GPT‑5 Pro Mode Prompt — Watch App State Machine

## Goal
Design and implement a robust state machine for iOS↔︎watchOS workout planning and syncing, with clear status reporting and queued transfer persistence.

## Critical Context (include these files)
- AirFitWatchApp/Views/*
- AirFit/Services/Watch/WorkoutPlanTransferService.swift
- AirFit/Modules/Workouts/Services/WorkoutSyncService.swift
- AirFit/Core/Models/PlannedWorkoutData.swift
- AirFit/Core/DI/DIBootstrapper.swift

## Tasks
1) Create a `WatchStatusStore` (paired/installed/reachable) exposed to UI.
2) Persist outbound `PlannedWorkoutData` queue (SwiftData or file-based) and retry on reachability.
3) Unify WCSession delegate handling and surface status changes via the store.
4) Add basic tests with a WCSession fake to validate message formats and retry logic.

## Acceptance Criteria
- Clear watch status UI signals (reachable/unreachable) in iOS.
- Queued plans survive app relaunch and transfer when watch becomes reachable.
- WCSession handling consolidated with minimal duplication.

---

Please implement the state machine/store, adapt transfer/sync services, and open a PR with tests.
