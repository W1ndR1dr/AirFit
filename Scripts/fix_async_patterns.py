#!/usr/bin/env python3
"""
Fix async/await patterns in test files according to TEST_STANDARDS.md
- Remove await from super.setUp() and super.tearDown() calls
- These XCTestCase methods are NOT async in Swift 6
"""

import os
import re
import sys

def fix_async_patterns(file_path):
    """Fix async patterns in a single file."""
    changes_made = False
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Fix setUp pattern
        # Match: try await super.setUp()
        content = re.sub(
            r'try\s+await\s+super\.setUp\(\)',
            'try super.setUp()',
            content
        )
        
        # Fix tearDown pattern
        # Match: try await super.tearDown()
        content = re.sub(
            r'try\s+await\s+super\.tearDown\(\)',
            'try super.tearDown()',
            content
        )
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            changes_made = True
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False
    
    return changes_made

def main():
    """Find and fix all test files with async pattern issues."""
    test_dir = "AirFit/AirFitTests"
    fixed_count = 0
    
    print("🔧 Fixing async/await patterns in test files...")
    print("Pattern: Remove 'await' from super.setUp() and super.tearDown()")
    print()
    
    for root, dirs, files in os.walk(test_dir):
        for file in files:
            if file.endswith('.swift') and 'Tests' in file:
                file_path = os.path.join(root, file)
                
                # Check if file has the pattern we want to fix
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                if 'try await super.setUp()' in content or 'try await super.tearDown()' in content:
                    if fix_async_patterns(file_path):
                        print(f"✅ Fixed: {file_path}")
                        fixed_count += 1
    
    print()
    print(f"📊 Summary: Fixed {fixed_count} files")
    
    # Verify no patterns remain
    print("\n🔍 Verifying fixes...")
    remaining_setup = os.popen(f'grep -r "try await super\.setUp\(\)" {test_dir} | wc -l').read().strip()
    remaining_teardown = os.popen(f'grep -r "try await super\.tearDown\(\)" {test_dir} | wc -l').read().strip()
    
    print(f"Remaining 'try await super.setUp()': {remaining_setup}")
    print(f"Remaining 'try await super.tearDown()': {remaining_teardown}")
    
    if remaining_setup == '0' and remaining_teardown == '0':
        print("\n✅ All async patterns fixed successfully!")
    else:
        print("\n⚠️  Some patterns may still remain. Please check manually.")

if __name__ == "__main__":
    main()