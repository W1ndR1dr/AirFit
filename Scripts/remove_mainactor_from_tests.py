#!/usr/bin/env python3

import os
import re

def remove_mainactor_from_test_class(file_path):
    """Remove @MainActor from test class and add to individual test methods if needed"""
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Remove @MainActor from the class declaration
    content = re.sub(
        r'@MainActor\s*\nfinal class (\w+Tests?): XCTestCase',
        r'final class \1: XCTestCase',
        content
    )
    
    # Add @MainActor to test methods that access UI or need main actor
    def add_mainactor_to_test(match):
        indent = match.group(1)
        func_decl = match.group(2)
        
        # Skip setUp and tearDown
        if 'setUp' in func_decl or 'tearDown' in func_decl:
            return match.group(0)
        
        # Add @MainActor if the test needs it (contains async or accesses UI)
        if 'async' in func_decl or 'await' in match.group(0):
            return f'{indent}@MainActor\n{indent}{func_decl}'
        
        return match.group(0)
    
    content = re.sub(
        r'^(\s+)(func test\w+[^\{]+\{)',
        add_mainactor_to_test,
        content,
        flags=re.MULTILINE
    )
    
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    test_dir = "AirFit/AirFitTests"
    fixed_count = 0
    
    # Find all test files with @MainActor
    for root, dirs, files in os.walk(test_dir):
        for file in files:
            if file.endswith('.swift') and 'Test' in file:
                file_path = os.path.join(root, file)
                
                # Check if file has @MainActor on class
                with open(file_path, 'r') as f:
                    content = f.read()
                    if '@MainActor\s*\nfinal class' in content or '@MainActor\s*\s*\nfinal class' in content:
                        if remove_mainactor_from_test_class(file_path):
                            print(f"✓ Fixed: {file_path}")
                            fixed_count += 1
    
    print(f"\nFixed {fixed_count} test files")

if __name__ == "__main__":
    os.chdir("/Users/Brian/Coding Projects/AirFit")
    main()