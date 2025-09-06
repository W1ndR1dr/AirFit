# Build/Test/Lint Snapshot

Environment references:
- `project.yml`: XcodeGen, iOS 26.0 / watchOS 11.0, Swift 6, strict concurrency, package: WhisperKit.
- Test plans present: `AirFit-Unit.xctestplan`, `AirFit-Integration.xctestplan`, `AirFit-UI.xctestplan`, plus primary `AirFit.xctestplan`.
- SwiftLint config `AirFit/.swiftlint.yml` enforces strict concurrency, but disables several complexity/length rules.

Observations from repo:
- Prior build logs are present under `/` (e.g., `build_generic.log`, `build_verbose.log` etc.), indicating prior successful builds in some configurations.
- Tests present but limited in scope: NutritionCalculator, StrengthProgressionService, PersonaSynthesizer basics.
- Several forced paths (`try!`) in non-test code indicate possible crash-at-runtime scenarios in some screens/flows.

Recommendations:
- Regenerate Xcode project with `xcodegen generate` after any `project.yml` changes.
- Run targeted tests locally:
  - Unit-only: `xcodebuild test -scheme AirFit -testPlan AirFit-Unit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'`
  - Focused: add `-only-testing:AirFitTests/NutritionCalculatorTests` etc.
- Lint with CI parity: `swiftlint --strict`. Consider temporarily enabling `file_length` and `type_body_length` with high thresholds to begin gating.
- Use `./reset-simulator.sh` for a clean iOS simulator between runs when debugging onboarding/HealthKit flows.

Near-term guardrails:
- Fail CI on any `try!` in app target outside previews/tests.
- Prohibit new ad-hoc `ModelContainer` instantiation via grep rule; exceptions documented.
- Run unit tests for nutrition and persona on every PR; add snapshot tests for AI parsers once split out.
