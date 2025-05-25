import SwiftUI

struct AppFonts {
    static func largeTitle(size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    
    static func title(size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    
    static func title2(size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    
    static func title3(size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    
    static func headline(size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    
    static func body(size: CGFloat = 17) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    
    static func callout(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    
    static func subheadline(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    
    static func footnote(size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    
    static func caption(size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    
    static func caption2(size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
}

extension Text {
    func appFont(_ style: (CGFloat) -> Font, size: CGFloat? = nil) -> Text {
        if let specificSize = size {
            return self.font(style(specificSize))
        }
        return self.font(style(17))
    }
} 