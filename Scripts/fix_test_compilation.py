#!/usr/bin/env python3
"""
Fix remaining test compilation issues after DI migration.
"""

import os
import re
import sys
from pathlib import Path

def fix_duplicate_mainactor(content):
    """Remove duplicate @MainActor annotations."""
    # Fix duplicate @MainActor on same line
    content = re.sub(r'@MainActor\s*\n\s*@MainActor', '@MainActor', content)
    return content

def fix_async_setup_issues(content):
    """Fix remaining async setUp issues."""
    # Fix lines like: diContainer = try await DITestHelper.createTestContainer()
    # These need to be in an async context
    
    lines = content.split('\n')
    new_lines = []
    
    for i, line in enumerate(lines):
        # Check for problematic patterns in setUp()
        if 'override func setUp()' in line and i < len(lines) - 5:
            # Check if there's async code in setUp
            has_async = False
            for j in range(i + 1, min(i + 20, len(lines))):
                if 'await' in lines[j] or 'async' in lines[j]:
                    has_async = True
                    break
            
            if has_async:
                # Need to convert this setUp
                new_lines.append(line)
                new_lines.append('        super.setUp()')
                new_lines.append('        // Async initialization moved to setupTest()')
                new_lines.append('    }')
                new_lines.append('')
                new_lines.append('    private func setupTest() async throws {')
                
                # Skip original setUp content
                j = i + 1
                brace_count = 1 if '{' in line else 0
                while j < len(lines) and brace_count > 0:
                    if 'super.setUp()' not in lines[j]:
                        new_lines.append(lines[j])
                    brace_count += lines[j].count('{') - lines[j].count('}')
                    j += 1
                i = j - 1
                continue
        
        new_lines.append(line)
    
    return '\n'.join(new_lines)

def fix_network_manager_tests(file_path):
    """Fix NetworkManagerTests specifically."""
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix the setUp method
    content = re.sub(
        r'override func setUp\(\) \{\s*super\.setUp\(\)\s*sut = try await container\.resolve\(NetworkClientProtocol\.self\)',
        '''override func setUp() {
        super.setUp()
        // Container initialization moved to test methods
    }
    
    private func setupTest() async throws {
        container = try await DITestHelper.createTestContainer()
        sut = try await container.resolve(NetworkClientProtocol.self) as? NetworkManager''',
        content
    )
    
    # Add setupTest() calls to test methods
    test_methods = re.findall(r'func test\w+\(\)', content)
    for method in test_methods:
        if 'async' not in content.split(method)[1].split('func')[0]:
            # Make test method async and add setupTest
            content = content.replace(
                method + ' {',
                method.replace('()', '() async throws') + ' {\n        try await setupTest()'
            )
    
    with open(file_path, 'w') as f:
        f.write(content)

def fix_dashboard_tests(file_path):
    """Fix DashboardViewModelTests specifically."""
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix the problematic setUp
    content = re.sub(
        r'override func setUp\(\) \{[^}]*\}',
        '''override func setUp() {
        super.setUp()
        // Async initialization moved to setupTest()
    }
    
    private func setupTest() async throws {
        diContainer = try await DITestHelper.createTestContainer()
        factory = DIViewModelFactory(container: diContainer)
        modelContainer = try await diContainer.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
    }''',
        content,
        flags=re.DOTALL
    )
    
    with open(file_path, 'w') as f:
        f.write(content)

def fix_nutrition_regression_tests(file_path):
    """Fix NutritionParsingRegressionTests specifically."""
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Add @MainActor to the test class
    if '@MainActor' not in content.split('final class NutritionParsingRegressionTests')[0][-100:]:
        content = content.replace(
            'final class NutritionParsingRegressionTests',
            '@MainActor\nfinal class NutritionParsingRegressionTests'
        )
    
    # Fix setUp to handle async initialization
    content = re.sub(
        r'override func setUp\(\)[^}]*\}',
        '''override func setUp() {
        super.setUp()
        // Async initialization moved to setupTest()
    }
    
    private func setupTest() async throws {
        // SwiftData setup
        do {
            let schema = Schema([User.self, FoodEntry.self, FoodItem.self, Workout.self, Exercise.self, ExerciseSet.self, DailyLog.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            XCTFail("Failed to create model container: \\(error)")
        }
        
        modelContext = modelContainer.mainContext
        
        // Create test user
        testUser = User(name: "Test User")
        testUser.dailyCalorieTarget = 2000
        testUser.preferences = NutritionPreferences()
        modelContext.insert(testUser)
        
        try modelContext.save()
        
        // Initialize mocks and SUT
        nutritionService = NutritionService(modelContext: modelContext)
        coachEngine = MockCoachEngine()
        coordinator = FoodTrackingCoordinator()
        mockFoodVoiceAdapter = MockFoodVoiceAdapter()
        
        viewModel = FoodTrackingViewModel(
            modelContext: modelContext,
            user: testUser,
            foodVoiceAdapter: mockFoodVoiceAdapter,
            nutritionService: nutritionService,
            coachEngine: coachEngine,
            coordinator: coordinator
        )
    }''',
        content,
        flags=re.DOTALL
    )
    
    # Add setupTest() calls to test methods
    test_pattern = r'(func test\w+\(\) async[^{]*\{)'
    
    def add_setup(match):
        return match.group(1) + '\n        try await setupTest()'
    
    content = re.sub(test_pattern, add_setup, content)
    
    with open(file_path, 'w') as f:
        f.write(content)

def main():
    """Fix specific test files with compilation errors."""
    test_dir = Path("/Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests")
    
    # Fix specific files
    problem_files = [
        test_dir / "Services" / "NetworkManagerTests.swift",
        test_dir / "Modules" / "Dashboard" / "DashboardViewModelTests.swift",
        test_dir / "Performance" / "NutritionParsingRegressionTests.swift",
        test_dir / "Modules" / "FoodTracking" / "FoodTrackingViewModelTests.swift",
    ]
    
    for file_path in problem_files:
        if file_path.exists():
            print(f"Fixing {file_path.name}...")
            
            if 'NetworkManagerTests' in str(file_path):
                fix_network_manager_tests(file_path)
            elif 'DashboardViewModelTests' in str(file_path):
                fix_dashboard_tests(file_path)
            elif 'NutritionParsingRegressionTests' in str(file_path):
                fix_nutrition_regression_tests(file_path)
            else:
                # General fixes
                with open(file_path, 'r') as f:
                    content = f.read()
                content = fix_duplicate_mainactor(content)
                content = fix_async_setup_issues(content)
                with open(file_path, 'w') as f:
                    f.write(content)
            
            print(f"✅ Fixed {file_path.name}")
    
    # Fix all duplicate @MainActor issues
    all_test_files = list(test_dir.rglob("*Tests.swift"))
    for file_path in all_test_files:
        with open(file_path, 'r') as f:
            content = f.read()
        
        original = content
        content = fix_duplicate_mainactor(content)
        
        if content != original:
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"✅ Fixed duplicate @MainActor in {file_path.name}")

if __name__ == "__main__":
    main()