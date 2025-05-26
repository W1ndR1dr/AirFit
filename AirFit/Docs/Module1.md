**Modular Sub-Document 1: Core Project Setup & Configuration**

**Version:** 2.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Date:** May 25, 2025
**Updated For:** iOS 18+, macOS 15+, Xcode 16+, Swift 6+

**1. Module Overview**

*   **Purpose:** To establish the foundational structure, configurations, and core utilities for the AirFit iOS application. This module ensures a consistent development environment, coding style, and provides essential shared resources optimized for Swift 6 concurrency and iOS 18 features.
*   **Responsibilities:**
    *   Setting up the Xcode project with Swift 6 and iOS 18 configuration
    *   Defining comprehensive project directory structure
    *   Implementing global constants and type-safe enumerations
    *   Establishing the visual theme with complete color and font systems
    *   Integrating and configuring SwiftLint with comprehensive rules
    *   Creating essential utility extensions with Swift 6 features
    *   Setting up structured logging with OSLog
    *   Configuring Git with proper ignore patterns
*   **Key Components:**
    *   Xcode Project (`.xcodeproj`) with iOS 18 minimum deployment
    *   Complete directory structure matching module organization
    *   `AppConstants.swift` with all global constants
    *   Complete theme system (colors, fonts, spacing)
    *   `.swiftlint.yml` with 100+ configured rules
    *   Comprehensive utility extensions
    *   `AppLogger.swift` with category-based logging

**2. Dependencies**

*   **Inputs:**
    *   macOS 15+ with Xcode 16+ installed
    *   Swift 6+ toolchain
    *   SwiftLint 0.54.0+ via Homebrew
*   **Outputs:**
    *   Fully configured Xcode project ready for feature development
    *   Foundation for all subsequent modules

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 1.0: Initialize Git Repository**

**Agent Task 1.0.1: Create Git Repository**
- Instruction: "Initialize Git repository with comprehensive .gitignore"
- Commands:
  ```bash
  git init
  touch .gitignore
  ```
- Required `.gitignore` content:
  ```gitignore
  # Xcode
  build/
  DerivedData/
  *.pbxuser
  !default.pbxuser
  *.mode1v3
  !default.mode1v3
  *.mode2v3
  !default.mode2v3
  *.perspectivev3
  !default.perspectivev3
  xcuserdata/
  *.xccheckout
  *.moved-aside
  *.xcuserstate
  *.xcscmblueprint
  *.xcscheme
  
  # Swift Package Manager
  .build/
  .swiftpm/
  Package.resolved
  
  # CocoaPods (if used later)
  Pods/
  *.xcworkspace
  
  # Carthage (if used later)
  Carthage/Build/
  
  # macOS
  .DS_Store
  *.swp
  *~.nib
  
  # Secrets
  *.plist.secret
  Config.xcconfig
  
  # Test Coverage
  *.xcresult
  coverage/
  
  # Fastlane
  fastlane/report.xml
  fastlane/Preview.html
  fastlane/screenshots
  fastlane/test_output
  
  # Code Injection
  iOSInjectionProject/
  ```
- Acceptance Criteria: 
  - `.git` directory exists
  - `.gitignore` contains all patterns
  - Initial commit completed

---

**Task 1.1: Create Xcode Project**

**Agent Task 1.1.1: Create iOS App Project**
- Instruction: "Create new Xcode project with iOS 18 configuration"
- Project Settings:
  - Product Name: `AirFit`
  - Team: None (placeholder)
  - Organization Identifier: `com.airfit`
  - Bundle Identifier: `com.airfit.app`
  - Interface: SwiftUI
  - Language: Swift
  - Use Core Data: No
  - Include Tests: Yes
  - Storage: None (will use SwiftData)
- Build Settings to Configure:
  ```
  IPHONEOS_DEPLOYMENT_TARGET = 18.0
  SWIFT_VERSION = 6.0
  SWIFT_STRICT_CONCURRENCY = complete
  SWIFT_UPCOMING_FEATURE_CONCISE_MAGIC_FILE = YES
  SWIFT_UPCOMING_FEATURE_FORWARD_TRAILING_CLOSURES = YES
  SWIFT_UPCOMING_FEATURE_BARE_SLASH_REGEX_LITERALS = YES
  SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY = YES
  ENABLE_USER_SCRIPT_SANDBOXING = YES
  ENABLE_MODULE_VERIFIER = YES
  ```
- Info.plist additions:
  ```xml
  <key>UILaunchScreen</key>
  <dict/>
  <key>ITSAppUsesNonExemptEncryption</key>
  <false/>
  <key>NSCameraUsageDescription</key>
  <string>AirFit uses the camera to scan food barcodes and take meal photos.</string>
  <key>NSHealthShareUsageDescription</key>
  <string>AirFit reads health data to provide personalized nutrition recommendations.</string>
  <key>NSHealthUpdateUsageDescription</key>
  <string>AirFit saves nutrition data to Apple Health.</string>
  ```
- Acceptance Criteria:
  - Project builds without errors
  - Deployment target is iOS 18.0
  - Swift 6 with strict concurrency enabled

---

**Task 1.2: Create Complete Directory Structure**

**Agent Task 1.2.1: Create Directory Hierarchy**
- Instruction: "Create comprehensive directory structure for modular architecture"
- Required Structure:
  ```
  AirFit/
  ├── Application/
  │   ├── AirFitApp.swift
  │   └── Info.plist
  ├── Core/
  │   ├── Constants/
  │   │   ├── AppConstants.swift
  │   │   └── APIConstants.swift
  │   ├── Enums/
  │   │   ├── GlobalEnums.swift
  │   │   └── AppError.swift
  │   ├── Extensions/
  │   │   ├── View+Extensions.swift
  │   │   ├── String+Extensions.swift
  │   │   ├── Date+Extensions.swift
  │   │   ├── Double+Extensions.swift
  │   │   └── Color+Extensions.swift
  │   ├── Protocols/
  │   │   └── ViewModelProtocol.swift
  │   ├── Theme/
  │   │   ├── AppColors.swift
  │   │   ├── AppFonts.swift
  │   │   ├── AppSpacing.swift
  │   │   └── AppShadows.swift
  │   └── Utilities/
  │       ├── AppLogger.swift
  │       ├── Formatters.swift
  │       └── Validators.swift
  ├── Data/
  │   ├── Models/
  │   ├── Repositories/
  │   └── SwiftData/
  ├── Modules/
  │   ├── Dashboard/
  │   ├── MealLogging/
  │   ├── Onboarding/
  │   ├── Progress/
  │   └── Settings/
  ├── Services/
  │   ├── Network/
  │   ├── AI/
  │   ├── Health/
  │   └── Storage/
  ├── Resources/
  │   ├── Assets.xcassets/
  │   ├── Localizable.strings
  │   └── LaunchScreen.storyboard
  └── Preview Content/
      └── Preview Assets.xcassets/
  ```
