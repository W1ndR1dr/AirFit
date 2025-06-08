#!/usr/bin/env python3
"""
Fix variable naming issues in test files:
- context → modelContext (for SwiftData contexts)
- Fix other common variable naming issues
"""

import os
import re
import sys

def fix_variable_names(file_path):
    """Fix variable naming in a single file."""
    changes_made = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Fix context → modelContext
        # But be careful not to change ModelContext type or other valid uses
        patterns_to_fix = [
            # Variable declarations
            (r'private var context:', 'private var modelContext:'),
            (r'var context:', 'var modelContext:'),
            (r'let context:', 'let modelContext:'),
            (r'private let context:', 'private let modelContext:'),
            
            # Assignments where context is on left side
            (r'\bcontext\s*=\s*', 'modelContext = '),
            
            # Method calls and property access
            (r'\bcontext\.insert\(', 'modelContext.insert('),
            (r'\bcontext\.save\(', 'modelContext.save('),
            (r'\bcontext\.fetch\(', 'modelContext.fetch('),
            (r'\bcontext\.delete\(', 'modelContext.delete('),
            (r'\bcontext\.fetchCount\(', 'modelContext.fetchCount('),
            
            # Common patterns
            (r'self\.context', 'self.modelContext'),
            (r'\(context:', '(modelContext:'),
            
            # Fix mockHealthProvider → mockHealthKitManager
            (r'mockHealthProvider', 'mockHealthKitManager'),
            
            # Fix contextAssembler references
            (r'contextAssembler', 'mockContextAssembler'),
        ]
        
        for pattern, replacement in patterns_to_fix:
            new_content = re.sub(pattern, replacement, content)
            if new_content != content:
                changes_made.append(f"{pattern} → {replacement}")
                content = new_content
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return changes_made
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return []
    
    return []

def main():
    """Find and fix all test files with variable naming issues."""
    test_dir = "AirFit/AirFitTests"
    total_fixes = 0
    files_fixed = 0
    
    print("🔧 Fixing variable naming issues in test files...")
    print("Patterns: context → modelContext, mockHealthProvider → mockHealthKitManager")
    print()
    
    for root, dirs, files in os.walk(test_dir):
        for file in files:
            if file.endswith('.swift') and 'Tests' in file:
                file_path = os.path.join(root, file)
                
                changes = fix_variable_names(file_path)
                if changes:
                    print(f"✅ Fixed {file_path}:")
                    for change in changes:
                        print(f"   - {change}")
                    total_fixes += len(changes)
                    files_fixed += 1
    
    print()
    print(f"📊 Summary: Fixed {total_fixes} issues in {files_fixed} files")
    
    # Verify fixes
    print("\n🔍 Verifying fixes...")
    
    # Check for remaining wrong patterns
    remaining_patterns = [
        ('private var context:', 'grep -r "private var context:" {test_dir} | grep -v modelContext | wc -l'),
        ('context.insert', 'grep -r "context\\.insert" {test_dir} | wc -l'),
        ('context.save', 'grep -r "context\\.save" {test_dir} | wc -l'),
        ('mockHealthProvider', 'grep -r "mockHealthProvider" {test_dir} | wc -l'),
    ]
    
    issues_remain = False
    for pattern_name, cmd_template in remaining_patterns:
        cmd = cmd_template.format(test_dir=test_dir)
        count = os.popen(cmd).read().strip()
        if count != '0':
            print(f"⚠️  {pattern_name}: {count} remaining")
            issues_remain = True
    
    if not issues_remain:
        print("\n✅ All variable naming issues fixed successfully!")
    else:
        print("\n⚠️  Some patterns may still remain. Running detailed check...")
        # Show specific files with issues
        os.system(f'grep -r "private var context:" {test_dir} | grep -v modelContext | head -5')

if __name__ == "__main__":
    main()