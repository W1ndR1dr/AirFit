#!/usr/bin/env python3

import os
import re

def fix_test_file(file_path):
    """Remove @MainActor from test class declaration"""
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Remove @MainActor before final class
    content = re.sub(
        r'@MainActor\s*\n(\s*)final class',
        r'\1final class',
        content
    )
    
    # Also handle cases where @MainActor might have extra whitespace
    content = re.sub(
        r'@MainActor\s*\n\s*\n(\s*)final class',
        r'\1final class',
        content
    )
    
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    # Specific files that have the issue
    problem_files = [
        "AirFit/AirFitTests/Modules/Settings/SettingsViewModelTests.swift",
        "AirFit/AirFitTests/Data/UserModelTests.swift",
        "AirFit/AirFitTests/Modules/AI/MessageClassificationTests.swift",
        "AirFit/AirFitTests/Services/NetworkManagerTests.swift",
        "AirFit/AirFitTests/Integration/OnboardingFlowTests.swift",
        "AirFit/AirFitTests/Services/WeatherServiceTests.swift",
        "AirFit/AirFitTests/Core/VoiceInputManagerTests.swift",
        "AirFit/AirFitTests/Modules/AI/ConversationManagerTests.swift",
        "AirFit/AirFitTests/Modules/Dashboard/DashboardViewModelTests.swift"
    ]
    
    fixed_count = 0
    
    for file_path in problem_files:
        if os.path.exists(file_path):
            if fix_test_file(file_path):
                print(f"✓ Fixed: {file_path}")
                fixed_count += 1
    
    # Also check all test files
    test_dir = "AirFit/AirFitTests"
    for root, dirs, files in os.walk(test_dir):
        for file in files:
            if file.endswith('.swift') and 'Test' in file:
                file_path = os.path.join(root, file)
                if file_path not in problem_files:  # Skip already processed
                    if fix_test_file(file_path):
                        print(f"✓ Fixed: {file_path}")
                        fixed_count += 1
    
    print(f"\nFixed {fixed_count} test files by removing @MainActor from class declarations")

if __name__ == "__main__":
    os.chdir("/Users/Brian/Coding Projects/AirFit")
    main()