- Script to create directories:
  ```bash
  #!/bin/bash
  dirs=(
    "Application"
    "Core/Constants" "Core/Enums" "Core/Extensions" 
    "Core/Protocols" "Core/Theme" "Core/Utilities"
    "Data/Models" "Data/Repositories" "Data/SwiftData"
    "Modules/Dashboard/Views" "Modules/Dashboard/ViewModels" "Modules/Dashboard/Services"
    "Modules/MealLogging/Views" "Modules/MealLogging/ViewModels" "Modules/MealLogging/Services"
    "Modules/Onboarding/Views" "Modules/Onboarding/ViewModels" "Modules/Onboarding/Services"
    "Modules/Progress/Views" "Modules/Progress/ViewModels" "Modules/Progress/Services"
    "Modules/Settings/Views" "Modules/Settings/ViewModels" "Modules/Settings/Services"
    "Services/Network" "Services/AI" "Services/Health" "Services/Storage"
    "Resources" "Preview Content"
  )
  
  for dir in "${dirs[@]}"; do
    mkdir -p "AirFit/$dir"
  done
  ```
- Acceptance Criteria:
  - All directories exist in filesystem
  - Xcode groups match directory structure
  - No compiler warnings about missing directories

---

**Task 1.3: Implement Core Constants and Enums**

**Agent Task 1.3.1: Create AppConstants.swift**
- File: `AirFit/Core/Constants/AppConstants.swift`
- Complete Implementation:
  ```swift
  import Foundation
  import SwiftUI
  
  enum AppConstants {
      // MARK: - App Info
      static let appName = "AirFit"
      static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
      static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
      
      // MARK: - Layout
      enum Layout {
          static let defaultPadding: CGFloat = 16
          static let smallPadding: CGFloat = 8
          static let largePadding: CGFloat = 24
          static let defaultCornerRadius: CGFloat = 12
          static let smallCornerRadius: CGFloat = 8
          static let largeCornerRadius: CGFloat = 20
          static let defaultSpacing: CGFloat = 12
      }
      
      // MARK: - Animation
      enum Animation {
          static let defaultDuration: Double = 0.3
          static let shortDuration: Double = 0.2
          static let longDuration: Double = 0.5
          static let springResponse: Double = 0.5
          static let springDamping: Double = 0.8
      }
      
      // MARK: - Networking
      enum API {
          static let timeoutInterval: TimeInterval = 30
          static let maxRetryAttempts = 3
          static let retryDelay: TimeInterval = 2
      }
      
      // MARK: - Storage
      enum Storage {
          static let userDefaultsSuiteName = "group.com.airfit.app"
          static let keychainServiceName = "com.airfit.app"
          static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
      }
      
      // MARK: - Health
      enum Health {
          static let maxDaysToSync = 30
          static let updateInterval: TimeInterval = 3600 // 1 hour
      }
      
      // MARK: - Validation
      enum Validation {
          static let minPasswordLength = 8
          static let maxPasswordLength = 128
          static let minAge = 13
          static let maxAge = 120
          static let minWeight: Double = 20 // kg
          static let maxWeight: Double = 300 // kg
          static let minHeight: Double = 50 // cm
          static let maxHeight: Double = 300 // cm
      }
  }
  ```

**Agent Task 1.3.2: Create GlobalEnums.swift**
- File: `AirFit/Core/Enums/GlobalEnums.swift`
- Complete Implementation:
  ```swift
  import Foundation
  
  // MARK: - User Related
  enum BiologicalSex: String, Codable, CaseIterable, Sendable {
      case male = "male"
      case female = "female"
      case other = "other"
      
      var displayName: String {
          switch self {
          case .male: return "Male"
          case .female: return "Female"
          case .other: return "Other"
          }
      }
  }
  
  enum ActivityLevel: String, Codable, CaseIterable, Sendable {
      case sedentary = "sedentary"
      case lightlyActive = "lightly_active"
      case moderate = "moderate"
      case veryActive = "very_active"
      case extreme = "extreme"
      
      var displayName: String {
          switch self {
          case .sedentary: return "Sedentary"
          case .lightlyActive: return "Lightly Active"
          case .moderate: return "Moderately Active"
          case .veryActive: return "Very Active"
          case .extreme: return "Extremely Active"
          }
      }
      
      var multiplier: Double {
          switch self {
          case .sedentary: return 1.2
          case .lightlyActive: return 1.375
          case .moderate: return 1.55
          case .veryActive: return 1.725
          case .extreme: return 1.9
          }
      }
  }
  
  enum FitnessGoal: String, Codable, CaseIterable, Sendable {
      case loseWeight = "lose_weight"
      case maintainWeight = "maintain_weight"
      case gainMuscle = "gain_muscle"
      
      var displayName: String {
          switch self {
          case .loseWeight: return "Lose Weight"
          case .maintainWeight: return "Maintain Weight"
          case .gainMuscle: return "Build Muscle"
          }
      }
      
      var calorieAdjustment: Double {
          switch self {
          case .loseWeight: return -500
          case .maintainWeight: return 0
          case .gainMuscle: return 300
          }
      }
  }
  
  // MARK: - App State
  enum LoadingState: Equatable, Sendable {
      case idle
      case loading
      case loaded
      case error(Error)
      
      static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
          switch (lhs, rhs) {
          case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
              return true
          case (.error(let lhsError), .error(let rhsError)):
              return lhsError.localizedDescription == rhsError.localizedDescription
          default:
              return false
          }
      }
  }
  
  // MARK: - Navigation
  enum AppTab: String, CaseIterable, Sendable {
      case dashboard
      case meals
      case discover
      case progress
      case settings
      
      var systemImage: String {
          switch self {
          case .dashboard: return "house.fill"
          case .meals: return "fork.knife"
          case .discover: return "magnifyingglass"
          case .progress: return "chart.line.uptrend.xyaxis"
          case .settings: return "gearshape.fill"
          }
      }
  }
  ```

**Agent Task 1.3.3: Create AppError.swift**
- File: `AirFit/Core/Enums/AppError.swift`
- Implementation:
  ```swift
  import Foundation
  
  enum AppError: LocalizedError, Sendable {
      case networkError(underlying: Error)
      case decodingError(underlying: Error)
      case validationError(message: String)
      case unauthorized
      case serverError(code: Int, message: String?)
      case unknown(message: String)
      case healthKitNotAuthorized
      case cameraNotAuthorized
      
      var errorDescription: String? {
          switch self {
          case .networkError(let error):
              return "Network error: \(error.localizedDescription)"
          case .decodingError:
              return "Unable to process server response"
          case .validationError(let message):
              return message
          case .unauthorized:
              return "Please log in to continue"
          case .serverError(let code, let message):
              return message ?? "Server error (Code: \(code))"
          case .unknown(let message):
              return message
          case .healthKitNotAuthorized:
              return "Health access is required for this feature"
          case .cameraNotAuthorized:
              return "Camera access is required to scan barcodes"
          }
      }
      
      var recoverySuggestion: String? {
          switch self {
          case .networkError:
              return "Please check your internet connection and try again"
          case .decodingError:
              return "Please try updating the app"
          case .unauthorized:
              return "Tap here to log in"
          case .healthKitNotAuthorized:
              return "Grant access in Settings > Privacy > Health"
          case .cameraNotAuthorized:
              return "Grant access in Settings > Privacy > Camera"
          default:
              return nil
          }
      }
  }
  ```

