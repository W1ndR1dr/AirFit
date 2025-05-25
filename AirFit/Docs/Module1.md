**Modular Sub-Document 1: Core Project Setup & Configuration**

**Version:** 1.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Date:** May 24, 2025

**1. Module Overview**

*   **Purpose:** To establish the foundational structure, configurations, and core utilities for the AirFit iOS and WatchOS application. This module ensures a consistent development environment, coding style, and provides essential shared resources.
*   **Responsibilities:**
    *   Setting up the Xcode project and Git repository.
    *   Defining the project's directory structure.
    *   Implementing global constants and enumerations.
    *   Establishing the visual theme (colors, fonts) for SwiftUI.
    *   Integrating and configuring code styling tools (SwiftLint, SwiftFormat).
    *   Creating essential utility extensions and helper functions.
    *   Setting up a basic logging mechanism.
*   **Key Components within this Module:**
    *   Xcode Project File (`.xcodeproj`)
    *   Git Repository (`.git`)
    *   Project Directory Structure
    *   `Constants.swift` file
    *   `Theme.swift` file (or similar for color/font definitions)
    *   `.swiftlint.yml` configuration file
    *   `.swiftformat` configuration file (if command-line tool is used)
    *   `Logger.swift` (basic logging utility)
    *   Utility extension files (e.g., `String+Extensions.swift`, `Date+Extensions.swift`)

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Design Specification (v1.2) - for theme (colors, fonts) and overall aesthetic.
    *   AirFit App - Master Architecture Specification (v1.2) - for technology stack and code style guidelines.
*   **Outputs:**
    *   A fully configured Xcode project ready for feature development.
    *   A shared foundation for all subsequent modules and AI agent tasks.

**3. Detailed Component Specifications & Agent Tasks**

