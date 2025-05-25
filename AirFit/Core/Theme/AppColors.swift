import SwiftUI

struct AppColors {
    // Primary Palette
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let accentColor = Color("AccentColor")
    
    // UI Elements
    static let cardBackground = Color("CardBackground")
    static let shadowColor = Color.black.opacity(0.1)
    static let dividerColor = Color("DividerColor")
    static let buttonBackground = Color("ButtonBackground")
    static let buttonText = Color("ButtonText")
    
    // Semantic Colors
    static let errorColor = Color.red
    static let successColor = Color.green
    static let warningColor = Color.orange
    
    // Macro Nutrient Colors
    static let caloriesColor = Color("CaloriesColor")
    static let proteinColor = Color("ProteinColor")
    static let carbsColor = Color("CarbsColor")
    static let fatColor = Color("FatColor")
    
    // Gradients for Macro Rings
    static let caloriesGradient = LinearGradient(
        gradient: Gradient(colors: [caloriesColor.opacity(0.8), caloriesColor]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let proteinGradient = LinearGradient(
        gradient: Gradient(colors: [proteinColor.opacity(0.8), proteinColor]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let carbsGradient = LinearGradient(
        gradient: Gradient(colors: [carbsColor.opacity(0.8), carbsColor]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let fatGradient = LinearGradient(
        gradient: Gradient(colors: [fatColor.opacity(0.8), fatColor]),
        startPoint: .top,
        endPoint: .bottom
    )
} 