---

**Task 1.4: Establish Complete Visual Theme**

**Agent Task 1.4.1: Create AppColors.swift**
- File: `AirFit/Core/Theme/AppColors.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  struct AppColors {
      // MARK: - Background Colors
      static let backgroundPrimary = Color("BackgroundPrimary")
      static let backgroundSecondary = Color("BackgroundSecondary")
      static let backgroundTertiary = Color("BackgroundTertiary")
      
      // MARK: - Text Colors
      static let textPrimary = Color("TextPrimary")
      static let textSecondary = Color("TextSecondary")
      static let textTertiary = Color("TextTertiary")
      static let textOnAccent = Color("TextOnAccent")
      
      // MARK: - UI Elements
      static let cardBackground = Color("CardBackground")
      static let dividerColor = Color("DividerColor")
      static let shadowColor = Color.black.opacity(0.1)
      static let overlayColor = Color.black.opacity(0.4)
      
      // MARK: - Interactive Elements
      static let buttonBackground = Color("ButtonBackground")
      static let buttonText = Color("ButtonText")
      static let accentColor = Color("AccentColor")
      static let accentSecondary = Color("AccentSecondary")
      
      // MARK: - Semantic Colors
      static let errorColor = Color("ErrorColor")
      static let successColor = Color("SuccessColor")
      static let warningColor = Color("WarningColor")
      static let infoColor = Color("InfoColor")
      
      // MARK: - Nutrition Colors (Macro Rings)
      static let caloriesColor = Color("CaloriesColor")
      static let proteinColor = Color("ProteinColor")
      static let carbsColor = Color("CarbsColor")
      static let fatColor = Color("FatColor")
      
      // MARK: - Gradients
      static let primaryGradient = LinearGradient(
          colors: [accentColor, accentSecondary],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
      )
      
      static let caloriesGradient = LinearGradient(
          colors: [caloriesColor.opacity(0.8), caloriesColor],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
      )
      
      static let proteinGradient = LinearGradient(
          colors: [proteinColor.opacity(0.8), proteinColor],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
      )
      
      static let carbsGradient = LinearGradient(
          colors: [carbsColor.opacity(0.8), carbsColor],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
      )
      
      static let fatGradient = LinearGradient(
          colors: [fatColor.opacity(0.8), fatColor],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
      )
  }
  ```

**Agent Task 1.4.2: Create Color Sets in Assets.xcassets**
- Required Color Sets with hex values:
  ```
  BackgroundPrimary: Light=#FFFFFF, Dark=#000000
  BackgroundSecondary: Light=#F2F2F7, Dark=#1C1C1E
  BackgroundTertiary: Light=#FFFFFF, Dark=#2C2C2E
  
  TextPrimary: Light=#000000, Dark=#FFFFFF
  TextSecondary: Light=#3C3C43, Dark=#EBEBF5
  TextTertiary: Light=#C7C7CC, Dark=#48484A
  TextOnAccent: Any=#FFFFFF
  
  CardBackground: Light=#FFFFFF, Dark=#1C1C1E
  DividerColor: Light=#E5E5EA, Dark=#38383A
  
  ButtonBackground: Light=#007AFF, Dark=#0A84FF
  ButtonText: Any=#FFFFFF
  AccentColor: Light=#007AFF, Dark=#0A84FF
  AccentSecondary: Light=#5856D6, Dark=#5E5CE6
  
  ErrorColor: Light=#FF3B30, Dark=#FF453A
  SuccessColor: Light=#34C759, Dark=#32D74B
  WarningColor: Light=#FF9500, Dark=#FF9F0A
  InfoColor: Light=#007AFF, Dark=#0A84FF
  
  CaloriesColor: Any=#FF6B6B
  ProteinColor: Any=#4ECDC4
  CarbsColor: Any=#FFD93D
  FatColor: Any=#95E1D3
  ```

**Agent Task 1.4.3: Create AppFonts.swift**
- File: `AirFit/Core/Theme/AppFonts.swift`
- Implementation:
  ```swift
  import SwiftUI
  
  struct AppFonts {
      // MARK: - Font Sizes
      private enum Size {
          static let largeTitle: CGFloat = 34
          static let title: CGFloat = 28
          static let title2: CGFloat = 22
          static let title3: CGFloat = 20
          static let headline: CGFloat = 17
          static let body: CGFloat = 17
          static let callout: CGFloat = 16
          static let subheadline: CGFloat = 15
          static let footnote: CGFloat = 13
          static let caption: CGFloat = 12
          static let caption2: CGFloat = 11
      }
      
      // MARK: - Title Fonts
      static let largeTitle = Font.system(size: Size.largeTitle, weight: .bold, design: .rounded)
      static let title = Font.system(size: Size.title, weight: .bold, design: .rounded)
      static let title2 = Font.system(size: Size.title2, weight: .semibold, design: .rounded)
      static let title3 = Font.system(size: Size.title3, weight: .semibold, design: .rounded)
      
      // MARK: - Body Fonts
      static let headline = Font.system(size: Size.headline, weight: .semibold, design: .default)
      static let body = Font.system(size: Size.body, weight: .regular, design: .default)
      static let bodyBold = Font.system(size: Size.body, weight: .semibold, design: .default)
      static let callout = Font.system(size: Size.callout, weight: .regular, design: .default)
      static let subheadline = Font.system(size: Size.subheadline, weight: .regular, design: .default)
      
      // MARK: - Small Fonts
      static let footnote = Font.system(size: Size.footnote, weight: .regular, design: .default)
      static let caption = Font.system(size: Size.caption, weight: .regular, design: .default)
      static let captionBold = Font.system(size: Size.caption, weight: .medium, design: .default)
      static let caption2 = Font.system(size: Size.caption2, weight: .regular, design: .default)
      
      // MARK: - Numeric Fonts
      static let numberLarge = Font.system(size: Size.title, weight: .bold, design: .rounded)
      static let numberMedium = Font.system(size: Size.title3, weight: .semibold, design: .rounded)
      static let numberSmall = Font.system(size: Size.body, weight: .medium, design: .rounded)
  }
  
  // MARK: - Text Extensions
  extension Text {
      func appFont(_ font: Font) -> Text {
          self.font(font)
      }
      
      func primaryTitle() -> Text {
          self.font(AppFonts.title)
              .foregroundColor(AppColors.textPrimary)
      }
      
      func secondaryBody() -> Text {
          self.font(AppFonts.body)
              .foregroundColor(AppColors.textSecondary)
      }
  }
  ```

