import SwiftUI

public struct AppColors {
    // MARK: - Background Colors
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let backgroundTertiary = Color("BackgroundTertiary")

    // MARK: - Text Colors
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")
    static let textOnAccent = Color("TextOnAccent")

    // MARK: - UI Elements
    static let cardBackground = Color("CardBackground")
    static let dividerColor = Color("DividerColor")
    static let shadowColor = Color.black.opacity(0.1)
    static let overlayColor = Color.black.opacity(0.4)

    // MARK: - Interactive Elements
    static let buttonBackground = Color("ButtonBackground")
    static let buttonText = Color("ButtonText")
    static let accentColor = Color("AccentColor")
    static let accentSecondary = Color("AccentSecondary")

    // MARK: - Semantic Colors
    static let errorColor = Color("ErrorColor")
    static let successColor = Color("SuccessColor")
    static let warningColor = Color("WarningColor")
    static let infoColor = Color("InfoColor")

    // MARK: - Nutrition Colors
    static let caloriesColor = Color("CaloriesColor")
    static let proteinColor = Color("ProteinColor")
    static let carbsColor = Color("CarbsColor")
    static let fatColor = Color("FatColor")

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [accentColor, accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let caloriesGradient = LinearGradient(
        colors: [caloriesColor.opacity(0.8), caloriesColor],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let proteinGradient = LinearGradient(
        colors: [proteinColor.opacity(0.8), proteinColor],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let carbsGradient = LinearGradient(
        colors: [carbsColor.opacity(0.8), carbsColor],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let fatGradient = LinearGradient(
        colors: [fatColor.opacity(0.8), fatColor],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
