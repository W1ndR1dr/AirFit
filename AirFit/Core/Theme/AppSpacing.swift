import SwiftUI

public enum AppSpacing: Sendable {
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
    
    // Convenience aliases
    static let xxs = xxSmall
    static let xs = xSmall
    static let sm = small
    static let md = medium
    static let lg = large
    static let xl = xLarge
    static let xxl = xxLarge
    
    // Corner radius values
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
}