**Agent Task 1.4.4: Create AppSpacing.swift**
- File: `AirFit/Core/Theme/AppSpacing.swift`
- Implementation:
  ```swift
  import SwiftUI
  
  enum AppSpacing {
      /// 4pt
      static let xxSmall: CGFloat = 4
      /// 8pt
      static let xSmall: CGFloat = 8
      /// 12pt
      static let small: CGFloat = 12
      /// 16pt
      static let medium: CGFloat = 16
      /// 24pt
      static let large: CGFloat = 24
      /// 32pt
      static let xLarge: CGFloat = 32
      /// 48pt
      static let xxLarge: CGFloat = 48
  }
  ```

---

**Task 1.5: Configure SwiftLint**

**Agent Task 1.5.1: Install SwiftLint**
- Instruction: "Add SwiftLint build phase to both targets"
- Build Phase Script:
  ```bash
  if [[ "$(uname -m)" == arm64 ]]; then
      export PATH="/opt/homebrew/bin:$PATH"
  fi
  
  if which swiftlint >/dev/null; then
      swiftlint --fix && swiftlint
  else
      echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
  ```

**Agent Task 1.5.2: Create .swiftlint.yml**
- File: `.swiftlint.yml` (at project root)
- Complete Configuration:
  ```yaml
  # SwiftLint configuration for AirFit
  # Updated for Swift 6 and SwiftLint 0.54.0+
  
  disabled_rules:
    - line_length # Will be opt-in with specific configuration
    - trailing_whitespace # Handled by formatter
    - todo # We want to allow TODOs during development
  
  opt_in_rules:
    # Clarity
    - attributes
    - closure_end_indentation
    - closure_spacing
    - collection_alignment
    - contains_over_filter_count
    - contains_over_filter_is_empty
    - contains_over_first_not_nil
    - contains_over_range_nil_comparison
    - empty_collection_literal
    - empty_count
    - empty_string
    - empty_xctest_method
    - explicit_init
    - first_where
    - flatmap_over_map_reduce
    - identical_operands
    - joined_default_parameter
    - last_where
    - legacy_multiple
    - legacy_random
    - literal_expression_end_indentation
    - lower_acl_than_parent
    - modifier_order
    - nimble_operator
    - nslocalizedstring_key
    - number_separator
    - operator_usage_whitespace
    - overridden_super_call
    - override_in_extension
    - pattern_matching_keywords
    - prefer_self_type_over_type_of_self
    - private_action
    - private_outlet
    - prohibited_super_call
    - quick_discouraged_call
    - quick_discouraged_focused_test
    - quick_discouraged_pending_test
    - reduce_into
    - redundant_nil_coalescing
    - redundant_type_annotation
    - single_test_class
    - sorted_first_last
    - static_operator
    - strong_iboutlet
    - toggle_bool
    - unavailable_function
    - unneeded_parentheses_in_closure_argument
    - untyped_error_in_catch
    - vertical_parameter_alignment_on_call
    - xct_specific_matcher
    - yoda_condition
    
    # Force unwrapping
    - force_unwrapping
    - implicitly_unwrapped_optional
    
    # String
    - string_literal_at_end_of_multiline_literal
    
    # Metrics
    - explicit_type_interface
    - file_name
    - file_types_order
    - indentation_width
    - multiline_arguments
    - multiline_function_chains
    - multiline_literal_brackets
    - multiline_parameters
    - multiline_parameters_brackets
    - no_space_in_method_call
    - optional_enum_case_matching
    - prefer_self_in_static_references
    - prefer_zero_over_explicit_init
    - prefixed_toplevel_constant
    - raw_value_for_camel_cased_codable_enum
    - sorted_imports
    - trailing_closure
    - type_contents_order
    - unused_declaration
    - unused_import
    - vertical_whitespace_closing_braces
    - vertical_whitespace_opening_braces
  
  analyzer_rules:
    - unused_import
    - unused_declaration
  
  included:
    - AirFit
  
  excluded:
    - Carthage
    - Pods
    - .build
    - .swiftpm
    - AirFit/Resources/Generated
  
  # Rule configurations
  line_length:
    warning: 120
    error: 150
    ignores_urls: true
    ignores_function_declarations: true
    ignores_comments: true
  
  type_body_length:
    warning: 300
    error: 500
  
  file_length:
    warning: 500
    error: 800
    ignore_comment_only_lines: true
  
  function_body_length:
    warning: 50
    error: 100
  
  function_parameter_count:
    warning: 6
    error: 8
  
  cyclomatic_complexity:
    warning: 15
    error: 25
  
  nesting:
    type_level:
      warning: 2
      error: 3
    function_level:
      warning: 3
      error: 5
  
  identifier_name:
    min_length:
      warning: 2
      error: 1
    max_length:
      warning: 50
      error: 60
    validates_start_with_lowercase: true
    allowed_symbols: ["_"]
    excludes:
      - id
      - URL
      - AI
  
  type_name:
    min_length:
      warning: 3
      error: 1
    max_length:
      warning: 50
      error: 60
  
  trailing_comma:
    mandatory_comma: true
  
  vertical_whitespace:
    max_empty_lines: 2
  
  custom_rules:
    no_print:
      name: "No direct print statements"
      regex: '(^|\s)print\('
      message: "Use AppLogger instead of print()"
      severity: warning
    
    no_nslog:
      name: "No NSLog statements"
      regex: '(^|\s)NSLog\('
      message: "Use AppLogger instead of NSLog()"
      severity: error
  
  reporter: "xcode"
  ```

---

**Task 1.6: Shared Utilities & Services**

**Agent Task 1.6.1: Create AppLogger**
- File: `AirFit/Core/Utilities/AppLogger.swift`
- Complete Implementation:
  ```swift
  import Foundation
  import os.log
  
  /// Centralized logging system for the AirFit app
  enum AppLogger {
      // MARK: - Log Categories
      enum Category: String {
          case general = "general"
          case ui = "ui"
          case data = "data"
          case network = "network"
          case healthKit = "healthkit"
          case ai = "ai"
          case voice = "voice"
          case chat = "chat"
          case workout = "workout"
          case nutrition = "nutrition"
          case notification = "notification"
          case performance = "performance"
          
          var logger: Logger {
              Logger(subsystem: "com.airfit.app", category: rawValue)
          }
      }
      
      // MARK: - Logging Methods
      static func debug(_ message: String, category: Category = .general) {
          #if DEBUG
          category.logger.debug("\(message)")
          #endif
      }
      
      static func info(_ message: String, category: Category = .general) {
          category.logger.info("\(message)")
      }
      
      static func notice(_ message: String, category: Category = .general) {
          category.logger.notice("\(message)")
      }
      
      static func warning(_ message: String, category: Category = .general) {
          category.logger.warning("\(message)")
      }
      
      static func error(_ message: String, error: Error? = nil, category: Category = .general) {
          if let error = error {
              category.logger.error("\(message): \(error.localizedDescription)")
          } else {
              category.logger.error("\(message)")
          }
      }
      
      static func fault(_ message: String, error: Error? = nil, category: Category = .general) {
          if let error = error {
              category.logger.fault("\(message): \(error.localizedDescription)")
          } else {
              category.logger.fault("\(message)")
          }
      }
      
      // MARK: - Performance Logging
      static func measureTime<T>(
          operation: String,
          category: Category = .performance,
          block: () throws -> T
      ) rethrows -> T {
          let start = CFAbsoluteTimeGetCurrent()
          defer {
              let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
              info("\(operation) completed in \(String(format: "%.2f", elapsed))ms", category: category)
          }
          return try block()
      }
  }
  ```

