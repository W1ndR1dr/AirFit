import SwiftUI

struct AppFonts {
    static func primaryTitle(size: CGFloat = 28) -> Font {
        Font.system(size: size, weight: .bold, design: .default)
    }

    static func primaryBody(size: CGFloat = 17) -> Font {
        Font.system(size: size, weight: .regular, design: .default)
    }

    static func secondaryBody(size: CGFloat = 15) -> Font {
        Font.system(size: size, weight: .light, design: .default)
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
