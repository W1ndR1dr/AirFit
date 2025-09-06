# Dependency Map — AirFit

Purpose: Provide a clear, living map of module boundaries and dependencies so we can remove dead code, untangle cross‑layer coupling, and enforce guardrails.

Update cadence: Daily during active refactor. Keep sections concise and link to sources where helpful.

## 1) Module → Services → Data Access
- Application:
  - Depends on: Core (DI, Theme), Modules (feature entry), Services (routing/config)
- Core:
  - Provides: DI (`DIBootstrapper`), Protocols, Theme, Utilities
  - Should not depend on Modules
- Data:
  - Provides: Models, Managers; owns SwiftData schema/container (via DI)
  - Consumers: Services only (no direct UI access)
- Modules (AI, Chat, Dashboard, FoodTracking, Notifications, Onboarding, Settings, Workouts):
  - Depends on: Services, Core
  - Must not import SwiftData or create `ModelContainer`
- Services (AI, Analytics, Cache, Context, Goals, Health, Monitoring, Network, Security, Speech, User, Weather):
  - Depend on: Core, Data
  - Provide repositories, managers, domain logic

Link paths:
- `AirFit/Core/DI/DIBootstrapper.swift`
- `AirFit/Modules/**`
- `AirFit/Services/**`
- `AirFit/Data/**`

## 2) Known Cross‑Layer Tangles (to be untangled)
- [ ] Any `import SwiftData` in `AirFit/Modules/**/ViewModels/**` or `Views/**`
- [ ] Direct `URLSession` usage outside `AirFit/Services/Network/**`
- [ ] NotificationCenter usage for chat streaming (must use `ChatStreamingStore`)
- [ ] Ad‑hoc `ModelContainer(` outside DI, previews, tests, or explicitly allowed files

## 3) Service Dependency Highlights
- AI
  - `AIServiceProtocol`
  - `CoachOrchestrator` depends on: PersonaService, ConversationManager, AIService, ContextAssembler, HealthKitManaging, NutritionCalculatorProtocol, MuscleGroupVolumeServiceProtocol, ExerciseDatabase, `ChatStreamingStore`
- Health
  - `HealthKitManager`, `HealthKitService`, `HealthKitAuthManager`
- Network
  - `NetworkClientProtocol`, `NetworkManager`, `RequestOptimizer`, `NetworkMonitor`
- Monitoring
  - `MonitoringService` (add TTFT, token cost, cache hit/miss, error rate hooks)

## 4) Data Access (Read/Write) — Current vs Target
- Current: ViewModels/services sometimes touch SwiftData directly
- Target: Repositories abstract SwiftData — `UserReadRepository`, `ChatHistoryRepository`, `WorkoutReadRepository`

Migration steps:
1. Introduce protocols + concrete impls in Services
2. Register in DI and swap 2–3 hot paths first
3. CI guard to block new SwiftData imports in UI (see SupClaude Guardrail Upgrades)

## 5) Dead Code & Duplicates — Quarantine List
- Candidates (to validate with Periphery + ripgrep):
  - Legacy NotificationCenter event names for chat streaming
  - Unused helpers under `Utilities` and duplicate extensions
  - Unreferenced Views in Modules (confirm via `rg` and Xcode index)

Tracking:
- Add items here with path and owner. After 1–2 days with no objections, move to `AirFit/Deprecated/` then remove.

## 6) Hotspots (Top 20)
List paths with highest churn, complexity, or coupling. Include owner and planned action.
- [ ] `AirFit/Modules/AI/Core/CoachOrchestrator.swift` — Owner: AI/Chat — Ensure store‑only streaming; add observability hooks
- [ ] `AirFit/Modules/AI/ContextAnalyzer.swift` — Owner: AI/Chat — Add router tests; verify determinism
- [ ] `AirFit/Core/DI/DIBootstrapper.swift` — Owner: Architecture — Validate registrations, lifetimes; tests
- [ ] `AirFit/Services/Network/**` — Owner: Network — Rationalize URLSession usage
- [ ] `AirFit/Modules/**/ViewModels/**` — Owner: Architecture — Remove SwiftData imports (use repos)

## 7) How to Rebuild This Map
- Ripgrep quick scan examples:
  - `rg -n "import SwiftData" AirFit/Modules/**`
  - `rg -n "NotificationCenter\\.default\\.(post|addObserver)" AirFit/Modules/AI AirFit/Modules/Chat`
  - `rg -n "ModelContainer\\s*\(" AirFit -g '!AirFit/Application/**' -g '!AirFit/**/Previews/**'`
  - `rg -n "URLSession\\.|dataTask\\(" AirFit -g '!AirFit/Services/Network/**'`
- Consider Periphery for deeper unused‑code detection.

---

Owner: Architecture
Status: Draft (seeded) — fill in details as tasks land.

