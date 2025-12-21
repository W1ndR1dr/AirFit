# Repository Guidelines

## Project Structure and Module Organization
AirFit is a SwiftUI iOS app with a FastAPI backend and a WidgetKit extension.

- `AirFit/` iOS app source: `App/`, `Views/`, `Services/`, `Models/`, `Utilities/`, `Resources/`, `Assets.xcassets/`.
- `AirFitWidget/` widget and Live Activity code.
- `server/` Python backend, data in `server/data/`, API in `server/server.py`.
- `project.yml` is the XcodeGen source for `AirFit.xcodeproj`.
- `docs/` and `USER_GUIDE.md` hold design and usage notes.

## Build, Test, and Development Commands
- `xcodegen generate` - regenerate `AirFit.xcodeproj` from `project.yml`.
- `xcodebuild -project AirFit.xcodeproj -scheme AirFit -sdk iphoneos build` - build for device.
- `cd server && python -m venv venv && source venv/bin/activate` - create/activate venv.
- `cd server && pip install -r requirements.txt` - install backend deps.
- `cd server && python server.py` - run FastAPI server on `http://0.0.0.0:8080`.

## Coding Style and Naming Conventions
- Swift: 4-space indentation, `UpperCamelCase` types, `lowerCamelCase` vars, SwiftUI-first; service classes are `actor`s and use Swift 6 strict concurrency.
- Python: 4-space indentation, `snake_case` functions, module-level FastAPI endpoints in `server/server.py`.
- Match existing file naming (one type per file, feature-aligned directories).

## Testing Guidelines
- No automated test suite is checked in.
- Validate manually: run the server, hit `/status` and `/scheduler/status`, and test on a physical iOS device (iOS 26+).
- For UI changes, sanity-check key flows (onboarding, chat, nutrition, insights).

## Commit and Pull Request Guidelines
- Commit messages follow conventional commits: `feat:`, `fix:`, `chore:`, `refactor:` and optional scopes, e.g. `feat(Insights): ...`.
- PRs should include a short summary, testing notes (device + server), config changes, and screenshots for UI changes; link issues when applicable.

## Configuration and Secrets
- Backend config uses env vars like `AIRFIT_HOST`, `AIRFIT_PORT`, `HEVY_API_KEY`, `CLI_TIMEOUT`, `AIRFIT_PROVIDERS`.
- Store secrets in a local `.env`; do not commit.
- The app points at a server URL in `AirFit/Services/APIClient.swift`; update when switching environments.

## Agent Review Mode
- For review-only tasks, do not edit source code in `AirFit/`, `AirFitWidget/`, or `server/`.
- Document findings in `docs/` as Markdown (e.g., `docs/CODE_REVIEW.md`).
- Before reviewing, read `CLAUDE.md`, `USER_GUIDE.md`, and `server/ARCHITECTURE.md` for philosophy and data ownership.
