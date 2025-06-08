#!/usr/bin/env python3
"""
Audit test files for common Phase 0 Emergency Triage issues.
"""

import os
import re
import sys
from pathlib import Path
from collections import defaultdict

# Path to test directory
TEST_DIR = Path("AirFit/AirFitTests")

# Patterns to search for
PATTERNS = {
    "wrong_protocol_names": [
        (r'HealthKitManagerProtocol', 'HealthKitManaging'),
        (r'\.genericError', '.unknown(message:)'),
        (r'\.unpredictable(?!\w)', '.unpredictableChaotic'),
        (r'\.evening(?!\w)', '.nightOwl'),
    ],
    "wrong_async_patterns": [
        (r'try await super\.setUp\(\)', 'try super.setUp()'),
        (r'try await super\.tearDown\(\)', 'try super.tearDown()'),
    ],
    "missing_mainactor": [
        (r'final class (\w+Tests): XCTestCase \{', r'@MainActor\nfinal class \1: XCTestCase {'),
    ],
    "undefined_references": [
        (r'mockHealth(?!Kit)', 'mockHealthKitManager'),
        (r'context(?!\.)', 'modelContext'),
    ],
    "mock_issues": [
        (r'MockCoachEngine', 'Check if using correct mock'),
        (r'stubbedCompleteResult', 'Property may not exist'),
        (r'\.verify\(\)', 'Method may not exist on mock'),
    ]
}

def scan_file(filepath):
    """Scan a single file for issues."""
    issues = defaultdict(list)
    
    try:
        with open(filepath, 'r') as f:
            content = f.read()
            lines = content.split('\n')
            
        # Check each pattern category
        for category, patterns in PATTERNS.items():
            for pattern, replacement in patterns:
                for i, line in enumerate(lines, 1):
                    if re.search(pattern, line):
                        issues[category].append({
                            'line': i,
                            'text': line.strip(),
                            'pattern': pattern,
                            'suggestion': replacement
                        })
        
        # Special check for @MainActor
        if 'ModelContext' in content and '@MainActor' not in content:
            issues['missing_mainactor'].append({
                'line': 0,
                'text': 'File uses ModelContext but lacks @MainActor',
                'pattern': 'ModelContext without @MainActor',
                'suggestion': 'Add @MainActor to test class'
            })
            
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        
    return issues

def main():
    """Run the audit on all test files."""
    print("🔍 Auditing test files for Phase 0 Emergency Triage issues...\n")
    
    all_issues = defaultdict(lambda: defaultdict(list))
    
    # Find all test files
    test_files = list(TEST_DIR.rglob("*Tests.swift"))
    
    for filepath in test_files:
        issues = scan_file(filepath)
        if issues:
            for category, issue_list in issues.items():
                all_issues[category][str(filepath)] = issue_list
    
    # Report findings
    if not all_issues:
        print("✅ No issues found!")
        return 0
    
    print("🔴 Issues found:\n")
    
    total_issues = 0
    for category, files in all_issues.items():
        print(f"\n## {category.replace('_', ' ').title()}")
        print(f"Found in {len(files)} files:\n")
        
        for filepath, issues in files.items():
            print(f"  📄 {filepath}")
            for issue in issues[:3]:  # Show first 3 issues per file
                print(f"     Line {issue['line']}: {issue['text'][:60]}...")
                print(f"     Fix: {issue['suggestion']}")
            if len(issues) > 3:
                print(f"     ... and {len(issues) - 3} more issues")
            print()
            total_issues += len(issues)
    
    print(f"\n📊 Total issues: {total_issues}")
    print("\n💡 Run this script after fixing issues to verify progress")
    
    return 1 if total_issues > 0 else 0

if __name__ == "__main__":
    sys.exit(main())