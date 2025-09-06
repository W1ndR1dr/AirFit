import Foundation

/// Centralized, type-safe helper for accessing Info.plist values
/// 
/// This helper eliminates scattered Bundle.main.infoDictionary calls throughout the codebase
/// and provides type-safe access to all Info.plist keys used by AirFit.
enum InfoPlistHelper {
    
    // MARK: - Bundle Information
    
    /// The display name of the app as configured in Info.plist
    static var appDisplayName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "AirFit"
    }
    
    /// The bundle name (product name) from Info.plist
    static var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "AirFit"
    }
    
    /// The short version string (e.g., "1.0.2") from Info.plist
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// The build number (e.g., "42") from Info.plist
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// The bundle identifier from Info.plist
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.airfit.app"
    }
    
    // MARK: - Permissions & Usage Descriptions
    
    /// Health data sharing usage description
    static var healthShareUsageDescription: String? {
        Bundle.main.infoDictionary?["NSHealthShareUsageDescription"] as? String
    }
    
    /// Health data update usage description
    static var healthUpdateUsageDescription: String? {
        Bundle.main.infoDictionary?["NSHealthUpdateUsageDescription"] as? String
    }
    
    /// Microphone usage description
    static var microphoneUsageDescription: String? {
        Bundle.main.infoDictionary?["NSMicrophoneUsageDescription"] as? String
    }
    
    /// Camera usage description
    static var cameraUsageDescription: String? {
        Bundle.main.infoDictionary?["NSCameraUsageDescription"] as? String
    }
    
    /// Photo library usage description
    static var photoLibraryUsageDescription: String? {
        Bundle.main.infoDictionary?["NSPhotoLibraryUsageDescription"] as? String
    }
    
    // MARK: - Background Processing & Activities
    
    /// Background task scheduler identifiers
    static var backgroundTaskIdentifiers: [String] {
        Bundle.main.infoDictionary?["BGTaskSchedulerPermittedIdentifiers"] as? [String] ?? []
    }
    
    /// Whether the app supports Live Activities
    static var supportsLiveActivities: Bool {
        Bundle.main.infoDictionary?["NSSupportsLiveActivities"] as? Bool ?? false
    }
    
    /// Background modes supported by the app
    static var backgroundModes: [String] {
        Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] ?? []
    }
    
    // MARK: - Environment & Configuration
    
    /// Check if running with staging configuration
    /// This looks for STAGING environment variable or custom Info.plist key
    static var isStagingEnvironment: Bool {
        // Check environment variable first
        if ProcessInfo.processInfo.environment["STAGING"] != nil {
            return true
        }
        
        // Check for custom staging flag in Info.plist (if added)
        return Bundle.main.infoDictionary?["AirFitStagingMode"] as? Bool ?? false
    }
    
    // MARK: - Raw Access
    
    /// Raw access to Info.plist dictionary for keys not covered by specific properties
    /// - Parameter key: The Info.plist key to retrieve
    /// - Returns: The value for the key, or nil if not found
    static func value(forKey key: String) -> Any? {
        Bundle.main.infoDictionary?[key]
    }
    
    /// Type-safe raw access to Info.plist values
    /// - Parameters:
    ///   - key: The Info.plist key to retrieve
    ///   - type: The expected type of the value
    /// - Returns: The typed value, or nil if not found or wrong type
    static func value<T>(forKey key: String, as type: T.Type) -> T? {
        Bundle.main.infoDictionary?[key] as? T
    }
}

// MARK: - Environment Detection Extension

extension InfoPlistHelper {
    
    /// Comprehensive environment detection that considers multiple factors
    enum DetectedEnvironment {
        case development
        case staging  
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "https://api-dev.airfit.app"
            case .staging:
                return "https://api-staging.airfit.app"
            case .production:
                return "https://api.airfit.app"
            }
        }
        
        var isDebug: Bool {
            self != .production
        }
    }
    
    /// Detect the current environment based on build configuration and runtime flags
    static var detectedEnvironment: DetectedEnvironment {
        #if DEBUG
        return .development
        #else
        return isStagingEnvironment ? .staging : .production
        #endif
    }
}