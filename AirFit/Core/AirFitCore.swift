import SwiftUI
import Foundation

// MARK: - Core Module Export
// This file ensures all Core components are compiled into the main AirFit module
// and available for testing and app usage.

// Re-export all Core types to ensure they're available in the AirFit module

// MARK: - Constants
public typealias AirFitConstants = AppConstants
public typealias AirFitAPIConstants = APIConstants

// MARK: - Enums
public typealias AirFitBiologicalSex = BiologicalSex
public typealias AirFitActivityLevel = ActivityLevel
public typealias AirFitFitnessGoal = FitnessGoal
public typealias AirFitLoadingState = LoadingState
public typealias AirFitAppTab = AppTab
public typealias AirFitAppError = AppError

// MARK: - Theme
public typealias AirFitColors = AppColors
public typealias AirFitFonts = AppFonts
public typealias AirFitSpacing = AppSpacing
public typealias AirFitShadows = AppShadows

// MARK: - Views
public typealias AirFitSectionHeader = SectionHeader
public typealias AirFitEmptyStateView = EmptyStateView
public typealias AirFitCard = Card
public typealias AirFitLoadingOverlay = LoadingOverlay

// MARK: - Utilities
public typealias AirFitLogger = AppLogger
public typealias AirFitFormatters = Formatters
public typealias AirFitValidators = Validators
public typealias AirFitKeychainWrapper = KeychainWrapper
public typealias AirFitHapticManager = HapticManager
public typealias AirFitDependencyContainer = DependencyContainer

// MARK: - Core Initialization
/// Ensures all Core components are properly initialized and available
public struct AirFitCore {
    
    /// Initialize the Core module
    public static func initialize() {
        AppLogger.info("AirFit Core module initialized", category: .general)
    }
    
    /// Verify all Core components are accessible
    public static func verifyComponents() -> Bool {
        // Test that all major components are accessible
        let _ = AppConstants.Layout.defaultPadding
        let _ = AppColors.backgroundPrimary
        let _ = AppFonts.body()
        let _ = AppSpacing.medium
        let _ = BiologicalSex.allCases
        let _ = ActivityLevel.allCases
        let _ = FitnessGoal.allCases
        let _ = AppTab.allCases
        
        return true
    }
}

// MARK: - Module Exports for Testing
#if DEBUG
/// Test helper to ensure all components are available for testing
public struct CoreTestHelper {
    public static func getAllComponents() -> [String] {
        return [
            "AppConstants", "APIConstants",
            "BiologicalSex", "ActivityLevel", "FitnessGoal", "LoadingState", "AppTab", "AppError",
            "AppColors", "AppFonts", "AppSpacing", "AppShadows",
            "SectionHeader", "EmptyStateView", "Card", "LoadingOverlay",
            "AppLogger", "Formatters", "Validators", "KeychainWrapper", "HapticManager", "DependencyContainer"
        ]
    }
}
#endif 