*(These tasks are designed to be sequential where necessary. Some sub-tasks within a larger task might be parallelizable by different specialized agents if the environment supports such fine-grained task distribution, but for simplicity, we'll assume one primary "Setup Agent" handles this module.)*

---

**Task 1.0: Initialize Git Repository**
    *   **Agent Task 1.0.1:**
        *   Instruction: "Initialize a new Git repository in the project's root directory."
        *   Details: Use standard Git initialization.
        *   Acceptance Criteria: A `.git` directory is created. `git status` shows an empty repository.
    *   **Agent Task 1.0.2:**
        *   Instruction: "Create a `.gitignore` file."
        *   Details: Add common Swift/Xcode ignores (e.g., `xcuserdata/`, `.DS_Store`, build artifacts, derived data, `*.swp`). Also, include ignores for dependency manager files if they are not meant to be committed (e.g., `.swiftpm/build/` if using SPM and not committing build artifacts).
        *   Reference: Standard GitHub `.gitignore` template for Swift can be used as a base.
        *   Acceptance Criteria: `.gitignore` file exists with appropriate patterns.
    *   **Agent Task 1.0.3:**
        *   Instruction: "Make an initial commit with the `.gitignore` file."
        *   Details: Commit message: "Initial commit: Add .gitignore".
        *   Acceptance Criteria: Git history shows the initial commit.

---

**Task 1.1: Create Xcode Project**
    *   **Agent Task 1.1.1:**
        *   Instruction: "Create a new Xcode project named 'AirFit'."
        *   Details:
            *   Template: iOS App with Watch App. (Alternatively, create iOS app first, then add WatchOS target later if agent finds that simpler).
            *   Interface: SwiftUI
            *   Lifecycle: SwiftUI App
            *   Language: Swift
            *   Include Tests: Yes (for both Unit and UI Testing targets).
            *   Organization Identifier: `com.[YourDeveloperNameOrCompany]` (Placeholder: `com.example.airfit` - *Human to update this later*)
            *   Team: None (or placeholder - *Human to configure later*)
            *   Bundle Identifier (iOS): `com.example.airfit.ios` (Placeholder)
            *   Bundle Identifier (WatchOS): `com.example.airfit.watchkitapp` (Placeholder)
        *   Acceptance Criteria: An `AirFit.xcodeproj` file is created. The project opens in Xcode without errors. Both iOS and WatchOS targets exist.

---

**Task 1.2: Define Project Directory Structure**
    *   **Agent Task 1.2.1:**
        *   Instruction: "Create the following top-level group (folder) structure within the 'AirFit' main project group in Xcode (and corresponding directories on the filesystem)."
        *   Directory Structure:
            ```
            AirFit/  (Main project group)
            ├── Application/
            │   ├── AppDelegate.swift (if not using SwiftUI App Lifecycle exclusively)
            │   ├── AirFitApp.swift (Main SwiftUI App struct)
            │   └── WatchApp/
            │       └── AirFitWatchApp.swift (WatchOS App struct)
            ├── Core/
            │   ├── Constants/
            │   ├── Enums/
            │   ├── Extensions/
            │   ├── Protocols/
            │   ├── Theme/
            │   └── Utilities/
            ├── Data/
            │   ├── Models/
            │   └── Managers/ (e.g., SwiftDataMigrationManager, if needed later)
            ├── Modules/
            │   ├── Onboarding/
            │   │   ├── Views/
            │   │   ├── ViewModels/
            │   │   └── Services/ (if module-specific services exist)
            │   ├── Dashboard/ (etc. for other feature modules)
            │   └── Settings/
            ├── Services/
            │   ├── Networking/
            │   ├── AI/
            │   ├── Health/
            │   └── Platform/
            ├── Resources/
            │   ├── Assets.xcassets/
            │   ├── LaunchScreen.storyboard (if used, though aiming for no splash)
            │   └── Info.plist (iOS and WatchOS)
            └── Tests/
                ├── AirFitTests/ (Unit tests for iOS)
                └── AirFitUITests/ (UI tests for iOS)
                └── AirFitWatchAppTests/ (Unit tests for WatchOS)
                └── AirFitWatchAppUITests/ (UI tests for WatchOS)
            ```
        *   Details: Ensure these groups are created in Xcode and map to actual filesystem directories. Delete any default files not fitting this structure (e.g., move `ContentView.swift` if it was created, or rename/reuse it later).
        *   Acceptance Criteria: The Xcode project navigator reflects this structure. Corresponding directories are created on the filesystem.

---

**Task 1.3: Implement Core Constants and Enums**
    *   **Agent Task 1.3.1:**
        *   Instruction: "Create a new Swift file named `AppConstants.swift` inside `AirFit/Core/Constants/`."
        *   Details: This file will store global, app-wide constants.
            ```swift
            // AirFit/Core/Constants/AppConstants.swift
            import Foundation

            struct AppConstants {
                static let appName = "AirFit"
                static let defaultCornerRadius: CGFloat = 12.0
                static let defaultPadding: CGFloat = 16.0
                // Add other app-wide constants as they become apparent, e.g., API base URLs (placeholders for now)
                static let weatherAPIBaseURL = "https://api.exampleweather.com/v1/" // Placeholder
                static let aiRouterAPIBaseURL = "https://api.exampleairouter.com/v1/" // Placeholder
            }
            ```
        *   Acceptance Criteria: `AppConstants.swift` exists with the specified content.
    *   **Agent Task 1.3.2:**
        *   Instruction: "Create a new Swift file named `GlobalEnums.swift` inside `AirFit/Core/Enums/`."
        *   Details: This file will store enums used across multiple modules. Module-specific enums should live within their respective module folders. For now, it can be empty or have placeholders.
            ```swift
            // AirFit/Core/Enums/GlobalEnums.swift
            import Foundation

            // Example:
            // enum UserRole {
            //     case freeUser, premiumUser
            // }
            // Add global enums as needed.
            ```
        *   Acceptance Criteria: `GlobalEnums.swift` exists.

---

**Task 1.4: Establish Visual Theme (Colors & Fonts)**
    *   **Agent Task 1.4.1:**
        *   Instruction: "Create a new Swift file named `AppColors.swift` inside `AirFit/Core/Theme/`."
        *   Details: Define app-specific colors using SwiftUI's `Color`. Refer to Design Spec v1.2 for "clean, classy, premium" feel (e.g., muted, sophisticated palette with an accent color). Define placeholders for now; specific hex values to be provided by human designer/product owner.
            ```swift
            // AirFit/Core/Theme/AppColors.swift
            import SwiftUI

            struct AppColors {
                // Primary Palette
                static let backgroundPrimary = Color("BackgroundPrimary") // Define in Assets.xcassets
                static let textPrimary = Color("TextPrimary")
                static let textSecondary = Color("TextSecondary")
                static let accentColor = Color("AccentColor")

                // UI Elements
                static let cardBackground = Color("CardBackground")
                static let shadowColor = Color.black.opacity(0.1) // Example

                // Semantic Colors (Optional, for consistency)
                static let errorColor = Color.red // Example
                static let successColor = Color.green // Example
                static let warningColor = Color.orange // Example

                // Gradients (for Macro Rings, etc.)
                static let caloriesGradient = LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green]), startPoint: .top, endPoint: .bottom) // Example
                static let proteinGradient = LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.8), Color.cyan]), startPoint: .top, endPoint: .bottom) // Example
                static let carbsGradient = LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.orange]), startPoint: .top, endPoint: .bottom) // Example
                static let fatGradient = LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.purple]), startPoint: .top, endPoint: .bottom) // Example
            }
            ```
        *   Acceptance Criteria: `AppColors.swift` exists with color definitions.
    *   **Agent Task 1.4.2:**
        *   Instruction: "Add placeholder Color Sets to `Assets.xcassets` for the custom colors defined in `AppColors.swift` (e.g., 'BackgroundPrimary', 'TextPrimary', 'AccentColor', 'CardBackground')."
        *   Details: For each custom named color, create a New Color Set in `Assets.xcassets`. Use placeholder color values (e.g., system blue, system gray). Define Appearances (Any, Dark) if dark mode will have distinct shades.
        *   Acceptance Criteria: `Assets.xcassets` contains the specified Color Sets.
    *   **Agent Task 1.4.3:**
        *   Instruction: "Create a new Swift file named `AppFonts.swift` inside `AirFit/Core/Theme/`."
        *   Details: Define custom font styles or helper methods for applying fonts. Placeholder: System font with various weights. Specific custom font names to be provided by human designer/product owner if applicable.
            ```swift
            // AirFit/Core/Theme/AppFonts.swift
            import SwiftUI

            struct AppFonts {
                // Example using system fonts, replace with custom font names if provided
                // static let customFontNameRegular = "YourCustomFont-Regular"
                // static let customFontNameBold = "YourCustomFont-Bold"

                static func primaryTitle(size: CGFloat = 28) -> Font {
                    // Font.custom(customFontNameBold, size: size)
                    .system(size: size, weight: .bold, design: .default) // Placeholder
                }

                static func primaryBody(size: CGFloat = 17) -> Font {
                    // Font.custom(customFontNameRegular, size: size)
                    .system(size: size, weight: .regular, design: .default) // Placeholder
                }

                static func secondaryBody(size: CGFloat = 15) -> Font {
                    // Font.custom(customFontNameRegular, size: size)
                    .system(size: size, weight: .light, design: .default) // Placeholder
                }
                // Add other font styles as needed (e.g., caption, button text)
            }

            // Optional: Extension for easier application in SwiftUI views
            extension Text {
                func appFont(_ style: (CGFloat) -> Font, size: CGFloat? = nil) -> Text {
                    if let specificSize = size {
                        return self.font(style(specificSize))
                    }
                    // Infer size if not provided, or use a default from the style
                    // This part might need more sophisticated logic or stricter style definitions
                    return self.font(style(17)) // Example default
                }
            }
            ```
        *   Acceptance Criteria: `AppFonts.swift` exists with font definitions/helpers.
    *   **Agent Task 1.4.4 (Human Task if custom fonts are used):**
        *   Instruction: "If custom fonts are specified, add the font files (e.g., `.ttf`, `.otf`) to the project and ensure they are included in the target's 'Copy Bundle Resources' build phase and listed in the `Info.plist` under 'Fonts provided by application'."
        *   Acceptance Criteria: Custom fonts render correctly in the app.

---

**Task 1.5: Integrate and Configure Code Styling Tools**
    *   **Agent Task 1.5.1 (SwiftLint):**
        *   Instruction: "Integrate SwiftLint into the project using Swift Package Manager (SPM) or CocoaPods/Homebrew (SPM preferred if agent supports configuration)."
        *   Details: If SPM: Add `github "realm/SwiftLint"` as a package dependency. Add a "Run Script Phase" to the "Build Phases" of the `AirFit` iOS and WatchOS targets: `"${BUILD_TOOL_PLUGINS_PATH}/SwiftLintPlugin/swiftlint" --fix && "${BUILD_TOOL_PLUGINS_PATH}/SwiftLintPlugin/swiftlint" lint` (or similar, depending on plugin version).
        *   Acceptance Criteria: SwiftLint runs during the build process.
    *   **Agent Task 1.5.2 (SwiftLint Configuration):**
        *   Instruction: "Create a `.swiftlint.yml` file in the project's root directory."
        *   Details: Configure SwiftLint rules. Start with a sensible default set, disabling overly strict or controversial rules. Emphasize rules that promote readability and consistency as per Apple's API Design Guidelines.
            ```yaml
            # .swiftlint.yml (Example - expand significantly)
            disabled_rules:
              - trailing_whitespace # Often handled by auto-formatters
              - line_length # Can be debated, set a reasonable limit if enabled (e.g., 160)
              - identifier_name # Can be too strict with short, common variable names
              - force_cast
              - force_try
            opt_in_rules:
              - empty_count
              - explicit_init
              - overridden_super_call
              - private_outlet
              - nimble_operator # If using Nimble for testing
              - prohibited_super_call
              - fatal_error_message
              - first_where
              # Add more opt-in rules that enforce good practices
            included: # Paths to include for linting
              - AirFit
            excluded: # Paths to exclude from linting
              - Pods
              - Carthage
              - AirFit/Tests # Or configure specific test rules
            # Rule Configurations (Examples)
            colon:
              flexible_right_spacing: true
            comma:
              flexible_spacing: true # Based on Swift 5.7+ formatting.
            cyclomatic_complexity:
              warning: 15
              error: 25
            file_length:
              warning: 500
              error: 800
            function_body_length:
              warning: 60
              error: 100
            type_body_length:
              warning: 300
              error: 500
            reporter: "xcode" # Integrates with Xcode issues
            ```
        *   Acceptance Criteria: `.swiftlint.yml` exists. SwiftLint uses this configuration. Build warnings/errors appear for violations.
    *   **Agent Task 1.5.3 (SwiftFormat - Optional but Recommended):**
        *   Instruction: "Integrate SwiftFormat into the project (e.g., as a Git pre-commit hook or build phase script)."
        *   Details: SwiftFormat auto-formats code. If using as a build phase: `if which swiftformat >/dev/null; then swiftformat .; else echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"; fi`.
        *   Create a `.swiftformat` rules file in the root directory if customization is needed (e.g., `--indent 4`, `--wraparguments beforefirst`).
        *   Acceptance Criteria: SwiftFormat can be run on the codebase to enforce formatting.

---

**Task 1.6: Create Basic Utility Extensions and Helpers**
    *   **Agent Task 1.6.1:**
        *   Instruction: "Create a new Swift file named `View+Extensions.swift` inside `AirFit/Core/Extensions/`."
        *   Details: Add common SwiftUI `View` extensions.
            ```swift
            // AirFit/Core/Extensions/View+Extensions.swift
            import SwiftUI

            extension View {
                func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
                    clipShape(RoundedCorner(radius: radius, corners: corners))
                }

                // Example for a common padding style
                func standardPadding() -> some View {
                    self.padding(AppConstants.defaultPadding)
                }
            }

            struct RoundedCorner: Shape {
                var radius: CGFloat = .infinity
                var corners: UIRectCorner = .allCorners

                func path(in rect: CGRect) -> Path {
                    let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
                    return Path(path.cgPath)
                }
            }
            ```
        *   Acceptance Criteria: `View+Extensions.swift` exists with useful extensions.
    *   **Agent Task 1.6.2:**
        *   Instruction: "Create other useful extension files as needed in `AirFit/Core/Extensions/`, e.g., `String+Extensions.swift`, `Date+Extensions.swift`. Populate with 1-2 genuinely useful, app-agnostic extensions for now."
        *   Example (`String+Extensions.swift`):
            ```swift
            // AirFit/Core/Extensions/String+Extensions.swift
            import Foundation

            extension String {
                var isBlank: Bool {
                    return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
            }
            ```
        *   Acceptance Criteria: Files created with basic, useful extensions.

---

**Task 1.7: Setup Basic Logging Mechanism**
    *   **Agent Task 1.7.1:**
        *   Instruction: "Create a new Swift file named `AppLogger.swift` inside `AirFit/Core/Utilities/`."
        *   Details: Implement a simple wrapper around `OSLog` or `print` (for early dev) to allow for categorized and easily searchable logging.
            ```swift
            // AirFit/Core/Utilities/AppLogger.swift
            import Foundation
            import os.log // Use os.log for better performance and filtering

            struct AppLogger {
                private static let subsystem = Bundle.main.bundleIdentifier ?? "com.example.airfit"

                enum LogCategory: String {
                    case general = "General"
                    case ui = "UI"
                    case data = "Data"
                    case healthKit = "HealthKit"
                    case network = "Network"
                    case ai = "AI"
                    case onboarding = "Onboarding"
                    // Add more categories as needed
                }

                private static func getOSLog(category: LogCategory) -> OSLog {
                    return OSLog(subsystem: subsystem, category: category.rawValue)
                }

                static func log(_ message: String, category: LogCategory = .general, level: OSLogType = .default, file: String = #file, function: String = #function, line: Int = #line) {
                    #if DEBUG // Only log in DEBUG builds, or use a more sophisticated check
                    let fileName = (file as NSString).lastPathComponent
                    let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
                    os_log("%{public}@", log: getOSLog(category: category), type: level, logMessage)
                    // For very early dev, can also use print:
                    // print("\(Date()) [\(category.rawValue)] \(logMessage)")
                    #endif
                }

                static func error(_ message: String, category: LogCategory = .general, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
                    #if DEBUG
                    let fileName = (file as NSString).lastPathComponent
                    var logMessage = "[\(fileName):\(line)] \(function) - ERROR: \(message)"
                    if let error = error {
                        logMessage += "\nError Details: \(error.localizedDescription)"
                    }
                    os_log("%{public}@", log: getOSLog(category: category), type: .error, logMessage)
                    #endif
                }
            }
            ```
        *   Acceptance Criteria: `AppLogger.swift` exists and provides static methods for logging.

---

**Task 1.8: Commit Changes**
    *   **Agent Task 1.8.1:**
        *   Instruction: "Stage all new and modified files from Tasks 1.1 to 1.7."
        *   Acceptance Criteria: `git status` shows all relevant files staged.
    *   **Agent Task 1.8.2:**
        *   Instruction: "Commit the staged changes with a descriptive message."
        *   Details: Commit message: "Feat: Setup core project structure, theme, utilities, and linting".
        *   Acceptance Criteria: Git history shows the new commit. Project builds successfully.

---

**4. Acceptance Criteria for Module Completion**

*   A new Xcode project "AirFit" is created and configured for both iOS and WatchOS (SwiftUI, Swift).
*   The project has a well-defined directory structure as specified.
*   Core constants, theme colors, and font styles/helpers are implemented and accessible.
*   SwiftLint is integrated and configured with a `.swiftlint.yml` file.
*   SwiftFormat (optional) is integrated or available for use.
*   Basic utility extensions and a logging mechanism are in place.
*   All setup work is committed to a Git repository with a clean history.
*   The project builds without errors or new SwiftLint violations on both iOS and WatchOS targets.

**5. Code Style Reminders for this Module**

*   Adhere strictly to instructions for file names and locations.
*   Use clear, descriptive names for constants, structs, and enums.
*   Ensure all generated Swift code passes SwiftLint checks based on the provided `.swiftlint.yml`.
*   Comments should explain placeholders or areas requiring human input (e.g., specific color hex values, API keys).

---

This sub-document provides a detailed "recipe" for setting up the project. The next sub-document would build upon this foundation, for example, by defining the Data Layer models.
