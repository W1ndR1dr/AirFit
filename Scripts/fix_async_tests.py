#!/usr/bin/env python3

import os
import re
import sys

def fix_async_setup_teardown(file_path):
    """Fix async setUp/tearDown in test files with @MainActor"""
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Check if the class has @MainActor
    has_mainactor_class = bool(re.search(r'@MainActor\s*\nfinal class \w+Tests?:', content))
    
    # Check if individual methods have @MainActor
    has_mainactor_methods = bool(re.search(r'@MainActor\s*\n\s*override func setUp\(\)', content))
    
    # If no @MainActor on class but has it on methods, add it to class
    if not has_mainactor_class and has_mainactor_methods:
        content = re.sub(
            r'(import.*\n)(\s*)(final class \w+Tests?:)',
            r'\1\2@MainActor\n\2\3',
            content
        )
        has_mainactor_class = True
    
    if has_mainactor_class:
        # Remove @MainActor from individual setUp/tearDown methods
        content = re.sub(r'@MainActor\s*\n(\s*)override func setUp\(\)', r'\1override func setUp()', content)
        content = re.sub(r'@MainActor\s*\n(\s*)override func tearDown\(\)', r'\1override func tearDown()', content)
        
        # Fix async setUp
        content = re.sub(
            r'override func setUp\(\) async throws \{',
            'override func setUp() {',
            content
        )
        
        # Fix super.setUp() calls
        content = re.sub(
            r'try await super\.setUp\(\)',
            'super.setUp()',
            content
        )
        
        # Fix async tearDown
        content = re.sub(
            r'override func tearDown\(\) async throws \{',
            'override func tearDown() {',
            content
        )
        
        # Fix super.tearDown() calls
        content = re.sub(
            r'try await super\.tearDown\(\)',
            'super.tearDown()',
            content
        )
        
        # Handle ModelContainer creation in setUp
        if 'ModelContainer.createTestContainer()' in content:
            # Find setUp method and wrap ModelContainer creation in do-catch
            def replace_model_container(match):
                indent = match.group(1)
                container_line = match.group(2)
                
                # If it's already in a do-catch, skip
                if 'do {' in match.group(0):
                    return match.group(0)
                
                return f'{indent}do {{\n{indent}    {container_line}\n{indent}}} catch {{\n{indent}    XCTFail("Failed to create test container: \\(error)")\n{indent}    return\n{indent}}}'
            
            content = re.sub(
                r'(\s+)(.*= try ModelContainer\.createTestContainer\(\).*)',
                replace_model_container,
                content
            )
        
        # Handle try modelContext.save() outside of do-catch blocks
        def wrap_context_save(match):
            indent = match.group(1)
            save_line = match.group(2)
            
            # Check if this is already in a do-catch block
            lines_before = content[:match.start()].split('\n')
            for i in range(len(lines_before) - 1, max(0, len(lines_before) - 5), -1):
                if 'do {' in lines_before[i]:
                    return match.group(0)  # Already in do-catch
            
            return f'{indent}do {{\n{indent}    {save_line}\n{indent}}} catch {{\n{indent}    XCTFail("Failed to save test context: \\(error)")\n{indent}}}'
        
        content = re.sub(
            r'(\s+)(try modelContext\.save\(\))',
            wrap_context_save,
            content
        )
    
    # Remove @MainActor from individual test methods if class has @MainActor
    if has_mainactor_class:
        content = re.sub(r'@MainActor\s*\n(\s*)func test', r'\1func test', content)
    
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    test_dir = "AirFit/AirFitTests"
    fixed_count = 0
    
    for root, dirs, files in os.walk(test_dir):
        for file in files:
            if file.endswith('.swift') and 'Test' in file:
                file_path = os.path.join(root, file)
                if fix_async_setup_teardown(file_path):
                    print(f"✓ Fixed: {file_path}")
                    fixed_count += 1
    
    print(f"\nFixed {fixed_count} test files")

if __name__ == "__main__":
    os.chdir("/Users/Brian/Coding Projects/AirFit")
    main()