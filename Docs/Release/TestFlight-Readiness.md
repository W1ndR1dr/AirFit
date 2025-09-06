# TestFlight Readiness Checklist

## Infra & Safety
- [ ] Replace `AppConstants.appStoreId` with real App Store ID
- [ ] `xcodegen generate` run after project.yml changes
- [ ] `swiftlint --strict` passes with custom boundary rules
- [ ] DI tests pass: `AirFit/AirFitTests/DIResolutionTests.swift`
- [ ] `Scripts/ci-guards.sh` passes all 7 boundary checks:
  - [ ] No force operations (try!, as!, !.)
  - [ ] No ad-hoc ModelContainer creation
  - [ ] No NotificationCenter for chat streaming
  - [ ] No SwiftData imports in UI layers  
  - [ ] All ViewModels have @MainActor
  - [ ] No direct URLSession usage outside Network layer
  - [ ] No hardcoded API keys or secrets

## Streaming & Data
- [ ] Chat streaming via `ChatStreamingStore` across ChatViewModel & CoachEngine
- [ ] No NotificationCenter streaming listeners in ChatViewModel
- [ ] ContextAssembler uses injected `ModelContext`; no ad‑hoc containers

## Performance (real devices)
- [ ] Chat TTFT < 250 ms on high‑end device; smooth 60fps
- [ ] Dashboard scroll smooth 60fps
- [ ] Photo capture/analysis responsive; no memory spikes
- [ ] WhisperKit model tier picks base on lower devices, large on high‑end

## Accessibility
- [ ] VoiceOver announces streaming and loading states meaningfully
- [ ] Dynamic Type up to +2 remains readable in Chat and Dashboard
- [ ] Contrast AA for all text states
- [ ] Reduce Motion: streaming/loader animations become fades

## UX Polish
- [ ] Glass tab bar shadows/blur balanced; touch targets ≥ 44pt
- [ ] Text hierarchy clear in Dashboard; spacing and typography reviewed
- [ ] TextLoadingView has eased dot timing; contextual messages used
- [ ] Photo quick action discoverable; voice buttons not intrusive

## Signing & Build
- [ ] Build scheme: `AirFit-TestFlight`
- [ ] Build version bump successful (post-action)
- [ ] Archive and validate in Xcode Organizer

## Smoke Flows
- [ ] First run → create user → chat prompt streams
- [ ] Food tab → Photo capture → confirmation → saved entry
- [ ] Recovery view opens and populates (no placeholder leaks)
- [ ] Voice input app-wide (a few fields tested)

---

## CI Guardrails Documentation

### Local Development Workflow
```bash
# Run complete development audit including CI guards
Scripts/dev-audit.sh

# Run just CI guards 
Scripts/ci-guards.sh

# Run SwiftLint with custom rules
cd AirFit && swiftlint --strict
```

### CI Integration
CI automatically runs guardrails on all PRs via GitHub Actions:
- **CI Guards**: Enforces architectural boundaries and safety
- **SwiftLint**: Custom rules for UI/data layer separation
- **Build**: Ensures clean compilation
- **Tests**: Validates functionality

### Guardrail Details

**Guard 1: No Force Operations**
- Prevents `try!`, `as!`, `!.` in app code
- Exceptions: Tests, Previews, ExerciseDatabase.swift
- Severity: Error (CI fails)

**Guard 2: No Ad-hoc ModelContainer** 
- Prevents `ModelContainer(` outside allowed locations
- Allowed: Application/, Tests/, Previews/, ExerciseDatabase.swift
- Ensures single source of truth for data access

**Guard 3: No NotificationCenter for Chat**
- Prevents NotificationCenter usage in AI/Chat modules
- Enforces ChatStreamingStore pattern
- Improves predictability and testability

**Guard 4: No SwiftData in UI**
- Prevents SwiftData imports in Modules/Views and ViewModels
- Enforces repository pattern and clean architecture
- Severity: Warning (allows gradual migration)

**Guard 5: @MainActor on ViewModels**
- Requires @MainActor annotation on all ViewModels
- Ensures UI updates happen on main thread
- Prevents common concurrency bugs

**Guard 6: NetworkClientProtocol Only**
- Prevents direct URLSession usage outside Network layer
- Ensures consistent error handling and monitoring
- Allows for request optimization and caching

**Guard 7: No Hardcoded Secrets**
- Scans for API keys, tokens, and secrets in code
- Prevents accidental commits of sensitive data
- Enforces proper Keychain usage

### Runbook
1) `Scripts/dev-audit.sh` - Complete local check
2) `xcodegen generate` - Refresh Xcode project  
3) `swiftlint --strict` - Lint with custom rules
4) `Scripts/ci-guards.sh` - Boundary checks
5) Archive with `AirFit-TestFlight` scheme
6) Quick on-device smoke (15 minutes)

