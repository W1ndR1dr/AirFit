import SwiftUI

public struct AppShadows {
    // MARK: - Shadow Styles
    static let small = Shadow(
        color: Color.black.opacity(0.08),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let medium = Shadow(
        color: Color.black.opacity(0.12),
        radius: 8,
        x: 0,
        y: 4
    )
    
    static let large = Shadow(
        color: Color.black.opacity(0.16),
        radius: 16,
        x: 0,
        y: 8
    )
    
    static let card = Shadow(
        color: Color.black.opacity(0.1),
        radius: 10,
        x: 0,
        y: 5
    )
    
    static let elevated = Shadow(
        color: Color.black.opacity(0.2),
        radius: 20,
        x: 0,
        y: 10
    )
    
    // MARK: - Colored Shadows
    static let accent = Shadow(
        color: AppColors.accentColor.opacity(0.3),
        radius: 12,
        x: 0,
        y: 6
    )
    
    static let success = Shadow(
        color: AppColors.successColor.opacity(0.3),
        radius: 8,
        x: 0,
        y: 4
    )
    
    static let error = Shadow(
        color: AppColors.errorColor.opacity(0.3),
        radius: 8,
        x: 0,
        y: 4
    )
}

// MARK: - Shadow Model
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extension
extension View {
    func appShadow(_ shadow: Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
} 
