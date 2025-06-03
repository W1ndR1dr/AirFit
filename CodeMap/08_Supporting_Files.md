# 08_Supporting_Files.md

This document covers miscellaneous supporting files and directories within the AirFit project.

## GitHub Workflows (`/.github/workflows`)

*   **`test.yml`**:
    *   **Purpose**: Defines a GitHub Actions workflow, likely triggered on pushes or pull requests.
    *   **Functionality**: Probably runs automated tests (unit tests, possibly UI tests) to ensure code quality and prevent regressions. It might also include steps for building the project or linting.

## Documentation (`/Docs`)

This directory houses project documentation, research, and design notes.

*   **`/Docs/Archive`**: Contains older or completed documents.
    *   **`Completed/`**: A rich collection of Markdown files detailing various phases of development, API integration analysis, codebase context, checklists, HealthKit integration details, onboarding flow design, persona refactoring guides, and system prompts. This indicates a well-documented development process, especially for AI and onboarding features.
        *   Examples: `API_INTEGRATION_ANALYSIS.md`, `HealthKitIntegration.md`, `OnboardingFlow.md`, `PERSONA_REFACTOR_EXECUTION_GUIDE.md`, `SystemPrompt.md`.
    *   Other files in `/Archive/` seem to be drafts or context for the completed documents (e.g., `Persona Refactor.md`).
*   **`/Docs/Research Reports`**:
    *   Contains reports on specific technical investigations or explorations.
    *   Examples: `Agents.md Report.md` (likely related to AI agents), `Architecture Cleanup Summary.md`, `MLX Whisper Integration Report.md`.
*   **`/Docs/*.md` (Root Level)**:
    *   `ArchitectureUpdateReport.md`, `ArchitectureAnalysis.md`, `ArchitectureOverview.md`: Documents related to the app's architecture.
    *   `CodeMap.md`: Potentially an earlier or different version of the codemap this breakdown is based on.
    *   `Design.md`: Design specifications or notes.
    *   `FileTree.md`: A text representation of the project's file structure.
    *   `ModuleX.md` (e.g., `Module0.md` to `Module13.md`): Likely detailed design or implementation notes for different development modules or phases of the project. These could be very valuable for understanding specific features.

## Scripts (`/Scripts` and `/AirFit/Scripts`)

*   **Root `/Scripts`**:
    *   `add_files_to_xcode.sh`: Adds new files to the Xcode project, useful if not using Xcode's built-in management for all files (e.g., if using a tool like `XcodeGen` from `project.yml`).
    *   `fix_targets.sh`: Possibly corrects target memberships for files or other project settings.
    *   `test_module8_integration.sh`, `verify_module8_integration.sh`, `verify_module10.sh`: Scripts for testing or verifying specific modules or integration points.
    *   `validate-tuneup.sh`: Script for validation, "tuneup" might refer to a specific process or AI model fine-tuning.
    *   `verify_module_tests.sh`: Generic script to verify module tests.
*   **`/AirFit/Scripts`** (nested inside the main app target's source, which is unusual but possible):
    *   `fix_targets.sh` (duplicate name, context might differ)
    *   `verify_module_tests.sh` (duplicate name)

## Project and Configuration Files (Root Directory)

*   **`.cursorrules`**: Configuration for the Cursor IDE.
*   **`.gitignore`**: Specifies intentionally untracked files that Git should ignore.
*   **`AGENTS.md`**: Document related to AI agents.
*   **`AirFit.xctestplan`**: Defines schemes for running tests, including configurations like code coverage, sanitizers, etc.
*   **`BUILDPROGRESS.md`**: Tracks build progress or development milestones.
*   **`CLAUDE.md`**: Notes or context related to using the Claude AI model.
*   **`envsetupscript.sh`**: Script for setting up the development environment.
*   **`Manual.md`**: User manual or manual testing guide.
*   **`package.json`**: Typically used for JavaScript projects (Node.js). Its presence might indicate:
    *   Use of JavaScript-based tools for linting, formatting, or scripting (e.g., Prettier, ESLint, running scripts).
    *   Hybrid development aspects or web components (less likely for a native Swift app but possible).
    *   Dependencies for documentation generation tools.
*   **`PROJECT_FILE_MANAGEMENT.md`**: Guidelines or notes on how project files are managed.
*   **`project.yml`**: Configuration file for a tool like XcodeGen, which generates Xcode project files (`.xcodeproj`) from a more manageable YAML definition. This is a common practice for large projects to avoid merge conflicts in `project.pbxproj`.
*   **`TESTING_GUIDELINES.md`**: Guidelines for writing tests.
*   **`AirFit.xcodeproj`**: The Xcode project file itself.
    *   `project.pbxproj`: The core project file managed by Xcode. Best managed via `project.yml` if XcodeGen is used.
*   **`/AirFit/AirFit.entitlements`**: Specifies capabilities and entitlements for the iOS app (e.g., HealthKit, Push Notifications, App Groups).
*   **`/AirFit/Info.plist`**: Configuration file for the iOS app, containing metadata, permissions descriptions, and settings.
*   **`/AirFit/.swiftlint.yml`**: Configuration file for SwiftLint, a tool for enforcing Swift style and conventions.

## Resources (`/AirFit/Resources`)

*   **`SeedData/exercises.json`**: JSON file containing seed data for exercises, likely loaded by `ExerciseDatabase.swift`.
*   **`Localizable.strings`**: Files for app localization (though only one `Localizable.strings` is listed, there might be language-specific versions like `en.lproj/Localizable.strings`).
*   **`/AirFit/Assets.xcassets`**: The asset catalog for the iOS app, containing images, icons (`AppIcon`), colors (`AccentColor`, `BackgroundPrimary`, etc.), and other resources. The detailed list of color sets indicates a well-defined color palette managed through assets.