# AirFit Project File Management Guide

## Overview

This document explains how files are managed in the AirFit project using XcodeGen and provides workflows to prevent file inclusion issues.

## Project Structure

### Targets

Our `project.yml` defines 3 targets:

1. **AirFit** - Main application target
2. **AirFitTests** - Unit test target  
3. **AirFitUITests** - UI test target

### XcodeGen File Inclusion Approach

**Current Strategy**: Hybrid approach using both glob patterns and explicit file listing

**Why**: While `**/*.swift` should theoretically include all Swift files recursively, we explicitly list files in critical areas (Modules, Tests) to ensure:
- Clear documentation of what's included
- Easier debugging when files are missing
- Explicit control over file organization
- No ambiguity about which files belong to which target

## File Inclusion Rules

### AirFit Target (Main App)

```yaml
sources:
  - path: AirFit
    includes: ["**/*.swift"]
    excludes: ["**/*.md", "**/.*", "AirFitTests/**", "AirFitUITests/**"]
  # EXPLICIT FILES (due to XcodeGen nesting bug):
  - AirFit/Modules/Onboarding/Models/OnboardingModels.swift
  - AirFit/Modules/Onboarding/ViewModels/OnboardingViewModel.swift
  # ... (all module files listed explicitly)
```

**What's Included Automatically**:
- All `.swift` files in `AirFit/` root
- Files in `AirFit/Core/`, `AirFit/Data/`, `AirFit/Services/`, `AirFit/Application/`

**What Must Be Listed Explicitly**:
- All files in `AirFit/Modules/*/` subdirectories
- Any new nested directory structures

### AirFitTests Target

```yaml
sources:
  - path: AirFit/AirFitTests
    includes: ["**/*.swift"]
  # EXPLICIT TEST FILES:
  - AirFit/AirFitTests/Onboarding/OnboardingServiceTests.swift
  - AirFit/AirFitTests/Onboarding/OnboardingFlowViewTests.swift
  - AirFit/AirFitTests/Onboarding/OnboardingViewTests.swift
```

**What's Included Automatically**:
- All `.swift` files directly in `AirFit/AirFitTests/`
- Files in immediate subdirectories like `AirFit/AirFitTests/Core/`

**What Must Be Listed Explicitly**:
- Files in nested test directories like `AirFit/AirFitTests/Onboarding/`

### AirFitUITests Target

```yaml
sources:
  - path: AirFit/AirFitUITests
    includes: ["**/*.swift"]
```

**What's Included Automatically**:
- All `.swift` files in `AirFit/AirFitUITests/` and subdirectories
- UI tests generally don't have deep nesting, so glob works fine

## Test File Management

### Critical for Test Refactoring

When working on test files:

1. **Deleting test files**: 
   - Remove from project.yml FIRST
   - Then delete the file
   - Run `xcodegen generate`
   - Commit both changes together

2. **Creating new test files**:
   - Create file in correct location (mirror source structure)
   - Add to project.yml immediately
   - Run `xcodegen generate` 
   - Verify with build before writing tests

3. **Moving/Renaming test files**:
   - Update project.yml with new path/name
   - Move/rename the actual file
   - Run `xcodegen generate`
   - Clean build folder: `xcodebuild clean`

### Test File Naming Convention
```
Source: AirFit/Modules/Dashboard/ViewModels/DashboardViewModel.swift
Test:   AirFit/AirFitTests/Modules/Dashboard/ViewModels/DashboardViewModelTests.swift

Source: AirFit/Services/AI/AIService.swift  
Test:   AirFit/AirFitTests/Services/AI/AIServiceTests.swift
```

## Workflows

### Adding New Module Files

1. **Create the file** in appropriate directory:
   ```
   AirFit/Modules/YourModule/Models/YourModuleModels.swift
   ```

2. **Add to project.yml** under AirFit target sources:
   ```yaml
   - AirFit/Modules/YourModule/Models/YourModuleModels.swift
   - AirFit/Modules/YourModule/ViewModels/YourModuleViewModel.swift
   - AirFit/Modules/YourModule/Views/YourModuleFlowView.swift
   # ... list ALL files in the module
   ```

3. **Regenerate project**:
   ```bash
   xcodegen generate
   ```

