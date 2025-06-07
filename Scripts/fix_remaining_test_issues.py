#!/usr/bin/env python3

import os
import re

def fix_test_file(file_path):
    """Fix remaining test file issues"""
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Fix nested do-catch blocks
    content = re.sub(
        r'do \{\s*do \{([^}]*)\} catch \{([^}]*)\}\s*([^}]*)\} catch \{',
        r'do {\1} catch {',
        content,
        flags=re.DOTALL
    )
    
    # Fix try statements without do-catch in setUp
    def fix_try_without_do(match):
        indent = match.group(1)
        statement = match.group(2)
        
        # Skip if already in do-catch
        if 'do {' in match.group(0):
            return match.group(0)
        
        # Check if this is a ModelContainer creation
        if 'ModelContainer' in statement:
            return f'{indent}do {{\n{indent}    {statement}\n{indent}}} catch {{\n{indent}    XCTFail("Failed to create container: \\(error)")\n{indent}    return\n{indent}}}'
        else:
            return f'{indent}do {{\n{indent}    {statement}\n{indent}}} catch {{\n{indent}    XCTFail("Failed: \\(error)")\n{indent}}}'
    
    # Fix try statements in setUp that aren't wrapped
    content = re.sub(
        r'^(\s+)(let \w+ = try (?:ModelContainer|.+Container)\.[^\n]+)$',
        fix_try_without_do,
        content,
        flags=re.MULTILINE
    )
    
    # Fix double blank lines from edits
    content = re.sub(r'\n\n\n+', '\n\n', content)
    
    # Fix trailing whitespace
    content = re.sub(r' +\n', '\n', content)
    
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    test_dir = "AirFit/AirFitTests"
    fixed_count = 0
    
    problem_files = [
        "AirFit/AirFitTests/Modules/Settings/SettingsViewModelTests.swift",
        "AirFit/AirFitTests/Data/UserModelTests.swift",
        "AirFit/AirFitTests/Integration/OnboardingFlowTests.swift",
        "AirFit/AirFitTests/Modules/Onboarding/OnboardingServiceTests.swift",
        "AirFit/AirFitTests/Modules/Onboarding/OnboardingViewModelTests.swift",
        "AirFit/AirFitTests/Integration/OnboardingIntegrationTests.swift",
        "AirFit/AirFitTests/Integration/OnboardingErrorRecoveryTests.swift",
        "AirFit/AirFitTests/Services/Context/ContextAssemblerTests.swift"
    ]
    
    for file_path in problem_files:
        if os.path.exists(file_path):
            if fix_test_file(file_path):
                print(f"✓ Fixed: {file_path}")
                fixed_count += 1
    
    print(f"\nFixed {fixed_count} test files")

if __name__ == "__main__":
    os.chdir("/Users/Brian/Coding Projects/AirFit")
    main()