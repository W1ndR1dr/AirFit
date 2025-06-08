#!/usr/bin/env python3
"""
Identify test files that actually need @MainActor annotation.
Only tests using ModelContext or UI components need it.
"""

import os
import re
from pathlib import Path

def needs_mainactor(filepath):
    """Check if a test file actually needs @MainActor."""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Skip if already has @MainActor
        if '@MainActor' in content:
            return False, None
            
        # Check for indicators that require @MainActor
        needs_it = False
        reasons = []
        
        # ModelContext usage
        if 'ModelContext' in content and 'modelContext' in content:
            needs_it = True
            reasons.append("Uses ModelContext")
            
        # SwiftData usage
        if 'ModelContainer' in content:
            needs_it = True
            reasons.append("Uses ModelContainer")
            
        # UI testing
        if any(ui in content for ui in ['@Published', 'ObservableObject', '@State', '@StateObject']):
            needs_it = True
            reasons.append("Uses SwiftUI property wrappers")
            
        # ViewModel testing (ViewModels are @MainActor)
        if 'ViewModel' in filepath and 'ViewModel' in content:
            needs_it = True
            reasons.append("Tests a ViewModel")
            
        return needs_it, reasons
        
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return False, None

def main():
    """Find test files that need @MainActor."""
    test_dir = Path("AirFit/AirFitTests")
    
    print("🔍 Identifying test files that need @MainActor...\n")
    print("Criteria:")
    print("- Uses ModelContext or ModelContainer")
    print("- Tests ViewModels")
    print("- Uses SwiftUI property wrappers\n")
    
    files_needing_mainactor = []
    
    for root, dirs, files in os.walk(test_dir):
        for file in files:
            if file.endswith('Tests.swift'):
                filepath = os.path.join(root, file)
                needs_it, reasons = needs_mainactor(filepath)
                
                if needs_it:
                    files_needing_mainactor.append((filepath, reasons))
    
    print(f"\n📊 Found {len(files_needing_mainactor)} files that need @MainActor:\n")
    
    for filepath, reasons in sorted(files_needing_mainactor):
        print(f"✅ {filepath}")
        for reason in reasons:
            print(f"   - {reason}")
        print()
    
    # Show how to fix
    if files_needing_mainactor:
        print("\n💡 To fix, add @MainActor before the class declaration:")
        print("@MainActor")
        print("final class SomeTests: XCTestCase {")

if __name__ == "__main__":
    main()