**Agent Task 1.6.2: Create HapticManager**
- File: `AirFit/Core/Utilities/HapticManager.swift`
- Complete Implementation:
  ```swift
  import UIKit
  import CoreHaptics
  
  /// Manages haptic feedback throughout the app
  @MainActor
  final class HapticManager {
      // MARK: - Singleton
      static let shared = HapticManager()
      
      // MARK: - Properties
      private var engine: CHHapticEngine?
      private let impactFeedback = UIImpactFeedbackGenerator()
      private let notificationFeedback = UINotificationFeedbackGenerator()
      private let selectionFeedback = UISelectionFeedbackGenerator()
      
      // MARK: - Initialization
      private init() {
          setupHapticEngine()
          prepareGenerators()
      }
      
      private func setupHapticEngine() {
          guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
              AppLogger.info("Device does not support haptics", category: .ui)
              return
          }
          
          do {
              engine = try CHHapticEngine()
              try engine?.start()
              
              // Handle engine reset
              engine?.resetHandler = { [weak self] in
                  Task { @MainActor in
                      do {
                          try self?.engine?.start()
                      } catch {
                          AppLogger.error("Failed to restart haptic engine", error: error, category: .ui)
                      }
                  }
              }
          } catch {
              AppLogger.error("Failed to setup haptic engine", error: error, category: .ui)
          }
      }
      
      private func prepareGenerators() {
          impactFeedback.prepare()
          notificationFeedback.prepare()
          selectionFeedback.prepare()
      }
      
      // MARK: - Public Methods
      
      /// Play impact haptic feedback
      static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
          Task { @MainActor in
              shared.impactFeedback.impactOccurred(intensity: style.intensity)
          }
      }
      
      /// Play notification haptic feedback
      static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
          Task { @MainActor in
              shared.notificationFeedback.notificationOccurred(type)
          }
      }
      
      /// Play selection haptic feedback
      static func selection() {
          Task { @MainActor in
              shared.selectionFeedback.selectionChanged()
          }
      }
  }
  
  // MARK: - Extensions
  private extension UIImpactFeedbackGenerator.FeedbackStyle {
      var intensity: CGFloat {
          switch self {
          case .light: return 0.5
          case .medium: return 0.7
          case .heavy: return 1.0
          case .soft: return 0.4
          case .rigid: return 0.9
          @unknown default: return 0.7
          }
      }
  }
  ```

**Agent Task 1.6.3: Create Common UI Components**
- File: `AirFit/Core/Views/CommonComponents.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  // MARK: - Section Header
  struct SectionHeader: View {
      let title: String
      let icon: String?
      let action: (() -> Void)?
      
      init(title: String, icon: String? = nil, action: (() -> Void)? = nil) {
          self.title = title
          self.icon = icon
          self.action = action
      }
      
      var body: some View {
          HStack {
              if let icon = icon {
                  Image(systemName: icon)
                      .font(.caption)
                      .foregroundStyle(.secondary)
              }
              
              Text(title)
                  .font(.headline)
                  .foregroundStyle(.primary)
              
              Spacer()
              
              if let action = action {
                  Button(action: action) {
                      Image(systemName: "ellipsis")
                          .font(.caption)
                          .foregroundStyle(.secondary)
                  }
              }
          }
      }
  }
  
  // MARK: - Empty State View
  struct EmptyStateView: View {
      let icon: String
      let title: String
      let message: String
      let action: (() -> Void)?
      let actionTitle: String?
      
      init(
          icon: String,
          title: String,
          message: String,
          action: (() -> Void)? = nil,
          actionTitle: String? = nil
      ) {
          self.icon = icon
          self.title = title
          self.message = message
          self.action = action
          self.actionTitle = actionTitle
      }
      
      var body: some View {
          VStack(spacing: AppSpacing.lg) {
              Image(systemName: icon)
                  .font(.system(size: 60))
                  .foregroundStyle(.quaternary)
              
              VStack(spacing: AppSpacing.sm) {
                  Text(title)
                      .font(.headline)
                  
                  Text(message)
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                      .multilineTextAlignment(.center)
              }
              
              if let action = action, let actionTitle = actionTitle {
                  Button(action: action) {
                      Text(actionTitle)
                  }
                  .buttonStyle(.borderedProminent)
                  .controlSize(.large)
              }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
      }
  }
  
  // MARK: - Card View
  struct Card<Content: View>: View {
      let content: () -> Content
      
      init(@ViewBuilder content: @escaping () -> Content) {
          self.content = content
      }
      
      var body: some View {
          content()
              .padding(AppSpacing.md)
              .background(Color.cardBackground)
              .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
              .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
      }
  }
  
  // MARK: - Loading Overlay Modifier
  struct LoadingOverlay: ViewModifier {
      let isLoading: Bool
      let message: String?
      
      func body(content: Content) -> some View {
          ZStack {
              content
                  .disabled(isLoading)
                  .blur(radius: isLoading ? 2 : 0)
              
              if isLoading {
                  VStack(spacing: AppSpacing.md) {
                      ProgressView()
                          .scaleEffect(1.5)
                      
                      if let message = message {
                          Text(message)
                              .font(.callout)
                              .foregroundStyle(.secondary)
                      }
                  }
                  .padding(AppSpacing.xl)
                  .background(.regularMaterial)
                  .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                  .shadow(radius: 10)
              }
          }
          .animation(.easeInOut(duration: 0.2), value: isLoading)
      }
  }
  
  extension View {
      func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
          modifier(LoadingOverlay(isLoading: isLoading, message: message))
      }
  }
  ```

**Note:** The WhisperModelManager has been moved to Core/Services/WhisperModelManager.swift and updated to be a shared singleton that can be used by both Module 8 (Food Tracking) and Module 13 (Chat Interface).

---

**Task 1.7: Setup Comprehensive Logging**

