# Duplicate File Dependency Analysis Strategy

## Overview
This document provides a systematic approach for identifying and safely removing duplicate files in the AirFit codebase.

## Current Status

### Confirmed Duplicates in project.yml
1. **ConversationSession.swift** - Listed twice at lines 101 and 106
2. **ConversationResponse.swift** - Listed twice at lines 100 and 107

### Analysis Results
- ✅ **No actual file duplicates found** - Only project.yml has duplicate entries
- ✅ **All Swift files have unique names** across the codebase
- ⚠️ **project.yml needs cleanup** to remove duplicate entries

## Dependency Analysis Strategy

### 1. Import Analysis
Search for all imports and references to identify dependencies:

```bash
# Find all imports of a specific file
rg "import.*ConversationSession" --type swift
rg "ConversationSession\." --type swift  # Direct references
rg ": ConversationSession" --type swift  # Type annotations

# Find all files importing from a module
rg "^import (AirFit|Data|Services|Modules)" --type swift | sort | uniq -c
```

### 2. Git History Analysis
Check creation date, modification history, and authorship:

```bash
# Check file history
git log --follow --oneline -- "path/to/file.swift"

# Check first commit (creation date)
git log --reverse --oneline -- "path/to/file.swift" | head -1

# Check last modification
git log -1 --format="%ai %s" -- "path/to/file.swift"

# Compare two files' histories
git log --oneline --graph -- file1.swift file2.swift
```

### 3. Content Comparison
Compare file contents for differences:

```bash
# Direct diff
diff -u file1.swift file2.swift

# Show side-by-side comparison
diff -y file1.swift file2.swift

# Check if files are identical
cmp -s file1.swift file2.swift && echo "Files are identical"

# Get MD5 hash for comparison
md5 file1.swift file2.swift
```

### 4. Test Coverage Analysis
Identify which tests depend on which files:

```bash
# Find tests that import the file
rg "import.*FileName" AirFit/AirFitTests --type swift
rg "@testable import" AirFit/AirFitTests --type swift

# Find test files for a specific module
find AirFit/AirFitTests -name "*ConversationSession*Test*.swift"
```

### 5. Build System Analysis
Check project configuration and build dependencies:

```bash
# Check project.yml for file references
rg "ConversationSession.swift" project.yml

# Check for conditional compilation
rg "#if|#endif" file.swift

# Verify build after changes
xcodegen generate
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Step-by-Step Removal Process

### Phase 1: Analysis
1. Run all dependency checks above
2. Document all imports and references
3. Create dependency graph
4. Identify safe removal candidates

### Phase 2: Preparation
1. Create feature branch: `git checkout -b cleanup/remove-duplicates`
2. Run full test suite to establish baseline
3. Document current build time and test results

### Phase 3: Removal
1. Remove duplicate from project.yml
2. Run `xcodegen generate`
3. Build project to verify no errors
4. Run test suite to ensure no regressions

### Phase 4: Validation
1. Run integration tests
2. Check UI functionality
3. Verify no runtime errors
4. Run performance tests

### Phase 5: Cleanup
1. Update documentation
2. Commit changes with detailed message
3. Create PR with analysis results

## Automation Script

Create a script to automate duplicate detection:

```bash
#!/bin/bash
# duplicate_finder.sh

echo "=== Finding Duplicate Files ==="

# Find duplicate filenames
echo -e "\n--- Duplicate Swift Files ---"
find . -name "*.swift" -type f | grep -v node_modules | grep -v build | \
    sed 's|.*/||' | sort | uniq -c | grep -v "^ *1 "

# Find duplicate entries in project.yml
echo -e "\n--- Duplicate project.yml Entries ---"
sort project.yml | uniq -c | grep -v "^ *1 " | grep -v "^$"

# Find potentially moved files
echo -e "\n--- Files in Multiple Locations ---"
for file in $(find . -name "*.swift" -type f | sed 's|.*/||' | sort | uniq); do
    count=$(find . -name "$file" -type f | wc -l)
    if [ $count -gt 1 ]; then
        echo "$file appears $count times:"
        find . -name "$file" -type f
    fi
done
```

## Specific Analysis: ConversationSession & ConversationResponse

### Current Status
- **Location**: `/Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/`
- **project.yml**: Duplicate entries at lines 100-101 and 106-107
- **Action Required**: Remove duplicate entries from project.yml

### Dependencies Found
```bash
# Will be populated by running analysis commands
```

### Recommendation
1. Remove duplicate entries from project.yml (lines 106-107)
2. Keep entries at lines 100-101
3. Run `xcodegen generate` after cleanup
4. Verify build succeeds

## Prevention Strategies

### 1. Pre-commit Hooks
Add git hook to check for duplicates:

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check for duplicate entries in project.yml
duplicates=$(sort project.yml | uniq -c | grep -v "^ *1 " | grep -v "^$")
if [ ! -z "$duplicates" ]; then
    echo "ERROR: Duplicate entries found in project.yml:"
    echo "$duplicates"
    exit 1
fi
```

### 2. CI/CD Checks
Add GitHub Action to verify no duplicates:

```yaml
- name: Check for duplicates
  run: |
    ./Scripts/check_duplicates.sh
```

### 3. Code Review Checklist
- [ ] No duplicate files in different locations
- [ ] No duplicate entries in project.yml
- [ ] All imports use correct paths
- [ ] Tests updated for any moves/renames

## Next Steps

1. **Immediate**: Fix project.yml duplicate entries
2. **Short-term**: Run full dependency analysis
3. **Long-term**: Implement prevention strategies

## Commands for ConversationSession/Response Cleanup

```bash
# 1. Backup current state
cp project.yml project.yml.backup

# 2. Check current imports
rg "ConversationSession|ConversationResponse" --type swift -B 1 -A 1

# 3. Remove duplicates from project.yml
# Manual edit to remove lines 106-107

# 4. Regenerate project
xcodegen generate

# 5. Verify build
xcodebuild clean build -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# 6. Run tests
swift test --filter AirFitTests
```