#!/usr/bin/env python3
"""Remove all HapticManager calls from the codebase."""

import os
import re
import sys

def remove_haptic_calls(file_path):
    """Remove HapticManager calls from a file."""
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Pattern to match HapticManager calls
    patterns = [
        # Match HapticManager.method(...) on its own line
        r'^\s*HapticManager\.[a-zA-Z]+\([^)]*\)\s*\n',
        # Match HapticManager.method(...) with other code on the same line
        r'HapticManager\.[a-zA-Z]+\([^)]*\)',
    ]
    
    # First, replace standalone lines with TODO comments
    content = re.sub(patterns[0], lambda m: f"{' ' * (len(m.group()) - len(m.group().lstrip()))}// TODO: Add haptic feedback via DI when needed\n", content, flags=re.MULTILINE)
    
    # Then, replace inline calls with empty string
    content = re.sub(patterns[1], '// Haptic feedback removed', content)
    
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    """Main function."""
    root_dir = 'AirFit'
    modified_files = []
    
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Skip test directories
        if 'Test' in dirpath or 'Mock' in dirpath:
            continue
            
        for filename in filenames:
            if filename.endswith('.swift'):
                file_path = os.path.join(dirpath, filename)
                if remove_haptic_calls(file_path):
                    modified_files.append(file_path)
    
    print(f"Modified {len(modified_files)} files:")
    for file in sorted(modified_files):
        print(f"  - {file}")

if __name__ == '__main__':
    main()