**Agent Task 1.7.1: Create AppLogger.swift**
- File: `AirFit/Core/Utilities/AppLogger.swift`
- Complete Implementation:
  ```swift
  import Foundation
  import os.log
  
  /// Centralized logging system for AirFit
  enum AppLogger {
      // MARK: - Categories
      enum Category: String {
          case general = "General"
          case ui = "UI"
          case data = "Data"
          case network = "Network"
          case health = "HealthKit"
          case ai = "AI"
          case auth = "Authentication"
          case onboarding = "Onboarding"
          case meals = "Meals"
          case performance = "Performance"
          
          var osLog: OSLog {
              OSLog(subsystem: subsystem, category: rawValue)
          }
      }
      
      private static let subsystem = Bundle.main.bundleIdentifier ?? "com.airfit.app"
      
      // MARK: - Logging Methods
      static func debug(
          _ message: String,
          category: Category = .general,
          file: String = #fileID,
          function: String = #function,
          line: Int = #line
      ) {
          #if DEBUG
          log(message, category: category, level: .debug, file: file, function: function, line: line)
          #endif
      }
      
      static func info(
          _ message: String,
          category: Category = .general,
          file: String = #fileID,
          function: String = #function,
          line: Int = #line
      ) {
          log(message, category: category, level: .info, file: file, function: function, line: line)
      }
      
      static func warning(
          _ message: String,
          category: Category = .general,
          file: String = #fileID,
          function: String = #function,
          line: Int = #line
      ) {
          log(message, category: category, level: .default, file: file, function: function, line: line)
      }
      
      static func error(
          _ message: String,
          error: Error? = nil,
          category: Category = .general,
          file: String = #fileID,
          function: String = #function,
          line: Int = #line
      ) {
          var fullMessage = message
          if let error = error {
              fullMessage += "\nError: \(error.localizedDescription)"
              if let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error {
                  fullMessage += "\nUnderlying: \(underlyingError.localizedDescription)"
              }
          }
          log(fullMessage, category: category, level: .error, file: file, function: function, line: line)
      }
      
      static func fault(
          _ message: String,
          category: Category = .general,
          file: String = #fileID,
          function: String = #function,
          line: Int = #line
      ) {
          log(message, category: category, level: .fault, file: file, function: function, line: line)
      }
      
      // MARK: - Private Methods
      private static func log(
          _ message: String,
          category: Category,
          level: OSLogType,
          file: String,
          function: String,
          line: Int
      ) {
          let fileName = (file as NSString).lastPathComponent
          let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
          
          os_log("%{public}@", log: category.osLog, type: level, logMessage)
          
          #if DEBUG
          // Also print to console in debug builds for easier development
          let emoji = emojiForLevel(level)
          let timestamp = Date().formatted(as: .time)
          print("\(emoji) \(timestamp) [\(category.rawValue)] \(logMessage)")
          #endif
      }
      
      private static func emojiForLevel(_ level: OSLogType) -> String {
          switch level {
          case .debug: return "🔍"
          case .info: return "ℹ️"
          case .default: return "⚠️"
          case .error: return "❌"
          case .fault: return "💥"
          default: return "📝"
          }
      }
  }
  
  // MARK: - Performance Logging
  extension AppLogger {
      static func measure<T>(
          _ label: String,
          category: Category = .performance,
          operation: () throws -> T
      ) rethrows -> T {
          let startTime = CFAbsoluteTimeGetCurrent()
          defer {
              let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
              debug("\(label) took \(String(format: "%.2f", timeElapsed))ms", category: category)
          }
          return try operation()
      }
      
      static func measureAsync<T>(
          _ label: String,
          category: Category = .performance,
          operation: () async throws -> T
      ) async rethrows -> T {
          let startTime = CFAbsoluteTimeGetCurrent()
          defer {
              let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
              debug("\(label) took \(String(format: "%.2f", timeElapsed))ms", category: category)
          }
          return try await operation()
      }
  }
  ```

---

**Task 1.8: Create Additional Utilities**

**Agent Task 1.8.1: Create Formatters.swift**
- File: `AirFit/Core/Utilities/Formatters.swift`
- Implementation:
  ```swift
  import Foundation
  
  enum Formatters {
      // MARK: - Number Formatters
      static let integer: NumberFormatter = {
          let formatter = NumberFormatter()
          formatter.numberStyle = .decimal
          formatter.maximumFractionDigits = 0
          return formatter
      }()
      
      static let decimal: NumberFormatter = {
          let formatter = NumberFormatter()
          formatter.numberStyle = .decimal
          formatter.minimumFractionDigits = 1
          formatter.maximumFractionDigits = 1
          return formatter
      }()
      
      static let percentage: NumberFormatter = {
          let formatter = NumberFormatter()
          formatter.numberStyle = .percent
          formatter.minimumFractionDigits = 0
          formatter.maximumFractionDigits = 0
          return formatter
      }()
      
      // MARK: - Date Formatters
      static let shortDate: DateFormatter = {
          let formatter = DateFormatter()
          formatter.dateStyle = .short
          formatter.timeStyle = .none
          return formatter
      }()
      
      static let mediumDate: DateFormatter = {
          let formatter = DateFormatter()
          formatter.dateStyle = .medium
          formatter.timeStyle = .none
          return formatter
      }()
      
      static let time: DateFormatter = {
          let formatter = DateFormatter()
          formatter.dateStyle = .none
          formatter.timeStyle = .short
          return formatter
      }()
      
      // MARK: - Custom Formatters
      static func formatCalories(_ calories: Double) -> String {
          "\(integer.string(from: NSNumber(value: calories)) ?? "0") cal"
      }
      
      static func formatMacro(_ grams: Double, suffix: String = "g") -> String {
          "\(integer.string(from: NSNumber(value: grams)) ?? "0")\(suffix)"
      }
      
      static func formatWeight(_ kilograms: Double, unit: WeightUnit = .metric) -> String {
          switch unit {
          case .metric:
              return "\(decimal.string(from: NSNumber(value: kilograms)) ?? "0") kg"
          case .imperial:
              let pounds = kilograms.kilogramsToPounds
              return "\(decimal.string(from: NSNumber(value: pounds)) ?? "0") lbs"
          }
      }
      
      enum WeightUnit {
          case metric, imperial
      }
  }
  ```

