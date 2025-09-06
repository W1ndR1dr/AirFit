# Environment Configuration

This document defines how AirFit handles different environments (Development, Staging, Production) and provides centralized access to environment-specific configuration.

## Environment Types

### 1. Development
- **Build Configuration**: `DEBUG` build 
- **Detection**: Always enabled when `DEBUG` flag is present
- **Characteristics**:
  - Debug logging enabled
  - Mock services available
  - Test data generation allowed
  - Relaxed validation rules
- **Base URL**: `https://api-dev.airfit.app`

### 2. Staging
- **Build Configuration**: `RELEASE` build with `STAGING=1` environment variable
- **Detection**: `STAGING` environment variable is set (any value)
- **Characteristics**:
  - Production-like environment
  - Real services with test data
  - Performance monitoring enabled
  - Full validation rules
- **Base URL**: `https://api-staging.airfit.app`

### 3. Production
- **Build Configuration**: `RELEASE` build without staging flags
- **Detection**: Default for release builds when staging flag is absent
- **Characteristics**:
  - Full analytics and monitoring
  - Real user data
  - Strict validation and security
  - Performance optimizations
- **Base URL**: `https://api.airfit.app`

## How to Switch Environments

### For Development
Development environment is automatically enabled for all `DEBUG` builds. No additional configuration required.

### For Staging
Set the `STAGING` environment variable when running the app:

#### Xcode
1. Edit Scheme → Run → Arguments
2. Add Environment Variable: `STAGING` = `1`

#### Command Line
```bash
export STAGING=1
# Launch your app or simulator
```

#### TestFlight/App Store Connect
Configure staging builds in your CI/CD pipeline to set the `STAGING` environment variable.

### For Production
Production is the default for release builds. Ensure no `STAGING` environment variable is set.

## Centralized Configuration Access

### InfoPlistHelper
All Info.plist access is centralized in `InfoPlistHelper`:

```swift
// Environment detection
let env = InfoPlistHelper.detectedEnvironment
let isStaging = InfoPlistHelper.isStagingEnvironment

// App information
let appName = InfoPlistHelper.appName
let version = InfoPlistHelper.appVersion
let build = InfoPlistHelper.buildNumber

// Permissions
let healthDescription = InfoPlistHelper.healthShareUsageDescription
```

### ServiceConfiguration
Service-specific environment configuration:

```swift
let config = ServiceConfiguration()
let environment = ServiceConfiguration.detectEnvironment()
let apiBaseURL = environment.baseURL
let isDebugMode = environment.isDebug
```

### AppConstants
Runtime configuration flags:

```swift
// Test and preview detection
let isTestMode = AppConstants.Configuration.isTestMode
let isPreviewMode = AppConstants.Configuration.isPreviewMode

// Demo mode toggle
AppConstants.Configuration.isUsingDemoMode = true
```

## What Changes Per Environment

### API Endpoints
```swift
switch environment {
case .development:
    baseURL = "https://api-dev.airfit.app"
case .staging:
    baseURL = "https://api-staging.airfit.app"
case .production:
    baseURL = "https://api.airfit.app"
}
```

### Logging Level
```swift
let loggingEnabled = environment.isDebug
```

### Analytics
```swift
let analyticsConfig = AnalyticsConfiguration(
    enabled: environment != .development,
    debugLogging: environment.isDebug
)
```

### AI Service Configuration
```swift
let aiConfig = AIConfiguration(
    costTrackingEnabled: environment != .development,
    cacheEnabled: true,
    streamingEnabled: environment != .development
)
```

## Usage Examples

### Conditional Feature Flags
```swift
struct FeatureFlags {
    static let enableBetaFeatures = InfoPlistHelper.detectedEnvironment.isDebug
    static let enableDetailedLogging = InfoPlistHelper.detectedEnvironment != .production
    static let enableTestDataGeneration = InfoPlistHelper.detectedEnvironment == .development
}
```

