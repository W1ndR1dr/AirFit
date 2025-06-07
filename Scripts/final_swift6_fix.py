#!/usr/bin/env python3

import os
import re

def fix_weather_service_tests(file_path):
    """Fix WeatherServiceTests by removing @MainActor from setUp/tearDown and making test class async-aware"""
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remove @MainActor from setUp/tearDown
    content = re.sub(r'@MainActor\s*\n\s*override func setUp', 'override func setUp', content)
    content = re.sub(r'@MainActor\s*\n\s*override func tearDown', 'override func tearDown', content)
    
    # Change setUp to create service differently
    content = re.sub(
        r'override func setUp\(\) \{\s*super\.setUp\(\)\s*sut = WeatherService\(\)\s*\}',
        '''override func setUp() {
        super.setUp()
        // WeatherService is @MainActor, will be created in test methods
    }''',
        content
    )
    
    # Fix each test method to create sut inside
    def fix_test_method(match):
        indent = match.group(1)
        func_name = match.group(2)
        
        # Add sut creation at the beginning of each test
        return f'''{indent}@MainActor
{indent}func {func_name} {{
{indent}    let sut = WeatherService()'''
    
    content = re.sub(
        r'^(\s+)@MainActor\s*\n\s*func (test\w+[^\{]+)\{',
        fix_test_method,
        content,
        flags=re.MULTILINE
    )
    
    with open(file_path, 'w') as f:
        f.write(content)

def fix_workout_coordinator_tests(file_path):
    """Fix WorkoutCoordinatorTests similarly"""
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remove @MainActor from setUp
    content = re.sub(r'@MainActor\s*\n\s*override func setUp', 'override func setUp', content)
    
    # Change setUp to not create coordinator
    content = re.sub(
        r'override func setUp\(\) \{\s*coordinator = WorkoutCoordinator\(\)\s*\}',
        '''override func setUp() {
        // WorkoutCoordinator is @MainActor, will be created in test methods
    }''',
        content
    )
    
    # Fix each test method to create coordinator inside
    def fix_test_method(match):
        indent = match.group(1)
        func_name = match.group(2)
        
        return f'''{indent}@MainActor
{indent}func {func_name} {{
{indent}    let coordinator = WorkoutCoordinator()'''
    
    content = re.sub(
        r'^(\s+)@MainActor\s*\n\s*func (test\w+[^\{]+)\{',
        fix_test_method,
        content,
        flags=re.MULTILINE
    )
    
    with open(file_path, 'w') as f:
        f.write(content)

def main():
    # Fix WeatherServiceTests
    weather_file = "AirFit/AirFitTests/Services/WeatherServiceTests.swift"
    if os.path.exists(weather_file):
        fix_weather_service_tests(weather_file)
        print(f"✓ Fixed: {weather_file}")
    
    # Fix WorkoutCoordinatorTests
    workout_file = "AirFit/AirFitTests/Modules/Workouts/WorkoutCoordinatorTests.swift"
    if os.path.exists(workout_file):
        fix_workout_coordinator_tests(workout_file)
        print(f"✓ Fixed: {workout_file}")

if __name__ == "__main__":
    os.chdir("/Users/Brian/Coding Projects/AirFit")
    main()