**Agent Task 1.8.2: Create Validators.swift**
- File: `AirFit/Core/Utilities/Validators.swift`
- Implementation:
  ```swift
  import Foundation
  
  enum Validators {
      // MARK: - User Input
      static func validateEmail(_ email: String) -> ValidationResult {
          guard !email.isBlank else {
              return .failure("Email is required")
          }
          guard email.isValidEmail else {
              return .failure("Please enter a valid email address")
          }
          return .success
      }
      
      static func validatePassword(_ password: String) -> ValidationResult {
          guard !password.isBlank else {
              return .failure("Password is required")
          }
          guard password.count >= AppConstants.Validation.minPasswordLength else {
              return .failure("Password must be at least \(AppConstants.Validation.minPasswordLength) characters")
          }
          guard password.count <= AppConstants.Validation.maxPasswordLength else {
              return .failure("Password must be less than \(AppConstants.Validation.maxPasswordLength) characters")
          }
          return .success
      }
      
      static func validateAge(_ age: Int) -> ValidationResult {
          guard age >= AppConstants.Validation.minAge else {
              return .failure("You must be at least \(AppConstants.Validation.minAge) years old")
          }
          guard age <= AppConstants.Validation.maxAge else {
              return .failure("Please enter a valid age")
          }
          return .success
      }
      
      static func validateWeight(_ weight: Double) -> ValidationResult {
          guard weight >= AppConstants.Validation.minWeight else {
              return .failure("Please enter a valid weight")
          }
          guard weight <= AppConstants.Validation.maxWeight else {
              return .failure("Please enter a valid weight")
          }
          return .success
      }
      
      static func validateHeight(_ height: Double) -> ValidationResult {
          guard height >= AppConstants.Validation.minHeight else {
              return .failure("Please enter a valid height")
          }
          guard height <= AppConstants.Validation.maxHeight else {
              return .failure("Please enter a valid height")
          }
          return .success
      }
      
      // MARK: - Result Type
      enum ValidationResult: Equatable {
          case success
          case failure(String)
          
          var isValid: Bool {
              switch self {
              case .success: return true
              case .failure: return false
              }
          }
          
          var errorMessage: String? {
              switch self {
              case .success: return nil
              case .failure(let message): return message
              }
          }
      }
  }
  ```

---

**Task 1.9: Update Main App File**

**Agent Task 1.9.1: Update AirFitApp.swift**
- File: `AirFit/Application/AirFitApp.swift`
- Implementation:
  ```swift
  import SwiftUI
  import SwiftData
  
  @main
  struct AirFitApp: App {
      // MARK: - Properties
      @Environment(\.scenePhase) private var scenePhase
      @StateObject private var appState = AppState()
      
      // MARK: - Initialization
      init() {
          setupAppearance()
          AppLogger.info("AirFit launched", category: .general)
      }
      
      // MARK: - Body
      var body: some Scene {
          WindowGroup {
              ContentView()
                  .environmentObject(appState)
                  .modelContainer(for: [
                      // Add SwiftData models here
                  ])
                  .onAppear {
                      AppLogger.info("Main view appeared", category: .ui)
                  }
          }
          .onChange(of: scenePhase) { _, newPhase in
              handleScenePhaseChange(newPhase)
          }
      }
      
      // MARK: - Private Methods
      private func setupAppearance() {
          // Navigation Bar
          let navAppearance = UINavigationBarAppearance()
          navAppearance.configureWithOpaqueBackground()
          navAppearance.backgroundColor = UIColor(AppColors.backgroundPrimary)
          navAppearance.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]
          navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]
          
          UINavigationBar.appearance().standardAppearance = navAppearance
          UINavigationBar.appearance().compactAppearance = navAppearance
          UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
          
          // Tab Bar
          let tabAppearance = UITabBarAppearance()
          tabAppearance.configureWithOpaqueBackground()
          tabAppearance.backgroundColor = UIColor(AppColors.backgroundPrimary)
          
          UITabBar.appearance().standardAppearance = tabAppearance
          UITabBar.appearance().scrollEdgeAppearance = tabAppearance
      }
      
      private func handleScenePhaseChange(_ phase: ScenePhase) {
          switch phase {
          case .active:
              AppLogger.info("App became active", category: .general)
          case .inactive:
              AppLogger.info("App became inactive", category: .general)
          case .background:
              AppLogger.info("App entered background", category: .general)
          @unknown default:
              break
          }
      }
  }
  
  // MARK: - App State
  class AppState: ObservableObject {
      @Published var isAuthenticated = false
      @Published var hasCompletedOnboarding = false
      @Published var selectedTab: AppTab = .dashboard
      
      init() {
          loadUserState()
      }
      
      private func loadUserState() {
          // Load from UserDefaults or Keychain
      }
  }
  ```

---

**Task 1.10: Commit All Changes**

**Agent Task 1.10.1: Stage and Commit**
- Commands:
  ```bash
  git add .
  git commit -m "Feat: Complete core project setup with Swift 6 and iOS 18 configuration"
  ```

---

**4. Acceptance Criteria for Module Completion**

- ✅ Xcode project created with iOS 18.0 minimum deployment target
- ✅ Swift 6 with strict concurrency checking enabled
- ✅ Complete directory structure matching specification
- ✅ All constants, enums, and error types implemented
- ✅ Complete theme system with colors, fonts, and spacing
- ✅ All color sets created in Assets.xcassets
- ✅ SwiftLint integrated with comprehensive configuration
- ✅ All utility extensions implemented and tested
- ✅ AppLogger with category-based logging functional
- ✅ Additional utilities (Formatters, Validators) implemented
- ✅ Main app file updated with proper configuration
- ✅ Project builds without warnings or SwiftLint violations
- ✅ All changes committed to Git with proper .gitignore

**5. Testing Requirements**

**Unit Tests Required:**
- `AppConstantsTests.swift` - Verify all constants
- `ValidatorsTests.swift` - Test all validation logic
- `FormattersTests.swift` - Test all formatting methods
- `ExtensionTests.swift` - Test all extensions

**6. Module Dependencies**

- **Requires Completion Of:** None (first module)
- **Must Be Completed Before:** All other modules
- **Can Run In Parallel With:** None

**7. Performance Benchmarks**

- App launch time: < 0.5 seconds
- SwiftLint execution: < 2 seconds
- Build time (clean): < 30 seconds

---

This sub-document provides a detailed "recipe" for setting up the project. The next sub-document would build upon this foundation, for example, by defining the Data Layer models.

---

**Task 1.6: Shared Utilities & Services**

