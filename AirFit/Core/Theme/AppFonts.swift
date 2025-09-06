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

    // MARK: - Title Fonts (iOS 26 Enhanced)
    static let largeTitle = Font.system(size: Size.largeTitle, weight: .bold, design: .rounded)
        .width(.expanded)
    static let title = Font.system(size: Size.title, weight: .bold, design: .rounded)
        .width(.expanded)
    static let title2 = Font.system(size: Size.title2, weight: .semibold, design: .rounded)
        .width(.expanded)
    static let title3 = Font.system(size: Size.title3, weight: .semibold, design: .rounded)
        .width(.expanded)

    // MARK: - Body Fonts (iOS 26 Enhanced)
    static let headline = Font.system(size: Size.headline, weight: .semibold, design: .rounded)
        .width(.expanded)  // iOS 26 font width
    static let body = Font.system(size: Size.body, weight: .regular, design: .rounded)
        .width(.standard)
    static let bodyBold = Font.system(size: Size.body, weight: .semibold, design: .rounded)
        .width(.standard)
    static let callout = Font.system(size: Size.callout, weight: .regular, design: .monospaced)
        .width(.condensed)
    static let subheadline = Font.system(size: Size.subheadline, weight: .regular, design: .rounded)
        .width(.standard)

    // MARK: - Small Fonts (iOS 26 Enhanced)
    static let footnote = Font.system(size: Size.footnote, weight: .regular, design: .serif)
        .width(.standard)
    static let caption = Font.system(size: Size.caption, weight: .regular, design: .rounded)
        .width(.compressed)
    static let captionBold = Font.system(size: Size.caption, weight: .medium, design: .rounded)
        .width(.compressed)
    static let caption2 = Font.system(size: Size.caption2, weight: .regular, design: .rounded)
        .width(.compressed)

    // MARK: - Numeric Fonts (iOS 26 Enhanced)
    static let numberLarge = Font.system(size: Size.title, weight: .bold, design: .rounded)
        .width(.expanded)
    static let numberMedium = Font.system(size: Size.title3, weight: .semibold, design: .rounded)
        .width(.standard)
    static let numberSmall = Font.system(size: Size.body, weight: .medium, design: .rounded)
        .width(.condensed)
    
    // MARK: - iOS 26 Gradient Text Helpers
    static func gradientStyle(_ font: Font, colors: [Color] = [.primary, .primary.opacity(0.8)]) -> AnyView {
        AnyView(
            Text("")
                .font(font)
                .foregroundStyle(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

// MARK: - Text Extensions
extension Text {
    func appFont(_ font: Font) -> Text {
        self.font(font)
    }

    func primaryTitle() -> Text {
        self.font(AppFonts.title)
            .foregroundColor(.primary)
    }

    func secondaryBody() -> Text {
        self.font(AppFonts.body)
            .foregroundColor(.secondary)
    }
}
