#!/bin/bash

echo "Applying final test fixes..."

# For test files that have errors with ModelContainer creation
files_to_fix=(
    "AirFit/AirFitTests/Modules/Settings/SettingsViewModelTests.swift"
    "AirFit/AirFitTests/Data/UserModelTests.swift"
)

for file in "${files_to_fix[@]}"; do
    if [ -f "$file" ]; then
        echo "Fixing $file..."
        
        # For SettingsViewModelTests - wrap the container creation properly
        if [[ "$file" == *"SettingsViewModelTests"* ]]; then
            perl -i -pe '
                # Fix the container creation block
                s/let config = ModelConfiguration\(isStoredInMemoryOnly: true\)\s*\n\s*do \{/let config = ModelConfiguration(isStoredInMemoryOnly: true)\n        do {/;
            ' "$file"
        fi
        
        # For UserModelTests - ensure proper error handling
        if [[ "$file" == *"UserModelTests"* ]]; then
            perl -i -pe '
                # Ensure we have proper do-catch structure
                s/override func setUp\(\) \{\s*\n\s*super\.setUp\(\)\s*\n\s*do \{/override func setUp() {\n        super.setUp()\n        do {/;
            ' "$file"
        fi
    fi
done

# Fix remaining issues in Onboarding tests that may have try statements
onboarding_tests=(
    "AirFit/AirFitTests/Modules/Onboarding/OnboardingServiceTests.swift"
    "AirFit/AirFitTests/Integration/OnboardingIntegrationTests.swift"
)

for file in "${onboarding_tests[@]}"; do
    if [ -f "$file" ]; then
        # Fix any remaining try statements that need do-catch
        perl -i -pe '
            # Fix try context.save() that are not in do-catch blocks
            s/(\s+)try context\.save\(\)$/\1do {\n\1    try context.save()\n\1} catch {\n\1    XCTFail("Failed to save context: \\(error)")\n\1}/g if !/do \{.*try context\.save/;
        ' "$file"
    fi
done

echo "Final fixes complete!"