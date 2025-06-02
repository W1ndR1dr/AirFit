#!/bin/bash

# Verify Module 10 Implementation Script

echo "🔍 Verifying Module 10 (Services Layer) Implementation..."
echo "=================================================="

# Base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR"

# Function to check if file exists
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo "✅ $description: $(basename "$file")"
        return 0
    else
        echo "❌ $description: $(basename "$file") - NOT FOUND"
        return 1
    fi
}

# Function to check if pattern exists in file
check_pattern() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "  ✓ $description"
        return 0
    else
        echo "  ✗ $description - NOT FOUND"
        return 1
    fi
}

echo ""
echo "1️⃣ Checking Service Protocols & Base Infrastructure..."
echo "------------------------------------------------------"
check_file "AirFit/Services/ServiceProtocols.swift" "Service Protocols"
check_file "AirFit/Services/Network/NetworkManager.swift" "Network Manager"
check_file "AirFit/Services/ServiceConfiguration.swift" "Service Configuration"
check_file "AirFit/Services/ServiceRegistry.swift" "Service Registry"

echo ""
echo "2️⃣ Checking API Key Management..."
echo "---------------------------------"
check_file "AirFit/Services/Security/DefaultAPIKeyManager.swift" "API Key Manager"
check_file "AirFit/Services/Security/KeychainHelper.swift" "Keychain Helper"

echo ""
echo "3️⃣ Checking AI Service Implementation..."
echo "----------------------------------------"
check_file "AirFit/Services/AI/EnhancedAIAPIService.swift" "Enhanced AI API Service"
check_file "AirFit/Services/AI/AIResponseParser.swift" "AI Response Parser"
check_file "AirFit/Services/AI/AIRequestBuilder.swift" "AI Request Builder"

# Check for provider support
echo ""
echo "   Checking AI Provider Support:"
if [ -f "AirFit/Services/AI/EnhancedAIAPIService.swift" ]; then
    check_pattern "AirFit/Services/AI/EnhancedAIAPIService.swift" "case \.openAI" "OpenAI support"
    check_pattern "AirFit/Services/AI/EnhancedAIAPIService.swift" "case \.anthropic" "Anthropic support"
    check_pattern "AirFit/Services/AI/EnhancedAIAPIService.swift" "case \.googleGemini" "Google Gemini support"
    check_pattern "AirFit/Services/AI/EnhancedAIAPIService.swift" "case \.openRouter" "OpenRouter support"
fi

echo ""
echo "4️⃣ Checking Weather Service..."
echo "------------------------------"
check_file "AirFit/Services/WeatherService.swift" "Weather Service"

echo ""
echo "5️⃣ Checking Mock Services..."
echo "----------------------------"
check_file "AirFit/Services/MockServices/MockNetworkManager.swift" "Mock Network Manager"
check_file "AirFit/Services/MockServices/MockAIAPIService.swift" "Mock AI API Service"
check_file "AirFit/Services/MockServices/MockWeatherService.swift" "Mock Weather Service"
check_file "AirFit/Services/MockServices/MockAPIKeyManager.swift" "Mock API Key Manager"

echo ""
echo "6️⃣ Checking Extensions..."
echo "-------------------------"
check_file "AirFit/Core/Extensions/URLRequest+Extensions.swift" "URLRequest Extensions"
check_file "AirFit/Core/Extensions/AIProvider+Extensions.swift" "AIProvider Extensions"

echo ""
echo "7️⃣ Checking Test Files..."
echo "-------------------------"
check_file "AirFit/AirFitTests/Services/NetworkManagerTests.swift" "Network Manager Tests"
check_file "AirFit/AirFitTests/Services/ServiceProtocolsTests.swift" "Service Protocols Tests"
check_file "AirFit/AirFitTests/Services/WeatherServiceTests.swift" "Weather Service Tests"
check_file "AirFit/AirFitTests/Services/MockServicesTests.swift" "Mock Services Tests"
check_file "AirFit/AirFitTests/Services/TestDataGenerators.swift" "Test Data Generators"
check_file "AirFit/AirFitTests/Services/ServicePerformanceTests.swift" "Service Performance Tests"
check_file "AirFit/AirFitTests/Services/ServiceIntegrationTests.swift" "Service Integration Tests"

echo ""
echo "8️⃣ Checking Key Features..."
echo "---------------------------"

# Check for streaming support
echo ""
echo "   Streaming Support:"
if [ -f "AirFit/Services/AI/EnhancedAIAPIService.swift" ]; then
    check_pattern "AirFit/Services/AI/EnhancedAIAPIService.swift" "AsyncThrowingStream" "Async streaming implementation"
    check_pattern "AirFit/Services/AI/AIResponseParser.swift" "parseStreamData" "SSE parsing support"
fi

# Check for error handling
echo ""
echo "   Error Handling:"
if [ -f "AirFit/Services/ServiceProtocols.swift" ]; then
    check_pattern "AirFit/Services/ServiceProtocols.swift" "enum ServiceError" "ServiceError enum"
    check_pattern "AirFit/Services/ServiceProtocols.swift" "rateLimitExceeded" "Rate limit handling"
fi

# Check for health checks
echo ""
echo "   Health Check Support:"
if [ -f "AirFit/Services/ServiceProtocols.swift" ]; then
    check_pattern "AirFit/Services/ServiceProtocols.swift" "struct ServiceHealth" "ServiceHealth struct"
    check_pattern "AirFit/Services/ServiceProtocols.swift" "healthCheck()" "Health check method"
fi

echo ""
echo "9️⃣ Checking Performance Requirements..."
echo "--------------------------------------"
if [ -f "AirFit/AirFitTests/Services/ServicePerformanceTests.swift" ]; then
    check_pattern "AirFit/AirFitTests/Services/ServicePerformanceTests.swift" "measure {" "Performance measurement"
    check_pattern "AirFit/AirFitTests/Services/ServicePerformanceTests.swift" "50 \* 1024 \* 1024" "50MB memory limit check"
fi

echo ""
echo "🔟 Checking Integration Tests..."
echo "--------------------------------"
if [ -f "AirFit/AirFitTests/Services/ServiceIntegrationTests.swift" ]; then
    check_pattern "AirFit/AirFitTests/Services/ServiceIntegrationTests.swift" "ServiceRegistry" "Service Registry integration"
    check_pattern "AirFit/AirFitTests/Services/ServiceIntegrationTests.swift" "testFullServiceStackIntegration" "Full stack integration test"
fi

echo ""
echo "=================================================="
echo "📊 Module 10 Verification Summary"
echo "=================================================="

# Count successes
TOTAL_CHECKS=34
PASSED_CHECKS=$(grep -c "✅\|✓" <<< "$(bash $0 2>&1)")

echo ""
echo "Total checks: $TOTAL_CHECKS"
echo "Passed checks: $PASSED_CHECKS"
echo ""

if [ "$PASSED_CHECKS" -eq "$TOTAL_CHECKS" ]; then
    echo "✅ Module 10 is FULLY IMPLEMENTED!"
else
    echo "⚠️  Module 10 has some missing components"
fi

echo ""
echo "=================================================="