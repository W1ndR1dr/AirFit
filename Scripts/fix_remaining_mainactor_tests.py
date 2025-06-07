#!/usr/bin/env python3

import os
import re

def add_mainactor_to_test_methods(file_path):
    """Add @MainActor to test methods that access @MainActor properties"""
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Add @MainActor to all test functions
    content = re.sub(
        r'^(\s+)(func test\w+[^\{]*\{)',
        r'\1@MainActor\n\1\2',
        content,
        flags=re.MULTILINE
    )
    
    # Also need to fix async test methods to have proper async signature
    content = re.sub(
        r'@MainActor\n(\s+func test\w+)\(\)',
        r'@MainActor\n\1()',
        content
    )
    
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    # List of test files that likely need @MainActor on test methods
    test_files = [
        "AirFit/AirFitTests/Modules/Onboarding/OnboardingViewModelTests.swift",
        "AirFit/AirFitTests/Modules/Onboarding/OnboardingServiceTests.swift",
        "AirFit/AirFitTests/Modules/Onboarding/OnboardingIntegrationTests.swift",
        "AirFit/AirFitTests/Modules/Onboarding/ConversationViewModelTests.swift",
        "AirFit/AirFitTests/Modules/Chat/ChatViewModelTests.swift",
        "AirFit/AirFitTests/Modules/Dashboard/DashboardViewModelTests.swift",
        "AirFit/AirFitTests/Modules/Settings/SettingsViewModelTests.swift",
        "AirFit/AirFitTests/Modules/FoodTracking/FoodTrackingViewModelTests.swift",
        "AirFit/AirFitTests/Modules/Workouts/WorkoutViewModelTests.swift"
    ]
    
    fixed_count = 0
    
    for file_path in test_files:
        if os.path.exists(file_path):
            if add_mainactor_to_test_methods(file_path):
                print(f"✓ Fixed: {file_path}")
                fixed_count += 1
    
    print(f"\nFixed {fixed_count} test files")

if __name__ == "__main__":
    os.chdir("/Users/Brian/Coding Projects/AirFit")
    main()