4. **Verify inclusion**:
   ```bash
   grep -c "YourModuleModels" AirFit.xcodeproj/project.pbxproj
   # Should return > 0
   ```

### Adding New Test Files

1. **Create the test file**:
   ```
   AirFit/AirFitTests/YourModule/YourModuleTests.swift
   ```

2. **Add to project.yml** under AirFitTests target sources:
   ```yaml
   - AirFit/AirFitTests/YourModule/YourModuleTests.swift
   ```

3. **Regenerate and verify** (same as above)

### Verification Scripts

#### Check All Module Files
```bash
find AirFit/Modules/YourModule -name "*.swift" | while read file; do
  filename=$(basename "$file")
  count=$(grep -c "$filename" AirFit.xcodeproj/project.pbxproj)
  echo "$filename: $count"
  if [ $count -eq 0 ]; then echo "❌ MISSING: $file"; fi
done
```

#### Check All Test Files
```bash
find AirFit/AirFitTests/YourModule -name "*.swift" | while read file; do
  filename=$(basename "$file")
  count=$(grep -c "$filename" AirFit.xcodeproj/project.pbxproj)
  echo "$filename: $count"
  if [ $count -eq 0 ]; then echo "❌ MISSING: $file"; fi
done
```

#### Verify Build
```bash
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
echo "✅ Build Status: $?"
```

## Templates

### Module File Template
```yaml
# Add to AirFit target sources in project.yml:
- AirFit/Modules/{ModuleName}/Models/{ModuleName}Models.swift
- AirFit/Modules/{ModuleName}/ViewModels/{ModuleName}ViewModel.swift
- AirFit/Modules/{ModuleName}/Views/{ModuleName}FlowView.swift
- AirFit/Modules/{ModuleName}/Views/{Feature}View.swift
- AirFit/Modules/{ModuleName}/Services/{ModuleName}Service.swift
- AirFit/Modules/{ModuleName}/Services/{ModuleName}ServiceProtocol.swift
```

### Test File Template
```yaml
# Add to AirFitTests target sources in project.yml:
- AirFit/AirFitTests/{ModuleName}/{ModuleName}ServiceTests.swift
- AirFit/AirFitTests/{ModuleName}/{ModuleName}ViewModelTests.swift
- AirFit/AirFitTests/{ModuleName}/{ModuleName}ViewTests.swift
```

## Troubleshooting

### File Not Found During Build
1. Check if file exists: `ls AirFit/Modules/YourModule/YourFile.swift`
2. Check if included in project: `grep -c "YourFile" AirFit.xcodeproj/project.pbxproj`
3. If count is 0, add to `project.yml` and regenerate

### Build Succeeds But File Changes Not Reflected
1. Clean build: `xcodebuild clean`
2. Regenerate project: `xcodegen generate`
3. Build again: `xcodebuild build`

### Test File Not Running
1. Verify test file is in AirFitTests target
2. Check test file naming convention: `*Tests.swift`
3. Ensure test class inherits from `XCTestCase`
4. Verify test methods start with `test_`

## Best Practices

1. **Always verify file inclusion** after adding new files
2. **Use the verification scripts** before committing
3. **Add files to project.yml immediately** after creating them
4. **Test the build** after adding new files
5. **Keep project.yml organized** with clear comments
6. **Follow the module structure** consistently

## Important Notes

### XcodeGen Version
- Using XcodeGen 2.38.0 or later
- The nesting bug affects all versions as of 2025-01-07

### When to Update project.yml
1. **Creating new files** - Add immediately before running xcodegen
2. **Moving files** - Update paths in project.yml first
3. **Deleting files** - Remove from project.yml and regenerate
4. **Renaming files** - Update in project.yml to match new name

### Common Mistakes to Avoid
1. **Forgetting nested directories** - Module files won't be included
2. **Not regenerating** - Changes won't take effect
3. **Typos in paths** - File won't be found during build
4. **Wrong target** - Test files in main target or vice versa

## Quick Reference

```bash
# After ANY file change:
xcodegen generate

# Verify all module files included:
find AirFit/Modules -name "*.swift" | while read f; do
  grep -q "$(basename "$f")" AirFit.xcodeproj/project.pbxproj || echo "❌ Missing: $f"
done

# Clean and rebuild:
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'
```

This guide ensures no files are missed and builds remain stable as we add new modules. 