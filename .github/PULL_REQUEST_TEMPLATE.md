## Summary
- What changed and why (link issues/ADRs):

## Handoff Packet
- Title: 
- Context: 
- Goals (Exit Criteria): 
- Constraints: iOS 18+, Swift 6 strict concurrency, SwiftLint strict
- Scope (modules/files): 
- Validation commands: 
- Test plan: 
- Risks & rollback: 

## Screenshots / Demos (if UI)

## Checklist
- [ ] Ran `xcodegen generate`
- [ ] `swiftlint --strict` passes
- [ ] Build passes: `xcodebuild build -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'`
- [ ] Tests updated/passing or quarantined with rationale
- [ ] No secrets, no extraneous files, no TODOs left
- [ ] Adheres to `Docs/Development-Standards/`
- [ ] Linked ADR(s) if architecture decisions changed
- [ ] (Optional) Attached Claude output or prompt used
