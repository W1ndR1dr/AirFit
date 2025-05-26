# SwiftLint Violations Fix Guide

## Overview
This document provides exact instructions for fixing all 101 SwiftLint violations in the AirFit project. Each fix is documented with the specific file, line, and required change.

## Configuration Issues (Fixed)
✅ **RESOLVED**: Updated `.swiftlint.yml` with proper configuration

## File-Level Violations

### 1. File Name Violations
**Rule**: `file_name` - File name should match a type declared in the file

#### Fix Required:
- `AirFit/Core/Enums/GlobalEnums.swift` → Rename to `BiologicalSex.swift` (primary type)
- `AirFit/Core/Views/CommonComponents.swift` → Rename to `SectionHeader.swift` (primary type)

### 2. File Types Order Violations  
**Rule**: `file_types_order` - Types should be ordered: supporting_type, main_type, extension

#### Files to Fix:
1. **DependencyContainer.swift** - Move protocol above class
2. **View+Extensions.swift** - Reorder extension and struct
3. **GlobalEnums.swift** - Reorder enum declarations
4. **KeychainWrapper.swift** - Move KeychainError enum above class
5. **AppShadows.swift** - Move ShadowStyle enum above struct
6. **APIConstants.swift** - Move nested enums above properties
7. **ViewModelProtocol.swift** - Reorder protocol and extensions
8. **CommonComponents.swift** - Reorder struct declarations
9. **AirFitApp.swift** - Move AppState class below main struct
10. **NetworkClient.swift** - Move protocol above class

### 3. Type Contents Order Violations
**Rule**: `type_contents_order` - Type contents should follow specific order

#### Order Required:
1. case
2. associated_type  
3. type_alias
4. subtype
5. type_property
6. instance_property
7. ib_outlet
8. ib_inspectable
9. initializer
10. type_method
11. view_life_cycle_method
12. ib_action
13. other_method
14. subscript
15. deinitializer

#### Files to Fix:
1. **AppConstants.swift** - Move static properties after nested enums
2. **APIConstants.swift** - Move static properties after nested enums
3. **Validators.swift** - Move static methods after nested enums
4. **Formatters.swift** - Move static properties and methods after nested enums
5. **String+Extensions.swift** - Reorder computed properties and methods
6. **Date+Extensions.swift** - Reorder methods
7. **CommonComponents.swift** - Move initializers after properties
8. **AirFitApp.swift** - Move init after properties
9. **NetworkClient.swift** - Reorder initializer and methods

### 4. Indentation Width Violations
**Rule**: `indentation_width` - Code should use 4 spaces

#### Files to Fix:
1. **KeychainWrapper.swift:46** - Fix indentation
2. **MockNetworkClient.swift:124** - Fix indentation  
3. **NetworkClient.swift:42,50,75,101** - Fix indentation

### 5. Identifier Name Violations
**Rule**: `identifier_name` - Variable names should be 2+ characters

#### Files to Fix:
1. **AppShadows.swift:67,68** - Variables `x`, `y` (ALLOWED in config)
2. **Color+Extensions.swift:11** - Variables `a`, `r`, `g`, `b` (ALLOWED in config)

### 6. Pattern Matching Keywords Violations
**Rule**: `pattern_matching_keywords` - Move keywords out of tuples

#### Files to Fix:
1. **AppError.swift:23** - Fix pattern matching in switch case

### 7. Attributes Violations
**Rule**: `attributes` - Attributes should be on correct lines

#### Files to Fix:
1. **CoreSetupTests.swift** - Move `@Test` attributes to separate lines (12 instances)
2. **FormattersTests.swift** - Move `@Test` attributes to separate lines (3 instances)
3. **AppConstantsTests.swift** - Move `@Test` attributes to separate lines (2 instances)
4. **AirFitApp.swift:8** - Move `@Environment` to separate line

### 8. Other Violations
1. **AirFitUITestsLaunchTests.swift:11** - Change `class` to `static`
2. **MockAIAPIService.swift:6** - Reduce tuple size (max 2 members)
3. **AirFitUITests.swift:20** - Remove empty XCTest method

## Exact Fix Commands

### File Renames
```bash
# Rename files to match primary types
mv "AirFit/Core/Enums/GlobalEnums.swift" "AirFit/Core/Enums/BiologicalSex.swift"
mv "AirFit/Core/Views/CommonComponents.swift" "AirFit/Core/Views/SectionHeader.swift"
```

### Pattern Fixes for Type Contents Order

#### AppConstants.swift
```swift
enum AppConstants {
    // MARK: - Nested Types (FIRST)
    enum Layout { ... }
    enum Animation { ... }
    enum API { ... }
    enum Storage { ... }
    enum Health { ... }
    enum Validation { ... }
    
    // MARK: - Static Properties (AFTER nested types)
    static let appName = "AirFit"
    static let appVersion = ...
    static let buildNumber = ...
}
```

#### Test Files - Attribute Fixes
```swift
// WRONG:
@Test func testSomething() { ... }

// CORRECT:
@Test
func testSomething() { ... }
```

#### Indentation Fixes
All indentation should use exactly 4 spaces, no tabs.

## Verification Commands

```bash
# Run SwiftLint to verify fixes
swiftlint --strict

# Should show 0 violations when complete
echo "Expected: 0 violations"
```

## Priority Order for Fixes

1. **HIGH PRIORITY** - File renames (breaks imports)
2. **HIGH PRIORITY** - Type contents order (affects readability)
3. **MEDIUM PRIORITY** - File types order (organizational)
4. **LOW PRIORITY** - Indentation and attributes (cosmetic)

## Success Criteria
- ✅ SwiftLint runs with 0 violations
- ✅ Project builds successfully
- ✅ All tests pass
- ✅ No breaking changes to public APIs

## Notes for OpenAI Codex Agent
- Make changes incrementally and test after each file
- Preserve all functionality - only change organization/formatting
- Update import statements if files are renamed
- Maintain all existing comments and documentation
- Follow the exact type contents order specified above 