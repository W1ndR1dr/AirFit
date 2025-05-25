import SwiftUI

struct AppColors {
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let accentColor = Color("AccentColor")

    static let cardBackground = Color("CardBackground")
    static let shadowColor = Color.black.opacity(0.1)

    static let errorColor = Color.red
    static let successColor = Color.green
    static let warningColor = Color.orange

    static let caloriesGradient = LinearGradient(
        gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green]),
        startPoint: .top,
        endPoint: .bottom)
    static let proteinGradient = LinearGradient(
        gradient: Gradient(colors: [Color.cyan.opacity(0.8), Color.cyan]),
        startPoint: .top,
        endPoint: .bottom)
    static let carbsGradient = LinearGradient(
        gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.orange]),
        startPoint: .top,
        endPoint: .bottom)
    static let fatGradient = LinearGradient(
        gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.purple]),
        startPoint: .top,
        endPoint: .bottom)
}
