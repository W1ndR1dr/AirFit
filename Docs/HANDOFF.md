# Handoff Packet Template

Use this template for every scoped task. Keep it concise and concrete.

---

Title: <Descriptive, action-oriented title>

Context:
- <1–3 bullets on the problem and why now>
- <Links to relevant files/sections>

Goals (Exit Criteria):
- <Measurable outcome e.g., build passes, lints clear, behavior verified>
- <Performance target if relevant>

Constraints:
- iOS 18+, Swift 6 strict concurrency, SwiftLint strict
- Architecture boundaries (Application/Core/Data/Modules/Services)

Scope:
- Affected modules: <e.g., Modules/Dashboard, Services/Network>
- Primary files: <paths>

Plan (High-Level):
- <Step 1>
- <Step 2>
- <Step 3>

Validation:
- Commands: `xcodegen generate`, `swiftlint --strict`, `xcodebuild build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'`
- Tests: <which tests to run or add>

Risks & Rollback:
- <Known risks>
- <Rollback strategy>

Notes:
- <Any gotchas, open questions, or follow-ups>

Run With Claude:
```bash
# Non-interactive run from packet text
Scripts/claude-impl.sh --print "Use Docs/HANDOFFS/<id>.md to implement this task."

# Or paste the packet content directly after the prompt
```
