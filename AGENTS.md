# Codex Agent Configuration

run: |
  swiftlint
  xcodebuild -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 15' test

## Documentation

- Consult `Docs/Agents.md` for coding style and module instructions.
- Architecture plans live under `Docs/`. Use these docs to guide implementation.

## General Guidance

- Ensure commits are descriptive and keep the working tree clean.
- Tests and lint must pass before proposing a PR.