**Agent Task 1.6.1: Create AppLogger**
- File: `AirFit/Core/Utilities/AppLogger.swift`
- Complete Implementation:
  ```swift
  import Foundation
  import os.log
  
  /// Centralized logging system for the AirFit app
  enum AppLogger {
      // MARK: - Log Categories
      enum Category: String {
          case general = "general"
          case ui = "ui"
          case data = "data"
          case network = "network"
          case healthKit = "healthkit"
          case ai = "ai"
          case voice = "voice"
          case chat = "chat"
          case workout = "workout"
          case nutrition = "nutrition"
          case notification = "notification"
          case performance = "performance"
          
          var logger: Logger {
              Logger(subsystem: "com.airfit.app", category: rawValue)
          }
      }
      
      // MARK: - Logging Methods
      static func debug(_ message: String, category: Category = .general) {
          #if DEBUG
          category.logger.debug("\(message)")
          #endif
      }
      
      static func info(_ message: String, category: Category = .general) {
          category.logger.info("\(message)")
      }
      
      static func notice(_ message: String, category: Category = .general) {
          category.logger.notice("\(message)")
      }
      
      static func warning(_ message: String, category: Category = .general) {
          category.logger.warning("\(message)")
      }
      
      static func error(_ message: String, error: Error? = nil, category: Category = .general) {
          if let error = error {
              category.logger.error("\(message): \(error.localizedDescription)")
          } else {
              category.logger.error("\(message)")
          }
      }
      
      static func fault(_ message: String, error: Error? = nil, category: Category = .general) {
          if let error = error {
              category.logger.fault("\(message): \(error.localizedDescription)")
          } else {
              category.logger.fault("\(message)")
          }
      }
      
      // MARK: - Performance Logging
      static func measureTime<T>(
          operation: String,
          category: Category = .performance,
          block: () throws -> T
      ) rethrows -> T {
          let start = CFAbsoluteTimeGetCurrent()
          defer {
              let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
              info("\(operation) completed in \(String(format: "%.2f", elapsed))ms", category: category)
          }
          return try block()
      }
  }
  ```

**Agent Task 1.6.2: Create HapticManager**
- File: `AirFit/Core/Utilities/HapticManager.swift`
- Complete Implementation:
  ```swift
  import UIKit
  import CoreHaptics
  
  /// Manages haptic feedback throughout the app
  @MainActor
  final class HapticManager {
      // MARK: - Singleton
      static let shared = HapticManager()
      
      // MARK: - Properties
      private var engine: CHHapticEngine?
      private let impactFeedback = UIImpactFeedbackGenerator()
      private let notificationFeedback = UINotificationFeedbackGenerator()
      private let selectionFeedback = UISelectionFeedbackGenerator()
      
      // MARK: - Initialization
      private init() {
          setupHapticEngine()
          prepareGenerators()
      }
      
      private func setupHapticEngine() {
          guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
              AppLogger.info("Device does not support haptics", category: .ui)
              return
          }
          
          do {
              engine = try CHHapticEngine()
              try engine?.start()
              
              // Handle engine reset
              engine?.resetHandler = { [weak self] in
                  Task { @MainActor in
                      do {
                          try self?.engine?.start()
                      } catch {
                          AppLogger.error("Failed to restart haptic engine", error: error, category: .ui)
                      }
                  }
              }
          } catch {
              AppLogger.error("Failed to setup haptic engine", error: error, category: .ui)
          }
      }
      
      private func prepareGenerators() {
          impactFeedback.prepare()
          notificationFeedback.prepare()
          selectionFeedback.prepare()
      }
      
      // MARK: - Public Methods
      
      /// Play impact haptic feedback
      static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
          Task { @MainActor in
              shared.impactFeedback.impactOccurred(intensity: style.intensity)
          }
      }
      
      /// Play notification haptic feedback
      static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
          Task { @MainActor in
              shared.notificationFeedback.notificationOccurred(type)
          }
      }
      
      /// Play selection haptic feedback
      static func selection() {
          Task { @MainActor in
              shared.selectionFeedback.selectionChanged()
          }
      }
  }
  
  // MARK: - Extensions
  private extension UIImpactFeedbackGenerator.FeedbackStyle {
      var intensity: CGFloat {
          switch self {
          case .light: return 0.5
          case .medium: return 0.7
          case .heavy: return 1.0
          case .soft: return 0.4
          case .rigid: return 0.9
          @unknown default: return 0.7
          }
      }
  }
  ```

**Agent Task 1.6.3: Create Common UI Components**
- File: `AirFit/Core/Views/CommonComponents.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  // MARK: - Section Header
  struct SectionHeader: View {
      let title: String
      let icon: String?
      let action: (() -> Void)?
      
      init(title: String, icon: String? = nil, action: (() -> Void)? = nil) {
          self.title = title
          self.icon = icon
          self.action = action
      }
      
      var body: some View {
          HStack {
              if let icon = icon {
                  Image(systemName: icon)
                      .font(.caption)
                      .foregroundStyle(.secondary)
              }
              
              Text(title)
                  .font(.headline)
                  .foregroundStyle(.primary)
              
              Spacer()
              
              if let action = action {
                  Button(action: action) {
                      Image(systemName: "ellipsis")
                          .font(.caption)
                          .foregroundStyle(.secondary)
                  }
              }
          }
      }
  }
  
  // MARK: - Empty State View
  struct EmptyStateView: View {
      let icon: String
      let title: String
      let message: String
      let action: (() -> Void)?
      let actionTitle: String?
      
      init(
          icon: String,
          title: String,
          message: String,
          action: (() -> Void)? = nil,
          actionTitle: String? = nil
      ) {
          self.icon = icon
          self.title = title
          self.message = message
          self.action = action
          self.actionTitle = actionTitle
      }
      
      var body: some View {
          VStack(spacing: AppSpacing.lg) {
              Image(systemName: icon)
                  .font(.system(size: 60))
                  .foregroundStyle(.quaternary)
              
              VStack(spacing: AppSpacing.sm) {
                  Text(title)
                      .font(.headline)
                  
                  Text(message)
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                      .multilineTextAlignment(.center)
              }
              
              if let action = action, let actionTitle = actionTitle {
                  Button(action: action) {
                      Text(actionTitle)
                  }
                  .buttonStyle(.borderedProminent)
                  .controlSize(.large)
              }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
      }
  }
  
  // MARK: - Card View
  struct Card<Content: View>: View {
      let content: () -> Content
      
      init(@ViewBuilder content: @escaping () -> Content) {
          self.content = content
      }
      
      var body: some View {
          content()
              .padding(AppSpacing.md)
              .background(Color.cardBackground)
              .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
              .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
      }
  }
  
  // MARK: - Loading Overlay Modifier
  struct LoadingOverlay: ViewModifier {
      let isLoading: Bool
      let message: String?
      
      func body(content: Content) -> some View {
          ZStack {
              content
                  .disabled(isLoading)
                  .blur(radius: isLoading ? 2 : 0)
              
              if isLoading {
                  VStack(spacing: AppSpacing.md) {
                      ProgressView()
                          .scaleEffect(1.5)
                      
                      if let message = message {
                          Text(message)
                              .font(.callout)
                              .foregroundStyle(.secondary)
                      }
                  }
                  .padding(AppSpacing.xl)
                  .background(.regularMaterial)
                  .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                  .shadow(radius: 10)
              }
          }
          .animation(.easeInOut(duration: 0.2), value: isLoading)
      }
  }
  
  extension View {
      func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
          modifier(LoadingOverlay(isLoading: isLoading, message: message))
      }
  }
  ```

**Note:** The WhisperModelManager has been moved to Core/Services/WhisperModelManager.swift and updated to be a shared singleton that can be used by both Module 8 (Food Tracking) and Module 13 (Chat Interface).
