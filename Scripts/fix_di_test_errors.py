#!/usr/bin/env python3
"""
Fix DI-related test compilation errors.
Addresses:
1. @MainActor isolation issues
2. Async setUp() method issues
3. Singleton .shared access patterns
"""

import os
import re
import sys
from pathlib import Path

def fix_mainactor_test_class(content):
    """Add @MainActor to test class if it has MainActor-isolated properties."""
    # Check if class uses MainActor-isolated types
    needs_mainactor = any([
        'FoodTrackingViewModel' in content,
        'MockCoachEngine' in content,
        'FoodTrackingCoordinator' in content,
        'DashboardViewModel' in content,
        'ChatViewModel' in content,
        'WorkoutViewModel' in content,
        'SettingsViewModel' in content,
        'ConversationViewModel' in content,
        'OnboardingViewModel' in content,
    ])
    
    if needs_mainactor:
        # Check if class already has @MainActor
        if not re.search(r'@MainActor\s*\n\s*final class \w+Tests?:', content):
            # Add @MainActor to test class
            content = re.sub(
                r'(import.*\n)(\s*)(final class \w+Tests?:)',
                r'\1\2@MainActor\n\2\3',
                content
            )
    
    return content

def fix_async_setup(content):
    """Fix async setUp() methods."""
    # Pattern to match async setUp
    async_setup_pattern = r'override func setUp\(\) async(?: throws)? \{'
    
    if re.search(async_setup_pattern, content):
        lines = content.split('\n')
        new_lines = []
        in_setup = False
        setup_body = []
        indent = ''
        
        i = 0
        while i < len(lines):
            line = lines[i]
            
            # Check for async setUp
            if re.match(r'\s*override func setUp\(\) async', line):
                in_setup = True
                indent = re.match(r'(\s*)', line).group(1)
                # Replace with sync setUp
                new_lines.append(f'{indent}override func setUp() {{')
                new_lines.append(f'{indent}    super.setUp()')
                i += 1
                continue
            
            # Collect setUp body
            if in_setup:
                if line.strip() == '}' and line.startswith(indent):
                    # End of setUp
                    in_setup = False
                    
                    # Process setup body
                    has_async_code = False
                    for setup_line in setup_body:
                        if 'await' in setup_line or 'ModelContainer' in setup_line:
                            has_async_code = True
                            break
                    
                    if has_async_code:
                        # Add setupTest method
                        new_lines.append(f'{indent}}}')
                        new_lines.append('')
                        new_lines.append(f'{indent}private func setupTest() async throws {{')
                        for setup_line in setup_body:
                            if 'super.setUp()' not in setup_line:
                                new_lines.append(setup_line)
                        new_lines.append(f'{indent}}}')
                    else:
                        # Just add the body to setUp
                        for setup_line in setup_body:
                            if 'super.setUp()' not in setup_line:
                                new_lines.append(setup_line)
                        new_lines.append(f'{indent}}}')
                else:
                    setup_body.append(line)
                i += 1
                continue
            
            new_lines.append(line)
            i += 1
        
        content = '\n'.join(new_lines)
    
    return content

def add_await_to_test_methods(content):
    """Add 'try await setupTest()' to async test methods."""
    lines = content.split('\n')
    new_lines = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        new_lines.append(line)
        
        # Check for async test method
        if re.match(r'\s*func test\w*\(\) async', line):
            # Find opening brace
            if '{' in line:
                indent = len(line) - len(line.lstrip()) + 4
                # Check if setupTest exists
                if 'setupTest()' in content and 'try await setupTest()' not in '\n'.join(lines[i:i+10]):
                    new_lines.append(' ' * indent + 'try await setupTest()')
            else:
                # Look for brace on next line
                j = i + 1
                while j < len(lines) and '{' not in lines[j]:
                    new_lines.append(lines[j])
                    j += 1
                if j < len(lines):
                    new_lines.append(lines[j])
                    indent = len(lines[j]) - len(lines[j].lstrip()) + 4
                    if 'setupTest()' in content and 'try await setupTest()' not in '\n'.join(lines[j:j+10]):
                        new_lines.append(' ' * indent + 'try await setupTest()')
                    i = j
        
        i += 1
    
    return '\n'.join(new_lines)

def fix_singleton_access(content):
    """Replace .shared singleton access with DI patterns."""
    replacements = [
        # NetworkManager.shared
        (r'NetworkManager\.shared', 'try await container.resolve(NetworkClientProtocol.self)'),
        # HealthKitManager.shared  
        (r'HealthKitManager\.shared', 'try await container.resolve(HealthKitManagerProtocol.self)'),
        # APIKeyManager.shared
        (r'APIKeyManager\.shared', 'try await container.resolve(APIKeyManagementProtocol.self)'),
        # DataManager.shared
        (r'DataManager\.shared\.modelContext', 'modelContext'),
        # NotificationManager.shared
        (r'NotificationManager\.shared', 'try await container.resolve(NotificationManagerProtocol.self)'),
    ]
    
    for pattern, replacement in replacements:
        if re.search(pattern, content):
            # Make sure we have container available
            if 'container: DIContainer' not in content and 'diContainer' not in content:
                # Add container property
                content = re.sub(
                    r'(class \w+Tests?: XCTestCase \{)',
                    r'\1\n    private var container: DIContainer!',
                    content
                )
            content = re.sub(pattern, replacement, content)
    
    return content

def fix_model_container_creation(content):
    """Fix ModelContainer creation in tests."""
    # Pattern for try ModelContainer.createTestContainer()
    pattern = r'(\s+)(.*= try ModelContainer\.createTestContainer\(\))'
    
    def replacement(match):
        indent = match.group(1)
        assignment = match.group(2)
        
        # Check if already in do-catch
        lines_before = content[:match.start()].split('\n')
        for line in reversed(lines_before[-5:]):
            if 'do {' in line:
                return match.group(0)
        
        return f'{indent}do {{\n{indent}    {assignment}\n{indent}}} catch {{\n{indent}    XCTFail("Failed to create test container: \\(error)")\n{indent}}}'
    
    content = re.sub(pattern, replacement, content)
    return content

def process_file(file_path):
    """Process a single test file."""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        original = content
        
        # Apply fixes
        content = fix_mainactor_test_class(content)
        content = fix_async_setup(content)
        content = add_await_to_test_methods(content)
        content = fix_singleton_access(content)
        content = fix_model_container_creation(content)
        
        if content != original:
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"✅ Fixed: {file_path.name}")
            return True
        
        return False
        
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def main():
    """Main function to process test files."""
    test_dir = Path("/Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests")
    
    if not test_dir.exists():
        print(f"Error: Test directory not found: {test_dir}")
        sys.exit(1)
    
    # Find all test files
    test_files = list(test_dir.rglob("*Tests.swift"))
    
    print(f"Found {len(test_files)} test files")
    
    fixed_count = 0
    for file_path in test_files:
        if process_file(file_path):
            fixed_count += 1
    
    print(f"\n✅ Fixed {fixed_count} files with DI-related issues")

if __name__ == "__main__":
    main()