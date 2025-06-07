#!/usr/bin/env python3

import os
import re

def fix_mainactor_test_file(file_path):
    """Fix @MainActor test file by moving initialization to test methods"""
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Check if this is a @MainActor test class
    if '@MainActor' not in content or 'XCTestCase' not in content:
        return False
    
    # For SettingsViewModelTests and similar - remove property assignments from setUp
    if 'SettingsViewModelTests' in file_path or 'UserModelTests' in file_path or 'MessageClassificationTests' in file_path or 'NetworkManagerTests' in file_path:
        # Comment out the entire setUp and tearDown methods
        content = re.sub(
            r'override func setUp\(\) \{[^}]*\}',
            '''override func setUp() {
        super.setUp()
        // Initialization moved to test methods due to @MainActor
    }''',
            content,
            flags=re.DOTALL
        )
        
        content = re.sub(
            r'override func tearDown\(\) \{[^}]*\}',
            '''override func tearDown() {
        // Cleanup moved to test methods due to @MainActor
        super.tearDown()
    }''',
            content,
            flags=re.DOTALL
        )
        
        # For each test method, add initialization at the beginning
        def add_init_to_test(match):
            indent = match.group(1)
            test_name = match.group(2)
            
            if 'SettingsViewModelTests' in file_path:
                init_code = f'''{indent}func {test_name} {{
{indent}    // Setup
{indent}    let config = ModelConfiguration(isStoredInMemoryOnly: true)
{indent}    do {{
{indent}        let container = try ModelContainer(for: User.self, configurations: config)
{indent}        modelContext = ModelContext(container)
{indent}    }} catch {{
{indent}        XCTFail("Failed to create container: \\(error)")
{indent}        return
{indent}    }}
{indent}    
{indent}    testUser = User(name: "Test User")
{indent}    modelContext.insert(testUser)
{indent}    try? modelContext.save()
{indent}    
{indent}    mockAPIKeyManager = MockAPIKeyManager()
{indent}    mockAIService = MockAIService()
{indent}    mockNotificationManager = MockNotificationManager()
{indent}    coordinator = SettingsCoordinator()
{indent}    
{indent}    sut = SettingsViewModel(
{indent}        modelContext: modelContext,
{indent}        user: testUser,
{indent}        apiKeyManager: mockAPIKeyManager,
{indent}        aiService: mockAIService,
{indent}        notificationManager: NotificationManager.shared,
{indent}        coordinator: coordinator
{indent}    )
{indent}    '''
            elif 'UserModelTests' in file_path:
                init_code = f'''{indent}func {test_name} {{
{indent}    // Setup
{indent}    do {{
{indent}        container = try ModelContainer.createTestContainer()
{indent}        context = container.mainContext
{indent}    }} catch {{
{indent}        XCTFail("Failed to create test container: \\(error)")
{indent}        return
{indent}    }}
{indent}    '''
            elif 'MessageClassificationTests' in file_path:
                init_code = f'''{indent}func {test_name} {{
{indent}    // Setup
{indent}    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
{indent}    let container = try! ModelContainer(for: User.self, CoachMessage.self, configurations: configuration)
{indent}    modelContext = ModelContext(container)
{indent}    
{indent}    testUser = User()
{indent}    modelContext.insert(testUser)
{indent}    try! modelContext.save()
{indent}    
{indent}    coachEngine = CoachEngine.createDefault(modelContext: modelContext)
{indent}    '''
            elif 'NetworkManagerTests' in file_path:
                init_code = f'''{indent}func {test_name} {{
{indent}    // Setup
{indent}    sut = NetworkManager.shared
{indent}    '''
            else:
                return match.group(0)
            
            return init_code
        
        # Find all test functions and add initialization
        content = re.sub(
            r'^(\s+)func (test\w+)\s*\([^)]*\)\s*(?:async\s*)?(?:throws\s*)?\{',
            add_init_to_test,
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
        "AirFit/AirFitTests/Modules/Settings/SettingsViewModelTests.swift",
        "AirFit/AirFitTests/Data/UserModelTests.swift",
        "AirFit/AirFitTests/Modules/AI/MessageClassificationTests.swift",
        "AirFit/AirFitTests/Services/NetworkManagerTests.swift"
    ]
    
    fixed_count = 0
    for file_path in files_to_fix:
        if os.path.exists(file_path):
            if fix_mainactor_test_file(file_path):
                print(f"✓ Fixed: {file_path}")
                fixed_count += 1
    
    print(f"\nFixed {fixed_count} test files")

if __name__ == "__main__":
    os.chdir("/Users/Brian/Coding Projects/AirFit")
    main()