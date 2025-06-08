import SwiftUI

extension Color {
    /// Initialize a color from an asset name with a fallback
    static func asset(_ name: String, fallback: Color = Color(UIColor.systemBackground)) -> Color {
        if UIColor(named: name) != nil {
            return Color(name)
        } else {
            AppLogger.warning("Color asset '\(name)' not found, using fallback", category: .ui)
            return fallback
        }
    }
}

// MARK: - Safe Color Accessors
extension AppColors {
    static var safeBackgroundPrimary: Color {
        Color.asset("BackgroundPrimary", fallback: Color(UIColor.systemBackground))
    }
    
    static var safeAccentColor: Color {
        Color.asset("AccentColor", fallback: .blue)
    }
    
    static var safeTextPrimary: Color {
        Color.asset("TextPrimary", fallback: Color(UIColor.label))
    }
    
    static var safeTextSecondary: Color {
        Color.asset("TextSecondary", fallback: Color(UIColor.secondaryLabel))
    }
}