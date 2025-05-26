import SwiftUI
import Foundation

// MARK: - Core Imports
// This file forces all Core components to be compiled into the main AirFit module
// by importing and referencing them, ensuring they're available for testing.

// Force compilation of all Core components
private struct CoreComponentsLoader {
    
    // Constants
    static let appConstants = AppConstants.self
    static let apiConstants = APIConstants.self
    
    // Enums
    static let biologicalSex = BiologicalSex.allCases
    static let activityLevel = ActivityLevel.allCases
    static let fitnessGoal = FitnessGoal.allCases
    static let loadingState = LoadingState.loading
    static let appTab = AppTab.allCases
    static let appError = AppError.unauthorized
    
    // Theme
    static let colors = AppColors.self
    static let fonts = AppFonts.self
    static let spacing = AppSpacing.self
    static let shadows = AppShadows.self
    
    // Views
    static func createViews() {
        let _ = SectionHeader(title: "Test")
        let _ = EmptyStateView(icon: "star", title: "Test", message: "Test")
        let _ = Card { Text("Test") }
    }
    
    // Utilities
    static let logger = AppLogger.self
    static let formatters = Formatters.self
    static let validators = Validators.self
    static let keychain = KeychainWrapper.self
    static let haptics = HapticManager.self
    static let container = DependencyContainer.self
    
    // Extensions - Force compilation by using them
    static func useExtensions() {
        let testString = "test"
        let _ = testString.isValidEmail
        let _ = testString.trimmed
        
        let testDate = Date()
        let _ = testDate.formatted(.dateTime)
        
        let testDouble = 123.45
        let _ = testDouble.rounded(toPlaces: 2)
        
        let testColor = Color.red
        let _ = testColor.toHex()
        
        let testView = Text("Test")
        let _ = testView.standardPadding()
        let _ = testView.cardStyle()
        let _ = testView.primaryButton()
    }
}

// MARK: - Public Interface
/// Ensures all Core components are loaded and available
public func loadCoreComponents() {
    // Reference all components to force compilation
    let _ = CoreComponentsLoader.appConstants
    let _ = CoreComponentsLoader.apiConstants
    let _ = CoreComponentsLoader.biologicalSex
    let _ = CoreComponentsLoader.activityLevel
    let _ = CoreComponentsLoader.fitnessGoal
    let _ = CoreComponentsLoader.loadingState
    let _ = CoreComponentsLoader.appTab
    let _ = CoreComponentsLoader.appError
    let _ = CoreComponentsLoader.colors
    let _ = CoreComponentsLoader.fonts
    let _ = CoreComponentsLoader.spacing
    let _ = CoreComponentsLoader.shadows
    let _ = CoreComponentsLoader.logger
    let _ = CoreComponentsLoader.formatters
    let _ = CoreComponentsLoader.validators
    let _ = CoreComponentsLoader.keychain
    let _ = CoreComponentsLoader.haptics
    let _ = CoreComponentsLoader.container
    
    CoreComponentsLoader.createViews()
    CoreComponentsLoader.useExtensions()
} 