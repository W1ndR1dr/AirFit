#!/usr/bin/env python3

import os
import re

def add_mainactor_to_test_methods(file_path):
    """Add @MainActor to test methods that need it"""
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # For WeatherServiceTests - add @MainActor to all test methods
    if 'WeatherServiceTests' in file_path:
        # Add @MainActor to test methods
        content = re.sub(
            r'^(\s+)(func test\w+[^\{]+\{)',
            r'\1@MainActor\n\1\2',
            content,
            flags=re.MULTILINE
        )
        
        # Also need to make setUp/tearDown @MainActor
        content = re.sub(
            r'^(\s+)(override func setUp\(\))',
            r'\1@MainActor\n\1\2',
            content,
            flags=re.MULTILINE
        )
        
        content = re.sub(
            r'^(\s+)(override func tearDown\(\))',
            r'\1@MainActor\n\1\2',
            content,
            flags=re.MULTILINE
        )
    
    # For WorkoutCoordinatorTests - similar treatment
    if 'WorkoutCoordinatorTests' in file_path:
        content = re.sub(
            r'^(\s+)(func test\w+[^\{]+\{)',
            r'\1@MainActor\n\1\2',
            content,
            flags=re.MULTILINE
        )
        
        content = re.sub(
            r'^(\s+)(override func setUp\(\))',
            r'\1@MainActor\n\1\2',
            content,
            flags=re.MULTILINE
        )
    
    # For other tests that access @MainActor services
    if any(service in file_path for service in ['ChatCoordinatorTests', 'SettingsCoordinator']):
        content = re.sub(
            r'^(\s+)(func test\w+[^\{]+\{)',
            r'\1@MainActor\n\1\2',
            content,
            flags=re.MULTILINE
        )
    
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    files_to_fix = [
        "AirFit/AirFitTests/Services/WeatherServiceTests.swift",
        "AirFit/AirFitTests/Modules/Workouts/WorkoutCoordinatorTests.swift",
        "AirFit/AirFitTests/Modules/Chat/ChatCoordinatorTests.swift"
    ]
    
    fixed_count = 0
    
    for file_path in files_to_fix:
        if os.path.exists(file_path):
            if add_mainactor_to_test_methods(file_path):
                print(f"✓ Fixed: {file_path}")
                fixed_count += 1
    
    print(f"\nFixed {fixed_count} test files by adding @MainActor to test methods")

if __name__ == "__main__":
    os.chdir("/Users/Brian/Coding Projects/AirFit")
    main()