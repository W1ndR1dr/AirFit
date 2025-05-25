# AirFit

AirFit is a SwiftUI fitness companion for iOS and watchOS. The repository is organized for OpenAI Codex agents and human contributors alike.

## Key Directories

- `AirFit/` – Xcode project, source, and tests
- `AirFit/Docs/` – architecture plans and module specifications

## Building & Testing

Run SwiftLint and the Xcode build from the repository root:

```bash
swiftlint
xcodebuild -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## Documentation

See the `Docs/` directory for detailed design and module breakdowns. The main entry points are:

- `Docs/Design.md` – visual and UX guidelines
- `Docs/ArchitectureOverview.md` – overall app architecture
- `Docs/Agents.md` – coding conventions and module instructions

The `AGENTS.md` file in the repository root contains build and test commands for Codex agents.
