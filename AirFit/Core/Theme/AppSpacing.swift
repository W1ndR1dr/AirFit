import SwiftUI

public enum AppSpacing: Sendable {
    // MARK: - Core Spacing System (UI Vision aligned)
    
    /// 12pt - Tight groupings
    static let xs: CGFloat = 12
    /// 20pt - Related elements
    static let sm: CGFloat = 20
    /// 24pt - Standard sections
    static let md: CGFloat = 24
    /// 32pt - Major sections
    static let lg: CGFloat = 32
    /// 48pt - Screen divisions
    static let xl: CGFloat = 48
    
    // MARK: - Legacy Support (kept for compatibility)
    
    /// 4pt
    static let xxSmall: CGFloat = 4
    /// 8pt
    static let xSmall: CGFloat = 8
    /// 12pt
    static let small: CGFloat = 12
    /// 16pt
    static let medium: CGFloat = 16
    /// 24pt
    static let large: CGFloat = 24
    /// 32pt
    static let xLarge: CGFloat = 32
    /// 48pt
    static let xxLarge: CGFloat = 48
    
    // MARK: - Screen & Component Padding
    
    /// 24pt - Standard screen padding
    static let screenPadding: CGFloat = 24
    /// 16pt - Card interior padding
    static let cardPadding: CGFloat = 16
    /// 20pt - Vertical component spacing
    static let componentSpacing: CGFloat = 20
    
    // MARK: - Corner Radius (Glass Morphism)
    
    /// 8pt - Small elements
    static let radiusSm: CGFloat = 8
    /// 12pt - Buttons
    static let radiusMd: CGFloat = 12
    /// 20pt - Cards (continuous curve)
    static let radiusLg: CGFloat = 20
}
