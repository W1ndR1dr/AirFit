import SwiftUI

public struct AppFonts: Sendable {
    // MARK: - Font Sizes
    private enum Size: Sendable {
        static let largeTitle: CGFloat = 34
        static let title: CGFloat = 28
        static let title2: CGFloat = 22
        static let title3: CGFloat = 20
        static let headline: CGFloat = 17
        static let body: CGFloat = 17
        static let callout: CGFloat = 16
        static let subheadline: CGFloat = 15
        static let footnote: CGFloat = 13
        static let caption: CGFloat = 12
        static let caption2: CGFloat = 11
    }

    // MARK: - Title Fonts
    static let largeTitle = Font.system(size: Size.largeTitle, weight: .bold, design: .rounded)
    static let title = Font.system(size: Size.title, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: Size.title2, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: Size.title3, weight: .semibold, design: .rounded)

    // MARK: - Body Fonts
    static let headline = Font.system(size: Size.headline, weight: .semibold, design: .default)
    static let body = Font.system(size: Size.body, weight: .regular, design: .default)
    static let bodyBold = Font.system(size: Size.body, weight: .semibold, design: .default)
    static let callout = Font.system(size: Size.callout, weight: .regular, design: .default)
    static let subheadline = Font.system(size: Size.subheadline, weight: .regular, design: .default)

    // MARK: - Small Fonts
    static let footnote = Font.system(size: Size.footnote, weight: .regular, design: .default)
    static let caption = Font.system(size: Size.caption, weight: .regular, design: .default)
    static let captionBold = Font.system(size: Size.caption, weight: .medium, design: .default)
    static let caption2 = Font.system(size: Size.caption2, weight: .regular, design: .default)

    // MARK: - Numeric Fonts
    static let numberLarge = Font.system(size: Size.title, weight: .bold, design: .rounded)
    static let numberMedium = Font.system(size: Size.title3, weight: .semibold, design: .rounded)
    static let numberSmall = Font.system(size: Size.body, weight: .medium, design: .rounded)
}

// MARK: - Text Extensions
extension Text {
    func appFont(_ font: Font) -> Text {
        self.font(font)
    }

    func primaryTitle() -> Text {
        self.font(AppFonts.title)
            .foregroundColor(AppColors.textPrimary)
    }

    func secondaryBody() -> Text {
        self.font(AppFonts.body)
            .foregroundColor(AppColors.textSecondary)
    }
}
