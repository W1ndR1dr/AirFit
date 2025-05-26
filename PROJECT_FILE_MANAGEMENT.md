# AirFit Project File Management Guide

## Overview

This document explains how files are managed in the AirFit project using XcodeGen and provides workflows to prevent file inclusion issues.

## Project Structure

### Targets

Our `project.yml` defines 3 targets:

1. **AirFit** - Main application target
2. **AirFitTests** - Unit test target  
3. **AirFitUITests** - UI test target

### XcodeGen Nesting Bug

**Critical Issue**: XcodeGen's `**/*.swift` glob pattern fails for nested directories like `AirFit/Modules/*/`

**Root Cause**: XcodeGen doesn't properly expand glob patterns in nested module structures

**Solution**: Explicitly list ALL files in nested directories in `project.yml`

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

## Current Status

### Module 3 (Onboarding) - ✅ Complete
- **Implementation Files**: 15 files, all included
- **Test Files**: 6 files, all included  
- **Build Status**: ✅ Passing
- **Test Coverage**: ~85%

### Verification Results
```
OnboardingViewModel.swift: 4
OnboardingModels.swift: 4
OnboardingService.swift: 8
OnboardingServiceProtocol.swift: 4
OnboardingServiceTests.swift: 4
OnboardingFlowViewTests.swift: 4
OnboardingViewTests.swift: 4
# All files properly included ✅
```

This guide ensures no files are missed and builds remain stable as we add new modules. 