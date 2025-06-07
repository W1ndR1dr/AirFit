#!/bin/bash

# Script to fix async setUp/tearDown in @MainActor test classes

echo "Fixing async setUp/tearDown in @MainActor test classes..."

# List of files that need fixing
files=(
    "AirFit/AirFitTests/Core/VoiceInputManagerTests.swift"
    "AirFit/AirFitTests/Integration/NutritionParsingIntegrationTests.swift"
    "AirFit/AirFitTests/Integration/OnboardingErrorRecoveryTests.swift"
    "AirFit/AirFitTests/Integration/OnboardingFlowTests.swift"
    "AirFit/AirFitTests/Integration/PersonaGenerationTests.swift"
    "AirFit/AirFitTests/Modules/AI/CoachEngineTests.swift"
    "AirFit/AirFitTests/Modules/AI/ConversationManagerPerformanceTests.swift"
    "AirFit/AirFitTests/Modules/AI/ConversationManagerPersistenceTests.swift"
    "AirFit/AirFitTests/Modules/AI/ConversationManagerTests.swift"
    "AirFit/AirFitTests/Modules/AI/FunctionCallDispatcherTests.swift"
    "AirFit/AirFitTests/Modules/AI/MessageClassificationTests.swift"
    "AirFit/AirFitTests/Modules/Chat/ChatCoordinatorTests.swift"
    "AirFit/AirFitTests/Modules/Chat/ChatSuggestionsEngineTests.swift"
    "AirFit/AirFitTests/Modules/Dashboard/DashboardViewModelTests.swift"
    "AirFit/AirFitTests/Modules/FoodTracking/AINutritionParsingIntegrationTests.swift"
    "AirFit/AirFitTests/Modules/FoodTracking/AINutritionParsingTests.swift"
    "AirFit/AirFitTests/Modules/FoodTracking/FoodTrackingViewModelAIIntegrationTests.swift"
    "AirFit/AirFitTests/Modules/FoodTracking/FoodTrackingViewModelTests.swift"
    "AirFit/AirFitTests/Modules/FoodTracking/NutritionParsingExtensiveTests.swift"
    "AirFit/AirFitTests/Modules/Notifications/EngagementEngineTests.swift"
    "AirFit/AirFitTests/Modules/Notifications/NotificationManagerTests.swift"
    "AirFit/AirFitTests/Modules/Onboarding/OnboardingFlowViewTests.swift"
    "AirFit/AirFitTests/Modules/Onboarding/OnboardingIntegrationTests.swift"
    "AirFit/AirFitTests/Modules/Onboarding/OnboardingServiceTests.swift"
    "AirFit/AirFitTests/Modules/Settings/SettingsViewModelTests.swift"
    "AirFit/AirFitTests/Modules/Workouts/WorkoutCoordinatorTests.swift"
    "AirFit/AirFitTests/Modules/Workouts/WorkoutViewModelTests.swift"
    "AirFit/AirFitTests/Performance/DirectAIPerformanceTests.swift"
    "AirFit/AirFitTests/Performance/NutritionParsingPerformanceTests.swift"
    "AirFit/AirFitTests/Performance/NutritionParsingRegressionTests.swift"
    "AirFit/AirFitTests/Performance/OnboardingPerformanceTests.swift"
    "AirFit/AirFitTests/Services/NetworkManagerTests.swift"
    "AirFit/AirFitTests/Services/ServiceIntegrationTests.swift"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing: $file"
        
        # Check if file has @MainActor on the class
        if grep -q "@MainActor" "$file" && grep -q "class.*Test.*XCTestCase" "$file"; then
            # Remove async from setUp
            sed -i '' 's/override func setUp() async throws/override func setUp()/g' "$file"
            sed -i '' 's/try await super\.setUp()/super.setUp()/g' "$file"
            
            # Remove async from tearDown
            sed -i '' 's/override func tearDown() async throws/override func tearDown()/g' "$file"
            sed -i '' 's/try await super\.tearDown()/super.tearDown()/g' "$file"
            
            echo "  ✓ Fixed async setUp/tearDown"
        fi
    fi
done

echo "Done!"