### Service Initialization
```swift
actor NetworkService {
    private let baseURL: String
    
    init() {
        let environment = ServiceConfiguration.detectEnvironment()
        self.baseURL = environment.baseURL
    }
}
```

### UI Behavior
```swift
struct DebugPanel: View {
    var body: some View {
        if InfoPlistHelper.detectedEnvironment.isDebug {
            VStack {
                Text("Debug Panel")
                Button("Generate Test Data") { }
                Button("Clear Cache") { }
            }
        }
    }
}
```

## Environment-Specific Build Configurations

### Xcode Build Settings

#### Development (Debug)
```
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG
DEBUG_INFORMATION_FORMAT = dwarf
SWIFT_OPTIMIZATION_LEVEL = -Onone
```

#### Staging/Production (Release)
```
SWIFT_ACTIVE_COMPILATION_CONDITIONS = (empty)
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
SWIFT_OPTIMIZATION_LEVEL = -O
```

### Info.plist Environment Keys
Optional custom keys for advanced environment detection:

```xml
<key>AirFitStagingMode</key>
<true/>

<key>AirFitEnvironment</key>
<string>staging</string>
```

## Common Pitfalls

### ❌ Scattered Environment Checks
```swift
// DON'T: Check environment variables directly throughout the app
if ProcessInfo.processInfo.environment["STAGING"] != nil {
    // staging behavior
}

// DON'T: Duplicate environment logic
#if DEBUG
let isDev = true
#else
let isDev = false
#endif
```

### ✅ Centralized Environment Access
```swift
// DO: Use centralized helpers
if InfoPlistHelper.detectedEnvironment == .staging {
    // staging behavior
}

// DO: Use consistent detection
let environment = ServiceConfiguration.detectEnvironment()
```

### ❌ Hardcoded URLs and Config
```swift
// DON'T: Hardcode environment-specific values
let apiURL = "https://api-dev.airfit.app"
```

### ✅ Dynamic Configuration
```swift
// DO: Use environment-aware configuration
let apiURL = ServiceConfiguration.detectEnvironment().baseURL
```

### ❌ Runtime Environment Changes
```swift
// DON'T: Try to change environment at runtime
InfoPlistHelper.detectedEnvironment = .staging // This won't work
```

### ✅ Build-Time Environment Selection
Environment is determined at build time and app launch. Use proper build configurations and environment variables.

## Testing Environment Behavior

### Unit Tests
```swift
func testEnvironmentDetection() {
    // Environment detection is build-time, not runtime configurable
    let environment = ServiceConfiguration.detectEnvironment()
    XCTAssertNotNil(environment)
}
```

### Integration Tests
Use the `AIRFIT_TEST_MODE` environment variable to enable test-specific behavior:

```swift
if AppConstants.Configuration.isTestMode {
    // Use mock services
    return MockAIService()
} else {
    // Use real services
    return OpenAIService()
}
```

## Migration from Legacy Code

### Before: Scattered Info.plist Access
```swift
let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
```

### After: Centralized Access
```swift
let appVersion = InfoPlistHelper.appVersion
let buildNumber = InfoPlistHelper.buildNumber
```

### Before: Duplicate Environment Logic
```swift
#if DEBUG
return .development
#else
if ProcessInfo.processInfo.environment["STAGING"] != nil {
    return .staging
}
return .production
#endif
```

### After: Single Source of Truth
```swift
return ServiceConfiguration.detectEnvironment()
```

## Deployment Checklist

### Development Builds
- [ ] Verify `DEBUG` flag is set
- [ ] Confirm development services are accessible
- [ ] Test data generation works

### Staging Builds
- [ ] Set `STAGING=1` environment variable
- [ ] Verify staging API endpoints
- [ ] Test with production-like data
- [ ] Validate all services work in staging

### Production Builds
- [ ] Ensure no `STAGING` environment variable
- [ ] Verify production API endpoints
- [ ] Confirm analytics and monitoring enabled
- [ ] Test with release build configuration