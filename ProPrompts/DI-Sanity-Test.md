# GPT‑5 Pro Mode Prompt — DI Sanity Test & Guardrails

## Goal
Add a DI sanity test to resolve critical registrations and prevent silent failures (e.g., named registrations that don’t exist). Add CI guardrails against regressions.

## Critical Context (include these files)
- AirFit/Core/DI/DIBootstrapper.swift
- AirFit/Core/DI/DIViewModelFactory.swift
- AirFit/AirFitTests/TestSupport.swift
- AirFit/AirFitTests/DIResolutionTests.swift (new)

## Tasks
1) Expand `DIResolutionTests` to include additional critical services (ContextAssembler, HealthKitManaging with minimal init).
2) Add a tiny test that enumerates known named resolves (if any) and asserts registration exists.
3) Add CI/script step to `rg -n "ModelContainer\s*\("` and fail if occurrences are outside allowed files.

## Acceptance Criteria
- DI test passes; build fails if a new unregistered named resolve is introduced.
- CI guard prevents new ad‑hoc ModelContainer creation.

---

Please implement the additional tests and CI guard.
